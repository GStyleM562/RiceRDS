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

  // El log registra CADA efecto por AMBOS lados — "(tú)" lo jugaste tú, "(rival)"
  // lo jugó el rival — para que se entienda cómo quedó la jugada de los dos.

  // SIGKILL — anula TODAS las subrutinas del otro.
  if (_has(you, 'sigkill')) {
    annulOpp = true;
    log.add('SIGKILL (tú) → anulas las subrutinas del rival');
  }
  if (_has(opp, 'sigkill')) {
    annulYou = true;
    log.add('SIGKILL (rival) → anula tus subrutinas');
  }

  // MIRROR — copia el tipo de la Rutina del otro. Recalcula los Ciclos al nivel
  // del nuevo tipo (igual que los desplazamientos), para que tipo y Ciclos queden
  // coherentes. Si AMBOS espejan, se ANULAN (cada uno copiaría al otro: paradoja)
  // → ninguno cambia. Así el resultado es idéntico visto desde los dos lados.
  final youMirror = _has(you, 'mirror') && !annulYou;
  final oppMirror = _has(opp, 'mirror') && !annulOpp;
  if (youMirror && oppMirror) {
    log.add('MIRROR ↔ MIRROR → los dos espejos se anulan');
  } else if (youMirror) {
    yT = oT;
    yC = _tierCiclos(you.rutina, yT);
    log.add('MIRROR (tú) → copias el tipo del rival');
  } else if (oppMirror) {
    oT = yT;
    oC = _tierCiclos(opp.rutina, oT);
    log.add('MIRROR (rival) → copia tu tipo');
  }

  // DESVÍO DE FASE — mantiene el nivel (básica/avanzada): recalcula Ciclos al tipo nuevo.
  // INTRUSIÓN ▸ (shift_fwd): mueve la Rutina del RIVAL al tipo SIGUIENTE.
  if (_has(you, 'shift_fwd') && !annulYou) {
    oT = oT.next;
    oC = _tierCiclos(opp.rutina, oT);
    log.add('INTRUSIÓN (tú) → mueves la Rutina del rival a ${oT.label}');
  }
  if (_has(opp, 'shift_fwd') && !annulOpp) {
    yT = yT.next;
    yC = _tierCiclos(you.rutina, yT);
    log.add('INTRUSIÓN (rival) → mueve tu Rutina a ${yT.label}');
  }
  // ◂ RECALIBRAR (shift_back): mueve TU PROPIA Rutina al tipo ANTERIOR.
  if (_has(you, 'shift_back') && !annulYou) {
    yT = yT.prev;
    yC = _tierCiclos(you.rutina, yT);
    log.add('RECALIBRAR (tú) → mueves tu Rutina a ${yT.label}');
  }
  if (_has(opp, 'shift_back') && !annulOpp) {
    oT = oT.prev;
    oC = _tierCiclos(opp.rutina, oT);
    log.add('RECALIBRAR (rival) → mueve su Rutina a ${oT.label}');
  }
  // ◂ SABOTAJE (shift_opp_back): mueve la Rutina del RIVAL al tipo ANTERIOR.
  if (_has(you, 'shift_opp_back') && !annulYou) {
    oT = oT.prev;
    oC = _tierCiclos(opp.rutina, oT);
    log.add('SABOTAJE (tú) → mueves la Rutina del rival a ${oT.label}');
  }
  if (_has(opp, 'shift_opp_back') && !annulOpp) {
    yT = yT.prev;
    yC = _tierCiclos(you.rutina, yT);
    log.add('SABOTAJE (rival) → mueve tu Rutina a ${yT.label}');
  }
  // AVANCE ▸ (shift_you_fwd): mueve TU PROPIA Rutina al tipo SIGUIENTE.
  if (_has(you, 'shift_you_fwd') && !annulYou) {
    yT = yT.next;
    yC = _tierCiclos(you.rutina, yT);
    log.add('AVANCE (tú) → mueves tu Rutina a ${yT.label}');
  }
  if (_has(opp, 'shift_you_fwd') && !annulOpp) {
    oT = oT.next;
    oC = _tierCiclos(opp.rutina, oT);
    log.add('AVANCE (rival) → mueve su Rutina a ${oT.label}');
  }

  // OVERCLOCK / THROTTLE (no afectan a NULL).
  if (_has(you, 'overclock') && !annulYou && you.rutina.type != CType.nul) {
    yC += 4;
    log.add('OVERCLOCK (tú) → +4 a tus Ciclos');
  }
  if (_has(opp, 'overclock') && !annulOpp && opp.rutina.type != CType.nul) {
    oC += 4;
    log.add('OVERCLOCK (rival) → +4 a los Ciclos del rival');
  }
  // IRON-WALL (fw_iron) es inmune a THROTTLE (no le bajan los Ciclos).
  if (_has(you, 'throttle') && !annulYou && opp.rutina.type != CType.nul && opp.rutina.rut?.id != 'fw_iron') {
    oC -= 4;
    log.add('THROTTLE (tú) → −4 a los Ciclos del rival');
  }
  if (_has(opp, 'throttle') && !annulOpp && you.rutina.type != CType.nul && you.rutina.rut?.id != 'fw_iron') {
    yC -= 4;
    log.add('THROTTLE (rival) → −4 a tus Ciclos');
  }

  // CUARENTENA fuerza empate.
  if (_has(you, 'cuarentena') && !annulYou) {
    forceDraw = true;
    log.add('CUARENTENA (tú) → fuerzas el EMPATE');
  }
  if (_has(opp, 'cuarentena') && !annulOpp) {
    forceDraw = true;
    log.add('CUARENTENA (rival) → fuerza el EMPATE');
  }

  // INVERSIÓN (triángulo) y PARADOJA (espejo) — toggles por nº IMPAR de la carta no
  // anulada (suma de ambos lados), para que el resultado sea idéntico desde las dos
  // perspectivas (simetría flipWinner). Se registran como efecto de cada lado.
  var invTri = 0, invCyc = 0;
  if (_has(you, 'invert_tri') && !annulYou) {
    invTri++;
    log.add('INVERSIÓN (tú) → el triángulo se invierte esta ronda');
  }
  if (_has(opp, 'invert_tri') && !annulOpp) {
    invTri++;
    log.add('INVERSIÓN (rival) → el triángulo se invierte esta ronda');
  }
  if (_has(you, 'invert_cyc') && !annulYou) {
    invCyc++;
    log.add('PARADOJA (tú) → en espejo gana quien tenga MENOS Ciclos');
  }
  if (_has(opp, 'invert_cyc') && !annulOpp) {
    invCyc++;
    log.add('PARADOJA (rival) → en espejo gana quien tenga MENOS Ciclos');
  }
  final invertTri = invTri.isOdd;
  final invertCyc = invCyc.isOdd;

  Winner winner;
  if (forceDraw) {
    winner = Winner.draw;
  } else if (yT == oT) {
    final youBetter = invertCyc ? yC < oC : yC > oC;
    final oppBetter = invertCyc ? oC < yC : oC > yC;
    if (youBetter) {
      winner = Winner.you;
    } else if (oppBetter) {
      winner = Winner.opp;
    } else {
      winner = Winner.draw;
    }
    log.add('Espejo ${yT.label} → ${invertCyc ? "PARADOJA: gana MENOS Ciclos" : "deciden los Ciclos"} (tú $yC vs $oC rival)');
  } else if (yT == CType.nul) {
    winner = Winner.you;
    log.add('NULL (tú) toma ventaja');
  } else if (oT == CType.nul) {
    winner = Winner.opp;
    log.add('NULL (rival) toma ventaja');
  } else if (yT.venceA(oT)) {
    winner = invertTri ? Winner.opp : Winner.you;
    log.add(invertTri
        ? 'INVERSIÓN → el ${oT.label} del rival se impone a tu ${yT.label}'
        : 'Tu ${yT.label} vence al ${oT.label} del rival');
  } else {
    winner = invertTri ? Winner.you : Winner.opp;
    log.add(invertTri
        ? 'INVERSIÓN → tu ${yT.label} se impone al ${oT.label} del rival'
        : 'El ${oT.label} del rival vence a tu ${yT.label}');
  }

  // Daño: 1 base; FORK-BOMB del ganador (no anulada) suma +1.
  var damage = winner == Winner.draw ? 0 : 1;
  if (winner == Winner.you && _has(you, 'forkbomb') && !annulYou) {
    damage += 1;
    log.add('FORK-BOMB (tú) → +1 daño al rival');
  }
  if (winner == Winner.opp && _has(opp, 'forkbomb') && !annulOpp) {
    damage += 1;
    log.add('FORK-BOMB (rival) → +1 daño a ti');
  }

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
