import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import 'package:nodehack_engine/card_instance.dart';
import 'package:nodehack_engine/deck.dart';
import 'adventure/adventure_controller.dart';
import 'adventure/adventure_data.dart';
import 'adventure/adventure_deck_screen.dart';
import 'adventure/adventure_host.dart';
import 'adventure/adventure_state.dart';
import 'adventure/codex_screen.dart';
import 'adventure/ending_screen.dart';
import 'audio/audio_service.dart';
import 'state/app_state.dart';
import 'state/match_controller.dart';
import 'state/match_view.dart';
import 'screens/deck_builder_screen.dart';
import 'screens/deck_list_screen.dart';
import 'screens/flush_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/match_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/nucleo_screen.dart';
import 'screens/online_screen.dart';
import 'screens/rules_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/tokens.dart';
import 'tutorial/tutorial_match_controller.dart';
import 'tutorial/tutorial_overlay.dart';
import 'widgets/card_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioService.instance.init();
  runApp(const NodehackApp());
}

class NodehackApp extends StatelessWidget {
  const NodehackApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'NODEHACK :: PROGRAM_NULL',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.black,
          brightness: Brightness.dark,
          textSelectionTheme: const TextSelectionThemeData(cursorColor: NH.fw),
        ),
        home: const AppRoot(),
      );
}

enum _Screen { menu, intro, tutorial, rules, settings, adventure, codex, nucleo, deckList, deckBuilder, match, online, flush }

class _AppRootState extends State<AppRoot> {
  final AppState app = AppState();
  final AdventureState adv = AdventureState();
  _Screen screen = _Screen.menu;
  int? _editIndex;
  MatchController? _match;
  TutorialMatchController? _tutorial;
  AdventureController? _advCtrl; // run de INMERSIÓN activa
  MatchController? _advMatch; // duelo dentro de la run
  bool _advDeckOpen = false; // constructor de mazo de aventura abierto
  MatchSummary _flushSummary = const MatchSummary(outcome: 'win', round: 0, history: []);
  bool _flushFromOnline = false;
  CardInstance? _zoom; // carta en modo "zoom" (lectura)
  bool _tutorialOffered = false; // ventana de 1ª vez ya mostrada en esta sesión
  bool _showTutChooser = false; // selector BÁSICO/AVANZADO desde el menú
  bool _showRoutes = false; // panel de rutas de assets (solo debug)
  // Zonas de la mesa que el tutorial puede señalar (compartidas mesa↔overlay).
  final Map<String, GlobalKey> _tutSpots = {
    for (final k in const ['slots', 'ram', 'legend', 'oppCard', 'cta', 'hand', 'center', 'integrity']) k: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    // Primer arranque: ve a la intro antes del menú.
    app.load().then((_) {
      if (mounted && !app.introSeen) _go(_Screen.intro);
    });
    adv.load();
    AudioService.instance.playMusic(Music.menu);
  }

  // ── Modo INMERSIÓN ──
  void _enterAdventure() {
    if (!adv.hasRun) adv.startNewRun();
    _advCtrl?.dispose();
    _advCtrl = AdventureController(adv);
    _go(_Screen.adventure);
  }

  // Monta el duelo de la run (botón ENTRAR del lore) y arranca el combate.
  void _enterAdvCombat() {
    final c = _advCtrl;
    final e = c?.enemy;
    if (c == null || e == null) return;
    _advMatch?.dispose();
    _advMatch = MatchController(
      deckYou: adv.advDeck,
      deckOpp: e.deck(),
      nucOpp: e.nucleo,
      oppName: e.name,
      integrityYouBonus: c.combatYouBonus,
      integrityOppBonus: c.combatOppBonus,
      onFlush: (s) {
        final win = s.outcome == 'win';
        final m = _advMatch;
        _advMatch = null;
        c.onCombatEnd(win); // avanza la run; el route vuelve al AdventureHost
        m?.dispose();
      },
    );
    c.startCombat();
  }

  // Rendirse en un combate de la run = perderlo.
  void _forfeitAdvCombat() {
    final c = _advCtrl;
    if (c == null) return;
    final m = _advMatch;
    _advMatch = null;
    c.onCombatEnd(false);
    m?.dispose();
  }

  void _exitAdventure() => _toMenu();

  // Ajustes: vuelve al estado de "primera vez" y muestra la intro ahora mismo.
  void _resetFirstTime() {
    app.resetOnboarding();
    _tutorialOffered = false;
    _go(_Screen.intro);
  }

  // Ajustes: borra el progreso de Historia y refresca el menú.
  void _wipeStory() {
    _advMatch?.dispose();
    _advMatch = null;
    _advCtrl?.dispose();
    _advCtrl = null;
    _advDeckOpen = false;
    adv.wipe();
    setState(() {});
  }

  void _startTutorial() {
    _tutorial?.dispose();
    _tutorial = TutorialMatchController(onComplete: () {
      app.markTutorialBasicDone();
      _toMenu();
    });
    _tutorialOffered = true;
    _showTutChooser = false;
    _go(_Screen.tutorial);
  }

  void _startTutorialAdvanced() {
    _tutorial?.dispose();
    _tutorial = TutorialMatchController.advanced(onComplete: () {
      app.markTutorialAdvancedDone();
      _toMenu();
    });
    _tutorialOffered = true;
    _showTutChooser = false;
    _go(_Screen.tutorial);
  }

  void _go(_Screen s) => setState(() => screen = s);

  void _showZoom(CardInstance c) {
    AudioService.instance.playSfx(Sfx.cardZoom);
    setState(() => _zoom = c);
  }
  void _hideZoom() => setState(() => _zoom = null);

  void _startMatch() {
    _match?.dispose();
    _flushFromOnline = false;
    _match = MatchController(
      deckYou: app.currentDeck,
      onFlush: (summary) {
        app.incGamesPlayed(); // cuenta para desbloquear cartas
        _flushSummary = summary;
        _go(_Screen.flush);
      },
    );
    _go(_Screen.match);
  }

  /// Vuelve al menú (descarta la partida/tutorial/inmersión si los hubiera).
  void _toMenu() {
    _match?.dispose();
    _match = null;
    _tutorial?.dispose();
    _tutorial = null;
    _advMatch?.dispose();
    _advMatch = null;
    _advCtrl?.dispose();
    _advCtrl = null;
    _advDeckOpen = false;
    setState(() {
      screen = _Screen.menu;
      _zoom = null;
    });
  }

  @override
  void dispose() {
    _match?.dispose();
    _tutorial?.dispose();
    _advMatch?.dispose();
    _advCtrl?.dispose();
    app.dispose();
    adv.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // El botón "atrás" del sistema vuelve al MENÚ (o cierra el zoom) en vez de salir.
    return PopScope(
      canPop: screen == _Screen.menu && _zoom == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_zoom != null) {
          _hideZoom();
        } else if (screen == _Screen.match || screen == _Screen.online || screen == _Screen.tutorial) {
          // La mesa/lobby manejan su propio "atrás" (confirmación de rendición).
          return;
        } else if (screen == _Screen.intro) {
          app.markIntroSeen();
          _toMenu();
        } else if (screen == _Screen.adventure) {
          // En el constructor de mazo, "atrás" lo cierra; en combate la mesa maneja
          // su propio "atrás" (rendición); fuera de eso, sale al menú (run guardada).
          if (_advDeckOpen) {
            setState(() => _advDeckOpen = false);
          } else {
            _exitAdventure();
          }
        } else if (screen != _Screen.menu) {
          _toMenu();
        }
      },
      child: _DeviceFrame(
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              ListenableBuilder(listenable: app, builder: (context, _) => _buildScreen()),
              if (screen == _Screen.menu && app.introSeen && !app.tutorialBasicDone && !_tutorialOffered)
                _firstTimePrompt(),
              if (_showTutChooser && screen == _Screen.menu) _tutChooser(),
              if (_showRoutes && screen == _Screen.menu) _routesOverlay(),
              if (_zoom != null) _zoomOverlay(_zoom!),
            ],
          ),
        ),
      ),
    );
  }

  // Panel de RUTAS de assets (solo debug): dónde dejar música/SFX y el icono.
  Widget _routesOverlay() {
    Widget group(String title, List<({String label, String path})> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: NH.mono(size: 10, weight: FontWeight.w700, color: NH.fw, spacing: 2)),
            const SizedBox(height: 6),
            for (final it in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(it.label, style: NH.mono(size: 8.5, color: NH.amber, spacing: 1)),
                  SelectableText(it.path, style: NH.mono(size: 10.5, color: const Color(0xFFE8F6FF))),
                ]),
              ),
            const SizedBox(height: 8),
          ],
        );
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _showRoutes = false),
        child: Container(
          color: NH.a(Colors.black, .9),
          alignment: Alignment.center,
          padding: const EdgeInsets.fromLTRB(20, NH.safe + 16, 20, NH.safe + 16),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              decoration: BoxDecoration(
                color: NH.a(const Color(0xFF03080C), .97),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NH.a(NH.fw, .7), width: 1.2),
                boxShadow: [BoxShadow(color: NH.a(NH.fw, .22), blurRadius: 22)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('RUTAS DE ASSETS · solo debug', style: NH.mono(size: 11, weight: FontWeight.w700, color: NH.fw, spacing: 2)),
                const SizedBox(height: 4),
                Text('Deja cada archivo con ESE nombre EXACTO en su carpeta. Si falta, el juego corre igual (silencioso).',
                    style: NH.mono(size: 9, color: NH.dim, height: 1.4)),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      group('MÚSICA  (assets/audio/)', AudioService.musicAssets()),
                      group('SFX  (assets/audio/)', AudioService.sfxAssets()),
                      Text('ICONO DE LA APP', style: NH.mono(size: 10, weight: FontWeight.w700, color: NH.fw, spacing: 2)),
                      const SizedBox(height: 6),
                      Text('Fuente: store_assets/icon_1024.png  ·  regenera con:\nflutter test tool/gen_store_graphics.dart\nluego: dart run flutter_launcher_icons',
                          style: NH.mono(size: 9.5, color: const Color(0xFFE8F6FF), height: 1.5)),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => setState(() => _showRoutes = false),
                    child: Text('CERRAR', style: NH.mono(size: 11, color: NH.dim, spacing: 2)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // Selector de tutorial (desde el botón CÓMO JUGAR del menú).
  Widget _tutChooser() => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _showTutChooser = false), // tocar fuera = cerrar
          child: Container(
            color: NH.a(Colors.black, .82),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: NH.a(const Color(0xFF03080C), .96),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: NH.a(NH.fw, .7), width: 1.2),
                  boxShadow: [BoxShadow(color: NH.a(NH.fw, .22), blurRadius: 22)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('CÓMO JUGAR', style: NH.mono(size: 11, color: NH.fw, spacing: 3)),
                    const SizedBox(height: 4),
                    Text('Partidas guiadas con un instructor.', style: NH.mono(size: 10, color: NH.dim)),
                    const SizedBox(height: 16),
                    _tutOption('TUTORIAL BÁSICO', 'El triángulo: quién vence a quién.', _startTutorial,
                        done: app.tutorialBasicDone),
                    const SizedBox(height: 10),
                    _tutOption('TUTORIAL AVANZADO', 'Ciclos, RAM, Subrutinas y el orden de resolución.', _startTutorialAdvanced,
                        done: app.tutorialAdvancedDone),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _showTutChooser = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        alignment: Alignment.center,
                        child: Text('CERRAR', style: NH.mono(size: 11, color: NH.dim, spacing: 2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _tutOption(String label, String sub, VoidCallback onTap, {bool done = false}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: NH.a(NH.fw, .06),
            border: Border.all(color: NH.a(NH.fw, .55), width: 1.1),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Text(label, style: NH.mono(size: 12, weight: FontWeight.w700, color: const Color(0xFFEAF7FF), spacing: 1)),
                  if (done) ...[
                    const SizedBox(width: 8),
                    Text('✓', style: NH.mono(size: 12, weight: FontWeight.w700, color: NH.pl)),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(sub, style: NH.mono(size: 8.5, color: NH.dim)),
              ]),
            ),
            Text('▸', style: NH.mono(size: 13, color: NH.fw)),
          ]),
        ),
      );

  // Ventana de primera vez: invita a ejecutar el tutorial al volver al menú.
  Widget _firstTimePrompt() => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {}, // captura toques (modal)
          child: Container(
            color: NH.a(Colors.black, .82),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: NH.a(const Color(0xFF03080C), .96),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NH.a(NH.fw, .7), width: 1.2),
                boxShadow: [BoxShadow(color: NH.a(NH.fw, .22), blurRadius: 22)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('∅ // SYS', style: NH.mono(size: 11, color: NH.fw, spacing: 3)),
                  const SizedBox(height: 12),
                  Text('Detecto tu primer acceso, proceso.\n¿Ejecuto el entrenamiento básico?',
                      style: NH.mono(size: 14, color: const Color(0xFFE8F6FF), height: 1.5)),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: _startTutorial,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: NH.a(NH.fw, .12),
                        border: Border.all(color: NH.fw, width: 1.2),
                        boxShadow: [BoxShadow(color: NH.a(NH.fw, .25), blurRadius: 14)],
                      ),
                      child: Text('INICIAR TUTORIAL', style: NH.mono(size: 13, weight: FontWeight.w700, color: NH.fw, spacing: 2)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() => _tutorialOffered = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      child: Text('AHORA NO', style: NH.mono(size: 12, color: NH.dim, spacing: 2)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _zoomOverlay(CardInstance card) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _hideZoom,
          child: Container(
            color: NH.a(Colors.black, .85),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CardView(card: card, width: 300),
                const SizedBox(height: 16),
                Text('toca para cerrar', style: NH.mono(size: 11, color: NH.dim, spacing: 2)),
              ],
            ),
          ),
        ),
      );

  Widget _buildScreen() {
    switch (screen) {
      case _Screen.menu:
        return MenuScreen(
          nucleoName: app.nucleo.name,
          onPlay: _startMatch,
          onOnline: () => _go(_Screen.online),
          onDeck: () => _go(_Screen.deckList),
          onNucleo: () => _go(_Screen.nucleo),
          onTutorial: () => setState(() => _showTutChooser = true),
          onRules: () => _go(_Screen.rules),
          onAdventure: _enterAdventure,
          hasAdventureRun: adv.hasRun,
          onCodex: () => _go(_Screen.codex),
          onSettings: () => _go(_Screen.settings),
          onDebugRoutes: kDebugMode ? () => setState(() => _showRoutes = true) : null,
        );
      case _Screen.settings:
        return SettingsScreen(
          onBack: () => _go(_Screen.menu),
          onResetFirstTime: _resetFirstTime,
          onWipeStory: _wipeStory,
          hasStoryRun: adv.hasRun,
        );
      case _Screen.adventure:
        return AnimatedBuilder(
          animation: _advCtrl!,
          builder: (context, _) {
            if (_advDeckOpen) {
              return AdventureDeckScreen(st: adv, onBack: () => setState(() => _advDeckOpen = false), onZoom: _showZoom);
            }
            if (_advCtrl!.step == AdvStep.ending) {
              return EndingScreen(
                view: endingViewFor(_advCtrl!.endingId, dominantNatureId: adv.dominantNature()),
                onClose: () {
                  adv.concludeRun(_advCtrl!.endingId); // desbloquea + reinicia la run
                  _exitAdventure();
                },
              );
            }
            if (_advCtrl!.step == AdvStep.combat && _advMatch != null) {
              return MatchScreen(ctrl: _advMatch!, onExit: _forfeitAdvCombat, onInspect: _showZoom);
            }
            return AdventureHost(
              ctrl: _advCtrl!,
              onZoom: _showZoom,
              onEnterCombat: _enterAdvCombat,
              onExit: _exitAdventure,
              onConfigDeck: () => setState(() => _advDeckOpen = true),
            );
          },
        );
      case _Screen.codex:
        return CodexScreen(st: adv, onBack: () => _go(_Screen.menu), onZoom: _showZoom);
      case _Screen.intro:
        return IntroScreen(
          onStartTutorial: () {
            app.markIntroSeen();
            _startTutorial();
          },
          onSkipToMenu: () {
            app.markIntroSeen();
            _go(_Screen.menu);
          },
        );
      case _Screen.tutorial:
        return Stack(children: [
          MatchScreen(ctrl: _tutorial!, onExit: _toMenu, onInspect: _showZoom, spotKeys: _tutSpots),
          TutorialOverlay(ctrl: _tutorial!, spotKeys: _tutSpots),
        ]);
      case _Screen.rules:
        return RulesScreen(onBack: () => _go(_Screen.menu));
      case _Screen.nucleo:
        return NucleoScreen(
          current: app.nucleo,
          onBack: () => _go(_Screen.menu),
          onConfirm: (n) {
            app.setNucleo(n);
            _go(_Screen.menu);
          },
        );
      case _Screen.deckList:
        return DeckListScreen(
          decks: app.decks,
          activeIndex: app.activeDeck,
          onBack: () => _go(_Screen.menu),
          onSelect: app.selectDeck,
          onNew: () {
            _editIndex = null;
            _go(_Screen.deckBuilder);
          },
          onEdit: (i) {
            _editIndex = i;
            _go(_Screen.deckBuilder);
          },
          onDelete: app.deleteDeck,
        );
      case _Screen.deckBuilder:
        final initial = _editIndex != null ? app.decks[_editIndex!] : Deck(name: 'NUEVO MAZO', nucleoId: app.nucleo.id);
        return DeckBuilderScreen(
          initial: initial,
          onBack: () => _go(_Screen.deckList),
          onInspect: _showZoom,
          cardLocked: (id) => !app.isMultiplayerUnlocked(id),
          gamesLeft: app.gamesToUnlock,
          onSave: (d) {
            app.saveDeck(d, index: _editIndex);
            _go(_Screen.deckList);
          },
        );
      case _Screen.match:
        return MatchScreen(ctrl: _match!, onExit: _toMenu, onInspect: _showZoom);
      case _Screen.online:
        return OnlineScreen(
          deck: app.currentDeck,
          playerName: app.playerName,
          serverUrl: app.serverUrl,
          onSetName: app.setPlayerName,
          onSetServerUrl: app.setServerUrl,
          onExit: _toMenu,
          onInspect: _showZoom,
          onFlush: (summary) {
            app.incGamesPlayed();
            _flushFromOnline = true;
            _flushSummary = summary;
            _go(_Screen.flush);
          },
        );
      case _Screen.flush:
        return FlushScreen(
          outcome: _flushSummary.outcome,
          round: _flushSummary.round,
          history: _flushSummary.history,
          reason: _flushSummary.reason,
          onAgain: _flushFromOnline ? () => _go(_Screen.online) : _startMatch,
          onMenu: _toMenu,
        );
    }
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

/// Marco de dispositivo móvil vertical (390×844), escalado a la ventana.
class _DeviceFrame extends StatelessWidget {
  final Widget child;
  const _DeviceFrame({required this.child});
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            width: NH.device.width,
            height: NH.device.height,
            decoration: BoxDecoration(
              color: NH.bg,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 60, spreadRadius: 4)],
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
  }
}
