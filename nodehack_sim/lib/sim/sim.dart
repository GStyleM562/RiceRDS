/// Arnés de simulación: logger legible, estadísticas agregadas y runner masivo.
library;

import '../engine/data.dart';
import '../engine/decider.dart';
import '../engine/game.dart';
import '../engine/models.dart';
import '../engine/state.dart';

// ── LOGGER (logs legibles, estilo docs/Partidas_de_prueba) ──

class GameLogger {
  static String _subs(List<SubId> s) =>
      s.isEmpty ? '' : ' + ${s.map((x) => subDe(x).nombre).join(' + ')}';

  static String ronda(RoundLog r, String la, String lb) {
    final b = StringBuffer();
    b.writeln('── Ronda ${r.turno} ──  RAM $la:${r.ramA} $lb:${r.ramB}');
    b.writeln('  $la: ${rutinaDe(r.rutinaA).nombre}(${r.ciclosFinalA}) [${r.tipoA.simbolo}]'
        '${_subs(r.subsA)}');
    b.writeln('  $lb: ${rutinaDe(r.rutinaB).nombre}(${r.ciclosFinalB}) [${r.tipoB.simbolo}]'
        '${_subs(r.subsB)}');
    for (final p in r.pasos) b.writeln('     · $p');
    for (final n in r.notas) {
      if (!n.startsWith('__')) b.writeln('     » $n');
    }
    final ganTxt = r.ganador == 1 ? la : (r.ganador == 2 ? lb : 'EMPATE');
    final danio = r.ganador == 1
        ? '$lb −${r.danioB}'
        : r.ganador == 2
            ? '$la −${r.danioA}'
            : 'sin daño';
    b.writeln('  → gana $ganTxt  ($danio)   Integridad  $la:${r.integridadA} $lb:${r.integridadB}');
    return b.toString();
  }

  static String partida(GameLog g) {
    final la = g.deckA;
    final lb = g.deckB;
    final b = StringBuffer();
    b.writeln('═══ PARTIDA  $la (${nucleoDe(g.nucleoA).nombre}) vs '
        '$lb (${nucleoDe(g.nucleoB).nombre})  · semilla ${g.semilla} ═══');
    for (final r in g.rondas) b.write(ronda(r, la, lb));
    final ganTxt = g.ganador == 1 ? la : (g.ganador == 2 ? lb : 'EMPATE');
    b.writeln('RESULTADO: gana $ganTxt  '
        '(Integridad final $la:${g.integridadFinalA} $lb:${g.integridadFinalB}, '
        '${g.rondasJugadas} rondas'
        '${g.remontada ? ', REMONTADA' : ''}${g.muerteSubita ? ', muerte súbita' : ''})');
    return b.toString();
  }
}

// ── STATS ──

class SimStats {
  final Map<String, int> victorias = {};
  final Map<String, int> partidas = {};

  /// matriz[A][B] = victorias de A sobre B.
  final Map<String, Map<String, int>> matrizVictorias = {};
  final Map<String, Map<String, int>> matrizPartidas = {};

  int totalPartidas = 0;
  int totalRondas = 0;
  int remontadas = 0;
  int muertesSubitas = 0;
  int empatesFinales = 0;

  // Uso de cartas: veces jugada y veces que la jugó el GANADOR de la partida.
  final Map<SubId, int> subUsos = {};
  final Map<SubId, int> subGana = {};
  final Map<RutinaId, int> rutUsos = {};
  final Map<RutinaId, int> rutGana = {};

  /// Acumula uso de cartas usando el log CRUDO (ganador en términos p0/p1).
  void acumularCartas(GameLog raw) {
    for (final r in raw.rondas) {
      rutUsos[r.rutinaA] = (rutUsos[r.rutinaA] ?? 0) + 1;
      rutUsos[r.rutinaB] = (rutUsos[r.rutinaB] ?? 0) + 1;
      if (raw.ganador == 1) rutGana[r.rutinaA] = (rutGana[r.rutinaA] ?? 0) + 1;
      if (raw.ganador == 2) rutGana[r.rutinaB] = (rutGana[r.rutinaB] ?? 0) + 1;
      for (final s in r.subsA) {
        subUsos[s] = (subUsos[s] ?? 0) + 1;
        if (raw.ganador == 1) subGana[s] = (subGana[s] ?? 0) + 1;
      }
      for (final s in r.subsB) {
        subUsos[s] = (subUsos[s] ?? 0) + 1;
        if (raw.ganador == 2) subGana[s] = (subGana[s] ?? 0) + 1;
      }
    }
  }

  void registrar(String idA, String idB, GameLog g) {
    totalPartidas++;
    totalRondas += g.rondasJugadas;
    if (g.remontada) remontadas++;
    if (g.muerteSubita) muertesSubitas++;

    partidas[idA] = (partidas[idA] ?? 0) + 1;
    partidas[idB] = (partidas[idB] ?? 0) + 1;
    _bump(matrizPartidas, idA, idB);
    _bump(matrizPartidas, idB, idA);

    if (g.ganador == 1) {
      victorias[idA] = (victorias[idA] ?? 0) + 1;
      _bump(matrizVictorias, idA, idB);
    } else if (g.ganador == 2) {
      victorias[idB] = (victorias[idB] ?? 0) + 1;
      _bump(matrizVictorias, idB, idA);
    } else {
      empatesFinales++;
    }
  }

  void _bump(Map<String, Map<String, int>> m, String a, String b) {
    m.putIfAbsent(a, () => {});
    m[a]![b] = (m[a]![b] ?? 0) + 1;
  }

  double winrate(String id) =>
      (partidas[id] ?? 0) == 0 ? 0 : (victorias[id] ?? 0) / partidas[id]!;

  double get rondasPromedio => totalPartidas == 0 ? 0 : totalRondas / totalPartidas;
}

// ── RUNNER ──

class SimRunner {
  final Game _game = Game();

  /// Corre [games] partidas de un cruce, **alternando lados** para neutralizar
  /// cualquier asimetría de posición. Atribuye victorias al mazo correcto.
  void matchup(
    SimStats stats,
    String idA,
    String idB,
    Decider polA,
    Decider polB, {
    required int games,
    required int baseSeed,
    void Function(GameLog log, String izq, String der)? onGame,
  }) {
    final deckA = kMazos[idA]!;
    final deckB = kMazos[idB]!;
    for (var g = 0; g < games; g++) {
      final seed = baseSeed + g * 2654435761;
      if (g.isEven) {
        final log = _game.play(deckA, deckB, polA, polB, seed);
        stats.registrar(idA, idB, log);
        stats.acumularCartas(log);
        onGame?.call(log, idA, idB);
      } else {
        // Lados intercambiados: A juega como p1.
        final log = _game.play(deckB, deckA, polB, polA, seed);
        stats.acumularCartas(log); // cartas con ganador crudo p0/p1
        // Reinterpretar ganador: en este log, deckB es A(1) y deckA es B(2).
        final reinterp = _swap(log, idA, idB);
        stats.registrar(idA, idB, reinterp);
        onGame?.call(reinterp, idB, idA);
      }
    }
  }

  /// Devuelve una copia del log con el ganador reinterpretado para que
  /// "1 = idA, 2 = idB" independientemente del lado en que jugó.
  GameLog _swap(GameLog log, String idA, String idB) {
    final r = GameLog(idA, idB, log.nucleoB, log.nucleoA, log.semilla);
    r.rondas.addAll(log.rondas);
    r.ganador = log.ganador == 1 ? 2 : (log.ganador == 2 ? 1 : 0);
    r.integridadFinalA = log.integridadFinalB;
    r.integridadFinalB = log.integridadFinalA;
    r.remontada = log.remontada;
    r.muerteSubita = log.muerteSubita;
    return r;
  }

  /// Test de habilidad: misma baraja en ambos lados, política [pa] vs [pb],
  /// alternando posición. Devuelve el win-rate de [pa]. Si pa≫0.5, la habilidad cuenta.
  double skill(
    List<String> ids,
    Decider Function() pa,
    Decider Function() pb, {
    required int games,
    required int baseSeed,
  }) {
    var winsA = 0, total = 0;
    for (var k = 0; k < ids.length; k++) {
      final deck = kMazos[ids[k]]!;
      for (var g = 0; g < games; g++) {
        final seed = baseSeed + (k * 1000 + g) * 7919;
        if (g.isEven) {
          if (_game.play(deck, deck, pa(), pb(), seed).ganador == 1) winsA++;
        } else {
          if (_game.play(deck, deck, pb(), pa(), seed).ganador == 2) winsA++;
        }
        total++;
      }
    }
    return total == 0 ? 0 : winsA / total;
  }

  /// Round-robin de todos los mazos [ids] entre sí (pares no ordenados).
  SimStats roundRobin(
    List<String> ids,
    Decider Function() policy, {
    required int games,
    required int baseSeed,
  }) {
    final stats = SimStats();
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        matchup(stats, ids[i], ids[j], policy(), policy(),
            games: games, baseSeed: baseSeed + (i * 100 + j) * 7919);
      }
    }
    return stats;
  }
}

// ── REPORTE ──

class SimReport {
  static String tabla(SimStats s, List<String> ids) {
    final b = StringBuffer();
    b.writeln('## Win-rate por mazo  (n=${s.totalPartidas})');
    b.writeln('| Mazo | Victorias | Partidas | Win-rate |');
    b.writeln('|---|---|---|---|');
    final orden = List.of(ids)
      ..sort((x, y) => s.winrate(y).compareTo(s.winrate(x)));
    for (final id in orden) {
      final pct = (s.winrate(id) * 100).toStringAsFixed(1);
      b.writeln('| ${id} ${kMazos[id]!.nombre} | ${s.victorias[id] ?? 0} | '
          '${s.partidas[id] ?? 0} | $pct% |');
    }
    b.writeln();
    b.writeln('Rondas promedio: ${s.rondasPromedio.toStringAsFixed(2)}  ·  '
        'Remontadas: ${_pct(s.remontadas, s.totalPartidas)}  ·  '
        'Muerte súbita: ${_pct(s.muertesSubitas, s.totalPartidas)}  ·  '
        'Empates finales: ${s.empatesFinales}');
    b.writeln();
    b.writeln('## Matriz (win-rate de fila vs columna)');
    b.write('| vs |');
    for (final c in ids) b.write(' $c |');
    b.writeln();
    b.write('|---|');
    for (final _ in ids) b.write('---|');
    b.writeln();
    for (final f in ids) {
      b.write('| **$f** |');
      for (final c in ids) {
        if (f == c) {
          b.write(' — |');
        } else {
          final w = s.matrizVictorias[f]?[c] ?? 0;
          final p = s.matrizPartidas[f]?[c] ?? 0;
          b.write(p == 0 ? '  |' : ' ${(w / p * 100).toStringAsFixed(0)}% |');
        }
      }
      b.writeln();
    }
    return b.toString();
  }

  static String _pct(int n, int total) =>
      total == 0 ? '0%' : '${(n / total * 100).toStringAsFixed(1)}%';

  /// Tabla de cartas: % de victoria de la partida cuando la carta fue jugada
  /// (señal aproximada de poder). Ordenada de mayor a menor.
  static String cartas(SimStats s) {
    final b = StringBuffer();
    b.writeln('## Poder por carta (win% de la partida cuando se jugó)');
    b.writeln('| Carta | Usos | Win% jugándola |');
    b.writeln('|---|---|---|');
    final filas = <(String, int, double)>[];
    s.rutUsos.forEach((id, u) {
      filas.add((rutinaDe(id).nombre, u, (s.rutGana[id] ?? 0) / u));
    });
    s.subUsos.forEach((id, u) {
      filas.add((subDe(id).nombre, u, (s.subGana[id] ?? 0) / u));
    });
    filas.sort((x, y) => y.$3.compareTo(x.$3));
    for (final (nombre, usos, wr) in filas) {
      b.writeln('| $nombre | $usos | ${(wr * 100).toStringAsFixed(1)}% |');
    }
    return b.toString();
  }
}
