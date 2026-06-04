/// Servidor WebSocket de NODEHACK :: PROGRAM_NULL.
/// Escucha en `$PORT` (8080 por defecto) — requerido por Cloud Run.
library;

import 'dart:io';

import 'package:nodehack_server/room.dart';
import 'package:nodehack_server/serve.dart';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final hub = Hub(RoomManager());
  await serve(hub, port: port);
  // ignore: avoid_print
  print('NODEHACK :: PROGRAM_NULL — servidor escuchando en :$port');
}
