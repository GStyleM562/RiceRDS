/// Datos del modo INMERSIÓN: naturalezas (personajes), procesos enemigos, jefe,
/// fragmentos de lore, ofertas de tienda y constantes de progresión. Todo es
/// placeholder CRÍPTICO mientras la historia no esté definida (a propósito).
library;

import 'package:nodehack_engine/card_instance.dart';
import 'package:nodehack_engine/cards.dart';
import 'package:nodehack_engine/deck.dart';

// ───────────────────────── Constantes de progresión ─────────────────────────
const int kBattlesPerSector = 5; // peleas antes de que aparezca el JEFE
const int kLoreEvery = 2; // cada N peleas, un FRAGMENTO de lore
const int kSubsUnlockWins = 3; // Subrutinas se habilitan tras 3 victorias
const int kBossLoseSetback = 2; // al perder vs el jefe, retrocede el contador

const int kRewardCredits = 6; // créditos por victoria normal
const int kEliteCredits = 12; // créditos por élite
const int kLoseConsolation = 2; // consolación al perder

// ───────────────────────── Naturalezas (personajes) ─────────────────────────
/// Tu "naturaleza" fija tu Núcleo y orienta tu FINAL. Empiezas en CENTINELA; un
/// evento de MUTACIÓN te deja cambiarla.
class NatureDef {
  final String id;
  final String name;
  final String nucleoId;
  final String blurb; // sabor críptico
  final String endingHint; // hacia qué final te inclina (críptico)
  const NatureDef(this.id, this.name, this.nucleoId, this.blurb, this.endingHint);
  NucleoDef get nucleo => kNucById[nucleoId] ?? kNucleos.first;
}

const NatureDef kStartNature = NatureDef(
  'guardian', 'CENTINELA', 'sentinel',
  'Naciste para contener. Aún no sabes contener qué.',
  'Un final que SELLA.',
);

const List<NatureDef> kNatures = [
  kStartNature,
  NatureDef('espectro', 'ESPECTRO', 'wraith',
      'Te filtras entre procesos muertos. Nadie te ve venir.',
      'Un final que SE INFILTRA.'),
  NatureDef('resonante', 'RESONANTE', 'echo',
      'Repites la señal hasta que el sistema canta contigo.',
      'Un final que RESUENA.'),
  NatureDef('nulo', 'NULO', 'nullkey',
      'No eres un tipo. Eres el hueco que dejaron.',
      'Un final que BORRA.'),
];

NatureDef natureById(String id) =>
    kNatures.firstWhere((n) => n.id == id, orElse: () => kStartNature);

/// Opciones de mutación distintas a tu naturaleza actual.
List<NatureDef> mutationOptions(String currentId) =>
    [for (final n in kNatures) if (n.id != currentId) n];

// ───────────────────────── Colección / cartas ─────────────────────────
/// Colección inicial: solo las 3 Rutinas básicas (×2). Sin Subrutinas.
Map<String, int> starterCollectionRut() => {'fw_base': 2, 'xp_base': 2, 'pl_base': 2};

/// Cartas que arrancan BLOQUEADAS (se consiguen como recompensa o en la tienda).
const List<String> kLockedRut = ['fw_iron', 'xp_zero', 'pl_emp', 'null_sh'];
const List<String> kLockedSub = [
  'overclock', 'throttle', 'mirror', 'shift_you_fwd', 'shift_back',
  'shift_fwd', 'shift_opp_back', 'cuarentena', 'sigkill', 'forkbomb',
];

// ───────────────────────── Procesos enemigos ─────────────────────────
class EnemyProc {
  final String id;
  final String name;
  final String nucleoId;
  final Map<String, int> rut;
  final Map<String, int> sub;
  final String flavor; // telegrafía críptica (pre-combate)
  final bool elite;
  const EnemyProc({
    required this.id,
    required this.name,
    required this.nucleoId,
    required this.rut,
    this.sub = const {},
    required this.flavor,
    this.elite = false,
  });
  Deck deck() => Deck(name: name, nucleoId: nucleoId, rut: Map.of(rut), sub: Map.of(sub));
  NucleoDef get nucleo => kNucById[nucleoId] ?? kNucleos.first;
}

const List<EnemyProc> kEnemies = [
  EnemyProc(
    id: 'filtro', name: 'proc_FILTRO', nucleoId: 'sentinel',
    rut: {'fw_base': 4, 'pl_base': 2}, sub: {'throttle': 2},
    flavor: 'Un muro que respira. No quiere pasar; quiere que NO pases.',
  ),
  EnemyProc(
    id: 'intruso', name: 'proc_INTRUSO', nucleoId: 'wraith',
    rut: {'xp_base': 4, 'fw_base': 2}, sub: {'overclock': 2},
    flavor: 'Algo ya está dentro. Solo falta que lo notes.',
  ),
  EnemyProc(
    id: 'eco', name: 'proc_ECO', nucleoId: 'echo',
    rut: {'pl_base': 4, 'xp_base': 2}, sub: {'mirror': 1},
    flavor: 'Tu propia señal, devuelta con retraso y mala intención.',
  ),
  EnemyProc(
    id: 'vigia', name: 'daemon_VIGÍA', nucleoId: 'sentinel', elite: true,
    rut: {'fw_base': 3, 'fw_iron': 2, 'xp_base': 2}, sub: {'throttle': 2, 'sigkill': 1},
    flavor: 'Te estuvo observando todo este tiempo. Ahora parpadea.',
  ),
  EnemyProc(
    id: 'gusano', name: 'daemon_GUSANO', nucleoId: 'wraith', elite: true,
    rut: {'xp_base': 3, 'xp_zero': 2, 'pl_base': 2}, sub: {'overclock': 2, 'forkbomb': 1},
    flavor: 'Se come las rutas que dejas atrás. Apúrate.',
  ),
];

/// El JEFE del tramo (KERNEL). Regla especial: por ahora se telegrafía en el lore
/// (modificadores reales del motor quedan para después).
const EnemyProc kBoss = EnemyProc(
  id: 'kernel', name: 'KERNEL_0x00', nucleoId: 'nullkey', elite: true,
  rut: {'null_sh': 2, 'fw_iron': 2, 'xp_zero': 2, 'pl_emp': 2},
  sub: {'mirror': 2, 'overclock': 2, 'sigkill': 1, 'cuarentena': 1},
  flavor: 'El que reescribió todo. Te mira como a una línea de código por borrar.',
);

// ───────────────────────── Lore (placeholder críptico) ─────────────────────────
/// Transmisiones cortas antes de un combate.
const List<String> kPreCombatLore = [
  'La máquina recuerda algo que tú no. Sigue bajando.',
  'Cada proceso que vence deja una huella tuya en el NULL ARCHIVE.',
  'No estás descendiendo. Te están dejando entrar.',
  'Hubo otros antes que tú. Llegaron lejos. No lo bastante.',
  'El KERNEL no defiende el centro. Defiende una pregunta.',
];

/// Eventos FRAGMENTO: lore + una decisión binaria (riesgo/recompensa).
class FragmentDef {
  final String id;
  final String text;
  final String optA; // etiqueta opción A
  final String optAEffect; // 'credits:+8' | 'copy' | 'heal' ...
  final String optB;
  final String optBEffect;
  const FragmentDef(this.id, this.text, this.optA, this.optAEffect, this.optB, this.optBEffect);
}

const List<FragmentDef> kFragments = [
  FragmentDef('cache',
      'Un caché corrupto late en la oscuridad. Puedes drenarlo… o dejarlo dormir.',
      'DRENAR (+créditos, riesgo)', 'credits:+10',
      'DEJARLO', 'none'),
  FragmentDef('eco_propio',
      'Oyes tu propia voz un paso adelante, dándote una pista que aún no entiendes.',
      'ESCUCHAR (+créditos)', 'credits:+6',
      'IGNORAR', 'none'),
  FragmentDef('puerta',
      'Una puerta con tu firma, pero más vieja. Alguien ya estuvo aquí siendo tú.',
      'CRUZAR', 'credits:+4',
      'RETROCEDER', 'none'),
];

/// Evento especial de MUTACIÓN (cambia tu naturaleza). Se ofrece de vez en cuando.
const String kMutationIntro =
    'El sistema te ofrece reescribirte. Lo que elijas aquí teñirá tu final.';

// ───────────────────────── Códice (lore por carta descubierta) ─────────────────────────
const List<String> _kCodexLore = [
  'Recuperada de un proceso que ya no responde.',
  'Su firma no coincide con ningún registro del NULL ARCHIVE.',
  'Vibra cuando la sostienes. Como si te reconociera.',
  'Alguien la marcó con tu identificador. Antes de que existieras.',
  'Funciona. Nadie recuerda quién la escribió.',
];

/// Fragmento de lore (placeholder críptico) asociado a una carta del Códice.
/// Determinista por id para que no cambie entre sesiones.
String codexLoreFor(String cardId) =>
    _kCodexLore[cardId.codeUnits.fold(0, (a, b) => a + b) % _kCodexLore.length];

/// Instancia visual de una carta por id (Rutina o Subrutina), para `CardView`.
CardInstance cardInstanceOf(String id) => kRutById.containsKey(id)
    ? CardInstance.rutina(kRutById[id]!)
    : CardInstance.subrutina(kSubById[id]!);
