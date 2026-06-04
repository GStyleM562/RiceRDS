import 'package:flutter/material.dart';

import 'package:nodehack_engine/card_instance.dart';
import 'package:nodehack_engine/deck.dart';
import 'state/app_state.dart';
import 'state/match_controller.dart';
import 'screens/deck_builder_screen.dart';
import 'screens/deck_list_screen.dart';
import 'screens/flush_screen.dart';
import 'screens/match_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/nucleo_screen.dart';
import 'screens/online_screen.dart';
import 'theme/tokens.dart';
import 'widgets/card_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

enum _Screen { menu, nucleo, deckList, deckBuilder, match, online, flush }

class _AppRootState extends State<AppRoot> {
  final AppState app = AppState();
  _Screen screen = _Screen.menu;
  int? _editIndex;
  MatchController? _match;
  String _flushOutcome = 'win';
  int _flushRound = 0;
  bool _flushFromOnline = false;
  CardInstance? _zoom; // carta en modo "zoom" (lectura)

  @override
  void initState() {
    super.initState();
    app.load();
  }

  void _go(_Screen s) => setState(() => screen = s);

  void _showZoom(CardInstance c) => setState(() => _zoom = c);
  void _hideZoom() => setState(() => _zoom = null);

  void _startMatch() {
    _match?.dispose();
    _flushFromOnline = false;
    _match = MatchController(
      deckYou: app.currentDeck,
      onFlush: (outcome, round) {
        _flushOutcome = outcome;
        _flushRound = round;
        _go(_Screen.flush);
      },
    );
    _go(_Screen.match);
  }

  /// Vuelve al menú (descarta la partida si la hubiera).
  void _toMenu() {
    _match?.dispose();
    _match = null;
    setState(() {
      screen = _Screen.menu;
      _zoom = null;
    });
  }

  @override
  void dispose() {
    _match?.dispose();
    app.dispose();
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
              if (_zoom != null) _zoomOverlay(_zoom!),
            ],
          ),
        ),
      ),
    );
  }

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
        );
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
          onFlush: (outcome, round) {
            _flushFromOnline = true;
            _flushOutcome = outcome;
            _flushRound = round;
            _go(_Screen.flush);
          },
        );
      case _Screen.flush:
        return FlushScreen(
          outcome: _flushOutcome,
          round: _flushRound,
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
