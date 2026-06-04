/// Salas con código, flujo de ronda y ruteo de mensajes. Estado **en memoria**
/// (escala-a-cero, sin DB). El `Conn` es una abstracción del socket para poder
/// probar el flujo sin red real.
library;

import 'dart:async';
import 'dart:math';

import 'package:nodehack_engine/nodehack_engine.dart';

import 'online_match.dart';
import 'protocol.dart';

/// Una conexión de cliente. `send` escribe un texto al socket (o a un buffer en tests).
class Conn {
  final void Function(String) send;
  String name;
  Room? room;
  int slot = -1;
  String? token;
  Conn(this.send, {this.name = 'anon'});
}

class Room {
  final String code;
  final RoomManager manager;

  final List<Conn?> conns = [null, null];
  final List<String> names = ['', ''];
  final List<Deck?> decks = [null, null];
  final List<bool> ackNext = [false, false];

  OnlineMatch? match;
  bool started = false;
  bool ended = false;

  Timer? _turnTimer;
  Timer? _ackTimer;
  Timer? _reconnectTimer;

  Room(this.code, this.manager);

  Duration get _turnTimeout => manager.turnTimeout;
  Duration get _ackTimeout => manager.ackTimeout;
  Duration get _reconnectWindow => manager.reconnectWindow;

  void _send(int slot, String type, [Map<String, dynamic> data = const {}]) =>
      conns[slot]?.send(encodeMsg(type, data));

  /// Conecta a [c] en el [slot] con su [name] y [deck]. Devuelve el token de reconexión.
  String attach(Conn c, int slot, String name, Deck deck) {
    conns[slot] = c;
    names[slot] = name;
    decks[slot] = deck;
    c
      ..room = this
      ..slot = slot
      ..name = name
      ..token = manager.genToken();
    manager.registerToken(c.token!, this, slot);
    return c.token!;
  }

  bool get _full => conns[0] != null && conns[1] != null && decks[0] != null && decks[1] != null;

  /// Arranca la partida cuando ambos jugadores están presentes.
  void tryStart() {
    if (started || !_full) return;
    started = true;
    final d0 = decks[0]!, d1 = decks[1]!;
    match = OnlineMatch(
      nuc0: kNucById[d0.nucleoId] ?? kNucleos.first,
      deck0: d0,
      nuc1: kNucById[d1.nucleoId] ?? kNucleos.first,
      deck1: d1,
      rng: manager.rng,
    );
    for (var i = 0; i < 2; i++) {
      _sendMatchStart(i);
    }
    _startTurnTimer();
  }

  void _sendMatchStart(int slot) {
    final m = match!;
    _send(slot, S2C.matchStart, {
      'hand': handToJson(m.handOf(slot)),
      'ramBase': m.ramBaseFor(slot),
      'public': m.publicStateFor(slot).toJson(),
      'oppName': names[1 - slot],
    });
  }

  // ---------------- Programación / revelación ----------------
  void onSubmit(int slot, PlaySubmission sub) {
    final m = match;
    if (m == null || ended) return;
    final err = m.submitPlay(slot, sub);
    if (err != null) {
      _send(slot, S2C.error, {'message': err});
      return;
    }
    _send(1 - slot, S2C.oppReady);
    if (m.bothSubmitted) _reveal();
  }

  void _reveal() {
    _turnTimer?.cancel();
    final m = match!;
    m.resolveRound();
    for (var i = 0; i < 2; i++) {
      _send(i, S2C.reveal, {
        'yourPlay': m.playOf(i).toJson(),
        'oppPlay': m.playOf(1 - i).toJson(),
        'result': m.resultFor(i).toJson(),
        'public': m.publicStateFor(i).toJson(),
      });
    }
    if (m.gameOver) {
      ended = true;
      manager.scheduleClose(this);
    } else {
      ackNext[0] = false;
      ackNext[1] = false;
      _ackTimer?.cancel();
      _ackTimer = Timer(_ackTimeout, _advance); // auto-avanza si alguien no confirma
    }
  }

  void onAck(int slot) {
    if (match == null || ended) return;
    ackNext[slot] = true;
    if (ackNext[0] && ackNext[1]) _advance();
  }

  void _advance() {
    _ackTimer?.cancel();
    final m = match!;
    if (m.gameOver || ended) return;
    m.advanceRound();
    for (var i = 0; i < 2; i++) {
      _send(i, S2C.acquire, {
        'hand': handToJson(m.handOf(i)),
        'ramBase': m.ramBaseFor(i),
        'public': m.publicStateFor(i).toJson(),
        'acquiredN': m.p[i].acquiredN,
        'acquiredRut': m.p[i].acquiredRut,
        'acquiredSub': m.p[i].acquiredSub,
      });
    }
    _startTurnTimer();
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _turnTimer = Timer(_turnTimeout, _onTurnTimeout);
  }

  /// Si alguien no programó a tiempo, se le juega una jugada por defecto.
  void _onTurnTimeout() {
    final m = match;
    if (m == null || ended) return;
    for (var i = 0; i < 2; i++) {
      if (!m.p[i].submitted) {
        m.submitPlay(i, m.defaultSubmissionFor(i));
        _send(1 - i, S2C.oppReady);
      }
    }
    if (m.bothSubmitted) _reveal();
  }

  // ---------------- Desconexión / reconexión ----------------
  void onDisconnect(int slot) {
    if (conns[slot] == null) return;
    conns[slot] = null;
    if (ended) {
      manager.scheduleClose(this);
      return;
    }
    if (!started) {
      // Nadie jugó aún: si la sala queda vacía, ciérrala.
      if (conns[0] == null && conns[1] == null) manager.closeRoom(this);
      return;
    }
    _send(1 - slot, S2C.oppDisconnected);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectWindow, () => _forfeit(slot));
  }

  void _forfeit(int loser) {
    if (ended) return;
    ended = true;
    final winner = 1 - loser;
    match?.gameOver = true;
    match?.winner = winner;
    _send(winner, S2C.gameOver, {'outcome': 'win'});
    manager.scheduleClose(this);
  }

  void onReconnect(Conn c, int slot) {
    if (ended) {
      _send0(c, S2C.error, {'message': 'la partida ya terminó'});
      return;
    }
    _reconnectTimer?.cancel();
    conns[slot] = c;
    c
      ..room = this
      ..slot = slot
      ..name = names[slot]
      ..token = manager.tokenFor(this, slot);
    // Reenvía el estado actual para que el cliente repinte la mesa.
    _sendMatchStart(slot);
    _send(1 - slot, S2C.oppReconnected);
  }

  void _send0(Conn c, String type, [Map<String, dynamic> data = const {}]) =>
      c.send(encodeMsg(type, data));

  void disposeTimers() {
    _turnTimer?.cancel();
    _ackTimer?.cancel();
    _reconnectTimer?.cancel();
  }
}

class RoomManager {
  final Map<String, Room> _rooms = {};
  final Map<String, ({Room room, int slot})> _byToken = {};
  final Random rng;
  final Duration turnTimeout;
  final Duration ackTimeout;
  final Duration reconnectWindow;
  final Duration closeDelay;

  RoomManager({
    Random? rng,
    this.turnTimeout = const Duration(seconds: 90),
    this.ackTimeout = const Duration(seconds: 45),
    this.reconnectWindow = const Duration(seconds: 30),
    this.closeDelay = const Duration(seconds: 2),
  }) : rng = rng ?? Random.secure();

  int get roomCount => _rooms.length;

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sin O/0/I/1

  String _genCode() {
    String code;
    do {
      code = List.generate(4, (_) => _alphabet[rng.nextInt(_alphabet.length)]).join();
    } while (_rooms.containsKey(code));
    return code;
  }

  String genToken() => List.generate(24, (_) => _alphabet[rng.nextInt(_alphabet.length)]).join();

  void registerToken(String token, Room room, int slot) => _byToken[token] = (room: room, slot: slot);

  String? tokenFor(Room room, int slot) {
    for (final e in _byToken.entries) {
      if (e.value.room == room && e.value.slot == slot) return e.key;
    }
    return null;
  }

  Room createRoom(Conn c, String name, Deck deck) {
    final room = Room(_genCode(), this);
    _rooms[room.code] = room;
    room.attach(c, 0, name, deck);
    return room;
  }

  /// Devuelve `null` si se unió bien, o un mensaje de error.
  String? joinRoom(Conn c, String code, String name, Deck deck) {
    final room = _rooms[code.toUpperCase().trim()];
    if (room == null) return 'sala no encontrada';
    if (room.started) return 'la sala ya empezó';
    if (room.conns[1] != null) return 'sala llena';
    room.attach(c, 1, name, deck);
    return null;
  }

  /// Reasocia una conexión a su slot por token. Devuelve la sala o `null`.
  Room? reconnect(String token, Conn c) {
    final e = _byToken[token];
    if (e == null) return null;
    e.room.onReconnect(c, e.slot);
    return e.room;
  }

  void scheduleClose(Room room) {
    // Pequeño margen para que lleguen los últimos mensajes antes de liberar.
    Timer(closeDelay, () => closeRoom(room));
  }

  void closeRoom(Room room) {
    room.disposeTimers();
    _rooms.remove(room.code);
    _byToken.removeWhere((_, v) => v.room == room);
  }
}

/// Rutea los mensajes de una conexión hacia el RoomManager / la sala.
class Hub {
  final RoomManager rooms;
  Hub(this.rooms);

  void onMessage(Conn c, String text) {
    final Map<String, dynamic> m;
    try {
      m = decodeMsg(text);
    } catch (_) {
      c.send(encodeMsg(S2C.error, {'message': 'mensaje inválido'}));
      return;
    }
    switch (m['t']) {
      case C2S.hello:
        final n = (m['name'] as String?)?.trim();
        c.name = (n == null || n.isEmpty) ? 'anon' : (n.length > 16 ? n.substring(0, 16) : n);
      case C2S.createRoom:
        final deck = _deck(m);
        if (deck == null || !deck.isLegal) {
          c.send(encodeMsg(S2C.error, {'message': 'mazo ilegal'}));
          return;
        }
        final room = rooms.createRoom(c, c.name, deck);
        c.send(encodeMsg(S2C.roomCreated, {'code': room.code, 'token': c.token, 'playerIndex': 0}));
      case C2S.joinRoom:
        final deck = _deck(m);
        if (deck == null || !deck.isLegal) {
          c.send(encodeMsg(S2C.error, {'message': 'mazo ilegal'}));
          return;
        }
        final code = (m['code'] as String?) ?? '';
        final err = rooms.joinRoom(c, code, c.name, deck);
        if (err != null) {
          c.send(encodeMsg(S2C.error, {'message': err}));
          return;
        }
        c.send(encodeMsg(S2C.roomCreated, {'code': c.room!.code, 'token': c.token, 'playerIndex': 1}));
        c.room!.tryStart();
      case C2S.submitPlay:
        if (c.room == null || c.slot < 0) return;
        c.room!.onSubmit(c.slot, PlaySubmission.fromJson(m));
      case C2S.nextRoundAck:
        c.room?.onAck(c.slot);
      case C2S.reconnect:
        final token = (m['token'] as String?) ?? '';
        if (rooms.reconnect(token, c) == null) {
          c.send(encodeMsg(S2C.error, {'message': 'no se pudo reconectar'}));
        }
      case C2S.leave:
        final room = c.room;
        final slot = c.slot;
        c.room = null;
        c.slot = -1;
        room?.onDisconnect(slot);
      default:
        c.send(encodeMsg(S2C.error, {'message': 'tipo desconocido'}));
    }
  }

  void onClose(Conn c) {
    final room = c.room;
    final slot = c.slot;
    c.room = null;
    c.slot = -1;
    room?.onDisconnect(slot);
  }

  Deck? _deck(Map<String, dynamic> m) {
    final d = m['deck'];
    if (d is! Map) return null;
    try {
      return Deck.fromJson(Map<String, dynamic>.from(d));
    } catch (_) {
      return null;
    }
  }
}
