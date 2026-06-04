/* ============================================================
   NODEHACK — MENU + NÚCLEO SELECT
   Exposes: window.MenuScreen, window.NucleoScreen
   ============================================================ */
const { NUCLEOS: M_NUCLEOS, TYPES: M_TYPES } = window.NH;
const { useState: M_useState, useEffect: M_useEffect } = React;

/* Decorative boot log line */
function BootLine({ children, delay }) {
  const [shown, setShown] = M_useState(false);
  M_useEffect(() => { const t = setTimeout(() => setShown(true), delay); return () => clearTimeout(t); }, []);
  return <div className="menu-boot-line" style={{ opacity: shown ? 1 : 0 }}>{children}</div>;
}

function MenuScreen({ onPlay, onDeck, onNucleo, nucleo }) {
  return (
    <div className="screen menu-screen">
      <div className="menu-grid-bg" />
      <div className="menu-scanlines" />

      <header className="menu-head">
        <div className="menu-boot">
          <BootLine delay={120}>&gt; init kernel...... <span className="ok">OK</span></BootLine>
          <BootLine delay={360}>&gt; mount /dev/null... <span className="ok">OK</span></BootLine>
          <BootLine delay={600}>&gt; load PROGRAM_NULL <span className="warn">⚠ inestable</span></BootLine>
        </div>
        <h1 className="menu-title">NODEHACK</h1>
        <div className="menu-subtitle">:: PROGRAM_NULL</div>
        <div className="menu-tagline">Dos procesos. Una máquina muriendo.</div>
      </header>

      <nav className="menu-nav">
        <button className="menu-btn primary" onClick={onPlay}>
          <span className="menu-btn-glyph">⚔</span>
          <span className="menu-btn-body">
            <span className="menu-btn-label">PARTIDA vs CPU</span>
            <span className="menu-btn-sub">Duelo de resolución simultánea</span>
          </span>
          <span className="menu-btn-arrow">▸</span>
        </button>

        <button className="menu-btn" onClick={onDeck}>
          <span className="menu-btn-glyph">▤</span>
          <span className="menu-btn-body">
            <span className="menu-btn-label">CREAR MAZO</span>
            <span className="menu-btn-sub">10 Rutinas · 20 Subrutinas</span>
          </span>
          <span className="menu-btn-arrow">▸</span>
        </button>

        <button className="menu-btn" onClick={onNucleo}>
          <span className="menu-btn-glyph">◈</span>
          <span className="menu-btn-body">
            <span className="menu-btn-label">NÚCLEO</span>
            <span className="menu-btn-sub">Activo: {nucleo ? nucleo.name : '—'}</span>
          </span>
          <span className="menu-btn-arrow">▸</span>
        </button>

        <button className="menu-btn ghost" disabled>
          <span className="menu-btn-glyph">⌬</span>
          <span className="menu-btn-body">
            <span className="menu-btn-label">COLECCIÓN</span>
            <span className="menu-btn-sub">Bloqueado — próximamente</span>
          </span>
          <span className="menu-btn-lock">🔒</span>
        </button>
      </nav>

      <footer className="menu-foot">
        <span>v0.3.1 · build_null</span>
        <span className="menu-foot-status"><i className="dot" /> conexión: local</span>
      </footer>
    </div>
  );
}

function NucleoScreen({ onBack, nucleo, setNucleo }) {
  const [sel, setSel] = M_useState(nucleo ? nucleo.id : M_NUCLEOS[0].id);
  const cur = M_NUCLEOS.find(n => n.id === sel);
  return (
    <div className="screen nucleo-screen">
      <div className="menu-grid-bg" />
      <div className="topbar">
        <button className="topbar-back" onClick={onBack}>‹ MENÚ</button>
        <span className="topbar-title">SELECCIÓN DE NÚCLEO</span>
        <span className="topbar-spacer" />
      </div>

      {/* Hero del núcleo seleccionado */}
      <div className="nucleo-hero" style={{ '--nc': cur.color }}>
        <div className="nucleo-hero-ring" />
        <div className="nucleo-hero-glyph"><Sigil type={cur.type} size={84} /></div>
        <div className="nucleo-hero-meta">
          <div className="nucleo-hero-handle">{cur.handle}</div>
          <h2 className="nucleo-hero-name">{cur.name}</h2>
          <div className="nucleo-hero-tag">{cur.tag}</div>
          <div className="nucleo-hero-stats">
            <span>RAM <b>{cur.ram}</b></span>
            <span>INTEGRIDAD <b>{cur.integrity}</b></span>
            <span>TIPO <b style={{ color: cur.color }}>{M_TYPES[cur.type].label}</b></span>
          </div>
        </div>
      </div>
      <div className="nucleo-passive" style={{ '--nc': cur.color }}>
        <span className="nucleo-passive-tag">PASIVA</span>
        <p>{cur.passive}</p>
      </div>

      {/* Selector */}
      <div className="nucleo-list">
        {M_NUCLEOS.map(n => (
          <button key={n.id} className={'nucleo-chip' + (n.id === sel ? ' active' : '')}
            style={{ '--nc': n.color }} onClick={() => setSel(n.id)}>
            <Sigil type={n.type} size={30} />
            <span className="nucleo-chip-name">{n.name}</span>
          </button>
        ))}
      </div>

      <div className="screen-foot">
        <button className="btn-wide" onClick={() => { setNucleo(cur); onBack(); }}>
          CONFIRMAR NÚCLEO ▸
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { MenuScreen, NucleoScreen });
