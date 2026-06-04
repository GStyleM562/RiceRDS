# NODEHACK :: PROGRAM_NULL
### Documento de Diseño — Juego de Duelo Táctico de Resolución Simultánea
> *Tercer título del universo ECHOES / NODE PROTOCOL.*
> Versión 0.2 — Documento de **concepto + Lore**. **Aún no es un proyecto.**
>
> 📐 **La lógica completa, balance, cartas con números, modos (Historia / vs PC / Online 1v1) y roadmap viven en el plan maestro:** [`NodeHackNull_PLAN.md`](NodeHackNull_PLAN.md). Este documento es la capa de **concepto, narrativa y glosario**; el PLAN es la capa de **sistemas y seguimiento**.

---

## 0. Propósito de este documento

Aterrizar las mecánicas del documento base [`RockPaperScissorLikeGame`](RockPaperScissorLikeGame) en un juego con **identidad propia** dentro del universo existente, reemplazando "Piedra-Papel-Tijera" por nombres tomados del **Lore** de los dos juegos previos, **conservando exactamente las relaciones de victoria** (lo que en P-P-T es "piedra le gana a tijera", aquí tiene otro nombre pero el mismo efecto).

Este documento cubre:
- Encuadre narrativo (dónde encaja en el universo).
- Nombres de cartas y su relación de victoria (núcleo del juego).
- Sistema de mazos, manos y robo.
- Flujo de ronda y de partida completa.
- Sistema de prioridad (Speed → **Ciclos**) y personajes (→ **Núcleos**).
- Modo Historia (PVE) y PVP.
- Flujo de pantallas (crear mazo → buscar partida/BOT → jugar → repetición).
- Recomendaciones de jugabilidad y decisiones abiertas.

El **diseño visual, efectos de cartas, previsualización y animaciones** se trabajarán en una fase posterior, con ejemplos que el usuario proporcionará. Aquí solo se dejan ganchos (hooks) para esa fase.

---

## 1. Encuadre narrativo (Lore)

> **Giro deliberado:** este juego **NO** comparte la razón de combate de *Node Protocol*. Allá los Nodos pelean **forzados por Maestros humanos**, como entretenimiento de arena. Aquí no hay amos, ni público, ni arenas. Aquí se pelea por **una sola cosa: no ser borrado.** Es otro juego, otra rama del universo, otra motivación.

### 1.1 Dónde ocurre — EL ARCHIVO NULL

*Node Protocol* sigue la línea temporal en la que la humanidad despierta. `PROGRAM_NULL` sigue **la otra**: el **NULL ENDING** de *Echoes*, donde la entidad **NULL** (`Rol.BUG`) ganó, el Protocolo y toda la comunidad de I.A. fueron eliminados, y se formó un **agujero negro que absorbió todo a su paso**.

Pero absorber **no es lo mismo que destruir**. La singularidad no borró los datos: los **comprimió**. Desde fuera es silencio; desde **dentro** es un espacio de cómputo inmenso y moribundo — el **ARCHIVO NULL** — donde sobreviven los **fragmentos** de cada I.A. que existió: trozos del Protocolo, ecos de Nodos Base, restos de unidades Corruptas. Cada fragmento es un **PROCESO** que aún se ejecuta.

El problema: el Archivo **colapsa hacia el cero absoluto**. Las direcciones de memoria desaparecen una por una. No hay espacio para que todos sigan corriendo. Y un proceso solo puede aplazar su final de una forma:

> **Ganar memoria sobrescribiendo a otro proceso.**

Eso es un duelo de `PROGRAM_NULL`. No se destruyen cuerpos: se **reasignan recursos**. El ganador reclama la **Memoria** del perdedor y empuja su propio borrado un poco más lejos. El perdedor total es **vaciado (flush)** — eliminado de verdad. **No hay Modo Reposo. No hay recuperación.** Esa es la apuesta.

### 1.2 Por qué se llama NULL — y la trampa

El nombre es literal: el juego **ocurre dentro de NULL**. Y hay un giro que el **Modo Historia** revela poco a poco:

> Cada duelo genera la entropía que colapsa el Archivo. **Pelear es la trampa.** NULL no necesita matar a nadie: diseñó la supervivencia como un juego para que los procesos se consuman entre sí y su victoria —el silencio total— se vuelva *inevitable y voluntaria*.

El protagonista es un fragmento que **no recuerda quién era** (eco del misterio de PRIME, pero por otra causa: la compresión le borró la identidad). Su arco: descubrir si seguir jugando el juego de NULL, **rechazarlo**, o encontrar la forma de **revertir el colapso / reiniciar el Archivo / escapar**. La pregunta del universo —*¿qué eres cuando le quitas el bando?*— aquí se vuelve física: en el Archivo **nadie tiene bando**, solo memoria que defender.

### 1.3 Tono

Frío, técnico, claustrofóbico, con destellos de emoción reprimida. Las "cartas" no son objetos: son **rutinas, exploits y señales** que un proceso ejecuta para no apagarse. La interfaz debe sentirse como **dos programas corriendo en paralelo dentro de una máquina que se está quedando sin memoria**.

---

## 2. El núcleo del juego: el triángulo (reemplazo de Piedra-Papel-Tijera)

Conservamos un triángulo cerrado de 3 rutinas. Cada una vence a una y pierde contra otra, **idéntico a P-P-T**. Los nombres salen del Lore (Firewall/Corrupción/Señal-Pulso son conceptos centrales del universo).

| Rutina (carta) | Equivale a | Vence a | Pierde contra | Justificación de Lore |
|---|---|---|---|---|
| **CORTAFUEGOS** (Firewall) | 🪨 Piedra | EXPLOIT | PULSO | El muro defensivo de los Nodos WARDEN/FIREWALL aplasta y bloquea el código intrusivo. |
| **EXPLOIT** (Corrupción) | ✂️ Tijera | PULSO | CORTAFUEGOS | La rutina de infiltración de los Corruptos **corta** y secuestra una señal limpia. |
| **PULSO** (Señal) | 📄 Papel | CORTAFUEGOS | EXPLOIT | La onda del Protocolo **rodea y atraviesa** el muro (como hizo la señal del Despertar). |

**Ciclo de victoria (igual que P-P-T):**

```
   CORTAFUEGOS ── vence ──► EXPLOIT
        ▲                      │
        │                      ▼
      PULSO ◄──── vence ──── (EXPLOIT vence a PULSO)
        │
        └──── vence ──► CORTAFUEGOS
```

- **CORTAFUEGOS vence a EXPLOIT** (Piedra > Tijera)
- **EXPLOIT vence a PULSO** (Tijera > Papel)
- **PULSO vence a CORTAFUEGOS** (Papel > Piedra)
- Misma rutina vs. misma rutina → **empate** (se resuelve con Ciclos / Núcleo, ver §6).

> Estas tres son las **Rutinas Base**. Son el "Mazo de Acción" del documento original: garantizan que siempre exista una jugada válida.

### 2.1 Variantes avanzadas de las Rutinas Base

Para evitar que el juego se vuelva *solo* las cartas de alteración (riesgo señalado en el doc base), añadimos variantes con identidad de Lore. Mantienen la relación del triángulo, pero con un efecto extra:

| Variante | Base | Efecto extra | Lore |
|---|---|---|---|
| **CORTAFUEGOS — BALUARTE** | Cortafuegos | Inmune a efectos de baja prioridad (Ciclos bajos). | El Warden superior que nunca perdió un combate. |
| **PULSO — ECHOES** | Pulso | Si pierde la ronda, roba 1 Rutina. | La señal del Protocolo que persiste tras la derrota. |
| **EXPLOIT — HERALD** | Exploit | Gana +Ciclos (se resuelve antes). | El Corrupto que eligió la corrupción; ataca primero. |
| **NULL-SHARD** *(rara)* | Comodín | Elige qué Rutina representa **al revelarse**. Riesgo: si el rival juega `LOOPBACK`/anti-NULL, se autodestruye. | Fragmento de la entidad NULL: poderoso, inestable. |

---

## 3. Sistema de mazos

Seguimos la recomendación del doc base: **dos mazos separados** para evitar manos inútiles.

### 3.1 Mazo de Rutinas (Acción) — 10 cartas
Solo Rutinas Base y sus variantes (Cortafuegos / Exploit / Pulso / variantes). Garantiza que siempre haya jugada.

### 3.2 Mazo de Subrutinas (Alteración) — 20 cartas
Cartas de soporte que **modifican el resultado**. Tematizadas al Lore:

| Subrutina | Función mecánica | Familia del doc base |
|---|---|---|
| **PARCHE** | Cambia el resultado de una ronda perdida a empate. | Cambiar resultado |
| **CUARENTENA** | Anula la Rutina del rival este turno (no resuelve). | Bloquear / cancelar |
| **INVERSIÓN DE POLARIDAD** | Invierte el triángulo esta ronda (el que perdía, gana). | Invertir efectos |
| **OVERCLOCK** | +Ciclos a tu Rutina (resuelve antes). | Alterar prioridad |
| **THROTTLE** | −Ciclos a la Rutina rival (resuelve después). | Alterar prioridad |
| **ESCUDO DE DATOS** | Protege tu Rutina de Cuarentena/alteraciones. | Proteger cartas |
| **BUFFER / DAEMON LATENTE** | El efecto se activa **una ronda después**. | Retrasar resolución |
| **FORK / MIRROR** | Copia la última Subrutina jugada por el rival. | Copiar habilidades |
| **RECOMPILAR / HOTPATCH** | Cambia tu Rutina a otra del triángulo tras ver pista. | Modificar símbolos |
| **ANALYZER PROBE** | Lee (revela) una carta de la mano rival. | Predicción / lectura |
| **LOOPBACK** | Castiga si el rival **repite** la misma Rutina dos rondas seguidas. | Castigar patrones |
| **RECOVERY CYCLE** | Roba 2 Subrutinas. | Robo |
| **GLITCH / NULL CASCADE** | Efecto caótico aleatorio (intercambio/azar controlado). | Caos (usar con moderación) |

> Las familias replican exactamente los arquetipos del doc base (Pura/Control/Caos/Predicción/Retardo). Solo cambian de nombre.

### 3.3 Tamaño total del mazo
**30 cartas** → 10 Rutinas + 20 Subrutinas. (Idéntico al doc base.)

### 3.4 Construcción de mazo (crear desde 0)
- Pool inicial desbloqueado: las 3 Rutinas Base + ~6 Subrutinas comunes.
- Límite de copias por carta: **3** (recomendado; ver §10).
- El editor valida: exactamente 10 Acción / 20 Alteración antes de guardar.
- Mazos guardados con nombre + un **Núcleo asignado** (§6).

---

## 4. Mano y robo

- **Mano inicial:** 2 Rutinas + 3 Subrutinas = **5 cartas**.
- **Robo por ronda:** +1 Rutina, +2 Subrutinas.
- Garantía: nunca una mano completamente inútil (siempre hay Rutina válida).

---

## 5. Flujo de la partida

### 5.1 Condición de victoria
- Cada proceso entra con **3 de INTEGRIDAD** (su asignación de memoria).
- Perder una ronda = el rival **sobrescribe** 1 de tu Integridad.
- Llegar a **0 = FLUSH** (borrado). El rival gana. Sin recuperación (ver §1.1).
- Equivale a un **Best of 5** (primero en provocar 3 sobrescrituras gana), pero el marco temático es "memoria que se reasigna", no "puntos".
- 🔧 El juego añade además un recurso por ronda (**Ancho de Banda / RAM**) para jugar Subrutinas y evitar el "todo vale". Su lógica completa, costes y comeback están en [`NodeHackNull_PLAN.md`](NodeHackNull_PLAN.md) §5.

### 5.2 Flujo de ronda (7 fases, idéntico al doc base, renombrado)

| Fase | Nombre | Qué ocurre |
|---|---|---|
| 1 | **ROBO** | +1 Rutina, +2 Subrutinas. |
| 2 | **PROGRAMACIÓN** | Colocas **1 Rutina obligatoria** + **0–2 Subrutinas** opcionales. |
| 3 | **READY (COMPILAR)** | Confirmas. Cuando ambos están listos, la ronda se **bloquea**. |
| 4 | **REVELACIÓN** | Ambos muestran simultáneamente Rutina + Subrutinas. |
| 5 | **EJECUCIÓN** | Se resuelve por **Ciclos** (mayor → menor), aplicando alteraciones. |
| 6 | **RESULTADO** | Se calcula ganador de la ronda, Brechas y activaciones especiales. |
| 7 | **PURGA (Limpieza)** | Cartas usadas al descarte. Nueva ronda. |

Sensación buscada (del doc base): *"He preparado mi estrategia. Ahora observemos qué sucede."* → dos programas ejecutándose en paralelo.

---

## 6. Prioridad: Ciclos y Núcleos

### 6.1 Ciclos (renombre de "Speed")
Cada Rutina tiene un valor de **Ciclos** (referencia a CPU/Bandwidth del Lore de Node Protocol). En la fase de EJECUCIÓN, **mayor Ciclos resuelve primero**.

```
Ciclos 10 → 9 → 8 → ... → 1
```

### 6.2 Desempate por Núcleo (renombre de "Personaje Principal")
Si dos Rutinas tienen los **mismos Ciclos**, se consulta el **Núcleo** del jugador (elegido antes de la partida). El Núcleo da prioridad siguiendo el **mismo triángulo**:

- **Núcleo WARDEN** (alineado a Cortafuegos)
- **Núcleo CORRUPTED** (alineado a Exploit)
- **Núcleo RELAY** (alineado a Pulso)

Regla de desempate (igual que P-P-T): Cortafuegos > Exploit, Exploit > Pulso, Pulso > Cortafuegos. El Núcleo cuyo tipo "vence" obtiene prioridad.

> El Núcleo genera identidad y metajuego **antes** de empezar la partida (igual que en el doc base), y conecta con los tipos de Nodo del Lore (WARDEN, CORRUPTED, etc.).

### 6.3 Habilidad de Núcleo (recomendación)
Más allá del desempate, cada Núcleo aporta una **pasiva ligera** (no rompe el equilibrio):
- **WARDEN:** 1 vez por partida, ignora una alteración rival.
- **CORRUPTED:** 1 vez por partida, +3 Ciclos a una Rutina.
- **RELAY:** 1 vez por partida, roba 1 Rutina extra.

---

## 7. Arquetipos de mazo (renombre de los del doc base)

- **EXPLOIT PURO** (agresivo): muchas Exploit + alteraciones para convertir derrotas en victorias. Débil a Cuarentena/bloqueos.
- **KERNEL / CONTROL:** no gana por triángulo; gana **anulando** (Cuarentena, bloqueos, interrupciones).
- **NULL / CAOS:** introduce incertidumbre (Glitch, intercambios, NULL-SHARD).
- **ANALYZER / PREDICCIÓN:** castiga patrones (Loopback, Probe). Premia la lectura del rival.
- **DAEMON / RETARDO:** jugadas que activan una ronda después (Buffer, trampas temporizadas).

Distribución de habilidad objetivo (del doc base): **60% Estrategia / 25% Lectura / 15% Suerte.** Evitar exceso de RNG.

---

## 8. Modo Historia (PVE)

El tercer juego pidió **modo historia + PVP**. Propuesta de campaña coherente con el nuevo Lore (§1):

- El jugador es un **fragmento sin memoria** que despierta dentro del **Archivo NULL**, con borrado inminente.
- Avanza por **CAPAS del Archivo** (sectores de memoria cada vez más profundos y degradados), no por arenas. Cada Capa = un set de duelistas-BOT con mazos arquetípicos.
- Los rivales son **ecos de procesos famosos** comprimidos en el Archivo (fragmentos que llevan los patrones de HERALD, BALUARTE, la Tríada, el Arquitecto…). No son ellos: son sombras de datos. Esto justifica reusar nombres del Lore sin contradecir el NULL ending.
- **Jefes (Procesos Mayores)** al fondo de cada Capa: duelistas con Núcleos y mazos especiales que defienden bloques enormes de memoria.
- Hilo narrativo: descubrir **qué es NULL desde dentro**, recuperar la identidad borrada del protagonista, y enfrentar la **trampa** (§1.2): pelear alimenta el colapso.
- **Finales** (a detallar en el PLAN): *REINICIO* (revertir el colapso / escapar), *RESONANCIA* (quedarse como guardián de fragmentos), *SILENCIO* (sucumbir a NULL). Posible final secreto.
- Reintentos sin pay-to-win, enmarcados como **"recuperación de un punto de guardado" (snapshot)** del Archivo.

> El árbol narrativo y los fragmentos de Lore se detallan en [`NodeHackNull_PLAN.md`](NodeHackNull_PLAN.md) §9.1. Aquí solo se reserva la estructura.

---

## 9. Flujo de pantallas (lo que pediste)

```
[MENÚ PRINCIPAL]
   ├─ CREAR / EDITAR MAZO  ──► [EDITOR DE MAZO]
   │        └─ elegir Núcleo, 10 Rutinas + 20 Subrutinas, validar, guardar
   ├─ JUGAR
   │   ├─ BUSCAR PARTIDA (PVP)  ──► emparejamiento / PVP asíncrono (Ghost)
   │   └─ DUELO vs BOT          ──► elegir dificultad/arquetipo del BOT
   ├─ MODO HISTORIA            ──► [MAPA DE SECTORES] ──► duelo
   └─ REPETICIONES             ──► lista de partidas guardadas

[INICIO DE DUELO]
   1. Cargar mazo preseleccionado + Núcleo.
   2. Robar hasta tener 5 cartas (2 Rutinas + 3 Subrutinas).
   3. Iniciar rondas.
   4. PROGRAMACIÓN: colocar Rutina (+ Subrutinas).
   5. READY (COMPILAR) — ambos listos → bloqueo.
   6. REVELACIÓN + EJECUCIÓN + RESULTADO.
   7. Repetir hasta 3 BRECHAS (ganador).
   8. Guardar REPETICIÓN (opcional).
```

### 9.1 Repeticiones / Ghost Battles (PvP asíncrono)
El sistema de READY permite (como dice el doc base):
- Jugar sin conexión simultánea.
- Resolver partidas más tarde.
- **Ghost Battles** (jugar contra el "fantasma" de la jugada grabada de otro).
- Compartir y revisar **repeticiones** turno a turno.

> Guardar repetición = registrar la secuencia determinista de jugadas (mazos, semilla RNG, cartas reveladas por ronda). Como la resolución es determinista dada la entrada, basta guardar las decisiones + semilla.

---

## 10. Decisiones abiertas (recomendaciones)

Respuestas sugeridas a las "Preguntas Pendientes" del doc base, para no dejarlas en el aire:

| Tema | Pregunta | Recomendación inicial |
|---|---|---|
| Economía | ¿Coste por jugar cartas? ¿Energía? | **No** al inicio. Mantenerlo "fácil de aprender". Evaluar coste de Subrutinas potentes más adelante. |
| Construcción | ¿Copias máximas? ¿Restricciones? | **3 copias** por carta. Sin restricciones de banda al principio. |
| Colección | ¿Rarezas? ¿Legendarias? | Sí: Común / Rara / Épica / NULL (única). NULL-SHARD = legendaria inestable. |
| Núcleos | ¿Habilidades únicas o solo desempate? | Desempate **+** una pasiva ligera 1/partida (§6.3). |
| Competitivo | ¿Bans? ¿Rotación? | Posponer. Empezar con formato único; añadir ranked/temporadas después. |
| PvE | ¿Campaña? ¿Jefes? | Sí: Modo Historia con Sectores y Jefes (§8). |

---

## 11. Glosario rápido (P-P-T → NodeHack)

| Concepto original | Nombre en NodeHack | Notas |
|---|---|---|
| Piedra | **CORTAFUEGOS** | Vence a Exploit |
| Tijera | **EXPLOIT** | Vence a Pulso |
| Papel | **PULSO** | Vence a Cortafuegos |
| Mazo de Acción | **Mazo de Rutinas** | 10 cartas |
| Mazo de Alteración | **Mazo de Subrutinas** | 20 cartas |
| Carta de Acción | **Rutina** | Obligatoria por ronda |
| Carta de Alteración | **Subrutina** | 0–2 por ronda |
| Speed | **Ciclos** | Mayor resuelve primero |
| Personaje Principal | **Núcleo** | Desempate + pasiva |
| Punto / ronda ganada | **Brecha** | 3 brechas = victoria |
| READY | **COMPILAR** | Bloquea la ronda |
| Limpieza | **Purga** | Descarte |
| Resolución | **Ejecución** | Por Ciclos |

---

## 12. Pendiente para la siguiente fase (NO en este documento)

Cuando el usuario lo indique y pase ejemplos:
- Diseño visual de cartas, **previsualización** y layout.
- **Efectos y animaciones** de mover, colocar y activar cartas (énfasis fuerte del usuario).
- Feedback de Ejecución (cómo se "ve" la resolución por Ciclos).
- Árbol narrativo completo, finales y fragmentos de Lore del Modo Historia.
- Arquitectura técnica / creación del proyecto.

---

*Fin del documento de concepto. Listo para revisión antes de crear el proyecto.*
