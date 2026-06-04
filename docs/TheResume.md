# NODEHACK :: PROGRAM_NULL — THE RESUME (Glosario maestro)
> **Documento de consulta rápida.** Resume, en un solo lugar: las **reglas**, los **problemas actuales**, qué hace cada **personaje (Núcleo)** y qué hace cada **carta**.
> Estado: **balance v0.3** (post Ciclo 3 de simulaciones). Fuente de verdad detallada: [`Cartas_Referencia.md`](Cartas_Referencia.md). Diseño: [`NodeHackNull_PLAN.md`](NodeHackNull_PLAN.md). Pruebas: [`Partidas_de_prueba.md`](Partidas_de_prueba.md) · [`_2`](Partidas_de_prueba_2.md) · [`_3`](Partidas_de_prueba_3.md).

---

# 🎯 EN UNA FRASE

Es **piedra-papel-tijera con preparación**: construyes un mazo, eliges un personaje, y cada ronda programas en secreto una **Rutina** (el tipo) + **Subrutinas** (alteraciones), revelan a la vez y se resuelve. **La incógnita de la mano del rival es el gancho** — por eso está prohibido ver información.

---

# 📏 LAS REGLAS (lo esencial, v0.3)

| Regla | Detalle |
|---|---|
| **Triángulo** | **CORTAFUEGOS** 🛡️ vence a **EXPLOIT** ⚔️ vence a **PULSO** 📡 vence a **CORTAFUEGOS**. |
| **Objetivo** | Empiezas con **4 de Integridad**. Pierdes una ronda → −1. A **0 = FLUSH** (derrota). ≈ best-of-7. |
| **Mazos** | **10 Rutinas** (el tipo) + **20 Subrutinas** (alteraciones), **barajados aparte** (así siempre tienes una jugada válida). |
| **Mano** | Inicial: **2 Rutinas + 3 Subrutinas**. Al final de cada ronda robas **+1 Rutina + 2 Subrutinas**. Tope de mano: **8**. |
| **RAM (Ancho de Banda)** | Recurso por ronda para pagar Subrutinas. R1=2, R2=3, R3=4, R4+=5 (tope 5). **No se acumula.** Las **Rutinas son gratis**. |
| **Jugada** | Obligatorio **1 Rutina**. Opcional **0–2 Subrutinas** (su coste sumado ≤ RAM). |
| **Ciclos** | Cada Rutina tiene un valor de "velocidad". Mayor Ciclos resuelve primero **y decide los espejos** (mismo tipo → gana mayor Ciclos → si empata, Núcleo → si empata, empate real). |
| **Empate** | Nadie pierde Integridad. **Muerte súbita:** desde la ronda 7, un empate hace −1 a **ambos**. |
| **Sobrecarga** | Si vas **1 por debajo** → +1 RAM esa ronda. Si vas **3+ por debajo** → +1 RAM **y** robas +1 Subrutina. (Ayuda a remontar sin regalar la partida.) |
| **Información** | 🚫 **TOTALMENTE OCULTA.** Nadie ve la mano del rival. Solo conoces lo **revelado** en rondas pasadas (historial público). |

### Flujo de una ronda
`ROBO → PROGRAMACIÓN (colocas Rutina + Subs en secreto) → COMPILAR (READY) → REVELACIÓN (simultánea) → EJECUCIÓN → RESULTADO → ADQUISICIÓN (robas)`

### Orden de resolución (pila determinista)
1. **Protección/cancelación:** SIGKILL, Escudo
2. **Anulación:** Cuarentena, Loopback (→ empate)
3. **Ciclo:** Inversión, Rotación, Glitch, Fork
4. **Ciclos:** Overclock, Throttle
5. **Matchup:** se compara el triángulo
6. **Daño + disparos** (Hotfix, Gusano, Broadcast, Pulso-Echo…)
7. **Post:** Parche, Fork-Bomb, robos, Buffer
8. **Adquisición** (robo + Sobrecarga)

### 🚫 Lo PROHIBIDO (regla de diseño que protege el CORE)
1. **Ver información oculta** (mano/cartas del rival). *Por esto se baneó ANALYZER PROBE.*
2. **Override por tipo** ("solo Cortafuegos gana", "si usas Exploit pierdes").
3. **Garantizar el tipo ganador** ("transforma a cualquier tipo"). *Por esto Hotpatch se volvió ROTACIÓN (solo un paso).*
> ✅ **Sí se permite manipular el CICLO** (invertir, rotar al siguiente, aleatorizar): cambia la *relación*, no la *información*.

---

# 🔴 LOS PROBLEMAS (exactamente cuáles son, hoy)

### ✅ Resueltos en los 3 ciclos
| Problema | Estaba | Solución aplicada |
|---|---|---|
| **Control aplastaba** (80% win) | Cuarentena anulaba **y ganaba** el punto | Cuarentena ahora **solo empata** (niega, no roba) → Control bajó a ~53-60% |
| **Mono-tipo = muerte** | Si no robabas el tipo correcto, perdías sin jugar | Polimórfico + Rotación dan consistencia |
| **Consistencia se pasó de fuerte** (PRISMA 63%) | "Transforma a cualquier tipo" anulaba la lectura | → Rotación (solo un paso) + Polimórfico Ciclos 2 → bajó a ~50% |
| **Partidas muy cortas** (3-4 rondas) | Integridad 3 | **Integridad 4** → ~6 rondas, la curva importa |
| **NULL-CORE se sentía feo** | Pasiva autodestructiva (−2 a ti) | Rediseñada como **finisher CORRUPCIÓN** |
| **Fork-Bomb hundía al perdedor** | Al fallar, descartabas toda la mano | Ahora descartas **solo 2 cartas** |
| **Ciclos decorativos** | El mismo tipo siempre empataba | Mismo tipo → **gana mayor Ciclos** |
| **Espiar la mano rompía el gancho** | Existía Analyzer Probe | **Baneada**; información 100% oculta |
| **Remontada con rubber-band** | Sobrecarga molestaba al líder | **Dosificada** (robo extra solo a 3 de diferencia) |

### 🟠 ABIERTOS (lo que falta para "sentar" el juego)
1. **🥇 IDENTIDAD DEL AGGRO (el problema #1).** El arquetipo agresivo (Núcleo CORRUPTED, mazo "Enjambre") lleva **3 ciclos siendo el más débil (~40%)**. Ahora que **todos** pueden rotar el tipo, el aggro **no tiene un nicho propio**. *A mejorar:* darle una recompensa de **iniciativa/tempo independiente del tipo** (ej: "si ganas 2 rondas seguidas, roba 1 Rutina"; o reforzar Gusano/Zero-Day como motor de ventaja). Que premie **presionar**, no acertar el tipo.
2. **📊 SIN VALIDACIÓN ESTADÍSTICA.** Todo el balance sale de **~90 partidas simuladas a mano**. Es suficiente para detectar lo grueso, **no** para fijar números. *A mejorar:* construir un **simulador automático** (motor de reglas como función pura) que corra 10.000+ partidas por cruce. Sin esto, los win-rates de muestra pequeña (D 60%, C 40% en Ciclo 3) **no son concluyentes**.
3. **🟡 CAOS quizá algo fuerte** (Núcleo NULL-CORE / mazo "Ruido", ~60% en Ciclo 3). Las cartas de ciclo (Glitch + Rotación + Inversión) juntas dan mucha manipulación. *Vigilar* (puede ser ruido de muestra); posible ajuste: subir coste de Glitch o **máx. 1 carta de ciclo por ronda**.
4. **🟡 TEMPO quizá debilitado** (mazo "Señal", ~40% en Ciclo 3). Loopback más suave (solo empata) y sin Probe pudieron restarle. *Vigilar y medir.*

### 🎭 Lo bueno que ya funciona (no tocar)
- El **triángulo + jugada simultánea oculta** entrega el 50/50 de lectura (el alma del juego).
- La **RAM** evita el "vómito de cartas" y crea decisiones de tempo.
- Las **cartas de ciclo** (Rotación/Inversión) enriquecen la lectura sin revelar info.
- La **amargura justa** (te leyeron, fallaste tu apuesta) se conservó; la **injusta** (perder en el reparto, morir sin jugar) se redujo.

---

# 🧑‍🚀 LOS PERSONAJES (Núcleos)

> El "personaje" es el **Núcleo** que eliges antes de la partida. Da: (a) **prioridad de desempate** en espejos de su tipo, y (b) una **pasiva 1 vez por partida**. Define tu identidad y tu plan. **Ninguno revela información.**

### 🛡️ WARDEN — *el muro*
- **Alineación:** Cortafuegos. **Desempate:** gana los espejos de Cortafuegos.
- **Pasiva (1×):** **ignora una Subrutina del rival** esta ronda.
- **Jugabilidad:** control y defensa. Aguanta, niega (Cuarentena/SIGKILL), gana el late game. Castiga a los agresivos que se lanzan con Exploit.
- ✅ **Bueno:** sólido, fácil de entender, gana el grindeo. ❌ **Malo/Problema:** puede sentirse *reactivo*/lento; antes era **demasiado** fuerte (ya corregido). 🔧 **A mejorar:** vigilar que tras los nerfs siga siendo viable sin ser opresivo.

### ⚔️ CORRUPTED — *el agresor*
- **Alineación:** Exploit. **Desempate:** gana los espejos de Exploit.
- **Pasiva (1×):** **+5 Ciclos** a tu Rutina (gana un espejo clave o resuelve primero).
- **Jugabilidad:** presión, tempo rápido, jugadas de riesgo (Fork-Bomb, Zero-Day). Quiere cerrar rápido.
- ✅ **Bueno:** sensación agresiva, burst. ❌ **PROBLEMA PRINCIPAL (abierto):** es **el más débil (~40%)** en los 3 ciclos; perdió su nicho porque ahora todos rotan el tipo. 🔧 **A mejorar:** darle una **recompensa de iniciativa independiente del tipo** (ver Problema #1).

### 📡 RELAY — *la señal / tempo*
- **Alineación:** Pulso. **Desempate:** gana los espejos de Pulso.
- **Pasiva (1×):** **roba 1 Rutina extra** (consistencia/recursos).
- **Jugabilidad:** el más **flexible**. Genera ventaja de cartas (Recovery, Broadcast), lee patrones (Loopback) y manipula el ciclo. Aguanta y supera por recursos.
- ✅ **Bueno:** versátil, buen win-rate, varios estilos (tempo, predicción, consistencia). ❌ **Malo:** puede ser "el bueno para todo" → cuidado con que opaque a los demás. 🔧 **A mejorar:** vigilar que no sea el Núcleo por defecto.

### 🕳️ NULL-CORE — *el caos / fragmento de NULL*
- **Alineación:** ninguna → **pierde todos los espejos** (desventaja de desempate).
- **Pasiva (1×) CORRUPCIÓN:** marcas una ronda → si **ganas** infliges **−2**, si **empatas** **ganas**, si **pierdes** −1 normal. Es un **finisher** de timing.
- **Jugabilidad:** alto riesgo/alta recompensa. Mazos de caos (Glitch, Inversión, Rotación). Crea incertidumbre y cierra con CORRUPCIÓN.
- ✅ **Bueno:** identidad única, divertido, ya no se autodestruye (corregido). ❌ **Problema/Vigilar:** podría estar **algo fuerte** en v0.3 (~60%); pierde espejos pero compensa con manipulación. 🔧 **A mejorar:** confirmar con muestra grande; posible límite a cartas de ciclo por ronda.

### Arquetipos de mazo de muestra (estilos de juego)
| Mazo | Estilo | Núcleo | Win-rate aprox. (último ciclo) |
|---|---|---|---|
| **A "Muro"** | Control | WARDEN | ~60% |
| **B "Enjambre"** | Agresivo | CORRUPTED | ~40% 🔴 |
| **C "Señal"** | Tempo | RELAY | ~40-53% (vigilar) |
| **D "Ruido"** | Caos | NULL-CORE | ~60% (vigilar) |
| **E "Lector"** | Predicción | RELAY | ~50% |
| **F "Prisma"** | Consistencia | RELAY | ~50% (antes 63%, corregido) |

---

# 🃏 LAS CARTAS — qué hace cada una

## Símbolos: 🛡️ Cortafuegos · ⚔️ Exploit · 📡 Pulso · ⭐ comodín

## A) RUTINAS (el "tipo" — Mazo de Acción, gratis, 1 obligatoria por ronda)

| Carta | Tipo | Ciclos | Qué hace | Nota ⚖️ |
|---|---|---|---|---|
| **CORTAFUEGOS** | 🛡️ | 5 | Carta base. Vence a Exploit. | El pilar del control. |
| **EXPLOIT** | ⚔️ | 5 | Carta base. Vence a Pulso. | El pilar agresivo. |
| **PULSO** | 📡 | 5 | Carta base. Vence a Cortafuegos. | El pilar del tempo. |
| **HOTFIX** | 🛡️ | 8 | Si **vences** la ronda, el rival **no roba** cartas esa ronda (lo asfixia). | Cortafuegos rápido + control de recursos. |
| **MURO-BALUARTE** | 🛡️ | 3 | **Inmune a Throttle** y a subrutinas de baja prioridad. Si vences, **ignoras los efectos negativos** de la ronda. | Muy resistente pero Ciclos bajos (pierde espejos). |
| **ZERO-DAY** | ⚔️ | 9 | Gana los **espejos de Exploit** (Ciclos altos). **Coste:** −1 RAM la ronda siguiente (recalienta). | Identidad del aggro; el coste evita que sea "Exploit gratis mejorado". |
| **GUSANO** | ⚔️ | 4 | Si **vences**, **robas 1 Subrutina** del descarte del rival. | Genera ventaja de cartas para el aggro. |
| **BROADCAST** | 📡 | 2 | Si **vences**, **+2 RAM** la próxima ronda (snowball de recursos). | Ciclos bajísimos (vulnerable en espejos); paga si conecta. |
| **PULSO-ECHO** | 📡 | 5 | Si **pierdes** la ronda, **robas 1 Rutina** y conservas 1 RAM. | "Pierde con estilo": te recompensa por perder, ideal en tempo. |
| **POLIMÓRFICO** | ⭐ | **2** | Comodín: **declaras su tipo en secreto** al programar. **Ciclos 2 → pierde casi todos los espejos.** (máx. 3) | Seguro anti-mono-tipo, pero **frágil** a propósito (no debe dar consistencia gratis). |
| **NULL-SHARD** | ⭐ | 6 | Comodín de consistencia: declaras tipo en secreto. **No puede recibir Overclock/Throttle** (señal inestable). (máx. 1) | Comodín fuerte pero único y sin apoyo de Ciclos. |

## B) SUBRUTINAS (alteraciones — Mazo de Alteración, 0-2 por ronda, cuestan RAM)

### Prioridad / Ciclos
| Carta | RAM | Qué hace |
|---|---|---|
| **OVERCLOCK** | 1 | **+4 Ciclos** a tu Rutina (resuelves antes / ganas espejos). |
| **THROTTLE** | 1 | **−4 Ciclos** a la Rutina del rival (lo retrasas / le pierdes el espejo). |

### Protección / negación
| Carta | RAM | Qué hace |
|---|---|---|
| **ESCUDO DE DATOS** | 1 | **Protege tu Rutina** de anulación y alteraciones esta ronda (bloquea Cuarentena, Throttle, Glitch…). |
| **CUARENTENA** | 2 | **Anula la Rutina del rival** → la ronda es **EMPATE**. **Niega** su jugada (no te da el punto). |
| **SIGKILL** | 3 | **Anula TODAS las Subrutinas del rival** esta ronda (mata combos). |
| **LOOPBACK** | 1 | Si el rival **repite** su tipo de la ronda anterior → su Rutina se **anula** → **EMPATE**. Castiga patrones (lee el historial **público**, no la mano). |

### Manipulación del CICLO (la "magia sana")
| Carta | RAM | Qué hace |
|---|---|---|
| **INVERSIÓN DE POLARIDAD** | 2 | **Invierte el triángulo** esta ronda (quien perdía, gana). Si ambos la juegan, se cancela. |
| **ROTACIÓN DE FASE** | 2 | Mueve **una Rutina** (la tuya **o la del rival**) **un paso** en el ciclo (🛡️→⚔️→📡→🛡️). *(reemplazó al viejo "Hotpatch" que transformaba a cualquier tipo)*. |
| **GLITCH** | 2 | **Ambas Rutinas** se vuelven de **tipo aleatorio** (semilla), salvo las protegidas por Escudo. Caos puro. |

### Recursos / cartas
| Carta | RAM | Qué hace |
|---|---|---|
| **RECOVERY CYCLE** | 1 | **Robas 2 Subrutinas.** |
| **DEFRAG** | 0 | **Devuelves 1 Subrutina** del descarte a tu mano (gratis). |
| **FORK / MIRROR** | 2 | **Copias la última Subrutina** que jugó el rival. |
| **BUFFER** | 1 | Programas un efecto que se **dispara la ronda siguiente** (trampa/retardo). |

### Resultado / riesgo
| Carta | RAM | Qué hace |
|---|---|---|
| **PARCHE** | 2 | Convierte **tu derrota** de esta ronda en **EMPATE** (salvavidas). |
| **FORK-BOMB** | 3 | Si **vences**: el rival pierde **2 Integridad**. Si **pierdes**: **descartas 2 cartas**. Riesgo de doble filo. |

### 🚫 Baneada
| Carta | Estado | Por qué |
|---|---|---|
| ~~**ANALYZER PROBE**~~ | **PROHIBIDA** | Dejaba **ver la mano del rival**. Viola el gancho del juego (la incógnita). Eliminada en v0.3. |

---

# 📜 QUÉ HA PASADO (historial de los 3 ciclos, resumido)

- **Ciclo 1 (25 partidas, v0.1):** detectó que Control aplastaba (80%), el mono-tipo mataba, las partidas eran muy cortas, NULL-CORE y Fork-Bomb se sentían mal, y los Ciclos eran decorativos.
- **Ciclo 2 (52 partidas, v0.2):** aplicó Integridad 4, Cuarentena→empate, antídoto anti-mono-tipo, NULL-CORE finisher, regla de espejo por Ciclos. **Comprimió** los win-rates de 27-80% a **41-63%**. Nuevo problema: la **consistencia se pasó de fuerte** (PRISMA 63%) y un comodín de información (Probe) seguía existiendo.
- **Ciclo 3 (14 partidas, v0.3):** por tu indicación, **baneó toda revelación de información** (la incógnita es el gancho), prohibió overrides por tipo, y cambió "transforma a cualquier tipo" por **ROTACIÓN** (un paso). La consistencia bajó a ~50%. **Quedan abiertos:** identidad del aggro y validación con simulador automático.

> **Estado honesto:** el CORE ya coincide con tu visión y se siente justo. **Aún no está "sentado" al 100%** por 2 cosas: (1) el aggro necesita identidad propia, (2) faltan números estadísticos (simulador). Estimación: **1-2 ciclos más**.

---

*TheResume.md — glosario maestro. Se actualiza cuando cambien las reglas o el balance.*
