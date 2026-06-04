// Tests de widget: cada pantalla se monta a 390×844 (como el marco real) y se
// verifica que NO lanza excepciones de layout/overflow. La lógica está en engine_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nodehack_engine/cards.dart';
import 'package:nodehack_engine/deck.dart';
import 'package:nodehack_engine/types.dart';
import 'package:nodehack_app/state/match_controller.dart';
import 'package:nodehack_app/screens/deck_builder_screen.dart';
import 'package:nodehack_app/screens/deck_list_screen.dart';
import 'package:nodehack_app/screens/flush_screen.dart';
import 'package:nodehack_app/screens/match_screen.dart';
import 'package:nodehack_app/screens/menu_screen.dart';
import 'package:nodehack_app/screens/nucleo_screen.dart';

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
      deckYou: Deck.starter(), onFlush: (_, round) {}, seed: 1,
    );
    await _pump(t, MatchScreen(ctrl: ctrl, onExit: () {}, onInspect: (_) {}));
    expect(tester(t), isNull);
    ctrl.dispose();
  });

  testWidgets('partida COMPLETA end-to-end por el controlador (fases + daño + FLUSH)', (t) async {
    final flushes = <String>[];
    final ctrl = MatchController(
      deckYou: Deck.starter(), // su Núcleo viene del mazo
      onFlush: (outcome, round) => flushes.add(outcome),
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
      await t.pump(const Duration(milliseconds: 2800)); // corre las fases hasta RESULTADO
      expect(t.takeException(), isNull);
      if (!ctrl.engine.gameOver) {
        ctrl.nextRound();
        await t.pump();
      }
    }
    await t.pump(const Duration(milliseconds: 1000)); // dispara onFlush (+900ms)

    expect(ctrl.engine.gameOver, isTrue);
    expect(ctrl.engine.integrityYou == 0 || ctrl.engine.integrityOpp == 0, isTrue);
    expect(flushes.single == 'win' || flushes.single == 'lose', isTrue);
    ctrl.dispose();
  });
}

/// Devuelve la última excepción capturada por el binding (o null).
Object? tester(WidgetTester t) => t.takeException();
