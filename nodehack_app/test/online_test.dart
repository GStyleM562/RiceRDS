// Cliente PVP: la pantalla de lobby monta sin overflow y el NetworkMatchController
// reacciona correctamente a los mensajes de un "servidor" FALSO en memoria.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nodehack_engine/nodehack_engine.dart';
import 'package:nodehack_app/net/ws_client.dart';
import 'package:nodehack_app/screens/online_screen.dart';
import 'package:nodehack_app/state/network_match_controller.dart';

/// Socket falso: captura lo enviado y permite inyectar mensajes "del servidor".
class FakeSocket implements GameSocket {
  final StreamController<Map<String, dynamic>> _c = StreamController.broadcast();
  final List<Map<String, dynamic>> sent = [];
  @override
  WsStatus status = WsStatus.open;
  @override
  void Function(WsStatus)? onStatus;
  @override
  Stream<Map<String, dynamic>> get messages => _c.stream;
  @override
  Future<bool> connect() async => true;
  @override
  void send(String type, [Map<String, dynamic> data = const {}]) => sent.add({'t': type, ...data});
  @override
  Future<void> close() async {
    if (!_c.isClosed) await _c.close();
  }

  void inject(Map<String, dynamic> m) => _c.add(m);
}

Map<String, dynamic> _public({int you = 4, int opp = 4, bool over = false, String? outcome}) =>
    PublicState(
      round: 1,
      integrityYou: you, integrityOpp: opp,
      integrityMaxYou: 4, integrityMaxOpp: 4,
      nucYouId: 'wraith', nucOppId: 'sentinel',
      rutPileYou: 8, subPileYou: 17, rutPileOpp: 8, subPileOpp: 17,
      gameOver: over, outcome: outcome,
    ).toJson();

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('OnlineScreen (lobby) monta sin overflow', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: OnlineScreen(
          deck: Deck.starter(),
          playerName: 'OPERADOR',
          serverUrl: 'ws://localhost:8080/ws',
          onSetName: (_) {},
          onSetServerUrl: (_) {},
          onExit: () {},
          onFlush: (_, _) {},
          onInspect: (_) {},
        ),
      ),
    ));
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.text('JUGAR ONLINE'), findsOneWidget);
  });

  test('NetworkMatchController: matchStart → compile → reveal → acquire', () async {
    final fake = FakeSocket();
    final flushes = <String>[];
    final ctrl = NetworkMatchController(
      ws: fake,
      deckYou: Deck.starter(),
      playerName: 'OP',
      onFlush: (o, _) => flushes.add(o),
    );

    // matchStart
    final hand = [
      CardInstance.rutina(kRutById['fw_base']!),
      CardInstance.subrutina(kSubById['overclock']!),
    ];
    fake.inject({
      't': S2C.matchStart,
      'hand': handToJson(hand),
      'ramBase': 5,
      'public': _public(),
      'oppName': 'BOB',
    });
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(ctrl.matchStarted, isTrue);
    expect(ctrl.nucYou.id, 'wraith');
    expect(ctrl.oppName, 'BOB');
    expect(ctrl.handYou.length, 2);

    // programar + compilar → envía submitPlay
    final rut = ctrl.handYou.firstWhere((c) => !c.isSub);
    ctrl.placeActive(rut);
    expect(ctrl.canCompile, isTrue);
    ctrl.compile();
    expect(fake.sent.last['t'], C2S.submitPlay);
    expect(fake.sent.last['rutinaUid'], rut.uid);
    expect(ctrl.phaseIdx, 2); // COMPILAR (sellado)

    // reveal: gano (CORTAFUEGOS vence EXPLOIT), el rival baja a 3 de integridad
    final r = resolve(
      Play(CardInstance.rutina(kRutById['fw_base']!), const []),
      Play(CardInstance.rutina(kRutById['xp_base']!), const []),
    );
    fake.inject({
      't': S2C.reveal,
      'yourPlay': Play(rut, const []).toJson(),
      'oppPlay': Play(CardInstance.rutina(kRutById['xp_base']!), const []).toJson(),
      'result': r.toJson(),
      'public': _public(you: 4, opp: 3),
    });
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    expect(ctrl.oppPlay, isNotNull);
    expect(ctrl.result!.winner, Winner.you);
    expect(ctrl.phaseIdx, 5); // RESULTADO
    expect(ctrl.integrityOpp, 3); // daño aplicado al llegar a RESULTADO
    expect(ctrl.history.single, Winner.you);

    // siguiente ronda
    ctrl.nextRound();
    expect(fake.sent.last['t'], C2S.nextRoundAck);
    fake.inject({
      't': S2C.acquire,
      'hand': handToJson([
        CardInstance.rutina(kRutById['pl_base']!),
        CardInstance.subrutina(kSubById['mirror']!),
      ]),
      'ramBase': 5,
      'public': _public(you: 4, opp: 3),
      'acquiredN': 2, 'acquiredRut': 1, 'acquiredSub': 1,
    });
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(ctrl.phaseIdx, 1); // PROGRAMACIÓN de la nueva ronda
    expect(ctrl.oppPlay, isNull);
    expect(ctrl.handYou.length, 2);

    ctrl.dispose();
  });

  test('NetworkMatchController: gameOver por forfeit dispara onFlush', () async {
    final fake = FakeSocket();
    final flushes = <String>[];
    final ctrl = NetworkMatchController(
      ws: fake, deckYou: Deck.starter(), playerName: 'OP',
      onFlush: (o, _) => flushes.add(o),
    );
    fake.inject({'t': S2C.gameOver, 'outcome': 'win'});
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(ctrl.gameOver, isTrue);
    expect(flushes.single, 'win');
    ctrl.dispose();
  });
}
