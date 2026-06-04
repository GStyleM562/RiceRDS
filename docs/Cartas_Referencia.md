# NODEHACK :: PROGRAM_NULL — CATÁLOGO CANÓNICO DE CARTAS Y REGLAS
> **Fuente de verdad** para las simulaciones. Si una simulación contradice este archivo, **manda este archivo**.
> **Versión 0.4** (balance validado con el **simulador automático** — 150k partidas/prueba). Pruebas: Ciclo 1 [`Partidas_de_prueba.md`](Partidas_de_prueba.md) · 2 [`_2`](Partidas_de_prueba_2.md) · 3 [`_3`](Partidas_de_prueba_3.md) · **4 [`_4`](Partidas_de_prueba_4.md)**. Motor: [`../nodehack_sim/`](../nodehack_sim/).
> Deriva de [`NodeHackNull_PLAN.md`](NodeHackNull_PLAN.md) §5–§7.

---

## 0. PRINCIPIO RECTOR (v0.3) — qué protege el CORE

> **La incógnita de la mano del rival es EL GANCHO del juego.** Por lo tanto:
> 1. 🚫 **PROHIBIDO ver información oculta** (mano/cartas del rival). Ninguna carta ni Núcleo puede revelarla.
> 2. 🚫 **PROHIBIDO el override determinista por tipo** ("solo X gana esta ronda", "si usas X pierdes").
> 3. ✅ **PERMITIDO manipular el CICLO**: invertir el triángulo, o **rotar** una Rutina al tipo *siguiente/anterior*. Esto **enriquece** la lectura (ahora también lees "¿me va a rotar/invertir?") en vez de anularla.

### Changelog v0.3 → v0.4 (validado con simulador, [`Partidas_de_prueba_4.md`](Partidas_de_prueba_4.md))
| Cambio | Antes | Ahora | Motivo (dato) |
|---|---|---|---|
| **FORK-BOMB** | Al perder: descarta 2 cartas | Al perder: **−1 Integridad extra** (apuesta simétrica −2) | Tenía 70% win al jugarse (sobrepoderosa). |
| **NULL-CORE CORRUPCIÓN** | empate→win **y −2 al ganar** | Solo **empate→win** (sin bonus −2) | El −2 inflaba a "RUIDO" (58→50%). |
| **MURO-BALUARTE** | inmune a Throttle | **+ inmune a anulación** (Cuarentena/Loopback) | Buff a Control (muro real). |
| **Mazo A "MURO"** | muy defensivo (3 Cuarentena, 2 Parche…) | reconstruido (tempo/cierre: 3 Hotfix, 3 Overclock…) | Control 41→47% (era construcción, no cartas). |
| **Muerte súbita (R7+)** | empate daña a ambos | **empate se rompe por Ciclos** (gana mayor; si igual, A) | Evita dobles-KO/estancamiento. |
| **HOTFIX** | "rival no roba" (todo) | rival **no roba subrutinas** (la Rutina obligatoria sí) | No dejar al rival sin jugada. |
| **BUFFER** | efecto diferido genérico | **+1 RAM la próxima ronda** (modelo del simulador) | Simplificación operable. |

### Changelog v0.2 → v0.3
| Cambio | Antes (v0.2) | Ahora (v0.3) | Motivo |
|---|---|---|---|
| **ANALYZER PROBE** | "Ves la mano del rival" | 🚫 **BANEADA** (eliminada) | Viola el gancho (regla 1). |
| **Núcleos** | — | Confirmado: **ninguno revela información** | Regla 1. |
| **HOTPATCH** | Transforma a **cualquier** tipo | → **ROTACIÓN DE FASE**: avanza una Rutina **un paso** en el ciclo (no a cualquier tipo) | El morph-a-cualquiera anulaba la lectura (J1, Ciclo 2). Rotar la enriquece (regla 3). |
| **POLIMÓRFICO** | Ciclos 4 | Ciclos **2** (frágil, pierde casi todos los espejos) | Bajar la consistencia que dominaba (PRISMA 63%). |
| **NULL-SHARD** | "Pierdes si rival juega Loopback" (auto-derrota) | Sin auto-derrota; en su lugar: **no recibe Overclock/Throttle** (inestable) | Quitar override determinista (regla 2). |
| **LOOPBACK** | Repite → **ganas** la ronda | Repite → su Rutina se **anula** → **EMPATE** (negación) | Menos fiat-win; coherente con Cuarentena. |
| **SOBRECARGA** | +RAM (1 abajo) · +RAM+robo (2 abajo) | +RAM (1 abajo) · +RAM **y robo solo a 3 abajo** | Evitar rubber-band molesto para el líder (J2, Ciclo 2). |

### Changelog v0.1 → v0.2 (histórico)
Integridad 3→4 · Cuarentena anula→empate (coste 2) · Zero-Day sin auto-derrota (coste −1 RAM) · Fork-Bomb al perder descarta 2 · NULL-CORE finisher CORRUPCIÓN · mismo tipo → gana mayor Ciclos · nueva Rutina Polimórfico.

---

## A. REGLAS EXACTAS USADAS EN LAS SIMULACIONES (v0.3)

1. **Objetivo:** Integridad inicial = **4**. Perder ronda → −1. A **0 = FLUSH** (derrota). (Modo "rápido": 3.)
2. **Mazos separados:** **10 Rutinas** + **20 Subrutinas**, barajados aparte.
3. **Robo:** mano inicial = **2 Rutinas + 3 Subrutinas**. **Adquisición (fin de ronda):** +1 Rutina + 2 Subrutinas. Ronda 1 con mano inicial. **Tope de mano = 8.**
4. **RAM por ronda:** R1=2, R2=3, R3=4, R4=5, R5+=5 (tope 5, salvo Broadcast). **No se acumula.**
   - **Sobrecarga:** **1** abajo → +1 RAM. **3 o más** abajo → +1 RAM **y** robas +1 Subrutina.
5. **Jugada por ronda:** **1 Rutina (gratis)** + **0 a 2 Subrutinas** (coste ≤ RAM).
6. **Triángulo:** **CORTAFUEGOS > EXPLOIT > PULSO > CORTAFUEGOS.** Mismo tipo → gana **mayor Ciclos** (→ Núcleo → empate). Ciclo del **rotador**: Cortafuegos →(+1)→ Exploit →(+1)→ Pulso →(+1)→ Cortafuegos.
7. **Ciclos:** ordenan resolución y deciden espejos.
8. **Empate de ronda:** nadie pierde Integridad. **Muerte súbita (v0.4):** desde la **R7** los empates se **rompen por Ciclos** (gana mayor Ciclos; si igualan, el jugador 1) → sin empates ni partidas eternas.
9. **Información oculta TOTAL:** **nadie** ve la mano del rival (no existe carta ni Núcleo que lo permita). Solo se conoce lo **revelado** en rondas anteriores (historial público) y lo propio. Jugadas a ciegas y simultáneas.

### Pila de resolución (determinista)
```
1. PROTECCIÓN/CANCELACIÓN: SIGKILL (anula subrutinas rivales) · ESCUDO (protege tu Rutina)
2. ANULACIÓN:              CUARENTENA (anula Rutina rival → EMPATE) · LOOPBACK (si rival repitió tipo → anula su Rutina → EMPATE)
3. CICLO:                  INVERSIÓN (invierte triángulo) · ROTACIÓN (mueve una Rutina +1 en el ciclo) · GLITCH (ambas → tipo aleatorio) · FORK (copia última subrutina rival)
4. CICLOS:                 OVERCLOCK (+4 tuya) · THROTTLE (−4 rival, salvo Escudo)
5. MATCHUP:                triángulo vigente · mismo tipo → mayor Ciclos (→Núcleo→empate) · Rutina anulada → EMPATE
6. DAÑO + TRIGGERS:        perdedor −1 · Hotfix/Gusano/Broadcast/Pulso-Echo/Zero-Day(recalienta)
7. POST:                   PARCHE (tu derrota→empate) · FORK-BOMB (ganas:−2 al rival / pierdes:−1 extra a ti) · robos (Recovery/Defrag) · BUFFER (+1 RAM próxima ronda)
8. ADQUISICIÓN:            descarte + robo (+1 Rutina, +2 Subrutinas) + Sobrecarga si aplica
```

---

## B. RUTINAS (Mazo de Acción)

| # | Carta | Triángulo | Ciclos | Rar. | Efecto |
|---|---|---|---|---|---|
| R1 | **CORTAFUEGOS** | Cortafuegos | 5 | C | Base. Vence a Exploit. |
| R2 | **EXPLOIT** | Exploit | 5 | C | Base. Vence a Pulso. |
| R3 | **PULSO** | Pulso | 5 | C | Base. Vence a Cortafuegos. |
| R4 | **HOTFIX** | Cortafuegos | 8 | R | Si vences, el rival **no roba** en la Adquisición de esta ronda. |
| R5 | **MURO-BALUARTE** | Cortafuegos | 3 | E | **Inmune a anulación (Cuarentena/Loopback) y a THROTTLE.** Si vences, ignoras efectos negativos de la ronda. |
| R6 | **ZERO-DAY** | Exploit | 9 | R | Gana espejos de Exploit por Ciclos. **Coste:** −1 RAM la ronda siguiente. |
| R7 | **GUSANO** | Exploit | 4 | R | Si vences, roba 1 Subrutina del descarte del rival. |
| R8 | **BROADCAST** | Pulso | 2 | R | Si vences, **+2 RAM** la próxima ronda. |
| R9 | **PULSO-ECHO** | Pulso | 5 | E | Si **pierdes** la ronda, roba 1 Rutina y conserva 1 RAM. |
| R10 | **POLIMÓRFICO** | Comodín | **2** | C | Declaras su tipo al programar (oculto). Ciclos muy bajos → **pierde casi todos los espejos**. (máx. 3) |
| R11 | **NULL-SHARD** | Comodín | 6 | N | Comodín de consistencia: declaras tipo al programar (oculto). **No puede recibir Overclock/Throttle** (señal inestable). (máx. 1) |

---

## C. SUBRUTINAS (Mazo de Alteración)

| # | Carta | RAM | Paso | Rar. | Efecto |
|---|---|---|---|---|---|
| S1 | **OVERCLOCK** | 1 | 4 | C | +4 Ciclos a tu Rutina. |
| S2 | **THROTTLE** | 1 | 4 | C | −4 Ciclos a la Rutina rival. |
| S3 | **ESCUDO DE DATOS** | 1 | 1 | C | Protege tu Rutina de anulación/alteración esta ronda. |
| ~~S4~~ | ~~**ANALYZER PROBE**~~ | — | — | — | 🚫 **PROHIBIDA (baneada v0.3):** revelaba la mano del rival. Viola el gancho del juego. |
| S5 | **RECOVERY CYCLE** | 1 | 7 | C | Roba 2 Subrutinas. |
| S6 | **DEFRAG** | 0 | 7 | C | Devuelve 1 Subrutina del descarte a tu mano. |
| S7 | **PARCHE** | 2 | 7 | C | Convierte tu derrota de esta ronda en **empate**. |
| S8 | **CUARENTENA** | 2 | 2 | R | Anula la Rutina del rival → la ronda es **EMPATE** (niega el punto, no lo roba). |
| S9 | **INVERSIÓN DE POLARIDAD** | 2 | 3 | R | Invierte el triángulo esta ronda. (Si ambos la juegan, se cancela.) |
| S10 | **ROTACIÓN DE FASE** | 2 | 3 | R | Elige una Rutina (la tuya o la del rival) y **avánzala un paso** en el ciclo (Cortafuegos→Exploit→Pulso→Cortafuegos). |
| S11 | **FORK / MIRROR** | 2 | 3 | R | Copia la última Subrutina que jugó el rival. |
| S12 | **BUFFER** | 1 | 7 | R | Programa un efecto que se dispara la **próxima** ronda. |
| S13 | **LOOPBACK** | 1 | 2 | R | Si el rival **repite** su tipo de Rutina del turno previo → su Rutina se **anula** → la ronda es **EMPATE** (niegas su jugada repetida). |
| S14 | **GLITCH** | 2 | 3 | E | Ambas Rutinas → tipo aleatorio (semilla), salvo ESCUDO. |
| S15 | **FORK-BOMB** | 3 | 7 | E | Apuesta simétrica: si **vences**, rival **−2**; si **pierdes**, **tú −1 extra** (−2 a ti). |
| S16 | **SIGKILL** | 3 | 1 | E | Anula **todas** las Subrutinas del rival esta ronda. |

> **Nota de diseño:** las cartas de CICLO (Inversión, Rotación, Glitch) **no anulan la lectura**: siguen sin saber qué jugó el rival; solo desplazan la relación. Son la "magia sana" que el juego quiere fomentar.

---

## D. NÚCLEOS

> ✅ **Ninguno revela información oculta** (regla 1). Sus pasivas son de combate/recursos, no de visión.

| Núcleo | Alineación | Desempate Ciclos | Pasiva (1×/partida) |
|---|---|---|---|
| **WARDEN** | Cortafuegos | gana espejo vs Exploit | Ignora una Subrutina rival esta ronda. |
| **CORRUPTED** | Exploit | gana espejo vs Pulso | +5 Ciclos a tu Rutina esta ronda. |
| **RELAY** | Pulso | gana espejo vs Cortafuegos | Roba 1 Rutina extra. |
| **NULL-CORE** | — (pierde espejos) | — | **CORRUPCIÓN (v0.4):** 1×/partida convierte **un empate en victoria** (sin bonus de daño). *(Pasiva floja a propósito; pendiente de rediseño — ver Ciclo 4.)* |

---

## E. MAZOS DE MUESTRA (v0.3 — sin Probe; Hotpatch→Rotación)

> Cada mazo: 10 Rutinas + 20 Subrutinas (máx. 3 copias; Null-Shard máx. 1).

### Mazo A — "MURO" · Núcleo **WARDEN** · *(Control)* — reconstruido en v0.4
- **Rutinas:** Cortafuegos×3, Hotfix×3, Muro-Baluarte×1, Polimórfico×1, Pulso×1, Exploit×1
- **Subrutinas:** Overclock×3, Escudo×2, Throttle×2, SIGKILL×2, Loopback×2, Rotación×2, Recovery×2, Cuarentena×1, Parche×1, Fork-Bomb×1, Defrag×2

### Mazo B — "ENJAMBRE" · Núcleo **CORRUPTED** · *(Agresivo)*
- **Rutinas:** Exploit×3, Zero-Day×2, Gusano×1, Polimórfico×2, Cortafuegos×1, Pulso×1
- **Subrutinas:** Overclock×3, Rotación×3, Throttle×2, Fork-Bomb×2, Escudo×2, Recovery×3, Glitch×1, Loopback×1, Inversión×1, Defrag×2

### Mazo C — "SEÑAL" · Núcleo **RELAY** · *(Tempo)*
- **Rutinas:** Pulso×3, Broadcast×2, Pulso-Echo×2, Polimórfico×1, Cortafuegos×1, Exploit×1
- **Subrutinas:** Recovery×3, Loopback×2, Overclock×3, Escudo×2, Rotación×2, Throttle×2, Cuarentena×1, Parche×1, Buffer×1, Defrag×2, Inversión×1

### Mazo D — "RUIDO" · Núcleo **NULL-CORE** · *(Caos)*
- **Rutinas:** Null-Shard×1, Polimórfico×2, Cortafuegos×2, Exploit×3, Pulso×2
- **Subrutinas:** Glitch×3, Rotación×3, Inversión×3, Fork×2, Overclock×2, Throttle×2, Escudo×2, Recovery×3

### Mazo E — "LECTOR" · Núcleo **RELAY** · *(Predicción — sin peek, pura lectura de patrón)*
- **Rutinas:** Cortafuegos×2, Exploit×2, Pulso×2, Hotfix×1, Pulso-Echo×1, Polimórfico×2
- **Subrutinas:** Loopback×3, Rotación×3, Inversión×3, Throttle×2, Overclock×2, Escudo×2, Recovery×2, Parche×1, Cuarentena×1, Buffer×1

### Mazo F — "PRISMA" · Núcleo **RELAY** · *(Consistencia — debilitada en v0.3)*
- **Rutinas:** Polimórfico×3, Null-Shard×1, Cortafuegos×2, Exploit×2, Pulso×2
- **Subrutinas:** Rotación×3, Recovery×3, Escudo×2, Overclock×2, Throttle×2, Loopback×2, Parche×1, Cuarentena×1, Inversión×1, Buffer×1, Defrag×2
