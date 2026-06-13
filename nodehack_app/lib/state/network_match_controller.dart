/// Controlador de partida ONLINE (PVP). Implementa [MatchView] igual que el
/// controlador local, pero su estado lo **dicta el servidor**: la mano, la
/// integridad y el resultado llegan por WebSocket; el jugador sólo programa en
/// local y envía su jugada. También gestiona el lobby (crear/unirse/esperar).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:nodehack_engine/nodehack_engine.dart';

import '../net/ws_client.dart';
import 'match_view.dart';

/// Etapa de la sesión online (meta-estado por encima de las fases de ronda).
enum OnlineStage { connecting, lobby, waitingOpponent, match, ended, error }

class NetworkMatchController extends ChangeNotifier implements MatchView {
  final GameSocket ws;
  final Deck deckYou;
  final String playerName;
  final void Function(MatchSummary) onFlush;

  NetworkMatchController({
    required this.ws,
    required this.deckYou,
    required this.playerName,
    required this.onFlush,
  }) {
    _sub = ws.messages.listen(_onMessage);
    ws.onStatus = _onWsStatus;
  }

  StreamSubscription<Map<String, dynamic>>? _sub;
  final List<Timer> _timers = [];

  // ---- Estado del lobby / conexión ----
  OnlineStage stage = OnlineStage.connecting;
  String? roomCode;
  String? token;
  int playerIndex = 0;
  @override
  String oppName = 'RIVAL';
  String? errorMsg;
  String? _outcome;
  bool oppConnected = true;
  bool _submitted = false;
  bool _oppReady = false;
  bool _ackedNext = false;

  bool get submitted => _submitted;
  bool get oppReady => _oppReady;
  bool get waitingNext => _ackedNext;

  // ---- Estado de la partida (MatchView) ----
  bool _matchStarted = false;
  bool get matchStarted => _matchStarted;

  NucleoDef _nucYou = kNucleos.first;
  NucleoDef _nucOpp = kNucleos.first;
  int _integrityYou = 4;
  int _integrityOpp = 4;
  int _round = 1;
  int _ramBase = 5;
  int _rutPileYou = 0;
  int _subPileYou = 0;

  final List<CardInstance> _handYou = [];
  CardInstance? _active;
  final List<CardInstance?> _subs = [null, null];
  Play? _oppPlay;
  RoundResult? _result;

  int _phaseIdx = 1;
  bool _revealed = false;
  ({String side, int amount})? _hit;
  final List<Winner> _history = [];
  bool _showAcquire = false;
  int _acquiredN = 0, _acquiredRut = 0, _acquiredSub = 0;
  bool _gameOver = false;

  // ===================== Lobby / arranque =====================
  Future<void> host() async {
    if (!await _ensureConnected()) return;
    ws.send(C2S.createRoom, {'deck': deckYou.toJson()});
  }

  Future<void> join(String code) async {
    if (!await _ensureConnected()) return;
    ws.send(C2S.joinRoom, {'code': code.trim().toUpperCase(), 'deck': deckYou.toJson()});
  }

  Future<bool> _ensureConnected() async {
    if (ws.status == WsStatus.open) return true;
    stage = OnlineStage.connecting;
    notifyListeners();
    final ok = await ws.connect();
    if (!ok) {
      errorMsg = 'No se pudo conectar al servidor';
      stage = OnlineStage.error;
      notifyListeners();
      return false;
    }
    ws.send(C2S.hello, {'name': playerName});
    return true;
  }

  void _onWsStatus(WsStatus s) {
    if ((s == WsStatus.closed || s == WsStatus.error) && !_gameOver && _matchStarted) {
      errorMsg = 'Conexión perdida';
      notifyListeners();
    }
  }

  /// Abandona: avisa al servidor y cierra.
  void leave() {
    ws.send(C2S.leave);
    ws.close();
  }

  // ===================== Mensajes del servidor =====================
  void _onMessage(Map<String, dynamic> m) {
    switch (m['t']) {
      case S2C.roomCreated:
        roomCode = m['code'] as String?;
        token = m['token'] as String?;
        playerIndex = (m['playerIndex'] as int?) ?? 0;
        // El anfitrión espera al rival; el invitado recibirá matchStart enseguida.
        if (!_matchStarted) stage = playerIndex == 0 ? OnlineStage.waitingOpponent : OnlineStage.lobby;
        notifyListeners();
      case S2C.matchStart:
        _applyMatchStart(m);
      case S2C.oppReady:
        _oppReady = true;
        notifyListeners();
      case S2C.reveal:
        _applyReveal(m);
      case S2C.acquire:
        _applyAcquire(m);
      case S2C.oppDisconnected:
        oppConnected = false;
        errorMsg = 'El rival se desconectó…';
        notifyListeners();
      case S2C.oppReconnected:
        oppConnected = true;
        errorMsg = null;
        notifyListeners();
      case S2C.gameOver:
        _gameOver = true;
        _outcome = (m['outcome'] as String?) ?? 'win';
        stage = OnlineStage.ended;
        notifyListeners();
        // Forfeit: el rival se rindió o se desconectó.
        _after(600, () => onFlush(MatchSummary(
              outcome: (m['outcome'] as String?) ?? 'win',
              round: _round,
              history: List.of(_history),
              reason: 'opp_left',
            )));
      case S2C.error:
        errorMsg = (m['message'] as String?) ?? 'error';
        if (!_matchStarted) stage = OnlineStage.error;
        notifyListeners();
    }
  }

  void _applyMatchStart(Map<String, dynamic> m) {
    final pub = PublicState.fromJson(m['public'] as Map<String, dynamic>);
    _nucYou = kNucById[pub.nucYouId] ?? kNucleos.first;
    _nucOpp = kNucById[pub.nucOppId] ?? kNucleos.first;
    oppName = (m['oppName'] as String?) ?? 'RIVAL';
    _ramBase = (m['ramBase'] as int?) ?? _nucYou.ram;
    _loadHand(m['hand'] as List);
    _applyPublic(pub);
    _resetRound();
    _matchStarted = true;
    stage = OnlineStage.match;
    errorMsg = null;
    notifyListeners();
  }

  void _applyReveal(Map<String, dynamic> m) {
    _oppPlay = Play.fromJson(m['oppPlay'] as Map<String, dynamic>);
    final r = RoundResult.fromJson(m['result'] as Map<String, dynamic>);
    final pub = PublicState.fromJson(m['public'] as Map<String, dynamic>);
    _result = r;
    _phaseIdx = 3; // REVELACIÓN
    _revealed = false;
    notifyListeners();
    // La EJECUCIÓN dura según cuántas cartas se jugaron (una parada por carta + resultado).
    final items = 1 +
        _subs.whereType<CardInstance>().length +
        1 +
        _oppPlay!.subs.length;
    const execStart = 1200;
    final resultAt = execStart + (items + 1) * kExecStepMs + 300;
    _after(350, () {
      _revealed = true;
      notifyListeners();
    });
    _after(execStart, () {
      _phaseIdx = 4; // EJECUCIÓN — la mesa enfoca carta por carta a kExecStepMs
      notifyListeners();
    });
    _after(resultAt, () {
      _phaseIdx = 5; // RESULTADO — aplica integridad junto con el "hit" (pips rotos)
      _applyPublic(pub);
      _history.add(r.winner);
      if (r.winner == Winner.you) {
        _hit = (side: 'opp', amount: r.damage);
      } else if (r.winner == Winner.opp) {
        _hit = (side: 'you', amount: r.damage);
      }
      notifyListeners();
      if (_hit != null) {
        _after(1200, () {
          _hit = null;
          notifyListeners();
        });
      }
      if (pub.gameOver) {
        _gameOver = true;
        _outcome = pub.outcome;
        // Pausa para ver la descarga/desconexión del perdedor antes de resultados.
        _after(3200, () => onFlush(MatchSummary(
              outcome: pub.outcome ?? 'lose',
              round: pub.round,
              history: List.of(_history),
            )));
      }
    });
  }

  void _applyAcquire(Map<String, dynamic> m) {
    _ramBase = (m['ramBase'] as int?) ?? _nucYou.ram;
    _loadHand(m['hand'] as List);
    _applyPublic(PublicState.fromJson(m['public'] as Map<String, dynamic>));
    _acquiredN = (m['acquiredN'] as int?) ?? 0;
    _acquiredRut = (m['acquiredRut'] as int?) ?? 0;
    _acquiredSub = (m['acquiredSub'] as int?) ?? 0;
    _resetRound();
    _showAcquire = _acquiredN > 0;
    notifyListeners();
    if (_showAcquire) {
      _after(1900, () {
        _showAcquire = false;
        notifyListeners();
      });
    }
  }

  void _applyPublic(PublicState pub) {
    _integrityYou = pub.integrityYou;
    _integrityOpp = pub.integrityOpp;
    _rutPileYou = pub.rutPileYou;
    _subPileYou = pub.subPileYou;
    _round = pub.round;
  }

  void _loadHand(List<dynamic> hand) {
    _handYou
      ..clear()
      ..addAll(handFromJson(hand));
  }

  void _resetRound() {
    _active = null;
    _subs[0] = null;
    _subs[1] = null;
    _oppPlay = null;
    _result = null;
    _phaseIdx = 1; // PROGRAMACIÓN
    _revealed = false;
    _submitted = false;
    _oppReady = false;
    _ackedNext = false;
    _hit = null;
  }

  // ===================== MatchView: lectura =====================
  @override
  MatchPhase get phase => kPhases[_phaseIdx];
  @override
  int get phaseIdx => _phaseIdx;
  @override
  bool get revealed => _revealed;
  @override
  int get round => _round;
  @override
  List<CardInstance> get handYou => _handYou;
  @override
  List<CardInstance?> get subs => _subs;
  @override
  CardInstance? get active => _active;
  @override
  Play? get oppPlay => _oppPlay;
  @override
  RoundResult? get result => _result;
  @override
  NucleoDef get nucYou => _nucYou;
  @override
  NucleoDef get nucOpp => _nucOpp;
  @override
  int get integrityYou => _integrityYou;
  @override
  int get integrityOpp => _integrityOpp;
  @override
  int get integrityMaxYou => _nucYou.integrity; // online no hay modificadores
  @override
  int get integrityMaxOpp => _nucOpp.integrity;
  @override
  String? get notice {
    if (_gameOver) return null;
    if (!oppConnected) return 'EL RIVAL SE DESCONECTÓ — si no vuelve en unos segundos, ganas por abandono';
    if (errorMsg == 'Conexión perdida') return 'CONEXIÓN PERDIDA — revisa tu red…';
    return null;
  }
  @override
  int get ramMax {
    var ram = _ramBase;
    final a = _active;
    if (a != null) {
      if (_nucYou.passiveId == PassiveId.resonancia && a.type == CType.signal) ram += 1;
      if (_nucYou.passiveId == PassiveId.corrupcion && a.esComodinNull) ram += 1;
    }
    return ram < 0 ? 0 : ram;
  }

  @override
  int get ramLeft => ramMax - _subs.fold(0, (a, s) => a + (s?.ram ?? 0));
  @override
  bool subCabe(CardInstance s) => s.ram <= ramLeft;
  @override
  int get rutPileYou => _rutPileYou;
  @override
  int get subPileYou => _subPileYou;
  @override
  int get acquiredN => _acquiredN;
  @override
  int get acquiredRut => _acquiredRut;
  @override
  int get acquiredSub => _acquiredSub;
  @override
  bool get showAcquire => _showAcquire;
  @override
  bool get needsNullDeclaration =>
      _active != null && _active!.esComodinNull && _active!.declaredType == null;
  @override
  bool get canCompile =>
      _matchStarted && _phaseIdx == 1 && !_submitted && _active != null && !needsNullDeclaration && !_gameOver;
  @override
  ({String side, int amount})? get hit => _hit;
  @override
  List<Winner> get history => _history;
  @override
  bool get gameOver => _gameOver;
  @override
  String? get outcome => _outcome;

  // ===================== MatchView: acciones =====================
  @override
  void placeActive(CardInstance c) {
    if (_phaseIdx != 1 || _submitted) return;
    if (_active != null && _active!.uid != c.uid) {
      _active!.declaredType = null;
      _handYou.add(_active!);
    }
    _handYou.removeWhere((x) => x.uid == c.uid);
    _active = c;
    notifyListeners();
  }

  @override
  void placeSub(CardInstance c, int idx) {
    if (_phaseIdx != 1 || _submitted) return;
    if (_subs[idx] != null || !subCabe(c)) return;
    _handYou.removeWhere((x) => x.uid == c.uid);
    _subs[idx] = c;
    notifyListeners();
  }

  @override
  void returnActive() {
    if (_phaseIdx != 1 || _submitted) return;
    if (_active != null) {
      _active!.declaredType = null;
      _handYou.add(_active!);
      _active = null;
      notifyListeners();
    }
  }

  @override
  void returnSub(int idx) {
    if (_phaseIdx != 1 || _submitted) return;
    final c = _subs[idx];
    if (c != null) {
      _handYou.add(c);
      _subs[idx] = null;
      notifyListeners();
    }
  }

  @override
  void declareNull(CType t) {
    _active?.declaredType = t;
    notifyListeners();
  }

  @override
  void compile() {
    if (!canCompile) return;
    final sub = PlaySubmission(
      rutinaUid: _active!.uid,
      declaredType: _active!.esComodinNull ? _active!.declaredType : null,
      subUids: [for (final s in _subs) if (s != null) s.uid],
    );
    ws.send(C2S.submitPlay, sub.toJson());
    _submitted = true;
    _phaseIdx = 2; // COMPILAR — sellado, esperando al rival
    notifyListeners();
  }

  @override
  void nextRound() {
    if (_gameOver || _ackedNext || _phaseIdx != 5) return;
    ws.send(C2S.nextRoundAck);
    _ackedNext = true;
    notifyListeners();
  }

  void _after(int ms, VoidCallback fn) => _timers.add(Timer(Duration(milliseconds: ms), fn));

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _sub?.cancel();
    ws.close();
    super.dispose();
  }
}
