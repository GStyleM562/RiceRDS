/// PRNG determinista (splitmix64). Reproducible: misma semilla ⇒ misma secuencia.
/// No usa DateTime ni Random global. Es la única fuente de azar del motor.
library;

class Rng {
  int _state;

  Rng(int seed) : _state = seed;

  int _next() {
    _state = (_state + 0x9E3779B97F4A7C15);
    var z = _state;
    z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9;
    z = (z ^ (z >>> 27)) * 0x94D049BB133111EB;
    return z ^ (z >>> 31);
  }

  /// Entero en [0, max).
  int nextInt(int max) {
    assert(max > 0);
    return (_next() & 0x7FFFFFFFFFFFFFFF) % max;
  }

  bool nextBool() => (_next() & 1) == 0;

  /// Fisher-Yates determinista in-place.
  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }

  /// Deriva una semilla hija estable (para sub-flujos por jugador/turno).
  int deriveSeed(int label) {
    final saved = _state;
    _state = saved ^ (label * 0x9E3779B97F4A7C15);
    final r = _next();
    _state = saved;
    return r;
  }
}
