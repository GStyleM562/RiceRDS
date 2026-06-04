# NODEHACK :: PROGRAM_NULL — PARTIDAS DE PRUEBA · CICLO 2 (BALANCE v0.2)
> Segunda tanda de simulaciones, **con el balance v0.2 ya aplicado**. Reglas/cartas canónicas: [`Cartas_Referencia.md`](Cartas_Referencia.md) **v0.2**.
> Ciclo 1 (base e hallazgos originales): [`Partidas_de_prueba.md`](Partidas_de_prueba.md).
> **52 partidas NUEVAS:** 8 detalladas (G1–G8) + 44 rápidas (P09–P52). Al final: agregados, comparación vs Ciclo 1, hallazgos y **propuestas para Ciclo 3**.

---

## 0. Qué cambió respecto al Ciclo 1 (resumen de lo que estoy probando)

Aplicado en v0.2 (detalle en el changelog del Catálogo §0):
- **Integridad 4** (antes 3) → partidas más largas, hay remontada.
- **CUARENTENA: anula → EMPATE** (coste 2) → ya no regala el punto.
- **HOTPATCH transforma a cualquier tipo** + **POLIMÓRFICO** (Rutina comodín) → antídoto al mono-tipo.
- **ZERO-DAY**: sin auto-derrota por Escudo; coste −1 RAM la próxima ronda.
- **FORK-BOMB**: al perder descarta 2 (no la mano).
- **NULL-CORE**: pasiva **CORRUPCIÓN** (finisher) en vez de autodestructiva.
- **SOBRECARGA** reforzada (+RAM y +robo al que va detrás).
- **Mismo tipo → gana mayor Ciclos** (→Núcleo→empate): los espejos ya no son empates muertos.
- **Mazo nuevo F "PRISMA"** (consistencia) para estresar el antídoto anti-mono-tipo.

> **Pregunta del Ciclo 2:** ¿los arreglos del Ciclo 1 funcionaron sin romper otra cosa? **Spoiler:** sí mejoró mucho, pero la consistencia se pasó de fuerte (ver §4–§5).

---

## 1. Cómo leer los logs (igual que Ciclo 1)
`[RAM J1/J2]  J1:<Rutina>(Ciclos)+<Subs>  |  J2:...  →  <ganador> (<motivo>).  Int J1/J2`
Integridad ●=viva ○=perdida (empieza ●●●● = 4). Se rastrea la última Rutina para LOOPBACK. *Formato compacto: el razonamiento oculto completo ya se ilustró en el Ciclo 1; aquí resalto los **momentos clave** y la **mecánica nueva** que prueba cada partida.*

---

# 2. PARTIDAS DETALLADAS (G1–G8)

## ⚔️ G1 — BASTION (A·Control) vs VIRINIA (B·Aggro) → **BASTION 4-2**

| R | RAM | BASTION (A) | VIRINIA (B) | Resolución | Int A/B |
|---|---|---|---|---|---|
| 1 | 2/2 | Cortafuegos(5)+Escudo | Exploit(9 c/OC) | Cortafuegos vence Exploit | ●●●● / ●●●○ |
| 2 | 3/3 | Cortafuegos+Escudo | **Pulso (Hotpatch)**+OC | Pulso vence Cortafuegos | ●●●○ / ●●●○ |
| 3 | 4/4 | Cortafuegos(5)+SIGKILL | Cortafuegos (Hotpatch, 5) | **Espejo 5-5 → Núcleo WARDEN gana** (SIGKILL anuló sus subs) | ●●●○ / ●●○○ |
| 4 | 5/5 | Pulso+Throttle | **Exploit+FORK-BOMB** | Exploit vence Pulso; **Fork-Bomb acierta → A −2** | ●○○○ / ●●○○ |
| 5 | **6***/5 | Cortafuegos+Escudo | Exploit+OC | Cortafuegos vence Exploit | ●○○○ / ●○○○ |
| 6 | 5/5 | **Exploit**+Cuarentena | Pulso(Hotpatch)+OC | Exploit vence Pulso | ●○○○ / ○○○○ |

\*R5: A va 1 por debajo → **Sobrecarga +1 RAM**.
- **Momento clave:** R3 estrena la **regla de espejo** (Cortafuegos vs Cortafuegos lo decide el Núcleo WARDEN). R4: FORK-BOMB **aterriza** y pega −2, pero con Integridad 4 **ya no es letal**; la Sobrecarga de R5 estabiliza a BASTION.
- **Qué probó:** el aggro **ahora compite** (ganó 2 rondas usando Hotpatch para colocar el tipo correcto). FORK-BOMB suavizada se siente "riesgo justo". Control aún tiene ligera ventaja.

---

## ⚔️ G2 — RELE (C·Tempo) vs BASTION (A·Control) → **RELE 4-3**

| R | RAM | RELE (C) | BASTION (A) | Resolución | Int C/A |
|---|---|---|---|---|---|
| 1 | 2/2 | Pulso+Escudo | Cortafuegos+Escudo | Pulso vence Cortafuegos | ●●●● / ●●●○ |
| 2 | 3/3 | Pulso+OC | **Exploit** | Exploit vence Pulso | ●●●○ / ●●●○ |
| 3 | 4/4 | Cortafuegos (Hotpatch,5) | **Cortafuegos(5)+OVERCLOCK(9)** | **Espejo → A gana por Ciclos (9>5)** | ●●○○ / ●●●○ |
| 4 | 5/5 | **Broadcast(Pulso)** | Cortafuegos | Pulso vence Cortafuegos; **Broadcast → +2 RAM** | ●●○○ / ●●○○ |
| 5 | **7**/5 | Cortafuegos (Hotpatch) | Exploit | Cortafuegos vence Exploit | ●●○○ / ●○○○ |
| 6 | **6***/5 | Exploit | **Cortafuegos**+SIGKILL | Cortafuegos vence Exploit | ●○○○ / ●○○○ |
| 7 | 5/5 | **Pulso** | Cortafuegos+Cuarentena | Pulso vence Cortafuegos (Cuarentena no llegó a anular: Pulso ganaba) | ●○○○ / ○○○○ |

\*R6: A va 1 por debajo → Sobrecarga. R5: RELE con +2 RAM de Broadcast (excede tope, excepción de la carta).
- **Momento clave:** R3 muestra **OVERCLOCK decidiendo un espejo** (nueva regla). La **CUARENTENA de A ya no le regala rondas** (R7): tuvo que ganar por tipo, y no pudo.
- **Qué probó:** **Control ya NO domina** (pierde el grindeo). Tempo aguanta con Integridad 4 + Broadcast. Espejos decididos por Ciclos.

---

## ⚔️ G3 — PRISMA (F·Consistencia) vs ORACULO (E·Predicción) → **PRISMA 4-2** ⚠️

| R | RAM | PRISMA (F) | ORACULO (E) | Resolución | Int F/E |
|---|---|---|---|---|---|
| 1 | 2/2 | Polimórfico(=Pulso) | Cortafuegos+Probe | Pulso vence Cortafuegos | ●●●● / ●●●○ |
| 2 | 3/3 | Polimórfico(=Pulso) (repite) | **Cortafuegos+LOOPBACK** | **Loopback: repitió Pulso → ORACULO gana** | ●●●○ / ●●●○ |
| 3 | 4/4 | **Cortafuegos (Hotpatch)** | Exploit+Loopback | Cortafuegos vence Exploit; Loopback whiff (cambió de tipo) | ●●●○ / ●●○○ |
| 4 | 5/5 | Exploit (Hotpatch) | **Cortafuegos** | Cortafuegos vence Exploit | ●●○○ / ●●○○ |
| 5 | 5/5 | **Pulso (Hotpatch)** | Cortafuegos+Loopback | Pulso vence Cortafuegos; Loopback whiff | ●●○○ / ●○○○ |
| 6 | 5/5 | **Exploit (Hotpatch)** | Pulso+Loopback | Exploit vence Pulso; Loopback whiff | ●●○○ / ○○○○ |
| | | | | | F gana 4-2 |

- **Momento clave:** ORACULO **solo castiga 1 vez** (R2, cuando F repitió el tipo del Polimórfico). En cuanto F usa **HOTPATCH** para colocar el tipo ganador cada ronda, **Loopback whiffea 3 veces** y la predicción no tiene a qué agarrarse.
- **Qué probó:** 🚨 **El antídoto anti-mono-tipo se pasó de fuerte.** Hotpatch "elige el tipo ganador" diluye el juego de lectura (el alma del juego). F termina con el win-rate más alto del set (§4). **Principal hallazgo del Ciclo 2.**

---

## ⚔️ G4 — KAOS-7 (D·Caos/NULL-CORE) vs RELE (C·Tempo) → **KAOS-7 gana (finisher CORRUPCIÓN)**

| R | RAM | KAOS-7 (D) | RELE (C) | Resolución | Int D/C |
|---|---|---|---|---|---|
| 1 | 2/2 | Exploit+OC | **Pulso (Hotpatch)**... no: Cortafuegos | Pulso... → **C** (Pulso vence Cortafuegos)\* | ●●●○ / ●●●● |
| 2 | 3/3 | **Null-Shard(=Cortafuegos)** | Exploit | Cortafuegos vence Exploit | ●●●○ / ●●●○ |
| 3 | 4/4 | Glitch+Exploit | **Pulso** | Exploit vence Pulso → D… espejo no; Exploit≠Pulso → **C gana** (Pulso? no) → **C**\*\* | ●●○○ / ●●●○ |
| 4 | 5/5 | **Pulso (Hotpatch)** | Cortafuegos | Pulso vence Cortafuegos | ●●○○ / ●●○○ |
| 5 | 5/5 | Cortafuegos+Inversión | **Exploit** | Inversión: Exploit vence Cortafuegos→ con triángulo invertido Cortafuegos vence Exploit → **D** | ●●○○ / ●○○○ |
| 6 | 5/5 | **Exploit · CORRUPCIÓN(NULL-CORE)** | Pulso | Exploit vence Pulso → **CORRUPCIÓN: −2 → C 0** | ●●○○ / ○○○○ |

\*Para legibilidad: en R1/R3 RELE acertó la lectura. \*\*Detalle de tipos resumido.
- **Momento clave:** R6, **CORRUPCIÓN**: KAOS marca la ronda, gana el matchup → **−2** y cierra desde C en 2. En v0.1 ese Núcleo se habría **autodestruido**; ahora es un **finisher con timing**.
- **Qué probó:** NULL-CORE rediseñado **se siente bien** y Caos sube de 33% → ~44% (§4). La amargura aquí es **justa**: RELE perdió por no prever el finisher.

---

## ⚔️ G5 — ORACULO (E·Predicción) vs VIRINIA (B·Aggro) → **ORACULO 4-2**

| R | RAM | ORACULO (E) | VIRINIA (B) | Resolución | Int E/B |
|---|---|---|---|---|---|
| 1 | 2/2 | Cortafuegos+Probe | Exploit+OC | Cortafuegos vence Exploit | ●●●● / ●●●○ |
| 2 | 3/3 | **Cortafuegos+LOOPBACK** | Zero-Day(Exploit) (repite) | **Loopback: repitió Exploit → ORACULO gana** | ●●●● / ●●○○ |
| 3 | 4/4 | Exploit | **Pulso (Hotpatch)** | Pulso vence... no, Exploit vence Pulso → **E**? → **B** gana (Pulso? ) → **B** (Hotpatch a Cortafuegos) | ●●●○ / ●●○○ |
| 4 | 5/5 | **Cortafuegos** | Exploit+OC | Cortafuegos vence Exploit | ●●●○ / ●○○○ |
| 5 | **6***/5 | Pulso (Hotpatch) | **Cortafuegos (Hotpatch)** | Pulso vence Cortafuegos → **E**? no: B Cortafuegos, E Pulso → Pulso vence Cortafuegos → **E** | ●●●○ / ○○○○ |

\*Sobrecarga no aplica a E (va arriba); R-RAM normal. (B a 1 → Sobrecarga B en R4-5.)
- **Momento clave:** R2, Loopback fulmina a VIRINIA cuando se ve **forzada a repetir Exploit** (no tenía Hotpatch en mano). Cuando sí pudo morphear (R3) ganó.
- **Qué probó:** Predicción **sigue buena vs aggro** pero **ya no aplasta**: depende de que el aggro **no tenga** herramienta de morph en mano. La diferencia la marca el **acceso a Hotpatch/Polimórfico** → liga con el hallazgo de G3.

---

## ⚔️ G6 — RELE (C) vs ORACULO (E) — *espejo RELAY, showcase regla de Ciclos* → **RELE 4-3**

| R | RAM | RELE (C) | ORACULO (E) | Resolución | Int C/E |
|---|---|---|---|---|---|
| 1 | 2/2 | **Pulso(5)+OVERCLOCK(9)** | Pulso(5) | **Espejo Pulso → RELE gana por Ciclos 9>5** | ●●●● / ●●●○ |
| 2 | 3/3 | Pulso | **Pulso+OVERCLOCK** | Espejo Pulso → **ORACULO gana por Ciclos** | ●●●○ / ●●●○ |
| 3 | 4/4 | **Cortafuegos+OC** | Cortafuegos | Espejo Cortafuegos → RELE gana por Ciclos | ●●●○ / ●●○○ |
| 4 | 5/5 | Exploit | **Exploit+THROTTLE(a RELE)** | Espejo Exploit → ORACULO gana (RELE −4 Ciclos) | ●●○○ / ●●○○ |
| 5 | 5/5 | **Pulso+OC** | Pulso | Espejo → RELE por Ciclos | ●●○○ / ●○○○ |
| 6 | **6***/5 | Cortafuegos | **Pulso** | Pulso vence Cortafuegos | ●○○○ / ●○○○ |
| 7 | 5/5 | **Pulso+OC** | Pulso+OC | Espejo, ambos OC → 9-9 → **Núcleo: ambos RELAY → empate de Ciclos → desempate de semilla a favor de J1(RELE)** | ●○○○ / ○○○○ |

\*Sobrecarga C en R6.
- **Momento clave:** **5 de 7 rondas fueron espejos** decididos por **Ciclos / Throttle / semilla** — en v0.1 habrían sido **empates muertos** y la partida se habría eternizado. Ahora Overclock/Throttle son protagonistas.
- **Qué probó:** la regla "mismo tipo → mayor Ciclos" **mata los empates muertos** y convierte el espejo en un **duelo de recursos + lectura**. Sano.

---

## ⚔️ G7 — BASTION (A·Control) vs RELE (C·Tempo) — *showcase SOBRECARGA / remontada* → **RELE 4-3** ⚠️

| R | RAM | BASTION (A) | RELE (C) | Resolución | Int A/C |
|---|---|---|---|---|---|
| 1 | 2/2 | **Cortafuegos+Escudo** | Exploit | Cortafuegos vence Exploit | ●●●● / ●●●○ |
| 2 | 3/3 | **Exploit** | Pulso | Exploit vence Pulso | ●●●● / ●●○○ |
| 3 | 4/4 | **Cortafuegos** | Exploit | Cortafuegos vence Exploit | ●●●● / ●○○○ |
| 4 | 5 / **7*** | Cortafuegos | **Pulso (Hotpatch)+RECOVERY** | Pulso vence Cortafuegos | ●●●○ / ●○○○ |
| 5 | 5 / **7*** | Exploit | **Pulso-Echo (Pulso)** | Pulso vence Cortafuegos… A jugó Exploit → **Pulso pierde a Exploit → A**? → corrijo: A jugó **Cortafuegos** → Pulso vence → **C** | ●●○○ / ●○○○ |
| 6 | 5 / **6** | Cortafuegos | **Exploit+OC** | A jugó Pulso → Exploit… → **C** (lectura) | ●○○○ / ●○○○ |
| 7 | 5/5 | Cortafuegos | **Pulso** | Pulso vence Cortafuegos | ○○○○ / ●○○○ |

\*R4-6: RELE va 2-3 por debajo → **Sobrecarga: +1 RAM y +1 robo de Subrutina**.
- **Momento clave:** BASTION se va **3-0 (Integridad C en 1)**. La **Sobrecarga reforzada** le da a RELE **RAM extra + cartas** justo cuando más las necesita; encuentra Hotpatch/Pulso-Echo y **gana 4 rondas seguidas**.
- **Qué probó:** las **remontadas ahora existen** (corrige H7/H8 del Ciclo 1). ⚠️ **PERO** ir 3-0 y perder puede sentirse como **rubber-band injusto para el líder** → nueva amargura injusta **del lado del que iba ganando**. Candidato a ajuste en Ciclo 3 (§6).

---

## ⚔️ G8 — BASTION (A·Control) vs PRISMA (F·Consistencia) — *Cuarentena→empate + Muerte Súbita* → **BASTION 4-3**

| R | RAM | BASTION (A) | PRISMA (F) | Resolución | Int A/F |
|---|---|---|---|---|---|
| 1 | 2/2 | **Cortafuegos+Escudo** | Polimórfico(=Exploit) | Cortafuegos vence Exploit | ●●●● / ●●●○ |
| 2 | 3/3 | Cortafuegos | **Pulso (Hotpatch)** | Pulso vence Cortafuegos | ●●●○ / ●●●○ |
| 3 | 4/4 | Exploit+**CUARENTENA** | Pulso (Hotpatch) | **Cuarentena anula Pulso → EMPATE** (negó, no robó) | ●●●○ / ●●●○ |
| 4 | 5/5 | **Cortafuegos** | Exploit (Hotpatch) | Cortafuegos vence Exploit | ●●●○ / ●●○○ |
| 5 | 5/5 | Cortafuegos | **Pulso (Hotpatch)** | Pulso vence Cortafuegos | ●●○○ / ●●○○ |
| 6 | 5/5 | Exploit+**CUARENTENA** | Cortafuegos (Hotpatch) | **Cuarentena → EMPATE** | ●●○○ / ●●○○ |
| 7 | 5/5 | **Cortafuegos** | Exploit (Hotpatch) | Cortafuegos vence Exploit | ●●○○ / ●○○○ |
| 8 | 5/5 | Exploit | Pulso (Hotpatch) | **R7+ = MUERTE SÚBITA**\* — ronda decisiva: Exploit… → Pulso pierde a Exploit → **A gana** y cierra | ●●○○ / ○○○○ |

\*Desde la ronda 7, los empates dañan a ambos; aquí PRISMA ya estaba a 1 y BASTION fuerza la decisiva.
- **Momento clave:** **CUARENTENA ahora solo empata** (R3, R6): niega el punto a F pero no lo regala a A → **alarga la partida** hasta zona de **muerte súbita**, generando un final tensísimo.
- **Qué probó:** Cuarentena→empate funciona como **negación pura**; la muerte súbita **evita partidas eternas**. ⚠️ Partida de **8 rondas** → roza el límite de 8 min; vigilar (§6).

---

# 3. PARTIDAS RÁPIDAS (P09–P52)

> Una línea por partida: `ganador(mazo) def perdedor(mazo) 4-x — motivo`. Integridad 4.

**A (Control) ↔ B/C/D/E/F**
- **P09** A def B 4-2 — Cortafuegos castiga a B sin Hotpatch en mano; SIGKILL apaga Fork-Bomb.
- **P10** B def A 4-3 — B morphea a Pulso 3 veces y lee bien; Cuarentena ya no salva a A.
- **P11** B def A 4-2 — Zero-Day gana espejos de Exploit (Ciclos 9); aggro con buen tempo.
- **P12** A def C 4-3 — Hotfix niega robos clave; espejos a favor de WARDEN.
- **P13** C def A 4-2 — Broadcast snowball de RAM + Pulso-Echo; control sin presión.
- **P14** A def C 4-3 — SIGKILL + Muro-Baluarte ignoran el tempo; cierre por Ciclos.
- **P15** A def D 4-2 — Probe + plan anti-Glitch; NULL-CORE mal timing del finisher.
- **P16** D def A 4-3 — Inversión + Glitch rompen 2 lecturas; CORRUPCIÓN cierra.
- **P17** A def D 4-3 — Cuarentena empata los Glitch peligrosos; A controla el ritmo.
- **P18** A def E 4-3 — Loopback whiffea (A varía con Hotpatch); SIGKILL gana el late.
- **P19** E def A 4-2 — Probe lee a A; castiga 2 repeticiones de Cortafuegos con Loopback.
- **P20** A def E 4-3 — Muro-Baluarte aguanta; A gana el 50/50 final.
- **P21** F def A 4-2 — PRISMA morphea al tipo ganador; A no logra leerla (réplica de G3).
- **P22** A def F 4-3 — A mete Loopback en el momento justo y castiga un Polimórfico repetido.
- **P23** F def A 4-3 — Hotpatch + Null-Shard dan consistencia total; A se queda sin reads.

**B (Aggro) ↔ C/D/E/F**
- **P24** C def B 4-2 — Tempo + Loopback castiga el Exploit forzado de B.
- **P25** B def C 4-3 — B diversifica con Polimórfico; Fork-Bomb aterriza −2 clave.
- **P26** C def B 4-3 — Pulso-Echo repone cartas; B se queda sin gas.
- **P27** D def B 4-3 — Glitch caotiza 2 matchups; CORRUPCIÓN finisher.
- **P28** B def D 4-2 — Overclock gana espejos; el caos de D le sale en contra.
- **P29** B def D 4-3 — Zero-Day + tempo; Inversión de D mal calculada.
- **P30** E def B 4-2 — Loopback fulmina a B sin Hotpatch (réplica de G5).
- **P31** B def E 4-3 — B morphea y gana los 50/50; predicción a ciegas.
- **P32** E def B 4-3 — Probe + Loopback; B repite bajo presión de Sobrecarga.
- **P33** F def B 4-2 — Consistencia total de PRISMA supera al tempo agresivo.
- **P34** B def F 4-3 — Fork-Bomb + Zero-Day burst; F sin respuesta de daño.
- **P35** F def B 4-3 — Hotpatch neutraliza cada lectura de B; cierre tranquilo.

**C (Tempo) ↔ D/E/F**
- **P36** D def C 4-3 — Glitch + CORRUPCIÓN; C pierde la carrera de ritmo.
- **P37** C def D 4-2 — Recovery + Loopback estabilizan contra el caos.
- **P38** D def C 4-3 — Inversión en momento clave; finisher NULL-CORE.
- **P39** C def E 4-3 — RELE varía tipos; Loopback de E whiffea (réplica de Ciclo 1 G2).
- **P40** E def C 4-2 — Probe + Loopback castigan una repetición de Broadcast.
- **P41** C def E 4-3 — Broadcast RAM + espejos por Ciclos a favor de C.
- **P42** F def C 4-3 — Morph supera al tempo; C no puede predecir a PRISMA.
- **P43** C def F 4-2 — C mete Cuarentena/Loopback y rompe el ritmo de morph de F.
- **P44** F def C 4-3 — Consistencia + Overclock en espejos; F arriba.

**D (Caos) ↔ E/F · E ↔ F**
- **P45** E def D 4-3 — Probe anticipa Glitch; Loopback castiga un Polimórfico repetido.
- **P46** D def E 4-3 — Glitch arruina 2 lecturas de E; CORRUPCIÓN cierra.
- **P47** E def D 4-2 — Predicción supera al caos cuando Glitch sale 50/50 en contra.
- **P48** F def D 4-3 — Consistencia gana la varianza; Hotpatch > Glitch.
- **P49** D def F 4-3 — Glitch ignora la consistencia (aleatoriza el tipo de F); caos puro.
- **P50** F def D 4-2 — Hotpatch + Escudo bloquean el Glitch; F arriba.
- **P51** F def E 4-3 — Morph neutraliza Loopback; consistencia vence predicción (réplica de G3).
- **P52** E def F 4-3 — E mete Loopback justo cuando F repite tipo; lectura paga.

---

# 4. RESULTADOS AGREGADOS (n = 52) y COMPARACIÓN vs CICLO 1

### Win-rate por mazo
| Mazo (arquetipo) | Victorias | Partidas | Win-rate **v0.2** | Win-rate v0.1 | Δ |
|---|---|---|---|---|---|
| **F — PRISMA (Consistencia)** | 10 | 16 | **63%** | — (nuevo) | nuevo |
| **A — MURO (Control)** | 10 | 19 | **53%** | 80% | **−27** ✅ |
| **C — SEÑAL (Tempo)** | 10 | 19 | **53%** | 70% | −17 ✅ |
| **E — LECTOR (Predicción)** | 8 | 17 | **47%** | 40% | +7 |
| **D — RUIDO (Caos)** | 7 | 16 | **44%** | 33% | **+11** ✅ |
| **B — ENJAMBRE (Aggro)** | 7 | 17 | **41%** | 27% | **+14** ✅ |

### Lectura
- **Rango de win-rates:** v0.1 = **27%–80% (53 pts)** → v0.2 = **41%–63% (22 pts)**. **Mucho más sano.**
- **Control bajó de 80% a 53%** (CUARENTENA→empate funcionó). ✅
- **Aggro subió de 27% a 41%** y **Caos de 33% a 44%** (antídoto mono-tipo + NULL-CORE finisher). ✅
- **Nuevo problema:** **PRISMA (consistencia) 63%** — el antídoto anti-mono-tipo es **demasiado bueno** y se lleva el meta. 🚨

### Duración y sensaciones
- **Promedio ≈ 6.1 rondas** (vs ~4.0 en Ciclo 1). La curva de RAM, las cartas caras y la Sobrecarga **por fin importan**.
- **Muerte súbita (R7+) se activó** (G8) → ya hay tope a las partidas con muchos empates.
- **Remontadas reales** (G7: 0-3 → victoria). ⚠️ pero ver H-feel abajo.
- **Espejos** ya **no son empates muertos** (G6): Overclock/Throttle/Núcleo deciden.

---

# 5. HALLAZGOS DEL CICLO 2

### 🔴 CRÍTICO

**J1 · La CONSISTENCIA se pasó de fuerte (PRISMA 63%) y DILUYE la lectura.**
HOTPATCH ("transforma a cualquier tipo") + POLIMÓRFICO permiten **colocar siempre el tipo ganador**, así que Loopback/predicción casi nunca castigan y el mind-game (el alma) se debilita. Arreglamos el mono-tipo (#H2) pero **sobrecorregimos**.
→ **Cambio (Ciclo 3, combinar):**
  - **POLIMÓRFICO Ciclos 4 → 2** (pierde casi todos los espejos; es consistencia *barata pero frágil*).
  - **LOOPBACK ve el tipo FINAL** (tras Hotpatch/Polimórfico): si morpheas al tipo que repetiste, **también** te castiga. Quita la inmunidad del morph.
  - **HOTPATCH**: subir coste **2 → 3** *o* máx. **2 por mazo**. Que morphear sea una **decisión cara**, no el plan A cada ronda.
  - (Opción) nueva Subrutina **CERROJO / TYPE-LOCK** (coste 1): "si el rival transforma su Rutina esta ronda, su Rutina se anula" → contrajuego dedicado a la consistencia.

### 🟠 IMPORTANTES

**J2 · La SOBRECARGA reforzada puede sentirse como rubber-band injusto PARA EL LÍDER.**
G7: ir **3-0** y perder. La remontada es buena (justa para el que iba detrás) pero **genera amargura injusta del otro lado** (el líder siente que el juego "regaló" recursos al rival). Hay que dosificar.
→ **Cambio:** mantener **+1 RAM** al que va detrás, pero el **+robo de Subrutina solo a 3 de diferencia** (no a 2), y/o que la Sobrecarga **no apile** más de X rondas seguidas. Objetivo: remontar es **posible**, no **probable** desde 0-3.

**J3 · El AGGRO (B 41%) sigue siendo el suelo del meta.**
Mejoró mucho, pero su identidad (tipo Exploit + burst) no le da ventaja propia: ahora *todos* pueden jugar cualquier tipo (morph), así que el aggro pierde su nicho de "presión".
→ **Cambio:** dar al aggro una **recompensa de tempo independiente del tipo** (p.ej. GUSANO/ZERO-DAY que generan ventaja al ganar, o una mecánica de "cadena": 2 rondas ganadas seguidas → daño extra). Que el aggro **premie la iniciativa**, no el tipo.

### 🟡 MENORES / VIGILAR

**J4 · Duración:** algunas partidas llegan a **7-8 rondas** (G2, G6, G8) → roza el objetivo de 8 min. *Vigilar*; si se alarga, subir daño de muerte súbita o adelantarla a R6.

**J5 · CUARENTENA quizá quedó algo débil** (solo negación defensiva). No es urgente —bajar a Control era el objetivo— pero monitorear que siga jugándose.

**J6 · NULL-CORE (CORRUPCIÓN):** se siente bien, pero su poder depende de **acertar la ronda** a marcar. Buen diseño (decisión de timing). Sin cambios.

**J7 · Regla de espejo por Ciclos:** éxito. Overclock/Throttle ahora tienen peso. Sin cambios.

### Validación de los arreglos del Ciclo 1
| Hallazgo Ciclo 1 | ¿Arreglado en v0.2? |
|---|---|
| H1 partidas muy cortas | ✅ (Integridad 4 → ~6 rondas) |
| H2 mono-tipo mortal | ✅ (pero **sobrecorregido**, ver J1) |
| H3 Cuarentena regala punto | ✅ (ahora empate) |
| H4 Escudo apaga Zero-Day | ✅ (Zero-Day rediseñada) |
| H5 NULL-CORE feo/débil | ✅ (finisher CORRUPCIÓN) |
| H6 Fork-Bomb espiral | ✅ (descarta 2, no la mano) |
| H7/H8 sin remontadas | ✅ (pero ver J2: ojo con el líder) |
| H9 Ciclos decorativos | ✅ (deciden espejos) |

---

# 6. PROPUESTAS PARA EL CICLO 3 (priorizadas)

| # | Cambio | Objetivo | Riesgo |
|---|---|---|---|
| 1 | **Nerf consistencia:** Polimórfico Ciclos 4→2 · Loopback ve tipo final · Hotpatch coste 3 o máx 2/mazo | Bajar a F (~63→~52); **devolver peso a la lectura** | Reintroducir algo de fragilidad mono-tipo (aceptable) |
| 2 | **Dosificar Sobrecarga:** +robo solo a 3 de diferencia; tope de rondas consecutivas | Remontada posible sin **feel-bad del líder** | Remontadas un poco más difíciles |
| 3 | **Identidad de Aggro:** recompensa de tempo/iniciativa independiente del tipo | Subir a B (~41→~48) sin depender del tipo | Cuidar que no genere snowball |
| 4 | (Opción) Subrutina **CERROJO** anti-morph | Contrajuego dedicado a J1 | +1 carta a balancear |
| 5 | **Re-simular Ciclo 3** — idealmente ya con el **simulador automático** (PLAN §13 Fase 1) | Números estadísticos, no cualitativos | Requiere implementar el simulador |

---

# 7. VEREDICTO DEL CICLO 2 (¿ya está la idea "sentada"?)

**Todavía NO.** Pero vamos muy bien:

- ✅ El CORE es **claramente más sano** que en el Ciclo 1 (rango 22 pts vs 53 pts).
- ✅ Las **sensaciones** mejoraron: partidas con arco, remontadas, espejos vivos, finales de muerte súbita.
- ✅ La **amargura justa se conservó** (te leen, fallas tu apuesta) y la **injusta se redujo** (ya casi nadie pierde "en el reparto" o "sin poder jugar").
- ⚠️ Aparecieron **2 amarguras injustas nuevas/residuales**: la consistencia que **anula la lectura** (J1) y el **rubber-band que molesta al líder** (J2).

**Recomendación:** ejecutar el **Ciclo 3** con los cambios 1-3 (y de ser posible construir ya el **simulador automático** para medir con miles de partidas, no a mano). Mi estimación: **1 o 2 ciclos más** y el CORE quedará listo para sentarlo como definitivo. **No declararé la idea "completa" hasta que los win-rates se compriman a ~45-55% sin que ninguna mecánica genere amargura injusta dominante** — y te lo diré explícitamente cuando lo considere así.

---

*Fin del Ciclo 2. Listo para tu visto bueno o para arrancar el Ciclo 3 cuando lo indiques.*
