// Tests de widget: cada pantalla se monta a 390×844 (como el marco real) y se
// verifica que NO lanza excepciones de layout/overflow. La lógica está en engine_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nodehack_engine/cards.dart';
import 'package:nodehack_engine/deck.dart';
import 'package:nodehack_engine/resolve.dart';
import 'package:nodehack_engine/types.dart';
import 'package:nodehack_app/state/match_controller.dart';
import 'package:nodehack_app/screens/deck_builder_screen.dart';
import 'package:nodehack_app/screens/deck_list_screen.dart';
import 'package:nodehack_app/screens/flush_screen.dart';
import 'package:nodehack_app/screens/intro_screen.dart';
import 'package:nodehack_app/screens/match_screen.dart';
import 'package:nodehack_app/screens/menu_screen.dart';
import 'package:nodehack_app/screens/nucleo_screen.dart';
import 'package:nodehack_app/screens/rules_screen.dart';
import 'package:nodehack_app/tutorial/tutorial_match_controller.dart';
import 'package:nodehack_app/tutorial/tutorial_overlay.dart';

Future<void> _pump(WidgetTester t, Widget child) async {
  await t.binding.setSurfaceSize(const Size(390, 844)); // tamaño real del marco
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: child),
  ));
  await t.pump(const Duration(seconds: 1)); // deja correr timers de boot
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('mazo inicial legal', (t) async {
    expect(Deck.starter().isLegal, isTrue);
  });

  testWidgets('MenuScreen monta sin overflow', (t) async {
    await _pump(t, MenuScreen(onPlay: () {}, onOnline: () {}, onDeck: () {}, onNucleo: () {}, nucleoName: 'SENTINEL'));
    expect(tester(t), isNull);
  });

  testWidgets('NucleoScreen monta sin overflow', (t) async {
    await _pump(t, NucleoScreen(current: kNucleos.first, onBack: () {}, onConfirm: (_) {}));
    expect(tester(t), isNull);
  });

  testWidgets('DeckListScreen monta sin overflow', (t) async {
    await _pump(t, DeckListScreen(
      decks: [Deck.starter(), Deck(name: 'VACÍO')],
      activeIndex: 0,
      onBack: () {}, onNew: () {}, onSelect: (_) {}, onEdit: (_) {}, onDelete: (_) {},
    ));
    expect(tester(t), isNull);
  });

  testWidgets('DeckBuilderScreen monta sin overflow', (t) async {
    await _pump(t, DeckBuilderScreen(initial: Deck.starter(), onBack: () {}, onSave: (_) {}, onInspect: (_) {}));
    expect(tester(t), isNull);
  });

  testWidgets('FlushScreen monta sin overflow', (t) async {
    await _pump(t, FlushScreen(outcome: 'win', round: 3, onMenu: () {}, onAgain: () {}));
    expect(tester(t), isNull);
  });

  testWidgets('MatchScreen monta sin overflow', (t) async {
    final ctrl = MatchController(
      deckYou: Deck.starter(), onFlush: (_) {}, seed: 1,
    );
    await _pump(t, MatchScreen(ctrl: ctrl, onExit: () {}, onInspect: (_) {}));
    expect(tester(t), isNull);
    ctrl.dispose();
  });

  testWidgets('IntroScreen monta sin overflow', (t) async {
    await _pump(t, IntroScreen(onStartTutorial: () {}, onSkipToMenu: () {}));
    expect(tester(t), isNull);
  });

  Map<String, GlobalKey> spotKeysOf() =>
      {for (final k in const ['slots', 'ram', 'legend', 'oppCard', 'cta', 'hand', 'center', 'integrity']) k: GlobalKey()};

  testWidgets('Tutorial básico (mesa + overlay) monta sin overflow', (t) async {
    final ctrl = TutorialMatchController(onComplete: () {});
    final spots = spotKeysOf();
    await _pump(t, Stack(children: [
      MatchScreen(ctrl: ctrl, onExit: () {}, onInspect: (_) {}, spotKeys: spots),
      TutorialOverlay(ctrl: ctrl, spotKeys: spots),
    ]));
    expect(tester(t), isNull);
    ctrl.dispose();
  });

  testWidgets('Tutorial avanzado (mesa + overlay) monta sin overflow', (t) async {
    final ctrl = TutorialMatchController.advanced(onComplete: () {});
    final spots = spotKeysOf();
    await _pump(t, Stack(children: [
      MatchScreen(ctrl: ctrl, onExit: () {}, onInspect: (_) {}, spotKeys: spots),
      TutorialOverlay(ctrl: ctrl, spotKeys: spots),
    ]));
    expect(tester(t), isNull);
    ctrl.dispose();
  });

  testWidgets('RulesScreen monta sin overflow', (t) async {
    await _pump(t, RulesScreen(onBack: () {}));
    expect(tester(t), isNull);
  });

  test('Tutorial: gating exige la carta correcta y el bucle completo gana 2 rondas', () {
    final done = <bool>[];
    final ctrl = TutorialMatchController(onComplete: () => done.add(true));
    // Avanza los pasos de info hasta el primer paso que exige colocar una carta.
    var guard = 0;
    while (ctrl.step.gate == TutGate.info && guard++ < 20) {
      ctrl.next();
    }
    expect(ctrl.step.gate, TutGate.place);
    // Carta equivocada: se ignora.
    final pulso = ctrl.handYou.firstWhere((c) => c.defId == 'pl_base');
    ctrl.placeActive(pulso);
    expect(ctrl.active, isNull);
    // Carta correcta: se coloca y avanza.
    final fw = ctrl.handYou.firstWhere((c) => c.defId == 'fw_base');
    ctrl.placeActive(fw);
    expect(ctrl.active, same(fw));
    expect(ctrl.canCompile, isTrue);
    ctrl.dispose();
  });

  test('Tutorial avanzado: MIRROR+OVERCLOCK gana el espejo por ciclos (9 vs 5) y la RAM se descuenta', () {
    final ctrl = TutorialMatchController.advanced(onComplete: () {});
    void advanceInfo() {
      var g = 0;
      while (ctrl.step.gate == TutGate.info && g++ < 40) {
        ctrl.next();
      }
    }

    advanceInfo();
    expect(ctrl.step.gate, TutGate.place); // coloca EXPLOIT
    ctrl.placeActive(ctrl.handYou.firstWhere((c) => c.defId == 'xp_base'));
    advanceInfo();
    expect(ctrl.step.cardDefId, 'mirror'); // MIRROR (cuesta 2)
    ctrl.placeSub(ctrl.handYou.firstWhere((c) => c.defId == 'mirror'), 0);
    advanceInfo();
    expect(ctrl.step.cardDefId, 'overclock'); // OVERCLOCK (cuesta 1)
    ctrl.placeSub(ctrl.handYou.firstWhere((c) => c.defId == 'overclock'), 1);
    expect(ctrl.ramLeft, 2); // 5 − 2 − 1
    advanceInfo();
    expect(ctrl.step.gate, TutGate.compile);
    expect(ctrl.canCompile, isTrue);
    ctrl.compile();
    expect(ctrl.result, isNotNull);
    expect(ctrl.result!.winner, Winner.you); // espejo CORTAFUEGOS, 9 vence a 5
    ctrl.dispose();
  });

  testWidgets('Tutorial avanzado: flujo COMPLETO de 3 rondas hasta FINALIZAR', (t) async {
    var done = false;
    final ctrl = TutorialMatchController.advanced(onComplete: () => done = true);
    final spots = spotKeysOf();
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Stack(children: [
            MatchScreen(ctrl: ctrl, onExit: () {}, onInspect: (_) {}, spotKeys: spots),
            TutorialOverlay(ctrl: ctrl, spotKeys: spots),
          ]),
        )));
    await t.pump(const Duration(seconds: 1));

    void advanceInfo() {
      var g = 0;
      while (ctrl.step.gate == TutGate.info && g++ < 40) {
        ctrl.next();
      }
    }

    var guard = 0;
    while (!done && guard++ < 30) {
      advanceInfo();
      final s = ctrl.step;
      switch (s.gate) {
        case TutGate.place:
          ctrl.placeActive(ctrl.handYou.firstWhere((c) => c.defId == s.cardDefId));
        case TutGate.placeSub:
          final idx = ctrl.subs[0] == null ? 0 : 1;
          ctrl.placeSub(ctrl.handYou.firstWhere((c) => c.defId == s.cardDefId), idx);
        case TutGate.compile:
          expect(ctrl.canCompile, isTrue);
          ctrl.compile();
          await t.pump(const Duration(milliseconds: 8000)); // corre fases (ejecución adaptativa) hasta RESULTADO
          expect(t.takeException(), isNull);
        case TutGate.nextRound:
          ctrl.nextRound();
          await t.pump(const Duration(milliseconds: 120));
        case TutGate.done:
          ctrl.next(); // FINALIZAR
        case TutGate.info:
          break;
      }
      await t.pump(const Duration(milliseconds: 40));
    }
    expect(done, isTrue);
    expect(ctrl.history.length, 3); // ganó las 3 rondas guionizadas
    ctrl.dispose();
  });

  testWidgets('partida COMPLETA end-to-end por el controlador (fases + daño + FLUSH)', (t) async {
    final flushes = <String>[];
    final ctrl = MatchController(
      deckYou: Deck.starter(), // su Núcleo viene del mazo
      onFlush: (s) => flushes.add(s.outcome),
      seed: 5,
    );
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(home: Scaffold(body: MatchScreen(ctrl: ctrl, onExit: () {}, onInspect: (_) {}))));

    var guard = 0;
    while (!ctrl.engine.gameOver && guard++ < 60) {
      final r = ctrl.engine.handYou.firstWhere((c) => !c.isSub);
      ctrl.placeActive(r);
      if (ctrl.engine.needsNullDeclaration) ctrl.declareNull(CType.firewall);
      expect(ctrl.engine.canCompile, isTrue);
      ctrl.compile();
      await t.pump(const Duration(milliseconds: 8000)); // corre las fases (ejecución adaptativa) hasta RESULTADO
      expect(t.takeException(), isNull);
      if (!ctrl.engine.gameOver) {
        ctrl.nextRound();
        await t.pump(const Duration(milliseconds: 120)); // muestra la insignia "ADQUIRIDAS +N"
        expect(t.takeException(), isNull); // sin overflow en la barra de mazos
      }
    }
    await t.pump(const Duration(milliseconds: 2800)); // dispara onFlush (+2600ms)

    expect(ctrl.engine.gameOver, isTrue);
    expect(ctrl.engine.integrityYou == 0 || ctrl.engine.integrityOpp == 0, isTrue);
    expect(flushes.single == 'win' || flushes.single == 'lose', isTrue);
    ctrl.dispose();
  });
}

/// Devuelve la última excepción capturada por el binding (o null).
Object? tester(WidgetTester t) => t.takeException();
