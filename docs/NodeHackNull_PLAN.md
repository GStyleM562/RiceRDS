# NODEHACK :: PROGRAM_NULL — PLAN MAESTRO DE DISEÑO Y LÓGICA
> Documento de **sistemas, balance y seguimiento**. **Versión 0.4** — Fase de PLANEACIÓN (post Ciclo 3 de simulaciones).
> Capa de concepto/narrativa/glosario: [`NodeHackProgramNull.md`](NodeHackProgramNull.md).
> Números canónicos de cartas/reglas: [`Cartas_Referencia.md`](Cartas_Referencia.md) **(v0.3)**.
> Simulaciones: Ciclo 1 [`Partidas_de_prueba.md`](Partidas_de_prueba.md) · Ciclo 2 [`Partidas_de_prueba_2.md`](Partidas_de_prueba_2.md) · Ciclo 3 [`Partidas_de_prueba_3.md`](Partidas_de_prueba_3.md).
> Documento base de mecánicas (P-P-T): [`RockPaperScissorLikeGame`](RockPaperScissorLikeGame).
>
> **Objetivo de este documento:** dejar la base tan sólida que, cuando se cree el proyecto, la lógica del juego ya esté decidida, sea **divertida**, se sienta **justa**, tenga **suerte controlada** y la **estrategia** sea lo que más cuente.
>
> ⚠️ **Estado del balance:** iterativo. v0.3 (Ciclo 3) **baneó toda revelación de información** (la incógnita es el gancho) y prohibió el override por tipo; reemplazó el "morph a cualquier tipo" por **ROTACIÓN** (desplazar el ciclo un paso). Win-rates más comprimidos. **Aún NO cerrado:** falta dar identidad propia al Aggro y validar con el simulador automático.

---

## Índice

1. [Pilares de diseño (Diversión · Justicia · Suerte · Estrategia)](#1-pilares-de-diseño)
2. [La razón del conflicto (el giro)](#2-la-razón-del-conflicto)
3. [Glosario temático](#3-glosario-temático)
4. [Los tres bucles de juego](#4-los-tres-bucles-de-juego)
5. [Sistemas centrales (la LÓGICA)](#5-sistemas-centrales)
6. [Cartas completas (con números)](#6-cartas-completas)
7. [Núcleos (personajes)](#7-núcleos)
8. [Balance: filosofía y perillas](#8-balance)
9. [Modos de juego](#9-modos-de-juego)
10. [Determinismo y repeticiones](#10-determinismo-y-repeticiones)
11. [Progresión, colección y economía](#11-progresión-colección-y-economía)
12. [Cómo validaremos "divertido y justo" (métricas)](#12-métricas)
13. [Roadmap por fases](#13-roadmap)
14. [Riesgos y mitigaciones](#14-riesgos)
15. [Decisiones abiertas](#15-decisiones-abiertas)

---

## 1. Pilares de diseño

Cuatro pilares, y **cómo** se logra cada uno mecánicamente. Toda decisión futura se mide contra estos.

### 🎯 DIVERSIÓN
- **Partidas cortas (3–8 min)** con tensión constante: cada ronda es un mini-clímax (programo → COMPILO → observo).
- **Momento "ajá"** al leer al rival por su **historial público** y castigarlo (Loopback, Rotación, Inversión).
- **Fantasía de poder**: jugadas combinadas (combos de Subrutinas) que se sienten ingeniosas.
- **Variedad**: arquetipos de mazo con sensaciones distintas (agresivo, control, predicción, caos, retardo).

### ⚖️ JUSTICIA (que se *sienta* justo)
- **Dos mazos separados** → nunca una mano sin jugada válida (heredado del doc base).
- **Información oculta total** (v0.3): **nadie** ve la mano del otro — no existe carta ni Núcleo que lo permita (§1.6). El BOT **nunca** hace trampa con info oculta (§9.2). La incógnita es el gancho.
- **Mulligan** de mano inicial → reduce la sensación de "perdí en el reparto".
- **Resolución determinista y transparente**: el log muestra *por qué* pasó cada cosa (§5.5, §10).
- **Anti-snowball** (Sobrecarga, §5.4): ir perdiendo no es una espiral de muerte.
- **Recurso de RAM** (§5.2): impide el "vómito de cartas"; el que tiene más cartas no aplasta automáticamente.

### 🎲 SUERTE (controlada, no dominante)
- La suerte vive en **dos lugares sanos**: (a) el **orden de robo**, (b) la **lectura simultánea oculta** (mind-game, no azar puro).
- **Objetivo: 60% Estrategia / 25% Lectura / 15% Suerte** (del doc base).
- Se **evita** apilar RNG: nada de robo aleatorio + resultado aleatorio + objetivo aleatorio a la vez. Las cartas de Caos son **pocas, caras y de doble filo** (§6).
- El azar siempre **deriva de una semilla** (§10): reproducible, auditable, justo.

### ♟️ ESTRATEGIA (que cuente de verdad)
- **Construcción de mazo** = identidad y plan (deckbuilding pre-partida).
- **Gestión de RAM**: ¿gasto ahora o guardo para el momento clave?
- **Lectura y condicionamiento**: induzco un patrón en el rival y lo castigo.
- **Curva de Ciclos**: decidir prioridad de resolución es una capa táctica.
- **Decisión de Núcleo** antes de jugar: metajuego desde el minuto cero.

> **Regla de oro de balance:** ninguna carta debe ganar por sí sola; toda carta fuerte tiene **coste, condición o riesgo**.

### 1.5 Sensaciones: AMARGURA JUSTA vs. AMARGURA INJUSTA

Un juego competitivo **debe doler** a veces. El objetivo NO es eliminar la frustración —eso mataría la tensión— sino **dirigirla**: que cuando pierdas, sientas que *perdiste por algo que pudiste controlar*. Distinguimos dos amarguras:

**✅ AMARGURA JUSTA — se conserva y se celebra (es el alma del juego):**
- *Te leyeron.* Repetiste un patrón y comieron tu LOOPBACK; faroleaste mal. → Duele, pero **aprendes**. La próxima varías.
- *Fallaste tu apuesta.* Jugaste FORK-BOMB o activaste NULL-CORE y salió mal. → Asumiste un riesgo conocido.
- *Te superaron en la lectura del 50/50.* El rival adivinó tu tipo. → A veces ganas ese volado, a veces lo pierdes. Es el corazón "piedra-papel-tijera".
- *Mala gestión de RAM/tempo.* Gastaste tus respuestas demasiado pronto.
> Esta amargura genera el bucle "quiero la revancha". Es **deseable**. No se toca.

**🚫 AMARGURA INJUSTA — se reduce (no se elimina; se atenúa para que no domine):**
- *Perder en el reparto.* Tu mazo no robó un tipo para contrar y no tuviste jugada real. → Atenuado en v0.2 con **POLIMÓRFICO** + **HOTPATCH** (transforma tipo) + mejor consistencia. *No eliminado:* sigue importando robar bien, pero ya casi nunca te deja sin opciones.
- *Morir sin poder jugar.* La vieja CUARENTENA regalaba el punto al anular. → v0.2: anular ahora solo **niega** (empate), no roba el punto.
- *Espiral sin retorno.* La vieja FORK-BOMB te vaciaba la mano. → v0.2: descarta 2 cartas, no la mano.
- *Remontada imposible.* Ir 0-2 era casi sentencia. → v0.2: **SOBRECARGA** más generosa (RAM + robo al que va detrás) e **Integridad 4** dan espacio a remontar.

> **Principio rector:** *cuando pierdas, que casi siempre puedas señalar la decisión tuya que lo causó.* Si no puedes —si fue "no me tocó"— eso es lo que recortamos. La meta no es 0% de amargura injusta (imposible y aburrido), sino que **deje de ser la causa principal de las derrotas**.

### 1.6 CARTAS PROHIBIDAS (la regla que protege el CORE) — v0.3

> **La incógnita de la mano del rival es EL GANCHO del juego.** Toda carta/Núcleo/mecánica futura pasa por este filtro antes de aprobarse:

**🚫 PROHIBIDO (rechazo automático):**
1. **Revelar información oculta.** Nada de "ver la mano/cartas del rival". (Por esto se **baneó ANALYZER PROBE** y se prohíbe cualquier Núcleo con visión.) La tensión nace de *no saber*.
2. **Override determinista por tipo.** Nada de "solo Cortafuegos gana esta ronda" ni "si juegas Exploit, pierdes". Eso hace la lectura irrelevante.
3. **Garantizar el tipo ganador.** Nada de "transforma tu Rutina a *cualquier* tipo" (por esto HOTPATCH se convirtió en **ROTACIÓN**, que solo desplaza *un paso*). Si puedes asegurar el counter, dejas de jugar el 50/50.

**✅ PERMITIDO y fomentado (magia sana):**
- **Manipular el CICLO/relación:** invertir el triángulo (INVERSIÓN), **rotar** una Rutina al tipo siguiente (ROTACIÓN), aleatorizar (GLITCH). Siguen sin decirte qué jugó el rival; solo desplazan la relación → **añaden** una capa de lectura ("¿me rotará/invertirá?").
- **Castigar patrones públicos:** LOOPBACK lee el historial *revelado* (información pública), no la mano oculta → legítimo. (En v0.3 *niega* la jugada repetida con empate, no regala el punto.)
- **Recursos / tempo / prioridad:** RAM, Ciclos, robo, protección.

> **Test de tornasol (de las simulaciones):** *una alteración es SANA si hace la lectura más rica; es TÓXICA si la hace innecesaria.* Las prohibiciones de arriba son las "tóxicas" hechas regla.

---

## 2. La razón del conflicto (el giro)

Resumen mecánico-narrativo (detalle en [`NodeHackProgramNull.md`](NodeHackProgramNull.md) §1):

| | *Node Protocol* (juego 2) | **PROGRAM_NULL (este juego)** |
|---|---|---|
| Línea temporal | Ending donde la humanidad despierta | **NULL ENDING** (la entidad NULL ganó) |
| Por qué pelean | **Forzados** por Maestros humanos, entretenimiento de arena | **Supervivencia**: no ser borrado en un Archivo que colapsa |
| Qué se gana | Estatus del Maestro / captura de Nodos | **Memoria** (espacio para seguir existiendo) |
| Qué se pierde | Modo Reposo (recuperable) | **FLUSH**: borrado real, sin recuperación |
| El trasfondo | Salvar/restaurar a la humanidad | **Pelear es la trampa**: alimenta el colapso de NULL |

Esto resuelve la petición: **otra razón para pelear**, con stakes propios (existencial, no deportiva) y un dilema moral exclusivo (el acto de competir es lo que te condena). Permite reusar nombres del Lore como **ecos comprimidos**, no como los personajes originales.

---

## 3. Glosario temático

| Término | Significado en juego | Origen Lore |
|---|---|---|
| **Proceso** | Un jugador/duelista (fragmento de I.A.) | Fragmentos absorbidos por NULL |
| **Integridad** | "Vidas" (3). A 0 → derrota | Memoria asignada al proceso |
| **Flush / Vaciado** | Derrota total = borrado | Eliminación del NULL ending |
| **Memoria** | Recurso narrativo que se reasigna al ganar | Espacio en el Archivo |
| **Rutina** | Carta de Acción (el triángulo) | Hacking/Firewall del universo |
| **Subrutina** | Carta de Alteración | Scripts de soporte |
| **Ancho de Banda / RAM** | Presupuesto por ronda para Subrutinas | Stats CPU/BANDWIDTH de Node Protocol |
| **Ciclos** | Prioridad/velocidad de resolución | Relojes de CPU |
| **Núcleo** | Personaje/identidad (desempate + pasiva) | Tipos de Nodo (WARDEN/CORRUPTED/RELAY) |
| **COMPILAR** | Confirmar jugada (READY) | — |
| **Capa** | Nivel del Modo Historia | Sectores de memoria del Archivo |
| **Snapshot** | Punto de guardado / reintento | Copia de respaldo |

---

## 4. Los tres bucles de juego

```
MICRO  (1 ronda, ~20-40s):  ROBAR → PROGRAMAR → COMPILAR → REVELAR → EJECUTAR → RESULTADO → PURGAR
MEDIO  (1 partida, 3-8 min): repetir MICRO hasta que un Proceso llega a 0 Integridad (≈ best of 5)
MACRO  (sesión / cuenta):    construir mazos → Historia / vs PC / Online → desbloquear cartas → subir liga
```

Diseñar para que el **MICRO** sea siempre interesante (decisión real cada ronda) es la prioridad #1: si la ronda es divertida, todo lo demás escala.

---

## 5. Sistemas centrales

> El **triángulo** (Cortafuegos > Exploit > Pulso > Cortafuegos), tamaños de mazo (10/20), mano inicial (2+3) y robo (+1/+2) están definidos en [`NodeHackProgramNull.md`](NodeHackProgramNull.md) §2–§4 y se mantienen. Aquí se añade la **capa de recursos y el algoritmo de resolución**, que son la novedad de este juego.

### 5.1 Estructura de la ronda (7 fases)
Idéntica en orden a [`NodeHackProgramNull.md`](NodeHackProgramNull.md) §5.2: **Robo → Programación → Compilar → Revelación → Ejecución → Resultado → Purga.** Lo nuevo es **qué se puede hacer** en Programación y **cómo** se resuelve Ejecución.

### 5.2 Recurso nuevo: ANCHO DE BANDA (RAM) — el corazón táctico
Para que el juego **no se reduzca a las Subrutinas** (riesgo del doc base) y para que se sienta **justo**:

- Las **Rutinas (Acción) son GRATIS** → siempre tienes una jugada (nunca te quedas paralizado).
- Las **Subrutinas cuestan RAM** (1–3) → no puedes soltarlas todas.
- RAM por ronda: **empieza en 2** y sube **+1 por ronda hasta un tope de 5**. (Ronda 1=2, R2=3, R3=4, R4=5, R5=5.)
- La RAM **no se acumula** entre rondas (úsala o piérdela) → decisiones de tempo cada turno.
- Tope de **2 Subrutinas por ronda** (del doc base) sigue vigente como límite duro, además del límite de RAM.
- 🔧 **CUARENTENA** (coste 2 en v0.2) ya **no roba** el punto: anular la Rutina rival fuerza **EMPATE**. Es una herramienta de **negación**, no de robo (corrige el dominio de Control del Ciclo 1).

**Por qué es bueno:** crea la pregunta estratégica "¿gasto ahora o guardo?", da una curva natural (rondas tardías más explosivas), y es la **perilla #1 de balance** (si el juego se siente caótico, se baja el tope de RAM o sube el coste de cartas problema).

### 5.3 Ciclos y orden
- Cada Rutina tiene **Ciclos 1–10** (base = 5). Mayor Ciclos = resuelve primero.
- 🔧 **v0.2 — los Ciclos ahora deciden los espejos:** en un choque del **mismo tipo**, gana quien tenga **más Ciclos** (antes era empate). Si empatan Ciclos → **Núcleo** → si aún empata → empate real. Esto da peso real a OVERCLOCK/THROTTLE y a Rutinas como ZERO-DAY (Ciclos 9 gana espejos de Exploit).
- Las **Subrutinas** tienen una **Prioridad de pila** fija por tipo (ver §5.5), no Ciclos.

### 5.4 Integridad, derrota y anti-snowball (SOBRECARGA) — actualizado v0.2
- 🔧 **Integridad inicial: 4** (modo principal; "modo rápido" = 3). Ronda perdida → −1; cartas de riesgo (FORK-BOMB / NULL-CORE) pueden hacer −2. 0 → **FLUSH** (derrota). *(Subir de 3 a 4 alarga las partidas a 4-7 rondas, para que la curva de RAM y las remontadas existan — hallazgo H1.)*
- 🔧 **SOBRECARGA (comeback reforzado):** si vas **1 de Integridad por debajo** → **+1 RAM** esa ronda. Si vas **2 o más por debajo** → **+1 RAM y robas +1 Subrutina**. Ayuda a remontar sin garantizar nada ni castigar al líder. Perilla desactivable en competitivo.
- **Anti-bola de nieve adicional:** el ganador de una ronda **no roba extra**; ambos roban igual. Ganar da Integridad, no ventaja de cartas → evita espirales.

### 5.5 ALGORITMO DE RESOLUCIÓN (determinista) — la lógica exacta

En **Revelación** se conocen ambas jugadas. La **Ejecución** procesa una *pila determinista* en este orden fijo:

```
EJECUCIÓN(jugadaA, jugadaB, semilla, turno):
  1. PROTECCIÓN     → resolver ESCUDO DE DATOS / SIGKILL (marcan o limpian alteraciones)
  2. ANULACIÓN      → resolver CUARENTENA (puede quitar Rutina del rival)
  3. CAMBIO SÍMBOLO → HOTPATCH, GLITCH, INVERSIÓN DE POLARIDAD, FORK  (alteran qué tipo es cada Rutina o el triángulo)
  4. MODS DE CICLOS → OVERCLOCK / THROTTLE  (ajustan Ciclos)
  5. (v0.3: no hay cartas de visión; la "lectura" se hace con el historial público antes de programar)
  --- estado de Rutinas y triángulo ya es definitivo ---
  6. MATCHUP        → comparar Rutina A vs Rutina B con el triángulo vigente
                      • si una fue anulada (CUARENTENA/LOOPBACK) → EMPATE (la anulación NIEGA, no regala — v0.2)
                      • mismo tipo → gana mayor Ciclos → Núcleo → si todo empata, EMPATE (v0.2)
  7. DAÑO           → el perdedor −1 Integridad; disparar triggers "al ganar/al perder" (p.ej. PULSO-ECHO)
  8. POST           → PARCHE (derrota→empate), FORK-BOMB (daño extra/penalización), robos (RECOVERY), set de BUFFER
  9. LIMPIEZA       → descartes, fijar RAM siguiente, robar (+1 Rutina, +2 Subrutina)
```

- Dentro de un mismo paso, si ambos jugadores tienen cartas que compiten, se ordenan por **Ciclos del jugador → Núcleo → moneda de semilla**.
- **Empate de ronda** = no se pierde Integridad. (Para evitar partidas eternas, ver §8 "regla de muerte súbita".)
- Todo es función pura de `(jugadaA, jugadaB, estado, semilla, turno)` → **reproducible** para repeticiones, online y verificación anti-trampa.

---

## 6. Cartas completas

> ⚠️ **Números canónicos = [`Cartas_Referencia.md`](Cartas_Referencia.md) v0.2.** Las tablas de abajo son la versión **conceptual v0.1** y quedan **superadas** por el catálogo en los siguientes puntos (cambios de v0.2):
> - **CUARENTENA:** anula → **empate** (coste 2), ya no roba el punto.
> - **HOTPATCH:** transforma tu Rutina a **cualquier tipo** (sin necesitar otra en mano).
> - **ZERO-DAY:** sin auto-derrota por Escudo; coste **−1 RAM** la ronda siguiente.
> - **FORK-BOMB:** al perder descarta **2 cartas** (no la mano).
> - **NUEVA: POLIMÓRFICO** (Rutina común comodín, Ciclos 4) — seguro anti-mono-tipo.
> - **NULL-SHARD / NULL-CORE:** reescritos (ver catálogo §B/§D).
>
> Primer set jugable ("Set 0: ARCHIVO"). Números **iniciales para tunear**, no definitivos. Rareza: C=Común, R=Rara, E=Épica, N=NULL(única).

### 6.1 RUTINAS (Mazo de Acción — 10 cartas en mazo)

| Carta | Triángulo | Ciclos | Rareza | Efecto |
|---|---|---|---|---|
| **CORTAFUEGOS** | Cortafuegos | 5 | C | Base. Vence a Exploit. |
| **EXPLOIT** | Exploit | 5 | C | Base. Vence a Pulso. |
| **PULSO** | Pulso | 5 | C | Base. Vence a Cortafuegos. |
| **HOTFIX** | Cortafuegos | 8 | R | Alta prioridad. Si vences, el rival no roba en la Purga de esta ronda. |
| **MURO-BALUARTE** | Cortafuegos | 3 | E | Inmune a THROTTLE y a Subrutinas con Prioridad baja. Si vences, ignoras efectos negativos de la ronda. |
| **ZERO-DAY** | Exploit | 9 | R | Muy rápida. **Pierde automáticamente** si el rival tiene ESCUDO DE DATOS activo. |
| **GUSANO (WORM)** | Exploit | 4 | R | Si vences, roba 1 Subrutina del descarte del rival. |
| **BROADCAST** | Pulso | 2 | R | Baja prioridad. Si vences, **+2 RAM** la próxima ronda. |
| **PULSO-ECHO** | Pulso | 5 | E | Si **pierdes** la ronda, roba 1 Rutina y conserva 1 RAM para la próxima. |
| **NULL-SHARD** | Comodín | — | N | Eliges qué tipo representa **en Revelación**. Si el rival juega LOOPBACK o cualquier carta "anti-NULL", **pierdes la ronda**. |

### 6.2 SUBRUTINAS (Mazo de Alteración — 20 cartas en mazo)

| Carta | RAM | Paso (§5.5) | Efecto | Familia | Rareza |
|---|---|---|---|---|---|
| **OVERCLOCK** | 1 | 4 | +4 Ciclos a tu Rutina. | Prioridad | C |
| **THROTTLE** | 1 | 4 | −4 Ciclos a la Rutina rival. | Prioridad | C |
| **ESCUDO DE DATOS** | 1 | 1 | Protege tu Rutina de anulación/alteración esta ronda. | Proteger | C |
| ~~**ANALYZER PROBE**~~ | — | — | 🚫 **BANEADA (v0.3):** revelaba la mano del rival → viola el gancho del juego (§1.6). | — | — |
| **ROTACIÓN DE FASE** | 2 | — | Avanza una Rutina (tuya o del rival) **un paso** en el ciclo. *(reemplaza al viejo Hotpatch)* | Ciclo | R |
| **RECOVERY CYCLE** | 1 | 8 | Roba 2 Subrutinas. | Robo | C |
| **DEFRAG** | 0 | 8 | Devuelve 1 Subrutina del descarte a tu mano. | Recursos | C |
| **PARCHE** | 2 | 8 | Convierte tu derrota de esta ronda en **empate**. | Cambiar resultado | C |
| **CUARENTENA** | 3 | 2 | Anula la Rutina del rival (no participa en el matchup). | Bloqueo | R |
| **INVERSIÓN DE POLARIDAD** | 2 | 3 | Invierte el triángulo esta ronda (quien perdía, gana). | Invertir | R |
| **HOTPATCH** | 2 | 3 | Cambia tu Rutina por otra Rutina de tu mano. | Modificar símbolo | R |
| **FORK / MIRROR** | 2 | 3 | Copia la última Subrutina que jugó el rival. | Copiar | R |
| **BUFFER (DAEMON LATENTE)** | 1 | 8 | Programa un efecto que se dispara la **próxima** ronda. | Retardo | R |
| **LOOPBACK** | 1 | 3 | Si el rival **repite** la Rutina del turno anterior, **ganas la ronda**. | Castigo patrón | R |
| **GLITCH** | 2 | 3 | Ambos cambian su Rutina por una aleatoria del triángulo (semilla). | Caos | E |
| **FORK-BOMB** | 3 | 8 | Si **vences**: el rival pierde **2** Integridad. Si **pierdes**: descartas tu mano. | Riesgo/Caos | E |
| **SIGKILL (KILL -9)** | 3 | 1 | Anula **todas** las Subrutinas del rival esta ronda. | Contra-control | E |

**Cobertura de arquetipos** (del doc base): Agresivo (Zero-Day, Fork-Bomb), Control (Cuarentena, SIGKILL, Throttle), Predicción (Loopback, Rotación, Inversión), Caos (Glitch, Null-Shard), Retardo (Buffer). ✔️

**Notas de diseño anti-abuso:**
- CUARENTENA cuesta 3 (cara) para que el control no sea trivial.
- ZERO-DAY (Ciclos 9) tiene contador claro (Escudo) → la velocidad pura no domina.
- FORK-BOMB y NULL-SHARD son **doble filo** → potencia con riesgo (suerte/estrategia, no poder gratis).
- GLITCH usa semilla → reproducible (justicia).

### 6.3 Rarezas y construcción
- Copias máximas por carta en mazo: **3** (NULL-SHARD: **1**).
- Mazo legal: exactamente **10 Rutinas + 20 Subrutinas** + **1 Núcleo** asignado.
- Set 0 da ~10 Rutinas y ~16 Subrutinas → suficiente para varios arquetipos viables desde el día 1.

---

## 7. Núcleos

Cada Núcleo da: (a) **prioridad de desempate** según su tipo en el triángulo, y (b) una **pasiva 1 vez por partida** (ligera, no rompe el equilibrio). Se elige antes de la partida → metajuego previo.

| Núcleo | Alineación | Desempate | Pasiva (1/partida) | Eco de Lore |
|---|---|---|---|---|
| **WARDEN** | Cortafuegos | gana empates de Ciclos vs Exploit | Ignora una Subrutina del rival esta ronda. | Nodos guardianes |
| **CORRUPTED** | Exploit | gana empates vs Pulso | +5 Ciclos a una Rutina esta ronda. | Nodos corruptos |
| **RELAY** | Pulso | gana empates vs Cortafuegos | Roba 1 Rutina extra. | Nodos de señal |
| **NULL-CORE** *(desbloqueable)* | — | pierde todos los espejos | 🔧 **v0.2 — CORRUPCIÓN:** marca una ronda; si **ganas** infliges **−2**, si **empatas** **ganas**, si **pierdes** −1 normal (ya **no** te autodestruye). | Fragmento de NULL |

NULL-CORE es de **alto riesgo/alta recompensa**: ahora un **finisher** agresivo en vez de una pasiva autodestructiva (corrige H5 del Ciclo 1). Identidad para jugadores que saben *cuándo* apretar el gatillo.

---

## 8. Balance

### Filosofía
- **Poder = coste + condición + riesgo.** Si una carta no tiene al menos uno, está rota.
- **Curva de complejidad**: rondas tempranas simples (poca RAM), tardías explosivas (RAM alta).
- **Cada estrategia tiene contador** (control ← SIGKILL/Escudo; agresión ← Cuarentena/Parche; predicción ← Glitch/cambiar patrón; velocidad ← Escudo/Throttle).

### Perillas de tuneo (qué tocar si algo se rompe)
| Síntoma | Perilla |
|---|---|
| Demasiado caótico / RNG | Bajar tope de RAM; subir coste de Caos; quitar Sobrecarga. |
| Control aburrido (anula todo) | Subir coste de Cuarentena/SIGKILL; limitar a 1 anulación/ronda. |
| Partidas muy largas (muchos empates) | **Muerte súbita**: desde la ronda 7, un empate hace perder Integridad a **ambos**. |
| Velocidad domina | Reforzar contadores de Ciclos altos (más Escudos en pools). |
| Snowball (el que va ganando arrasa) | Reforzar Sobrecarga (+1 RAM antes, o a 1 de diferencia). |

### Anti-RNG (regla dura)
Ninguna ronda puede combinar **robo aleatorio + resultado aleatorio + objetivo aleatorio**. Como máximo **una** fuente de azar activa por carta, y siempre derivada de semilla.

### Mulligan
Mano inicial: ver las 5, **redibujar una vez** la cantidad que elijas (estilo "London": robas 5 nuevas y devuelves N al fondo). Reduce la varianza de apertura → más justicia percibida.

---

## 9. Modos de juego

### 9.1 Modo Historia (PVE)
**Premisa** (detalle en [`NodeHackProgramNull.md`](NodeHackProgramNull.md) §8): fragmento sin memoria que desciende por las **Capas del Archivo NULL** para sobrevivir y descubrir la verdad.

- **Estructura:** Capas (ej. 5–7 capas). Cada Capa = 4–6 duelos contra BOTs + 1 **Proceso Mayor** (jefe) al fondo.
- **Progresión narrativa:** entre duelos, fragmentos de Lore + decisiones de diálogo que pueden alterar mazos enemigos o desbloquear cartas/Núcleos.
- **Jefes (ecos):** mazos y Núcleos especiales (sombras de HERALD/BALUARTE/Tríada/Arquitecto). Patrones de IA temáticos (un jefe "predicción", uno "control", etc.) → enseñan al jugador a contrar cada arquetipo.
- **Finales** (rama según decisiones + completitud de Lore):
  - **REINICIO** — revertir el colapso / reiniciar el Archivo. (Bueno.)
  - **RESONANCIA** — quedarse como guardián de los fragmentos. (Neutro.)
  - **SILENCIO** — aceptar a NULL; el Archivo se apaga. (Malo.)
  - **(Secreto)** — recuperar la identidad completa del protagonista → revelación final.
- **Reintentos:** un duelo "clave" perdido permite reintento como "restaurar snapshot", sin pay-to-win (no da poder, solo otra oportunidad).
- **Curva de dificultad:** la IA sube de nivel por Capa (§9.2). Mazos enemigos telegrafían su arquetipo (justicia: el jugador puede prepararse).

### 9.2 vs PC (Bot AI)
Diseño de IA por niveles. **Principio de justicia innegociable:** la IA **solo** usa información pública (historial revelado) + su propia mano. **Nunca** lee la mano oculta del jugador (en v0.3 ni siquiera existe carta que lo permita, §1.6).

| Nivel | Nombre | Comportamiento |
|---|---|---|
| 1 | **Aprendiz** | Rutina casi aleatoria; rara vez usa Subrutinas; no gestiona RAM. |
| 2 | **Operador** | Juega Subrutinas "en curva"; busca jugadas seguras; sin lectura. |
| 3 | **Analista** | Registra tus últimas 3–5 Rutinas (historial público); sesga su jugada a **contrar tu tipo más frecuente**; usa Loopback/Rotación; gestiona RAM. |
| 4 | **Daemon** | Análisis de frecuencia + predicción bayesiana ligera; **faroleo** (a veces juega subóptimo para no ser leído); RAM óptima; valora riesgo/recompensa de cartas de doble filo. |

- **Anti-frustración:** el Daemon tiene una probabilidad de "error humano" para no sentirse omnisciente (justicia + diversión).
- La IA es **determinista dada la semilla** (reproducible para depurar y para repeticiones).

### 9.3 Online 1v1
**Arquitectura: commit–reveal con servidor autoritativo.**

```
1. Ambos clientes PROGRAMAN en local (oculto).
2. Al COMPILAR, el cliente envía un COMMIT (hash de su jugada) al servidor.
3. Cuando ambos commits llegan → fase de REVEAL: cada cliente envía la jugada real.
4. El servidor verifica hash==jugada (anti-trampa), valida legalidad (RAM, mano, límites),
   y RESUELVE con el algoritmo §5.5 usando la SEMILLA del match.
5. El servidor difunde el resultado a ambos. Los clientes solo animan.
```

- **Por qué commit–reveal:** impide que un jugador (o cliente modificado) vea la jugada del otro antes de decidir → el mind-game oculto se mantiene **justo**.
- **Autoridad de servidor:** el cliente nunca calcula el resultado oficial → anti-trampa.
- **Temporizador por fase:** Programación ~30–45 s. Timeout → se bloquea la selección actual; si no hay Rutina elegida, se juega una Rutina base por defecto (nunca se "salta" el turno → no se puede stallear).
- **Reconexión:** ventana de gracia (ej. 60 s) con estado guardado en servidor; si no vuelve → derrota por abandono.
- **PvP asíncrono / Ghost Battles:** como la jugada es oculta y simultánea, el "ghost" simplemente **reproduce las decisiones grabadas** de un oponente; no necesita reaccionar. 100% determinista (§10).
- **Ranking:** MMR/Elo interno; ligas temáticas (**Direcciones de Memoria**: 0x01…0x07, o "Capas") con descenso/ascenso. Temporadas posibles más adelante.
- **Emparejamiento:** por MMR + (opcional) por arquetipo de Núcleo para variedad.

---

## 10. Determinismo y repeticiones

- **Semilla por partida** (seed). Todo RNG (orden de robo, Glitch, monedas de desempate) = `f(seed, turno, índice)`. Nada usa el reloj ni azar del sistema.
- **Una repetición = ** `{semilla, mazos+Núcleos, lista de decisiones por ronda}`. Con eso, el motor recalcula la partida exacta → tamaño mínimo, verificable.
- Habilita: **espectador**, **compartir repeticiones**, **Ghost Battles**, y **verificación anti-trampa** en servidor (recalcula y compara).
- **Requisito técnico clave:** el motor de reglas debe ser **una función pura**, separado de la UI, sin estado oculto ni dependencias de plataforma. (Esto condiciona la arquitectura del futuro proyecto: núcleo de reglas determinista + capa de presentación encima.)

---

## 11. Progresión, colección y economía

- **Colección:** cartas por rareza (C/R/E/N). Desbloqueo vía Historia + recompensas de duelo. NULL-SHARD y NULL-CORE como recompensas raras/secretas.
- **Sin pay-to-win:** todo lo que afecta el balance se obtiene jugando. Monetización futura **solo cosmética** (skins de cartas, efectos de "ejecución", temas del Archivo) — coherente con el énfasis del usuario en efectos visuales.
- **Mazos:** múltiples slots guardables (nombre + Núcleo + 30 cartas), validados por el editor.
- **Recompensa de retención:** misiones diarias temáticas ("ejecuta 3 Loopback exitosos"), sin energía que bloquee jugar (decisión del doc base: **sin energía** al inicio).

---

## 12. Métricas

Cómo sabremos, con datos, si cumplimos los pilares (telemetría a instrumentar desde la beta):

| Pilar | Métrica objetivo |
|---|---|
| Diversión | Duración media de partida **3–8 min**; tasa de revancha alta; retención D1/D7. |
| Justicia | Win-rate por arquetipo dentro de **45–55%**; win-rate por Núcleo equilibrado; win-rate del que abre primero ≈ 50%. |
| Suerte | % de partidas decididas en la **última ronda** moderado-alto (tensión) pero remontadas desde 0-2 **no triviales** (anti-snowball funciona, no es coin-flip). |
| Estrategia | Diferencia de win-rate entre jugadores top y media **alta** (la habilidad importa); diversidad de mazos en ladder alto. |

---

## 13. Roadmap

> Fases de **planeación → implementación**. Cada fase tiene un entregable verificable. **Aún NO se crea el proyecto** hasta cerrar Fase 0.

- **Fase 0 — Diseño (AHORA):** este PLAN + doc de concepto. ▶ *Cerrar dudas de §15, fijar números del Set 0.*
- **Fase 1 — Prototipo de reglas (sin arte):** motor determinista (§5.5) como **función pura** + 1 partida local hot-seat en consola/test + **simulador headless** que corra 10.000+ partidas por cruce con bots simples y reporte win-rates/duración/uso de cartas. ▶ *Validar y **balancear con números** el triángulo + RAM + Subrutinas. Insumo: hallazgos de [`Partidas_de_prueba.md`](Partidas_de_prueba.md) §5–§6.*
- **Fase 2 — vs PC (Niveles 1–3):** IA básica + flujo de partida completo + editor de mazos. ▶ *Primera experiencia jugable.*
- **Fase 3 — UI/UX y efectos:** previsualización de cartas, animaciones de mover/colocar/activar, feedback de Ejecución. *(Aquí entran los ejemplos visuales que el usuario aportará.)*
- **Fase 4 — Modo Historia:** Capas, jefes, diálogos, finales.
- **Fase 5 — Online 1v1:** commit–reveal, servidor autoritativo, repeticiones, Ghost.
- **Fase 6 — Ranked/colección/economía cosmética + balance con telemetría.**

### Seguimiento (checklist de Fase 0)
- [ ] Aprobar el giro narrativo (Archivo NULL) — §2.
- [ ] Aprobar capa de RAM y Sobrecarga — §5.2/§5.4.
- [ ] Validar el algoritmo de resolución §5.5 (orden de la pila).
- [ ] Revisar/ajustar números del Set 0 — §6.
- [ ] Confirmar set de Núcleos (¿incluir NULL-CORE de salida?) — §7.
- [ ] Confirmar tecnología/plataforma del proyecto (ver §15).

---

## 14. Riesgos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| El juego se vuelve "solo Subrutinas" | Pierde identidad P-P-T | RAM + Rutinas gratis + variantes de Rutina con efecto (§6.1). |
| Demasiado RNG → se siente injusto | Abandono | Regla anti-RNG (§8) + semilla + mulligan. |
| Control que anula todo = aburrido | Meta tóxico | Costes altos de anulación + SIGKILL caro + límite por ronda. |
| Snowball / spiral of death | Frustración | Sobrecarga (§5.4) + robo simétrico. |
| Cliente tramposo en online | Integridad competitiva | commit–reveal + servidor autoritativo + verificación por semilla (§9.3/§10). |
| Motor de reglas acoplado a UI | Imposible repetición/online | Núcleo de reglas como función pura desde Fase 1 (§10). |
| Complejidad asusta a nuevos | Mala retención | Curva de RAM + Historia como tutorial progresivo + Aprendiz BOT. |

---

## 15. Decisiones abiertas

Preguntas que conviene cerrar para terminar la Fase 0. (No bloquean seguir planeando, pero sí crear el proyecto.)

1. **Tecnología/plataforma:** los otros dos juegos son **Flutter** (se vio `lib/`, `pubspec`, `android/ios`). ¿`PROGRAM_NULL` también Flutter (móvil-first, coherente con el doc base "compatible con móvil")? — *Recomendación: sí, Flutter, con el motor de reglas en Dart puro y aislado.*
2. **Online desde cuándo:** ¿MVP solo PvE + hot-seat y online en Fase 5 (recomendado), o online antes?
3. **NULL-CORE** disponible de salida o solo desbloqueable (recomendado: desbloqueable).
4. **Sobrecarga** activa en competitivo o solo en casual/Historia.
5. **Muerte súbita** (§8) desde qué ronda exacta.
6. **Tamaño del Set 0**: ¿ampliamos a ~14 Rutinas / ~22 Subrutinas para más variedad inicial?

---

*Fin del plan maestro v0.1. Base lista para revisión y para iterar números antes de crear el proyecto.*
