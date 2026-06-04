/// Protocolo de mensajes WebSocket (sobre JSON). Las *cargas* (mano, jugada,
/// resultado, estado público) usan los DTOs del motor compartido → cliente y
/// servidor hablan exactamente el mismo formato.
library;

import 'dart:convert';

// Las claves del protocolo (C2S/S2C) viven en el motor compartido → una sola
// fuente de verdad para cliente y servidor.
export 'package:nodehack_engine/protocol_keys.dart';

Map<String, dynamic> decodeMsg(String text) => jsonDecode(text) as Map<String, dynamic>;

/// Serializa un mensaje `{t: type, ...data}`.
String encodeMsg(String type, [Map<String, dynamic> data = const {}]) =>
    jsonEncode({'t': type, ...data});
