/// Conduce una run de INMERSIÓN por "nodos": decide el siguiente paso por el
/// contador de peleas (jefe / fragmento / elección de 3 caminos), prepara el rival
/// del combate y aplica recompensas. La mesa de duelo (`MatchScreen`) la lanza
/// `main` cuando `step == combat`, y avisa el resultado con `onCombatEnd`.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:nodehack_engine/cards.dart';

import 'adventure_data.dart';
import 'adventure_state.dart';

enum AdvStep { path, loreIntro, combat, reward, shop, fragment, event, bossIntro, ending }

/// Qué hay detrás de cada carta-camino (críptico hasta elegir).
enum PathKind { combat, elite, shop, fragment }

/// Oferta de la tienda (CUARENTENA): una carta a comprar por créditos.
class ShopOffer {
  final String cardId;
  final int price;
  const ShopOffer(this.cardId, this.price);
}

class AdventureController extends ChangeNotifier {
  final AdventureState st;
  final Random _rng;

  AdvStep step = AdvStep.path;

  // Elección de camino: las 3 cartas crípticas.
  List<PathKind> paths = const [];

  // Combate actual.
  EnemyProc? enemy;
  bool isBoss = false;
  String preLore = '';
  int combatYouBonus = 0; // modificador de integridad para TI este combate (curse)
  int combatOppBonus = 0; // modificador de integridad para el rival (jefe blindado)
  String modLabel = ''; // telegrafía del modificador (vacío = ninguno)

  // Draft de recompensa.
  List<String> rewardChoices = const [];

  // Fragmento / mutación.
  FragmentDef? frag;
  bool isMutation = false;
  List<NatureDef> mutationChoices = const [];

  // Tienda.
  List<ShopOffer> shopOffers = const [];

  // Mini-evento (monólogo del rol) y final.
  String eventText = '';
  String endingId = '';

  AdventureController(this.st, {int? seed}) : _rng = seed != null ? Random(seed) : Random() {
    _decideNext();
  }

  // ── Decisión del siguiente nodo (run-points / jefes / mini-eventos) ──
  void _decideNext() {
    enemy = null;
    isBoss = false;
    // 1) Jefe en run-points 10/20/30/40/50 (si no hay cooldown).
    if (st.bossCooldown == 0 &&
        st.bossesDone < kBossCount &&
        st.runPoints >= (st.bossesDone + 1) * kCheckpointStep) {
      _toBossIntro();
      return;
    }
    // 2) Mini-evento: tu rol "habla" en 5/10/.../45 (1 vez por umbral).
    final ev = st.pendingEvent();
    if (ev != null) {
      _toEvent(ev);
      return;
    }
    // 3) Elección de 3 caminos.
    _toPath();
  }

  void _toPath() {
    paths = [for (var i = 0; i < 3; i++) _rollPath()];
    step = AdvStep.path;
    notifyListeners();
  }

  PathKind _rollPath() {
    final r = _rng.nextInt(100);
    if (r < 50) return PathKind.combat;
    if (r < 70) return PathKind.shop;
    if (r < 90) return PathKind.fragment;
    return _tier >= 1 ? PathKind.elite : PathKind.combat; // sin élites tan temprano
  }

  // ── Mini-evento (monólogo del rol) ──
  void _toEvent(int t) {
    final idx = kMiniEventPoints.indexOf(t).clamp(0, st.nature.monologues.length - 1);
    eventText = st.nature.monologues[idx];
    st.markEventFired(t);
    step = AdvStep.event;
    notifyListeners();
  }

  /// Continúa tras leer el monólogo.
  void nextFromEvent() => _decideNext();

  /// El jugador elige una de las 3 cartas-camino.
  void choosePath(int i) {
    switch (paths[i.clamp(0, paths.length - 1)]) {
      case PathKind.combat:
        _toCombatIntro(elite: false);
      case PathKind.elite:
        _toCombatIntro(elite: true);
      case PathKind.shop:
        _toShop();
      case PathKind.fragment:
        _toFragment();
    }
  }

  // ── Combate ──
  void _clearMods() {
    combatYouBonus = 0;
    combatOppBonus = 0;
    modLabel = '';
  }

  int get _tier => enemyTier(subsUnlocked: st.subsUnlocked, bossesDone: st.bossesDone);

  void _toCombatIntro({required bool elite}) {
    final tier = _tier;
    final pool = elite ? eliteEnemies(tier) : combatEnemies(tier);
    enemy = pool[_rng.nextInt(pool.length)];
    isBoss = false;
    preLore = kPreCombatLore[_rng.nextInt(kPreCombatLore.length)];
    _clearMods();
    // Modificadores SOLO desde tier ≥1 (al inicio nada los hace más difícil).
    if (tier >= 1) {
      if (elite) {
        combatOppBonus = 1; // los daemon élite aguantan más
        modLabel = 'DAEMON REFORZADO · el rival empieza con +1 de integridad';
      } else if (_rng.nextInt(100) < 22) {
        combatYouBonus = -1; // proceso infectado: te debilita
        modLabel = 'PROCESO INFECTADO · empiezas con −1 de integridad';
        st.addCorruption(kCorruptInfected); // los caminos infectados corrompen
      }
    }
    if (st.corruption >= kCorruptEnemyBuffAt) {
      combatOppBonus += 1; // la corrupción alta hace que el vacío empuje
      modLabel = modLabel.isEmpty ? 'CORRUPCIÓN ALTA · el rival empieza con +1 de integridad' : '$modLabel  + CORRUPCIÓN';
    }
    step = AdvStep.loreIntro;
    notifyListeners();
  }

  void _toBossIntro() {
    final tier = _tier;
    enemy = bossForTier(tier);
    isBoss = true;
    preLore = enemy!.flavor;
    _clearMods();
    combatOppBonus = (tier >= 2 ? 2 : 1) + (st.corruption >= kCorruptEnemyBuffAt ? 1 : 0);
    modLabel = 'KERNEL BLINDADO · empieza con +$combatOppBonus de integridad';
    step = AdvStep.bossIntro;
    notifyListeners();
  }

  void _toEnding() {
    endingId = st.evaluateEnding();
    step = AdvStep.ending;
    notifyListeners();
  }

  /// Tras leer el lore, arranca el duelo (lo monta `main`).
  void startCombat() {
    step = AdvStep.combat;
    notifyListeners();
  }

  /// `main` avisa el resultado del duelo.
  void onCombatEnd(bool win) {
    if (isBoss) {
      st.recordBoss(win: win);
      if (win && st.bossesDone >= kBossCount) {
        _toEnding(); // venciste al 5º jefe → fin de la run
      } else {
        _decideNext();
      }
      return;
    }
    final elite = enemy?.elite ?? false;
    st.recordCombat(win: win, elite: elite);
    if (win) {
      _toReward();
    } else {
      _decideNext();
    }
  }

  // ── Recompensa (draft 1 de 3) ──
  void _toReward() {
    rewardChoices = _rewardCandidates();
    if (rewardChoices.isEmpty) {
      // Nada que ofrecer (todo al tope): compensa con créditos.
      st.addCredits(kRewardCredits);
      _decideNext();
      return;
    }
    step = AdvStep.reward;
    notifyListeners();
  }

  List<String> _rewardCandidates() {
    bool canOwn(String id) => !st.atCap(id);
    final lockedNew = <String>[]; // aún no posees → prioridad (desbloqueo)
    final more = <String>[]; // ya posees, no al tope → copia extra
    for (final id in kRutById.keys) {
      if (!canOwn(id)) continue;
      (st.owned(id) == 0 ? lockedNew : more).add(id);
    }
    if (st.subsUnlocked) {
      for (final id in kSubById.keys) {
        if (!canOwn(id)) continue;
        (st.owned(id) == 0 ? lockedNew : more).add(id);
      }
    }
    lockedNew.shuffle(_rng);
    more.shuffle(_rng);
    return [...lockedNew, ...more].take(3).toList();
  }

  /// El jugador elige una carta de recompensa (o null = saltar por créditos).
  void chooseReward(String? id) {
    if (id != null) {
      st.addCard(id);
    } else {
      st.addCredits(kRewardCredits);
    }
    _decideNext();
  }

  // ── Fragmento / Mutación ──
  void _toFragment() {
    // ~35% de las veces es una MUTACIÓN (cambia tu naturaleza → tu final).
    if (_rng.nextInt(100) < 35) {
      isMutation = true;
      frag = null;
      mutationChoices = mutationOptions(st.natureId);
    } else {
      isMutation = false;
      frag = kFragments[_rng.nextInt(kFragments.length)];
      mutationChoices = const [];
    }
    step = AdvStep.fragment;
    notifyListeners();
  }

  /// Resuelve un fragmento normal (A = efecto; B = nada).
  void chooseFragment(bool optionA) {
    final f = frag;
    if (f != null && optionA) _applyEffect(f.optAEffect);
    if (f != null && !optionA) _applyEffect(f.optBEffect);
    _decideNext();
  }

  /// Resuelve una MUTACIÓN (cambia de naturaleza, o conserva la actual).
  void chooseMutation(String? natureId) {
    if (natureId != null) st.setNature(natureId);
    _decideNext();
  }

  void _applyEffect(String effect) {
    if (effect.startsWith('credits:+')) {
      st.addCredits(int.tryParse(effect.substring('credits:+'.length)) ?? 0);
    }
    // 'none' u otros efectos futuros → sin acción.
  }

  // ── Tienda ──
  void _toShop() {
    shopOffers = _genOffers();
    step = AdvStep.shop;
    notifyListeners();
  }

  List<ShopOffer> _genOffers() {
    final pool = <String>[];
    for (final id in kRutById.keys) {
      if (!st.atCap(id)) pool.add(id);
    }
    if (st.subsUnlocked) {
      for (final id in kSubById.keys) {
        if (!st.atCap(id)) pool.add(id);
      }
    }
    pool.shuffle(_rng);
    return [for (final id in pool.take(4)) ShopOffer(id, _priceFor(id))];
  }

  int _priceFor(String id) {
    if (kSubById.containsKey(id)) return 8;
    // Rutina: básica barata, avanzada cara.
    const advanced = {'fw_iron', 'xp_zero', 'pl_emp', 'null_sh'};
    return advanced.contains(id) ? 14 : 4;
  }

  /// Compra una oferta si hay créditos y no está al tope. Devuelve true si se compró.
  bool buy(ShopOffer offer) {
    if (st.atCap(offer.cardId) || st.credits < offer.price) return false;
    if (!st.spend(offer.price)) return false;
    st.addCard(offer.cardId);
    notifyListeners();
    return true;
  }

  /// Salir de la tienda continúa la run.
  void leaveShop() => _decideNext();
}
