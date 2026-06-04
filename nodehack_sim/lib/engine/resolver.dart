/// LA PILA DE RESOLUCIÓN (v0.3). Determinista: todo azar viene del `Rng` inyectado.
/// Pasos (docs/Cartas_Referencia.md §A): 1 Protección · 2 Anulación · 3 Ciclo ·
/// 4 Ciclos · 5 Matchup · 6 Daño+triggers · 7 Post. (8 Adquisición la hace Game.)
///
/// Simplificaciones documentadas (v1 del simulador):
///  - FORK copia la última subrutina activa del rival y la re-procesa en los pasos 3-4-7
///    (no puede "rebobinar" a pasos ya pasados como Cuarentena/Escudo).
///  - BUFFER se modela como +4 Ciclos diferido a la próxima ronda.
///  - MURO-BALUARTE: inmune a THROTTLE (la cláusula "subrutinas de baja prioridad" no se modela).
library;

import 'data.dart';
import 'models.dart';
import 'rng.dart';
import 'state.dart';
import 'triangle.dart';

class _Side {
  final PlayerState ps;
  final Play play;
  final NucleoId nucleo;
  Tipo tipo;
  int ciclos;
  bool anulada = false;
  bool protegida = false;
  late List<SubId> subs; // activas (cancelables por SIGKILL/WARDEN)

  _Side(this.ps, this.play, this.nucleo)
      : tipo = play.tipoDeclarado,
        ciclos = rutinaDe(play.rutina).ciclos {
    subs = List.of(play.subs);
  }

  bool get usaWarden => play.usarPasiva && nucleo == NucleoId.warden;
  bool get usaCorrupted => play.usarPasiva && nucleo == NucleoId.corrupted;
  bool get usaNullCore => play.usarPasiva && nucleo == NucleoId.nullCore;
  bool tiene(SubId s) => subs.contains(s);
}

class Resolver {
  /// Resuelve una ronda y aplica los cambios de estado (daño, robos de carta,
  /// modificadores de RAM). NO hace el robo estándar de fin de ronda (eso es Game).
  RoundLog resolve(
    GameState gs,
    Play a,
    Play b,
    Rng rng,
    int turno,
    int ramA,
    int ramB,
  ) {
    final log = RoundLog(turno, ramA, ramB);
    final A = _Side(gs.p0, a, gs.p0.nucleo);
    final B = _Side(gs.p1, b, gs.p1.nucleo);

    log.rutinaA = a.rutina;
    log.rutinaB = b.rutina;
    log.subsA = List.of(a.subs);
    log.subsB = List.of(b.subs);

    // ── PASO 1: PROTECCIÓN / CANCELACIÓN ──
    final aSig = a.subs.contains(SubId.sigkill);
    final bSig = b.subs.contains(SubId.sigkill);
    if (aSig) {
      B.subs.clear();
      log.pasos.add('SIGKILL de A anula todas las subrutinas de B');
    }
    if (bSig) {
      A.subs.clear();
      log.pasos.add('SIGKILL de B anula todas las subrutinas de A');
    }
    // Pasiva WARDEN: ignora una subrutina rival (la más cara).
    if (A.usaWarden) _cancelarMasCara(B, log, 'Pasiva WARDEN(A)');
    if (B.usaWarden) _cancelarMasCara(A, log, 'Pasiva WARDEN(B)');
    if (A.tiene(SubId.escudo)) A.protegida = true;
    if (B.tiene(SubId.escudo)) B.protegida = true;

    // ── PASO 2: ANULACIÓN (→ empate) ──
    // MURO-BALUARTE es inmune a anulación (v0.4): un muro real contra la disrupción.
    if (A.tiene(SubId.cuarentena) && !_inmuneAnulacion(B)) {
      B.anulada = true;
      log.pasos.add('CUARENTENA(A) anula la Rutina de B → empate');
    }
    if (B.tiene(SubId.cuarentena) && !_inmuneAnulacion(A)) {
      A.anulada = true;
      log.pasos.add('CUARENTENA(B) anula la Rutina de A → empate');
    }
    if (A.tiene(SubId.loopback) && !_inmuneAnulacion(B) && _repitio(B)) {
      B.anulada = true;
      log.pasos.add('LOOPBACK(A): B repitió ${B.tipo.simbolo} → anulada → empate');
    }
    if (B.tiene(SubId.loopback) && !_inmuneAnulacion(A) && _repitio(A)) {
      A.anulada = true;
      log.pasos.add('LOOPBACK(B): A repitió ${A.tipo.simbolo} → anulada → empate');
    }

    // ── PASO 3: CICLO ──
    // FORK (al inicio): copia la última subrutina activa del rival (≠ fork) y la
    // re-inyecta en el forker para que la procesen los pasos 3-4-7.
    _aplicarFork(A, B, log);
    _aplicarFork(B, A, log);

    final aInv = A.tiene(SubId.inversion);
    final bInv = B.tiene(SubId.inversion);
    final invertido = aInv ^ bInv; // ambos ⇒ se cancela
    log.invertido = invertido;
    if (invertido) log.pasos.add('INVERSIÓN: triángulo invertido esta ronda');

    _rotar(A, B, log);
    _rotar(B, A, log);

    if (A.tiene(SubId.glitch) || B.tiene(SubId.glitch)) {
      if (!A.protegida) A.tipo = Tipo.values[rng.nextInt(3)];
      if (!B.protegida) B.tipo = Tipo.values[rng.nextInt(3)];
      log.pasos.add('GLITCH: tipos aleatorizados → A=${A.tipo.simbolo} B=${B.tipo.simbolo}');
    }

    // ── PASO 4: CICLOS ──
    if (A.tiene(SubId.overclock) && a.rutina != RutinaId.nullShard) A.ciclos += 4;
    if (B.tiene(SubId.overclock) && b.rutina != RutinaId.nullShard) B.ciclos += 4;
    if (A.tiene(SubId.throttle)) _throttle(A, B, log);
    if (B.tiene(SubId.throttle)) _throttle(B, A, log);
    if (A.usaCorrupted) {
      A.ciclos += 5;
      log.pasos.add('Pasiva CORRUPTED(A): +5 Ciclos');
    }
    if (B.usaCorrupted) {
      B.ciclos += 5;
      log.pasos.add('Pasiva CORRUPTED(B): +5 Ciclos');
    }

    A.ciclos = A.ciclos.clamp(0, 99);
    B.ciclos = B.ciclos.clamp(0, 99);
    log.ciclosFinalA = A.ciclos;
    log.ciclosFinalB = B.ciclos;
    log.anuladaA = A.anulada;
    log.anuladaB = B.anulada;
    log.tipoA = A.tipo;
    log.tipoB = B.tipo;

    // ── PASO 5: MATCHUP ──
    var ganador = matchup(
      tipoA: A.tipo,
      tipoB: B.tipo,
      ciclosA: A.ciclos,
      ciclosB: B.ciclos,
      anuladaA: A.anulada,
      anuladaB: B.anulada,
      invertido: invertido,
      alineacionA: A.ps.alineacion,
      alineacionB: B.ps.alineacion,
    );

    // PARCHE: el perdedor convierte su derrota en empate.
    if (ganador == 1 && B.tiene(SubId.parche)) {
      ganador = 0;
      log.pasos.add('PARCHE(B): derrota → empate');
    } else if (ganador == 2 && A.tiene(SubId.parche)) {
      ganador = 0;
      log.pasos.add('PARCHE(A): derrota → empate');
    }

    // NULL-CORE CORRUPCIÓN (v0.4): convierte UN empate en victoria. (Sin bonus −2.)
    int danioGanador = 1;
    if (A.usaNullCore && ganador == 0) {
      ganador = 1;
      log.pasos.add('CORRUPCIÓN(A): empate → victoria');
    }
    if (B.usaNullCore && ganador == 0) {
      ganador = 2;
      log.pasos.add('CORRUPCIÓN(B): empate → victoria');
    }

    // FORK-BOMB: el ganador inflige 2.
    if (ganador == 1 && A.tiene(SubId.forkBomb)) danioGanador = 2;
    if (ganador == 2 && B.tiene(SubId.forkBomb)) danioGanador = 2;
    if (danioGanador == 2 && ganador != 0) {
      log.notas.add('FORK-BOMB: daño aumentado a −2');
    }

    // MUERTE SÚBITA: desde la ronda 7 los empates se rompen por Ciclos
    // (mayor Ciclos gana; si igualan, A). Evita estancamientos eternos.
    if (ganador == 0 && turno >= 7) {
      ganador = A.ciclos >= B.ciclos ? 1 : 2;
      log.muerteSubita = true;
      log.notas
          .add('MUERTE SÚBITA: desempate por Ciclos → gana ${ganador == 1 ? 'A' : 'B'}');
    }

    // ── PASO 6: DAÑO + TRIGGERS ──
    if (ganador == 1) {
      B.ps.integridad -= danioGanador;
      log.danioB = danioGanador;
      _triggersGanador(A, B, rng, log, 'A');
      _triggersPerdedor(B, rng, log, 'B');
    } else if (ganador == 2) {
      A.ps.integridad -= danioGanador;
      log.danioA = danioGanador;
      _triggersGanador(B, A, rng, log, 'B');
      _triggersPerdedor(A, rng, log, 'A');
    }

    // ZERO-DAY recalienta (−1 RAM próxima ronda), gane o pierda.
    if (a.rutina == RutinaId.zeroDay) A.ps.ramDeltaNext -= 1;
    if (b.rutina == RutinaId.zeroDay) B.ps.ramDeltaNext -= 1;

    // FORK-BOMB del perdedor: −1 Integridad adicional (apuesta simétrica: −2 ganes o pierdas).
    if (ganador == 1 && B.tiene(SubId.forkBomb)) {
      B.ps.integridad -= 1;
      log.danioB += 1;
      log.notas.add('FORK-BOMB(B) falló: −1 Integridad extra');
    }
    if (ganador == 2 && A.tiene(SubId.forkBomb)) {
      A.ps.integridad -= 1;
      log.danioA += 1;
      log.notas.add('FORK-BOMB(A) falló: −1 Integridad extra');
    }

    // ── PASO 7: POST (robos / retardo) ──
    for (final s in [A, B]) {
      if (s.tiene(SubId.recovery)) {
        s.ps.robarSub(rng);
        s.ps.robarSub(rng);
      }
      if (s.tiene(SubId.defrag) && s.ps.descarteSubs.isNotEmpty) {
        s.ps.manoSubs.add(s.ps.descarteSubs.removeLast());
      }
      if (s.tiene(SubId.buffer)) s.ps.ramDeltaNext += 1; // BUFFER: +1 RAM próxima ronda (simplificación)
    }

    log.ganador = ganador;
    log.integridadA = A.ps.integridad;
    log.integridadB = B.ps.integridad;
    return log;
  }

  bool _repitio(_Side s) =>
      s.ps.ultimaRutinaTipo != null && s.ps.ultimaRutinaTipo == s.tipo;

  /// Una Rutina es inmune a anulación si está protegida (Escudo) o es MURO-BALUARTE.
  bool _inmuneAnulacion(_Side s) =>
      s.protegida || s.play.rutina == RutinaId.muroBaluarte;

  void _cancelarMasCara(_Side victima, RoundLog log, String quien) {
    if (victima.subs.isEmpty) return;
    victima.subs.sort((x, y) => subDe(y).costeRam.compareTo(subDe(x).costeRam));
    final quitada = victima.subs.removeAt(0);
    log.pasos.add('$quien ignora ${subDe(quitada).nombre}');
  }

  void _throttle(_Side from, _Side to, RoundLog log) {
    if (to.protegida) return;
    if (to.play.rutina == RutinaId.muroBaluarte) return; // inmune
    if (to.play.rutina == RutinaId.nullShard) return; // no recibe mods de Ciclos
    to.ciclos -= 4;
    log.pasos.add('THROTTLE: −4 Ciclos al rival');
  }

  void _rotar(_Side from, _Side to, RoundLog log) {
    if (!from.tiene(SubId.rotacion)) return;
    final obj = from.play.rotacionObjetivo ?? RotacionObjetivo.propia;
    final target = obj == RotacionObjetivo.propia ? from : to;
    if (target != from && target.protegida) {
      log.pasos.add('ROTACIÓN bloqueada por ESCUDO del rival');
      return;
    }
    final antes = target.tipo;
    target.tipo = target.tipo.siguiente;
    log.pasos.add('ROTACIÓN: ${antes.simbolo} → ${target.tipo.simbolo}');
  }

  void _aplicarFork(_Side forker, _Side rival, RoundLog log) {
    if (!forker.tiene(SubId.fork)) return;
    SubId? copia;
    for (final s in rival.subs.reversed) {
      if (s != SubId.fork) {
        copia = s;
        break;
      }
    }
    if (copia == null) return;
    forker.subs.add(copia);
    log.pasos.add('FORK: copia ${subDe(copia).nombre} del rival');
  }

  void _triggersGanador(_Side win, _Side lose, Rng rng, RoundLog log, String w) {
    switch (win.play.rutina) {
      case RutinaId.hotfix:
        log.notas.add('HOTFIX($w): el rival no roba esta ronda');
        // Marca al perdedor para que Game omita su robo.
        log.notas.add('__NOROBA__${lose.ps.index}');
      case RutinaId.gusano:
        if (lose.ps.descarteSubs.isNotEmpty) {
          win.ps.manoSubs.add(lose.ps.descarteSubs.removeLast());
          log.notas.add('GUSANO($w): roba 1 subrutina del descarte rival');
        }
      case RutinaId.broadcast:
        win.ps.ramDeltaNext += 2;
        log.notas.add('BROADCAST($w): +2 RAM la próxima ronda');
      default:
        break;
    }
  }

  void _triggersPerdedor(_Side lose, Rng rng, RoundLog log, String l) {
    if (lose.play.rutina == RutinaId.pulsoEcho) {
      lose.ps.robarRutina(rng);
      lose.ps.ramDeltaNext += 1;
      log.notas.add('PULSO-ECHO($l): roba 1 Rutina y +1 RAM próxima ronda');
    }
  }

}
