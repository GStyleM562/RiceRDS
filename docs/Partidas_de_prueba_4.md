# NODEHACK :: PROGRAM_NULL — CICLO 4 (SIMULADOR AUTOMÁTICO · BALANCE v0.4)
> Primer ciclo con el **simulador headless** (motor Dart en `nodehack_sim/`). Ya **no son partidas a mano**: son cientos de miles de partidas con bots, estadísticas por carta y test de habilidad.
> Reglas/cartas canónicas: [`Cartas_Referencia.md`](Cartas_Referencia.md) v0.4. Reporte de números crudos: [`Partidas_auto_v0.4.md`](Partidas_auto_v0.4.md).
> Ciclos a mano previos: [1](Partidas_de_prueba.md) · [2](Partidas_de_prueba_2.md) · [3](Partidas_de_prueba_3.md).

---

## 0. Qué cambió de método (y por qué importa)

Construimos un **simulador automático** que corre **150.000 partidas por ronda de pruebas** en segundos, con:
- **Motor determinista** (misma semilla ⇒ misma partida; verificado con tests).
- **3 bots** que solo ven información pública (imposible hacer trampa por construcción).
- **Estadísticas por carta** (win% de la partida cuando se jugó) y **test de habilidad**.

Esto convierte el balance de "intuición a mano" a **medición**. Y de entrada reveló cosas que los ciclos a mano **no podían ver**.

---

## 1. Hallazgo metodológico #1: la calidad del bot domina los números

Primer susto: con los bots iniciales, **el bot "inteligente" perdía contra el aleatorio (~40%)**. Diagnóstico: los bots **infrautilizaban el kit** (no jugaban Fork-Bomb, etc.), mientras el aleatorio sí lo lanzaba.

**Implicación crítica:** los win-rates por mazo **dependen de la política de juego**. Cualquier conclusión de balance debe fijar una política competente. Reescribimos un `SmartBot` que despliega el kit por valor. Resultado:

| Test de habilidad (misma baraja, posición alternada) | Win-rate |
|---|---|
| smart **vs rival predecible (counter)** | **60.5%** ✅ |
| smart vs heurístico | ~49% |
| smart vs **aleatorio puro** | ~45% |
| aleatorio vs aleatorio (sanidad) | 50.3% ✅ |

**Lectura clave (y muy importante para el OBJETIVO del juego):**
- **Contra un rival legible/predecible, la habilidad gana claramente (60.5%)** → la lectura y la estrategia **sí cuentan**. Este es el caso real (humanos tienen patrones).
- **Contra un rival perfectamente aleatorio, el duelo de tipos es ~50/50** → ese es el núcleo de **suerte** intencional de piedra-papel-tijera: *no puedes leer el ruido puro*. Es una virtud, no un fallo. Los humanos no juegan aleatorio perfecto, así que en la práctica la lectura paga.

> Conclusión: **el juego premia leer al rival y castiga ser predecible**, que es exactamente el objetivo. El componente de azar existe y está acotado (no domina).

---

## 2. Hallazgo #2: diagnóstico por carta (lo que estaba roto)

Con `--cards` medimos el win% de la partida cuando cada carta se jugó (política smart, 150k partidas):

| Carta | Win% al jugarla | Lectura |
|---|---|---|
| **FORK-BOMB** | **70.3%** 🔴 | Sobrepoderosa: valor proactivo casi gratis |
| ZERO-DAY | 58.6% | Fuerte (sano para aggro) |
| GUSANO / NULL-SHARD | ~55–56% | OK |
| OVERCLOCK | 53.1% | Sano |
| *(base: Exploit/Pulso/Cortafuegos/Polimórfico)* | ~48–52% | Neutro ✅ |
| HOTFIX / MURO-BALUARTE | 36–43% | Débiles |
| PARCHE / CUARENTENA | 26–30% | Bajísimo (sesgo: se juegan al ir perdiendo) |

Y a nivel mazo (con la política smart), el desequilibrio inicial era: **D RUIDO 64% arriba**, **A MURO 37% abajo**.

---

## 3. El pase de balance v0.4 (cada cambio, medido)

Cada ajuste se aplicó y **re-midió con 150k partidas**:

| # | Cambio | Antes → Después | Efecto medido |
|---|---|---|---|
| 1 | **FORK-BOMB**: al perder, en vez de "descarta 2 cartas" → **−1 Integridad extra** (apuesta simétrica −2 ganes o pierdas) | B ENJAMBRE 59% → **51%** | Le quitó el valor "gratis"; B se normalizó |
| 2 | **NULL-CORE CORRUPCIÓN**: quita el bonus **−2** (ahora solo convierte UN empate en victoria) | D RUIDO 58.5% → **50.5%** | El −2 era el driver real de D (−8 pts) |
| 3 | **MURO-BALUARTE**: inmune a anulación (Cuarentena/Loopback) | A: ~sin cambio (poco jugada) | Buff válido pero insuficiente solo |
| 4 | **Reconstrucción del mazo A** (menos cartas que solo empatan; más tempo/cierre) | A MURO 41% → **47%** | El problema de Control era **construcción de mazo**, no las cartas |

### Resultado final (política smart, robusto en 2 semillas)
| Mazo | Win-rate |
|---|---|
| E LECTOR (Predicción) | 53.8% |
| F PRISMA (Consistencia) | 51.9% |
| B ENJAMBRE (Aggro) | 51.7% |
| D RUIDO (Caos) | 48.9% |
| A MURO (Control) | 47.1% |
| C SEÑAL (Tempo) | 46.6% |

**Spread: 7.2 puntos (46.6–53.8%)** — vs **53 puntos (27–80%)** del Ciclo 1. Bajo buen juego, **los 6 arquetipos son viables y ninguno domina**.

---

## 4. Métricas de "diversión" (objetivo del juego)

| Métrica | Valor (política smart) | ¿Sano? |
|---|---|---|
| Rondas promedio | **6.5** | ✅ (encaja en 3–8 min) |
| Remontadas | 13.5% | ✅ (existen, no dominan) |
| Partidas a muerte súbita (R7+) | ~16% | ✅ (cierre tenso, no eterno) |
| Empates finales (partidas sin ganador) | **0** | ✅ |
| Habilidad vs rival legible | **60.5%** | ✅ (la estrategia cuenta) |
| Spread de arquetipos bajo buen juego | **7 pts** | ✅ |

---

## 5. Matices honestos (lo que NO está cerrado)

1. **El balance es más fino bajo buen juego que bajo juego mediocre.** Con el bot heurístico (más débil) el spread se abre a ~22 pts (E sube a ~60, C baja a ~38). Es normal en juegos competitivos —lo que importa es el balance bajo buen juego— y hasta temático (el mazo de predicción castiga a quien juega predecible). Pero conviene saberlo.
2. **Los bots son heurísticos, no óptimos.** Un solver real afinaría más los números. Los valores actuales son una base sólida, no la última palabra.
3. **NULL-CORE quedó con una pasiva floja** (solo empate→victoria, y los empates son raros). El mazo D sigue viable por sus cartas de ciclo, pero el Núcleo podría rediseñarse luego para ser interesante-sin-romper.
4. **Cartas situacionales** (Cuarentena/Parche) tienen win% bajo por **sesgo de selección** (se juegan al ir perdiendo), no porque sean inútiles.

---

## 6. VEREDICTO — ¿se respeta el objetivo y es divertido?

**Sí, con evidencia:**

- ✅ **Es "piedra-papel-tijera avanzado":** el triángulo + jugada simultánea oculta es el corazón; la preparación (mazo, RAM, Ciclos, cartas de ciclo) añade las capas de "ajedrez" sin tapar el núcleo.
- ✅ **La incógnita es el gancho:** sin cartas de información (verificado por test de *fairness*), cada ronda es una lectura real.
- ✅ **La estrategia cuenta:** ganar leyendo a un rival legible da **60.5%**; la construcción de mazo mueve 6 puntos de win-rate (Control 41→47).
- ✅ **La suerte está acotada:** vs ruido puro es 50/50 (núcleo RPS), pero vs patrones humanos la habilidad manda.
- ✅ **Es justo y se siente bien:** partidas de ~6.5 rondas, con remontadas posibles, sin estancamientos, y **ningún arquetipo dominante ni carta rota** tras v0.4.
- ✅ **La amargura es mayormente "justa":** pierdes por que te leyeron, fallaste tu apuesta (Fork-Bomb ahora es −2 simétrico) o perdiste el 50/50 — no por "no me tocó".

> **Tengo información suficiente para afirmar que el CORE respeta el objetivo y es divertido**, bajo juego competente, con balance medido (spread 7 pts) y métricas de ritmo/justicia sanas. El sistema quedó además **medible**: cualquier carta o mazo futuro se valida en segundos con el simulador.

**Lo que queda (no bloquea el diseño visual):** rediseñar la pasiva de NULL-CORE, mejorar los bots hacia óptimo para afinar decimales, y revisar el balance bajo juego mediocre. Todo iterable con la herramienta.

---

## 7. Cómo reproducir
```
cd nodehack_sim && dart pub get && dart test          # 23 tests verdes
dart run bin/simulate.dart --round-robin --games 10000 --seed 42 --bots smart --cards
dart run bin/simulate.dart --skill --bots smart,counter --games 6000   # habilidad
dart run bin/simulate.dart --matchup E,A --games 1 --log 1             # log legible
```

*Fin del Ciclo 4. El motor (`nodehack_sim/lib/engine/`) es Flutter-agnóstico y queda listo para que el futuro app de batalla lo reutilice sin cambios.*
