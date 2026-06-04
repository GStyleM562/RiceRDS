/// Resolución de ronda — portado de `resolve()` en game-data.js.
/// Orden: SIGKILL → MIRROR → OVERCLOCK/THROTTLE → CUARENTENA → triángulo/espejo.
library;

import 'card_instance.dart';
import 'types.dart';

enum Winner { you, opp, draw }

/// Winner visto "al revés" (para mandar a cada cliente desde su perspectiva).
Winner flipWinner(Winner w) => switch (w) {
      Winner.you => Winner.opp,
      Winner.opp => Winner.you,
      Winner.draw => Winner.draw,
    };

class Play {
  final CardInstance rutina;
  final List<CardInstance> subs;
  Play(this.rutina, this.subs);

  Map<String, dynamic> toJson() => {
        'rutina': rutina.toJson(),
        'subs': [for (final s in subs) s.toJson()],
      };

  factory Play.fromJson(Map<String, dynamic> j) => Play(
        CardInstance.fromJson(j['rutina'] as Map<String, dynamic>),
        [for (final s in (j['subs'] as List)) CardInstance.fromJson(s as Map<String, dynamic>)],
      );
}

class RoundResult {
  final Winner winner;
  final int youCiclos;
  final int oppCiclos;
  final CType youType;
  final CType oppType;
  final List<String> log;

  /// Daño a aplicar al perdedor (1 base, +1 si el ganador jugó FORK-BOMB).
  final int damage;

  RoundResult({
    required this.winner,
    required this.youCiclos,
    required this.oppCiclos,
    required this.youType,
    required this.oppType,
    required this.log,
    required this.damage,
  });

  Map<String, dynamic> toJson() => {
        'winner': winner.name,
        'youCiclos': youCiclos,
        'oppCiclos': oppCiclos,
        'youType': cTypeId(youType),
        'oppType': cTypeId(oppType),
        'log': log,
        'damage': damage,
      };

  factory RoundResult.fromJson(Map<String, dynamic> j) => RoundResult(
        winner: Winner.values.byName(j['winner'] as String),
        youCiclos: j['youCiclos'] as int,
        oppCiclos: j['oppCiclos'] as int,
        youType: cTypeFromId(j['youType'] as String)!,
        oppType: cTypeFromId(j['oppType'] as String)!,
        log: List<String>.from(j['log'] as List),
        damage: j['damage'] as int,
      );

  /// Misma ronda vista desde el otro lado (you↔opp). El servidor resuelve una vez
  /// y manda a cada cliente su versión.
  RoundResult flipped() => RoundResult(
        winner: flipWinner(winner),
        youCiclos: oppCiclos,
        oppCiclos: youCiclos,
        youType: oppType,
        oppType: youType,
        log: log,
        damage: damage,
      );
}

bool _has(Play p, String id) => p.subs.any((s) => s.isSub && s.sub!.id == id);

/// Ciclos de la Rutina al desplazarla a [newType], **respetando su nivel**:
/// básica → 5; avanzada → (firewall 7 / exploit 9 / signal 8); comodín → su valor.
int _tierCiclos(CardInstance card, CType newType) {
  if (card.isSub) return 0;
  final id = card.rut?.id ?? '';
  if (id == 'null_sh') return card.ciclos; // comodín mantiene su valor
  const advanced = {'fw_iron', 'xp_zero', 'pl_emp'};
  if (advanced.contains(id)) {
    return switch (newType) {
      CType.firewall => 7,
      CType.exploit => 9,
      CType.signal => 8,
      CType.nul => card.ciclos,
    };
  }
  return 5; // básica
}

RoundResult resolve(Play you, Play opp) {
  final log = <String>[];
  var yT = you.rutina.type; // declaredType ya resuelto en CardInstance.type
  var oT = opp.rutina.type;
  var yC = you.rutina.ciclos;
  var oC = opp.rutina.ciclos;
  var annulYou = false, annulOpp = false, forceDraw = false;

  // SIGKILL
  if (_has(you, 'sigkill')) {
    annulOpp = true;
    log.add('SIGKILL → subrutinas rivales anuladas');
  }
  if (_has(opp, 'sigkill')) {
    annulYou = true;
    log.add('SIGKILL rival → tus subrutinas anuladas');
  }

  // MIRROR (copia el tipo rival)
  if (_has(you, 'mirror') && !annulYou) {
    yT = oT;
    log.add('MIRROR → copias el tipo rival');
  }
  if (_has(opp, 'mirror') && !annulOpp) {
    oT = yT;
  }

  // DESVÍO DE FASE: INTRUSIÓN ▸ (rival al siguiente) · ◂ RECALIBRAR (tú al anterior).
  // Mantiene el nivel (básica/avanzada): los Ciclos se ajustan al tipo nuevo.
  if (_has(you, 'shift_fwd') && !annulYou) {
    oT = oT.next;
    oC = _tierCiclos(opp.rutina, oT);
    log.add('INTRUSIÓN → Rutina rival desplazada a ${oT.label}');
  }
  if (_has(opp, 'shift_fwd') && !annulOpp) {
    yT = yT.next;
    yC = _tierCiclos(you.rutina, yT);
    log.add('INTRUSIÓN rival → tu Rutina desplazada a ${yT.label}');
  }
  if (_has(you, 'shift_back') && !annulYou) {
    yT = yT.prev;
    yC = _tierCiclos(you.rutina, yT);
    log.add('RECALIBRAR → tu Rutina a ${yT.label}');
  }
  if (_has(opp, 'shift_back') && !annulOpp) {
    oT = oT.prev;
    oC = _tierCiclos(opp.rutina, oT);
  }
  // SABOTAJE ◂ (rival al anterior)
  if (_has(you, 'shift_opp_back') && !annulYou) {
    oT = oT.prev;
    oC = _tierCiclos(opp.rutina, oT);
    log.add('SABOTAJE → Rutina rival a ${oT.label}');
  }
  if (_has(opp, 'shift_opp_back') && !annulOpp) {
    yT = yT.prev;
    yC = _tierCiclos(you.rutina, yT);
    log.add('SABOTAJE rival → tu Rutina a ${yT.label}');
  }
  // AVANCE ▸ (tú al siguiente)
  if (_has(you, 'shift_you_fwd') && !annulYou) {
    yT = yT.next;
    yC = _tierCiclos(you.rutina, yT);
    log.add('AVANCE → tu Rutina a ${yT.label}');
  }
  if (_has(opp, 'shift_you_fwd') && !annulOpp) {
    oT = oT.next;
    oC = _tierCiclos(opp.rutina, oT);
  }

  // OVERCLOCK / THROTTLE (no afectan a NULL)
  if (_has(you, 'overclock') && !annulYou && you.rutina.type != CType.nul) {
    yC += 4;
    log.add('OVERCLOCK → +4 Ciclos');
  }
  if (_has(opp, 'overclock') && !annulOpp && opp.rutina.type != CType.nul) {
    oC += 4;
  }
  if (_has(you, 'throttle') && !annulYou && opp.rutina.type != CType.nul) {
    oC -= 4;
    log.add('THROTTLE → −4 Ciclos al rival');
  }
  if (_has(opp, 'throttle') && !annulOpp && you.rutina.type != CType.nul) {
    yC -= 4;
  }

  // CUARENTENA fuerza empate
  if ((_has(you, 'cuarentena') && !annulYou) ||
      (_has(opp, 'cuarentena') && !annulOpp)) {
    forceDraw = true;
    log.add('CUARENTENA → ronda forzada a EMPATE');
  }

  Winner winner;
  if (forceDraw) {
    winner = Winner.draw;
  } else if (yT == oT) {
    if (yC > oC) {
      winner = Winner.you;
    } else if (oC > yC) {
      winner = Winner.opp;
    } else {
      winner = Winner.draw;
    }
    log.add('Espejo ${yT.label} → decide Ciclos ($yC vs $oC)');
  } else if (yT == CType.nul) {
    winner = Winner.you;
    log.add('NULL toma ventaja');
  } else if (oT == CType.nul) {
    winner = Winner.opp;
  } else if (yT.venceA(oT)) {
    winner = Winner.you;
    log.add('${yT.label} vence a ${oT.label}');
  } else {
    winner = Winner.opp;
    log.add('${oT.label} vence a ${yT.label}');
  }

  // Daño: 1 base; FORK-BOMB del ganador (no anulada) suma +1.
  var damage = winner == Winner.draw ? 0 : 1;
  if (winner == Winner.you && _has(you, 'forkbomb') && !annulYou) damage += 1;
  if (winner == Winner.opp && _has(opp, 'forkbomb') && !annulOpp) damage += 1;
  if (damage == 2) log.add('FORK-BOMB → +1 daño');

  return RoundResult(
    winner: winner,
    youCiclos: yC,
    oppCiclos: oC,
    youType: yT,
    oppType: oT,
    log: log,
    damage: damage,
  );
}
