import 'dart:math';

import 'package:test/test.dart';
import 'package:nodehack_engine/card_instance.dart';
import 'package:nodehack_engine/cards.dart';
import 'package:nodehack_engine/deck.dart';
import 'package:nodehack_engine/match_engine.dart';
import 'package:nodehack_engine/resolve.dart';
import 'package:nodehack_engine/types.dart';

CardInstance _rut(String id, {CType? declared}) {
  final c = CardInstance.rutina(kRutById[id]!);
  c.declaredType = declared;
  return c;
}

CardInstance _sub(String id) => CardInstance.subrutina(kSubById[id]!);

Play _p(CardInstance r, [List<CardInstance> subs = const []]) => Play(r, subs);

void main() {
  group('resolve / triángulo', () {
    test('CORTAFUEGOS vence a EXPLOIT', () {
      final r = resolve(_p(_rut('fw_base')), _p(_rut('xp_base')));
      expect(r.winner, Winner.you);
      expect(r.damage, 1);
    });

    test('espejo decidido por Ciclos (ZERO-DAY 9 vs EXPLOIT 5)', () {
      final r = resolve(_p(_rut('xp_zero')), _p(_rut('xp_base')));
      expect(r.winner, Winner.you);
    });

    test('OVERCLOCK gana el espejo', () {
      final r = resolve(_p(_rut('fw_base'), [_sub('overclock')]), _p(_rut('fw_base')));
      expect(r.winner, Winner.you);
      expect(r.youCiclos, 9);
    });

    test('CUARENTENA fuerza empate', () {
      // PULSO vencería a CORTAFUEGOS, pero hay Cuarentena.
      final r = resolve(_p(_rut('fw_base'), [_sub('cuarentena')]), _p(_rut('pl_base')));
      expect(r.winner, Winner.draw);
      expect(r.damage, 0);
    });

    test('SIGKILL anula la CUARENTENA rival', () {
      final you = _p(_rut('fw_base'), [_sub('sigkill')]);
      final opp = _p(_rut('xp_base'), [_sub('cuarentena')]);
      final r = resolve(you, opp);
      expect(r.winner, Winner.you); // cuarentena anulada → firewall vence exploit
    });

    test('FORK-BOMB suma +1 daño al ganar', () {
      final r = resolve(_p(_rut('fw_base'), [_sub('forkbomb')]), _p(_rut('xp_base')));
      expect(r.winner, Winner.you);
      expect(r.damage, 2);
    });

    test('NULL-SHARD declarado juega como su tipo declarado', () {
      // NULL-SHARD declarado PULSO vence a CORTAFUEGOS.
      final r = resolve(_p(_rut('null_sh', declared: CType.signal)), _p(_rut('fw_base')));
      expect(r.winner, Winner.you);
    });

    test('INTRUSIÓN ▸ mueve al rival al tipo siguiente y respeta nivel avanzado', () {
      // Rival IRON-WALL (firewall avanzada, 7). INTRUSIÓN → exploit avanzada → 9 Ciclos.
      final r = resolve(_p(_rut('xp_base'), [_sub('shift_fwd')]), _p(_rut('fw_iron')));
      expect(r.oppType, CType.exploit);
      expect(r.oppCiclos, 9); // ZERO-DAY (avanzada exploit)
      expect(r.winner, Winner.opp); // espejo EXPLOIT 5 vs 9 → gana rival
    });

    test('◂ RECALIBRAR mueve TU Rutina al tipo anterior (respeta nivel)', () {
      // Tú IRON-WALL (firewall avanzada). RECALIBRAR → signal avanzada (8). Vence a firewall del rival.
      final r = resolve(_p(_rut('fw_iron'), [_sub('shift_back')]), _p(_rut('fw_base')));
      expect(r.youType, CType.signal);
      expect(r.youCiclos, 8); // EMP-BURST (avanzada signal)
      expect(r.winner, Winner.you); // PULSO vence CORTAFUEGOS
    });

    test('◂ SABOTAJE mueve al rival al tipo anterior (respeta nivel)', () {
      // Rival IRON-WALL (firewall avanzada). SABOTAJE → signal avanzada (8).
      final r = resolve(_p(_rut('xp_base'), [_sub('shift_opp_back')]), _p(_rut('fw_iron')));
      expect(r.oppType, CType.signal);
      expect(r.oppCiclos, 8);
      expect(r.winner, Winner.you); // EXPLOIT vence PULSO
    });

    test('AVANCE ▸ mueve TU Rutina al tipo siguiente (respeta nivel)', () {
      // Tú IRON-WALL (firewall avanzada). AVANCE → exploit avanzada (9). Vence a PULSO del rival.
      final r = resolve(_p(_rut('fw_iron'), [_sub('shift_you_fwd')]), _p(_rut('pl_base')));
      expect(r.youType, CType.exploit);
      expect(r.youCiclos, 9); // ZERO-DAY (avanzada exploit)
      expect(r.winner, Winner.you); // EXPLOIT vence PULSO
    });
  });

  group('mazo', () {
    test('el mazo inicial es legal (10/20)', () {
      final d = Deck.starter();
      expect(d.rutCount, 10);
      expect(d.subCount, 20);
      expect(d.isLegal, isTrue);
    });

    test('drawHand siempre incluye ≥1 Rutina', () {
      final d = Deck.starter();
      final rng = Random(1);
      for (var i = 0; i < 50; i++) {
        final hand = d.drawHand(rng);
        expect(hand.any((c) => !c.isSub), isTrue);
      }
    });
  });

  group('partida (CPU sin ver tu mano)', () {
    test('la mano nunca queda sin Subrutinas (ni de puras Rutinas)', () {
      for (var seed = 0; seed < 20; seed++) {
        final m = MatchEngine(
          nucYou: kNucById['wraith']!,
          nucOpp: kNucById['sentinel']!,
          deckYou: Deck.starter(),
          deckOpp: Deck.starter(),
          rng: Random(seed),
        );
        var guard = 0;
        while (!m.gameOver && guard++ < 60) {
          expect(m.handYou.any((c) => c.isSub), isTrue, reason: 'mano sin subrutinas');
          expect(m.handYou.any((c) => !c.isSub), isTrue, reason: 'mano sin rutinas');
          expect(m.handYou.length, lessThanOrEqualTo(kMaxHand));
          final r = m.handYou.firstWhere((c) => !c.isSub);
          if (r.esComodinNull) r.declaredType = CType.firewall;
          m.placeActive(r);
          m.compile();
          m.applyResult();
          if (!m.gameOver) m.nextRound();
        }
      }
    });

    test('una partida siempre termina con un ganador y el perdedor a 0', () {
      for (var seed = 0; seed < 40; seed++) {
        final m = MatchEngine(
          nucYou: kNucById['wraith']!,
          nucOpp: kNucById['sentinel']!,
          deckYou: Deck.starter(),
          deckOpp: Deck.starter(),
          rng: Random(seed),
        );
        var guard = 0;
        while (!m.gameOver && guard++ < 200) {
          // auto-juego del jugador: primera Rutina, sin subrutinas.
          final r = m.handYou.firstWhere((c) => !c.isSub);
          if (r.esComodinNull) r.declaredType = CType.firewall;
          m.placeActive(r);
          m.compile();
          m.applyResult();
          if (!m.gameOver) m.nextRound();
        }
        expect(m.gameOver, isTrue, reason: 'semilla $seed no terminó');
        expect(m.outcome == 'win' || m.outcome == 'lose', isTrue);
        expect(m.integrityYou == 0 || m.integrityOpp == 0, isTrue);
      }
    });

    test('SENTINEL anula la primera pérdida de integridad', () {
      final m = MatchEngine(
        nucYou: kNucById['sentinel']!,
        nucOpp: kNucById['wraith']!,
        deckYou: Deck.starter(),
        deckOpp: Deck.starter(),
        rng: Random(3),
      );
      // Forzamos una derrota de ronda del jugador: PULSO pierde contra EXPLOIT.
      m.active = _rut('pl_base');
      m.oppPlay = _p(_rut('xp_base'));
      m.result = resolve(Play(m.active!, const []), m.oppPlay!);
      expect(m.result!.winner, Winner.opp);
      m.applyResult();
      expect(m.integrityYou, m.nucYou.integrity); // sin pérdida (BLINDAJE)
    });
  });
}
