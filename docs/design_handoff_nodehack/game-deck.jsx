/* ============================================================
   NODEHACK — DECK BUILDER + FLUSH (resultado de partida)
   Exposes: window.DeckScreen, window.FlushScreen
   ============================================================ */
const { useState: D_useState } = React;
const { RUTINAS: D_RUTINAS, SUBRUTINAS: D_SUBRUTINAS } = window.NH;

const RUT_TARGET = 10, SUB_TARGET = 20;

function DeckScreen({ onBack }) {
  const [tab, setTab] = D_useState('rutinas');
  // conteo por id
  const [rut, setRut] = D_useState({ fw_base: 3, xp_base: 3, pl_base: 2, xp_zero: 1, null_sh: 1 });
  const [sub, setSub] = D_useState({ overclock: 5, throttle: 5, cuarentena: 4, mirror: 3, sigkill: 2, forkbomb: 1 });

  const rutCount = Object.values(rut).reduce((a, b) => a + b, 0);
  const subCount = Object.values(sub).reduce((a, b) => a + b, 0);

  const list = tab === 'rutinas' ? D_RUTINAS : D_SUBRUTINAS;
  const counts = tab === 'rutinas' ? rut : sub;
  const setCounts = tab === 'rutinas' ? setRut : setSub;
  const target = tab === 'rutinas' ? RUT_TARGET : SUB_TARGET;
  const total = tab === 'rutinas' ? rutCount : subCount;
  const maxCopies = tab === 'rutinas' ? 3 : 5;

  const inc = (id, d) => setCounts(c => {
    const cur = c[id] || 0;
    const nv = Math.max(0, Math.min(maxCopies, cur + d));
    if (d > 0 && total >= target) return c;
    return { ...c, [id]: nv };
  });

  const ready = rutCount === RUT_TARGET && subCount === SUB_TARGET;

  return (
    <div className="screen deck-screen">
      <div className="menu-grid-bg" />
      <div className="topbar">
        <button className="topbar-back" onClick={onBack}>‹ MENÚ</button>
        <span className="topbar-title">CONSTRUCTOR DE MAZO</span>
        <span className="topbar-spacer" />
      </div>

      <div className="deck-counters">
        <button className={'deck-counter' + (tab === 'rutinas' ? ' active' : '')} onClick={() => setTab('rutinas')}>
          <span className="deck-counter-label">RUTINAS</span>
          <span className={'deck-counter-num' + (rutCount === RUT_TARGET ? ' ok' : '')}>{rutCount}<small>/{RUT_TARGET}</small></span>
        </button>
        <button className={'deck-counter' + (tab === 'subs' ? ' active' : '')} onClick={() => setTab('subs')}>
          <span className="deck-counter-label">SUBRUTINAS</span>
          <span className={'deck-counter-num' + (subCount === SUB_TARGET ? ' ok' : '')}>{subCount}<small>/{SUB_TARGET}</small></span>
        </button>
      </div>

      <div className="deck-pool">
        {list.map(card => {
          const c = counts[card.id] || 0;
          return (
            <div key={card.id} className={'deck-row' + (c > 0 ? ' in' : '')}>
              <div className="deck-row-card">
                <div className="deck-row-card-inner"><GameCard card={{ ...card, isSub: tab === 'subs', declaredType: null }} /></div>
              </div>
              <div className="deck-row-info">
                <div className="deck-row-name">{card.name}</div>
                <div className="deck-row-txt">{card.txt}</div>
                <div className="deck-row-meta">
                  {tab === 'rutinas'
                    ? <span style={{ color: (window.NH.TYPES[card.type] || {}).color }}>{(window.NH.TYPES[card.type] || {}).label} · {card.ciclos} CYC</span>
                    : <span>RAM {card.ram}</span>}
                  <span className="deck-row-rar">{window.NH.RAR[card.rar]}</span>
                </div>
              </div>
              <div className="deck-row-stepper">
                <button onClick={() => inc(card.id, -1)} disabled={c === 0}>−</button>
                <span className="deck-row-count">{c}</span>
                <button onClick={() => inc(card.id, +1)} disabled={c >= maxCopies || total >= target}>+</button>
              </div>
            </div>
          );
        })}
      </div>

      <div className="screen-foot">
        <button className={'btn-wide' + (ready ? '' : ' muted')} disabled={!ready} onClick={onBack}>
          {ready ? 'GUARDAR MAZO ▸' : `FALTAN ${(RUT_TARGET - rutCount) + (SUB_TARGET - subCount)} CARTAS`}
        </button>
      </div>
    </div>
  );
}

function FlushScreen({ outcome, meta, onMenu, onAgain }) {
  const win = outcome === 'win';
  return (
    <div className={'screen flush-screen ' + (win ? 'win' : 'lose')}>
      <div className="menu-grid-bg" />
      <div className="flush-scanlines" />
      <div className="flush-core">
        <div className="flush-glitch" data-text={win ? 'FLUSH' : 'PROGRAM_NULL'}>
          {win ? 'FLUSH' : 'CORE DUMP'}
        </div>
        <div className="flush-verdict">{win ? '> proceso rival purgado' : '> tu proceso fue terminado'}</div>
        <div className="flush-stats">
          <div className="flush-stat"><span>RESULTADO</span><b className={win ? 'g' : 'r'}>{win ? 'VICTORIA' : 'DERROTA'}</b></div>
          <div className="flush-stat"><span>RONDAS</span><b>{meta ? String(meta.round).padStart(2, '0') : '—'}</b></div>
          <div className="flush-stat"><span>FIRMA</span><b>0x{Math.floor(Math.random() * 1e6).toString(16).toUpperCase()}</b></div>
        </div>
      </div>
      <div className="flush-actions">
        <button className="btn-wide" onClick={onAgain}>REINTENTAR ▸</button>
        <button className="btn-wide ghost-btn" onClick={onMenu}>VOLVER AL MENÚ</button>
      </div>
    </div>
  );
}

Object.assign(window, { DeckScreen, FlushScreen });
