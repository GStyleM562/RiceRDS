/* ============================================================
   NODEHACK — MATCH (mesa de duelo JUGABLE con arrastre)
   Exposes: window.MatchScreen
   Arrastre por puntero (touch + ratón) de la mano a los slots.
   ============================================================ */
const { useState: X_useState, useRef: X_useRef, useEffect: X_useEffect, useCallback: X_useCallback } = React;
const { TYPES: X_TYPES, PHASES: X_PHASES, opponentPlay, resolve: X_resolve } = window.NH;

function MatchScreen({ onExit, nucleo, onFlush }) {
  const N = nucleo || window.NH.NUCLEOS[0];
  const [phaseIdx, setPhaseIdx] = X_useState(1); // arranca en PROGRAMACIÓN
  const phase = X_PHASES[phaseIdx];

  const [hand, setHand] = X_useState(() => window.NH.sampleHand());
  const [active, setActive] = X_useState(null);          // rutina programada
  const [subs, setSubs] = X_useState([null, null]);      // dos slots de subrutina
  const [ramMax] = X_useState(N.ram);
  const ramUsed = subs.reduce((a, s) => a + (s ? s.ram : 0), 0);
  const ramLeft = ramMax - ramUsed;

  const [integrity, setIntegrity] = X_useState({ you: N.integrity, opp: N.integrity });
  const [opp, setOpp] = X_useState(null);                // jugada del rival (oculta)
  const [revealed, setRevealed] = X_useState(false);
  const [result, setResult] = X_useState(null);
  const [round, setRound] = X_useState(1);

  // NULL-SHARD: pedir tipo declarado
  const [pendingNull, setPendingNull] = X_useState(null);

  // ---------- DRAG STATE ----------
  const [drag, setDrag] = X_useState(null); // { card, x, y, ox, oy }
  const dragRef = X_useRef(null);
  const slotRefs = X_useRef({}); // id -> dom node
  const [hover, setHover] = X_useState(null); // slot id currently valid-hovered

  const setSlotRef = (id) => (el) => { if (el) slotRefs.current[id] = el; };

  const validTargets = X_useCallback((card) => {
    if (!card) return [];
    if (card.isSub) return ['sub0', 'sub1'].filter((id, i) => !subs[i] && card.ram <= ramLeft + (0));
    return ['active'];
  }, [subs, ramLeft]);

  const hitTest = X_useCallback((x, y, card) => {
    const targets = validTargets(card);
    for (const id of targets) {
      const el = slotRefs.current[id];
      if (!el) continue;
      const r = el.getBoundingClientRect();
      const pad = 26; // zona generosa para el dedo
      if (x >= r.left - pad && x <= r.right + pad && y >= r.top - pad && y <= r.bottom + pad) return id;
    }
    return null;
  }, [validTargets]);

  const onCardDown = (e, card) => {
    if (phase.id !== 'programacion') return;
    e.preventDefault();
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX, y = e.clientY;
    setDrag({ card, x, y, ox: x - rect.left - rect.width / 2, oy: y - rect.top - rect.height / 2 });
  };

  X_useEffect(() => {
    if (!drag) return;
    const move = (e) => {
      const x = e.clientX, y = e.clientY;
      setDrag(d => d ? { ...d, x, y } : d);
      setHover(hitTest(x, y, drag.card));
    };
    const up = (e) => {
      const x = e.clientX, y = e.clientY;
      const target = hitTest(x, y, drag.card);
      if (target) placeCard(drag.card, target);
      setDrag(null); setHover(null);
    };
    window.addEventListener('pointermove', move, { passive: false });
    window.addEventListener('pointerup', up);
    return () => { window.removeEventListener('pointermove', move); window.removeEventListener('pointerup', up); };
  }, [drag, hitTest]);

  function placeCard(card, target) {
    setHand(h => h.filter(c => c.uid !== card.uid));
    if (target === 'active') {
      setActive(card);
      if (card.type === 'null') setPendingNull(card.uid);
    } else {
      const idx = target === 'sub0' ? 0 : 1;
      setSubs(s => { const n = [...s]; n[idx] = card; return n; });
    }
  }

  function returnToHand(card, from) {
    if (phase.id !== 'programacion') return;
    if (from === 'active') { setActive(null); setPendingNull(null); }
    else { const idx = from === 'sub0' ? 0 : 1; setSubs(s => { const n = [...s]; n[idx] = null; return n; }); }
    setHand(h => [...h, card]);
  }

  // ---------- PHASE FLOW ----------
  function compile() {
    if (!active) return;
    // rival programa (oculto)
    const o = opponentPlay();
    setOpp(o);
    setPhaseIdx(2); // COMPILAR
    setTimeout(() => setPhaseIdx(3), 700);      // REVELACIÓN
    setTimeout(() => setRevealed(true), 1050);
    setTimeout(() => {                            // EJECUCIÓN
      setPhaseIdx(4);
      const you = { rutina: active, subs: subs.filter(Boolean) };
      const res = X_resolve(you, o);
      setResult(res);
    }, 1900);
    setTimeout(() => {                            // RESULTADO
      setPhaseIdx(5);
      setIntegrity(prev => {
        const r = JSON.parse(sessionStorage.getItem('_nh_res') || 'null');
        return prev;
      });
    }, 2700);
  }

  // aplica daño cuando hay resultado y estamos en fase resultado
  X_useEffect(() => {
    if (phase.id === 'resultado' && result && !result._applied) {
      setIntegrity(prev => {
        const next = { ...prev };
        if (result.winner === 'you') next.opp = Math.max(0, prev.opp - 1);
        else if (result.winner === 'opp') next.you = Math.max(0, prev.you - 1);
        return next;
      });
      result._applied = true;
    }
  }, [phase.id, result]);

  // fin de partida
  X_useEffect(() => {
    if (integrity.you <= 0 || integrity.opp <= 0) {
      const t = setTimeout(() => onFlush && onFlush(integrity.opp <= 0 ? 'win' : 'lose', { round }), 900);
      return () => clearTimeout(t);
    }
  }, [integrity]);

  function nextRound() {
    setActive(null); setSubs([null, null]); setOpp(null); setRevealed(false);
    setResult(null); setPendingNull(null);
    setHand(window.NH.sampleHand());
    setRound(r => r + 1);
    setPhaseIdx(1);
  }

  const declareNull = (typeId) => {
    setActive(a => a ? { ...a, declaredType: typeId } : a);
    setPendingNull(null);
  };

  // ---------- RENDER HELPERS ----------
  const Pips = ({ n, max = N.integrity, color }) => (
    <div className="mat-pips">
      {Array.from({ length: max }).map((_, i) => (
        <span key={i} className={'mat-pip' + (i < n ? ' on' : '')} style={{ '--pc': color }} />
      ))}
    </div>
  );

  const resultBanner = result && (phase.id === 'ejecucion' || phase.id === 'resultado') ? (
    <div className={'mat-result ' + result.winner}>
      <span className="mat-result-label">
        {result.winner === 'you' ? 'PROCESO GANADO' : result.winner === 'opp' ? 'PROCESO PERDIDO' : 'EMPATE'}
      </span>
      <span className="mat-result-sub">{result.log[result.log.length - 1]}</span>
    </div>
  ) : null;

  return (
    <div className="screen match-screen">
      <div className="mat-bg mat-bg-A" />

      {/* topbar */}
      <div className="match-topbar">
        <button className="topbar-back" onClick={onExit}>‹ RENDIRSE</button>
        <span className="match-round">RONDA {String(round).padStart(2, '0')}</span>
        <span className="match-seed">0x{(round * 4079).toString(16).toUpperCase()}</span>
      </div>

      {/* RIVAL */}
      <div className="mat-zone mat-opp">
        <div className="mat-status">
          <span className="mat-who" style={{ color: '#ff6b86' }}>RIVAL · proc_0x4F</span>
          <Pips n={integrity.opp} color="#ff4068" />
        </div>
        <div className="mat-fan mat-fan-top">
          {[0, 1, 2, 3].map(i => <div key={i} className="mat-mini"><GameCardBack seed={i + round * 7} /></div>)}
        </div>
        <div className="mat-row">
          <div className="mat-slot mat-sub-slot">
            {opp && opp.subs[0] && (revealed
              ? <div className="slot-card"><GameCard card={opp.subs[0]} /></div>
              : <div className="slot-card"><GameCardBack seed={91} /></div>)}
          </div>
          <div className={'mat-slot mat-active-slot' + (opp ? ' filled' : '')}>
            {opp && (revealed
              ? <div className="slot-card pop"><GameCard card={opp.rutina} /></div>
              : <div className="slot-card"><GameCardBack seed={42} /></div>)}
          </div>
          <div className="mat-slot mat-sub-slot" />
        </div>
      </div>

      {/* CENTRO — fase */}
      <div className="mat-center">
        <div className="mat-phase-track">
          {X_PHASES.map((p, i) => (
            <span key={p.id} className={'mat-phase-dot' + (i === phaseIdx ? ' on' : '') + (i < phaseIdx ? ' done' : '')} />
          ))}
        </div>
        <div className="mat-phase-name">{phase.label}</div>
        <div className="mat-phase-hint">{phase.hint}</div>
        {resultBanner}
      </div>

      {/* JUGADOR */}
      <div className="mat-zone mat-you">
        <div className="mat-row">
          <div ref={setSlotRef('sub0')} className={'mat-slot mat-sub-slot drop' + (hover === 'sub0' ? ' hot' : '') + (subs[0] ? ' filled' : '')}>
            {subs[0]
              ? <div className="slot-card" onClick={() => returnToHand(subs[0], 'sub0')}><GameCard card={subs[0]} /></div>
              : <span className="slot-tag">SUB</span>}
          </div>
          <div ref={setSlotRef('active')} className={'mat-slot mat-active-slot drop' + (hover === 'active' ? ' hot' : '') + (active ? ' filled glow' : '')}>
            {active
              ? <div className="slot-card pop" onClick={() => returnToHand(active, 'active')}><GameCard card={active} /></div>
              : <span className="slot-tag">ACTIVO</span>}
          </div>
          <div ref={setSlotRef('sub1')} className={'mat-slot mat-sub-slot drop' + (hover === 'sub1' ? ' hot' : '') + (subs[1] ? ' filled' : '')}>
            {subs[1]
              ? <div className="slot-card" onClick={() => returnToHand(subs[1], 'sub1')}><GameCard card={subs[1]} /></div>
              : <span className="slot-tag">SUB</span>}
          </div>
        </div>

        <div className="mat-status mat-you-status">
          <div className="mat-ram">
            <span>RAM</span>
            {Array.from({ length: ramMax }).map((_, i) => <i key={i} className={i < ramLeft ? 'on' : ''} />)}
            <small>{ramLeft}/{ramMax}</small>
          </div>
          <div className="mat-you-meta">
            <span className="mat-who" style={{ color: N.color }}>{N.name}</span>
            <Pips n={integrity.you} color="#26e6a4" />
          </div>
        </div>

        {/* MANO */}
        <div className="mat-hand">
          {hand.map((c, i) => {
            const n = hand.length;
            const mid = (n - 1) / 2;
            const rot = (i - mid) * 7;
            const lift = Math.abs(i - mid) * 5;
            const isDragging = drag && drag.card.uid === c.uid;
            return (
              <div key={c.uid}
                className={'mat-handcard' + (isDragging ? ' dragging' : '') + (phase.id === 'programacion' ? ' grab' : '')}
                style={{ transform: `rotate(${rot}deg) translateY(${lift}px)`, zIndex: isDragging ? 0 : 5 - Math.abs(i - mid) }}
                onPointerDown={(e) => onCardDown(e, c)}>
                <div className="mat-handcard-inner"><GameCard card={c} /></div>
              </div>
            );
          })}
        </div>

        {/* CTA por fase */}
        <div className="mat-cta">
          {phase.id === 'programacion' && (
            <button className="btn-wide" disabled={!active || pendingNull} onClick={compile}>
              {pendingNull ? 'DECLARA EL TIPO DEL NULL-SHARD' : active ? 'COMPILAR ▸' : 'ARRASTRA UNA RUTINA AL PUESTO ACTIVO'}
            </button>
          )}
          {(phase.id === 'compilar' || phase.id === 'revelacion' || phase.id === 'ejecucion') && (
            <button className="btn-wide loading" disabled>
              {phase.id === 'compilar' ? 'SELLANDO PROCESO…' : phase.id === 'revelacion' ? 'REVELANDO…' : 'EJECUTANDO…'}
            </button>
          )}
          {phase.id === 'resultado' && integrity.you > 0 && integrity.opp > 0 && (
            <button className="btn-wide" onClick={nextRound}>SIGUIENTE RONDA ▸</button>
          )}
        </div>
      </div>

      {/* GHOST arrastrado */}
      {drag && (
        <div ref={dragRef} className="mat-drag-ghost"
          style={{ left: drag.x - drag.ox, top: drag.y - drag.oy }}>
          <GameCard card={drag.card} />
        </div>
      )}

      {/* NULL-SHARD type picker */}
      {pendingNull && (
        <div className="null-picker-overlay">
          <div className="null-picker">
            <div className="null-picker-title">NULL-SHARD · declara su tipo</div>
            <div className="null-picker-row">
              {['firewall', 'exploit', 'signal'].map(t => (
                <button key={t} className="null-picker-btn" style={{ '--ac': X_TYPES[t].color }} onClick={() => declareNull(t)}>
                  <Sigil type={t} size={34} />
                  <span>{X_TYPES[t].label}</span>
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

Object.assign(window, { MatchScreen });
