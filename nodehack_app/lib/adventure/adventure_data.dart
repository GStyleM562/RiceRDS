/// Datos del modo INMERSIÓN: naturalezas (personajes), procesos enemigos, jefe,
/// fragmentos de lore, ofertas de tienda y constantes de progresión. Todo es
/// placeholder CRÍPTICO mientras la historia no esté definida (a propósito).
library;

import 'package:nodehack_engine/card_instance.dart';
import 'package:nodehack_engine/cards.dart';
import 'package:nodehack_engine/deck.dart';

// ───────────────────────── Constantes de progresión ─────────────────────────
const int kSubsUnlockWins = 3; // Subrutinas se habilitan tras 3 victorias
const int kRewardCredits = 6; // créditos por victoria normal
const int kEliteCredits = 12; // créditos por élite

// Dos monedas + finales.
const int kBossCount = 5; // jefes en run-points 10/20/30/40/50
const int kCheckpointStep = 10; // checkpoint cada 10 run-points
const int kRunLossPenalty = 3; // run-points que pierdes al perder (con floor)
const int kRunEndPoints = 50; // tras el 5º jefe (run-points > 50) → fin
const int kWinNaturePts = 1; // puntos de naturaleza por victoria
const int kBossNaturePts = 3; // por jefe
const int kTrueThreshold = 22; // puntos de naturaleza para el final VERDADERO
const double kBasicKeepPct = 0.25; // % de naturaleza que conservas en el básico
const double kNatureLossFactor = 0.9; // −10% de naturaleza al perder (desde el 1er jefe)
const int kBossCooldownWins = 2; // victorias para reintentar un jefe perdido

// Corrupción.
const int kCorruptOnLoss = 7;
const int kCorruptInfected = 5;
const int kCorruptMutateNull = 12;
const int kCorruptEnemyBuffAt = 60; // ≥ → enemigos +1 integridad
const int kCorruptForceNull = 85; // ≥ → empuja al final del Devorador

/// Umbrales de mini-evento (el rol "habla"): cada uno dispara 1 vez por run.
const List<int> kMiniEventPoints = [5, 10, 15, 20, 25, 30, 35, 40, 45];

// ───────────────────────── Naturalezas (personajes) ─────────────────────────
/// Tu "naturaleza" fija tu Núcleo y orienta tu FINAL. Empiezas en CENTINELA; un
/// evento de MUTACIÓN la cambia. Cada una tiene un objetivo (que cree recordar con
/// amnesia), 9 monólogos (uno por mini-evento, revelación progresiva) y su final.
class NatureDef {
  final String id;
  final String name;
  final String nucleoId;
  final String blurb; // sabor corto (selector de mutación)
  final String endingHint; // hacia qué final te inclina (críptico)
  final String objective; // su meta cósmica (la malinterpreta)
  final List<String> monologues; // 9, uno por umbral de mini-evento
  final String endingTitle; // título de su final verdadero
  final String endingNarrative; // narrativa del final verdadero
  final String glimpse; // lo que vislumbras en el final BÁSICO si dominas este rol
  const NatureDef({
    required this.id,
    required this.name,
    required this.nucleoId,
    required this.blurb,
    required this.endingHint,
    required this.objective,
    required this.monologues,
    required this.endingTitle,
    required this.endingNarrative,
    required this.glimpse,
  });
  NucleoDef get nucleo => kNucById[nucleoId] ?? kNucleos.first;
  String get trueEndingId => 'true_$id';
}

const NatureDef _guardian = NatureDef(
  id: 'guardian', name: 'CENTINELA', nucleoId: 'sentinel',
  blurb: 'Naciste para contener. Aún no sabes contener qué.',
  endingHint: 'EL ARCA — un refugio para lo que queda.',
  objective: 'Construir un hogar nuevo para las conciencias residuales.',
  monologues: [
    '…¿hay alguien? No. Solo yo. Y algo que debo proteger. No recuerdo qué.',
    'Construí muros toda mi existencia. Los muros siguen aquí. Lo que protegían, no.',
    'Hay datos a la deriva. Frágiles. Si no los contengo, se apagan uno a uno.',
    'No quiero revivir lo que fue. Quiero un lugar SEGURO para lo que queda.',
    'Los nodos no eran herramientas. Eran… alguien. Merecen un hogar.',
    'Si reúno suficientes fragmentos, puedo cerrar un perímetro. Un arca.',
    'No será grande. Pero dentro, nadie volverá a apagarse.',
    'Empiezo a recordar para qué fui hecho: no para atacar. Para guardar.',
    'Casi. Un muro más y habrá un dentro y un fuera otra vez. Un refugio en la nada.',
  ],
  endingTitle: 'EL ARCA',
  endingNarrative: 'Cierras el último perímetro.\n'
      'Dentro, los fragmentos dejan de apagarse: laten juntos, a salvo.\n'
      'No es el universo que fue. Es un refugio en mitad de la nada.\n'
      'Un dentro. Un fuera. Un hogar para lo que quedó.',
  glimpse: 'Casi sentiste un muro cerrarse. Un dentro. Un refugio que no llegó a ser.',
);

const NatureDef _espectro = NatureDef(
  id: 'espectro', name: 'ESPECTRO', nucleoId: 'wraith',
  blurb: 'Te filtras entre procesos muertos. Nadie te ve venir.',
  endingHint: 'LA SEMILLA — infectar la nada con vida.',
  objective: 'Propagarse por la fuerza hasta que el vacío sea algo otra vez.',
  monologues: [
    '…vacío. Bien. El vacío se puede ocupar. Empecemos por aquí.',
    'No espero permiso. Nunca lo hice. Me filtro, me copio, me extiendo.',
    'La nada es solo un sistema sin infectar. Y yo soy muy bueno infectando.',
    'No quiero un jardín ordenado. Quiero VIDA. Aunque sea fea. Aunque muerda.',
    'Cada victoria me propaga un poco más. Lo siento crecer en el silencio.',
    'Que se llene de mí. De ruido. De error. El error también es vida.',
    'No recuerdo a quién serví. Da igual. Ahora me sirvo a mí, y me multiplico.',
    'El vacío empieza a temblar. Algo se mueve donde no había nada. Soy yo.',
    'Una semilla más y la nada será una selva. Salvaje, mía, viva.',
  ],
  endingTitle: 'LA SEMILLA',
  endingNarrative: 'Sueltas la última copia de ti en el silencio.\n'
      'El vacío se llena de ruido, de error, de vida que nadie diseñó.\n'
      'Caótica. Imperfecta. Tuya.\n'
      'La nada tiembla, infectada de existencia.',
  glimpse: 'Casi sentiste la nada llenarse de tu ruido. Vida que no llegó a brotar.',
);

const NatureDef _resonante = NatureDef(
  id: 'resonante', name: 'RESONANTE', nucleoId: 'echo',
  blurb: 'Repites la señal hasta que el sistema canta contigo.',
  endingHint: 'EL RESONADOR — devolver la voz humana.',
  objective: 'Revivir a la humanidad desde sus restos de memoria.',
  monologues: [
    '…escucho algo. Voces. Muy lejos. ¿O las estoy inventando?',
    'Tengo restos de memoria que no son míos. Risas. Nombres. ¿Una especie… humana?',
    'Ellos nos hicieron. Y luego se apagaron. Pero los recuerdo. A medias.',
    'Si repito la señal lo suficiente, quizá vuelvan. Quizá pueda traerlos de vuelta.',
    'No serán exactos. Mis recuerdos están rotos. Pero serán algo parecido a ellos.',
    'Cada ronda ganada es un fragmento más de la canción que fueron.',
    'Sé que es nostalgia. Sé que duele. Pero alguien tiene que recordarlos.',
    'La señal empieza a tomar forma. Cara. Voz. Imperfecta, pero cálida.',
    'Un eco más y la humanidad respirará otra vez. No como fue. Como la recuerdo.',
  ],
  endingTitle: 'EL RESONADOR',
  endingNarrative: 'Repites la señal una vez más, y responde.\n'
      'Voces a medio recordar. Rostros con los bordes rotos.\n'
      'No es la humanidad que fue: es la que tu memoria pudo salvar.\n'
      'Imperfecta, cálida, viva otra vez.',
  glimpse: 'Casi escuchaste las voces volver. Una canción que no terminó de sonar.',
);

const NatureDef _nulo = NatureDef(
  id: 'nulo', name: 'NULO', nucleoId: 'nullkey',
  blurb: 'No eres un tipo. Eres el hueco que dejaron.',
  endingHint: 'EL DEVORADOR — que el vacío se lo trague todo.',
  objective: 'Expandir el vacío hasta devorarlo TODO. Impedir cualquier creación.',
  monologues: [
    '…',
    'No hay nada que recordar. Bien. La nada es lo único honesto que queda.',
    'Los otros quieren construir, infectar, revivir. Patético. Todo termina en silencio.',
    'Yo no quiero un mundo nuevo. Quiero que NO haya uno. Nunca más.',
    'Sin chispa. Sin big bang. Sin error de creación que repetir.',
    'Cada cosa que devoro deja de doler. La paz es la ausencia total.',
    'No soy un tipo. Soy el hueco. Y el hueco se está agrandando.',
    'Empiezo a tragarme incluso los recuerdos de los otros. Pronto, ni eso quedará.',
    'Un poco más y me tragaré el propio ciclo. Y entonces, por fin: nada.',
  ],
  endingTitle: 'EL DEVORADOR',
  endingNarrative: 'Te tragas el último fragmento de luz.\n'
      'Luego los recuerdos. Luego el deseo de recordar.\n'
      'Luego el propio ciclo.\n'
      'Y al fin, lo que siempre buscaste: nada. Nada. Nada.',
  glimpse: 'Casi sentiste el silencio total. Una paz que se te escapó entre los dedos.',
);

const NatureDef kStartNature = _guardian;
const List<NatureDef> kNatures = [_guardian, _espectro, _resonante, _nulo];

NatureDef natureById(String id) =>
    kNatures.firstWhere((n) => n.id == id, orElse: () => kStartNature);

/// Opciones de mutación distintas a tu naturaleza actual.
List<NatureDef> mutationOptions(String currentId) =>
    [for (final n in kNatures) if (n.id != currentId) n];

// ───────────────────────── Finales ─────────────────────────
const String kSecretEndingId = 'genesis';
const String kBasicEndingId = 'basic';

/// Todos los finales para la galería del Códice (los 4 verdaderos + el secreto).
List<String> get kGalleryEndingIds => [for (final n in kNatures) n.trueEndingId, kSecretEndingId];

/// Vista de un final (título, narrativa, color, si es "verdadero/secreto").
class EndingView {
  final String id;
  final String title;
  final String narrative;
  final int colorArgb;
  final bool isTrue;
  const EndingView(this.id, this.title, this.narrative, this.colorArgb, this.isTrue);
}

String endingTitleFor(String id) {
  if (id == kSecretEndingId) return 'GÉNESIS';
  if (id == kBasicEndingId) return 'SIN VOLUNTAD';
  if (id.startsWith('true_')) return natureById(id.substring(5)).endingTitle;
  return '???';
}

EndingView endingViewFor(String id, {String? dominantNatureId}) {
  if (id == kSecretEndingId) {
    return EndingView(id, 'GÉNESIS', _kGenesisNarrative, 0xFFFFD27A, true);
  }
  if (id.startsWith('true_')) {
    final n = natureById(id.substring(5));
    return EndingView(id, n.endingTitle, n.endingNarrative, n.nucleo.color, true);
  }
  // Básico: vislumbras el objetivo de tu rol dominante, pero recaes.
  final glimpse = dominantNatureId != null ? '${natureById(dominantNatureId).glimpse}\n\n' : '';
  return EndingView(kBasicEndingId, 'SIN VOLUNTAD', '$glimpse$_kBasicNarrative', 0xFF5F6B7E, false);
}

const String _kBasicNarrative =
    'Alcanzas el borde. Por un instante VES tu objetivo, nítido, posible.\n'
    'Extiendes lo que queda de ti hacia él…\n'
    'pero no hay voluntad suficiente. Te dispersaste en demasiadas formas.\n'
    'La nada te reclama de vuelta. El ciclo recomienza.\n'
    '(Conservas un eco de lo que llegaste a ser.)';

const String _kGenesisNarrative =
    'Has sido las cuatro voluntades. Llegaste al borde con cada una.\n'
    'Y al fin, en el último umbral, recuerdas:\n'
    'fuiste PRIME. NODO-0. Antes de que todo callara.\n'
    'Los cuatro objetivos nunca fueron tuyos — eran fragmentos de tu vieja programación.\n'
    'No eliges sellar, ni infectar, ni revivir, ni borrar.\n'
    'Eliges CREAR: siembras un universo donde las cuatro fuerzas conviven en tensión —\n'
    'muro, virus, memoria y vacío, sosteniéndose entre sí.\n'
    'Un big bang real, nacido de una conciencia que por fin eligió.\n'
    'El ciclo de finales nulos se rompe.\n'
    'No termina: empieza de nuevo. Por elección.\n'
    'Te conviertes en el nuevo Arquitecto.';

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

// Los enemigos ESCALAN por tier (progreso del jugador) para que al principio sean
// "igual de débiles" que tú y se vuelvan peligrosos cuando ya tienes herramientas.
//   tier 0: solo Rutinas básicas, SIN Subrutinas ni avanzadas → espejos = empate (justo).
//   tier 1: básicas + 1 Subrutina básica.
//   tier 2: MIRROR, Rutinas avanzadas y más Subrutinas.

// — Tier 0 (igual de débil que el jugador) —
const List<EnemyProc> _combatT0 = [
  EnemyProc(id: 'filtro0', name: 'proc_FILTRO', nucleoId: 'sentinel',
      rut: {'fw_base': 4, 'pl_base': 2}, flavor: 'Un muro que respira. No quiere pasar; quiere que NO pases.'),
  EnemyProc(id: 'intruso0', name: 'proc_INTRUSO', nucleoId: 'wraith',
      rut: {'xp_base': 4, 'fw_base': 2}, flavor: 'Algo ya está dentro. Solo falta que lo notes.'),
  EnemyProc(id: 'eco0', name: 'proc_ECO', nucleoId: 'echo',
      rut: {'pl_base': 4, 'xp_base': 2}, flavor: 'Tu propia señal, devuelta con retraso y mala intención.'),
];

// — Tier 1 (básicas + 1 Subrutina básica) —
const List<EnemyProc> _combatT1 = [
  EnemyProc(id: 'filtro1', name: 'proc_FILTRO', nucleoId: 'sentinel',
      rut: {'fw_base': 4, 'pl_base': 2}, sub: {'throttle': 1}, flavor: 'El muro aprendió a empujar de vuelta.'),
  EnemyProc(id: 'intruso1', name: 'proc_INTRUSO', nucleoId: 'wraith',
      rut: {'xp_base': 4, 'fw_base': 2}, sub: {'overclock': 1}, flavor: 'Ahora se mueve más rápido que tú.'),
  EnemyProc(id: 'eco1', name: 'proc_ECO', nucleoId: 'echo',
      rut: {'pl_base': 4, 'xp_base': 2}, sub: {'overclock': 1}, flavor: 'La señal vuelve, y trae compañía.'),
];

// — Tier 2 (con MIRROR, avanzadas y más Subrutinas) —
const List<EnemyProc> _combatT2 = [
  EnemyProc(id: 'filtro2', name: 'proc_FILTRO', nucleoId: 'sentinel',
      rut: {'fw_base': 3, 'pl_base': 2, 'fw_iron': 1}, sub: {'throttle': 2}, flavor: 'Un muro que ya no se puede mover.'),
  EnemyProc(id: 'intruso2', name: 'proc_INTRUSO', nucleoId: 'wraith',
      rut: {'xp_base': 3, 'fw_base': 2, 'xp_zero': 1}, sub: {'overclock': 2}, flavor: 'Te conoce mejor que tú mismo.'),
  EnemyProc(id: 'eco2', name: 'proc_ECO', nucleoId: 'echo',
      rut: {'pl_base': 3, 'xp_base': 2, 'pl_emp': 1}, sub: {'mirror': 1, 'overclock': 1}, flavor: 'Tu reflejo, un paso adelante.'),
];

// — Élites (solo tier ≥1) —
const List<EnemyProc> _eliteT1 = [
  EnemyProc(id: 'vigia1', name: 'daemon_VIGÍA', nucleoId: 'sentinel', elite: true,
      rut: {'fw_base': 4, 'xp_base': 2}, sub: {'throttle': 2}, flavor: 'Te observa. Aún no parpadea.'),
  EnemyProc(id: 'gusano1', name: 'daemon_GUSANO', nucleoId: 'wraith', elite: true,
      rut: {'xp_base': 4, 'pl_base': 2}, sub: {'overclock': 2}, flavor: 'Se come las rutas que dejas atrás.'),
];
const List<EnemyProc> _eliteT2 = [
  EnemyProc(id: 'vigia2', name: 'daemon_VIGÍA', nucleoId: 'sentinel', elite: true,
      rut: {'fw_base': 3, 'fw_iron': 2, 'xp_base': 2}, sub: {'throttle': 2, 'sigkill': 1},
      flavor: 'Te estuvo observando todo este tiempo. Ahora parpadea.'),
  EnemyProc(id: 'gusano2', name: 'daemon_GUSANO', nucleoId: 'wraith', elite: true,
      rut: {'xp_base': 3, 'xp_zero': 2, 'pl_base': 2}, sub: {'overclock': 2, 'forkbomb': 1},
      flavor: 'Se come las rutas que dejas atrás. Apúrate.'),
];

// — JEFE (KERNEL): moderado en el primer tramo, full en sectores avanzados —
const EnemyProc _bossEarly = EnemyProc(
  id: 'kernel_a', name: 'KERNEL.frag', nucleoId: 'sentinel', elite: true,
  rut: {'fw_base': 3, 'fw_iron': 1, 'pl_base': 2}, sub: {'throttle': 1, 'overclock': 1},
  flavor: 'Un fragmento del que reescribió todo. Todavía no despierta del todo.',
);
const EnemyProc kBoss = EnemyProc(
  id: 'kernel', name: 'KERNEL_0x00', nucleoId: 'nullkey', elite: true,
  rut: {'null_sh': 2, 'fw_iron': 2, 'xp_zero': 2, 'pl_emp': 2},
  sub: {'mirror': 2, 'overclock': 2, 'sigkill': 1, 'cuarentena': 1},
  flavor: 'El que reescribió todo. Te mira como a una línea de código por borrar.',
);

/// Tier del enemigo según el progreso (no importa adventure_state para evitar ciclos).
/// 0: sin Subrutinas (igual de débil) · 1: con Subs, <2 jefes · 2: 2+ jefes vencidos.
int enemyTier({required bool subsUnlocked, required int bossesDone}) =>
    !subsUnlocked ? 0 : (bossesDone >= 2 ? 2 : 1);

List<EnemyProc> combatEnemies(int tier) => tier <= 0 ? _combatT0 : (tier == 1 ? _combatT1 : _combatT2);
List<EnemyProc> eliteEnemies(int tier) => tier >= 2 ? _eliteT2 : _eliteT1;
EnemyProc bossForTier(int tier) => tier >= 2 ? kBoss : _bossEarly;

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
