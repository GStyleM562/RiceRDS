# Desplegar en Render (plan GRATIS)

Render construye y corre nuestra imagen Docker. Gratis, sin tarjeta. El plan
free **se duerme tras ~15 min sin uso** y el siguiente acceso tarda ~30–60 s en
despertar (aceptable para un juego por turnos). Migrar luego a Cloud Run / Fly /
Railway es trivial: usan el mismo `Dockerfile`.

## Requisitos
1. El código en un repo de **GitHub** (o GitLab/Bitbucket). Ya dejé el repo
   inicializado y con un commit; sólo falta crear el repo remoto y hacer push.
2. Una cuenta en **render.com** (puedes entrar con tu GitHub — sin tarjeta).

## Paso 1 — Subir el código a GitHub
Crea un repo vacío en GitHub (p. ej. `nodehack`), y desde la raíz del proyecto:

```powershell
git remote add origin https://github.com/TU_USUARIO/nodehack.git
git push -u origin main
```

## Paso 2 — Crear el servicio en Render (con el Blueprint)
1. En Render: **New → Blueprint**.
2. Conecta tu cuenta de GitHub y elige el repo `nodehack`.
3. Render detecta `render.yaml` (en la raíz) y propone el servicio
   **nodehack-server** (Docker, plan Free). Pulsa **Apply**.
4. Espera el build (construye la imagen Dart). Al terminar, te da una URL como:
   `https://nodehack-server.onrender.com`

> Si prefieres sin Blueprint: **New → Web Service** → repo `nodehack` →
> Runtime **Docker**, Dockerfile Path `./nodehack_server/Dockerfile`, Docker
> Context `.`, Plan **Free**, Health Check Path `/`.

## Paso 3 — Probar
- Abre `https://nodehack-server.onrender.com/` en el navegador → debe decir
  `NODEHACK :: PROGRAM_NULL server OK`.
- En el app, campo **SERVIDOR**, pon la URL WebSocket (con `wss` y `/ws`):
  ```
  wss://nodehack-server.onrender.com/ws
  ```
- Un jugador **CREAR SALA**, comparte el código; el otro **UNIRSE**. ¡A jugar
  desde cualquier red!

## Notas
- Render inyecta la variable `PORT`; el servidor ya la lee (no hay que tocar nada).
- TLS (`https`/`wss`) lo da Render automáticamente.
- Cada `git push` a `main` redepliega (autoDeploy).
- Estado en memoria: si Render reinicia/duerme el servicio, las partidas en curso
  se pierden (es lo esperado en el MVP sin base de datos).
