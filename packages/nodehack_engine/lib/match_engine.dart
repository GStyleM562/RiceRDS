/// Motor de partida (puro): fases, RAM por núcleo, **pilas de robo reales que se
/// agotan**, mano persistente con adquisición por ronda, CPU sin ver tu mano, pasivas.
library;

import 'dart:math';

import 'card_instance.dart';
import 'cards.dart';
import 'cpu.dart';
import 'deck.dart';
import 'resolve.dart';
import 'types.dart';

const int kMaxHand = 9;

class MatchEngine {
  final NucleoDef nucYou;
  final NucleoDef nucOpp;
  final Deck deckYou;
  final Deck deckOpp;
  final Random rng;
  final Cpu _cpu = Cpu();

  int round = 1;
  int integrityYou;
  int integrityOpp;

  // Pilas de robo (se agotan; se rebarajan desde el mazo si se vacían).
  final List<CardInstance> _rutYou = [];
  final List<CardInstance> _subYou = [];
  final List<CardInstance> _rutOpp = [];
  final List<CardInstance> _subOpp = [];

  final List<CardInstance> handYou = [];
  final List<CardInstance> _handOpp = []; // OCULTA — nunca se expone a la UI

  CardInstance? active;
  final List<CardInstance?> subs = [null, null];

  Play? oppPlay;
  RoundResult? result;

  // Adquisición de la última ronda (para la insignia "+N").
  int acquiredN = 0, acquiredRut = 0, acquiredSub = 0;

  // Pasivas / efectos diferidos.
  bool _sentinelUsedYou = false, _sentinelUsedOpp = false;
  bool _wraithNextYou = false, _wraithNextOpp = false;
  int _ramPenYou = 0, _ramPenOpp = 0;
  bool _empAgainstYou = false, _empAgainstOpp = false;

  bool gameOver = false;
  String? outcome; // 'win' | 'lose'

  MatchEngine({
    required this.nucYou,
    required this.nucOpp,
    required this.deckYou,
    required this.deckOpp,
    Random? rng,
  })  : integrityYou = nucYou.integrity,
        integrityOpp = nucOpp.integrity,
        rng = rng ?? Random() {
    _refillRut(_rutYou, deckYou);
    _refillSub(_subYou, deckYou);
    _refillRut(_rutOpp, deckOpp);
    _refillSub(_subOpp, deckOpp);
    // Mano inicial: 2 Rutinas + 3 Subrutinas.
    _acquire(handYou, _rutYou, _subYou, deckYou, 2, 3, isYou: true);
    _acquire(_handOpp, _rutOpp, _subOpp, deckOpp, 2, 3, isYou: false);
  }

  // ---- Conteos de pila (para la UI) ----
  int get rutPileYou => _rutYou.length;
  int get subPileYou => _subYou.length;
  int get rutPileOpp => _rutOpp.length;
  int get subPileOpp => _subOpp.length;

  void _refillRut(List<CardInstance> pile, Deck d) {
    pile.addAll(d.buildRutinas());
    pile.shuffle(rng);
  }

  void _refillSub(List<CardInstance> pile, Deck d) {
    pile.addAll(d.buildSubs());
    pile.shuffle(rng);
  }

  CardInstance _drawRut(List<CardInstance> pile, Deck d) {
    if (pile.isEmpty) _refillRut(pile, d);
    return pile.removeLast();
  }

  CardInstance _drawSub(List<CardInstance> pile, Deck d) {
    if (pile.isEmpty) _refillSub(pile, d);
    return pile.removeLast();
  }

  /// Roba [nR] Rutinas + [nS] Subrutinas a [hand] desde las pilas. Garantiza ≥1
  /// Rutina en mano y respeta el tope [kMaxHand] (descarta Subrutinas sobrantes).
  void _acquire(List<CardInstance> hand, List<CardInstance> rutPile,
      List<CardInstance> subPile, Deck d, int nR, int nS, {required bool isYou}) {
    var gotR = 0, gotS = 0;
    for (var i = 0; i < nR; i++) {
      hand.add(_drawRut(rutPile, d));
      gotR++;
    }
    for (var i = 0; i < nS; i++) {
      hand.add(_drawSub(subPile, d));
      gotS++;
    }
    if (!hand.any((c) => !c.isSub)) {
      hand.add(_drawRut(rutPile, d)); // ≥1 Rutina (para poder jugar)
      gotR++;
    }
    if (!hand.any((c) => c.isSub)) {
      hand.add(_drawSub(subPile, d)); // ≥1 Subrutina (evita manos de "puras Rutinas")
      gotS++;
    }
    // Tope balanceado: descarta del tipo MÁS abundante (nunca baja de 1 de cada uno).
    while (hand.length > kMaxHand) {
      final rut = hand.where((c) => !c.isSub).length;
      final sub = hand.length - rut;
      if (rut >= sub && rut > 1) {
        hand.removeAt(hand.indexWhere((c) => !c.isSub));
      } else if (sub > 1) {
        hand.removeAt(hand.lastIndexWhere((c) => c.isSub));
      } else {
        break;
      }
    }
    if (isYou) {
      acquiredN = gotR + gotS;
      acquiredRut = gotR;
      acquiredSub = gotS;
    }
  }

  // ---- RAM ----
  int ramMaxFor(NucleoDef n, CardInstance? activeCard, int penalty) {
    var ram = n.ram - penalty;
    if (activeCard != null) {
      if (n.passiveId == PassiveId.resonancia && activeCard.type == CType.signal) ram += 1;
      if (n.passiveId == PassiveId.corrupcion && activeCard.esComodinNull) ram += 1;
    }
    return ram < 0 ? 0 : ram;
  }

  int get ramMax => ramMaxFor(nucYou, active, _ramPenYou);
  int get ramUsed => subs.fold(0, (a, s) => a + (s?.ram ?? 0));
  int get ramLeft => ramMax - ramUsed;

  bool subCabe(CardInstance s) => s.ram <= ramLeft;

  void placeActive(CardInstance c) {
    if (active != null && active!.uid != c.uid) {
      active!.declaredType = null;
      handYou.add(active!); // la carta anterior regresa a la mano (no se pierde)
    }
    handYou.removeWhere((x) => x.uid == c.uid);
    active = c;
  }

  void placeSub(CardInstance c, int idx) {
    if (subs[idx] != null && subs[idx]!.uid != c.uid) {
      handYou.add(subs[idx]!); // la carta anterior regresa a la mano
    }
    handYou.removeWhere((x) => x.uid == c.uid);
    subs[idx] = c;
  }

  void returnActive() {
    if (active != null) {
      active!.declaredType = null;
      handYou.add(active!);
      active = null;
    }
  }

  void returnSub(int idx) {
    final c = subs[idx];
    if (c != null) {
      handYou.add(c);
      subs[idx] = null;
    }
  }

  void declareNull(CType t) => active?.declaredType = t;

  bool get needsNullDeclaration =>
      active != null && active!.esComodinNull && active!.declaredType == null;

  bool get canCompile => active != null && !needsNullDeclaration && !gameOver;

  void compile() {
    if (!canCompile) return;
    final you = Play(active!, subs.whereType<CardInstance>().toList());
    oppPlay = _cpuChoose();
    result = resolve(you, oppPlay!);
  }

  Play _cpuChoose() {
    final tentativa = _cpu.chooseFor(_handOpp, ramMaxFor(nucOpp, null, _ramPenOpp), rng);
    // Quita de la mano del rival lo que va a jugar (consumo real).
    _handOpp.removeWhere((c) => c.uid == tentativa.rutina.uid);
    final ramReal = ramMaxFor(nucOpp, tentativa.rutina, _ramPenOpp);
    final subsValidas = <CardInstance>[];
    var left = ramReal;
    for (final s in tentativa.subs) {
      if (s.ram <= left) {
        subsValidas.add(s);
        left -= s.ram;
        _handOpp.removeWhere((c) => c.uid == s.uid);
      }
    }
    return Play(tentativa.rutina, subsValidas);
  }

  void applyResult() {
    final r = result;
    if (r == null) return;

    if (r.winner == Winner.you) {
      _danar(opp: true, amount: r.damage);
    } else if (r.winner == Winner.opp) {
      _danar(opp: false, amount: r.damage);
    }

    if (r.winner == Winner.you &&
        nucYou.passiveId == PassiveId.inyeccion &&
        active!.type == CType.exploit) {
      _wraithNextYou = true;
    }
    if (r.winner == Winner.opp &&
        nucOpp.passiveId == PassiveId.inyeccion &&
        oppPlay!.rutina.type == CType.exploit) {
      _wraithNextOpp = true;
    }
    if (r.winner == Winner.you && active!.rut?.id == 'pl_emp') _empAgainstOpp = true;
    if (r.winner == Winner.opp && oppPlay!.rutina.rut?.id == 'pl_emp') _empAgainstYou = true;

    _ramPenYou = active!.rut?.id == 'xp_zero' ? 1 : 0;
    _ramPenOpp = oppPlay!.rutina.rut?.id == 'xp_zero' ? 1 : 0;

    if (integrityYou <= 0 || integrityOpp <= 0) {
      gameOver = true;
      outcome = integrityOpp <= 0 ? 'win' : 'lose';
    }
  }

  void _danar({required bool opp, required int amount}) {
    if (amount <= 0) return;
    if (opp) {
      if (nucOpp.passiveId == PassiveId.blindaje && !_sentinelUsedOpp) {
        _sentinelUsedOpp = true;
        result?.log.add('BLINDAJE rival anula el daño');
        return;
      }
      integrityOpp = (integrityOpp - amount).clamp(0, nucOpp.integrity);
    } else {
      if (nucYou.passiveId == PassiveId.blindaje && !_sentinelUsedYou) {
        _sentinelUsedYou = true;
        result?.log.add('BLINDAJE anula el daño');
        return;
      }
      integrityYou = (integrityYou - amount).clamp(0, nucYou.integrity);
    }
  }

  /// Avanza de ronda: descarta la jugada, adquiere cartas hasta llenar la mano.
  void nextRound() {
    if (gameOver) return;
    round += 1;
    active = null;
    subs[0] = null;
    subs[1] = null;
    oppPlay = null;
    result = null;

    // Robo por defecto: +2 Rutinas + 2 Subrutinas (pasivas WRAITH +1 sub / EMP −1).
    var subYou = 2, subOpp = 2;
    if (_wraithNextYou) {
      subYou += 1;
      _wraithNextYou = false;
    }
    if (_empAgainstYou) {
      subYou -= 1;
      _empAgainstYou = false;
    }
    if (_wraithNextOpp) {
      subOpp += 1;
      _wraithNextOpp = false;
    }
    if (_empAgainstOpp) {
      subOpp -= 1;
      _empAgainstOpp = false;
    }

    _acquire(handYou, _rutYou, _subYou, deckYou, 2, subYou.clamp(0, 4), isYou: true);
    _acquire(_handOpp, _rutOpp, _subOpp, deckOpp, 2, subOpp.clamp(0, 4), isYou: false);
  }
}
