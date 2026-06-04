import 'dart:math';

import 'package:test/test.dart';
import 'package:nodehack_engine/nodehack_engine.dart';
import 'package:nodehack_server/online_match.dart';

OnlineMatch _match([int seed = 1]) => OnlineMatch(
      nuc0: kNucById['wraith']!,
      deck0: Deck.starter(),
      nuc1: kNucById['sentinel']!,
      deck1: Deck.starter(),
      rng: Random(seed),
    );

void main() {
  group('OnlineMatch · partida completa', () {
    test('jugada por defecto en ambos → siempre termina con un ganador y el perdedor a 0', () {
      for (var seed = 0; seed < 40; seed++) {
        final m = _match(seed);
        var guard = 0;
        while (!m.gameOver && guard++ < 300) {
          // Manos legales en todo momento (≥1 rutina, ≥1 sub, ≤ tope).
          for (var i = 0; i < 2; i++) {
            expect(m.handOf(i).any((c) => !c.isSub), isTrue, reason: 'mano $i sin rutinas');
            expect(m.handOf(i).any((c) => c.isSub), isTrue, reason: 'mano $i sin subrutinas');
            expect(m.handOf(i).length, lessThanOrEqualTo(kMaxHand));
          }
          expect(m.submitPlay(0, m.defaultSubmissionFor(0)), isNull);
          expect(m.submitPlay(1, m.defaultSubmissionFor(1)), isNull);
          expect(m.bothSubmitted, isTrue);
          m.resolveRound();
          if (!m.gameOver) m.advanceRound();
        }
        expect(m.gameOver, isTrue, reason: 'semilla $seed no terminó');
        expect(m.winner, anyOf(0, 1));
        expect(m.p[0].integrity == 0 || m.p[1].integrity == 0, isTrue);
      }
    });
  });

  group('OnlineMatch · perspectivas', () {
    test('resultFor(0) y resultFor(1) son espejo', () {
      final m = _match(7);
      expect(m.submitPlay(0, m.defaultSubmissionFor(0)), isNull);
      expect(m.submitPlay(1, m.defaultSubmissionFor(1)), isNull);
      m.resolveRound();
      final r0 = m.resultFor(0), r1 = m.resultFor(1);
      expect(r0.winner, flipWinner(r1.winner));
      expect(r0.youType, r1.oppType);
      expect(r0.oppType, r1.youType);
      expect(r0.youCiclos, r1.oppCiclos);
    });

    test('publicStateFor intercambia you↔opp y no incluye la mano rival', () {
      final m = _match(3);
      final ps0 = m.publicStateFor(0), ps1 = m.publicStateFor(1);
      expect(ps0.integrityYou, ps1.integrityOpp);
      expect(ps0.nucYouId, ps1.nucOppId);
      expect(ps0.rutPileYou, ps1.rutPileOpp);
      // PublicState sólo lleva CONTEOS de pila, nunca cartas → imposible espiar la mano.
      expect(ps0.toJson().containsKey('hand'), isFalse);
    });
  });

  group('OnlineMatch · validación autoritativa (anti-trampa)', () {
    test('rechaza una rutina que no está en la mano', () {
      final m = _match(1);
      expect(m.submitPlay(0, PlaySubmission(rutinaUid: 'fantasma')), isNotNull);
    });

    test('rechaza usar una Subrutina como Rutina y viceversa', () {
      final m = _match(1);
      final sub = m.handOf(0).firstWhere((c) => c.isSub);
      expect(m.submitPlay(0, PlaySubmission(rutinaUid: sub.uid)), 'rutina inválida');
    });

    test('rechaza más de 2 subrutinas', () {
      final deck = Deck(name: 'S', nucleoId: 'sentinel', rut: {'fw_base': 10}, sub: {'overclock': 20});
      final m = OnlineMatch(
          nuc0: kNucById['sentinel']!, deck0: deck,
          nuc1: kNucById['sentinel']!, deck1: Deck.starter(), rng: Random(1));
      final rut = m.handOf(0).firstWhere((c) => !c.isSub);
      final subs = m.handOf(0).where((c) => c.isSub).map((c) => c.uid).toList();
      expect(subs.length, greaterThanOrEqualTo(3));
      expect(m.submitPlay(0, PlaySubmission(rutinaUid: rut.uid, subUids: subs.take(3).toList())),
          'máximo 2 subrutinas');
    });

    test('rechaza RAM insuficiente', () {
      // SENTINEL: 5 RAM. Dos subrutinas de coste 3 = 6 > 5 → rechazo.
      final deck = Deck(name: 'R', nucleoId: 'sentinel', rut: {'fw_base': 10}, sub: {'sigkill': 10, 'forkbomb': 10});
      final m = OnlineMatch(
          nuc0: kNucById['sentinel']!, deck0: deck,
          nuc1: kNucById['sentinel']!, deck1: Deck.starter(), rng: Random(1));
      final rut = m.handOf(0).firstWhere((c) => !c.isSub);
      final subs = m.handOf(0).where((c) => c.isSub).take(2).map((c) => c.uid).toList();
      expect(subs.length, 2);
      expect(m.submitPlay(0, PlaySubmission(rutinaUid: rut.uid, subUids: subs)), 'RAM insuficiente');
    });

    test('exige declarar el tipo del NULL-SHARD', () {
      final deck = Deck(name: 'N', nucleoId: 'nullkey', rut: {'null_sh': 10}, sub: {'overclock': 20});
      final m = OnlineMatch(
          nuc0: kNucById['nullkey']!, deck0: deck,
          nuc1: kNucById['sentinel']!, deck1: Deck.starter(), rng: Random(1));
      final rut = m.handOf(0).firstWhere((c) => !c.isSub);
      expect(rut.esComodinNull, isTrue);
      expect(m.submitPlay(0, PlaySubmission(rutinaUid: rut.uid)), 'declara el tipo del NULL-SHARD');
      expect(m.submitPlay(0, PlaySubmission(rutinaUid: rut.uid, declaredType: CType.firewall)), isNull);
    });

    test('rechaza doble envío en la misma ronda', () {
      final m = _match(1);
      expect(m.submitPlay(0, m.defaultSubmissionFor(0)), isNull);
      expect(m.submitPlay(0, m.defaultSubmissionFor(0)), 'ya enviaste tu jugada');
    });

    test('la jugada comprometida sale de la mano (no se puede reusar)', () {
      final m = _match(5);
      final before = m.handOf(0).length;
      final rut = m.handOf(0).firstWhere((c) => !c.isSub);
      expect(m.submitPlay(0, PlaySubmission(rutinaUid: rut.uid)), isNull);
      expect(m.handOf(0).any((c) => c.uid == rut.uid), isFalse);
      expect(m.handOf(0).length, before - 1);
    });
  });
}
