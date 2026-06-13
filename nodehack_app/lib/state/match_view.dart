/// Vista abstracta de una partida que consume la mesa de duelo (`match_screen`).
/// La implementan el controlador local (vs CPU) y el de red (PVP), de modo que la
/// misma pantalla sirve para ambos modos sin tocar su lógica de pintado.
library;

import 'package:flutter/foundation.dart';

import 'package:nodehack_engine/card_instance.dart';
import 'package:nodehack_engine/cards.dart';
import 'package:nodehack_engine/resolve.dart';
import 'package:nodehack_engine/types.dart';

/// Ritmo de la fase de EJECUCIÓN: cuánto dura el foco de cada carta jugada antes
/// de pasar a la siguiente (la mesa enfoca la carta y muestra su línea de log).
/// La duración total de la ejecución se calcula a partir de esto y del nº de
/// cartas jugadas, tanto en el controlador (tiempos) como en la mesa (spotlight).
const int kExecStepMs = 800;

/// Resumen de fin de partida que se entrega a la pantalla de resultados.
class MatchSummary {
  final String outcome; // 'win' | 'lose'
  final int round;
  final List<Winner> history; // ganador de cada ronda
  final String? reason; // null = normal; 'opp_left' = rival se rindió/desconectó
  const MatchSummary({
    required this.outcome,
    required this.round,
    required this.history,
    this.reason,
  });
}

/// Fase visual de la ronda (progreso + textos de ayuda).
class MatchPhase {
  final String id;
  final String label;
  final String hint;
  const MatchPhase(this.id, this.label, this.hint);
}

const List<MatchPhase> kPhases = [
  MatchPhase('robo', 'ROBO', 'Se roban procesos a la mano.'),
  MatchPhase('programacion', 'PROGRAMACIÓN',
      'Arrastra una Rutina al puesto activo. Añade Subrutinas si tienes RAM.'),
  MatchPhase('compilar', 'COMPILAR', 'Confirmas tu jugada. Queda sellada.'),
  MatchPhase('revelacion', 'REVELACIÓN', 'Ambos procesos se revelan a la vez.'),
  MatchPhase('ejecucion', 'EJECUCIÓN', 'El triángulo y los Ciclos resuelven el conflicto.'),
  MatchPhase('resultado', 'RESULTADO', 'Se aplica el daño a la integridad.'),
];

/// Interfaz que la mesa de duelo lee. `Listenable` para repintar con AnimatedBuilder.
abstract class MatchView implements Listenable {
  // Fase / progreso
  MatchPhase get phase;
  int get phaseIdx;
  bool get revealed;

  // Estado de la ronda
  int get round;
  List<CardInstance> get handYou;
  List<CardInstance?> get subs; // longitud 2
  CardInstance? get active;
  Play? get oppPlay;
  RoundResult? get result;

  // Núcleos / integridad
  NucleoDef get nucYou;
  NucleoDef get nucOpp;
  int get integrityYou;
  int get integrityOpp;
  // Máximos EFECTIVOS (base del núcleo ± modificadores de Historia): el HUD
  // dibuja los pips contra estos y señala la diferencia con la base.
  int get integrityMaxYou;
  int get integrityMaxOpp;

  // RAM
  int get ramMax;
  int get ramLeft;
  bool subCabe(CardInstance s);

  // Pilas / adquisición
  int get rutPileYou;
  int get subPileYou;
  int get acquiredN;
  int get acquiredRut;
  int get acquiredSub;
  bool get showAcquire;

  // NULL-SHARD
  bool get needsNullDeclaration;
  bool get canCompile;

  // Daño / historial (alimentan animaciones)
  ({String side, int amount})? get hit;
  List<Winner> get history;

  // Aviso transitorio sobre la mesa (online: rival desconectado, conexión
  // perdida…). null = sin aviso.
  String? get notice;

  // Fin de partida
  bool get gameOver;
  String? get outcome; // 'win' | 'lose' cuando gameOver; null si sigue

  // Nombre del rival (para mensajes/animaciones). 'RIVAL' por defecto.
  String get oppName;

  // Acciones del jugador
  void placeActive(CardInstance c);
  void placeSub(CardInstance c, int idx);
  void returnActive();
  void returnSub(int idx);
  void declareNull(CType t);
  void compile();
  void nextRound();
}
