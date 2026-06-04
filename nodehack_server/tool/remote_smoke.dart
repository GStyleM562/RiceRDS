/// Prueba de humo contra un servidor PVP YA desplegado: conecta por WebSocket,
/// saluda y crea una sala. Uso: `dart run tool/remote_smoke.dart [wss://…/ws]`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nodehack_engine/nodehack_engine.dart';

Future<void> main(List<String> args) async {
  final url = args.isNotEmpty ? args.first : 'wss://nodehack-server.onrender.com/ws';
  stdout.writeln('Conectando a $url ...');
  final ws = await WebSocket.connect(url);
  final done = Completer<void>();
  ws.listen((d) {
    stdout.writeln('<= $d');
    final m = jsonDecode(d as String) as Map<String, dynamic>;
    if (m['t'] == 'roomCreated') {
      stdout.writeln('OK ✓  El servidor desplegado creó la sala ${m['code']} (WebSocket/wss funcionan).');
      ws.close();
      if (!done.isCompleted) done.complete();
    }
  }, onDone: () {
    if (!done.isCompleted) done.complete();
  });
  ws.add(jsonEncode({'t': C2S.hello, 'name': 'SMOKE'}));
  ws.add(jsonEncode({'t': C2S.createRoom, 'deck': Deck.starter().toJson()}));
  await done.future.timeout(const Duration(seconds: 25), onTimeout: () => stdout.writeln('TIMEOUT (¿arranque en frío?)'));
}
