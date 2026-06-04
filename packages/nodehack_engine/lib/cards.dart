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
  RutinaDef('fw_iron', 'IRON-WALL', CType.firewall, 7, Rareza.r, 'ironwall.sys', 'Si ganas, no recibes Subrutinas de daño esta ronda.'),
  RutinaDef('xp_base', 'EXPLOIT', CType.exploit, 5, Rareza.c, 'exploit.bin', 'Rutina base. Vence a PULSO.'),
  RutinaDef('xp_zero', 'ZERO-DAY', CType.exploit, 9, Rareza.r, '0day.exploit', 'Gana los espejos de EXPLOIT por Ciclos. Coste: −1 RAM la próxima ronda.'),
  RutinaDef('pl_base', 'PULSO', CType.signal, 5, Rareza.c, 'pulse.sig', 'Rutina base. Vence a CORTAFUEGOS.'),
  RutinaDef('pl_emp', 'EMP-BURST', CType.signal, 8, Rareza.r, 'emp.burst', 'Si ganas, el rival roba 1 carta menos la próxima ronda.'),
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
];

final Map<String, RutinaDef> kRutById = {for (final r in kRutinas) r.id: r};
final Map<String, SubDef> kSubById = {for (final s in kSubrutinas) s.id: s};
final Map<String, NucleoDef> kNucById = {for (final n in kNucleos) n.id: n};

/// Límites de construcción de mazo.
const int kRutTarget = 10;
const int kSubTarget = 20;
const int kMaxRutCopies = 3;
const int kMaxSubCopies = 5;
