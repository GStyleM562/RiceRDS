/// Estado persistente del modo INMERSIÓN (savefile único `nh_adventure_v1`).
/// Maneja DOS monedas: puntos de RUN (progreso, con checkpoints cada 10) y puntos
/// de NATURALEZA (voluntad por color, deciden el final), además de corrupción,
/// jefes, mini-eventos y la galería de finales desbloqueados (meta-persistente).
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
  int battles = 0;
  String natureId = kStartNature.id;

  // Progreso de la run (dos monedas).
  int runPoints = 0; // +1/victoria, −3/derrota (con floor)
  int runFloor = 0; // mayor checkpoint alcanzado (múltiplo de 10)
  int bossesDone = 0; // 0..kBossCount
  int bossCooldown = 0; // victorias requeridas para reintentar un jefe perdido
  int corruption = 0; // 0..100
  final Map<String, int> naturePoints = {}; // id de rol -> puntos de voluntad
  final Set<int> firedEvents = {}; // umbrales de mini-evento ya disparados esta run

  // Colección / mazo.
  final Map<String, int> collection = {};
  final Map<String, int> deckSel = {};
  final Set<String> codex = {};

  // Meta (persistente ENTRE runs).
  final Set<String> unlockedEndings = {};

  bool get hasRun => runActive;
  NatureDef get nature => natureById(natureId);
  int naturePointsOf(String id) => naturePoints[id] ?? 0;

  /// El rol con más puntos de naturaleza (empate → el primero).
  String dominantNature() {
    var best = kNatures.first.id, bestN = -1;
    for (final n in kNatures) {
      final p = naturePointsOf(n.id);
      if (p > bestN) {
        bestN = p;
        best = n.id;
      }
    }
    return best;
  }

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
      natureId = j['nature'] as String? ?? kStartNature.id;
      runPoints = j['runPoints'] as int? ?? 0;
      runFloor = j['runFloor'] as int? ?? 0;
      bossesDone = j['bossesDone'] as int? ?? 0;
      bossCooldown = j['bossCooldown'] as int? ?? 0;
      corruption = j['corruption'] as int? ?? 0;
      naturePoints
        ..clear()
        ..addAll(Map<String, int>.from((j['naturePoints'] as Map?) ?? {}));
      firedEvents
        ..clear()
        ..addAll(((j['firedEvents'] as List?) ?? const []).cast<int>());
      collection
        ..clear()
        ..addAll(Map<String, int>.from((j['collection'] as Map?) ?? {}));
      deckSel
        ..clear()
        ..addAll(Map<String, int>.from((j['deck'] as Map?) ?? collection));
      codex
        ..clear()
        ..addAll(((j['codex'] as List?) ?? const []).cast<String>());
      unlockedEndings
        ..clear()
        ..addAll(((j['endings'] as List?) ?? const []).cast<String>());
    } catch (_) {/* savefile corrupto → se ignora */}
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kSave,
      jsonEncode({
        'v': 2,
        'runActive': runActive,
        'credits': credits,
        'subsUnlocked': subsUnlocked,
        'wins': wins,
        'battles': battles,
        'nature': natureId,
        'runPoints': runPoints,
        'runFloor': runFloor,
        'bossesDone': bossesDone,
        'bossCooldown': bossCooldown,
        'corruption': corruption,
        'naturePoints': naturePoints,
        'firedEvents': firedEvents.toList(),
        'collection': collection,
        'deck': deckSel,
        'codex': codex.toList(),
        'endings': unlockedEndings.toList(),
      }),
    );
  }

  /// Empieza una run nueva (sobrescribe la anterior). Colección starter mínima.
  /// [keepNature] permite conservar puntos de naturaleza (final básico → 25%).
  /// `unlockedEndings` NO se toca (es meta-progreso).
  void startNewRun({Map<String, int>? keepNature}) {
    runActive = true;
    credits = 0;
    subsUnlocked = false;
    wins = 0;
    battles = 0;
    natureId = kStartNature.id;
    runPoints = 0;
    runFloor = 0;
    bossesDone = 0;
    bossCooldown = 0;
    corruption = 0;
    naturePoints
      ..clear()
      ..addAll(keepNature ?? const {});
    firedEvents.clear();
    collection
      ..clear()
      ..addAll(starterCollectionRut());
    deckSel
      ..clear()
      ..addAll(collection);
    codex
      ..clear()
      ..addAll(collection.keys);
    notifyListeners();
    _save();
  }

  // ── Mazo de aventura (selección manual; por defecto = todo lo poseído) ──
  int inDeck(String id) => deckSel[id] ?? 0;

  void setInDeck(String id, int n) {
    final v = n.clamp(0, owned(id));
    if (v <= 0) {
      deckSel.remove(id);
    } else {
      deckSel[id] = v;
    }
    notifyListeners();
    _save();
  }

  Deck get advDeck {
    final rut = <String, int>{};
    final sub = <String, int>{};
    deckSel.forEach((id, n) {
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

  bool addCard(String id) {
    if (atCap(id)) return false;
    collection[id] = owned(id) + 1;
    deckSel[id] = (inDeck(id) + 1).clamp(0, owned(id));
    codex.add(id);
    notifyListeners();
    _save();
    return true;
  }

  void removeCard(String id) {
    final n = owned(id);
    if (n <= 0) return;
    if (n == 1) {
      collection.remove(id);
    } else {
      collection[id] = n - 1;
    }
    if (inDeck(id) > owned(id)) setInDeck(id, owned(id));
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

  void addCorruption(int n) {
    corruption = (corruption + n).clamp(0, 100);
    notifyListeners();
    _save();
  }

  // ── Progreso (dos monedas) ──
  void _addNature(int n) => naturePoints[natureId] = naturePointsOf(natureId) + n;
  void _loseNatureOnDefeat() {
    if (bossesDone >= 1) {
      naturePoints[natureId] = (naturePointsOf(natureId) * kNatureLossFactor).round();
    }
  }

  /// Combate normal/élite (no jefe). Recompensa SOLO al ganar.
  void recordCombat({required bool win, required bool elite}) {
    battles++;
    if (win) {
      wins++;
      runPoints++;
      final cp = (runPoints ~/ kCheckpointStep) * kCheckpointStep;
      if (cp > runFloor) runFloor = cp;
      _addNature(kWinNaturePts);
      addCreditsSilent(elite ? kEliteCredits : kRewardCredits);
      if (!subsUnlocked && wins >= kSubsUnlockWins) subsUnlocked = true;
      if (bossCooldown > 0) bossCooldown--;
    } else {
      runPoints = (runPoints - kRunLossPenalty).clamp(runFloor, 1 << 30);
      corruption = (corruption + kCorruptOnLoss).clamp(0, 100);
      _loseNatureOnDefeat();
    }
    notifyListeners();
    _save();
  }

  /// Resultado del JEFE. Ganar → +3 naturaleza y avanza; perder → cooldown.
  void recordBoss({required bool win}) {
    if (win) {
      bossesDone++;
      _addNature(kBossNaturePts);
      addCreditsSilent(kEliteCredits);
      bossCooldown = 0;
    } else {
      bossCooldown = kBossCooldownWins;
      corruption = (corruption + kCorruptOnLoss).clamp(0, 100);
      _loseNatureOnDefeat();
    }
    notifyListeners();
    _save();
  }

  /// Cambia tu naturaleza (evento MUTACIÓN) — cambia tu Núcleo; a NULO sube corrupción.
  void setNature(String id) {
    natureId = id;
    if (id == 'nulo') corruption = (corruption + kCorruptMutateNull).clamp(0, 100);
    notifyListeners();
    _save();
  }

  // ── Mini-eventos ──
  /// Umbral de mini-evento pendiente (cruzado y no disparado), o null.
  int? pendingEvent() {
    for (final t in kMiniEventPoints) {
      if (runPoints >= t && !firedEvents.contains(t)) return t;
    }
    return null;
  }

  void markEventFired(int t) {
    firedEvents.add(t);
    notifyListeners();
    _save();
  }

  // ── Finales ──
  /// Qué final corresponde al terminar (tras el 5º jefe).
  String evaluateEnding() {
    if (unlockedEndings.containsAll([for (final n in kNatures) n.trueEndingId])) {
      return kSecretEndingId; // los 4 verdaderos → GÉNESIS
    }
    final dom = dominantNature();
    if (corruption >= kCorruptForceNull) {
      // El vacío gana: NULL verdadero si tiene voluntad; si no, recaes (básico).
      return naturePointsOf('nulo') >= kTrueThreshold ? 'true_nulo' : kBasicEndingId;
    }
    if (naturePointsOf(dom) >= kTrueThreshold) return 'true_$dom';
    return kBasicEndingId;
  }

  /// Cierra la run con [endingId]: desbloquea galería, calcula carryover de
  /// naturaleza (verdadero/secreto → 0; básico → 25%) y reinicia la run.
  void concludeRun(String endingId) {
    if (endingId == kSecretEndingId || endingId.startsWith('true_')) {
      unlockedEndings.add(endingId);
    }
    Map<String, int>? keep;
    if (endingId == kBasicEndingId) {
      keep = {
        for (final e in naturePoints.entries)
          if ((e.value * kBasicKeepPct).round() > 0) e.key: (e.value * kBasicKeepPct).round(),
      };
    }
    startNewRun(keepNature: keep); // conserva unlockedEndings (meta) y guarda
  }

  // Suma créditos sin notificar/guardar dos veces (uso interno).
  void addCreditsSilent(int n) => credits = (credits + n).clamp(0, 999999);

  /// Borra por completo el progreso de Historia, incluida la galería de finales.
  Future<void> wipe() async {
    runActive = false;
    credits = 0;
    subsUnlocked = false;
    wins = 0;
    battles = 0;
    natureId = kStartNature.id;
    runPoints = 0;
    runFloor = 0;
    bossesDone = 0;
    bossCooldown = 0;
    corruption = 0;
    naturePoints.clear();
    firedEvents.clear();
    collection.clear();
    deckSel.clear();
    codex.clear();
    unlockedEndings.clear();
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.remove(_kSave);
  }
}
