import 'dart:math';

import 'package:test/test.dart';
import 'package:nodehack_engine/card_instance.dart';
import 'package:nodehack_engine/cards.dart';
import 'package:nodehack_engine/deck.dart';
import 'package:nodehack_engine/match_engine.dart';
import 'package:nodehack_engine/pile_set.dart';
import 'package:nodehack_engine/resolve.dart';
import 'package:nodehack_engine/types.dart';

CardInstance _rut(String id, {CType? declared}) {
  final c = CardInstance.rutina(kRutById[id]!);
  c.declaredType = declared;
  return c;
}

CardInstance _sub(String id) => CardInstance.subrutina(kSubById[id]!);

Play _p(CardInstance r, [List<CardInstance> subs = const []]) => Play(r, subs);

Play _build(String rid, CType? declared, List<String> subs) =>
    Play(_rut(rid, declared: declared), [for (final s in subs) _sub(s)]);

String _descPlay(Play p) =>
    '${p.rutina.rut?.id}${p.rutina.declaredType != null ? "(${p.rutina.declaredType!.short})" : ""}'
    '+[${p.subs.map((s) => s.sub?.id).join(",")}]';

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

    test('el log registra los efectos del RIVAL (no solo los tuyos)', () {
      // El rival juega OVERCLOCK en un espejo: debe constar en TU log y ganar él.
      final r = resolve(_p(_rut('fw_base')), _p(_rut('fw_base'), [_sub('overclock')]));
      expect(r.winner, Winner.opp); // rival 5+4=9 vs tus 5
      expect(r.log.any((l) => l.contains('OVERCLOCK') && l.contains('rival')), isTrue);
    });

    test('INTRUSIÓN del RIVAL desplaza TU Rutina y queda en el log', () {
      // El rival te aplica INTRUSIÓN: tu CORTAFUEGOS → exploit (firewall.next).
      final r = resolve(_p(_rut('fw_base')), _p(_rut('xp_base'), [_sub('shift_fwd')]));
      expect(r.youType, CType.exploit);
      expect(r.log.any((l) => l.contains('INTRUSIÓN') && l.contains('rival')), isTrue);
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

  group('reciclado de mazo (límite de copias)', () {
    test('PileSet recicla: jamás produce más copias que las del mazo', () {
      final deck = Deck(name: 'X', nucleoId: 'sentinel', rut: {'pl_base': 3, 'fw_base': 7}, sub: {'overclock': 20});
      final piles = PileSet(deck, Random(1));
      final seen = <String, Set<String>>{};
      // Roba MUCHÍSIMAS más rutinas que las del mazo, descartando cada una.
      for (var i = 0; i < 200; i++) {
        final c = piles.drawRut();
        expect(c, isNotNull);
        (seen[c!.defId] ??= <String>{}).add(c.uid);
        piles.discard(c);
      }
      expect(seen['pl_base']!.length, 3); // solo 3 instancias de PULSO, siempre
      expect(seen['fw_base']!.length, 7);
    });

    test('en partida completa nunca aparecen más copias de una carta que las del mazo', () {
      final deck = Deck(
        name: 'COPIAS',
        nucleoId: 'sentinel',
        rut: {'pl_base': 3, 'fw_base': 3, 'xp_base': 3, 'pl_emp': 1},
        sub: {'overclock': 5, 'throttle': 5, 'cuarentena': 5, 'mirror': 5},
      );
      expect(deck.isLegal, isTrue);
      for (var seed = 0; seed < 25; seed++) {
        final m = MatchEngine(
          nucYou: kNucById['sentinel']!,
          nucOpp: kNucById['wraith']!,
          deckYou: deck,
          deckOpp: Deck.starter(),
          rng: Random(seed),
        );
        final seen = <String, Set<String>>{};
        var guard = 0;
        while (!m.gameOver && guard++ < 300) {
          for (final c in m.handYou) {
            (seen[c.defId] ??= <String>{}).add(c.uid);
          }
          final r = m.handYou.firstWhere((c) => !c.isSub);
          if (r.esComodinNull) r.declaredType = CType.firewall;
          m.placeActive(r);
          m.compile();
          m.applyResult();
          if (!m.gameOver) m.nextRound();
        }
        deck.rut.forEach((id, count) {
          expect((seen[id] ?? const {}).length, lessThanOrEqualTo(count),
              reason: 'semilla $seed: rutina $id superó $count copias');
        });
        deck.sub.forEach((id, count) {
          expect((seen[id] ?? const {}).length, lessThanOrEqualTo(count),
              reason: 'semilla $seed: sub $id superó $count copias');
        });
      }
    });
  });

  group('resolución correcta y consistente (auditoría del CAOS)', () {
    // Todas las jugadas posibles: cada Rutina (con NULL declarado a sus 3 tipos)
    // × 0, 1 o 2 Subrutinas distintas (el tope real del juego).
    List<Play> _allPlays() {
      final rutCfgs = <(String, CType?)>[
        ('fw_base', null), ('fw_iron', null),
        ('xp_base', null), ('xp_zero', null),
        ('pl_base', null), ('pl_emp', null),
        ('null_sh', CType.firewall), ('null_sh', CType.exploit), ('null_sh', CType.signal),
      ];
      final subIds = kSubrutinas.map((s) => s.id).toList();
      final combos = <List<String>>[const []];
      for (final s in subIds) {
        combos.add([s]);
      }
      for (var i = 0; i < subIds.length; i++) {
        for (var j = i + 1; j < subIds.length; j++) {
          combos.add([subIds[i], subIds[j]]);
        }
      }
      return [
        for (final (rid, dt) in rutCfgs)
          for (final c in combos) _build(rid, dt, c),
      ];
    }

    test('CONSISTENCIA: el ganador desde ambos lados SIEMPRE coincide (todas las combinaciones)', () {
      final plays = _allPlays(); // resolve() no muta las cartas → se pueden reusar
      var pairs = 0;
      for (final a in plays) {
        for (final b in plays) {
          final r1 = resolve(a, b); // perspectiva de A
          final r2 = resolve(b, a); // perspectiva de B
          // Si A gana desde su vista, B DEBE perder desde la suya (y viceversa).
          expect(r1.winner, flipWinner(r2.winner),
              reason: 'INCONSISTENCIA\n  A=${_descPlay(a)}\n  B=${_descPlay(b)}\n'
                  '  resolve(A,B).winner=${r1.winner}  resolve(B,A).winner=${r2.winner}');
          // El daño es el mismo número visto desde cualquier lado.
          expect(r1.damage, r2.damage,
              reason: 'daño distinto: A=${_descPlay(a)} B=${_descPlay(b)}');
          // Un empate nunca aplica daño.
          if (r1.winner == Winner.draw) expect(r1.damage, 0);
          pairs++;
        }
      }
      expect(pairs, plays.length * plays.length);
    });

    test('CORRECCIÓN: caos de desplazamientos da el ganador correcto', () {
      // Tú PULSO(5) + AVANCE(→firewall) + OVERCLOCK(+4) ⇒ firewall, 9.
      // Rival CORTAFUEGOS(5). Espejo firewall ⇒ 9 vs 5 ⇒ ganas tú.
      final r = resolve(
        _build('pl_base', null, ['shift_you_fwd', 'overclock']),
        _build('fw_base', null, const []),
      );
      expect(r.youType, CType.firewall);
      expect(r.youCiclos, 9);
      expect(r.winner, Winner.you);

      // El rival te SABOTEA (firewall→signal) y tú lo INTRUSIONas (su exploit→signal):
      // ambos signal ⇒ deciden Ciclos. fw_base(5, básica→signal=5) vs xp_base(5,→signal 5) ⇒ empate.
      final r2 = resolve(
        _build('fw_base', null, ['shift_fwd']), // tu INTRUSIÓN mueve al rival
        _build('xp_base', null, ['shift_opp_back']), // SABOTAJE del rival te mueve a ti
      );
      // Tú: fw → signal (por SABOTAJE rival). Rival: xp → signal (por tu INTRUSIÓN).
      expect(r2.youType, CType.signal);
      expect(r2.oppType, CType.signal);
      expect(r2.winner, Winner.draw); // espejo 5 vs 5
    });

    test('CONSISTENCIA bajo SIGKILL (anula las subrutinas del otro)', () {
      final plays = _allPlays();
      // Comprobación extra centrada en SIGKILL combinado con desplazamientos.
      final sk = [
        _build('fw_base', null, ['sigkill', 'shift_fwd']),
        _build('xp_base', null, ['sigkill']),
        _build('pl_base', null, ['shift_back', 'sigkill']),
      ];
      for (final a in sk) {
        for (final b in plays) {
          expect(resolve(a, b).winner, flipWinner(resolve(b, a).winner),
              reason: 'SIGKILL A=${_descPlay(a)} B=${_descPlay(b)}');
        }
      }
    });
  });
}
