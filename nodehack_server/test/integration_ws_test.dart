// Integración E2E: dos clientes WebSocket REALES juegan una partida completa
// contra el servidor (crear sala, unirse, varias rondas, gameOver). Verifica que
// ninguno ve la mano del otro.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:test/test.dart';
import 'package:nodehack_engine/nodehack_engine.dart';
import 'package:nodehack_server/protocol.dart';
import 'package:nodehack_server/room.dart';
import 'package:nodehack_server/serve.dart';

class WsClient {
  final WebSocket ws;
  final List<Map<String, dynamic>> msgs = [];
  WsClient(this.ws) {
    ws.listen((d) {
      if (d is String) msgs.add(jsonDecode(d) as Map<String, dynamic>);
    });
  }
  void send(String t, [Map<String, dynamic> data = const {}]) => ws.add(encodeMsg(t, data));
  List<Map<String, dynamic>> ofType(String t) => msgs.where((m) => m['t'] == t).toList();
  Map<String, dynamic>? lastOf(String t) {
    final l = ofType(t);
    return l.isEmpty ? null : l.last;
  }

  List<dynamic> latestHand() {
    for (var i = msgs.length - 1; i >= 0; i--) {
      if (msgs[i].containsKey('hand')) return msgs[i]['hand'] as List;
    }
    return const [];
  }

  Set<String> handUids() {
    final out = <String>{};
    for (final m in msgs) {
      if ((m['t'] == S2C.matchStart || m['t'] == S2C.acquire) && m['hand'] is List) {
        for (final c in m['hand'] as List) {
          out.add((c as Map)['uid'] as String);
        }
      }
    }
    return out;
  }
}

PlaySubmission defPlay(WsClient cap) {
  final hand = handFromJson(cap.latestHand());
  final rut = hand.firstWhere((c) => !c.isSub);
  return PlaySubmission(rutinaUid: rut.uid, declaredType: rut.esComodinNull ? CType.firewall : null);
}

Future<void> waitFor(bool Function() cond, {int maxMs = 3000}) async {
  final sw = Stopwatch()..start();
  while (!cond() && sw.elapsedMilliseconds < maxMs) {
    await Future<void>.delayed(const Duration(milliseconds: 4));
  }
}

void main() {
  late HttpServer server;
  late int port;

  setUp(() async {
    final hub = Hub(RoomManager(rng: Random(9), closeDelay: const Duration(milliseconds: 5)));
    server = await serve(hub, port: 0, address: InternetAddress.loopbackIPv4);
    port = server.port;
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('dos clientes WebSocket juegan una partida completa por código', () async {
    final a = WsClient(await WebSocket.connect('ws://localhost:$port/ws'));
    final b = WsClient(await WebSocket.connect('ws://localhost:$port/ws'));

    a.send(C2S.hello, {'name': 'ALICE'});
    b.send(C2S.hello, {'name': 'BOB'});

    a.send(C2S.createRoom, {'deck': Deck.starter().toJson()});
    await waitFor(() => a.lastOf(S2C.roomCreated) != null);
    final code = a.lastOf(S2C.roomCreated)!['code'] as String;

    b.send(C2S.joinRoom, {'code': code, 'deck': Deck.starter().toJson()});
    await waitFor(() => a.lastOf(S2C.matchStart) != null && b.lastOf(S2C.matchStart) != null);
    expect(a.lastOf(S2C.matchStart)!['oppName'], 'BOB');
    expect(b.lastOf(S2C.matchStart)!['oppName'], 'ALICE');

    var over = false, guard = 0;
    while (!over && guard++ < 400) {
      final prev = a.ofType(S2C.reveal).length;
      a.send(C2S.submitPlay, defPlay(a).toJson());
      b.send(C2S.submitPlay, defPlay(b).toJson());
      await waitFor(() =>
          a.ofType(S2C.reveal).length > prev && b.ofType(S2C.reveal).length > prev);

      over = (a.lastOf(S2C.reveal)!['public'] as Map)['gameOver'] == true;
      if (!over) {
        final pa = a.ofType(S2C.acquire).length;
        a.send(C2S.nextRoundAck);
        b.send(C2S.nextRoundAck);
        await waitFor(() =>
            a.ofType(S2C.acquire).length > pa && b.ofType(S2C.acquire).length > pa);
      }
    }

    expect(over, isTrue, reason: 'la partida no terminó');
    final outA = (a.lastOf(S2C.reveal)!['public'] as Map)['outcome'];
    final outB = (b.lastOf(S2C.reveal)!['public'] as Map)['outcome'];
    expect({outA, outB}, {'win', 'lose'});

    // Privacidad: las manos vistas por cada cliente son disjuntas.
    expect(a.handUids().intersection(b.handUids()), isEmpty);

    await a.ws.close();
    await b.ws.close();
  });
}
