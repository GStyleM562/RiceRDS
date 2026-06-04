import 'package:nodehack_sim/nodehack_sim.dart';
import 'package:test/test.dart';

String _firma(GameLog g) {
  final b = StringBuffer('${g.ganador}|${g.integridadFinalA}|${g.integridadFinalB}|');
  for (final r in g.rondas) {
    b.write('${r.turno}:${r.tipoA.index}${r.tipoB.index}:${r.ganador}:'
        '${r.integridadA}${r.integridadB};');
  }
  return b.toString();
}

void main() {
  test('misma semilla ⇒ partida idéntica', () {
    final g = Game();
    final a = g.play(kMazos['A']!, kMazos['B']!, HeuristicBot(), HeuristicBot(), 777);
    final b = g.play(kMazos['A']!, kMazos['B']!, HeuristicBot(), HeuristicBot(), 777);
    expect(_firma(a), _firma(b));
  });

  test('semillas distintas ⇒ (casi siempre) partidas distintas', () {
    final g = Game();
    final a = g.play(kMazos['C']!, kMazos['D']!, HeuristicBot(), HeuristicBot(), 1);
    final b = g.play(kMazos['C']!, kMazos['D']!, HeuristicBot(), HeuristicBot(), 2);
    // No es garantía absoluta, pero con semillas distintas debería divergir.
    expect(_firma(a) == _firma(b), isFalse);
  });
}
