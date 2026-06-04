/// Sigilos geométricos por tipo (SVG inline portado de game-cards.jsx).
library;

import 'package:flutter/material.dart';

import 'package:nodehack_engine/types.dart';

class Sigil extends StatelessWidget {
  final CType type;
  final double size;
  const Sigil({super.key, required this.type, this.size = 44});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _SigilPainter(type)),
      );
}

class _SigilPainter extends CustomPainter {
  final CType type;
  _SigilPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 48.0;
    final c = Color(type.color);
    Offset p(double x, double y) => Offset(x * k, y * k);
    Paint stroke(double w, [double opacity = 1]) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * k
      ..color = c.withValues(alpha: opacity)
      ..strokeCap = StrokeCap.round;
    Paint fill([double opacity = 1]) => Paint()..color = c.withValues(alpha: opacity);

    switch (type) {
      case CType.firewall:
        final hex = Path()
          ..moveTo(24 * k, 4 * k)
          ..lineTo(42 * k, 13 * k)
          ..lineTo(42 * k, 33 * k)
          ..lineTo(24 * k, 44 * k)
          ..lineTo(6 * k, 33 * k)
          ..lineTo(6 * k, 13 * k)
          ..close();
        canvas.drawPath(hex, stroke(2.2));
        canvas.drawLine(p(11, 20), p(37, 20), stroke(1.6, .75));
        canvas.drawLine(p(11, 28), p(37, 28), stroke(1.6, .75));
        canvas.drawLine(p(24, 13), p(24, 20), stroke(1.6, .5));
        canvas.drawLine(p(17, 20), p(17, 28), stroke(1.6, .5));
        canvas.drawLine(p(31, 20), p(31, 28), stroke(1.6, .5));
      case CType.exploit:
        canvas.drawLine(p(10, 10), p(38, 38), stroke(3));
        canvas.drawLine(p(38, 10), p(10, 38), stroke(3));
        canvas.drawCircle(p(24, 24), 4.5 * k, fill());
      case CType.signal:
        canvas.drawCircle(p(24, 24), 3.5 * k, fill());
        canvas.drawArc(Rect.fromCircle(center: p(24, 24), radius: 11 * k),
            -1.05, 2.1, false, stroke(2.2));
        canvas.drawArc(Rect.fromCircle(center: p(24, 24), radius: 11 * k),
            3.14 - 1.05, 2.1, false, stroke(2.2));
        canvas.drawArc(Rect.fromCircle(center: p(24, 24), radius: 18 * k),
            -1.05, 2.1, false, stroke(2, .55));
        canvas.drawArc(Rect.fromCircle(center: p(24, 24), radius: 18 * k),
            3.14 - 1.05, 2.1, false, stroke(2, .55));
      case CType.nul:
        final outer = Path()
          ..moveTo(24 * k, 6 * k)
          ..lineTo(42 * k, 24 * k)
          ..lineTo(24 * k, 42 * k)
          ..lineTo(6 * k, 24 * k)
          ..close();
        canvas.drawPath(outer, stroke(2.4));
        final inner = Path()
          ..moveTo(24 * k, 16 * k)
          ..lineTo(32 * k, 24 * k)
          ..lineTo(24 * k, 32 * k)
          ..lineTo(16 * k, 24 * k)
          ..close();
        canvas.drawPath(inner, fill(.85));
    }
  }

  @override
  bool shouldRepaint(covariant _SigilPainter old) => old.type != type;
}
