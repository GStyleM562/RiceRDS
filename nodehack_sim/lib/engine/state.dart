/// Estado mutable de partida + estructuras de log.
library;

import 'data.dart';
import 'models.dart';
import 'rng.dart';

class PlayerState {
  final int index; // 0 o 1
  final Deck deck;
  final NucleoId nucleo;

  int integridad = 4;

  final List<RutinaId> manoRutinas = [];
  final List<SubId> manoSubs = [];
  final List<RutinaId> mazoRutinas = [];
  final List<SubId> mazoSubs = [];
  final List<RutinaId> descarteRutinas = [];
  final List<SubId> descarteSubs = [];

  /// Tipo de la Rutina que jugó la ronda anterior (para LOOPBACK).
  Tipo? ultimaRutinaTipo;

  /// Historial público de tipos jugados (revelados) — lo usan los bots para leer.
  final List<Tipo> historialTipos = [];

  bool pasivaUsada = false;

  /// Modificadores de RAM para la PRÓXIMA ronda
  /// (Broadcast +2, Pulso-Echo +1, Buffer +1, Zero-Day −1).
  int ramDeltaNext = 0;

  PlayerState(this.index, this.deck, this.nucleo);

  Tipo? get alineacion => nucleoDe(nucleo).alineacion;

  void _rellenarRutinasSiHaceFalta(Rng rng) {
    if (mazoRutinas.isEmpty && descarteRutinas.isNotEmpty) {
      mazoRutinas.addAll(descarteRutinas);
      descarteRutinas.clear();
      rng.shuffle(mazoRutinas);
    }
  }

  void _rellenarSubsSiHaceFalta(Rng rng) {
    if (mazoSubs.isEmpty && descarteSubs.isNotEmpty) {
      mazoSubs.addAll(descarteSubs);
      descarteSubs.clear();
      rng.shuffle(mazoSubs);
    }
  }

  RutinaId? robarRutina(Rng rng) {
    _rellenarRutinasSiHaceFalta(rng);
    if (mazoRutinas.isEmpty) return null;
    final c = mazoRutinas.removeLast();
    manoRutinas.add(c);
    return c;
  }

  SubId? robarSub(Rng rng) {
    _rellenarSubsSiHaceFalta(rng);
    if (mazoSubs.isEmpty) return null;
    final c = mazoSubs.removeLast();
    manoSubs.add(c);
    return c;
  }
}

/// Log estructurado de una ronda (para imprimir legible y para stats).
class RoundLog {
  final int turno;
  final int ramA;
  final int ramB;

  // Jugadas crudas.
  late Tipo tipoA;
  late Tipo tipoB;
  late RutinaId rutinaA;
  late RutinaId rutinaB;
  List<SubId> subsA = const [];
  List<SubId> subsB = const [];

  // Estado tras resolución.
  int ciclosFinalA = 0;
  int ciclosFinalB = 0;
  bool anuladaA = false;
  bool anuladaB = false;
  bool invertido = false;

  /// 0 empate, 1 gana A, 2 gana B.
  int ganador = 0;
  int danioA = 0;
  int danioB = 0;
  bool muerteSubita = false;
  int integridadA = 0;
  int integridadB = 0;

  final List<String> pasos = [];
  final List<String> notas = [];

  RoundLog(this.turno, this.ramA, this.ramB);
}

/// Log completo de una partida.
class GameLog {
  final String deckA;
  final String deckB;
  final NucleoId nucleoA;
  final NucleoId nucleoB;
  final int semilla;
  final List<RoundLog> rondas = [];

  /// 0 empate (no debería), 1 gana A, 2 gana B.
  int ganador = 0;
  int integridadFinalA = 0;
  int integridadFinalB = 0;

  /// Estadística: ¿el ganador estuvo alguna vez 2+ de Integridad por debajo? (remontada).
  bool remontada = false;
  bool muerteSubita = false;

  GameLog(this.deckA, this.deckB, this.nucleoA, this.nucleoB, this.semilla);

  int get rondasJugadas => rondas.length;
}

class GameState {
  final PlayerState p0;
  final PlayerState p1;
  int turno = 0;

  GameState(this.p0, this.p1);

  PlayerState jugador(int i) => i == 0 ? p0 : p1;
}
