# Imagen del servidor PVP. CONSTRUIR DESDE LA RAÍZ DEL REPO (para incluir el
# paquete del motor, que es una dependencia `path`):
#
#   docker build -f nodehack_server/Dockerfile -t nodehack-server .
#
# Resultado: imagen mínima (~10–15 MB) con un ejecutable nativo autocontenido.

FROM dart:stable AS build
WORKDIR /app

# Respeta la dependencia path del servidor (../packages/nodehack_engine).
COPY packages/nodehack_engine/ /packages/nodehack_engine/
COPY nodehack_server/ /app/

RUN dart pub get
RUN dart compile exe bin/server.dart -o bin/server

# Imagen final mínima: sólo el runtime de Dart + el ejecutable.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

# Cloud Run inyecta PORT (8080); el servidor lo lee de la variable de entorno.
ENV PORT=8080
EXPOSE 8080
CMD ["/app/bin/server"]
