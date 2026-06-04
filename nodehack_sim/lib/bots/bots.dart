/// Políticas de bot. SOLO usan la `PublicView` (jamás la mano del rival).
library;

import '../engine/data.dart';
import '../engine/decider.dart';
import '../engine/models.dart';
import '../engine/rng.dart';

/// El tipo que vence a [t].  (cortafuegos vence exploit; exploit vence pulso; pulso vence cortafuegos)
Tipo venceA(Tipo t) => switch (t) {
      Tipo.exploit => Tipo.cortafuegos,
      Tipo.pulso => Tipo.exploit,
      Tipo.cortafuegos => Tipo.pulso,
    };

Tipo? _masFrecuente(List<Tipo> h) {
  if (h.isEmpty) return null;
  final c = <Tipo, int>{};
  for (final t in h) c[t] = (c[t] ?? 0) + 1;
  return c.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

/// Elige una Rutina de la mano que pueda presentar [deseado]; prefiere no-comodín
/// del tipo (mayor Ciclos) y, si no, un comodín.
(RutinaId, Tipo)? _rutinaPara(List<RutinaId> mano, Tipo deseado) {
  RutinaId? best;
  var bestCic = -1;
  for (final id in mano) {
    final r = rutinaDe(id);
    if (!r.esComodin && r.tipoBase == deseado && r.ciclos > bestCic) {
      best = id;
      bestCic = r.ciclos;
    }
  }
  if (best != null) return (best, deseado);
  for (final id in mano) {
    if (rutinaDe(id).esComodin) return (id, deseado);
  }
  return null;
}

/// Jugada base segura (primera Rutina de la mano, sin subrutinas).
Play _base(PublicView v) {
  final id = v.miMano.first;
  final r = rutinaDe(id);
  final tipo = r.esComodin ? Tipo.values[0] : r.tipoBase!;
  return Play(rutina: id, tipoDeclarado: tipo);
}

/// Toma de [deseadas] (por prioridad) las que estén en mano y quepan en [ram] (máx 2).
List<SubId> _tomarSubs(List<SubId> mano, List<SubId> deseadas, int ram) {
  final disp = List.of(mano);
  final out = <SubId>[];
  var coste = 0;
  for (final s in deseadas) {
    if (out.length >= 2) break;
    if (!disp.remove(s)) continue;
    final c = subDe(s).costeRam;
    if (coste + c > ram) continue;
    coste += c;
    out.add(s);
  }
  return out;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Bot aleatorio legal (baseline).
class RandomBot implements Decider {
  @override
  String get nombre => 'random';

  @override
  Play decide(PublicView v, Rng rng) {
    final id = v.miMano[rng.nextInt(v.miMano.length)];
    final r = rutinaDe(id);
    final tipo = r.esComodin ? Tipo.values[rng.nextInt(3)] : r.tipoBase!;
    final subs = List.of(v.miSubs);
    rng.shuffle(subs);
    final elegidas = _tomarSubs(subs, subs, v.ramDisponible);
    return Play(
      rutina: id,
      tipoDeclarado: tipo,
      subs: elegidas,
      rotacionObjetivo: rng.nextBool() ? RotacionObjetivo.propia : RotacionObjetivo.rival,
      usarPasiva: v.pasivaDisponible && rng.nextInt(6) == 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Predice el tipo más frecuente del rival y juega para vencerlo. Castiga repeticiones.
class CounterFrequencyBot implements Decider {
  @override
  String get nombre => 'counter';

  @override
  Play decide(PublicView v, Rng rng) {
    if (v.miMano.isEmpty) return _base(v);
    final pred = _masFrecuente(v.rivalHistorialTipos) ??
        v.rivalUltimoTipo ??
        Tipo.values[rng.nextInt(3)];
    final deseado = venceA(pred);

    var sel = _rutinaPara(v.miMano, deseado);
    sel ??= (v.miMano.first, _tipoDe(v.miMano.first, deseado));
    final (rutina, tipo) = sel;

    // Wishlist de subrutinas según situación.
    final wish = <SubId>[];
    final rivalRepite = v.rivalUltimoTipo != null && v.rivalUltimoTipo == pred;
    if (rivalRepite) wish.add(SubId.loopback); // anula su repetición
    wish.add(SubId.overclock); // ayuda en espejos
    if (v.miIntegridad < v.rivalIntegridad) wish.add(SubId.parche);
    wish.add(SubId.throttle);

    final subs = _tomarSubs(v.miSubs, wish, v.ramDisponible);
    return Play(
      rutina: rutina,
      tipoDeclarado: tipo,
      subs: subs,
      rotacionObjetivo: RotacionObjetivo.propia,
      usarPasiva: false,
    );
  }

  Tipo _tipoDe(RutinaId id, Tipo deseado) {
    final r = rutinaDe(id);
    return r.esComodin ? deseado : r.tipoBase!;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Heurístico: predice, evita repetir (esquiva Loopback), usa subrutinas y pasiva
/// con criterio, gestiona la RAM.
class HeuristicBot implements Decider {
  @override
  String get nombre => 'heuristic';

  @override
  Play decide(PublicView v, Rng rng) {
    if (v.miMano.isEmpty) return _base(v);

    final pred = _masFrecuente(v.rivalHistorialTipos) ??
        v.rivalUltimoTipo ??
        Tipo.values[rng.nextInt(3)];
    var deseado = venceA(pred);

    // Esquivar Loopback: si vencer al pronóstico me haría repetir mi último tipo,
    // a veces cambio a otra opción para no ser predecible.
    final miUltimo = v.miHistorialTipos.isEmpty ? null : v.miHistorialTipos.last;
    if (deseado == miUltimo && rng.nextBool()) {
      deseado = deseado.siguiente; // varío
    }

    var sel = _rutinaPara(v.miMano, deseado);
    final esperoPerder = sel == null; // no puedo presentar el tipo que quiero
    sel ??= _rutinaPara(v.miMano, miUltimo == null ? deseado : deseado) ??
        (v.miMano.first, _tipoDe(v.miMano.first, deseado));
    final (rutina, tipo) = sel;

    final rutinaCard = rutinaDe(rutina);
    final espejoProbable = tipo == pred; // si presento el mismo tipo que pronostico

    final wish = <SubId>[];
    final rivalRepite = v.rivalUltimoTipo != null && v.rivalUltimoTipo == pred;
    if (rivalRepite) wish.add(SubId.loopback);
    if (espejoProbable) wish.add(SubId.overclock); // gano el espejo por Ciclos
    if (esperoPerder && v.miIntegridad <= v.rivalIntegridad) {
      wish.add(SubId.cuarentena); // niego la ronda que creo perder
      wish.add(SubId.parche);
    }
    wish.add(SubId.throttle);
    wish.add(SubId.escudo);

    final subs = _tomarSubs(v.miSubs, wish, v.ramDisponible);

    // Pasiva (1×) con criterio.
    var pasiva = false;
    if (v.pasivaDisponible) {
      switch (v.miNucleo) {
        case NucleoId.relay:
          pasiva = v.miMano.length <= 1; // robar cuando faltan rutinas
        case NucleoId.corrupted:
          pasiva = espejoProbable; // +5 Ciclos gana el espejo
        case NucleoId.warden:
          pasiva = v.rivalIntegridad - v.miIntegridad >= 2; // blanquear sub clave
        case NucleoId.nullCore:
          pasiva = !esperoPerder && v.rivalIntegridad <= 2; // CORRUPCIÓN para −2 letal
      }
    }

    return Play(
      rutina: rutina,
      tipoDeclarado: rutinaCard.esComodin ? tipo : rutinaCard.tipoBase!,
      subs: subs,
      rotacionObjetivo: RotacionObjetivo.propia,
      usarPasiva: pasiva,
    );
  }

  Tipo _tipoDe(RutinaId id, Tipo deseado) {
    final r = rutinaDe(id);
    return r.esComodin ? deseado : r.tipoBase!;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Bot fuerte. Filosofía:
///  - TIPO: mezclado (cuasi-aleatorio) para ser **inexplotable**; solo se inclina a
///    contrar si el rival muestra un sesgo claro y explotable (lectura real).
///  - CARTAS: despliega el kit por **valor esperado** (no acapara): Fork-Bomb cuando
///    no va por detrás, Overclock en espejos, Escudo vs caos, Parche al ir perdiendo,
///    Recovery para ventaja de cartas. Esto es lo que vence al azar.
class SmartBot implements Decider {
  @override
  String get nombre => 'smart';

  @override
  Play decide(PublicView v, Rng rng) {
    if (v.miMano.isEmpty) return _base(v);

    // ── TIPO ──
    Tipo pred = _prediccion(v, rng);
    final miUltimo = v.miHistorialTipos.isEmpty ? null : v.miHistorialTipos.last;
    final explotable = _sesgoExplotable(v);
    if (miUltimo != null && _rivalContraataca(v, miUltimo)) {
      pred = venceA(miUltimo);
    }
    var deseado = venceA(pred);
    // Si el rival NO es explotable, juego casi aleatorio (inexplotable).
    if (!explotable && rng.nextInt(3) != 0) deseado = Tipo.values[rng.nextInt(3)];

    var sel = _rutinaPara(v.miMano, deseado);
    final esperoPerder = sel == null;
    sel ??= (v.miMano.first, _tipoDe(v.miMano.first, deseado));
    final (rutina, tipo) = sel;
    final rCard = rutinaDe(rutina);
    final espejoProbable = tipo == pred;
    final behind = v.miIntegridad < v.rivalIntegridad;
    final rivalCaos = v.rivalNucleo == NucleoId.nullCore;

    // ── CARTAS: desplegar el kit (no acaparar) por prioridad situacional. ──
    final wish = <SubId>[];
    if (espejoProbable) wish.add(SubId.overclock);
    if (rivalCaos) wish.add(SubId.escudo); // bloquea GLITCH/ROTACIÓN/THROTTLE
    if (v.rivalUltimoTipo != null && v.rivalUltimoTipo == pred) wish.add(SubId.loopback);
    if (!behind) wish.add(SubId.forkBomb); // valor proactivo (−2 al ganar)
    if (behind) {
      wish.add(SubId.parche);
      wish.add(SubId.cuarentena);
    }
    // Relleno de RAM sobrante (usar el kit es mejor que acaparar).
    wish.add(SubId.recovery);
    wish.add(SubId.overclock);
    wish.add(SubId.throttle);
    wish.add(SubId.escudo);

    final subs = _tomarSubs(v.miSubs, wish, v.ramDisponible);

    // ── PASIVA ──
    var pasiva = false;
    if (v.pasivaDisponible) {
      switch (v.miNucleo) {
        case NucleoId.relay:
          pasiva = v.miMano.length <= 1;
        case NucleoId.corrupted:
          pasiva = espejoProbable || (!esperoPerder && v.rivalIntegridad <= 2);
        case NucleoId.warden:
          pasiva = v.rivalIntegridad - v.miIntegridad >= 2;
        case NucleoId.nullCore:
          pasiva = !esperoPerder && v.rivalIntegridad <= 2;
      }
    }

    return Play(
      rutina: rutina,
      tipoDeclarado: rCard.esComodin ? tipo : rCard.tipoBase!,
      subs: subs,
      rotacionObjetivo: RotacionObjetivo.propia,
      usarPasiva: pasiva,
    );
  }

  Tipo _prediccion(PublicView v, Rng rng) {
    final h = v.rivalHistorialTipos;
    if (h.isEmpty) return v.rivalUltimoTipo ?? Tipo.values[rng.nextInt(3)];
    final peso = <Tipo, double>{};
    for (var i = 0; i < h.length; i++) {
      peso[h[i]] = (peso[h[i]] ?? 0) + (i + 1);
    }
    return peso.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// ¿El rival tiene un sesgo de tipo claramente explotable? (un tipo domina su historial)
  bool _sesgoExplotable(PublicView v) {
    final h = v.rivalHistorialTipos;
    if (h.length < 3) return false;
    final c = <Tipo, int>{};
    for (final t in h) c[t] = (c[t] ?? 0) + 1;
    final maxN = c.values.reduce((a, b) => a > b ? a : b);
    return maxN / h.length >= 0.5; // un tipo es ≥50% de sus jugadas
  }

  bool _rivalContraataca(PublicView v, Tipo miUltimo) {
    final mh = v.miHistorialTipos;
    final rh = v.rivalHistorialTipos;
    if (mh.length < 3 || rh.length < 3) return false;
    var aciertos = 0, total = 0;
    for (var i = 1; i < mh.length && i < rh.length; i++) {
      total++;
      if (rh[i] == venceA(mh[i - 1])) aciertos++;
    }
    return total > 0 && aciertos / total >= 0.5;
  }

  Tipo _tipoDe(RutinaId id, Tipo deseado) {
    final r = rutinaDe(id);
    return r.esComodin ? deseado : r.tipoBase!;
  }
}

/// Fábrica por nombre.
Decider botPorNombre(String n) => switch (n) {
      'random' => RandomBot(),
      'counter' => CounterFrequencyBot(),
      'heuristic' => HeuristicBot(),
      'smart' => SmartBot(),
      _ => SmartBot(),
    };
