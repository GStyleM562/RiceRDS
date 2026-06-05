/// Mazo de robo de un jugador: pila de ROBO + pila de DESCARTE que se rebaraja
/// cuando la de robo se agota. **Recicla las mismas instancias** (nunca crea
/// copias nuevas), así que jamás existen más copias de una carta que las que
/// armaste en el mazo (p. ej. 3 PULSO siguen siendo 3 durante toda la partida).
library;

import 'dart:math';

import 'card_instance.dart';
import 'deck.dart';

class PileSet {
  final Random rng;
  final List<CardInstance> _drawRut;
  final List<CardInstance> _drawSub;
  final List<CardInstance> _discardRut = [];
  final List<CardInstance> _discardSub = [];

  PileSet(Deck deck, this.rng)
      : _drawRut = deck.buildRutinas(),
        _drawSub = deck.buildSubs() {
    _drawRut.shuffle(rng);
    _drawSub.shuffle(rng);
  }

  /// Cartas inmediatamente robables (lo que muestra el contador de la UI).
  int get rutLeft => _drawRut.length;
  int get subLeft => _drawSub.length;

  /// Roba una Rutina; si la pila de robo está vacía, rebaraja el descarte.
  /// Devuelve `null` solo si TODAS las copias están en mano/juego (no debería
  /// pasar con los topes del juego).
  CardInstance? drawRut() => _drawFrom(_drawRut, _discardRut);
  CardInstance? drawSub() => _drawFrom(_drawSub, _discardSub);

  CardInstance? _drawFrom(List<CardInstance> draw, List<CardInstance> discard) {
    if (draw.isEmpty) {
      if (discard.isEmpty) return null;
      draw.addAll(discard);
      discard.clear();
      draw.shuffle(rng);
    }
    return draw.isEmpty ? null : draw.removeLast();
  }

  /// Manda una carta jugada/descartada al descarte (se reciclará). Limpia el
  /// tipo declarado del NULL-SHARD para que vuelva "en blanco".
  void discard(CardInstance c) {
    c.declaredType = null;
    (c.isSub ? _discardSub : _discardRut).add(c);
  }
}
