/// Estado persistente del modo INMERSIÓN (savefile único `nh_adventure_v1`).
/// Guarda colección de aventura, créditos, contadores de progreso, naturaleza y
/// Códice. El mazo de aventura se AUTO-arma con todo lo que posees (Fase 1: un
/// constructor manual queda para después).
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nodehack_engine/cards.dart';
import 'package:nodehack_engine/deck.dart';

import 'adventure_data.dart';

class AdventureState extends ChangeNotifier {
  static const _kSave = 'nh_adventure_v1';

  bool runActive = false;
  int credits = 0;
  bool subsUnlocked = false;
  int wins = 0;
  int battles = 0; // combates completados (no jefe)
  int sinceBoss = 0; // combates desde el último jefe
  int sector = 1;
  String natureId = kStartNature.id;
  final Map<String, int> collection = {}; // cardId -> copias poseídas
  final Set<String> codex = {}; // cartas descubiertas en historia

  bool get hasRun => runActive;
  NatureDef get nature => natureById(natureId);

  // ── Carga / guardado ──
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kSave);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      runActive = j['runActive'] as bool? ?? false;
      credits = j['credits'] as int? ?? 0;
      subsUnlocked = j['subsUnlocked'] as bool? ?? false;
      wins = j['wins'] as int? ?? 0;
      battles = j['battles'] as int? ?? 0;
      sinceBoss = j['sinceBoss'] as int? ?? 0;
      sector = j['sector'] as int? ?? 1;
      natureId = j['nature'] as String? ?? kStartNature.id;
      collection
        ..clear()
        ..addAll(Map<String, int>.from((j['collection'] as Map?) ?? {}));
      codex
        ..clear()
        ..addAll(((j['codex'] as List?) ?? const []).cast<String>());
    } catch (_) {/* savefile corrupto → se ignora */}
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kSave,
      jsonEncode({
        'v': 1,
        'runActive': runActive,
        'credits': credits,
        'subsUnlocked': subsUnlocked,
        'wins': wins,
        'battles': battles,
        'sinceBoss': sinceBoss,
        'sector': sector,
        'nature': natureId,
        'collection': collection,
        'codex': codex.toList(),
      }),
    );
  }

  /// Empieza una run nueva (sobrescribe la anterior). Colección starter mínima.
  void startNewRun() {
    runActive = true;
    credits = 0;
    subsUnlocked = false;
    wins = 0;
    battles = 0;
    sinceBoss = 0;
    sector = 1;
    natureId = kStartNature.id;
    collection
      ..clear()
      ..addAll(starterCollectionRut());
    codex
      ..clear()
      ..addAll(collection.keys);
    notifyListeners();
    _save();
  }

  // ── Mazo de aventura (auto-armado con lo poseído) ──
  Deck get advDeck {
    final rut = <String, int>{};
    final sub = <String, int>{};
    collection.forEach((id, n) {
      if (n <= 0) return;
      if (kRutById.containsKey(id)) {
        rut[id] = n;
      } else if (subsUnlocked && kSubById.containsKey(id)) {
        sub[id] = n;
      }
    });
    return Deck(name: 'INMERSIÓN', nucleoId: nature.nucleo.id, rut: rut, sub: sub);
  }

  // ── Colección ──
  int owned(String id) => collection[id] ?? 0;
  bool isRut(String id) => kRutById.containsKey(id);
  int capFor(String id) => isRut(id) ? kMaxRutCopies : kMaxSubCopies;
  bool atCap(String id) => owned(id) >= capFor(id);

  /// Añade una copia (respeta el tope). Devuelve true si entró. Registra en el Códice.
  bool addCard(String id) {
    if (atCap(id)) return false;
    collection[id] = owned(id) + 1;
    codex.add(id);
    notifyListeners();
    _save();
    return true;
  }

  /// Quita una copia (defragmentar en la tienda).
  void removeCard(String id) {
    final n = owned(id);
    if (n <= 0) return;
    if (n == 1) {
      collection.remove(id);
    } else {
      collection[id] = n - 1;
    }
    notifyListeners();
    _save();
  }

  // ── Créditos ──
  void addCredits(int n) {
    credits = (credits + n).clamp(0, 999999);
    notifyListeners();
    _save();
  }

  bool spend(int n) {
    if (credits < n) return false;
    credits -= n;
    notifyListeners();
    _save();
    return true;
  }

  // ── Progreso ──
  /// Resultado de un combate normal/élite (no jefe). Aplica créditos y contadores.
  void recordCombat({required bool win, required bool elite}) {
    battles++;
    sinceBoss++;
    if (win) {
      wins++;
      addCreditsSilent(elite ? kEliteCredits : kRewardCredits);
      if (!subsUnlocked && wins >= kSubsUnlockWins) subsUnlocked = true;
    } else {
      addCreditsSilent(kLoseConsolation);
    }
    notifyListeners();
    _save();
  }

  /// Resultado del JEFE. Ganar → avanza de tramo; perder → solo retrocede el contador.
  void recordBoss({required bool win}) {
    if (win) {
      sector++;
      sinceBoss = 0;
      addCreditsSilent(kEliteCredits);
    } else {
      sinceBoss = (kBattlesPerSector - kBossLoseSetback).clamp(0, kBattlesPerSector);
    }
    notifyListeners();
    _save();
  }

  /// Cambia tu naturaleza (evento MUTACIÓN) — también cambia tu Núcleo.
  void setNature(String id) {
    natureId = id;
    notifyListeners();
    _save();
  }

  // Suma créditos sin notificar/guardar dos veces (uso interno).
  void addCreditsSilent(int n) => credits = (credits + n).clamp(0, 999999);
}
