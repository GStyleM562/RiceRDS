/// CPU: elige su jugada **solo desde su propia mano** (jamás ve la mano del jugador).
library;

import 'dart:math';

import 'card_instance.dart';
import 'resolve.dart';
import 'types.dart';

class Cpu {
  /// Elige una Rutina de su mano + 0–2 Subrutinas que quepan en [ramMax].
  Play chooseFor(List<CardInstance> hand, int ramMax, Random rng) {
    final rutinas = hand.where((c) => !c.isSub).toList();
    final rutina = rutinas[rng.nextInt(rutinas.length)];
    if (rutina.esComodinNull) {
      rutina.declaredType =
          [CType.firewall, CType.exploit, CType.signal][rng.nextInt(3)];
    }

    final subs = <CardInstance>[];
    final pool = hand.where((c) => c.isSub).toList()..shuffle(rng);
    var ramLeft = ramMax;
    // ~70% de las veces intenta usar subrutinas.
    if (rng.nextDouble() < 0.7) {
      for (final s in pool) {
        if (subs.length >= 2) break;
        if (s.ram <= ramLeft) {
          subs.add(s);
          ramLeft -= s.ram;
        }
      }
    }
    return Play(rutina, subs);
  }
}
