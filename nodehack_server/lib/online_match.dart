/// Partida autoritativa de DOS humanos. El servidor es la fuente de verdad:
/// gestiona las pilas/robo (reusando `Deck`), valida cada jugada (carta en mano,
/// RAM, ≤2 subrutinas, NULL declarado) y resuelve con `resolve()` del motor
/// compartido → el cliente no puede falsificar el resultado.
///
/// Simétrica: los jugadores son `p[0]` y `p[1]` (sin "you/opp" fijo). Para cada
/// jugador se calcula su propia perspectiva (resolve es puro y determinista, así
/// que se ejecuta dos veces y cada quien recibe su `RoundResult` bien redactado).
library;

import 'dart:math';

import 'package:nodehack_engine/nodehack_engine.dart';

// kMaxHand viene del motor compartido (match_engine.dart) — misma regla que vs CPU.

class PlayerState {
  final NucleoDef nuc;
  final Deck deck;
  final PileSet piles; // robo + descarte que se rebaraja reciclando (no duplica)
  int integrity;

  final List<CardInstance> hand = [];

  // Jugada programada de la ronda actual.
  CardInstance? active;
  final List<CardInstance> playSubs = [];
  bool submitted = false;

  // Adquisición de la última ronda (insignia "+N").
  int acquiredN = 0, acquiredRut = 0, acquiredSub = 0;

  // Pasivas / efectos diferidos.
  bool sentinelUsed = false; // BLINDAJE (una vez por partida)
  bool wraithNext = false; // INYECCIÓN → +1 sub próxima ronda
  int ramPen = 0; // ZERO-DAY/EMP-BURST/IRON-WALL → −1 RAM próxima ronda
  bool empAgainst = false; // EMP-BURST rival → −1 sub próxima ronda
  bool shuffleNext = false; // DESFRAG/FORMATEO → rebaraja la mano próxima ronda

  PlayerState(this.nuc, this.deck, this.piles) : integrity = nuc.integrity;
}

class OnlineMatch {
  final Random rng;
  late final List<PlayerState> p; // longitud 2

  int round = 1;
  bool gameOver = false;
  int? winner; // índice del ganador (0|1) cuando gameOver

  // Resultados de la ronda revelada, uno por jugador (perspectiva propia).
  List<RoundResult>? _results;

  OnlineMatch({
    required NucleoDef nuc0,
    required Deck deck0,
    required NucleoDef nuc1,
    required Deck deck1,
    Random? rng,
  })  : rng = rng ?? Random() {
    p = [
      PlayerState(nuc0, deck0, PileSet(deck0, this.rng)),
      PlayerState(nuc1, deck1, PileSet(deck1, this.rng)),
    ];
    _acquire(0, 2, 3);
    _acquire(1, 2, 3);
  }

  /// Roba [nR] Rutinas + [nS] Subrutinas a la mano de `p[i]`, garantiza ≥1 Rutina
  /// y ≥1 Subrutina, y respeta el tope [kMaxHand] (los sobrantes van al descarte
  /// del propio mazo: se reciclan, no se duplican ni se pierden).
  void _acquire(int i, int nR, int nS) {
    final s = p[i];
    var gotR = 0, gotS = 0;
    void takeRut() {
      final c = s.piles.drawRut();
      if (c != null) {
        s.hand.add(c);
        gotR++;
      }
    }

    void takeSub() {
      final c = s.piles.drawSub();
      if (c != null) {
        s.hand.add(c);
        gotS++;
      }
    }

    for (var k = 0; k < nR; k++) {
      takeRut();
    }
    for (var k = 0; k < nS; k++) {
      takeSub();
    }
    if (!s.hand.any((c) => !c.isSub)) takeRut();
    if (!s.hand.any((c) => c.isSub)) takeSub();

    while (s.hand.length > kMaxHand) {
      final rut = s.hand.where((c) => !c.isSub).length;
      final sub = s.hand.length - rut;
      if (rut >= sub && rut > 1) {
        s.piles.discard(s.hand.removeAt(s.hand.indexWhere((c) => !c.isSub)));
      } else if (sub > 1) {
        s.piles.discard(s.hand.removeAt(s.hand.lastIndexWhere((c) => c.isSub)));
      } else {
        break;
      }
    }
    s.acquiredN = gotR + gotS;
    s.acquiredRut = gotR;
    s.acquiredSub = gotS;
  }

  // ---------------- RAM ----------------
  int ramMaxFor(PlayerState s, CardInstance? activeCard) {
    var ram = s.nuc.ram - s.ramPen;
    if (activeCard != null) {
      if (s.nuc.passiveId == PassiveId.resonancia && activeCard.type == CType.signal) ram += 1;
      if (s.nuc.passiveId == PassiveId.corrupcion && activeCard.esComodinNull) ram += 1;
    }
    return ram < 0 ? 0 : ram;
  }

  // ---------------- Programación (validación autoritativa) ----------------
  CardInstance? _findInHand(PlayerState s, String uid, {required bool wantSub}) {
    for (final c in s.hand) {
      if (c.uid == uid && c.isSub == wantSub) return c;
    }
    return null;
  }

  /// Registra la jugada de `p[i]`. Devuelve `null` si es válida, o un mensaje de
  /// error si la rechaza (carta inexistente, RAM insuficiente, etc.).
  String? submitPlay(int i, PlaySubmission sub) {
    if (gameOver) return 'partida terminada';
    final s = p[i];
    if (s.submitted) return 'ya enviaste tu jugada';

    final rut = _findInHand(s, sub.rutinaUid, wantSub: false);
    if (rut == null) return 'rutina inválida';
    if (rut.esComodinNull) {
      if (sub.declaredType == null) return 'declara el tipo del NULL-SHARD';
      if (sub.declaredType == CType.nul) return 'tipo declarado inválido';
    }
    if (sub.subUids.length > 2) return 'máximo 2 subrutinas';

    final subs = <CardInstance>[];
    for (final uid in sub.subUids) {
      if (subs.any((x) => x.uid == uid)) return 'subrutina duplicada';
      final card = _findInHand(s, uid, wantSub: true);
      if (card == null) return 'subrutina inválida';
      subs.add(card);
    }

    // Declara el tipo antes de medir RAM (resonancia/corrupción dependen del tipo).
    rut.declaredType = rut.esComodinNull ? sub.declaredType : null;
    final ramMax = ramMaxFor(s, rut);
    final ramUsed = subs.fold<int>(0, (a, x) => a + x.ram);
    if (ramUsed > ramMax) {
      rut.declaredType = null;
      return 'RAM insuficiente';
    }

    // Compromete la jugada: saca las cartas de la mano.
    s.hand.removeWhere((c) => c.uid == rut.uid || subs.any((x) => x.uid == c.uid));
    s.active = rut;
    s.playSubs
      ..clear()
      ..addAll(subs);
    s.submitted = true;
    return null;
  }

  /// Jugada por defecto (timeout): primera Rutina de la mano, sin subrutinas.
  PlaySubmission defaultSubmissionFor(int i) {
    final rut = p[i].hand.firstWhere((c) => !c.isSub);
    return PlaySubmission(
      rutinaUid: rut.uid,
      declaredType: rut.esComodinNull ? CType.firewall : null,
    );
  }

  bool get bothSubmitted => p[0].submitted && p[1].submitted;

  // ---------------- Resolución ----------------
  /// Resuelve la ronda (requiere ambas jugadas). Aplica daño/pasivas y detecta
  /// fin de partida. Tras esto, `resultFor(i)` da el resultado de cada jugador.
  void resolveRound() {
    final play0 = Play(p[0].active!, List.of(p[0].playSubs));
    final play1 = Play(p[1].active!, List.of(p[1].playSubs));
    // resolve es puro: cada jugador recibe su perspectiva ("you" = él mismo).
    _results = [resolve(play0, play1), resolve(play1, play0)];
    _applyCanonical(_results![0]);
  }

  /// Aplica el resultado canónico (perspectiva de p[0]) a integridad y pasivas.
  void _applyCanonical(RoundResult r) {
    // Subrutinas anuladas por SIGKILL/CONTRAVIRUS del rival no aplican efectos.
    bool annuls(Iterable<CardInstance> s) => s.any((c) => c.sub?.id == 'sigkill' || c.sub?.id == 'st_purge');
    final p0Annulled = annuls(p[1].playSubs);
    final p1Annulled = annuls(p[0].playSubs);
    bool p0(String id) => !p0Annulled && p[0].playSubs.any((s) => s.sub?.id == id);
    bool p1(String id) => !p1Annulled && p[1].playSubs.any((s) => s.sub?.id == id);
    void heal(int i, int d) => p[i].integrity = (p[i].integrity + d).clamp(0, p[i].nuc.integrity);
    final p0Won = r.winner == Winner.you, p1Won = r.winner == Winner.opp;

    // Daño base — BASTIÓN del perdedor lo anula.
    if (r.winner == Winner.you) {
      if (!p1('st_bastion')) _damage(1, r.damage); // p[1] perdió
    } else if (r.winner == Winner.opp) {
      if (!p0('st_bastion')) _damage(0, r.damage); // p[0] perdió
    }

    // PARCHE / PARCHE.Ω — cura al ganar; PARCHE además daña 1 extra al perder.
    if (p0Won && (p0('patch') || p0('patch_pro'))) {
      heal(0, 1);
    } else if (p1Won && p0('patch')) {
      heal(0, -1);
    }
    if (p1Won && (p1('patch') || p1('patch_pro'))) {
      heal(1, 1);
    } else if (p0Won && p1('patch')) {
      heal(1, -1);
    }

    // DESFRAG (al perdedor) / FORMATEO (solo si pierde el rival) → rebaraja la mano.
    if (p0('shuffle_loser') || p1('shuffle_loser')) {
      if (p1Won) p[0].shuffleNext = true; // p[0] perdió
      if (p0Won) p[1].shuffleNext = true; // p[1] perdió
    }
    if (p0('shuffle_opp') && p0Won) p[1].shuffleNext = true;
    if (p1('shuffle_opp') && p1Won) p[0].shuffleNext = true;

    // INYECCIÓN (WRAITH): ganar con EXPLOIT → +1 sub la próxima ronda.
    if (r.winner == Winner.you &&
        p[0].nuc.passiveId == PassiveId.inyeccion &&
        p[0].active!.type == CType.exploit) {
      p[0].wraithNext = true;
    }
    if (r.winner == Winner.opp &&
        p[1].nuc.passiveId == PassiveId.inyeccion &&
        p[1].active!.type == CType.exploit) {
      p[1].wraithNext = true;
    }
    // EMP-BURST: el ganador con pl_emp hace que el rival robe 1 menos.
    if (r.winner == Winner.you && p[0].active!.rut?.id == 'pl_emp') p[1].empAgainst = true;
    if (r.winner == Winner.opp && p[1].active!.rut?.id == 'pl_emp') p[0].empAgainst = true;
    // Variantes con coste: −1 RAM la próxima ronda (ZERO-DAY, EMP-BURST, IRON-WALL).
    const ramPenRut = {'xp_zero', 'pl_emp', 'fw_iron'};
    p[0].ramPen = ramPenRut.contains(p[0].active!.rut?.id) ? 1 : 0;
    p[1].ramPen = ramPenRut.contains(p[1].active!.rut?.id) ? 1 : 0;

    if (p[0].integrity <= 0 || p[1].integrity <= 0) {
      gameOver = true;
      winner = p[0].integrity <= 0 ? 1 : 0;
    }
  }

  void _damage(int i, int amount) {
    if (amount <= 0) return;
    final s = p[i];
    if (s.nuc.passiveId == PassiveId.blindaje && !s.sentinelUsed) {
      s.sentinelUsed = true;
      // Nota en ambos registros, con la redacción de cada perspectiva.
      _results?[i].log.add('BLINDAJE (tú) → anula el daño');
      _results?[1 - i].log.add('BLINDAJE (rival) → anula el daño');
      return;
    }
    s.integrity = (s.integrity - amount).clamp(0, s.nuc.integrity);
  }

  RoundResult resultFor(int i) => _results![i];

  /// Avanza a la siguiente ronda: limpia jugadas, aplica WRAITH/EMP y reparte.
  void advanceRound() {
    if (gameOver) return;
    round += 1;
    for (final s in p) {
      // Lo jugado esta ronda vuelve al descarte del propio mazo (se recicla).
      if (s.active != null) s.piles.discard(s.active!);
      for (final c in s.playSubs) {
        s.piles.discard(c);
      }
      s.active = null;
      s.playSubs.clear();
      s.submitted = false;
    }
    _results = null;
    for (var i = 0; i < 2; i++) {
      var nSub = 2;
      if (p[i].wraithNext) {
        nSub += 1;
        p[i].wraithNext = false;
      }
      if (p[i].empAgainst) {
        nSub -= 1;
        p[i].empAgainst = false;
      }
      // DESFRAG/FORMATEO: descarta la mano entera y roba una nueva.
      if (p[i].shuffleNext) {
        for (final c in List.of(p[i].hand)) {
          p[i].piles.discard(c);
        }
        p[i].hand.clear();
        p[i].shuffleNext = false;
      }
      _acquire(i, 2, nSub.clamp(0, 4));
    }
  }

  // ---------------- Vistas por jugador ----------------
  List<CardInstance> handOf(int i) => p[i].hand;

  /// RAM base de la ronda (sin bonus por carta activa) — el cliente le suma el
  /// bonus de RESONANCIA/CORRUPCIÓN al elegir su Rutina. El servidor valida la real.
  int ramBaseFor(int i) => ramMaxFor(p[i], null);

  Play playOf(int i) => Play(p[i].active!, List.of(p[i].playSubs));

  PublicState publicStateFor(int i) {
    final me = p[i], op = p[1 - i];
    return PublicState(
      round: round,
      integrityYou: me.integrity,
      integrityOpp: op.integrity,
      integrityMaxYou: me.nuc.integrity,
      integrityMaxOpp: op.nuc.integrity,
      nucYouId: me.nuc.id,
      nucOppId: op.nuc.id,
      rutPileYou: me.piles.rutLeft,
      subPileYou: me.piles.subLeft,
      rutPileOpp: op.piles.rutLeft,
      subPileOpp: op.piles.subLeft,
      gameOver: gameOver,
      outcome: gameOver ? (winner == i ? 'win' : 'lose') : null,
    );
  }
}
