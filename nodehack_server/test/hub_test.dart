// Flujo de salas por código probado a través del Hub con conexiones FALSAS
// (sin red real): determinista y rápido. La privacidad de manos y la validación
// anti-trampa se verifican aquí; la integración por WebSocket real va aparte.
import 'dart:convert';
import 'dart:math';

import 'package:test/test.dart';
import 'package:nodehack_engine/nodehack_engine.dart';
import 'package:nodehack_server/protocol.dart';
import 'package:nodehack_server/room.dart';

/// Captura los mensajes enviados a un cliente.
class Cap {
  final List<Map<String, dynamic>> msgs = [];
  late final Conn conn;
  Cap([String name = 'anon']) {
    conn = Conn((s) => msgs.add(jsonDecode(s) as Map<String, dynamic>), name: name);
  }

  List<Map<String, dynamic>> ofType(String t) => msgs.where((m) => m['t'] == t).toList();
  Map<String, dynamic>? lastOf(String t) {
    final l = ofType(t);
    return l.isEmpty ? null : l.last;
  }

  /// Última mano recibida (matchStart o acquire).
  List<dynamic> latestHand() {
    for (var i = msgs.length - 1; i >= 0; i--) {
      if (msgs[i].containsKey('hand')) return msgs[i]['hand'] as List;
    }
    return const [];
  }

  /// uids de todas las cartas que este cliente ha visto en su mano.
  Set<String> handUids() {
    final out = <String>{};
    for (final m in msgs) {
      if ((m['t'] == S2C.matchStart || m['t'] == S2C.acquire) && m['hand'] is List) {
        for (final c in m['hand'] as List) {
          out.add((c as Map)['uid'] as String);
        }
      }
    }
    return out;
  }
}

/// Jugada por defecto a partir de la última mano vista.
PlaySubmission defPlay(Cap cap) {
  final hand = handFromJson(cap.latestHand());
  final rut = hand.firstWhere((c) => !c.isSub);
  return PlaySubmission(rutinaUid: rut.uid, declaredType: rut.esComodinNull ? CType.firewall : null);
}

(Hub, Cap, Cap, String) _openRoom([int seed = 1]) {
  final hub = Hub(RoomManager(rng: Random(seed), closeDelay: const Duration(milliseconds: 5)));
  final a = Cap('ALICE'), b = Cap('BOB');
  hub.onMessage(a.conn, encodeMsg(C2S.hello, {'name': 'ALICE'}));
  hub.onMessage(b.conn, encodeMsg(C2S.hello, {'name': 'BOB'}));
  hub.onMessage(a.conn, encodeMsg(C2S.createRoom, {'deck': Deck.starter().toJson()}));
  final code = a.lastOf(S2C.roomCreated)!['code'] as String;
  hub.onMessage(b.conn, encodeMsg(C2S.joinRoom, {'code': code, 'deck': Deck.starter().toJson()}));
  return (hub, a, b, code);
}

void main() {
  group('salas con código', () {
    test('crear → unirse → ambos reciben matchStart con su mano y rival', () {
      final (_, a, b, code) = _openRoom();
      expect(code.length, 4);
      expect(a.lastOf(S2C.roomCreated)!['playerIndex'], 0);
      expect(b.lastOf(S2C.roomCreated)!['playerIndex'], 1);
      final msA = a.lastOf(S2C.matchStart)!;
      final msB = b.lastOf(S2C.matchStart)!;
      expect(msA['oppName'], 'BOB');
      expect(msB['oppName'], 'ALICE');
      expect((msA['hand'] as List), isNotEmpty);
      expect((msB['hand'] as List), isNotEmpty);
    });

    test('partida COMPLETA por el Hub termina con un ganador (win/lose)', () {
      final (hub, a, b, _) = _openRoom(3);
      var over = false;
      var guard = 0;
      while (!over && guard++ < 400) {
        hub.onMessage(a.conn, encodeMsg(C2S.submitPlay, defPlay(a).toJson()));
        hub.onMessage(b.conn, encodeMsg(C2S.submitPlay, defPlay(b).toJson()));
        final pub = a.lastOf(S2C.reveal)!['public'] as Map<String, dynamic>;
        over = pub['gameOver'] == true;
        if (!over) {
          hub.onMessage(a.conn, encodeMsg(C2S.nextRoundAck));
          hub.onMessage(b.conn, encodeMsg(C2S.nextRoundAck));
        }
      }
      expect(over, isTrue);
      final outA = (a.lastOf(S2C.reveal)!['public'] as Map)['outcome'];
      final outB = (b.lastOf(S2C.reveal)!['public'] as Map)['outcome'];
      expect({outA, outB}, {'win', 'lose'});
    });

    test('PRIVACIDAD: las manos de los dos jugadores nunca se cruzan', () {
      final (hub, a, b, _) = _openRoom(4);
      var over = false, guard = 0;
      while (!over && guard++ < 400) {
        hub.onMessage(a.conn, encodeMsg(C2S.submitPlay, defPlay(a).toJson()));
        hub.onMessage(b.conn, encodeMsg(C2S.submitPlay, defPlay(b).toJson()));
        over = (a.lastOf(S2C.reveal)!['public'] as Map)['gameOver'] == true;
        if (!over) {
          hub.onMessage(a.conn, encodeMsg(C2S.nextRoundAck));
          hub.onMessage(b.conn, encodeMsg(C2S.nextRoundAck));
        }
      }
      // Cada quien sólo recibió SU mano: los conjuntos de uids son disjuntos.
      expect(a.handUids().intersection(b.handUids()), isEmpty);
      // A nunca recibió un mensaje 'matchStart'/'acquire' con la mano de B.
      expect(a.ofType(S2C.acquire).every((m) => m.containsKey('hand')), isTrue);
    });
  });

  group('validación / errores', () {
    test('rechaza mazo ilegal al crear sala', () {
      final hub = Hub(RoomManager(rng: Random(1)));
      final a = Cap();
      hub.onMessage(a.conn, encodeMsg(C2S.createRoom, {'deck': Deck(name: 'X').toJson()}));
      expect(a.lastOf(S2C.error)!['message'], 'mazo ilegal');
    });

    test('rechaza código inexistente al unirse', () {
      final hub = Hub(RoomManager(rng: Random(1)));
      final b = Cap();
      hub.onMessage(b.conn, encodeMsg(C2S.joinRoom, {'code': 'ZZZZ', 'deck': Deck.starter().toJson()}));
      expect(b.lastOf(S2C.error)!['message'], 'sala no encontrada');
    });

    test('rechaza una jugada inválida sin tumbar la sala', () {
      final (hub, a, _, _) = _openRoom();
      hub.onMessage(a.conn, encodeMsg(C2S.submitPlay, {'rutinaUid': 'fantasma', 'subUids': <String>[]}));
      expect(a.lastOf(S2C.error)!['message'], 'rutina inválida');
    });
  });

  group('desconexión / reconexión', () {
    test('si el rival no vuelve dentro de la ventana, el otro gana por forfeit', () async {
      final hub = Hub(RoomManager(
        rng: Random(1),
        reconnectWindow: const Duration(milliseconds: 30),
        closeDelay: const Duration(milliseconds: 5),
      ));
      final a = Cap('A'), b = Cap('B');
      hub.onMessage(a.conn, encodeMsg(C2S.createRoom, {'deck': Deck.starter().toJson()}));
      final code = a.lastOf(S2C.roomCreated)!['code'] as String;
      hub.onMessage(b.conn, encodeMsg(C2S.joinRoom, {'code': code, 'deck': Deck.starter().toJson()}));

      hub.onClose(a.conn); // A se cae
      expect(b.lastOf(S2C.oppDisconnected), isNotNull);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(b.lastOf(S2C.gameOver)!['outcome'], 'win');
    });

    test('rendición explícita (leave): el rival gana AL INSTANTE, sin ventana', () {
      // Ventana de reconexión larga a propósito: el forfeit NO debe esperarla.
      final hub = Hub(RoomManager(
        rng: Random(1),
        reconnectWindow: const Duration(minutes: 5),
        closeDelay: const Duration(milliseconds: 5),
      ));
      final a = Cap('A'), b = Cap('B');
      hub.onMessage(a.conn, encodeMsg(C2S.createRoom, {'deck': Deck.starter().toJson()}));
      final code = a.lastOf(S2C.roomCreated)!['code'] as String;
      hub.onMessage(b.conn, encodeMsg(C2S.joinRoom, {'code': code, 'deck': Deck.starter().toJson()}));

      hub.onMessage(a.conn, encodeMsg(C2S.leave)); // A se rinde
      expect(b.lastOf(S2C.gameOver)!['outcome'], 'win'); // sin esperar nada
    });

    test('reconexión por token restaura la mesa y avisa al rival', () {
      final hub = Hub(RoomManager(rng: Random(1), reconnectWindow: const Duration(seconds: 5)));
      final a = Cap('A'), b = Cap('B');
      hub.onMessage(a.conn, encodeMsg(C2S.createRoom, {'deck': Deck.starter().toJson()}));
      final tokenA = a.lastOf(S2C.roomCreated)!['token'] as String;
      final code = a.lastOf(S2C.roomCreated)!['code'] as String;
      hub.onMessage(b.conn, encodeMsg(C2S.joinRoom, {'code': code, 'deck': Deck.starter().toJson()}));

      hub.onClose(a.conn);
      expect(b.lastOf(S2C.oppDisconnected), isNotNull);

      final a2 = Cap('A');
      hub.onMessage(a2.conn, encodeMsg(C2S.reconnect, {'token': tokenA}));
      expect(a2.lastOf(S2C.matchStart), isNotNull); // recupera su mano/estado
      expect(b.lastOf(S2C.oppReconnected), isNotNull);
    });
  });
}
