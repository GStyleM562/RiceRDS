// Tests del modo INMERSIÓN: estado/persistencia, controlador (contador/jefe/botín)
// y montaje de pantallas a 390×844 sin overflow.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nodehack_engine/cards.dart';
import 'package:nodehack_app/adventure/adventure_controller.dart';
import 'package:nodehack_app/adventure/adventure_data.dart';
import 'package:nodehack_app/adventure/adventure_deck_screen.dart';
import 'package:nodehack_app/adventure/adventure_host.dart';
import 'package:nodehack_app/adventure/codex_screen.dart';
import 'package:nodehack_app/adventure/adventure_state.dart';
import 'package:nodehack_app/adventure/ending_screen.dart';
import 'package:nodehack_app/screens/settings_screen.dart';
import 'package:nodehack_app/state/app_state.dart';

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

  test('Controller: el JEFE aparece a los 10 run-points; perder pone cooldown', () {
    final st = AdventureState();
    st.startNewRun();
    st.runPoints = 10; // umbral del 1er jefe
    st.firedEvents.addAll(kMiniEventPoints); // sin mini-eventos pendientes
    final c = AdventureController(st, seed: 1);
    expect(c.step, AdvStep.bossIntro);
    expect(c.isBoss, isTrue);
    c.startCombat();
    expect(c.step, AdvStep.combat);
    c.onCombatEnd(false); // pierdes vs el jefe
    expect(st.bossesDone, 0); // NO avanzó
    expect(st.bossCooldown, greaterThan(0)); // cooldown para reintentar
  });

  test('Controller: ganar al JEFE incrementa bossesDone; el 5º dispara el final', () {
    final st = AdventureState();
    st.startNewRun();
    st.runPoints = 10;
    st.firedEvents.addAll(kMiniEventPoints);
    var c = AdventureController(st, seed: 1);
    c.startCombat();
    c.onCombatEnd(true);
    expect(st.bossesDone, 1);

    // Fuerza el 5º jefe con voluntad suficiente → final verdadero.
    st.bossesDone = 4;
    st.runPoints = 50;
    st.naturePoints['guardian'] = 25;
    c = AdventureController(st, seed: 1);
    expect(c.step, AdvStep.bossIntro);
    c.startCombat();
    c.onCombatEnd(true);
    expect(st.bossesDone, 5);
    expect(c.step, AdvStep.ending);
    expect(c.endingId, 'true_guardian');
  });

  test('Dos monedas: +1/win, +3/jefe, checkpoint, y −10% solo desde el 1er jefe', () {
    final st = AdventureState();
    st.startNewRun();
    for (var i = 0; i < 10; i++) {
      st.recordCombat(win: true, elite: false);
    }
    expect(st.runPoints, 10);
    expect(st.runFloor, 10);
    expect(st.naturePointsOf('guardian'), 10);
    st.recordBoss(win: true);
    expect(st.bossesDone, 1);
    expect(st.naturePointsOf('guardian'), 13); // +3
    st.recordCombat(win: false, elite: false);
    expect(st.runPoints, 10); // checkpoint: no baja de 10
    expect(st.naturePointsOf('guardian'), lessThan(13)); // −10% (ya hubo jefe)
  });

  test('Naturaleza NO baja al perder antes del 1er jefe', () {
    final st = AdventureState();
    st.startNewRun();
    st.recordCombat(win: true, elite: false);
    expect(st.naturePointsOf('guardian'), 1);
    st.recordCombat(win: false, elite: false);
    expect(st.naturePointsOf('guardian'), 1); // intacto
  });

  test('evaluateEnding: básico/verdadero/corrupción-NULL/secreto', () {
    final st = AdventureState();
    st.startNewRun();
    st.naturePoints['guardian'] = 10;
    expect(st.evaluateEnding(), kBasicEndingId);
    st.naturePoints['guardian'] = 22;
    expect(st.evaluateEnding(), 'true_guardian');
    st.corruption = 90; // vacío gana, sin voluntad NULL → básico
    expect(st.evaluateEnding(), kBasicEndingId);
    st.naturePoints['nulo'] = 30; // ahora NULL tiene voluntad
    expect(st.evaluateEnding(), 'true_nulo');
    st.corruption = 0;
    st.unlockedEndings.addAll([for (final n in kNatures) n.trueEndingId]);
    expect(st.evaluateEnding(), kSecretEndingId);
  });

  test('concludeRun: verdadero resetea naturaleza y desbloquea; básico conserva 25%', () {
    final st = AdventureState();
    st.startNewRun();
    st.naturePoints['guardian'] = 28;
    st.concludeRun('true_guardian');
    expect(st.unlockedEndings.contains('true_guardian'), isTrue);
    expect(st.naturePointsOf('guardian'), 0); // reset tras verdadero
    st.naturePoints['espectro'] = 20;
    st.concludeRun(kBasicEndingId);
    expect(st.naturePointsOf('espectro'), 5); // 25% de 20
    expect(st.unlockedEndings.contains('true_guardian'), isTrue); // meta se conserva
  });

  test('Mini-eventos: cada umbral 1 sola vez por run', () {
    final st = AdventureState();
    st.startNewRun();
    st.runPoints = 7;
    expect(st.pendingEvent(), 5);
    st.markEventFired(5);
    expect(st.pendingEvent(), isNull);
    st.runPoints = 12;
    expect(st.pendingEvent(), 10);
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
    await _pump(t, AdventureHost(ctrl: c, onZoom: (_) {}, onExit: () {}, onEnterCombat: () {}, onConfigDeck: () {}));
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

  testWidgets('AdventureDeckScreen monta sin overflow (subs bloqueadas)', (t) async {
    final st = AdventureState();
    st.startNewRun();
    await _pump(t, AdventureDeckScreen(st: st, onBack: () {}, onZoom: (_) {}));
    expect(t.takeException(), isNull);
  });

  testWidgets('SettingsScreen monta sin overflow', (t) async {
    await _pump(t, SettingsScreen(onBack: () {}, onResetFirstTime: () {}, onWipeStory: () {}, hasStoryRun: true));
    expect(t.takeException(), isNull);
  });

  test('Balance: enemigos tier 0 = solo básicas, SIN Subrutinas', () {
    for (final e in combatEnemies(0)) {
      expect(e.sub.isEmpty, isTrue, reason: e.name);
      for (final id in e.rut.keys) {
        expect(const ['fw_base', 'xp_base', 'pl_base'].contains(id), isTrue, reason: id);
      }
    }
  });

  test('Balance: enemyTier escala con subsUnlocked y bossesDone', () {
    expect(enemyTier(subsUnlocked: false, bossesDone: 0), 0);
    expect(enemyTier(subsUnlocked: true, bossesDone: 0), 1);
    expect(enemyTier(subsUnlocked: true, bossesDone: 2), 2);
  });

  testWidgets('EndingScreen monta sin overflow (verdadero y secreto)', (t) async {
    await _pump(t, EndingScreen(view: endingViewFor('true_guardian'), onClose: () {}));
    expect(t.takeException(), isNull);
    await _pump(t, EndingScreen(view: endingViewFor(kSecretEndingId), onClose: () {}));
    expect(t.takeException(), isNull);
  });

  test('Cartas de Historia: excluidas del multijugador', () {
    final app = AppState();
    expect(app.isMultiplayerUnlocked('st_overdrive'), isFalse);
    expect(app.isMultiplayerUnlocked('st_purge'), isFalse);
    expect(app.isMultiplayerUnlocked('overclock'), isTrue); // base, sí
  });

  test('Purga de corrupción: gasta créditos y baja la corrupción', () {
    final st = AdventureState();
    st.startNewRun();
    st.corruption = 50;
    st.addCredits(20);
    final c = AdventureController(st, seed: 1);
    expect(c.canPurge, isTrue);
    final creditsBefore = st.credits;
    expect(c.buyPurge(), isTrue);
    expect(st.corruption, 25); // −25
    expect(st.credits, creditsBefore - c.purgeCost);
  });

  test('Perder un combate NO da créditos ni victorias', () {
    final st = AdventureState();
    st.startNewRun();
    final before = st.credits;
    st.recordCombat(win: false, elite: false);
    expect(st.credits, before);
    expect(st.wins, 0);
    expect(st.battles, 1);
  });

  test('deck builder: setInDeck acota a lo poseído; wipe borra todo', () {
    final st = AdventureState();
    st.startNewRun();
    expect(st.inDeck('fw_base'), 2); // arranca con todo en el mazo
    st.setInDeck('fw_base', 0);
    expect(st.inDeck('fw_base'), 0);
    expect(st.advDeck.rut['fw_base'], isNull);
    st.setInDeck('fw_base', 99); // se acota a lo poseído (2)
    expect(st.inDeck('fw_base'), 2);
    st.wipe();
    expect(st.hasRun, isFalse);
    expect(st.collection.isEmpty, isTrue);
    expect(st.deckSel.isEmpty, isTrue);
  });
}
