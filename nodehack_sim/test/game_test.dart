import 'package:nodehack_sim/nodehack_sim.dart';
import 'package:test/test.dart';

void main() {
  test('una partida siempre termina con un ganador y el perdedor a 0', () {
    final g = Game();
    for (var seed = 0; seed < 50; seed++) {
      final log = g.play(kMazos['A']!, kMazos['B']!, HeuristicBot(), HeuristicBot(), seed);
      expect(log.ganador == 1 || log.ganador == 2, isTrue,
          reason: 'semilla $seed no produjo ganador');
      if (log.ganador == 1) {
        expect(log.integridadFinalB <= 0, isTrue);
      } else {
        expect(log.integridadFinalA <= 0, isTrue);
      }
      // Con Integridad 4, las partidas deberían durar varias rondas (no instantáneas).
      expect(log.rondasJugadas, greaterThanOrEqualTo(4));
      expect(log.rondasJugadas, lessThan(40));
    }
  });

  test('todos los mazos pueden ganar y perder en un round-robin chico', () {
    final runner = SimRunner();
    final ids = ['A', 'B', 'C', 'D', 'E', 'F'];
    final s = runner.roundRobin(ids, () => HeuristicBot(), games: 60, baseSeed: 99);
    for (final id in ids) {
      expect(s.partidas[id]! > 0, isTrue);
      // nadie debería tener 0% ni 100% en un set sano (señal de carta rota).
      expect(s.winrate(id), greaterThan(0.0), reason: '$id nunca gana');
      expect(s.winrate(id), lessThan(1.0), reason: '$id nunca pierde');
    }
  });
}
