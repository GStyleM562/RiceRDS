import 'package:nodehack_sim/nodehack_sim.dart';
import 'package:test/test.dart';

void main() {
  group('triángulo base', () {
    test('cortafuegos vence exploit', () {
      expect(venceTipo(Tipo.cortafuegos, Tipo.exploit), isTrue);
      expect(venceTipo(Tipo.exploit, Tipo.cortafuegos), isFalse);
    });
    test('exploit vence pulso', () {
      expect(venceTipo(Tipo.exploit, Tipo.pulso), isTrue);
    });
    test('pulso vence cortafuegos', () {
      expect(venceTipo(Tipo.pulso, Tipo.cortafuegos), isTrue);
    });
    test('inversión voltea el resultado', () {
      expect(venceTipo(Tipo.cortafuegos, Tipo.exploit, invertido: true), isFalse);
      expect(venceTipo(Tipo.exploit, Tipo.cortafuegos, invertido: true), isTrue);
    });
  });

  group('matchup', () {
    int m({
      required Tipo a,
      required Tipo b,
      int ca = 5,
      int cb = 5,
      bool anA = false,
      bool anB = false,
      bool inv = false,
      Tipo? alA,
      Tipo? alB,
    }) =>
        matchup(
          tipoA: a,
          tipoB: b,
          ciclosA: ca,
          ciclosB: cb,
          anuladaA: anA,
          anuladaB: anB,
          invertido: inv,
          alineacionA: alA,
          alineacionB: alB,
        );

    test('anulación ⇒ empate (negación, no robo)', () {
      // B jugaría pulso (vence cortafuegos) pero está anulada ⇒ empate.
      expect(m(a: Tipo.cortafuegos, b: Tipo.pulso, anB: true), 0);
    });
    test('espejo: gana mayor Ciclos', () {
      expect(m(a: Tipo.cortafuegos, b: Tipo.cortafuegos, ca: 9, cb: 5), 1);
      expect(m(a: Tipo.cortafuegos, b: Tipo.cortafuegos, ca: 5, cb: 9), 2);
    });
    test('espejo con Ciclos iguales: decide Núcleo alineado', () {
      expect(
          m(a: Tipo.cortafuegos, b: Tipo.cortafuegos, alA: Tipo.cortafuegos), 1);
      expect(
          m(a: Tipo.cortafuegos, b: Tipo.cortafuegos, alB: Tipo.cortafuegos), 2);
    });
    test('espejo sin alineación ⇒ empate', () {
      expect(m(a: Tipo.pulso, b: Tipo.pulso), 0);
    });
  });
}
