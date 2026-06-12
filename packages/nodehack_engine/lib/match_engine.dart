/// Motor de partida (puro): fases, RAM por núcleo, **pilas de robo reales que se
/// agotan**, mano persistente con adquisición por ronda, CPU sin ver tu mano, pasivas.
library;

import 'dart:math';

import 'card_instance.dart';
import 'cards.dart';
import 'cpu.dart';
import 'deck.dart';
import 'pile_set.dart';
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

  // Mazo de robo de cada jugador (robo + descarte que se rebaraja reciclando).
  late final PileSet _pilesYou;
  late final PileSet _pilesOpp;

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
  bool _shuffleNextYou = false, _shuffleNextOpp = false; // DESFRAG/FORMATEO

  bool gameOver = false;
  String? outcome; // 'win' | 'lose'

  MatchEngine({
    required this.nucYou,
    required this.nucOpp,
    required this.deckYou,
    required this.deckOpp,
    int integrityYouBonus = 0, // modificadores del modo Historia (caminos infectados, jefes)
    int integrityOppBonus = 0,
    Random? rng,
  })  : integrityYou = (nucYou.integrity + integrityYouBonus).clamp(1, 99),
        integrityOpp = (nucOpp.integrity + integrityOppBonus).clamp(1, 99),
        rng = rng ?? Random() {
    _pilesYou = PileSet(deckYou, this.rng);
    _pilesOpp = PileSet(deckOpp, this.rng);
    // Mano inicial: 2 Rutinas + 3 Subrutinas.
    _acquire(handYou, _pilesYou, 2, 3, isYou: true);
    _acquire(_handOpp, _pilesOpp, 2, 3, isYou: false);
  }

  // ---- Conteos de pila de robo (para la UI) ----
  int get rutPileYou => _pilesYou.rutLeft;
  int get subPileYou => _pilesYou.subLeft;
  int get rutPileOpp => _pilesOpp.rutLeft;
  int get subPileOpp => _pilesOpp.subLeft;

  /// Roba [nR] Rutinas + [nS] Subrutinas a [hand] desde [piles]. Garantiza ≥1
  /// Rutina y ≥1 Subrutina en mano y respeta el tope [kMaxHand] (los sobrantes
  /// van al descarte para reciclarse, no se pierden ni se duplican).
  void _acquire(List<CardInstance> hand, PileSet piles, int nR, int nS, {required bool isYou}) {
    var gotR = 0, gotS = 0;
    void takeRut() {
      final c = piles.drawRut();
      if (c != null) {
        hand.add(c);
        gotR++;
      }
    }

    void takeSub() {
      final c = piles.drawSub();
      if (c != null) {
        hand.add(c);
        gotS++;
      }
    }

    for (var i = 0; i < nR; i++) {
      takeRut();
    }
    for (var i = 0; i < nS; i++) {
      takeSub();
    }
    if (!hand.any((c) => !c.isSub)) takeRut(); // ≥1 Rutina (para poder jugar)
    if (!hand.any((c) => c.isSub)) takeSub(); // ≥1 Subrutina (evita manos de "puras Rutinas")

    // Tope balanceado: descarta del tipo MÁS abundante (nunca baja de 1 de cada uno).
    while (hand.length > kMaxHand) {
      final rut = hand.where((c) => !c.isSub).length;
      final sub = hand.length - rut;
      if (rut >= sub && rut > 1) {
        piles.discard(hand.removeAt(hand.indexWhere((c) => !c.isSub)));
      } else if (sub > 1) {
        piles.discard(hand.removeAt(hand.lastIndexWhere((c) => c.isSub)));
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

    // Subrutinas anuladas por SIGKILL del rival no aplican sus efectos post-resolución.
    final youSubsAnnulled = oppPlay!.subs.any((s) => s.sub?.id == 'sigkill');
    final oppSubsAnnulled = subs.whereType<CardInstance>().any((s) => s.sub?.id == 'sigkill');
    bool youPlayed(String id) =>
        !youSubsAnnulled && subs.whereType<CardInstance>().any((s) => s.sub?.id == id);
    bool oppPlayed(String id) => !oppSubsAnnulled && oppPlay!.subs.any((s) => s.sub?.id == id);

    // PARCHE / PARCHE.Ω — cura al ganar; PARCHE además daña 1 extra al perder.
    if (r.winner == Winner.you && (youPlayed('patch') || youPlayed('patch_pro'))) {
      integrityYou = (integrityYou + 1).clamp(0, nucYou.integrity);
      r.log.add('PARCHE (tú) → +1 de integridad');
    } else if (r.winner == Winner.opp && youPlayed('patch')) {
      integrityYou = (integrityYou - 1).clamp(0, nucYou.integrity);
      r.log.add('PARCHE (tú) → −1 de integridad extra');
    }
    if (r.winner == Winner.opp && (oppPlayed('patch') || oppPlayed('patch_pro'))) {
      integrityOpp = (integrityOpp + 1).clamp(0, nucOpp.integrity);
    } else if (r.winner == Winner.you && oppPlayed('patch')) {
      integrityOpp = (integrityOpp - 1).clamp(0, nucOpp.integrity);
    }

    // DESFRAG (al perdedor) / FORMATEO (solo si pierde el rival) → rebaraja la mano.
    final youLost = r.winner == Winner.opp, oppLost = r.winner == Winner.you;
    if (youPlayed('shuffle_loser') || oppPlayed('shuffle_loser')) {
      if (youLost) _shuffleNextYou = true;
      if (oppLost) _shuffleNextOpp = true;
    }
    if (youPlayed('shuffle_opp') && oppLost) _shuffleNextOpp = true;
    if (oppPlayed('shuffle_opp') && youLost) _shuffleNextYou = true;

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

    // Variantes con coste: −1 RAM la próxima ronda (ZERO-DAY, EMP-BURST, IRON-WALL).
    const ramPenRut = {'xp_zero', 'pl_emp', 'fw_iron'};
    _ramPenYou = ramPenRut.contains(active!.rut?.id) ? 1 : 0;
    _ramPenOpp = ramPenRut.contains(oppPlay!.rutina.rut?.id) ? 1 : 0;

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
        result?.log.add('BLINDAJE (rival) → anula el daño');
        return;
      }
      integrityOpp = (integrityOpp - amount).clamp(0, nucOpp.integrity);
    } else {
      if (nucYou.passiveId == PassiveId.blindaje && !_sentinelUsedYou) {
        _sentinelUsedYou = true;
        result?.log.add('BLINDAJE (tú) → anula el daño');
        return;
      }
      integrityYou = (integrityYou - amount).clamp(0, nucYou.integrity);
    }
  }

  /// Avanza de ronda: descarta la jugada, adquiere cartas hasta llenar la mano.
  void nextRound() {
    if (gameOver) return;
    // Las cartas jugadas esta ronda van al descarte (se reciclan; no se duplican).
    if (active != null) _pilesYou.discard(active!);
    for (final s in subs) {
      if (s != null) _pilesYou.discard(s);
    }
    final op = oppPlay;
    if (op != null) {
      _pilesOpp.discard(op.rutina);
      for (final s in op.subs) {
        _pilesOpp.discard(s);
      }
    }
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

    // DESFRAG/FORMATEO: el lado marcado descarta su mano entera y roba una nueva.
    if (_shuffleNextYou) {
      for (final c in List.of(handYou)) {
        _pilesYou.discard(c);
      }
      handYou.clear();
      _shuffleNextYou = false;
    }
    if (_shuffleNextOpp) {
      for (final c in List.of(_handOpp)) {
        _pilesOpp.discard(c);
      }
      _handOpp.clear();
      _shuffleNextOpp = false;
    }

    _acquire(handYou, _pilesYou, 2, subYou.clamp(0, 4), isYou: true);
    _acquire(_handOpp, _pilesOpp, 2, subOpp.clamp(0, 4), isYou: false);
  }
}
