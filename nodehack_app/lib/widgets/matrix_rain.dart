/// Lluvia de código "Matrix" de fondo (portado de game-matrix.jsx).
/// Incluye un MENSAJE OCULTO de Lore que "cae" periódicamente en una columna.
library;

import 'dart:math';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

const _glyphs =
    '01{}/<>;:[]()=+*#\$%&∅01アカサタナハマヤラワabcdef0123456789';

class MatrixRain extends StatefulWidget {
  final double intensity; // 1..10
  final Color color;
  final String message; // mensaje de Lore oculto
  final double opacity;
  const MatrixRain({
    super.key,
    this.intensity = 4,
    this.color = NH.fw,
    this.message = '',
    this.opacity = .6,
  });

  @override
  State<MatrixRain> createState() => _MatrixRainState();
}

class _Drop {
  double y;
  bool on;
  double speed;
  _Drop(this.y, this.on, this.speed);
}

class _MatrixRainState extends State<MatrixRain> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: widget.opacity,
        child: ShaderMask(
          // máscara radial: se desvanece hacia los bordes.
          shaderCallback: (rect) => RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.1,
            colors: const [Colors.white, Colors.white, Colors.transparent],
            stops: const [0, .55, 1],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: CustomPaint(
            size: Size.infinite,
            painter: _MatrixPainter(_ctrl, widget.intensity, widget.color, widget.message),
          ),
        ),
      ),
    );
  }
}

class _MatrixPainter extends CustomPainter {
  final double intensity;
  final Color color;
  final String message;
  final List<_Drop> _drops = [];
  final _rnd = Random();
  static const double font = 14;
  int _frame = 0;

  // mensaje cayendo
  int _msgCol = -1, _msgRow = 0, _msgIdx = 0, _sinceMsg = 200;

  _MatrixPainter(Listenable repaint, this.intensity, this.color, this.message)
      : super(repaint: repaint);

  double get _activeFrac => 0.32 + (intensity / 10) * 0.6;

  void _ensure(int cols, double rows) {
    if (_drops.length == cols) return;
    _drops.clear();
    for (var i = 0; i < cols; i++) {
      _drops.add(_Drop(_rnd.nextDouble() * rows, _rnd.nextDouble() < _activeFrac,
          0.55 + _rnd.nextDouble() * 0.5 + intensity * 0.04));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cols = (size.width / font).floor();
    final rows = size.height / font;
    _ensure(cols, rows);
    _frame++;

    for (var i = 0; i < cols; i++) {
      final d = _drops[i];
      if (!d.on) continue;
      final x = i * font + font / 2;
      final y = d.y * font;

      // estela: haz vertical degradado (transparente arriba → color abajo).
      final beam = Rect.fromLTWH(x - font * 0.45, y - font * 12, font * 0.9, font * 12);
      canvas.drawRect(
        beam,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, color.withValues(alpha: .32)],
          ).createShader(beam),
      );
      // glifo de color tras la cabeza.
      _glyph(canvas, x, y - font, color.withValues(alpha: .55), false);
      // cabeza brillante.
      _glyph(canvas, x, y, const Color(0xFFDFFAFF), true);

      if (_frame.isEven || intensity > 6) d.y += d.speed;
      if (y > size.height + font * 2) {
        d.y = _rnd.nextDouble() * -30;
        d.on = _rnd.nextDouble() < _activeFrac;
        d.speed = 0.55 + _rnd.nextDouble() * 0.5 + intensity * 0.04;
      }
    }

    _drawMessage(canvas, size, cols);
    if (_frame > 100000) _frame = 0;
  }

  void _drawMessage(Canvas canvas, Size size, int cols) {
    if (message.isEmpty) return;
    _sinceMsg++;
    if (_msgCol < 0 && _sinceMsg > 240) {
      _msgCol = 1 + _rnd.nextInt(cols - 2);
      _msgRow = 0;
      _msgIdx = 0;
      _sinceMsg = 0;
    }
    if (_msgCol < 0) return;
    final x = _msgCol * font + font / 2;
    for (var k = 0; k <= _msgIdx && k < message.length; k++) {
      final yy = (_msgRow - (_msgIdx - k)) * font;
      final fade = 1 - (_msgIdx - k) * 0.12;
      if (fade <= 0 || yy < 0) continue;
      _text(canvas, message[k], x, yy, Color(color.toARGB32()).withValues(alpha: 1), glow: true, bright: true, op: fade);
    }
    if (_frame % 4 == 0) {
      _msgRow++;
      if (_msgRow - _msgIdx > 0 && _msgIdx < message.length - 1) {
        _msgIdx++;
      } else if (_msgIdx >= message.length - 1) {
        _msgIdx++;
      }
      if ((_msgRow - message.length) * font > size.height) _msgCol = -1;
    }
  }

  final Map<String, TextPainter> _cacheHead = {};
  final Map<String, TextPainter> _cacheTrail = {};

  void _glyph(Canvas canvas, double cx, double cy, Color c, bool head) {
    final g = _glyphs[_rnd.nextInt(_glyphs.length)];
    _text(canvas, g, cx, cy, c, glow: head, bright: head);
  }

  void _text(Canvas canvas, String g, double cx, double cy, Color c,
      {bool glow = false, bool bright = false, double op = 1}) {
    final cache = bright ? _cacheHead : _cacheTrail;
    var tp = cache[g];
    if (tp == null) {
      tp = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: g,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: font,
            color: bright ? const Color(0xFFDFFAFF) : c,
            shadows: glow ? [Shadow(color: color, blurRadius: 8)] : null,
          ),
        ),
      )..layout();
      cache[g] = tp;
    }
    final o = Offset(cx - tp.width / 2, cy - tp.height);
    if (op < 1) {
      canvas.saveLayer(
          Rect.fromLTWH(o.dx - 2, o.dy - 2, tp.width + 4, tp.height + 4),
          Paint()..color = Color.fromRGBO(255, 255, 255, op.clamp(0, 1)));
      tp.paint(canvas, o);
      canvas.restore();
    } else {
      tp.paint(canvas, o);
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixPainter old) => true;
}
