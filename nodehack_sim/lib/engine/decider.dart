/// Interfaz de decisión (lo que un jugador —bot o humano— ve y devuelve).
///
/// REGLA DE ORO: la `PublicView` **NO** contiene la mano del rival. Es imposible
/// hacer trampa por construcción (refleja la regla §1.6 del PLAN; Probe baneada).
library;

import 'models.dart';
import 'rng.dart';

class PublicView {
  final int yo; // 0 o 1
  final int turno;

  // Mi información (privada, solo mía).
  final List<RutinaId> miMano;
  final List<SubId> miSubs;
  final int miIntegridad;
  final int ramDisponible;
  final bool pasivaDisponible;
  final NucleoId miNucleo;

  // Información PÚBLICA del rival.
  final int rivalIntegridad;
  final NucleoId rivalNucleo;
  final Tipo? rivalUltimoTipo; // lo que el rival jugó la ronda anterior (revelado)
  final List<Tipo> rivalHistorialTipos; // todos los tipos revelados del rival
  final List<Tipo> miHistorialTipos;

  const PublicView({
    required this.yo,
    required this.turno,
    required this.miMano,
    required this.miSubs,
    required this.miIntegridad,
    required this.ramDisponible,
    required this.pasivaDisponible,
    required this.miNucleo,
    required this.rivalIntegridad,
    required this.rivalNucleo,
    required this.rivalUltimoTipo,
    required this.rivalHistorialTipos,
    required this.miHistorialTipos,
  });
}

/// Un decisor elige su jugada secreta a partir de su vista pública.
abstract class Decider {
  String get nombre;
  Play decide(PublicView view, Rng rng);
}
