/* ============================================================
   NODEHACK :: PROGRAM_NULL — GAME DATA (single source of truth)
   Plain JS. Exposes window.NH = { TYPES, TRIANGLE, NUCLEOS, RUTINAS, SUBRUTINAS, ... }
   Cartas = procesos manifestados desde datos (no objetos físicos).
   ============================================================ */
(function () {
  // ---- Tipos del triángulo ------------------------------------------------
  const TYPES = {
    firewall: { id: 'firewall', label: 'CORTAFUEGOS', short: 'FW', color: '#3fc7ec', beats: 'exploit'  },
    exploit:  { id: 'exploit',  label: 'EXPLOIT',     short: 'XP', color: '#ff4068', beats: 'signal'   },
    signal:   { id: 'signal',   label: 'PULSO',       short: 'PL', color: '#26e6a4', beats: 'firewall' },
    null:     { id: 'null',     label: 'NULL',        short: '∅',  color: '#b061ff', beats: null       },
  };
  // firewall > exploit > signal > firewall
  const TRIANGLE = { firewall: 'exploit', exploit: 'signal', signal: 'firewall' };

  const RAR = { C: 'COMÚN', R: 'RARA', E: 'ÉPICA', N: 'NULL' };

  // ---- Núcleos (personajes) ----------------------------------------------
  // Cada núcleo: identidad + pasiva + RAM base + integridad base.
  const NUCLEOS = [
    {
      id: 'sentinel', name: 'SENTINEL', handle: 'sys.guardian', type: 'firewall',
      tag: 'Defensa adaptativa',
      passive: 'BLINDAJE — La primera vez por partida que perderías integridad, la anulas.',
      ram: 5, integrity: 4, color: '#3fc7ec',
    },
    {
      id: 'wraith', name: 'WRAITH', handle: 'ghost.shell', type: 'exploit',
      tag: 'Intrusión agresiva',
      passive: 'INYECCIÓN — Si ganas la ronda con EXPLOIT, robas 1 Subrutina extra.',
      ram: 5, integrity: 4, color: '#ff4068',
    },
    {
      id: 'echo', name: 'ECHO', handle: 'wave.daemon', type: 'signal',
      tag: 'Control de tempo',
      passive: 'RESONANCIA — Empiezas cada ronda con +1 RAM si tu Rutina es PULSO.',
      ram: 6, integrity: 4, color: '#26e6a4',
    },
    {
      id: 'nullkey', name: 'NULL-KEY', handle: 'void.root', type: 'null',
      tag: 'Comodín inestable',
      passive: 'CORRUPCIÓN — Tus NULL-SHARD cuestan −1 RAM, pero pierdes 1 RAM máx.',
      ram: 4, integrity: 4, color: '#b061ff', locked: false,
    },
  ];

  // ---- Catálogo de RUTINAS (Mazo de Acción, 10 en un mazo) ----------------
  // ciclos = velocidad/prioridad. tipo del triángulo.
  const RUTINAS = [
    { id: 'fw_base',  name: 'CORTAFUEGOS', type: 'firewall', ciclos: 5, rar: 'C', proc: 'firewall.proc',  txt: 'Rutina base. Vence a EXPLOIT.' },
    { id: 'fw_iron',  name: 'IRON-WALL',   type: 'firewall', ciclos: 7, rar: 'R', proc: 'ironwall.sys',    txt: 'Si ganas, no recibes Subrutinas de daño esta ronda.' },
    { id: 'xp_base',  name: 'EXPLOIT',     type: 'exploit',  ciclos: 5, rar: 'C', proc: 'exploit.bin',     txt: 'Rutina base. Vence a PULSO.' },
    { id: 'xp_zero',  name: 'ZERO-DAY',    type: 'exploit',  ciclos: 9, rar: 'R', proc: '0day.exploit',    txt: 'Gana los espejos de EXPLOIT por Ciclos. Coste: −1 RAM la próxima ronda.' },
    { id: 'pl_base',  name: 'PULSO',       type: 'signal',   ciclos: 5, rar: 'C', proc: 'pulse.sig',       txt: 'Rutina base. Vence a CORTAFUEGOS.' },
    { id: 'pl_emp',   name: 'EMP-BURST',   type: 'signal',   ciclos: 8, rar: 'R', proc: 'emp.burst',       txt: 'Si ganas, el rival roba 1 carta menos la próxima ronda.' },
    { id: 'null_sh',  name: 'NULL-SHARD',  type: 'null',     ciclos: 6, rar: 'N', proc: 'shard.null',      txt: 'Comodín. Declaras su tipo al programar. Inmune a Overclock/Throttle.' },
  ];

  // ---- Catálogo de SUBRUTINAS (Mazo de Alteración, 20 en un mazo) ---------
  // ram = coste. Sin tipo de triángulo. Alteran/disrumpen la ronda.
  const SUBRUTINAS = [
    { id: 'overclock',  name: 'OVERCLOCK',  ram: 1, rar: 'C', proc: 'clk.boost',  txt: '+4 Ciclos a tu Rutina.' },
    { id: 'throttle',   name: 'THROTTLE',   ram: 1, rar: 'C', proc: 'clk.choke',  txt: '−4 Ciclos a la Rutina del rival.' },
    { id: 'cuarentena', name: 'CUARENTENA', ram: 2, rar: 'R', proc: 'quar.kill',  txt: 'Anula la Rutina del rival → la ronda es EMPATE.' },
    { id: 'mirror',     name: 'MIRROR',     ram: 2, rar: 'R', proc: 'mirror.ref',  txt: 'Copia el tipo de la Rutina del rival antes de resolver.' },
    { id: 'sigkill',    name: 'SIGKILL',    ram: 3, rar: 'E', proc: 'sig.kill -9', txt: 'Anula TODAS las Subrutinas del rival esta ronda.' },
    { id: 'forkbomb',   name: 'FORK-BOMB',  ram: 3, rar: 'E', proc: 'fork.bomb',   txt: 'Si ganas la ronda, el rival pierde 1 integridad extra.' },
  ];

  const byId = (arr) => Object.fromEntries(arr.map(c => [c.id, c]));
  const RUT_BY = byId(RUTINAS);
  const SUB_BY = byId(SUBRUTINAS);

  // ---- Helpers de carta ---------------------------------------------------
  let _uid = 0;
  function inst(def, isSub) {
    return { ...def, uid: 'c' + (++_uid), isSub: !!isSub, declaredType: null };
  }

  // Construye una mano de ejemplo (mezcla de rutinas + subrutinas)
  function sampleHand() {
    return [
      inst(RUT_BY.fw_base),
      inst(RUT_BY.xp_zero),
      inst(SUB_BY.overclock, true),
      inst(RUT_BY.pl_base),
      inst(SUB_BY.cuarentena, true),
    ];
  }

  // ---- MAZOS / PILAS DE ROBO (Adquisición) -------------------------------
  // Cada jugador tiene DOS pilas: Rutinas (10) y Subrutinas (20).
  function makePiles() { return { rut: 10, sub: 20 }; }

  // Roba `n` cartas de las pilas. Devuelve { cards, piles, rut, sub } donde
  // rut/sub = cuántas de cada tipo se adquirieron. `needRutina` garantiza al
  // menos una Rutina en lo robado (para que la mano sea jugable).
  function drawFromPiles(piles, n, needRutina) {
    const p = { ...piles };
    const cards = [];
    let rut = 0, sub = 0;
    for (let i = 0; i < n; i++) {
      const canR = p.rut > 0, canS = p.sub > 0;
      if (!canR && !canS) break;
      let pickRut;
      if (canR && canS) pickRut = Math.random() < 0.42;  // ~42% Rutinas
      else pickRut = canR;
      if (pickRut) { cards.push(inst(RUTINAS[(Math.random() * RUTINAS.length) | 0], false)); p.rut--; rut++; }
      else { cards.push(inst(SUBRUTINAS[(Math.random() * SUBRUTINAS.length) | 0], true)); p.sub--; sub++; }
    }
    // garantía de Rutina
    if (needRutina && rut === 0 && p.rut > 0) {
      const subCard = cards.find(c => c.isSub);
      if (subCard) { Object.assign(subCard, inst(RUTINAS[(Math.random() * RUTINAS.length) | 0], false)); p.rut--; p.sub++; rut++; sub--; }
      else { cards.push(inst(RUTINAS[(Math.random() * RUTINAS.length) | 0], false)); p.rut--; rut++; }
    }
    return { cards, piles: p, rut, sub };
  }

  // Pool oculto del rival (lo que "programa" y se revela)
  function opponentPlay() {
    const rut = [RUT_BY.fw_base, RUT_BY.xp_base, RUT_BY.pl_base, RUT_BY.xp_zero, RUT_BY.pl_emp][Math.floor(Math.random() * 5)];
    const useSub = Math.random() > 0.5;
    const sub = [SUB_BY.overclock, SUB_BY.throttle][Math.floor(Math.random() * 2)];
    return { rutina: inst(rut), subs: useSub ? [inst(sub, true)] : [] };
  }

  // ---- Resolución de ronda (triángulo + ciclos + subrutinas) --------------
  // Devuelve { winner:'you'|'opp'|'draw', youCiclos, oppCiclos, log:[] }
  function resolve(you, opp) {
    const log = [];
    let yT = you.rutina.declaredType || you.rutina.type;
    let oT = opp.rutina.declaredType || opp.rutina.type;
    let yC = you.rutina.ciclos, oC = opp.rutina.ciclos;
    let annulYouSubs = false, annulOppSubs = false, forceDraw = false;

    const has = (side, id) => side.subs.some(s => s.id === id);

    // SIGKILL anula subs del rival
    if (has(you, 'sigkill')) { annulOppSubs = true; log.push('SIGKILL → subrutinas rivales anuladas'); }
    if (has(opp, 'sigkill')) { annulYouSubs = true; log.push('SIGKILL rival → tus subrutinas anuladas'); }

    // MIRROR copia tipo rival
    if (has(you, 'mirror') && !annulYouSubs) { yT = oT; log.push('MIRROR → copias el tipo rival'); }
    if (has(opp, 'mirror') && !annulOppSubs) { oT = yT; }

    // OVERCLOCK / THROTTLE (no afectan NULL)
    if (has(you, 'overclock') && !annulYouSubs && you.rutina.type !== 'null') { yC += 4; log.push('OVERCLOCK → +4 Ciclos'); }
    if (has(opp, 'overclock') && !annulOppSubs && opp.rutina.type !== 'null') { oC += 4; }
    if (has(you, 'throttle') && !annulYouSubs && opp.rutina.type !== 'null') { oC -= 4; log.push('THROTTLE → −4 Ciclos al rival'); }
    if (has(opp, 'throttle') && !annulOppSubs && you.rutina.type !== 'null') { yC -= 4; }

    // CUARENTENA fuerza empate
    if ((has(you, 'cuarentena') && !annulYouSubs) || (has(opp, 'cuarentena') && !annulOppSubs)) {
      forceDraw = true; log.push('CUARENTENA → ronda forzada a EMPATE');
    }

    let winner;
    if (forceDraw) winner = 'draw';
    else if (yT === oT || yT === 'null' && oT === 'null') {
      winner = yC > oC ? 'you' : oC > yC ? 'opp' : 'draw';
      log.push(`Espejo ${TYPES[yT].label} → decide Ciclos (${yC} vs ${oC})`);
    } else if (yT === 'null') { winner = 'you'; log.push('NULL toma ventaja'); }
    else if (oT === 'null') { winner = 'opp'; }
    else if (TRIANGLE[yT] === oT) { winner = 'you'; log.push(`${TYPES[yT].label} vence a ${TYPES[oT].label}`); }
    else { winner = 'opp'; log.push(`${TYPES[oT].label} vence a ${TYPES[yT].label}`); }

    return { winner, youCiclos: yC, oppCiclos: oC, youType: yT, oppType: oT, log };
  }

  // Fases del round (orden canónico)
  const PHASES = [
    { id: 'robo',         label: 'ROBO',         hint: 'Se roban procesos a la mano.' },
    { id: 'programacion', label: 'PROGRAMACIÓN', hint: 'Arrastra una Rutina al puesto activo. Añade Subrutinas si tienes RAM.' },
    { id: 'compilar',     label: 'COMPILAR',     hint: 'Confirmas tu jugada. Queda sellada.' },
    { id: 'revelacion',   label: 'REVELACIÓN',   hint: 'Ambos procesos se revelan a la vez.' },
    { id: 'ejecucion',    label: 'EJECUCIÓN',    hint: 'El triángulo y los Ciclos resuelven el conflicto.' },
    { id: 'resultado',    label: 'RESULTADO',    hint: 'Se aplica el daño a la integridad.' },
  ];

  window.NH = {
    TYPES, TRIANGLE, RAR, NUCLEOS, RUTINAS, SUBRUTINAS, RUT_BY, SUB_BY,
    PHASES, inst, sampleHand, opponentPlay, resolve,
    makePiles, drawFromPiles,
  };
})();
