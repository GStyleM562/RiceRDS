/// Cliente WebSocket del app (PVP). Conecta a `wss://…/ws`, expone un stream de
/// mensajes ya decodificados y permite enviar `{t: tipo, ...datos}`.
library;

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

enum WsStatus { idle, connecting, open, closed, error }

/// Abstracción del socket de juego (permite un socket FALSO en tests).
abstract class GameSocket {
  Stream<Map<String, dynamic>> get messages;
  WsStatus get status;
  set onStatus(void Function(WsStatus)? f);
  Future<bool> connect();
  void send(String type, [Map<String, dynamic> data = const {}]);
  Future<void> close();
}

class WsClient implements GameSocket {
  final String url;
  WebSocketChannel? _ch;
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  WsStatus status = WsStatus.idle;
  @override
  void Function(WsStatus)? onStatus;

  WsClient(this.url);

  @override
  Stream<Map<String, dynamic>> get messages => _controller.stream;

  void _set(WsStatus s) {
    status = s;
    onStatus?.call(s);
  }

  @override
  Future<bool> connect() async {
    _set(WsStatus.connecting);
    try {
      final ch = WebSocketChannel.connect(Uri.parse(url));
      await ch.ready;
      _ch = ch;
      _set(WsStatus.open);
      ch.stream.listen(
        (data) {
          if (data is String) {
            try {
              _controller.add(jsonDecode(data) as Map<String, dynamic>);
            } catch (_) {
              // mensaje no-JSON: ignora.
            }
          }
        },
        onDone: () => _set(WsStatus.closed),
        onError: (_) => _set(WsStatus.error),
        cancelOnError: true,
      );
      return true;
    } catch (_) {
      _set(WsStatus.error);
      return false;
    }
  }

  @override
  void send(String type, [Map<String, dynamic> data = const {}]) {
    _ch?.sink.add(jsonEncode({'t': type, ...data}));
  }

  @override
  Future<void> close() async {
    try {
      await _ch?.sink.close();
    } catch (_) {}
    _set(WsStatus.closed);
    if (!_controller.isClosed) await _controller.close();
  }
}
