/// Mazo: 10 Rutinas + 20 Subrutinas (por conteo de id). Construcción, validación,
/// persistencia (JSON) y robo de mano desde el mazo real.
library;

import 'dart:math';

import 'card_instance.dart';
import 'cards.dart';

class Deck {
  String name;
  String nucleoId; // cada mazo lleva su propio Núcleo
  final Map<String, int> rut; // id de Rutina -> copias
  final Map<String, int> sub; // id de Subrutina -> copias

  Deck({required this.name, this.nucleoId = 'sentinel', Map<String, int>? rut, Map<String, int>? sub})
      : rut = rut ?? {},
        sub = sub ?? {};

  int get rutCount => rut.values.fold(0, (a, b) => a + b);
  int get subCount => sub.values.fold(0, (a, b) => a + b);

  bool get isLegal =>
      rutCount == kRutTarget &&
      subCount == kSubTarget &&
      rut.values.every((n) => n <= kMaxRutCopies) &&
      sub.values.every((n) => n <= kMaxSubCopies);

  /// Legalidad RELAJADA para el modo Inmersión (mazos pequeños mientras desbloqueas
  /// cartas): basta con ≥[kAdvMinRut] Rutinas; las Subrutinas son opcionales. Respeta
  /// los topes de copias.
  bool get isLegalAdventure =>
      rutCount >= kAdvMinRut &&
      rut.values.every((n) => n <= kMaxRutCopies) &&
      sub.values.every((n) => n <= kMaxSubCopies);

  /// Construye las 30 instancias del mazo.
  List<CardInstance> buildRutinas() => [
        for (final e in rut.entries)
          for (var i = 0; i < e.value; i++) CardInstance.rutina(kRutById[e.key]!)
      ];
  List<CardInstance> buildSubs() => [
        for (final e in sub.entries)
          for (var i = 0; i < e.value; i++) CardInstance.subrutina(kSubById[e.key]!)
      ];

  /// Roba una mano: `rutN` Rutinas + `subN` Subrutinas desde el mazo (con reposición
  /// por ronda — el prototipo no agota el mazo). Garantiza al menos 1 Rutina.
  List<CardInstance> drawHand(Random rng, {int rutN = 2, int subN = 3}) {
    final rutinas = buildRutinas()..shuffle(rng);
    final subs = buildSubs()..shuffle(rng);
    final hand = <CardInstance>[];
    hand.addAll(rutinas.take(rutN.clamp(1, rutinas.length)));
    hand.addAll(subs.take(subN.clamp(0, subs.length)));
    if (!hand.any((c) => !c.isSub) && rutinas.isNotEmpty) hand.add(rutinas.first);
    return hand;
  }

  Map<String, dynamic> toJson() => {'name': name, 'nucleo': nucleoId, 'rut': rut, 'sub': sub};

  factory Deck.fromJson(Map<String, dynamic> j) => Deck(
        name: j['name'] as String? ?? 'MAZO',
        nucleoId: j['nucleo'] as String? ?? 'sentinel',
        rut: Map<String, int>.from((j['rut'] as Map?) ?? {}),
        sub: Map<String, int>.from((j['sub'] as Map?) ?? {}),
      );

  Deck copy() => Deck(name: name, nucleoId: nucleoId, rut: Map.of(rut), sub: Map.of(sub));

  /// Mazo inicial sugerido (legal) para arrancar rápido.
  factory Deck.starter([String name = 'MAZO BASE']) => Deck(
        name: name,
        nucleoId: 'sentinel',
        rut: {'fw_base': 3, 'xp_base': 3, 'pl_base': 2, 'xp_zero': 1, 'null_sh': 1},
        sub: {'overclock': 3, 'throttle': 3, 'cuarentena': 2, 'mirror': 2, 'sigkill': 1, 'forkbomb': 1, 'shift_fwd': 2, 'shift_back': 2, 'shift_opp_back': 2, 'shift_you_fwd': 2},
      );
}
