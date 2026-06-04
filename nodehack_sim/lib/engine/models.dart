/// Modelos del motor (Flutter-agnóstico). Reglas v0.3 — ver docs/Cartas_Referencia.md.
library;

/// Los tres tipos del triángulo: CORTAFUEGOS > EXPLOIT > PULSO > CORTAFUEGOS.
enum Tipo { cortafuegos, exploit, pulso }

extension TipoX on Tipo {
  String get simbolo => switch (this) {
        Tipo.cortafuegos => 'CORTAFUEGOS',
        Tipo.exploit => 'EXPLOIT',
        Tipo.pulso => 'PULSO',
      };

  /// Tipo siguiente en el ciclo (lo que usa ROTACIÓN +1).
  Tipo get siguiente => switch (this) {
        Tipo.cortafuegos => Tipo.exploit,
        Tipo.exploit => Tipo.pulso,
        Tipo.pulso => Tipo.cortafuegos,
      };
}

enum Rareza { comun, rara, epica, nullUnica }

enum RutinaId {
  cortafuegos,
  exploit,
  pulso,
  hotfix,
  muroBaluarte,
  zeroDay,
  gusano,
  broadcast,
  pulsoEcho,
  polimorfico,
  nullShard,
}

enum SubId {
  overclock,
  throttle,
  escudo,
  recovery,
  defrag,
  parche,
  cuarentena,
  inversion,
  rotacion,
  fork,
  buffer,
  loopback,
  glitch,
  forkBomb,
  sigkill,
}

enum NucleoId { warden, corrupted, relay, nullCore }

/// Una carta de Acción. `tipoBase == null` ⇒ comodín (se declara el tipo al jugar).
class Rutina {
  final RutinaId id;
  final String nombre;
  final Tipo? tipoBase;
  final int ciclos;
  final Rareza rareza;
  final int maxCopias;

  const Rutina(this.id, this.nombre, this.tipoBase, this.ciclos, this.rareza,
      {this.maxCopias = 3});

  bool get esComodin => tipoBase == null;
}

/// Una carta de Alteración.
class Subrutina {
  final SubId id;
  final String nombre;
  final int costeRam;

  /// Paso de la pila de resolución (1..7) — ver docs/Cartas_Referencia.md §A.
  final int paso;
  final Rareza rareza;

  const Subrutina(this.id, this.nombre, this.costeRam, this.paso, this.rareza);
}

/// Un personaje (Núcleo). `alineacion == null` ⇒ NULL-CORE (pierde todos los espejos).
class Nucleo {
  final NucleoId id;
  final String nombre;
  final Tipo? alineacion;

  const Nucleo(this.id, this.nombre, this.alineacion);
}

/// Un mazo: 10 Rutinas + 20 Subrutinas + 1 Núcleo.
class Deck {
  final String id;
  final String nombre;
  final NucleoId nucleo;
  final List<RutinaId> rutinas;
  final List<SubId> subrutinas;

  const Deck(this.id, this.nombre, this.nucleo, this.rutinas, this.subrutinas);
}

/// A quién apunta una ROTACIÓN DE FASE.
enum RotacionObjetivo { propia, rival }

/// La jugada secreta de un jugador en una ronda.
class Play {
  final RutinaId rutina;

  /// Tipo efectivo: para comodines es el declarado; para normales, su tipoBase.
  final Tipo tipoDeclarado;
  final List<SubId> subs;
  final RotacionObjetivo? rotacionObjetivo;
  final bool usarPasiva;

  Play({
    required this.rutina,
    required this.tipoDeclarado,
    this.subs = const [],
    this.rotacionObjetivo,
    this.usarPasiva = false,
  });
}
