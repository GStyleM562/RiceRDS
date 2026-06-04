/* ============================================================
   NODEHACK — CARD COMPONENTS (Dirección A · Terminal)
   Exposes: window.GameCard, window.GameCardBack, window.Sigil
   ============================================================ */
const { TYPES: GC_TYPES, RAR: GC_RAR } = window.NH;

function Sigil({ type, size = 44 }) {
  const c = (GC_TYPES[type] || GC_TYPES.null).color;
  const s = { width: size, height: size, display: 'block' };
  if (type === 'firewall') return (
    <svg viewBox="0 0 48 48" style={s}>
      <polygon points="24,4 42,13 42,33 24,44 6,33 6,13" fill="none" stroke={c} strokeWidth="2.2" />
      <line x1="11" y1="20" x2="37" y2="20" stroke={c} strokeWidth="1.6" opacity=".75" />
      <line x1="11" y1="28" x2="37" y2="28" stroke={c} strokeWidth="1.6" opacity=".75" />
      <line x1="24" y1="13" x2="24" y2="20" stroke={c} strokeWidth="1.6" opacity=".5" />
      <line x1="17" y1="20" x2="17" y2="28" stroke={c} strokeWidth="1.6" opacity=".5" />
      <line x1="31" y1="20" x2="31" y2="28" stroke={c} strokeWidth="1.6" opacity=".5" />
    </svg>
  );
  if (type === 'exploit') return (
    <svg viewBox="0 0 48 48" style={s}>
      <path d="M10 10 L38 38 M38 10 L10 38" stroke={c} strokeWidth="3" strokeLinecap="square" />
      <circle cx="24" cy="24" r="4.5" fill={c} />
    </svg>
  );
  if (type === 'signal') return (
    <svg viewBox="0 0 48 48" style={s}>
      <circle cx="24" cy="24" r="3.5" fill={c} />
      <path d="M16 16 A11 11 0 0 1 16 32" fill="none" stroke={c} strokeWidth="2.2" />
      <path d="M32 16 A11 11 0 0 0 32 32" fill="none" stroke={c} strokeWidth="2.2" />
      <path d="M11 11 A18 18 0 0 1 11 37" fill="none" stroke={c} strokeWidth="2" opacity=".55" />
      <path d="M37 11 A18 18 0 0 0 37 37" fill="none" stroke={c} strokeWidth="2" opacity=".55" />
    </svg>
  );
  return (
    <svg viewBox="0 0 48 48" style={s}>
      <polygon points="24,6 42,24 24,42 6,24" fill="none" stroke={c} strokeWidth="2.4" />
      <polygon points="24,16 32,24 24,32 16,24" fill={c} opacity=".85" />
    </svg>
  );
}

/* Card sizes: full=172x240 base; we scale via wrapper. The card always renders at base
   metrics and the parent scales it — keeps text crisp & layout identical everywhere. */
function GameCard({ card, dim }) {
  const sub = card.isSub;
  const dtype = card.declaredType || card.type;
  const t = sub ? GC_TYPES.null : (GC_TYPES[dtype] || GC_TYPES.null);
  const accent = sub ? '#7d8aa0' : t.color;
  return (
    <div className={'gc-card' + (dim ? ' gc-dim' : '')} style={{ '--ac': accent }}>
      <div className="gc-grid" />
      <div className="gc-top">
        <span className="gc-kind">{sub ? 'SUBRUTINA' : 'RUTINA'}</span>
        {sub
          ? <span className="gc-ram">RAM<b>{card.ram}</b></span>
          : <span className="gc-cyc">{card.ciclos}<small>CYC</small></span>}
      </div>
      <div className="gc-name">{card.name}</div>
      <div className="gc-art">
        <div className="gc-scan" />
        {!sub
          ? <div className="gc-sigil"><Sigil type={dtype} size={40} /></div>
          : <div className="gc-subglyph">{'{ }'}</div>}
        <span className="gc-cap">&gt; {sub ? 'compiling' : 'rendering'} {card.proc}</span>
      </div>
      <div className="gc-foot">
        {!sub && <span className="gc-type">{t.label}{t.beats ? ` ▸ ${GC_TYPES[t.beats].label}` : ''}</span>}
        {sub && card.declaredType && <span className="gc-type">DECL: {GC_TYPES[card.declaredType].label}</span>}
        <p className="gc-txt">{card.txt}</p>
        <span className="gc-rar">{GC_RAR[card.rar]}</span>
      </div>
    </div>
  );
}

function GameCardBack({ seed }) {
  const hex = (seed != null ? seed : Math.floor(Math.random() * 1e6)).toString(16).padStart(5, '0').slice(0, 5);
  return (
    <div className="gc-card gc-back" style={{ '--ac': '#3a4760' }}>
      <div className="gc-grid" />
      <div className="gc-backinner">
        <div className="gc-backglyph">∅</div>
        <span className="gc-cap">&gt; proceso oculto</span>
        <span className="gc-cap gc-dimcap">0x{hex}</span>
      </div>
    </div>
  );
}

Object.assign(window, { GameCard, GameCardBack, Sigil });
