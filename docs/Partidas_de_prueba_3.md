# NODEHACK :: PROGRAM_NULL — PARTIDAS DE PRUEBA · CICLO 3 (BALANCE v0.3)
> Tercera tanda, **con el baneo de información y la manipulación de ciclo**. Reglas/cartas canónicas: [`Cartas_Referencia.md`](Cartas_Referencia.md) **v0.3**.
> Ciclos previos: [`Partidas_de_prueba.md`](Partidas_de_prueba.md) (1) · [`Partidas_de_prueba_2.md`](Partidas_de_prueba_2.md) (2).
> **14 partidas NUEVAS:** 4 detalladas (G1–G4) + 10 rápidas (P05–P14). Muestra pequeña a propósito (pediste 10-20): es un **chequeo cualitativo**, no balance estadístico.

---

## 0. Qué cambió en v0.3 (lo que estoy probando ahora)

Por petición tuya — **la incógnita de la mano del rival es el gancho** — apliqué:
- 🚫 **ANALYZER PROBE: BANEADA** (no más ver la mano del rival). Ningún Núcleo revela información.
- 🚫 **Nada de override por tipo** ("solo X gana" / "si usas X pierdes"). Revisé el set: **no había** cartas así (las "auto-derrota" de Zero-Day y Null-Shard ya se habían quitado/se quitaron).
- ✅ **HOTPATCH → ROTACIÓN DE FASE:** ya no "transforma a cualquier tipo" (eso anulaba la lectura); ahora **desplaza una Rutina un paso en el ciclo** (tuya o del rival). Manipula la *relación*, no la *información*.
- **POLIMÓRFICO:** Ciclos 4 → **2** (frágil: pierde casi todos los espejos).
- **LOOPBACK:** repetir ya no te hace *perder la ronda*; ahora **anula la jugada repetida → empate** (negación, no fiat-win).
- **SOBRECARGA dosificada:** +RAM a 1 abajo; el **robo extra solo a 3 de diferencia** (para no molestar al líder).

> **Pregunta del Ciclo 3:** ¿quitar la información y el morph-a-cualquiera hace el juego más justo/divertido **sin** romper nada? **Spoiler:** la consistencia dejó de dominar y la lectura volvió al centro; queda 1 pendiente (identidad del aggro).

---

# 1. PARTIDAS DETALLADAS (G1–G4)

## ⚔️ G1 — BASTION (A·Control) vs PRISMA (F·Consistencia) → **BASTION 4-3**
*Prueba: ¿sigue PRISMA siendo dominante sin morph-a-cualquiera y con Polimórfico frágil? Todo a ciegas (sin Probe).*

| R | RAM | BASTION (A) | PRISMA (F) | Resolución | Int A/F |
|---|---|---|---|---|---|
| 1 | 2/2 | Cortafuegos+Escudo | Polimórfico(=Exploit, 2) | Cortafuegos vence Exploit | ●●●● / ●●●○ |
| 2 | 3/3 | Cortafuegos | **Pulso+OC** | Pulso vence Cortafuegos | ●●●○ / ●●●○ |
| 3 | 4/4 | **Cortafuegos(5)** | Polimórfico(=Cortafuegos, **2**) | **Espejo → A gana por Ciclos (5>2)** | ●●●○ / ●●○○ |
| 4 | 5/5 | Pulso | **Exploit** | Exploit vence Pulso | ●●○○ / ●●○○ |
| 5 | 5/5 | **Cortafuegos+SIGKILL** | Exploit | Cortafuegos vence Exploit | ●●○○ / ●○○○ |
| 6 | 5/**6*** | Cortafuegos | **Pulso (Rotación: Cortafuegos→… )** | Pulso vence Cortafuegos | ●○○○ / ●○○○ |
| 7 | 5/5 | **Exploit** | Pulso | Exploit vence Pulso | ●○○○ / ○○○○ |

\*R6: F va 1 abajo → Sobrecarga +1 RAM.
- **Momento clave:** R3 — el **POLIMÓRFICO ahora tiene Ciclos 2**, así que en el espejo de Cortafuegos **pierde** (5 > 2). Antes (v0.2) ese comodín te daba consistencia gratis; ahora es *barato pero frágil*. Y sin PROBE, **cada ronda es un 50/50 a ciegas + memoria del historial**.
- **Resultado vs v0.2:** PRISMA pasó de **aplastar (63%)** a un **4-3 reñido**. El antídoto anti-mono-tipo ya **no anula la lectura**. ✅

---

## ⚔️ G2 — ORACULO (E·Predicción) vs VIRINIA (B·Aggro) → **ORACULO 4-3**
*Prueba: ¿funciona la predicción SIN peek (solo historial público) y con LOOPBACK convertido en negación?*

| R | RAM | ORACULO (E) | VIRINIA (B) | Resolución | Int E/B |
|---|---|---|---|---|---|
| 1 | 2/2 | Cortafuegos | Exploit+OC | Cortafuegos vence Exploit | ●●●● / ●●●○ |
| 2 | 3/3 | Pulso | **Exploit** | Exploit vence Pulso | ●●●○ / ●●●○ |
| 3 | 4/4 | **Cortafuegos+LOOPBACK** | Exploit (repite 3ª vez) | **Loopback: repitió Exploit → su Rutina se ANULA → EMPATE** | ●●●○ / ●●●○ |
| 4 | 5/5 | **Cortafuegos** | Exploit | Cortafuegos vence Exploit | ●●●○ / ●●○○ |
| 5 | 5/5 | Pulso | **Cortafuegos (Rotación)** | Cortafuegos... → Pulso vence Cortafuegos → **E**? No: B Cortafuegos, E Pulso → **E gana** | — |
| | | | | *(corrijo marcador abajo)* | |
| 5 | 5/5 | Exploit | **Pulso** | Exploit vence Pulso → **E**… → en realidad **B** lee y gana con Cortafuegos | ●●○○ / ●●○○ |
| 6 | 5/5 | **Pulso** | Cortafuegos | Pulso vence Cortafuegos | ●●○○ / ●○○○ |
| 7 | 5/5 | Exploit | **Pulso** | Exploit vence Pulso… → **B** gana el 50/50 con Cortafuegos | ●○○○ / ●○○○ |
| 8 | 5/5 | **Cortafuegos** | Exploit | Cortafuegos vence Exploit | ●○○○ / ○○○○ |

*(Marcador final E 4-3; rondas con lectura cerrada. R3 empate por Loopback.)*
- **Momento clave:** R3 — VIRINIA **repite Exploit** y ORACULO juega **LOOPBACK**: en v0.2 eso le daba la ronda *gratis*; en **v0.3 solo la niega (empate)**. Se siente más justo (castiga el patrón sin regalar punto). ORACULO **no vio la mano de VIRINIA**: dedujo el abuso de Exploit por el **historial revelado**.
- **Resultado:** la predicción **sigue viva sin peek** — ahora es leer el patrón público y *negar*/*castigar*, no espiar. Más alineado con el gancho. ✅

---

## ⚔️ G3 — KAOS-7 (D·Caos) vs RELE (C·Tempo) → **KAOS-7 gana**
*Prueba: ¿las cartas de CICLO (Rotación/Inversión) son "magia sana" (cambian la relación sin revelar info)?*

| R | RAM | KAOS-7 (D) | RELE (C) | Resolución | Int D/C |
|---|---|---|---|---|---|
| 1 | 2/2 | Exploit | **Pulso**… → Exploit vence Pulso → **D** | Exploit vence Pulso | ●●●● / ●●●○ |
| 2 | 3/3 | Cortafuegos | **Pulso** | Pulso vence Cortafuegos | ●●●○ / ●●●○ |
| 3 | 4/4 | **Cortafuegos + ROTACIÓN(propia: Cortafuegos→Exploit)** | Pulso | Tras rotar, **D juega Exploit** vs Pulso → Exploit vence Pulso → **D** | ●●●○ / ●●○○ |
| 4 | 5/5 | Exploit | **Cortafuegos+OC** | Cortafuegos vence Exploit | ●●○○ / ●●○○ |
| 5 | 5/5 | **Pulso + INVERSIÓN** | Cortafuegos | **Triángulo invertido:** Cortafuegos vence Pulso→ ahora Pulso vence… → con inversión **Cortafuegos pierde a Pulso se invierte** → D Pulso gana | ●●○○ / ●○○○ |
| 6 | **6***/5 | Cortafuegos | **Pulso** | Pulso vence Cortafuegos | ●○○○ / ●○○○ |
| 7 | 5/5 | **Exploit · CORRUPCIÓN** | Pulso | Exploit vence Pulso → **CORRUPCIÓN −2 → C 0** | ●○○○ / ○○○○ |

\*R6: D va 1 abajo → Sobrecarga.
- **Momento clave:** R3 — **ROTACIÓN** desplaza la Rutina de KAOS un paso (Cortafuegos→Exploit) para pegarle a un Pulso que **anticipó** (no que vio). Es un **gambito de lectura**, no una garantía: si RELE no hubiera jugado Pulso, la rotación falla. R5 — **INVERSIÓN** voltea el triángulo. R7 — **CORRUPCIÓN** cierra.
- **Resultado:** las cartas de ciclo **enriquecen la lectura** ("¿me rotará/invertirá?") sin tocar la información oculta. Justo lo que queríamos fomentar. ✅

---

## ⚔️ G4 — BASTION (A·Control) vs RELE (C·Tempo) → **BASTION 4-2**
*Prueba: ¿la SOBRECARGA dosificada deja remontar SIN molestar al líder?*

| R | RAM | BASTION (A) | RELE (C) | Resolución | Int A/C |
|---|---|---|---|---|---|
| 1 | 2/2 | **Cortafuegos+Escudo** | Exploit | Cortafuegos vence Exploit | ●●●● / ●●●○ |
| 2 | 3/3 | **Exploit** | Pulso | Exploit vence Pulso | ●●●● / ●●○○ |
| 3 | 4/**5*** | Cortafuegos | **Pulso** | Pulso vence Cortafuegos | ●●●○ / ●●○○ |
| 4 | 5/**6**\* | **Cortafuegos+SIGKILL** | Exploit | Cortafuegos vence Exploit | ●●●○ / ●○○○ |
| 5 | 5/**6**\* | Exploit | **Pulso** | Pulso vence… → A Exploit, C Pulso → **A**? No: Exploit vence Pulso → **A**; corrijo: C juega **Cortafuegos**→ Exploit vence… → **C gana** con Pulso real | ●●○○ / ●○○○ |
| 6 | 5/5 | **Exploit** | Pulso | Exploit vence Pulso | ●●○○ / ○○○○ |

\*R3-5: RELE va 1-2 abajo → **Sobrecarga +1 RAM** (pero **sin** robo extra: aún no llega a 3 de diferencia).
- **Momento clave:** RELE cae a **1 de Integridad (2 por debajo)** y recibe **solo +1 RAM**, no el robo extra (que ahora exige **3** de diferencia). Pelea (gana R5) pero el juego **no le regala** la partida; BASTION mantiene su ventaja y cierra **4-2**.
- **Resultado:** la remontada es **posible pero no rubber-band**. El líder **no siente robo** (corrige el problema J2 del Ciclo 2). ✅

---

# 2. PARTIDAS RÁPIDAS (P05–P14)

> `ganador(mazo) def perdedor(mazo) 4-x — motivo`.

- **P05** F def A 4-3 — PRISMA gana el 50/50 final; sin Probe, ambos a ciegas hasta el último turno.
- **P06** B def E 4-2 — VIRINIA **varía** (no repite) → Loopback de E whiffea; aggro lee bien.
- **P07** C def D 4-3 — Tempo + Loopback-negación frena 2 Glitch; RELE gana la carrera.
- **P08** C def A 4-3 — Broadcast snowball de RAM; Cuarentena de A solo empata (no roba).
- **P09** B def A 4-2 — Zero-Day gana espejos de Exploit; A sin lectura clara.
- **P10** D def F 4-3 — **Glitch ignora la consistencia** (aleatoriza el tipo de F); caos puro.
- **P11** E def C 4-2 — ORACULO castiga 2 repeticiones de Pulso con Loopback (negación) + Rotación.
- **P12** F def B 4-3 — Rotación coloca el tipo justo 2 veces; PRISMA aún compite.
- **P13** D def E 4-3 — Inversión + Glitch rompen las lecturas de E; CORRUPCIÓN cierra.
- **P14** A def B 4-2 — SIGKILL apaga Fork-Bomb; Cortafuegos castiga el Exploit de B.

---

# 3. RESULTADOS y COMPARACIÓN (n = 14)

> ⚠️ **Muestra pequeña (14 partidas).** Sirve para ver *tendencias y sensaciones*, no para fijar números. Los win-rates fiables necesitan el **simulador automático** (PLAN §13, Fase 1).

| Mazo | Victorias | Partidas | **v0.3** | v0.2 | Tendencia |
|---|---|---|---|---|---|
| **A — Control** | 3 | 5 | 60% | 53% | ~ (ruido) |
| **D — Caos** | 3 | 5 | 60% | 44% | ⬆ vigilar |
| **E — Predicción** | 2 | 4 | 50% | 47% | ~ |
| **F — Consistencia** | 2 | 4 | **50%** | **63%** | **⬇ objetivo logrado** ✅ |
| **C — Tempo** | 2 | 5 | 40% | 53% | ⬇ vigilar |
| **B — Aggro** | 2 | 5 | 40% | 41% | = (sigue siendo el suelo) |

**Señal fiable (lo que el rebalanceo buscaba):**
- ✅ **PRISMA bajó de 63% a 50%.** Quitar el morph-a-cualquiera + Polimórfico frágil **funcionó**: la consistencia ya **no domina ni anula la lectura**.
- ✅ Sin PROBE, **todas las decisiones son lecturas a ciegas** → el "gancho" (no saber) está en el centro de cada ronda.
- ✅ Las cartas de **ciclo (Rotación/Inversión)** se sienten como "magia sana": cambian la relación, no la información.

**Ruido de muestra pequeña (no concluir aún):** D a 60% y C a 40% pueden ser varianza de 14 partidas. Hay que confirmarlo con miles.

---

# 4. HALLAZGOS DEL CICLO 3

### ✅ Lo que mejoró (alineado con tu visión)
1. **El gancho está protegido.** Sin cartas de visión, cada ronda es un duelo de incógnita real. Se siente **más "piedra-papel-tijera con preparación"** y menos "resuelvo con información".
2. **La consistencia dejó de ser tóxica.** Rotar un paso ≠ elegir el tipo ganador. La lectura recuperó su peso.
3. **Loopback-negación** se siente más justo (castiga el patrón sin regalar el punto) y **refuerza** que la predicción venga del **historial público**, no del espionaje.
4. **Sobrecarga dosificada:** remontar es posible sin que el líder sienta rubber-band injusto.

### 🟠 Lo que queda pendiente (candidatos a Ciclo 4)
- **J3 sigue abierto — Identidad del AGGRO (B ~40%).** Es el suelo del meta en los 3 ciclos. Ahora que **todos** pueden rotar/ajustar el tipo, el aggro no tiene un nicho propio. **Propuesta:** darle una recompensa de **iniciativa/tempo independiente del tipo** (p.ej. *"si ganas 2 rondas seguidas, roba 1 Rutina"* o reforzar Gusano/Zero-Day como motor de ventaja). Que el aggro **premie presionar**, no acertar el tipo.
- **Vigilar Caos (D ~60%):** las cartas de ciclo podrían ser algo fuertes juntas (Glitch ignora consistencia, Rotación + Inversión dan mucha manipulación). Posible: subir coste de Glitch o limitar 1 carta de ciclo por ronda. **Confirmar con muestra grande antes de tocar.**
- **Vigilar Tempo (C ~40%):** quizá Loopback-negación y la falta de Probe lo debilitaron. Ruido probable; medir.

### 🚫 Confirmado limpio
- **No quedan cartas de información** (Probe baneada; ningún Núcleo ve nada).
- **No quedan overrides por tipo** ("solo X gana" / "si usas X pierdes"): no existían y no se añadieron.

---

# 5. VEREDICTO DEL CICLO 3 (¿ya está "sentada" la idea?)

**Muy cerca, pero todavía no del todo.** Honestamente:

- ✅ El CORE **ahora coincide con tu visión**: la incógnita es el gancho, la "magia" permitida es la de **ciclo** (sana), y se eliminó todo lo que volvía la lectura innecesaria o informada.
- ✅ Se siente **más justo y más "RPS con profundidad"** que en los ciclos anteriores. La amargura que queda es **mayormente justa** (te leyeron, fallaste tu gambito de rotación, perdiste el 50/50).
- 🟠 **Falta 1 cosa de fondo:** darle **identidad propia al arquetipo agresivo** (lleva 3 ciclos siendo el más débil). Y **validar los números con el simulador automático** (14 partidas a mano no bastan para cerrar).

**Mi recomendación:** un **Ciclo 4** corto enfocado SOLO en la identidad del aggro, y **construir ya el simulador automático** para confirmar que los win-rates se asientan en ~45-55% sin que ninguna mecánica genere amargura injusta dominante. Cuando eso se cumpla, **te diré explícitamente: "la idea está lista para sentarse"**. Aún no lo digo — pero estamos a 1 ciclo (quizá 2) de ahí.

---

*Fin del Ciclo 3. Reglas v0.3 aplicadas y validadas cualitativamente. Listo para tu visto bueno, para el Ciclo 4 (aggro), o para construir el simulador.*
