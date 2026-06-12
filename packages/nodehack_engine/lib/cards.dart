/// Catálogo canónico (portado de game-data.js): Núcleos, Rutinas, Subrutinas.
library;

import 'types.dart';

/// Pasivas con id para la lógica del motor.
enum PassiveId { blindaje, inyeccion, resonancia, corrupcion }

class NucleoDef {
  final String id;
  final String name;
  final String handle;
  final CType type;
  final String tag;
  final String passive; // texto
  final PassiveId passiveId;
  final int ram; // RAM base
  final int integrity;

  const NucleoDef({
    required this.id,
    required this.name,
    required this.handle,
    required this.type,
    required this.tag,
    required this.passive,
    required this.passiveId,
    required this.ram,
    required this.integrity,
  });

  int get color => type.color;
}

const List<NucleoDef> kNucleos = [
  NucleoDef(
    id: 'sentinel', name: 'SENTINEL', handle: 'sys.guardian', type: CType.firewall,
    tag: 'Defensa adaptativa',
    passive: 'BLINDAJE — La primera vez por partida que perderías integridad, la anulas.',
    passiveId: PassiveId.blindaje, ram: 5, integrity: 4,
  ),
  NucleoDef(
    id: 'wraith', name: 'WRAITH', handle: 'ghost.shell', type: CType.exploit,
    tag: 'Intrusión agresiva',
    passive: 'INYECCIÓN — Si ganas la ronda con EXPLOIT, robas 1 Subrutina extra la próxima ronda.',
    passiveId: PassiveId.inyeccion, ram: 5, integrity: 4,
  ),
  NucleoDef(
    id: 'echo', name: 'ECHO', handle: 'wave.daemon', type: CType.signal,
    tag: 'Control de tempo',
    passive: 'RESONANCIA — Tienes +1 RAM la ronda en que tu Rutina activa es PULSO.',
    passiveId: PassiveId.resonancia, ram: 6, integrity: 4,
  ),
  NucleoDef(
    id: 'nullkey', name: 'NULL-KEY', handle: 'void.root', type: CType.nul,
    tag: 'Comodín inestable',
    passive: 'CORRUPCIÓN — Tienes +1 RAM la ronda en que juegas un NULL-SHARD.',
    passiveId: PassiveId.corrupcion, ram: 4, integrity: 4,
  ),
];

class RutinaDef {
  final String id;
  final String name;
  final CType type;
  final int ciclos;
  final Rareza rar;
  final String proc;
  final String txt;
  const RutinaDef(this.id, this.name, this.type, this.ciclos, this.rar, this.proc, this.txt);
}

const List<RutinaDef> kRutinas = [
  RutinaDef('fw_base', 'CORTAFUEGOS', CType.firewall, 5, Rareza.c, 'firewall.proc', 'Rutina base. Vence a EXPLOIT.'),
  RutinaDef('fw_iron', 'IRON-WALL', CType.firewall, 7, Rareza.r, 'ironwall.sys', 'Inmune a THROTTLE (no le bajan los Ciclos). Coste: −1 RAM la próxima ronda.'),
  RutinaDef('xp_base', 'EXPLOIT', CType.exploit, 5, Rareza.c, 'exploit.bin', 'Rutina base. Vence a PULSO.'),
  RutinaDef('xp_zero', 'ZERO-DAY', CType.exploit, 9, Rareza.r, '0day.exploit', 'Gana los espejos de EXPLOIT por Ciclos. Coste: −1 RAM la próxima ronda.'),
  RutinaDef('pl_base', 'PULSO', CType.signal, 5, Rareza.c, 'pulse.sig', 'Rutina base. Vence a CORTAFUEGOS.'),
  RutinaDef('pl_emp', 'EMP-BURST', CType.signal, 8, Rareza.r, 'emp.burst', 'Si ganas, el rival roba 1 Subrutina menos. Coste: −1 RAM la próxima ronda.'),
  RutinaDef('null_sh', 'NULL-SHARD', CType.nul, 6, Rareza.n, 'shard.null', 'Comodín. Declaras su tipo al programar. Inmune a Overclock/Throttle.'),
];

class SubDef {
  final String id;
  final String name;
  final int ram; // coste
  final Rareza rar;
  final String proc;
  final String txt;
  const SubDef(this.id, this.name, this.ram, this.rar, this.proc, this.txt);
}

const List<SubDef> kSubrutinas = [
  SubDef('overclock', 'OVERCLOCK', 1, Rareza.c, 'clk.boost', '+4 Ciclos a tu Rutina.'),
  SubDef('throttle', 'THROTTLE', 1, Rareza.c, 'clk.choke', '−4 Ciclos a la Rutina del rival.'),
  SubDef('cuarentena', 'CUARENTENA', 2, Rareza.r, 'quar.kill', 'Anula la Rutina del rival → la ronda es EMPATE.'),
  SubDef('mirror', 'MIRROR', 2, Rareza.r, 'mirror.ref', 'Copia el tipo de la Rutina del rival antes de resolver.'),
  SubDef('sigkill', 'SIGKILL', 3, Rareza.e, 'sig.kill -9', 'Anula TODAS las Subrutinas del rival esta ronda.'),
  SubDef('forkbomb', 'FORK-BOMB', 3, Rareza.e, 'fork.bomb', 'Si ganas la ronda, el rival pierde 1 integridad extra.'),
  SubDef('shift_fwd', 'INTRUSIÓN ▸', 2, Rareza.r, 'phase.fwd', 'Mueve la Rutina del RIVAL al tipo SIGUIENTE del ciclo (mantiene su nivel básica/avanzada).'),
  SubDef('shift_back', '◂ RECALIBRAR', 2, Rareza.r, 'phase.rev', 'Mueve TU Rutina al tipo ANTERIOR del ciclo (mantiene su nivel básica/avanzada).'),
  SubDef('shift_opp_back', '◂ SABOTAJE', 2, Rareza.r, 'phase.sab', 'Mueve la Rutina del RIVAL al tipo ANTERIOR del ciclo (mantiene su nivel básica/avanzada).'),
  SubDef('shift_you_fwd', 'AVANCE ▸', 2, Rareza.r, 'phase.adv', 'Mueve TU Rutina al tipo SIGUIENTE del ciclo (mantiene su nivel básica/avanzada).'),
  // — Cartas nuevas —
  SubDef('patch', 'PARCHE', 2, Rareza.r, 'patch.sys', 'Si GANAS la ronda, +1 de integridad. Si PIERDES, pierdes 1 extra.'),
  SubDef('patch_pro', 'PARCHE.Ω', 4, Rareza.e, 'patch.omega', 'Si GANAS la ronda, +1 de integridad. Sin riesgo (pero caro).'),
  SubDef('invert_tri', 'INVERSIÓN', 2, Rareza.e, 'tri.flip', 'INVIERTE el triángulo esta ronda: el tipo que perdería, vence.'),
  SubDef('invert_cyc', 'PARADOJA', 2, Rareza.e, 'cyc.flip', 'Esta ronda, en un ESPEJO gana quien tenga MENOS Ciclos.'),
  SubDef('shuffle_loser', 'DESFRAG', 2, Rareza.r, 'frag.any', 'Quien PIERDA la ronda rebaraja su mano (la descarta y roba de nuevo).'),
  SubDef('shuffle_opp', 'FORMATEO', 3, Rareza.e, 'fmt.rival', 'Si el RIVAL pierde la ronda, rebaraja su mano. (A ti no te afecta.)'),
  // — Cartas SOLO de Historia (poder extra; el modo es más difícil/injusto) —
  SubDef('st_overdrive', 'SOBRECARGA', 2, Rareza.e, 'sys.overdrive', '+6 Ciclos a tu Rutina. (Solo Historia.)'),
  SubDef('st_purge', 'CONTRAVIRUS', 2, Rareza.e, 'anti.virus', 'Anula TODAS las Subrutinas del rival esta ronda. (Solo Historia.)'),
  SubDef('st_bastion', 'BASTIÓN', 2, Rareza.e, 'wall.absolute', 'Si PIERDES la ronda, no pierdes integridad (te atrincheras). (Solo Historia.)'),
];

/// Cartas que SOLO existen en el modo Historia (excluidas del Versus/multijugador).
const Set<String> kStoryOnlyCardIds = {'st_overdrive', 'st_purge', 'st_bastion'};

final Map<String, RutinaDef> kRutById = {for (final r in kRutinas) r.id: r};
final Map<String, SubDef> kSubById = {for (final s in kSubrutinas) s.id: s};
final Map<String, NucleoDef> kNucById = {for (final n in kNucleos) n.id: n};

/// Todas las cartas del catálogo actual (Rutinas + Subrutinas). Son las "base"
/// (gratuitas) del multijugador; futuras cartas se añadirán bloqueadas.
final Set<String> kAllCardIds = {...kRutById.keys, ...kSubById.keys};

/// Cartas que se DESBLOQUEAN para multijugador jugando partidas (escalonado, para
/// que "siempre haya algo cerca"). Las no listadas son base (desbloqueadas).
const Map<String, int> kCardUnlockGames = {
  'patch': 5,
  'invert_tri': 10,
  'patch_pro': 15,
  'invert_cyc': 20,
  'shuffle_loser': 25,
  'shuffle_opp': 30,
};

/// Límites de construcción de mazo.
const int kRutTarget = 10;
const int kSubTarget = 20;
const int kMaxRutCopies = 3;
const int kMaxSubCopies = 5;

/// Mínimo de Rutinas para un mazo del modo Inmersión (legalidad relajada).
const int kAdvMinRut = 3;
