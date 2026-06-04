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

class AppState extends ChangeNotifier {
  static const _kDecks = 'nh_decks';
  static const _kActive = 'nh_active_deck';
  static const _kNucleo = 'nh_nucleo';
  static const _kName = 'nh_name';
  static const _kDevice = 'nh_device';
  static const _kServer = 'nh_server';

  NucleoDef nucleo = kNucleos.first;
  List<Deck> decks = [];
  int activeDeck = 0;

  // Identidad anónima + config de servidor (PVP).
  String playerName = '';
  String deviceId = '';
  String serverUrl = kDefaultServerUrl;

  Deck get currentDeck =>
      decks.isEmpty ? Deck.starter() : decks[activeDeck.clamp(0, decks.length - 1)];

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
    notifyListeners();
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
