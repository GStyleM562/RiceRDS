/// Arranque HTTP/WebSocket reutilizable (lo usan `bin/server.dart` y los tests
/// de integración). Toda petición no-WebSocket responde 200 (health check de
/// Cloud Run); las de upgrade se vuelven WebSocket y se rutean por el [Hub].
library;

import 'dart:io';

import 'room.dart';

Future<HttpServer> serve(Hub hub, {int port = 8080, Object? address}) async {
  final server = await HttpServer.bind(address ?? InternetAddress.anyIPv4, port);
  server.listen((req) async {
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      try {
        final ws = await WebSocketTransformer.upgrade(req);
        ws.pingInterval = const Duration(seconds: 30); // mantiene viva la conexión
        attachSocket(hub, ws);
      } catch (_) {
        // upgrade fallido: ignora.
      }
    } else {
      req.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.text
        ..write('NODEHACK :: PROGRAM_NULL server OK');
      await req.response.close();
    }
  });
  return server;
}

/// Asocia un WebSocket a una [Conn] y lo conecta al Hub.
void attachSocket(Hub hub, WebSocket ws) {
  final conn = Conn((data) {
    if (ws.readyState == WebSocket.open) ws.add(data);
  });
  ws.listen(
    (data) {
      if (data is String) hub.onMessage(conn, data);
    },
    onDone: () => hub.onClose(conn),
    onError: (_) => hub.onClose(conn),
    cancelOnError: true,
  );
}
