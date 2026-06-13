/// Estado de app: núcleo activo, mazos guardados, mazo activo. Persistido (prefs).
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nodehack_engine/cards.dart';
import 'package:nodehack_engine/deck.dart';

/// URL por defecto del servidor PVP (desplegado en Render). Para pruebas en LAN
/// puedes cambiarla en el app por `ws://IP-de-tu-PC:8080/ws`.
const String kDefaultServerUrl = 'wss://nodehack-server.onrender.com/ws';

/// Mientras probamos las cartas nuevas, TODAS están desbloqueadas en multijugador.
/// Poner en `false` activa el desbloqueo escalonado por partidas/anuncios.
const bool kUnlockAllForTesting = true;

class AppState extends ChangeNotifier {
  static const _kDecks = 'nh_decks';
  static const _kActive = 'nh_active_deck';
  static const _kNucleo = 'nh_nucleo';
  static const _kName = 'nh_name';
  static const _kDevice = 'nh_device';
  static const _kServer = 'nh_server';
  static const _kIntro = 'nh_intro';
  static const _kTutBasic = 'nh_tut_basic';
  static const _kTutAdv = 'nh_tut_adv';
  static const _kFirstPrompt = 'nh_first_prompt'; // sugerencia de tutorial ya ofrecida
  static const _kGames = 'nh_games';

  NucleoDef nucleo = kNucleos.first;
  List<Deck> decks = [];
  int activeDeck = 0;

  // Identidad anónima + config de servidor (PVP).
  String playerName = '';
  String deviceId = '';
  String serverUrl = kDefaultServerUrl;

  // Onboarding (primera vez).
  bool introSeen = false;
  bool tutorialBasicDone = false;
  bool tutorialAdvancedDone = false;
  bool firstPromptSeen = false; // la sugerencia de tutorial ya se ofreció (persistente)

  // Partidas de Versus jugadas (para desbloquear cartas nuevas en multijugador).
  int gamesPlayed = 0;

  Deck get currentDeck =>
      decks.isEmpty ? Deck.starter() : decks[activeDeck.clamp(0, decks.length - 1)];

  /// ¿La carta está desbloqueada para el MULTIJUGADOR? Las cartas base (las que ya
  /// existían) siempre; las nuevas, jugando [kCardUnlockGames] partidas (o por
  /// anuncios, a futuro). Con [kUnlockAllForTesting] todas están abiertas para probar.
  bool isMultiplayerUnlocked(String cardId) {
    if (kStoryOnlyCardIds.contains(cardId)) return false; // exclusivas de Historia
    if (kUnlockAllForTesting) return true;
    final req = kCardUnlockGames[cardId];
    if (req == null) return kAllCardIds.contains(cardId); // base / desconocida
    return gamesPlayed >= req;
  }

  /// Partidas que faltan para desbloquear [cardId] (0 si ya está). Para la UI.
  int gamesToUnlock(String cardId) {
    final req = kCardUnlockGames[cardId];
    if (req == null) return 0;
    return (req - gamesPlayed).clamp(0, req);
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kDecks);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      decks = list.map(Deck.fromJson).toList();
    }
    if (decks.isEmpty) decks = [Deck.starter('MAZO BASE')];
    activeDeck = (p.getInt(_kActive) ?? 0).clamp(0, decks.length - 1);
    nucleo = kNucById[p.getString(_kNucleo)] ?? kNucleos.first;

    deviceId = p.getString(_kDevice) ?? '';
    if (deviceId.isEmpty) {
      deviceId = _genDeviceId();
      await p.setString(_kDevice, deviceId);
    }
    playerName = p.getString(_kName) ?? 'OPERADOR-${deviceId.substring(0, 4).toUpperCase()}';
    serverUrl = p.getString(_kServer) ?? kDefaultServerUrl;

    introSeen = p.getBool(_kIntro) ?? false;
    tutorialBasicDone = p.getBool(_kTutBasic) ?? false;
    tutorialAdvancedDone = p.getBool(_kTutAdv) ?? false;
    firstPromptSeen = p.getBool(_kFirstPrompt) ?? false;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    notifyListeners();
  }

  /// Cuenta una partida de Versus terminada (alimenta el desbloqueo de cartas).
  void incGamesPlayed() {
    gamesPlayed++;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setInt(_kGames, gamesPlayed));
  }

  void markIntroSeen() {
    if (introSeen) return;
    introSeen = true;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setBool(_kIntro, true));
  }

  void markTutorialBasicDone() {
    if (tutorialBasicDone) return;
    tutorialBasicDone = true;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setBool(_kTutBasic, true));
  }

  void markTutorialAdvancedDone() {
    if (tutorialAdvancedDone) return;
    tutorialAdvancedDone = true;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setBool(_kTutAdv, true));
  }

  /// La sugerencia de tutorial ya se ofreció (la inició o la descartó). No vuelve
  /// a aparecer hasta "reiniciar primera vez". Persistente entre sesiones.
  void markFirstPromptSeen() {
    if (firstPromptSeen) return;
    firstPromptSeen = true;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setBool(_kFirstPrompt, true));
  }

  /// Vuelve al estado de "primera vez": la próxima vez (o ahora mismo) verás la
  /// intro y la ventana de tutorial otra vez. No toca mazos ni Historia.
  void resetOnboarding() {
    introSeen = false;
    tutorialBasicDone = false;
    tutorialAdvancedDone = false;
    firstPromptSeen = false;
    notifyListeners();
    SharedPreferences.getInstance().then((p) {
      p.remove(_kIntro);
      p.remove(_kTutBasic);
      p.remove(_kTutAdv);
      p.remove(_kFirstPrompt);
    });
  }

  static String _genDeviceId() {
    final r = Random();
    final a = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final b = r.nextInt(1 << 32).toRadixString(36);
    return '$a$b';
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kDecks, jsonEncode(decks.map((d) => d.toJson()).toList()));
    await p.setInt(_kActive, activeDeck);
    await p.setString(_kNucleo, nucleo.id);
  }

  void setPlayerName(String name) {
    playerName = name.trim().isEmpty ? playerName : name.trim();
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setString(_kName, playerName));
  }

  void setServerUrl(String url) {
    serverUrl = url.trim().isEmpty ? kDefaultServerUrl : url.trim();
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setString(_kServer, serverUrl));
  }

  void setNucleo(NucleoDef n) {
    nucleo = n;
    notifyListeners();
    _save();
  }

  void selectDeck(int i) {
    activeDeck = i.clamp(0, decks.length - 1);
    notifyListeners();
    _save();
  }

  /// Guarda un mazo (nuevo o reemplazo por índice). Devuelve su índice.
  int saveDeck(Deck d, {int? index}) {
    if (index != null && index >= 0 && index < decks.length) {
      decks[index] = d;
    } else {
      decks.add(d);
      index = decks.length - 1;
    }
    activeDeck = index;
    notifyListeners();
    _save();
    return index;
  }

  void deleteDeck(int i) {
    if (decks.length <= 1) return; // siempre al menos 1
    decks.removeAt(i);
    activeDeck = activeDeck.clamp(0, decks.length - 1);
    notifyListeners();
    _save();
  }
}
