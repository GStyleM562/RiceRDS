import 'package:nodehack_sim/nodehack_sim.dart';
import 'package:test/test.dart';

/// Registra cada PublicView que recibe, para verificar que NO hay fuga de info oculta.
class _CapturingBot implements Decider {
  final Decider inner;
  final List<PublicView> vistas = [];
  _CapturingBot(this.inner);

  @override
  String get nombre => 'capture:${inner.nombre}';

  @override
  Play decide(PublicView view, Rng rng) {
    vistas.add(view);
    return inner.decide(view, rng);
  }
}

void main() {
  test('la vista del bot no expone información oculta del rival', () {
    final cap = _CapturingBot(HeuristicBot());
    Game().play(kMazos['A']!, kMazos['B']!, cap, HeuristicBot(), 2026);

    expect(cap.vistas, isNotEmpty);

    // Ronda 1: el rival aún no reveló nada.
    final v1 = cap.vistas.first;
    expect(v1.turno, 1);
    expect(v1.rivalUltimoTipo, isNull);
    expect(v1.rivalHistorialTipos, isEmpty);

    // En cada ronda, el historial del rival = solo rondas ya reveladas (público),
    // nunca su mano actual oculta.
    for (final v in cap.vistas) {
      expect(v.rivalHistorialTipos.length, v.turno - 1,
          reason: 'el bot ve más tipos del rival que rondas reveladas');
    }
  });
}
