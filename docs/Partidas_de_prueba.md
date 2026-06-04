# NODEHACK :: PROGRAM_NULL — PARTIDAS DE PRUEBA (SIMULACIONES)
> Banco de partidas simuladas a mano para **pulir el CORE** antes de programar nada.
> Reglas y cartas: **fuente de verdad** en [`Cartas_Referencia.md`](Cartas_Referencia.md). Si algo aquí la contradice, manda ese archivo.
> 25 partidas: **5 detalladas** (G1–G5) + **20 rápidas** (P06–P25). Al final: matriz de resultados y **hallazgos accionables**.

---

## 0. Metodología (cómo simulo, y por qué es honesto)

- **Cada jugador es un Proceso** con un **mazo de muestra** (A–E) y un **Núcleo** fijos (ver Catálogo §E).
- **Información oculta real:** elijo la jugada de cada jugador **usando solo lo que ese jugador sabe en ese momento** (su mano, lo revelado, lo que vio con PROBE, los patrones del rival). Anoto su razonamiento. Ninguno "ve el futuro".
- **Simultaneidad:** ambos bloquean a ciegas; recién entonces revelo y resuelvo con la **pila determinista** del Catálogo §A.
- **Sin trampa de autor:** cuando un jugador "adivina", a veces acierta y a veces falla. No inclino los resultados; dejo que el triángulo + las lecturas decidan. Por eso hay barridas 3-0 y remontadas 3-2.
- **Límite honesto:** esto es **prueba cualitativa** (n=25), no balance estadístico. Sirve para detectar *qué se rompe y qué se siente mal*. Para win-rates reales hace falta un **simulador automático** (ver §8).

## 1. Cómo leer los logs

```
[RAM J1/J2]  J1: <Rutina>(Ciclos) + <Subrutinas>   |   J2: ...
→ <ganador> (<motivo>).   Integridad  J1:●●● J2:●●○
```
- **Integridad** ●=viva, ○=perdida (empieza ●●● = 3).
- **Última Rutina** se rastrea para LOOPBACK.
- **Adq.** = fase de adquisición (robo +1 Rutina, +2 Subrutinas al cierre de ronda).

---

# 2. PARTIDAS DETALLADAS

---

## ⚔️ G1 — BASTION (A · WARDEN · Control) vs VIRINIA (B · CORRUPTED · Aggro)

**Manos iniciales (ocultas entre sí):**
- BASTION: Rutinas{Cortafuegos, Pulso} · Subs{Cuarentena, Escudo, Throttle}
- VIRINIA: Rutinas{Exploit, Zero-Day} · Subs{Overclock, Fork-Bomb, Probe}

### Ronda 1 — RAM 2/2
- **Razona VIRINIA (aggro):** *"Solo tengo Rutinas tipo Exploit en mano. Si abre Cortafuegos pierdo, pero el control suele abrir defensivo y no sé qué hará. Lanzo ZERO-DAY (Ciclos 9): gano contra Pulso y empato contra Exploit; solo pierdo si saca Cortafuegos. Meto PROBE para ver su mano de cara a la R2."* → **Zero-Day + Probe**.
- **Razona BASTION (control):** *"Contra un agresivo, lo más probable es Exploit/alta velocidad. CORTAFUEGOS los vence. Y un ESCUDO me cubre de cualquier alteración. Barato y seguro."* → **Cortafuegos + Escudo**.
- **REVELACIÓN:** BASTION Cortafuegos(5)+Escudo | VIRINIA Zero-Day(9, Exploit)+Probe
- **Ejecución:** (1) Escudo protege Cortafuegos. (4) **Zero-Day pierde automáticamente porque el rival tiene ESCUDO.** Además Cortafuegos vence a Exploit de todos modos.
- **→ Gana BASTION** (doble motivo: regla de Zero-Day + triángulo). Integridad **B:●●○**. Probe: VIRINIA ve la mano de BASTION → *sabe que tiene Pulso, Cuarentena, Throttle.*
- Adq.: ambos roban. *(Último: BASTION=Cortafuegos, VIRINIA=Exploit)*

> 💡 **Lección inmediata:** la velocidad pura (Ciclos 9) **no vence al triángulo**; los Ciclos solo ordenan. Y ESCUDO apaga a ZERO-DAY por completo.

### Ronda 2 — RAM 3/3
- **VIRINIA:** *"Sigo sin Rutina que no sea Exploit. Voy perdiendo. Apuesto fuerte: EXPLOIT + FORK-BOMB. Si gano, lo bajo a 1 Integridad. Si pierde... descarto mi mano, pero ya voy perdiendo."* → **Exploit + Fork-Bomb**.
- **BASTION:** *"El agresivo redobla. Otra vez CORTAFUEGOS lo cubre; guardo Cuarentena/SIGKILL para sus turnos grandes. ESCUDO de nuevo por si trae Zero-Day."* → **Cortafuegos + Escudo**.
- **REVELACIÓN:** Cortafuegos(5)+Escudo | Exploit(5)+Fork-Bomb
- **Ejecución:** Cortafuegos vence a Exploit. **VIRINIA jugó Fork-Bomb y PERDIÓ → descarta toda su mano.**
- **→ Gana BASTION.** Integridad **B:●○○**. VIRINIA pierde su mano entera. *(Último: ambos repiten su tipo.)*
- Adq.: VIRINIA quedará 2 por debajo → **Sobrecarga +1 RAM** en R3.

### Ronda 3 — RAM 4 / 5 (Sobrecarga VIRINIA)
- **VIRINIA:** *"Mano vacía, solo robé GUSANO (Exploit) + Glitch. Estoy obligada a jugar Exploit otra vez. HOTPATCH no me sirve (no tengo otra Rutina para cambiar). Tiro GLITCH para escapar del Cortafuegos: si vuelve aleatorio, quizá me salve."* → **Gusano + Glitch**.
- **BASTION:** *"Está desesperada y encajonada en Exploit. Podría hacer Glitch para escapar. Lo cierro con CUARENTENA: si anulo su Rutina, da igual qué tipo o Glitch tenga — pierde."* → **Cortafuegos + Cuarentena**.
- **REVELACIÓN:** Cortafuegos+Cuarentena | Gusano(Exploit)+Glitch
- **Ejecución:** (2) Cuarentena **anula Gusano**. (3) Glitch intenta aleatorizar, pero VIRINIA ya no tiene Rutina → irrelevante. (5) BASTION sin rival → gana.
- **→ Gana BASTION.** Integridad **B:○○○ → FLUSH.**

### 🏁 Resultado G1: **BASTION (A) 3 – 0 VIRINIA (B)**
- **Por qué:** el mazo B salió **mono-Exploit** y nunca robó un tipo para contrar Cortafuegos. El control lo castigó sin despeinarse.
- **Hallazgos:** mono-tipo = trampa mortal (#2); ESCUDO apaga Zero-Day (#4); FORK-BOMB hundió a quien ya perdía (#6); partida de **3 rondas** → la RAM nunca pasó de 4 y las cartas caras casi no importaron (#7).

---

## ⚔️ G2 — RELE (C · RELAY · Tempo) vs ORACULO (E · RELAY · Predicción)

**Manos:** RELE Rutinas{Pulso, Broadcast} Subs{Recovery, Loopback, Escudo} · ORACULO Rutinas{Cortafuegos, Hotfix} Subs{Loopback, Probe, Hotpatch}

### R1 — RAM 2/2
- **RELE:** *"Quiero ventaja temprana y RAM. BROADCAST (Pulso): si vence, +2 RAM la próxima. ESCUDO por seguridad."* → **Broadcast + Escudo**.
- **ORACULO:** *"Sin patrón aún. HOTFIX (Cortafuegos, Ciclos 8) defensivo + PROBE para empezar a leerlo."* → **Hotfix + Probe**.
- **REVELACIÓN:** Broadcast(2,Pulso)+Escudo | Hotfix(8,Cortafuegos)+Probe → **Pulso vence a Cortafuegos.**
- **→ Gana RELE.** Int **E:●●○**. Broadcast → **RELE +2 RAM en R2.** Probe → ORACULO ve mano de RELE (sabe que tiene LOOPBACK y Pulso). *(Últ: RELE=Pulso, ORA=Cortafuegos)*

### R2 — RAM 5 (RELE, +2 Broadcast) / 3
- **ORACULO:** *"Ganó con Pulso; lo natural es repetir. Pongo EXPLOIT (vence a Pulso) y, por si repite Pulso, LOOPBACK para auto-ganar. Doble cobertura."* → **Exploit + Loopback**.
- **RELE:** *"Es mazo de predicción; castiga repetir. NO repito Pulso. Cambio a CORTAFUEGOS y aprovecho RAM con RECOVERY para cavar cartas."* → **Cortafuegos + Recovery + Overclock**.
- **REVELACIÓN:** Cortafuegos(5→9 c/Overclock)+Recovery | Exploit+Loopback
- **Ejecución:** Loopback comprueba si RELE repitió Pulso → jugó Cortafuegos → **whiff.** Cortafuegos vence a Exploit.
- **→ Gana RELE.** Int **E:●○○**. *(Últ: RELE=Cortafuegos, ORA=Exploit)*

### R3 — RAM 4 / 5 (Sobrecarga ORACULO)
- **RELE:** *"Quiero cerrar. Creo que repetirá Exploit (su tipo). Pongo CORTAFUEGOS (lo vence) + LOOPBACK (si repite Exploit, auto-gano)."* → **Cortafuegos + Loopback**.
- **ORACULO:** *"Sé que tiene Loopback (lo vi). NO puedo repetir Exploit. Y necesito ganar. Pongo CORTAFUEGOS para empatar el tipo y forzar desempate de Núcleo... no, empate no me sirve. Pongo PULSO (vence a Cortafuegos, que es lo que suele abrir)."* → **Pulso + Hotpatch(seguro)**.
- **REVELACIÓN:** RELE Cortafuegos | ORACULO Pulso → **Pulso vence a Cortafuegos.** Loopback de RELE: ORA no repitió Exploit → whiff.
- **→ Gana ORACULO.** Int **RELE:●●○**. ¡ORACULO respira! *(Últ: RELE=Cortafuegos, ORA=Pulso)*

### R4 — RAM 5/5
- **ORACULO:** *"Su patrón fue P→C→C; quizá vuelve a Cortafuegos o sube a Exploit. Pongo EXPLOIT (vence Pulso) + LOOPBACK (si repite Cortafuegos no aplica... ) "* — duda y cubre el caso Pulso: → **Exploit + Loopback**.
- **RELE:** *"Acaba de ganar con Pulso; esperará que yo cambie. Y él suele defender con Cortafuegos/Exploit. Pongo CORTAFUEGOS (vence Exploit) + THROTTLE."* → **Cortafuegos + Throttle**.
- **REVELACIÓN:** Cortafuegos | Exploit+Loopback. Loopback: RELE repitió Cortafuegos (R3→R4)... **¡sí repitió!** → **ORACULO auto-gana la ronda por Loopback.**
- **→ Gana ORACULO.** Int **RELE:●○○**. ¡Empate de match 2-2 en rondas! *(Últ: RELE=Cortafuegos, ORA=Exploit)*

> 💡 RELE cometió el error que castiga el meta: **repitió** Cortafuegos y comió Loopback.

### R5 — RAM 5/5 (decisiva)
- **RELE:** *"No puedo repetir Cortafuegos. Él viene jugando Exploit; lo vence Cortafuegos, pero no quiero repetir... arriesgo PULSO (pierde a Exploit) — mala idea. Mejor EXPLOIT-no, tengo solo Cortafuegos/Pulso en mano. Pongo PULSO + ESCUDO y rezo que él juegue Cortafuegos."*  → **Pulso + Escudo**.
- **ORACULO:** *"Cerró con Cortafuegos dos veces; lo evitará. Probable Pulso. Pongo EXPLOIT (vence Pulso) + OVERCLOCK."* → **Exploit + Overclock**.
- **REVELACIÓN:** Pulso(Escudo) | Exploit(9). **Exploit vence a Pulso.**
- **→ Gana ORACULO.** Int **RELE:○○○ → FLUSH.**

### 🏁 Resultado G2: **ORACULO (E) 3 – 2 RELE (C)** — remontada 0-2 → 3-2
- **Por qué:** RELE dominó leyendo, pero **repitió Cortafuegos** y Loopback le dio vuelta al juego; en la R5 ORACULO ganó el volado de tipos.
- **Hallazgos:** Loopback **whiffeó 2 veces** y **decidió 1**: arma situacional (#5). La lectura es real pero **falla** → ahí vive la "suerte sana". Remontada posible = sensación justa (#7/#8). Broadcast dio RAM pero el **tope 5** lo limitó.

---

## ⚔️ G3 — RELE (C · Tempo) vs VIRINIA (B · Aggro) — *remontada desde 0-2*

| Ronda | RAM | RELE (C) | VIRINIA (B) | Resolución | Int RELE / VIRINIA |
|---|---|---|---|---|---|
| R1 | 2/2 | Pulso + Escudo | **Exploit + Overclock** | Exploit vence Pulso | ●●○ / ●●● |
| R2 | 3/3 | Cortafuegos + Recovery | **Pulso + Probe** (splash) | Pulso vence Cortafuegos | ●○○ / ●●● |
| R3 | 5*/3 | **Exploit + Loopback + Escudo** | Pulso + Overclock (repite) | **Loopback: VIRINIA repitió Pulso → RELE gana** | ●○○ / ●●○ |
| R4 | 5/5 | **Cortafuegos + Escudo** | Exploit + Fork-Bomb | Cortafuegos vence Exploit; **Fork-Bomb pierde → VIRINIA descarta mano** | ●○○ / ●○○ |
| R5 | 5/5 | **Cortafuegos + Loopback** | Gusano(Exploit) + Throttle | **Loopback: repitió Exploit → RELE gana** (y Cortafuegos vencía igual) | ●○○ / ○○○ |

\*R3: RELE a 1, 2 por debajo → Sobrecarga +1 RAM.

### 🏁 Resultado G3: **RELE (C) 3 – 2 VIRINIA (B)**
- **Por qué:** VIRINIA arrancó 2-0 metiendo **PULSO de splash** (la cura al mono-tipo). Pero **repitió** y comió Loopback; luego **FORK-BOMB falló y le vació la mano**, dejándola sin splash y obligada a Exploit → Loopback otra vez.
- **Hallazgos:** el **splash de tipos salva al aggro** (#2). **Fork-Bomb acelera tu propia derrota** cuando fallas (#6). Loopback brilla **cuando obligas a repetir**.

---

## ⚔️ G4 — KAOS-7 (D · NULL-CORE · Caos) vs BASTION (A · Control) — *el riesgo de NULL-CORE*

| Ronda | RAM | KAOS-7 (D) | BASTION (A) | Resolución | Int KAOS / BASTION |
|---|---|---|---|---|---|
| R1 | 2/2 | **Null-Shard(=Pulso, 6) + Probe** | Cortafuegos + Escudo | Pulso vence Cortafuegos | ●●● / ●●○ |
| R2 | 3/3 | Cortafuegos + (—) | **Cortafuegos + Cuarentena** | Cuarentena **anula** Cortafuegos de KAOS → BASTION gana | ●●○ / ●●○ |
| R3 | 4/4 | Exploit + Probe · **ACTIVA NÚCLEO NULL-CORE** (apuesta a empate) | **Cortafuegos + Throttle** | Cortafuegos vence Exploit → **KAOS pierde la ronda con NULL-CORE activo → −2** | ○○○ / ●●○ |

### 🏁 Resultado G4: **BASTION (A) gana** (rondas 2-1; KAOS eliminado por **−2** de su propio Núcleo)
- **Por qué:** KAOS apostó NULL-CORE esperando un espejo/empate; BASTION jugó para **ganar el tipo**, no para empatar, y el castigo −2 cerró el match de golpe.
- **Hallazgos:** **CUARENTENA = punto casi gratis** (anula→ganas), demasiado fuerte/poca contrajugada (#3). **NULL-CORE se siente feo**: su lado bueno (empate→win) casi nunca aparece (los empates son raros) y el −2 castiga durísimo (#9). El **Null-Shard como Pulso** ganó limpio la R1 → su valor real es **consistencia de tipo** (#10).

---

## ⚔️ G5 — VIRINIA (B · Aggro) vs ORACULO (E · Predicción) — *predicción NO es contador duro del aggro*

| Ronda | RAM | VIRINIA (B) | ORACULO (E) | Resolución | Int VIRINIA / ORACULO |
|---|---|---|---|---|---|
| R1 | 2/2 | **Exploit + Overclock** | Pulso + Probe | Exploit vence Pulso | ●●● / ●●○ |
| R2 | 3/3 | Exploit + Escudo (repite) | **Cortafuegos + Loopback** | **Loopback: repitió Exploit → ORACULO gana** | ●●○ / ●●○ |
| R3 | 4/4 | **Pulso + Overclock** (cambia) | Cortafuegos + Loopback | Pulso vence Cortafuegos; Loopback whiff | ●●○ / ●○○ |
| R4 | 5/5 | Exploit + Fork-Bomb | Exploit + Loopback | **Empate de tipo** (Exploit=Exploit); Fork-Bomb sin efecto (empate≠derrota) | ●●○ / ●○○ |
| R5 | 5/5 | **Pulso + Overclock** | Cortafuegos + Loopback | Pulso vence Cortafuegos; Loopback whiff | ●●○ / ○○○ |

### 🏁 Resultado G5: **VIRINIA (B) 3 – 2 ORACULO (E)**
- **Por qué:** ORACULO logró **1 castigo** con Loopback (R2), pero en cuanto VIRINIA metió **Pulso** dejó de repetir; ORACULO (sesgado a Cortafuegos) **perdió el volado de tipos** dos veces.
- **Hallazgos:** Loopback es **inútil contra quien no repite**; la predicción **igual debe ganar el 50/50 de tipos** (#5). Aquí B ganó porque **diversificó** (#2). El **empate dejó FORK-BOMB en nada** → aclarar interacción (#11).

---

# 3. PARTIDAS RÁPIDAS (P06–P25)

> Formato compacto. `●` Integridad restante del ganador al cierre. Solo se anotan rondas y motivos clave.

### P06 · BASTION(A) vs RELE(C) → **RELE 3–2**
Tempo aguanta con Pulso-Echo (roba al perder) y Broadcast; control se queda sin Cuarentenas en mano clave. Cierra con Pulso vs Cortafuegos.

### P07 · BASTION(A) vs RELE(C) → **BASTION 3–1**
Doble Cuarentena + SIGKILL apaga el tempo; Pulso-Echo no alcanza. Control gana el grindeo.

### P08 · BASTION(A) vs KAOS-7(D) → **BASTION 3–1**
Glitch sale 50/50 y falla 2 veces; Cuarentena cierra rondas. NULL-CORE ni se activa.

### P09 · BASTION(A) vs KAOS-7(D) → **KAOS 3–2**
Glitch le da la vuelta a 2 matchups perdidos; Inversión de Polaridad pilla a BASTION con Cortafuegos. Caos paga.

### P10 · BASTION(A) vs ORACULO(E) → **BASTION 3–2**
Loopback castiga 1 repetición de BASTION, pero Escudo+Cuarentena estabilizan; Hotfix cierra negando robo.

### P11 · BASTION(A) vs VIRINIA(B) → **BASTION 3–0**
VIRINIA otra vez mono-Exploit; Cortafuegos la barre. (Repite patrón de G1.)

### P12 · RELE(C) vs ORACULO(E) → **RELE 3–2**
Espejo RELAY. RELE varía tipos cada ronda; ORACULO whiffea Loopback. Broadcast da tempo.

### P13 · RELE(C) vs ORACULO(E) → **ORACULO 3–2**
ORACULO Probe + lee bien 2 rondas; RELE repite Pulso una vez → Loopback. Revancha del espejo.

### P14 · RELE(C) vs VIRINIA(B) → **RELE 3–1**
VIRINIA splash insuficiente; Loopback + Pulso tempo dominan.

### P15 · RELE(C) vs KAOS-7(D) → **RELE 3–2**
Tempo le gana la carrera al caos; Glitch acierta 1 vez. Cuarentena (1 copia en C) cierra.

### P16 · RELE(C) vs KAOS-7(D) → **KAOS 3–2**
Doble Glitch + Hotpatch rompen el plan de RELE; Null-Shard como Cortafuegos sella.

### P17 · ORACULO(E) vs VIRINIA(B) → **ORACULO 3–1**
VIRINIA mono-Exploit forzada a repetir → Loopback la fusila 2 veces. **Aquí predicción SÍ aplasta.**

### P18 · ORACULO(E) vs VIRINIA(B) → **VIRINIA 3–2**
VIRINIA roba Pulso y Cortafuegos de splash; deja de repetir; gana el 50/50.

### P19 · ORACULO(E) vs KAOS-7(D) → **ORACULO 3–1**
Probe revela el caos; ORACULO planea alrededor de Glitch. NULL-CORE −2 vuelve a costarle a D.

### P20 · KAOS-7(D) vs VIRINIA(B) → **KAOS 3–2**
Choque de alta varianza; Inversión + Glitch deciden. Fork-Bomb de B falla 1 vez.

### P21 · KAOS-7(D) vs VIRINIA(B) → **VIRINIA 3–1**
B con buen splash + Overclock; el caos de D le sale en contra (Glitch auto-perjudica).

### P22 · BASTION(A) vs VIRINIA(B) → **BASTION 3–1**
Cuarentena + Escudo; B aguanta 1 ronda con splash pero cae.

### P23 · RELE(C) vs VIRINIA(B) → **RELE 3–0**
VIRINIA mano mono-Exploit; barrida.

### P24 · ORACULO(E) vs BASTION(A) → **BASTION 3–2**
Loopback castiga 1 vez; Cuarentena/SIGKILL de A revierten. Control aguanta.

### P25 · KAOS-7(D) vs ORACULO(E) → **ORACULO 3–2**
Probe + plan anti-Glitch; NULL-CORE −2 castiga a D en la decisiva.

---

# 4. RESULTADOS AGREGADOS (n = 25)

### Récord por mazo
| Mazo (arquetipo · Núcleo) | Victorias | Derrotas | Win-rate |
|---|---|---|---|
| **A — MURO (Control · WARDEN)** | 8 | 2 | **80%** |
| **C — SEÑAL (Tempo · RELAY)** | 7 | 3 | **70%** |
| **E — LECTOR (Predicción · RELAY)** | 4 | 6 | **40%** |
| **D — RUIDO (Caos · NULL-CORE)** | 3 | 6 | **33%** |
| **B — ENJAMBRE (Aggro · CORRUPTED)** | 3 | 8 | **27%** |

### Matriz (filas = jugador, ganador de cada cruce)
| | vs A | vs B | vs C | vs D | vs E |
|---|---|---|---|---|---|
| **A** | — | A,A,A | A,**C** | A,**D** | A,A |
| **B** | — | — | **C**,**C** | **D**,B | B,**E** |
| **C** | C,**A** | C,C | — | C,**D** | C,**E** |
| **D** | **A**,D | D,**B** | **C**,D | — | **E**,**E** |
| **E** | **A**,**A** | E,**B** | **C**,E | E,E | — |

*(negritas = quién ganó ese cruce concreto; cada celda lista las partidas jugadas.)*

### Duración de partidas
- **Moda: 3–4 rondas.** Promedio ≈ 4.0. Solo 4/25 llegaron a 5 rondas. **0 llegaron a muerte súbita (R7).**
- **RAM:** rara vez se usó por encima de 4. Las cartas de coste 3 (Cuarentena, SIGKILL, Fork-Bomb) **definieron** cuando aparecieron, pero muchas partidas terminaron antes de que ambos tuvieran RAM alta.

---

# 5. HALLAZGOS (lo que aprendí, y qué cambiar)

> Orden por severidad. Cada uno: **qué pasó → qué cambiar → dónde actualizar.**

### 🔴 CRÍTICOS

**H1 · La partida termina demasiado rápido (3-4 rondas).**
La RAM sube 2→5 pero a Integridad 3 muchas partidas acaban en R3-R4, antes de que la curva, la Sobrecarga y las cartas caras importen. El "juego profundo" casi no se llega a jugar.
→ **Cambio:** probar **Integridad 4** (sensación best-of-7) como modo principal; dejar Integridad 3 para "modo rápido". Alternativa: **RAM inicial 3** para que la profundidad aparezca antes.
→ *Actualizar* PLAN §5.2/§5.4 y Catálogo §A.4.

**H2 · El mono-tipo es una sentencia de muerte (y el sistema no lo evita).**
Los dos mazos separados garantizan *una* Rutina, **no una Rutina que contre**. B perdió 5 partidas básicamente por no robar un tipo para vencer Cortafuegos. No es estrategia ni suerte sana: es perder en el reparto.
→ **Cambio (combinar):** (a) **guía/validación de construcción** que sugiera reparto mínimo de tipos; (b) un **comodín común** (Rutina "POLIMÓRFICO" débil) o que **HOTPATCH pueda transformar tu Rutina a cualquier tipo sin necesitar otra en mano**; (c) promover **NULL-SHARD** como seguro de consistencia.
→ *Actualizar* PLAN §6.1, §8 (perillas) y §15.

**H3 · CUARENTENA es un punto casi gratis.**
Anular la Rutina rival = ganas el matchup. A coste 3 ya está online en R2 y solo la para ESCUDO. Demasiado fuerte y con poca contrajugada → infla a Control (A 80%).
→ **Cambio:** **CUARENTENA anula → EMPATE de ronda** (niega el punto, no lo regala), o sube su coste/condición. Es la palanca #1 para bajar a Control.
→ *Actualizar* Catálogo §C (S8) y PLAN §6.2.

### 🟠 IMPORTANTES

**H4 · ESCUDO es demasiado eficiente por 1 RAM.**
Bloquea Cuarentena, Throttle, Glitch **y** apaga Zero-Day por completo. Hace a Zero-Day una carta-trampa y a Control aún más sólido.
→ **Cambio:** separar funciones. Que el "auto-pierde" de **ZERO-DAY** dependa de una carta dedicada y rara (no del Escudo común), o suavizarlo a **−3 Ciclos** en vez de derrota. Mantener Escudo como protección, pero quizá que **no** frene a Cuarentena (solo a mods de Ciclos).
→ *Actualizar* Catálogo §B (R6) y §C (S3).

**H5 · NULL-CORE se siente mal (y es débil).**
Su lado bueno (empate→victoria) casi nunca ocurre —los empates son raros— y el −2 castiga brutal. D quedó en 33%.
→ **Cambio:** rediseñar la pasiva a algo que aparezca seguido y no dependa de empates. P.ej. *"1×/partida: ignora el resultado del matchup y fuerza un re-roll de ambos tipos"* o *"tus comodines no pueden ser contrados por Loopback"*. Reducir el castigo a −1.
→ *Actualizar* Catálogo §D y PLAN §7.

**H6 · FORK-BOMB castiga al que ya va perdiendo (espiral feo).**
"Si pierdes, descartas tu mano" la juegan los que van detrás como Hail Mary; al fallar, se hunden solos (G1, G3).
→ **Cambio:** al perder, **descarta 2 cartas** (no la mano entera). Mantener el +upside (−2 al rival).
→ *Actualizar* Catálogo §C (S15).

**H7 · SOBRECARGA no remonta nada en partidas cortas.**
A 2 de diferencia (Int 1 vs 3), +1 RAM llega cuando el match casi acabó. No salvó a ningún perdedor.
→ **Cambio:** disparar a **1 de diferencia** y/o añadir **robar +1** al que va detrás. (Liga con H1: con Integridad 4 habría más espacio para remontar.)
→ *Actualizar* PLAN §5.4 y Catálogo §A.4.

### 🟡 MENORES / AJUSTES FINOS

**H8 · LOOPBACK es feast-or-famine.** Aplasta a quien repite (P17, G3) e inútil contra quien varía (G2, G5). Es **sano** (se autorregula: la gente deja de repetir), pero su efecto "auto-ganar ronda" por 1 RAM es muy swingy. *Vigilar*; posible: que solo dispare con la **misma carta exacta**, no el mismo tipo.

**H9 · Los Ciclos casi no importan.** No cambian el triángulo; OVERCLOCK/THROTTLE se sintieron flojos salvo como habilitadores (Zero-Day, desempates, Muro-Baluarte). *Decisión:* mantenerlos baratos como **habilitadores**, pero la UI debe dejar clarísimo que **Ciclos ≠ ganar el tipo** (varios "errores" de los bots vinieron de sobrevalorar Ciclos altos). Considerar darle al ganador de Ciclos un mini-beneficio (resolver su trigger primero) para que la estadística no sea decorativa.

**H10 · Empates son raros** → muerte súbita (R7) nunca se activó y la sinergia de empate de NULL-CORE casi no aplica. Confirma H1 (partidas decisivas y cortas) y H5.

### Aclaraciones de reglas descubiertas al simular (ya volcadas al Catálogo con 🔧)
- **C1 — ANALYZER PROBE:** muestra la **mano** del rival, **no** la carta que eligió esta ronda; **no** permite cambiar tu jugada ya bloqueada. Su valor es predecir rondas futuras (por eso en partidas cortas vale poco — liga con H1).
- **C2 — NULL-SHARD "elige al revelarse":** bajo revelación simultánea es **idéntico** a elegir el tipo al programar. Reescribir su texto: es un **comodín de consistencia** (cuenta como el tipo que declares, oculto). Esto lo vuelve la respuesta natural a H2.
- **C3 — Velocidad vs triángulo:** Ciclos solo ordenan/empatan; **nunca** invierten quién gana el tipo. (Causó "errores" realistas de los bots agresivos.)
- **C4 — GLITCH sobre Rutina anulada:** no hace nada para ese jugador; el rival sin Rutina pierde igual.
- **C5 — FORK-BOMB en empate:** un empate **no** es derrota → no descarta y no inflige. (Decidir si se desea o si debería "fallar" también en empate.)

---

# 6. CAMBIOS PROPUESTOS (priorizados para la próxima iteración del balance)

| Prioridad | Cambio | Efecto esperado | Riesgo |
|---|---|---|---|
| 1 | **Integridad 3 → 4** (modo principal) | Partidas 5-7 rondas; la curva de RAM, Sobrecarga y cartas caras por fin importan | Partidas un poco más largas (vigilar tope 8 min) |
| 2 | **CUARENTENA: anula → empate** | Baja el dominio de Control (A) | Puede debilitar de más a Control; medir |
| 3 | **Seguro anti-mono-tipo** (comodín común + Hotpatch que transforma) | Sube Aggro (B); elimina pérdidas "en el reparto" | Menos castigo a la mala construcción |
| 4 | **Rediseñar NULL-CORE** (pasiva sin depender de empates; castigo −1) | Sube Caos (D); Núcleo deja de sentirse trampa | — |
| 5 | **ZERO-DAY**: Escudo le da −3 Ciclos (no derrota) | Zero-Day deja de ser carta muerta | — |
| 6 | **FORK-BOMB**: al perder descarta 2 (no la mano) | Menos espirales feos | Carta algo más segura |
| 7 | **SOBRECARGA** a 1 de diferencia + robar 1 | Remontadas reales | Vigilar que no premie ir perdiendo |

---

# 7. ¿FUE DIVERTIDO / JUSTO / SUERTE / ESTRATEGIA? (veredicto del CORE)

- **Estrategia ✅ (con asterisco):** construcción, gestión de RAM y lectura **sí** deciden. PERO ahora mismo **demasiado peso en 2-3 cartas** (Cuarentena, Escudo) y en la **diversidad de tipos del mazo**. Tras H2/H3/H4 quedará más sano.
- **Suerte ✅ sana en su origen** (robo + lectura simultánea oculta), **pero** el robo puede regalar/negar la partida vía mono-tipo (H2). Hay que mover la suerte del "¿robé un tipo que contre?" al "¿leí bien al rival?".
- **Justicia ⚠️:** el sistema es transparente y determinista, **pero** Control 80% vs Aggro 27% es un desequilibrio claro y las partidas cortas dan poco margen de remontada (H1/H3/H7).
- **Diversión ✅ potencial alto:** las rondas de lectura (G2, G5) y las remontadas (G3) se sienten geniales; los barridos por mono-tipo (G1, P11, P23) **no**. Arreglar H1+H2 es lo que separa "prototipo prometedor" de "core pulido".

**Conclusión:** el CORE **funciona y es prometedor**, pero NO está pulido hasta aplicar al menos los cambios de prioridad 1-3 y re-simular.

---

# 8. RECOMENDACIÓN: SIMULADOR AUTOMÁTICO (entregable de Fase 1)

Estas 25 partidas a mano ya revelaron lo grueso, pero **no** dan números de balance fiables. Antes de la UI conviene construir, en Dart puro (el mismo motor determinista del PLAN §10), un **simulador headless**:

- Implementa la pila de resolución (Catálogo §A) como **función pura**.
- Bots con políticas simples (aleatorio, contra-frecuencia, minimax a 1 ronda).
- Corre **10.000+ partidas por cruce de mazos** y reporta win-rates, duración media, % de remontadas, frecuencia de uso/efectividad por carta.
- Permite **iterar números** (Integridad, RAM, costes) en segundos, no a mano.

> Esto convierte el balance en un proceso medible y hace que, cuando llegue el diseño visual, el CORE ya esté **estadísticamente pulido**. Lo agrego como tarea explícita de **Fase 1** en el roadmap.

---

*Fin de las simulaciones v0.1. Próximo paso sugerido: aplicar cambios de prioridad 1-3, re-simular (idealmente ya automatizado), y recién entonces cerrar números para crear el proyecto.*
