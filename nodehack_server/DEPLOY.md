# Despliegue — NODEHACK :: PROGRAM_NULL (servidor PVP)

Servidor Dart autoritativo, WebSocket, **estado en memoria** (sin base de datos),
pensado para **Cloud Run con escala-a-cero** (≈ $0 con poco tráfico).

> MVP: `--max-instances=1` para que el estado en memoria viva en una sola
> instancia (todas las conexiones caen ahí). Suficiente para miles de partidas
> por turnos. Escalar horizontal (Redis + `max-instances>1`) es la Fase 3.

## 1) Probar en LOCAL (sin Docker)

```powershell
# Terminal del servidor (escucha en :8080)
cd nodehack_server
dart pub get
dart run bin/server.dart

# Health check (en otra terminal)
curl http://localhost:8080      # → "NODEHACK :: PROGRAM_NULL server OK"
```

Apunta el app a `ws://localhost:8080/ws` (config de servidor en `app_state`).
Para probar 1v1: dos emuladores/teléfonos, uno **crea sala** y comparte el código,
el otro **se une**.

## 2) Tests

```powershell
cd nodehack_server
dart test         # unidad (OnlineMatch, Hub) + integración 2 clientes WebSocket
```

## 3) Build de la imagen (desde la RAÍZ del repo)

El servidor depende del paquete `packages/nodehack_engine` vía `path:`, así que el
**contexto de build es la raíz del repo**:

```powershell
docker build -f nodehack_server/Dockerfile -t nodehack-server .
docker run -p 8080:8080 nodehack-server   # prueba local del contenedor
```

## 4) Desplegar a Google Cloud Run (escala-a-cero, free tier)

Requiere: cuenta de Google Cloud + `gcloud` CLID logueado + un proyecto.

```powershell
# Variables (ajusta REGION cerca de tus jugadores: us-south1 o southamerica-east1)
$PROJECT = "tu-proyecto"
$REGION  = "us-south1"

gcloud config set project $PROJECT

# Opción A — deploy directo desde el código (Cloud Build construye la imagen).
#   Debe ejecutarse desde la RAÍZ del repo.
gcloud run deploy nodehack-server `
  --source . `
  --region $REGION `
  --allow-unauthenticated `
  --min-instances=0 `
  --max-instances=1 `
  --port=8080 `
  --timeout=3600 `
  --cpu=1 --memory=256Mi
```

> `--timeout=3600` (1 h) permite WebSockets largos. Cloud Run da TLS, así que la
> URL será `https://nodehack-server-xxxx.a.run.app` y el WebSocket
> `wss://nodehack-server-xxxx.a.run.app/ws`.

Si prefieres construir la imagen tú mismo y subirla a Artifact Registry:

```powershell
docker build -f nodehack_server/Dockerfile -t $REGION-docker.pkg.dev/$PROJECT/nodehack/server:v1 .
docker push $REGION-docker.pkg.dev/$PROJECT/nodehack/server:v1
gcloud run deploy nodehack-server --image $REGION-docker.pkg.dev/$PROJECT/nodehack/server:v1 `
  --region $REGION --allow-unauthenticated --min-instances=0 --max-instances=1 --port=8080 --timeout=3600
```

## 5) Conectar el app

Tras el deploy, copia la URL `wss://…/ws` y ponla en la configuración del servidor
del app (pantalla **JUGAR ONLINE → servidor**, o el valor por defecto en
`app_state`). Vuelve a probar el e2e desde 2 teléfonos reales y mide la latencia
por ronda.

## Costo / notas
- **Escala-a-cero:** sin tráfico, 0 instancias → ≈ $0. Primer mensaje tras inactividad
  paga un arranque en frío ~1–2 s. Si molesta, `--min-instances=1` (unos pocos $/mes).
- **Sin DB:** las salas son efímeras (memoria). Al reiniciarse la instancia se pierden
  las partidas en curso (reconexión por token sólo dentro de la misma instancia/vida).
- **Alternativas equivalentes:** Fly.io / Railway (también escala-a-cero y WebSocket).
