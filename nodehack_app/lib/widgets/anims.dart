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

/// "Materialización" digital de una carta: se construye de arriba a abajo con
/// una línea de escaneo cian, parpadeo y tinte que se disipa. Con [reverse]
/// hace lo contrario (desmaterializar, p. ej. al rebarajar la mano).
/// [delay] (0..1) retrasa el inicio dentro de la propia animación (escalonado).
class Materialize extends StatelessWidget {
  final Widget child;
  final bool reverse;
  final double delay;
  final Duration duration;
  const Materialize({
    super.key,
    required this.child,
    this.reverse = false,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 420),
  });

  @override
  Widget build(BuildContext context) {
    return OneShot(
      duration: duration,
      curve: Curves.linear,
      builder: (ctx, raw) {
        // Aplica el retraso re-mapeando t; en reversa el progreso corre al revés.
        var t = delay >= 1 ? raw : ((raw - delay) / (1 - delay)).clamp(0.0, 1.0);
        if (reverse) t = 1 - t;
        if (t >= 1) return child;
        if (t <= 0) return Opacity(opacity: 0, child: child);
        // Parpadeo de "señal inestable" mientras se construye.
        final flicker = t < .75 ? (sin(t * 46) > 0 ? .9 : .55) : 1.0;
        return Opacity(
          opacity: (t * 1.6).clamp(0.0, 1.0) * flicker,
          child: ClipRect(
            clipper: _RevealClipper(t),
            child: Stack(children: [
              child,
              // Tinte cian que se disipa + línea de escaneo en el borde del reveal.
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _ScanPainter(t)),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

/// Recorta el alto de 0 → completo (revela de arriba hacia abajo) sin afectar layout.
class _RevealClipper extends CustomClipper<Rect> {
  final double t;
  _RevealClipper(this.t);
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width, size.height * t);
  @override
  bool shouldReclip(covariant _RevealClipper old) => old.t != t;
}

/// Tinte + línea de escaneo de la materialización.
class _ScanPainter extends CustomPainter {
  final double t;
  _ScanPainter(this.t);
  static const _cyan = Color(0xFF3FC7EC);
  @override
  void paint(Canvas canvas, Size size) {
    // Tinte cian que se disipa según avanza.
    canvas.drawRect(Offset.zero & size, Paint()..color = _cyan.withValues(alpha: .22 * (1 - t)));
    // Línea brillante en el borde del reveal.
    final y = size.height * t;
    canvas.drawRect(Rect.fromLTWH(0, y - 2.5, size.width, 2.5),
        Paint()..color = _cyan.withValues(alpha: .85)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  }

  @override
  bool shouldRepaint(covariant _ScanPainter old) => old.t != t;
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
  // 90 ms de hit-stop (congelado) + ~560 ms de sacudida con decaimiento cuadrático.
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

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
        // Hit-stop: nada se mueve hasta pasar el ~14% (≈90 ms).
        final s = t <= .14 ? 0.0 : ((t - .14) / .86);
        final decay = (1 - s) * (1 - s); // cuadrático
        final dx = s > 0 && s < 1 ? sin(s * pi * 7) * decay * 9 : 0.0;
        final dy = s > 0 && s < 1 ? cos(s * pi * 5) * decay * 5 : 0.0;
        final rot = s > 0 && s < 1 ? sin(s * pi * 6) * decay * 0.014 : 0.0;
        // Flash con dos pulsos (impacto + rebote menor).
        final f1 = t == 0 ? 0.0 : (t < .20 ? t / .20 : (1 - (t - .20) / .80)).clamp(0.0, 1.0);
        final f2 = (t > .45 && t < .62) ? sin((t - .45) / .17 * pi) : 0.0;
        final flash = (f1 * .38).clamp(0.0, .38) + (f2 * .16).clamp(0.0, .16);
        return Stack(children: [
          Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(angle: rot, child: child),
          ),
          if (flash > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: RadialGradient(
                      colors: [const Color(0xFFFF4068).withValues(alpha: flash), Colors.transparent],
                      stops: const [0, .7],
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
