# PVP — Guía rápida (salas con código)

NODEHACK :: PROGRAM_NULL ya soporta **1v1 contra otra persona** por salas con
código. Arquitectura: servidor Dart autoritativo (reusa el motor del juego) +
WebSocket + estado en memoria. El cliente sólo programa su jugada; **el servidor
decide el resultado** → imposible de hacer trampa.

## Estructura del repo

```
packages/nodehack_engine/   ← motor de reglas (Dart puro): lo usan app Y servidor
nodehack_app/               ← la app Flutter (CPU + online)
nodehack_server/            ← el servidor PVP (Dart, WebSocket)
```

## Jugar por internet (servidor ya desplegado)

El servidor está en Render: **`wss://nodehack-server.onrender.com/ws`** (ya es el
valor por defecto del app). Solo instala el APK, entra a **JUGAR ONLINE**, uno
**CREA SALA** y comparte el código de 4 letras; el otro **UNIRSE** y lo escribe.
Funciona desde cualquier red. *(Nota: en el plan free el servidor se duerme tras
~15 min sin uso; la primera conexión tras dormir tarda ~30–60 s en despertar.)*

## Probar PVP en LOCAL (sin desplegar)

1. **Arranca el servidor** en tu PC:
   ```powershell
   cd nodehack_server
   dart run bin/server.dart      # escucha en :8080
   ```

2. **Averigua la IP LAN de tu PC** (para que los teléfonos la alcancen):
   ```powershell
   ipconfig    # busca "Dirección IPv4", p. ej. 192.168.1.42
   ```

3. **En el app** (cada dispositivo), entra a **JUGAR ONLINE** y en el campo
   *SERVIDOR* pon:
   - Emulador Android → `ws://10.0.2.2:8080/ws` (alias del host)
   - Teléfono físico en la misma WiFi → `ws://TU_IP_LAN:8080/ws` (p. ej. `ws://192.168.1.42:8080/ws`)

4. Un jugador toca **CREAR SALA** → aparece un **código de 4 letras**. El otro
   toca **UNIRSE A SALA**, escribe el código y **CONECTAR**. Empieza el duelo.

> Las dos instancias pueden ser: 2 teléfonos, o teléfono + emulador, o incluso
> 2 emuladores. La identidad es anónima (nombre escrito + id de dispositivo).

## Desplegar el servidor (para jugar fuera de tu WiFi)

Ver `nodehack_server/DEPLOY.md` — resumen: Cloud Run, escala-a-cero (≈ $0),
`--min-instances=0 --max-instances=1`. Tras el deploy, pon la URL `wss://…/ws`
en el campo *SERVIDOR* del app.

## Tests

```powershell
cd packages/nodehack_engine ; dart test     # motor (reglas + serialización)
cd nodehack_server         ; dart test       # OnlineMatch + Hub + integración 2 WebSockets
cd nodehack_app            ; flutter test     # pantallas + controladores (local y online)
```

## Qué falta (tu parte)
- (Opcional) Desplegar a Cloud Run para jugar por internet (te dejé los comandos).
- Probar el e2e desde 2 dispositivos reales y medir la latencia por ronda.

## Roadmap (sin rehacer)
- **Fase 2:** emparejamiento aleatorio (cola en el mismo servidor).
- **Fase 3:** ranked — Redis (estado compartido, `max-instances>1`) + Postgres
  gratis (cuentas anónimo→vinculado, MMR, ligas) + repeticiones (semilla + log).
