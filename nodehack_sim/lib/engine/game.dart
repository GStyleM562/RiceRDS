/// Orquestador de una partida completa: reparto, RAM por ronda, Sobrecarga,
/// adquisición (robo estándar), Hotfix, pasiva RELAY, tope de mano, victoria.
library;

import 'data.dart';
import 'decider.dart';
import 'models.dart';
import 'resolver.dart';
import 'rng.dart';
import 'state.dart';

class Game {
  final Resolver _resolver = Resolver();
  static const int _maxRondas = 40;

  GameLog play(Deck deckA, Deck deckB, Decider da, Decider db, int semilla) {
    final rng = Rng(semilla);
    final p0 = PlayerState(0, deckA, deckA.nucleo);
    final p1 = PlayerState(1, deckB, deckB.nucleo);
    _iniciar(p0, rng);
    _iniciar(p1, rng);
    final gs = GameState(p0, p1);

    final log = GameLog(deckA.id, deckB.id, p0.nucleo, p1.nucleo, semilla);
    var deficitMax0 = 0, deficitMax1 = 0;

    while (p0.integridad > 0 && p1.integridad > 0 && gs.turno < _maxRondas) {
      gs.turno++;
      final t = gs.turno;

      // Sobrecarga: robo extra de subrutina si vas 3+ por debajo (antes de programar).
      if (p1.integridad - p0.integridad >= 3) p0.robarSub(rng);
      if (p0.integridad - p1.integridad >= 3) p1.robarSub(rng);

      // Red de seguridad: siempre debe haber una Rutina jugable.
      if (p0.manoRutinas.isEmpty) p0.robarRutina(rng);
      if (p1.manoRutinas.isEmpty) p1.robarRutina(rng);

      final ram0 = _ramDe(p0, p1, t);
      final ram1 = _ramDe(p1, p0, t);
      p0.ramDeltaNext = 0;
      p1.ramDeltaNext = 0;

      final play0 = _saneado(p0, da.decide(_vista(p0, p1, t, ram0), rng), ram0);
      final play1 = _saneado(p1, db.decide(_vista(p1, p0, t, ram1), rng), ram1);

      _quitarDeMano(p0, play0);
      _quitarDeMano(p1, play1);

      final round = _resolver.resolve(gs, play0, play1, rng, t, ram0, ram1);
      log.rondas.add(round);

      _aDescarte(p0, play0);
      _aDescarte(p1, play1);
      p0.ultimaRutinaTipo = play0.tipoDeclarado;
      p1.ultimaRutinaTipo = play1.tipoDeclarado;
      p0.historialTipos.add(play0.tipoDeclarado);
      p1.historialTipos.add(play1.tipoDeclarado);

      final relay0 = play0.usarPasiva && !p0.pasivaUsada && p0.nucleo == NucleoId.relay;
      final relay1 = play1.usarPasiva && !p1.pasivaUsada && p1.nucleo == NucleoId.relay;
      if (play0.usarPasiva) p0.pasivaUsada = true;
      if (play1.usarPasiva) p1.pasivaUsada = true;

      // Adquisición: la Rutina obligatoria SIEMPRE se roba; HOTFIX del rival solo
      // niega las 2 Subrutinas (evita dejar al rival sin jugada — clarificación v0.3-sim).
      final noRoba = _noRobaIndices(round);
      _robar(p0, rng, relay0, robaSubs: !noRoba.contains(0));
      _robar(p1, rng, relay1, robaSubs: !noRoba.contains(1));
      _recortarMano(p0);
      _recortarMano(p1);

      if (round.muerteSubita) log.muerteSubita = true;
      final d0 = p1.integridad - p0.integridad;
      final d1 = p0.integridad - p1.integridad;
      if (d0 > deficitMax0) deficitMax0 = d0;
      if (d1 > deficitMax1) deficitMax1 = d1;
    }

    log.integridadFinalA = p0.integridad;
    log.integridadFinalB = p1.integridad;
    if (p0.integridad <= 0 && p1.integridad <= 0) {
      log.ganador = p0.integridad == p1.integridad
          ? 0
          : (p0.integridad > p1.integridad ? 1 : 2);
    } else if (p1.integridad <= 0) {
      log.ganador = 1;
    } else if (p0.integridad <= 0) {
      log.ganador = 2;
    } else {
      log.ganador = 0; // alcanzó el tope de rondas (no debería)
    }
    log.remontada = (log.ganador == 1 && deficitMax0 >= 2) ||
        (log.ganador == 2 && deficitMax1 >= 2);
    return log;
  }

  void _iniciar(PlayerState ps, Rng rng) {
    ps.integridad = 4;
    ps.mazoRutinas.addAll(ps.deck.rutinas);
    ps.mazoSubs.addAll(ps.deck.subrutinas);
    rng.shuffle(ps.mazoRutinas);
    rng.shuffle(ps.mazoSubs);
    for (var i = 0; i < 2; i++) ps.robarRutina(rng);
    for (var i = 0; i < 3; i++) ps.robarSub(rng);
  }

  int _ramDe(PlayerState me, PlayerState rival, int turno) {
    var ram = (turno + 1).clamp(2, 5); // R1=2..R4+=5
    ram += me.ramDeltaNext;
    if (rival.integridad - me.integridad >= 1) ram += 1; // Sobrecarga
    return ram < 0 ? 0 : ram;
  }

  PublicView _vista(PlayerState me, PlayerState rival, int turno, int ram) {
    return PublicView(
      yo: me.index,
      turno: turno,
      miMano: List.of(me.manoRutinas),
      miSubs: List.of(me.manoSubs),
      miIntegridad: me.integridad,
      ramDisponible: ram,
      pasivaDisponible: !me.pasivaUsada,
      miNucleo: me.nucleo,
      rivalIntegridad: rival.integridad,
      rivalNucleo: rival.nucleo,
      rivalUltimoTipo: rival.ultimaRutinaTipo,
      rivalHistorialTipos: List.of(rival.historialTipos),
      miHistorialTipos: List.of(me.historialTipos),
    );
  }

  /// Garantiza que la jugada sea legal (rutina en mano, subs en mano, coste ≤ RAM,
  /// ≤2 subs, tipo correcto, pasiva disponible). Si no, hace una jugada base.
  Play _saneado(PlayerState ps, Play p, int ram) {
    if (!ps.manoRutinas.contains(p.rutina)) {
      return Play(rutina: ps.manoRutinas.first, tipoDeclarado: _tipoBase(ps.manoRutinas.first, p));
    }
    final r = rutinaDe(p.rutina);
    final tipo = r.esComodin ? p.tipoDeclarado : r.tipoBase!;

    final disponibles = List.of(ps.manoSubs);
    final usadas = <SubId>[];
    var coste = 0;
    for (final s in p.subs) {
      if (usadas.length >= 2) break;
      if (!disponibles.remove(s)) continue;
      final c = subDe(s).costeRam;
      if (coste + c > ram) continue;
      coste += c;
      usadas.add(s);
    }
    final pasiva = p.usarPasiva && !ps.pasivaUsada;
    return Play(
      rutina: p.rutina,
      tipoDeclarado: tipo,
      subs: usadas,
      rotacionObjetivo: p.rotacionObjetivo,
      usarPasiva: pasiva,
    );
  }

  Tipo _tipoBase(RutinaId id, Play p) {
    final r = rutinaDe(id);
    return r.esComodin ? p.tipoDeclarado : r.tipoBase!;
  }

  void _quitarDeMano(PlayerState ps, Play p) {
    ps.manoRutinas.remove(p.rutina);
    for (final s in p.subs) ps.manoSubs.remove(s);
  }

  void _aDescarte(PlayerState ps, Play p) {
    ps.descarteRutinas.add(p.rutina);
    ps.descarteSubs.addAll(p.subs);
  }

  Set<int> _noRobaIndices(RoundLog round) {
    final set = <int>{};
    for (final n in round.notas) {
      if (n.startsWith('__NOROBA__')) {
        set.add(int.parse(n.substring('__NOROBA__'.length)));
      }
    }
    return set;
  }

  void _robar(PlayerState ps, Rng rng, bool relayExtra, {bool robaSubs = true}) {
    ps.robarRutina(rng);
    if (relayExtra) ps.robarRutina(rng);
    if (robaSubs) {
      ps.robarSub(rng);
      ps.robarSub(rng);
    }
  }

  void _recortarMano(PlayerState ps) {
    while (ps.manoRutinas.length + ps.manoSubs.length > 8) {
      if (ps.manoSubs.isNotEmpty) {
        ps.descarteSubs.add(ps.manoSubs.removeLast());
      } else if (ps.manoRutinas.length > 1) {
        ps.descarteRutinas.add(ps.manoRutinas.removeLast());
      } else {
        break;
      }
    }
  }
}
