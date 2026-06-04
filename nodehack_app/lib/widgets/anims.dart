/// Animaciones reutilizables (una sola pasada al montar + efecto de impacto).
library;

import 'dart:math';
import 'package:flutter/material.dart';

/// Reproduce una animación 0→1 UNA vez al montar. `builder(t)` recibe el progreso.
/// Regla del handoff: el estado base queda visible; solo animamos transform/opacity.
class OneShot extends StatefulWidget {
  final Duration duration;
  final Curve curve;
  final Widget Function(BuildContext context, double t) builder;
  const OneShot({super.key, required this.builder, this.duration = const Duration(milliseconds: 300), this.curve = Curves.easeOut});

  @override
  State<OneShot> createState() => _OneShotState();
}

class _OneShotState extends State<OneShot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)..forward();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: _c, builder: (ctx, _) => widget.builder(ctx, widget.curve.transform(_c.value)));
}

/// Sacudida + destello rojo cuando [active] pasa a true (daño recibido).
class HitEffects extends StatefulWidget {
  final bool active;
  final Widget child;
  const HitEffects({super.key, required this.active, required this.child});

  @override
  State<HitEffects> createState() => _HitEffectsState();
}

class _HitEffectsState extends State<HitEffects> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void didUpdateWidget(covariant HitEffects old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (ctx, child) {
        final t = _c.value;
        final dx = t > 0 && t < 1 ? sin(t * pi * 6) * (1 - t) * 7 : 0.0;
        final flash = t == 0 ? 0.0 : (t < .18 ? t / .18 : (1 - (t - .18) / .82)).clamp(0.0, 1.0);
        return Stack(children: [
          Transform.translate(offset: Offset(dx, 0), child: child),
          if (flash > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: RadialGradient(
                      colors: [const Color(0xFFFF4068).withValues(alpha: .30 * flash), Colors.transparent],
                      stops: const [0, .68],
                    ),
                  ),
                ),
              ),
            ),
        ]);
      },
      child: widget.child,
    );
  }
}
