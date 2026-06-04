/// Catálogo canónico v0.3 (números EXACTOS de docs/Cartas_Referencia.md §B–§E).
library;

import 'models.dart';

/// Las 11 Rutinas.
const Map<RutinaId, Rutina> kRutinas = {
  RutinaId.cortafuegos:
      Rutina(RutinaId.cortafuegos, 'CORTAFUEGOS', Tipo.cortafuegos, 5, Rareza.comun),
  RutinaId.exploit: Rutina(RutinaId.exploit, 'EXPLOIT', Tipo.exploit, 5, Rareza.comun),
  RutinaId.pulso: Rutina(RutinaId.pulso, 'PULSO', Tipo.pulso, 5, Rareza.comun),
  RutinaId.hotfix: Rutina(RutinaId.hotfix, 'HOTFIX', Tipo.cortafuegos, 8, Rareza.rara),
  RutinaId.muroBaluarte:
      Rutina(RutinaId.muroBaluarte, 'MURO-BALUARTE', Tipo.cortafuegos, 3, Rareza.epica),
  RutinaId.zeroDay: Rutina(RutinaId.zeroDay, 'ZERO-DAY', Tipo.exploit, 9, Rareza.rara),
  RutinaId.gusano: Rutina(RutinaId.gusano, 'GUSANO', Tipo.exploit, 4, Rareza.rara),
  RutinaId.broadcast: Rutina(RutinaId.broadcast, 'BROADCAST', Tipo.pulso, 2, Rareza.rara),
  RutinaId.pulsoEcho: Rutina(RutinaId.pulsoEcho, 'PULSO-ECHO', Tipo.pulso, 5, Rareza.epica),
  RutinaId.polimorfico:
      Rutina(RutinaId.polimorfico, 'POLIMÓRFICO', null, 2, Rareza.comun),
  RutinaId.nullShard:
      Rutina(RutinaId.nullShard, 'NULL-SHARD', null, 6, Rareza.nullUnica, maxCopias: 1),
};

/// Las 16 Subrutinas activas (ANALYZER PROBE está baneada y NO existe aquí).
const Map<SubId, Subrutina> kSubrutinas = {
  SubId.overclock: Subrutina(SubId.overclock, 'OVERCLOCK', 1, 4, Rareza.comun),
  SubId.throttle: Subrutina(SubId.throttle, 'THROTTLE', 1, 4, Rareza.comun),
  SubId.escudo: Subrutina(SubId.escudo, 'ESCUDO DE DATOS', 1, 1, Rareza.comun),
  SubId.recovery: Subrutina(SubId.recovery, 'RECOVERY CYCLE', 1, 7, Rareza.comun),
  SubId.defrag: Subrutina(SubId.defrag, 'DEFRAG', 0, 7, Rareza.comun),
  SubId.parche: Subrutina(SubId.parche, 'PARCHE', 2, 7, Rareza.comun),
  SubId.cuarentena: Subrutina(SubId.cuarentena, 'CUARENTENA', 2, 2, Rareza.rara),
  SubId.inversion: Subrutina(SubId.inversion, 'INVERSIÓN DE POLARIDAD', 2, 3, Rareza.rara),
  SubId.rotacion: Subrutina(SubId.rotacion, 'ROTACIÓN DE FASE', 2, 3, Rareza.rara),
  SubId.fork: Subrutina(SubId.fork, 'FORK', 2, 3, Rareza.rara),
  SubId.buffer: Subrutina(SubId.buffer, 'BUFFER', 1, 7, Rareza.rara),
  SubId.loopback: Subrutina(SubId.loopback, 'LOOPBACK', 1, 2, Rareza.rara),
  SubId.glitch: Subrutina(SubId.glitch, 'GLITCH', 2, 3, Rareza.epica),
  SubId.forkBomb: Subrutina(SubId.forkBomb, 'FORK-BOMB', 3, 7, Rareza.epica),
  SubId.sigkill: Subrutina(SubId.sigkill, 'SIGKILL', 3, 1, Rareza.epica),
};

/// Los 4 Núcleos.
const Map<NucleoId, Nucleo> kNucleos = {
  NucleoId.warden: Nucleo(NucleoId.warden, 'WARDEN', Tipo.cortafuegos),
  NucleoId.corrupted: Nucleo(NucleoId.corrupted, 'CORRUPTED', Tipo.exploit),
  NucleoId.relay: Nucleo(NucleoId.relay, 'RELAY', Tipo.pulso),
  NucleoId.nullCore: Nucleo(NucleoId.nullCore, 'NULL-CORE', null),
};

Rutina rutinaDe(RutinaId id) => kRutinas[id]!;
Subrutina subDe(SubId id) => kSubrutinas[id]!;
Nucleo nucleoDe(NucleoId id) => kNucleos[id]!;

/// Helper: expande una lista de `(id, cantidad)` en una lista plana.
List<T> _expand<T>(List<(T, int)> pares) =>
    [for (final (id, n) in pares) ...List.filled(n, id)];

/// Mazos de muestra A–F (docs/Cartas_Referencia.md §E, v0.3).
final Map<String, Deck> kMazos = {
  'A': Deck('A', 'MURO', NucleoId.warden, _expand([
    (RutinaId.cortafuegos, 3),
    (RutinaId.hotfix, 3),
    (RutinaId.muroBaluarte, 1),
    (RutinaId.polimorfico, 1),
    (RutinaId.pulso, 1),
    (RutinaId.exploit, 1),
  ]), _expand([
    (SubId.overclock, 3),
    (SubId.escudo, 2),
    (SubId.throttle, 2),
    (SubId.sigkill, 2),
    (SubId.loopback, 2),
    (SubId.rotacion, 2),
    (SubId.recovery, 2),
    (SubId.cuarentena, 1),
    (SubId.parche, 1),
    (SubId.forkBomb, 1),
    (SubId.defrag, 2),
  ])),
  'B': Deck('B', 'ENJAMBRE', NucleoId.corrupted, _expand([
    (RutinaId.exploit, 3),
    (RutinaId.zeroDay, 2),
    (RutinaId.gusano, 1),
    (RutinaId.polimorfico, 2),
    (RutinaId.cortafuegos, 1),
    (RutinaId.pulso, 1),
  ]), _expand([
    (SubId.overclock, 3),
    (SubId.rotacion, 3),
    (SubId.throttle, 2),
    (SubId.forkBomb, 2),
    (SubId.escudo, 2),
    (SubId.recovery, 3),
    (SubId.glitch, 1),
    (SubId.loopback, 1),
    (SubId.inversion, 1),
    (SubId.defrag, 2),
  ])),
  'C': Deck('C', 'SEÑAL', NucleoId.relay, _expand([
    (RutinaId.pulso, 3),
    (RutinaId.broadcast, 2),
    (RutinaId.pulsoEcho, 2),
    (RutinaId.polimorfico, 1),
    (RutinaId.cortafuegos, 1),
    (RutinaId.exploit, 1),
  ]), _expand([
    (SubId.recovery, 3),
    (SubId.loopback, 2),
    (SubId.overclock, 3),
    (SubId.escudo, 2),
    (SubId.rotacion, 2),
    (SubId.throttle, 2),
    (SubId.cuarentena, 1),
    (SubId.parche, 1),
    (SubId.buffer, 1),
    (SubId.defrag, 2),
    (SubId.inversion, 1),
  ])),
  'D': Deck('D', 'RUIDO', NucleoId.nullCore, _expand([
    (RutinaId.nullShard, 1),
    (RutinaId.polimorfico, 2),
    (RutinaId.cortafuegos, 2),
    (RutinaId.exploit, 3),
    (RutinaId.pulso, 2),
  ]), _expand([
    (SubId.glitch, 3),
    (SubId.rotacion, 3),
    (SubId.inversion, 3),
    (SubId.fork, 2),
    (SubId.overclock, 2),
    (SubId.throttle, 2),
    (SubId.escudo, 2),
    (SubId.recovery, 3),
  ])),
  'E': Deck('E', 'LECTOR', NucleoId.relay, _expand([
    (RutinaId.cortafuegos, 2),
    (RutinaId.exploit, 2),
    (RutinaId.pulso, 2),
    (RutinaId.hotfix, 1),
    (RutinaId.pulsoEcho, 1),
    (RutinaId.polimorfico, 2),
  ]), _expand([
    (SubId.loopback, 3),
    (SubId.rotacion, 3),
    (SubId.inversion, 3),
    (SubId.throttle, 2),
    (SubId.overclock, 2),
    (SubId.escudo, 2),
    (SubId.recovery, 2),
    (SubId.parche, 1),
    (SubId.cuarentena, 1),
    (SubId.buffer, 1),
  ])),
  'F': Deck('F', 'PRISMA', NucleoId.relay, _expand([
    (RutinaId.polimorfico, 3),
    (RutinaId.nullShard, 1),
    (RutinaId.cortafuegos, 2),
    (RutinaId.exploit, 2),
    (RutinaId.pulso, 2),
  ]), _expand([
    (SubId.rotacion, 3),
    (SubId.recovery, 3),
    (SubId.escudo, 2),
    (SubId.overclock, 2),
    (SubId.throttle, 2),
    (SubId.loopback, 2),
    (SubId.parche, 1),
    (SubId.cuarentena, 1),
    (SubId.inversion, 1),
    (SubId.buffer, 1),
    (SubId.defrag, 2),
  ])),
};
