# Handoff: NODEHACK :: PROGRAM_NULL — UI/UX del juego

## Overview
**NODEHACK :: PROGRAM_NULL** es un juego de duelo táctico de **resolución simultánea** (estilo piedra-papel-tijera ampliado) para **móvil vertical**. Dos "procesos" se enfrentan en una máquina moribunda: cada jugador **programa** en secreto una jugada, ambas se **revelan a la vez** y se **ejecutan** mediante un triángulo de tipos + prioridad por *Ciclos* + alteraciones (*Subrutinas*).

Este bundle contiene un **prototipo HTML jugable** que cubre el flujo completo: **Menú → Selección de Núcleo → Constructor de Mazo → Partida (7 fases con arrastre) → FLUSH (resultado)**. Las cartas no son objetos físicos: se **manifiestan desde datos** (estética "terminal/consola").

## About the Design Files
Los archivos de este bundle son **referencias de diseño hechas en HTML/CSS/React (vía Babel en el navegador)** — prototipos que muestran el aspecto y el comportamiento deseados, **no código de producción para copiar tal cual**. La tarea es **recrear estos diseños en el entorno del proyecto destino** (React Native, React web, Flutter, Unity UI, SwiftUI, etc.) usando sus patrones y librerías establecidos. Si aún no hay entorno, elige el framework más apropiado (para un juego de cartas móvil: **React Native / Expo**, **Flutter** o un motor como **Unity/Godot** si se busca más juego) e impleméntalos ahí.

La lógica de juego (`game-data.js`) **sí es portable casi directa**: es JS puro sin dependencias y define el catálogo, el triángulo y la resolución de ronda. Úsalo como especificación ejecutable.

## Fidelity
**Alta fidelidad (hifi).** Colores, tipografías, espaciados, animaciones e interacción de arrastre son definitivos y deben recrearse con precisión. Excepción consciente: las **cartas raras épicas** aún **no** tienen tratamiento especial de impacto (pendiente de diseño futuro) — no inventes uno.

## Screens / Views

### 1. Menú principal (`MenuScreen` — `game-menu.jsx`)
- **Propósito:** punto de entrada. Botones típicos.
- **Layout:** columna, `padding: 0 22px`. Cabecera centrada arriba (boot-log monoespaciado de 3 líneas que aparecen escalonadas a 120/360/600 ms; título `NODEHACK` 54px con glitch ocasional; subtítulo `:: PROGRAM_NULL`; tagline). Debajo, nav vertical con `gap: 11px`. Pie con versión y estado de conexión.
- **Botones (`.menu-btn`):** fila glyph + cuerpo (label 15px Chakra Petch + sub 9px JetBrains Mono) + flecha. El primario (`PARTIDA vs CPU`) lleva borde cian y glow. Orden: **PARTIDA vs CPU** (→ match), **CREAR MAZO** (→ deck), **NÚCLEO** (→ nucleo, muestra el activo), **COLECCIÓN** (deshabilitado/bloqueado).
- **Estados:** hover desplaza 2px y enciende barra lateral izquierda cian; `.primary` siempre encendido; `.ghost` opacidad .45, no clicable.

### 2. Selección de Núcleo (`NucleoScreen` — `game-menu.jsx`)
- **Propósito:** elegir el personaje/núcleo (define color, RAM base, integridad y pasiva).
- **Layout:** topbar (‹ MENÚ · título · spacer). **Hero** del núcleo seleccionado (glyph SVG grande + handle + nombre 30px + tag + stats RAM/Integridad/Tipo; anillo rotatorio decorativo). Bloque **PASIVA** con borde izquierdo del color del núcleo. **Grid 2×2** de chips seleccionables. Pie con **CONFIRMAR NÚCLEO**.
- **4 núcleos:** SENTINEL (firewall, RAM5/INT4), WRAITH (exploit, 5/4), ECHO (signal, 6/4), NULL-KEY (null, 4/4). Ver `NUCLEOS` en `game-data.js` para pasivas exactas.

### 3. Constructor de Mazo (`DeckScreen` — `game-deck.jsx`)
- **Propósito:** armar el mazo: **10 Rutinas + 20 Subrutinas** (dos mazos separados).
- **Layout:** topbar. Dos **contadores** (tabs) RUTINAS `n/10` y SUBRUTINAS `n/20` (número se pone verde al llegar al objetivo). **Lista scrollable** de cartas del pool: cada fila = mini-preview de carta (50×70) + info (nombre, texto, tipo/ciclos o RAM, rareza) + **stepper** −/cuenta/+. Pie con **GUARDAR MAZO** (deshabilitado hasta 10+20, muestra cuántas faltan).
- **Reglas de copias:** máx **3** copias por Rutina, **5** por Subrutina (constantes `maxCopies`).

### 4. Partida / Mesa de duelo (`MatchScreen` — `game-match.jsx`) ★ pantalla central
- **Propósito:** jugar una ronda completa. **El arrastre con el dedo es la interacción clave.**
- **Layout (de arriba a abajo):**
  - **Topbar:** ‹ RENDIRSE · RONDA NN · seed hex.
  - **Zona RIVAL:** estado (nombre + pips de integridad rojos) · mano abanicada de **dorsos** (4 cartas, mini) · fila de slots [sub, **activo**, sub] que muestran dorsos hasta la revelación.
  - **Centro (fase):** track de 6 puntos de fase · nombre de fase (letter-spacing .3em) · hint · banner de **RESULTADO** cuando aplica.
  - **Zona JUGADOR:** fila de slots [sub0, **activo**(glow), sub1] · estado (medidor **RAM** de puntos ámbar + nombre del núcleo + pips de integridad verdes) · **mano abanicada** de cartas reales (rotación `(i-mid)*7deg`, lift por distancia al centro) · **CTA** por fase.
- **Slots como drop-targets:** `.mat-active-slot` 72×100 (solo Rutinas), `.mat-sub-slot` 52×73 ×2 (solo Subrutinas). Al pasar un arrastre válido por encima → estado `.hot` (borde verde sólido, glow, scale 1.04).

### 5. FLUSH / Resultado (`FlushScreen` — `game-deck.jsx`)
- **Propósito:** cierre de partida. Victoria = "FLUSH" (rival purgado); derrota = "CORE DUMP".
- **Layout:** título glitch grande (capas ::before/::after roja+cian) · veredicto · 3 stats (RESULTADO/RONDAS/FIRMA) · acciones **REINTENTAR** y **VOLVER AL MENÚ**. Fondo radial verde (win) o rojo (lose).

### 6. Detalle de carta
- Implementado de forma ligera: durante PROGRAMACIÓN, **tocar** una carta ya colocada en un slot la **devuelve a la mano**. El componente `GameCard` ya renderiza toda la info (tipo, ciclos/RAM, texto, rareza, “región de compilación” animada) a tamaño completo 172×240; reutilízalo para un overlay de inspección a pantalla completa si se desea.

## Interacciones & Behavior

### Arrastre (la interacción estrella) — `game-match.jsx`
Implementado con **Pointer Events** (funciona con dedo y ratón). No usa HTML5 drag-and-drop.
1. `onPointerDown` sobre `.mat-handcard` (solo en fase `programacion`) → guarda `drag = {card, x, y, ox, oy}` (offset respecto al centro de la carta). `e.preventDefault()` + `touch-action: none` en la carta evitan el scroll.
2. Un `useEffect` (dependiente de `drag`) registra en `window` los listeners `pointermove`/`pointerup` mientras se arrastra.
3. En cada `pointermove`: actualiza la posición del **ghost** (clon flotante `position: fixed`, `translate(-50%,-50%)`) y hace **hit-test** contra los slots válidos.
4. **Hit-test** (`hitTest`): rutina → solo `['active']`; subrutina → `['sub0','sub1']` libres y con RAM suficiente. Usa `getBoundingClientRect` de cada slot con un padding generoso de **26px** (zona cómoda para el dedo). El slot bajo el puntero se marca `hover` → clase `.hot`.
5. En `pointerup`: si hay slot objetivo válido, `placeCard`; si no, la carta vuelve a la mano (no pasa nada, sigue en `hand`).
6. **Quitar:** tocar una carta colocada en un slot durante `programacion` la devuelve a la mano (`returnToHand`).

> Al recrear en React Native: usa `PanResponder`/`react-native-gesture-handler` + `Reanimated`. El patrón es idéntico: captura, ghost que sigue al dedo, medición de slots (`measureInWindow`), hit-test con padding, drop o retorno.

### Flujo de fases (round) — orden canónico
`PHASES` en `game-data.js`: **ROBO → PROGRAMACIÓN → COMPILAR → REVELACIÓN → EJECUCIÓN → RESULTADO** (la adquisición/robo se pliega en el inicio de la siguiente ronda).
- El prototipo arranca en **PROGRAMACIÓN** (índice 1).
- **COMPILAR** (botón, requiere Rutina activa y, si es NULL-SHARD, tipo declarado): el rival programa en oculto (`opponentPlay`), luego una secuencia temporizada: `compilar` (700ms) → `revelacion` + flip de dorsos (1050ms) → `ejecucion` + cálculo (1900ms) → `resultado` + daño (2700ms).
- **RESULTADO:** se aplica −1 integridad al perdedor; botón **SIGUIENTE RONDA** rehace la mano y vuelve a PROGRAMACIÓN. Si una integridad llega a 0 → `onFlush(win|lose)`.

### Animaciones (intensidad ~7/10)
- **Importante (lección aprendida):** las animaciones de entrada **no deben dejar el estado base oculto**. Si una animación parte de `opacity:0` y el navegador la pausa (pestaña en segundo plano), el contenido queda invisible. Regla: el estado de reposo SIEMPRE visible; animar solo `transform` (slide/scale), nunca depender de un fade-in para mostrar contenido. Ver `scrIn` y `popIn` en `game.css`.
- Efectos: barrido de escaneo en la “región de compilación” de cada carta (`gc-scan`), glitch del título, glow por tipo, flip de dorsos en la revelación, banner de resultado con scale-in, ghost de arrastre con drop-shadow, scanlines sutiles.

## State Management
Estado en React (`useState`), elevable a store del proyecto (Zustand/Redux/Bloc):
- **App:** `screen` ('menu'|'nucleo'|'deck'|'match'|'flush'), `nucleo` (objeto), `flush` ({outcome, meta}).
- **Match:** `phaseIdx`, `hand[]`, `active`, `subs[2]`, `integrity{you,opp}`, `opp` (jugada oculta del rival), `revealed`, `result`, `round`, `pendingNull` (uid de NULL-SHARD esperando declaración de tipo), y el estado de arrastre `drag` + `hover`. `ramUsed`/`ramLeft` derivados de `subs`.
- **Deck:** conteos por id `rut{}` y `sub{}`; derivados `rutCount`/`subCount`.

## Reglas de juego (especificación canónica) — `game-data.js`
- **Triángulo de tipos:** `CORTAFUEGOS (firewall) ▸ vence EXPLOIT`, `EXPLOIT ▸ vence PULSO (signal)`, `PULSO ▸ vence CORTAFUEGOS`. **NULL** = comodín (declara su tipo al programar; inmune a Overclock/Throttle).
- **Ciclos:** número grande de cada Rutina = prioridad/velocidad. En **espejo** (mismo tipo) decide el de **más Ciclos**; empate de Ciclos = EMPATE.
- **RAM:** recurso para pagar Subrutinas (coste por carta). El núcleo define la RAM base.
- **Integridad:** "vida" (pips). Perder la ronda = −1 (modificable por Subrutinas como FORK-BOMB). 0 = derrota.
- **Subrutinas (alteraciones):** OVERCLOCK (+4 Ciclos propios), THROTTLE (−4 al rival), CUARENTENA (fuerza EMPATE), MIRROR (copia el tipo rival), SIGKILL (anula TODAS las subrutinas rivales), FORK-BOMB (+1 daño si ganas). Lógica exacta en la función `resolve(you, opp)`.
- **Mazos:** 10 Rutinas + 20 Subrutinas; máx 3 copias/Rutina, 5/Subrutina.
- **Resolución (`resolve`)** devuelve `{ winner:'you'|'opp'|'draw', youCiclos, oppCiclos, youType, oppType, log[] }`. Orden de aplicación: SIGKILL → MIRROR → OVERCLOCK/THROTTLE → CUARENTENA (empate forzado) → comparación de triángulo/espejo.

## Design Tokens
**Colores**
- Fondo: `#06080d` / `#080b12`; panel `#0b0f17`; líneas `#161c28`.
- Tinta: `#cdd6e6` (ink), `#aeb8c8` (ink2), `#5f6b7e` (dim), `#46506a` (dim2).
- Tipos: CORTAFUEGOS/firewall `#3fc7ec` (cian), EXPLOIT `#ff4068` (rojo), PULSO/signal `#26e6a4` (verde), NULL `#b061ff` (violeta).
- Acento RAM/aviso: ámbar `#ffb43f`.

**Tipografía**
- Display: **Chakra Petch** (400/500/600/700) — títulos, nombres de carta, labels.
- Mono/datos: **JetBrains Mono** (400/500/700) — números, texto de carta, HUD, captions.
- Escala notable: título menú 54px; nombre núcleo 30px; Ciclos en carta 26px; RAM 24px; nombre carta 14px; texto carta 8.5px; captions 7–9px.

**Carta (métrica base)** 172×240, radio 3px, borde 1px en color del tipo con `color-mix`, grid interno 14px, “región de compilación” 78px con barrido. Se escala vía `transform: scale()` del contenedor para mano/slot/mini (la carta siempre se renderiza a tamaño base para mantener nitidez).

**Radios:** cartas 3px; slots 6px; botones 7px; paneles 9–12px; chips 8px.
**Espaciado:** unidades de 6–16px; `--safe: 20px` para márgenes de seguridad del dispositivo.
**Sombras/Glow:** glows por color de tipo con `box-shadow` + `text-shadow`; sombra de carta en mano `0 5px 14px rgba(0,0,0,.6)`.
**Dispositivo:** lienzo fijo **390×844** (móvil vertical), escalado a viewport por JS (`fitDevice`).

## Assets
- **Sin imágenes externas.** Todo el arte es **SVG geométrico inline** (`Sigil` en `game-cards.jsx`: un glifo por tipo — escudo facetado/firewall, X/exploit, ondas/pulso, rombo/null) + CSS. Esto es intencional ("cartas manifestadas desde datos").
- **Fuentes:** Google Fonts (Chakra Petch, JetBrains Mono).
- Nota: el arte de **rareza épica** está pendiente de diseño (no implementado).

## Files (en este bundle)
- `NODEHACK.html` — shell: carga fuentes, React/Babel, los módulos, monta `App` (router de pantallas) y el escalado del dispositivo.
- `game.css` — todos los estilos (tokens, carta, las 5 pantallas, arrastre, animaciones).
- `game-data.js` — **lógica/datos portables**: tipos, triángulo, núcleos, catálogos de Rutinas/Subrutinas, fases, `resolve()`, helpers (`sampleHand`, `opponentPlay`).
- `game-cards.jsx` — `GameCard`, `GameCardBack`, `Sigil` (componentes de carta, estética Terminal).
- `game-menu.jsx` — `MenuScreen`, `NucleoScreen`.
- `game-deck.jsx` — `DeckScreen`, `FlushScreen`.
- `game-match.jsx` — `MatchScreen` (mesa + arrastre + flujo de fases). **Empieza por aquí** para la interacción clave.

## Cómo correr el prototipo de referencia
Abrir `NODEHACK.html` con un servidor estático (por las cargas de `.jsx`/`.js` vía `<script src>`). Cualquiera sirve, p. ej. `npx serve` o la extensión Live Server de VS Code. No requiere build.

## Notas para el desarrollador
- **Multijugador real (PVP):** el prototipo simula al rival con `opponentPlay()`. En producción, ambos lados solo deben **colocar cartas**; la revelación es simultánea por servidor autoritativo (programa cifrado/oculto hasta que ambos confirman COMPILAR). Mantén `resolve()` en el servidor para evitar trampas.
- **NULL-SHARD:** al colocarse en el slot activo abre un overlay para **declarar tipo** (firewall/exploit/pulso) antes de poder compilar.
- Respeta `prefers-reduced-motion` y la regla de "estado base visible" al portar animaciones.
