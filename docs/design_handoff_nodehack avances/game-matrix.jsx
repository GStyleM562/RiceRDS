/* ============================================================
   NODEHACK — MATRIX RAIN (fondo de lluvia de código)
   Exposes: window.MatrixRain
   Canvas detrás del contenido. Sutil por defecto.

   ── MENSAJE OCULTO ─────────────────────────────────────────
   Para escribir un mensaje que "cae" dentro de la lluvia, edita
   la global antes de cargar la app, o pásalo como prop:

       window.NH_MATRIX_MESSAGE = "DESPIERTA";

   O en JSX:  <MatrixRain message="DESPIERTA" />
   El mensaje aparece periódicamente en una columna, en brillo alto.
   ──────────────────────────────────────────────────────────
   ============================================================ */
const { useRef: MX_useRef, useEffect: MX_useEffect } = React;

// glifos: mezcla hacker + katakana tenue (estilo Matrix)
const MX_GLYPHS = '01{}/<>;:[]()=+*#$%&∅01アカサタナハマヤラワabcdef0123456789'.split('');

function MatrixRain({ intensity = 4, color = '#3fc7ec', message = (window.NH_MATRIX_MESSAGE || '') }) {
  const ref = MX_useRef(null);

  MX_useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const W = 390, H = 844;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = W * dpr; canvas.height = H * dpr;
    canvas.style.width = W + 'px'; canvas.style.height = H + 'px';
    ctx.scale(dpr, dpr);

    const font = 14;
    const cols = Math.floor(W / font);
    // densidad por intensidad: cuántas columnas están "activas"
    const activeFrac = 0.32 + (intensity / 10) * 0.6;
    const rows = H / font;
    const drops = Array.from({ length: cols }, (_, i) => ({
      y: Math.random() * rows,            // repartidas por toda la pantalla (visible al instante)
      on: Math.random() < activeFrac,
      speed: 0.55 + Math.random() * 0.5 + intensity * 0.04,
    }));

    // mensaje que cae ocasionalmente en una columna
    let msg = null; // { col, row, idx }
    let sinceMsg = 120;

    const trailAlpha = 0.10 - intensity * 0.004; // más intensidad = estela más larga
    let raf, frame = 0, running = true;

    function spawnMsg() {
      if (!message) return;
      msg = { col: 1 + Math.floor(Math.random() * (cols - 2)), row: 0, idx: 0, drawn: [] };
    }

    function draw() {
      frame++;
      ctx.fillStyle = `rgba(5,7,11,${Math.max(0.05, trailAlpha)})`;
      ctx.fillRect(0, 0, W, H);
      ctx.font = `${font}px 'JetBrains Mono', monospace`;
      ctx.textAlign = 'center';

      for (let i = 0; i < cols; i++) {
        const d = drops[i];
        if (!d.on) continue;
        const x = i * font + font / 2;
        const y = d.y * font;
        // cabeza brillante
        const g = MX_GLYPHS[(Math.random() * MX_GLYPHS.length) | 0];
        ctx.fillStyle = '#dffaff';
        ctx.shadowColor = color; ctx.shadowBlur = 8;
        ctx.fillText(g, x, y);
        ctx.shadowBlur = 0;
        // rastro tenue del color
        ctx.fillStyle = color;
        ctx.globalAlpha = 0.5;
        ctx.fillText(MX_GLYPHS[(Math.random() * MX_GLYPHS.length) | 0], x, y - font);
        ctx.globalAlpha = 1;

        if (frame % 2 === 0 || intensity > 6) d.y += d.speed;
        if (y > H + font * 2) {
          d.y = Math.random() * -30;
          d.on = Math.random() < activeFrac;
          d.speed = 0.55 + Math.random() * 0.5 + intensity * 0.04;
        }
      }

      // mensaje oculto
      if (message) {
        sinceMsg++;
        if (!msg && sinceMsg > 260) { spawnMsg(); sinceMsg = 0; }
        if (msg) {
          const x = msg.col * font + font / 2;
          // dibuja la traza ya escrita, desvaneciendo
          for (let k = 0; k <= msg.idx && k < message.length; k++) {
            const yy = (msg.row - (msg.idx - k)) * font;
            const fade = 1 - (msg.idx - k) * 0.12;
            if (fade <= 0) continue;
            ctx.fillStyle = `rgba(223,250,255,${Math.max(0, fade)})`;
            ctx.shadowColor = color; ctx.shadowBlur = 12;
            ctx.fillText(message[k], x, yy);
            ctx.shadowBlur = 0;
          }
          if (frame % 4 === 0) {
            msg.row++;
            if (msg.row - msg.idx > 0 && msg.idx < message.length - 1) msg.idx++;
            else if (msg.idx >= message.length - 1) msg.idx++;
            if ((msg.row - message.length) * font > H) msg = null;
          }
        }
      }

      if (frame > 100000) frame = 0;
    }
    function loop() { draw(); if (running) raf = requestAnimationFrame(loop); }
    // pinta un fondo base y prima unos cuadros para que la lluvia sea visible al instante
    ctx.fillStyle = '#05070b'; ctx.fillRect(0, 0, W, H);
    for (let p = 0; p < 10; p++) draw();
    raf = requestAnimationFrame(loop);

    const onVis = () => { /* el navegador ya pausa rAF en background; nada que hacer */ };
    document.addEventListener('visibilitychange', onVis);
    return () => { running = false; cancelAnimationFrame(raf); document.removeEventListener('visibilitychange', onVis); };
  }, [intensity, color, message]);

  return <canvas ref={ref} className="matrix-canvas" aria-hidden="true" />;
}

Object.assign(window, { MatrixRain });
