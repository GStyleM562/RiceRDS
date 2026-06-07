/// Controlador de partida (ChangeNotifier): conduce el MatchEngine por fases con
/// la temporización/animación del handoff. La CPU programa oculto en COMPILAR.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:nodehack_engine/card_instance.dart';
import 'package:nodehack_engine/cards.dart';
import 'package:nodehack_engine/deck.dart';
import 'package:nodehack_engine/match_engine.dart';
import 'package:nodehack_engine/resolve.dart';
import 'package:nodehack_engine/types.dart';

import 'match_view.dart';

class MatchController extends ChangeNotifier implements MatchView {
  final MatchEngine engine;
  final void Function(MatchSummary) onFlush;

  @override
  int phaseIdx = 1; // arranca en PROGRAMACIÓN
  @override
  bool revealed = false;
  final List<Timer> _timers = [];

  /// Lado que recibe daño esta ronda (para sacudida/flash/pip roto). Se limpia a 1.2s.
  @override
  ({String side, int amount})? hit;

  /// Ganador de cada ronda (para el marcador de seguimiento).
  @override
  final List<Winner> history = [];

  /// Insignia "ADQUIRIDAS +N" visible al inicio de ronda.
  @override
  bool showAcquire = false;

  MatchController({
    required Deck deckYou,
    required this.onFlush,
    int? seed,
  }) : engine = MatchEngine(
          nucYou: kNucById[deckYou.nucleoId] ?? kNucleos.first,
          nucOpp: kNucleos[Random(seed).nextInt(kNucleos.length)],
          deckYou: deckYou,
          deckOpp: Deck.starter(),
          rng: seed != null ? Random(seed) : Random(),
        );

  @override
  MatchPhase get phase => kPhases[phaseIdx];

  // ---- MatchView: reenvío al engine (lectura) ----
  @override
  int get round => engine.round;
  @override
  List<CardInstance> get handYou => engine.handYou;
  @override
  List<CardInstance?> get subs => engine.subs;
  @override
  CardInstance? get active => engine.active;
  @override
  Play? get oppPlay => engine.oppPlay;
  @override
  RoundResult? get result => engine.result;
  @override
  NucleoDef get nucYou => engine.nucYou;
  @override
  NucleoDef get nucOpp => engine.nucOpp;
  @override
  int get integrityYou => engine.integrityYou;
  @override
  int get integrityOpp => engine.integrityOpp;
  @override
  int get ramMax => engine.ramMax;
  @override
  int get ramLeft => engine.ramLeft;
  @override
  bool subCabe(CardInstance s) => engine.subCabe(s);
  @override
  int get rutPileYou => engine.rutPileYou;
  @override
  int get subPileYou => engine.subPileYou;
  @override
  int get acquiredN => engine.acquiredN;
  @override
  int get acquiredRut => engine.acquiredRut;
  @override
  int get acquiredSub => engine.acquiredSub;
  @override
  bool get needsNullDeclaration => engine.needsNullDeclaration;
  @override
  bool get canCompile => engine.canCompile;
  @override
  bool get gameOver => engine.gameOver;
  @override
  String? get outcome => engine.outcome;
  @override
  String get oppName => 'proc_0x4F';

  @override
  void placeActive(CardInstance c) {
    if (phase.id != 'programacion') return;
    engine.placeActive(c);
    notifyListeners();
  }

  @override
  void placeSub(CardInstance c, int idx) {
    if (phase.id != 'programacion') return;
    if (engine.subs[idx] != null || !engine.subCabe(c)) return;
    engine.placeSub(c, idx);
    notifyListeners();
  }

  @override
  void returnActive() {
    if (phase.id != 'programacion') return;
    engine.returnActive();
    notifyListeners();
  }

  @override
  void returnSub(int idx) {
    if (phase.id != 'programacion') return;
    engine.returnSub(idx);
    notifyListeners();
  }

  @override
  void declareNull(CType t) {
    engine.declareNull(t);
    notifyListeners();
  }

  @override
  void compile() {
    if (!engine.canCompile) return;
    engine.compile(); // CPU programa + resuelve (oculto hasta revelar)
    phaseIdx = 2;
    notifyListeners();
    // La EJECUCIÓN dura según cuántas cartas se jugaron: una "parada" por carta
    // (tú activo+subs, rival activo+subs) + una para el resultado.
    final items = 1 +
        engine.subs.whereType<CardInstance>().length +
        1 +
        engine.oppPlay!.subs.length;
    const execStart = 1900;
    final resultAt = execStart + (items + 1) * kExecStepMs + 300;
    _after(700, () {
      phaseIdx = 3; // REVELACIÓN
      notifyListeners();
    });
    _after(1050, () {
      revealed = true;
      notifyListeners();
    });
    _after(execStart, () {
      phaseIdx = 4; // EJECUCIÓN — la mesa enfoca carta por carta a kExecStepMs
      notifyListeners();
    });
    _after(resultAt, () {
      phaseIdx = 5; // RESULTADO

      engine.applyResult();
      final r = engine.result!;
      history.add(r.winner);
      if (r.winner == Winner.you) {
        hit = (side: 'opp', amount: r.damage);
      } else if (r.winner == Winner.opp) {
        hit = (side: 'you', amount: r.damage);
      }
      notifyListeners();
      if (hit != null) {
        _after(1200, () {
          hit = null;
          notifyListeners();
        });
      }
      if (engine.gameOver) {
        // Pausa amplia para que se vea el último golpe y QUIÉN ganó la ronda/partida.
        _after(2600, () => onFlush(MatchSummary(
              outcome: engine.outcome!,
              round: engine.round,
              history: List.of(history),
            )));
      }
    });
  }

  @override
  void nextRound() {
    if (engine.gameOver) return;
    engine.nextRound();
    phaseIdx = 1;
    revealed = false;
    hit = null;
    showAcquire = engine.acquiredN > 0;
    notifyListeners();
    if (showAcquire) {
      _after(1900, () {
        showAcquire = false;
        notifyListeners();
      });
    }
  }

  void _after(int ms, VoidCallback fn) {
    _timers.add(Timer(Duration(milliseconds: ms), fn));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }
}
