// Round-trips JSON de los DTOs de red: lo que sale por el cable y vuelve debe ser
// idéntico (mismo uid, mismo tipo, mismo resultado) en cliente y servidor.
import 'dart:convert';

import 'package:test/test.dart';
import 'package:nodehack_engine/card_instance.dart';
import 'package:nodehack_engine/cards.dart';
import 'package:nodehack_engine/dto.dart';
import 'package:nodehack_engine/resolve.dart';
import 'package:nodehack_engine/types.dart';

/// Pasa por encode/decode real para detectar tipos no serializables.
Map<String, dynamic> wire(Map<String, dynamic> j) =>
    jsonDecode(jsonEncode(j)) as Map<String, dynamic>;

void main() {
  group('CardInstance', () {
    test('Rutina round-trip conserva uid, defId y tipo', () {
      final c = CardInstance.rutina(kRutById['fw_iron']!);
      final back = CardInstance.fromJson(wire(c.toJson()));
      expect(back.uid, c.uid);
      expect(back.defId, 'fw_iron');
      expect(back.isSub, isFalse);
      expect(back.type, CType.firewall);
    });

    test('NULL-SHARD conserva el tipo declarado', () {
      final c = CardInstance.rutina(kRutById['null_sh']!)..declaredType = CType.signal;
      final back = CardInstance.fromJson(wire(c.toJson()));
      expect(back.esComodinNull, isTrue);
      expect(back.declaredType, CType.signal);
      expect(back.type, CType.signal);
    });

    test('Subrutina round-trip', () {
      final c = CardInstance.subrutina(kSubById['sigkill']!);
      final back = CardInstance.fromJson(wire(c.toJson()));
      expect(back.uid, c.uid);
      expect(back.isSub, isTrue);
      expect(back.defId, 'sigkill');
      expect(back.ram, 3);
    });
  });

  group('Play', () {
    test('round-trip con subs', () {
      final p = Play(
        CardInstance.rutina(kRutById['xp_base']!),
        [CardInstance.subrutina(kSubById['overclock']!), CardInstance.subrutina(kSubById['throttle']!)],
      );
      final back = Play.fromJson(wire(p.toJson()));
      expect(back.rutina.uid, p.rutina.uid);
      expect(back.subs.map((s) => s.defId), ['overclock', 'throttle']);
    });
  });

  group('RoundResult', () {
    test('round-trip preserva ganador, ciclos, tipos, log y daño', () {
      final r = resolve(
        Play(CardInstance.rutina(kRutById['fw_base']!), [CardInstance.subrutina(kSubById['forkbomb']!)]),
        Play(CardInstance.rutina(kRutById['xp_base']!), const []),
      );
      final back = RoundResult.fromJson(wire(r.toJson()));
      expect(back.winner, r.winner);
      expect(back.youCiclos, r.youCiclos);
      expect(back.oppCiclos, r.oppCiclos);
      expect(back.youType, r.youType);
      expect(back.oppType, r.oppType);
      expect(back.damage, r.damage);
      expect(back.log, r.log);
    });

    test('flipped() invierte la perspectiva (you↔opp)', () {
      final r = resolve(
        Play(CardInstance.rutina(kRutById['fw_base']!), const []), // firewall vence exploit
        Play(CardInstance.rutina(kRutById['xp_base']!), const []),
      );
      expect(r.winner, Winner.you);
      final f = r.flipped();
      expect(f.winner, Winner.opp); // para el rival, el ganador soy "yo (opp)"
      expect(f.youType, r.oppType);
      expect(f.oppType, r.youType);
      expect(f.youCiclos, r.oppCiclos);
      expect(f.damage, r.damage); // el daño es el mismo número
    });
  });

  group('PlaySubmission', () {
    test('round-trip con tipo declarado y subs', () {
      final s = PlaySubmission(rutinaUid: 'c42', declaredType: CType.exploit, subUids: ['c1', 'c2']);
      final back = PlaySubmission.fromJson(wire(s.toJson()));
      expect(back.rutinaUid, 'c42');
      expect(back.declaredType, CType.exploit);
      expect(back.subUids, ['c1', 'c2']);
    });

    test('sin tipo declarado ni subs', () {
      final back = PlaySubmission.fromJson(wire(PlaySubmission(rutinaUid: 'c7').toJson()));
      expect(back.declaredType, isNull);
      expect(back.subUids, isEmpty);
    });
  });

  group('PublicState', () {
    PublicState sample() => PublicState(
          round: 3,
          integrityYou: 2, integrityOpp: 4,
          integrityMaxYou: 4, integrityMaxOpp: 4,
          nucYouId: 'wraith', nucOppId: 'sentinel',
          rutPileYou: 8, subPileYou: 17, rutPileOpp: 9, subPileOpp: 18,
          gameOver: false,
        );

    test('round-trip', () {
      final back = PublicState.fromJson(wire(sample().toJson()));
      expect(back.round, 3);
      expect(back.integrityYou, 2);
      expect(back.nucOppId, 'sentinel');
      expect(back.subPileOpp, 18);
      expect(back.gameOver, isFalse);
      expect(back.outcome, isNull);
    });

    test('flipped() intercambia you↔opp e invierte el outcome', () {
      final s = PublicState(
        round: 5, integrityYou: 0, integrityOpp: 3,
        integrityMaxYou: 4, integrityMaxOpp: 4,
        nucYouId: 'echo', nucOppId: 'nullkey',
        rutPileYou: 1, subPileYou: 2, rutPileOpp: 3, subPileOpp: 4,
        gameOver: true, outcome: 'lose',
      );
      final f = s.flipped();
      expect(f.integrityYou, 3);
      expect(f.integrityOpp, 0);
      expect(f.nucYouId, 'nullkey');
      expect(f.rutPileYou, 3);
      expect(f.subPileOpp, 2);
      expect(f.outcome, 'win');
    });
  });

  group('mano', () {
    test('handToJson/handFromJson round-trip conserva orden y uids', () {
      final hand = [
        CardInstance.rutina(kRutById['fw_base']!),
        CardInstance.subrutina(kSubById['mirror']!),
        CardInstance.rutina(kRutById['null_sh']!)..declaredType = CType.firewall,
      ];
      final back = handFromJson(jsonDecode(jsonEncode(handToJson(hand))) as List);
      expect(back.length, 3);
      expect(back.map((c) => c.uid), hand.map((c) => c.uid));
      expect(back[2].declaredType, CType.firewall);
    });
  });
}
