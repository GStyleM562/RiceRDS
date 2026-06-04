/* ============================================================
   NODEHACK — DECKS (lista de mazos + favoritos) + BUILDER + FLUSH
   Exposes: window.DecksScreen, window.DeckBuilderScreen, window.FlushScreen
   Cada mazo = { id, name, nucleoId, rut:{}, sub:{}, favorite }
   ============================================================ */
const { useState: D_useState } = React;
const { RUTINAS: D_RUTINAS, SUBRUTINAS: D_SUBRUTINAS, NUCLEOS: D_NUCLEOS, TYPES: D_TYPES, RAR: D_RAR } = window.NH;

const RUT_TARGET = 10, SUB_TARGET = 20, MAX_DECKS = 12;
const sum = (o) => Object.values(o).reduce((a, b) => a + b, 0);
const deckReady = (d) => sum(d.rut) === RUT_TARGET && sum(d.sub) === SUB_TARGET;
const nucleoOf = (id) => D_NUCLEOS.find(n => n.id === id) || D_NUCLEOS[0];

/* ---------------- LISTA DE MAZOS ---------------- */
function DecksScreen({ decks, onBack, onNew, onEdit, onToggleFav, onDelete }) {
  const favs = decks.filter(d => d.favorite);
  const rest = decks.filter(d => !d.favorite);

  const DeckRow = ({ d }) => {
    const nuc = nucleoOf(d.nucleoId);
    const ready = deckReady(d);
    return (
      <div className="deckcard" style={{ '--nc': nuc.color }} onClick={() => onEdit(d.id)}>
        <div className="deckcard-glyph"><Sigil type={nuc.type} size={34} /></div>
        <div className="deckcard-body">
          <div className="deckcard-name">{d.name}</div>
          <div className="deckcard-meta">
            <span style={{ color: nuc.color }}>{nuc.name}</span>
            <span className="deckcard-sep">·</span>
            <span className={ready ? 'ok' : 'warn'}>{sum(d.rut)}/{RUT_TARGET}R · {sum(d.sub)}/{SUB_TARGET}S</span>
          </div>
        </div>
        {!ready && <span className="deckcard-flag">INCOMPLETO</span>}
        <button className={'deckcard-star' + (d.favorite ? ' on' : '')} title="Favorito"
          onClick={(e) => { e.stopPropagation(); onToggleFav(d.id); }}>★</button>
        <button className="deckcard-del" title="Eliminar"
          onClick={(e) => { e.stopPropagation(); onDelete(d.id); }}>✕</button>
      </div>
    );
  };

  return (
    <div className="screen decks-screen">
      <MatrixRain intensity={3} />
      <div className="menu-grid-bg" />
      <div className="topbar">
        <button className="topbar-back" onClick={onBack}>‹ MENÚ</button>
        <span className="topbar-title">MIS MAZOS</span>
        <span className="topbar-count">{decks.length}/{MAX_DECKS}</span>
      </div>

      <div className="decks-scroll">
        {favs.length > 0 && (
          <div className="decks-section">
            <div className="decks-section-head"><span className="decks-section-star">★</span> FAVORITOS</div>
            {favs.map(d => <DeckRow key={d.id} d={d} />)}
          </div>
        )}
        <div className="decks-section">
          {favs.length > 0 && <div className="decks-section-head">TODOS</div>}
          {rest.length === 0 && favs.length === 0 && (
            <div className="decks-empty">
              <div className="decks-empty-glyph">▤</div>
              <p>No hay mazos todavía.</p>
              <span>Crea tu primer mazo: elige un Núcleo y sus cartas.</span>
            </div>
          )}
          {rest.map(d => <DeckRow key={d.id} d={d} />)}
        </div>
      </div>

      <div className="screen-foot">
        <button className={'btn-wide' + (decks.length >= MAX_DECKS ? ' muted' : '')}
          disabled={decks.length >= MAX_DECKS} onClick={onNew}>
          {decks.length >= MAX_DECKS ? `MÁXIMO ${MAX_DECKS} MAZOS` : '+ NUEVO MAZO'}
        </button>
      </div>
    </div>
  );
}

/* ---------------- CONSTRUCTOR (por mazo) ---------------- */
function DeckBuilderScreen({ deck, onSave, onCancel }) {
  const [name, setName] = D_useState(deck.name);
  const [nucleoId, setNucleoId] = D_useState(deck.nucleoId);
  const [rut, setRut] = D_useState({ ...deck.rut });
  const [sub, setSub] = D_useState({ ...deck.sub });
  const [tab, setTab] = D_useState('rutinas');

  const rutCount = sum(rut), subCount = sum(sub);
  const list = tab === 'rutinas' ? D_RUTINAS : D_SUBRUTINAS;
  const counts = tab === 'rutinas' ? rut : sub;
  const setCounts = tab === 'rutinas' ? setRut : setSub;
  const target = tab === 'rutinas' ? RUT_TARGET : SUB_TARGET;
  const total = tab === 'rutinas' ? rutCount : subCount;
  const maxCopies = tab === 'rutinas' ? 3 : 5;
  const nuc = nucleoOf(nucleoId);

  const inc = (id, d) => setCounts(c => {
    const cur = c[id] || 0;
    const nv = Math.max(0, Math.min(maxCopies, cur + d));
    if (d > 0 && total >= target) return c;
    return { ...c, [id]: nv };
  });

  const ready = rutCount === RUT_TARGET && subCount === SUB_TARGET && name.trim();

  return (
    <div className="screen deck-screen">
      <div className="menu-grid-bg" />
      <div className="topbar">
        <button className="topbar-back" onClick={onCancel}>‹ CANCELAR</button>
        <span className="topbar-title">CONSTRUCTOR</span>
        <span className="topbar-spacer" />
      </div>

      {/* nombre + núcleo */}
      <div className="builder-head">
        <input className="builder-name" value={name} maxLength={22}
          placeholder="NOMBRE DEL MAZO" onChange={e => setName(e.target.value)} />
        <div className="builder-nucleo" style={{ '--nc': nuc.color }}>
          <span className="builder-nucleo-label">NÚCLEO</span>
          <div className="builder-nucleo-chips">
            {D_NUCLEOS.map(n => (
              <button key={n.id} className={'builder-nuc-chip' + (n.id === nucleoId ? ' active' : '')}
                style={{ '--nc': n.color }} onClick={() => setNucleoId(n.id)} title={n.name}>
                <Sigil type={n.type} size={22} />
              </button>
            ))}
          </div>
          <span className="builder-nucleo-name" style={{ color: nuc.color }}>{nuc.name}</span>
        </div>
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
                    ? <span style={{ color: (D_TYPES[card.type] || {}).color }}>{(D_TYPES[card.type] || {}).label} · {card.ciclos} CYC</span>
                    : <span>RAM {card.ram}</span>}
                  <span className="deck-row-rar">{D_RAR[card.rar]}</span>
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
        <button className={'btn-wide' + (ready ? '' : ' muted')} disabled={!ready}
          onClick={() => onSave({ ...deck, name: name.trim(), nucleoId, rut, sub })}>
          {ready ? 'GUARDAR MAZO ▸' : !name.trim() ? 'PONLE NOMBRE AL MAZO' : `FALTAN ${(RUT_TARGET - rutCount) + (SUB_TARGET - subCount)} CARTAS`}
        </button>
      </div>
    </div>
  );
}

/* ---------------- FLUSH (resultado) ---------------- */
function FlushScreen({ outcome, meta, onMenu, onAgain }) {
  const win = outcome === 'win';
  return (
    <div className={'screen flush-screen ' + (win ? 'win' : 'lose')}>
      <div className="menu-grid-bg" />
      <div className="flush-scanlines" />
      <div className="flush-core">
        <div className="flush-glitch" data-text={win ? 'FLUSH' : 'CORE DUMP'}>{win ? 'FLUSH' : 'CORE DUMP'}</div>
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

Object.assign(window, { DecksScreen, DeckBuilderScreen, FlushScreen, NH_DECK_HELPERS: { deckReady, nucleoOf, MAX_DECKS } });
