// Tests del modo INMERSIÓN: estado/persistencia, controlador (contador/jefe/botín)
// y montaje de pantallas a 390×844 sin overflow.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nodehack_engine/cards.dart';
import 'package:nodehack_app/adventure/adventure_controller.dart';
import 'package:nodehack_app/adventure/adventure_data.dart';
import 'package:nodehack_app/adventure/adventure_host.dart';
import 'package:nodehack_app/adventure/codex_screen.dart';
import 'package:nodehack_app/adventure/adventure_state.dart';

Future<void> _pump(WidgetTester t, Widget child) async {
  await t.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: Scaffold(body: child)));
  await t.pump(const Duration(milliseconds: 500));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('startNewRun: colección starter = 3 básicas ×2, sin Subrutinas', () {
    final st = AdventureState();
    st.startNewRun();
    expect(st.hasRun, isTrue);
    expect(st.owned('fw_base'), 2);
    expect(st.owned('xp_base'), 2);
    expect(st.subsUnlocked, isFalse);
    expect(st.advDeck.isLegalAdventure, isTrue);
    expect(st.advDeck.subCount, 0); // subs bloqueadas → no entran al mazo
  });

  test('addCard respeta el tope y registra en el Códice', () {
    final st = AdventureState();
    st.startNewRun();
    expect(st.addCard('fw_base'), isTrue); // 2 → 3
    expect(st.addCard('fw_base'), isFalse); // al tope (kMaxRutCopies)
    expect(st.owned('fw_base'), kMaxRutCopies);
    expect(st.codex.contains('fw_base'), isTrue);
  });

  test('Subrutinas se desbloquean a las 3 victorias', () {
    final st = AdventureState();
    st.startNewRun();
    st.recordCombat(win: true, elite: false);
    st.recordCombat(win: true, elite: false);
    expect(st.subsUnlocked, isFalse);
    st.recordCombat(win: true, elite: false);
    expect(st.subsUnlocked, isTrue);
    expect(st.wins, 3);
    expect(st.credits, greaterThan(0));
  });

  test('Controller: el JEFE aparece al umbral; perder solo retrocede el contador', () {
    final st = AdventureState();
    st.startNewRun();
    st.sinceBoss = kBattlesPerSector; // fuerza el umbral del jefe
    final c = AdventureController(st, seed: 1);
    expect(c.step, AdvStep.bossIntro);
    expect(c.isBoss, isTrue);
    c.startCombat();
    expect(c.step, AdvStep.combat);
    c.onCombatEnd(false); // pierdes vs el jefe
    expect(st.sector, 1); // NO avanzó de sector
    expect(st.sinceBoss, lessThan(kBattlesPerSector)); // contador retrocedió
  });

  test('Controller: ganar al JEFE avanza de sector', () {
    final st = AdventureState();
    st.startNewRun();
    st.sinceBoss = kBattlesPerSector;
    final c = AdventureController(st, seed: 1);
    c.startCombat();
    c.onCombatEnd(true);
    expect(st.sector, 2);
    expect(st.sinceBoss, 0);
    expect(c.step, AdvStep.sectorEnd);
  });

  test('Controller: ganar un combate normal ofrece botín y se puede elegir', () {
    final st = AdventureState();
    st.startNewRun();
    // Busca una semilla cuyas 3 cartas-camino incluyan combate/élite.
    AdventureController c;
    var seed = 0;
    do {
      c = AdventureController(st, seed: seed++);
    } while (!c.paths.any((p) => p == PathKind.combat || p == PathKind.elite) && seed < 80);
    final idx = c.paths.indexWhere((p) => p == PathKind.combat || p == PathKind.elite);
    expect(idx, greaterThanOrEqualTo(0));
    c.choosePath(idx);
    expect(c.step, AdvStep.loreIntro);
    expect(c.enemy, isNotNull);
    c.startCombat();
    c.onCombatEnd(true); // ganas
    expect(c.step, AdvStep.reward);
    expect(c.rewardChoices, isNotEmpty);
    final before = st.owned(c.rewardChoices.first);
    c.chooseReward(c.rewardChoices.first);
    expect(st.owned(c.rewardChoices.first), before + 1);
  });

  testWidgets('AdventureHost (elección de camino) monta sin overflow', (t) async {
    final st = AdventureState();
    st.startNewRun();
    final c = AdventureController(st, seed: 3); // arranca en path
    await _pump(t, AdventureHost(ctrl: c, onZoom: (_) {}, onExit: () {}, onEnterCombat: () {}));
    expect(t.takeException(), isNull);
    c.dispose();
  });

  testWidgets('CodexScreen monta sin overflow (con cartas descubiertas)', (t) async {
    final st = AdventureState();
    st.startNewRun();
    st.addCard('fw_iron');
    await _pump(t, CodexScreen(st: st, onBack: () {}, onZoom: (_) {}));
    expect(t.takeException(), isNull);
  });
}
