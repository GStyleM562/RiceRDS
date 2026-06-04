/// CLI del simulador.
///
/// Ejemplos:
///   dart run bin/simulate.dart --matchup A,B --games 10000 --log 3
///   dart run bin/simulate.dart --round-robin --games 5000 --seed 42 --report docs/Partidas_auto.md
///   dart run bin/simulate.dart --matchup C,F --games 2000 --bots heuristic,counter
import 'dart:io';

import 'package:nodehack_sim/nodehack_sim.dart';

void main(List<String> args) {
  final opt = _parse(args);
  final games = int.tryParse(opt['games'] ?? '') ?? 1000;
  final seed = int.tryParse(opt['seed'] ?? '') ?? 12345;
  final logN = int.tryParse(opt['log'] ?? '') ?? 0;
  final bots = (opt['bots'] ?? 'heuristic,heuristic').split(',');
  final polA = botPorNombre(bots[0].trim());
  final polB = botPorNombre(bots.length > 1 ? bots[1].trim() : bots[0].trim());

  final runner = SimRunner();
  final stats = SimStats();
  final out = StringBuffer();
  final ids = (opt['ids'] ?? 'A,B,C,D,E,F').split(',').map((e) => e.trim()).toList();

  if (opt.containsKey('skill')) {
    final a = bots[0].trim();
    final b = bots.length > 1 ? bots[1].trim() : 'random';
    final wr = runner.skill(ids, () => botPorNombre(a), () => botPorNombre(b),
        games: games, baseSeed: seed);
    stdout.writeln('Habilidad: "$a" vs "$b"  →  win-rate de "$a" = '
        '${(wr * 100).toStringAsFixed(1)}%  (mismas barajas, posición alternada)');
    return;
  }

  if (opt.containsKey('round-robin')) {
    final s = runner.roundRobin(ids, () => botPorNombre(bots[0].trim()),
        games: games, baseSeed: seed);
    out.write(SimReport.tabla(s, ids));
    if (opt.containsKey('cards')) out.write('\n${SimReport.cartas(s)}');
    stdout.write(out.toString());
  } else {
    final m = (opt['matchup'] ?? 'A,B').split(',').map((e) => e.trim()).toList();
    var impresos = 0;
    runner.matchup(stats, m[0], m[1], polA, polB, games: games, baseSeed: seed,
        onGame: (log, izq, der) {
      if (impresos < logN) {
        stdout.writeln(GameLogger.partida(log));
        impresos++;
      }
    });
    out.write(SimReport.tabla(stats, [m[0], m[1]]));
    stdout.write(out.toString());
  }

  final reportPath = opt['report'];
  if (reportPath != null) {
    File(reportPath).writeAsStringSync(out.toString());
    stdout.writeln('\n[reporte escrito en $reportPath]');
  }
}

Map<String, String> _parse(List<String> args) {
  final m = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a.startsWith('--')) {
      final key = a.substring(2);
      if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
        m[key] = args[++i];
      } else {
        m[key] = 'true';
      }
    }
  }
  return m;
}
