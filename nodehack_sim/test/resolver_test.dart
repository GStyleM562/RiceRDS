import 'package:nodehack_sim/nodehack_sim.dart';
import 'package:test/test.dart';

PlayerState _ps(int i, NucleoId n) {
  // Mazo base ('A') solo para satisfacer la firma; las manos se setean a mano.
  return PlayerState(i, kMazos['A']!, n);
}

GameState _gs(NucleoId a, NucleoId b) => GameState(_ps(0, a), _ps(1, b));

RoundLog _resolver(GameState gs, Play a, Play b, {int turno = 1, int seed = 1}) {
  return Resolver().resolve(gs, a, b, Rng(seed), turno, 5, 5);
}

Play _p(RutinaId r, Tipo t,
        {List<SubId> subs = const [],
        RotacionObjetivo? rot,
        bool pasiva = false}) =>
    Play(rutina: r, tipoDeclarado: t, subs: subs, rotacionObjetivo: rot, usarPasiva: pasiva);

void main() {
  test('triángulo básico: cortafuegos vence exploit', () {
    final gs = _gs(NucleoId.warden, NucleoId.corrupted);
    final log = _resolver(
      gs,
      _p(RutinaId.cortafuegos, Tipo.cortafuegos),
      _p(RutinaId.exploit, Tipo.exploit),
    );
    expect(log.ganador, 1);
    expect(gs.p1.integridad, 3); // B perdió 1
    expect(gs.p0.integridad, 4);
  });

  test('CUARENTENA anula ⇒ empate (no roba el punto)', () {
    final gs = _gs(NucleoId.warden, NucleoId.relay);
    // B juega pulso (vencería a cortafuegos), pero A lo anula con Cuarentena.
    final log = _resolver(
      gs,
      _p(RutinaId.cortafuegos, Tipo.cortafuegos, subs: [SubId.cuarentena]),
      _p(RutinaId.pulso, Tipo.pulso),
    );
    expect(log.ganador, 0);
    expect(gs.p0.integridad, 4);
    expect(gs.p1.integridad, 4);
  });

  test('espejo decidido por OVERCLOCK (Ciclos)', () {
    final gs = _gs(NucleoId.relay, NucleoId.relay);
    final log = _resolver(
      gs,
      _p(RutinaId.cortafuegos, Tipo.cortafuegos, subs: [SubId.overclock]),
      _p(RutinaId.cortafuegos, Tipo.cortafuegos),
    );
    expect(log.ganador, 1);
    expect(log.ciclosFinalA, 9);
  });

  test('LOOPBACK anula la repetición ⇒ empate', () {
    final gs = _gs(NucleoId.warden, NucleoId.corrupted);
    gs.p1.ultimaRutinaTipo = Tipo.exploit; // B repetirá exploit
    final log = _resolver(
      gs,
      _p(RutinaId.cortafuegos, Tipo.cortafuegos, subs: [SubId.loopback]),
      _p(RutinaId.exploit, Tipo.exploit),
    );
    expect(log.ganador, 0);
    expect(gs.p1.integridad, 4);
  });

  test('ROTACIÓN propia desplaza el tipo un paso', () {
    final gs = _gs(NucleoId.relay, NucleoId.warden);
    // A exploit → rotación → pulso ; pulso vence cortafuegos de B.
    final log = _resolver(
      gs,
      _p(RutinaId.exploit, Tipo.exploit,
          subs: [SubId.rotacion], rot: RotacionObjetivo.propia),
      _p(RutinaId.cortafuegos, Tipo.cortafuegos),
    );
    expect(log.tipoA, Tipo.pulso);
    expect(log.ganador, 1);
  });

  test('SIGKILL cancela las subrutinas del rival (anula su Cuarentena)', () {
    final gs = _gs(NucleoId.relay, NucleoId.warden);
    // B intenta Cuarentena (anularía a A), pero A juega SIGKILL.
    final log = _resolver(
      gs,
      _p(RutinaId.pulso, Tipo.pulso, subs: [SubId.sigkill]),
      _p(RutinaId.cortafuegos, Tipo.cortafuegos, subs: [SubId.cuarentena]),
    );
    expect(log.anuladaA, isFalse); // la Cuarentena de B fue cancelada
    expect(log.ganador, 1); // pulso vence cortafuegos
  });

  test('ZERO-DAY recalienta: −1 RAM la próxima ronda', () {
    final gs = _gs(NucleoId.corrupted, NucleoId.warden);
    _resolver(
      gs,
      _p(RutinaId.zeroDay, Tipo.exploit),
      _p(RutinaId.pulso, Tipo.pulso),
    );
    expect(gs.p0.ramDeltaNext, -1);
  });

  test('FORK-BOMB perdedor recibe −1 extra (apuesta simétrica v0.4)', () {
    final gs = _gs(NucleoId.corrupted, NucleoId.warden);
    // A exploit + fork-bomb pierde contra cortafuegos → −1 (perder) −1 (Fork-Bomb).
    _resolver(
      gs,
      _p(RutinaId.exploit, Tipo.exploit, subs: [SubId.forkBomb]),
      _p(RutinaId.cortafuegos, Tipo.cortafuegos),
    );
    expect(gs.p0.integridad, 2);
  });

  test('CORRUPCIÓN (NULL-CORE v0.4): convierte un empate en victoria (sin bonus −2)', () {
    final gs = _gs(NucleoId.nullCore, NucleoId.warden);
    // Ambos PULSO, Ciclos iguales, ninguno alineado a pulso → empate; A lo convierte.
    final log = _resolver(
      gs,
      _p(RutinaId.pulso, Tipo.pulso, pasiva: true),
      _p(RutinaId.pulso, Tipo.pulso),
    );
    expect(log.ganador, 1);
    expect(gs.p1.integridad, 3); // −1 normal, sin bonus
  });

  test('MURO-BALUARTE es inmune a CUARENTENA (v0.4)', () {
    final gs = _gs(NucleoId.warden, NucleoId.relay);
    final log = _resolver(
      gs,
      _p(RutinaId.muroBaluarte, Tipo.cortafuegos),
      _p(RutinaId.exploit, Tipo.exploit, subs: [SubId.cuarentena]),
    );
    expect(log.anuladaA, isFalse); // no fue anulada
    expect(log.ganador, 1); // cortafuegos vence exploit
  });
}
