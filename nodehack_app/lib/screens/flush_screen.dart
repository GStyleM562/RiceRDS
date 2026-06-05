import 'dart:math';

import 'package:flutter/material.dart';

import 'package:nodehack_engine/resolve.dart';

import '../theme/tokens.dart';
import '../widgets/chrome.dart';

class FlushScreen extends StatefulWidget {
  final String outcome; // 'win' | 'lose'
  final int round;
  final List<Winner> history;
  final String? reason; // 'opp_left' = rival se rindió/desconectó
  final VoidCallback onMenu;
  final VoidCallback onAgain;
  const FlushScreen({
    super.key,
    required this.outcome,
    required this.round,
    this.history = const [],
    this.reason,
    required this.onMenu,
    required this.onAgain,
  });

  @override
  State<FlushScreen> createState() => _FlushScreenState();
}

class _FlushScreenState extends State<FlushScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  final String _sig = '0x${Random().nextInt(0xFFFFFF).toRadixString(16).toUpperCase()}';

  bool get _win => widget.outcome == 'win';

  @override
  void initState() {
    super.initState();
    // La derrota tiene una intro más larga (apagado/desconexión); la victoria, breve.
    _intro = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _win ? 1100 : 2000),
    )..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = _win ? NH.pl : NH.xp;
    return AnimatedBuilder(
      animation: _intro,
      builder: (context, _) {
        final t = _intro.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(center: const Alignment(0, -.2), radius: 1.1, colors: [NH.a(glow, .10), NH.cardBg]),
          ),
          child: Stack(children: [
            const GridBg(),
            // Contenido (aparece cuando la intro va terminando).
            Positioned.fill(child: _content(t)),
            // Animación de apagado/desconexión del que perdió.
            if (!_win && t < .72) Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ShutdownPainter(t)))),
            // Destello de victoria.
            if (_win && t < .9) Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _VictoryPainter(t)))),
          ]),
        );
      },
    );
  }

  Widget _content(double t) {
    final glow = _win ? NH.pl : NH.xp;
    // El reporte "entra" expandiéndose desde una línea (sensación de reinicio).
    final reveal = _win ? Curves.easeOut.transform((t / .7).clamp(0.0, 1.0)) : ((t - .62) / .38).clamp(0.0, 1.0);
    if (reveal <= 0) return const SizedBox.shrink();
    final sy = (0.04 + 0.96 * reveal).clamp(0.04, 1.0);
    return Opacity(
      opacity: reveal,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(1.0, sy, 1.0),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Stack(alignment: Alignment.center, children: [
                Transform.translate(offset: const Offset(-3, 1), child: Text(_win ? 'FLUSH' : 'CORE DUMP', style: NH.disp(size: 46, weight: FontWeight.w700, color: NH.a(NH.xp, .5)))),
                Transform.translate(offset: const Offset(3, -1), child: Text(_win ? 'FLUSH' : 'CORE DUMP', style: NH.disp(size: 46, weight: FontWeight.w700, color: NH.a(NH.fw, .5)))),
                Text(_win ? 'FLUSH' : 'CORE DUMP', style: NH.disp(size: 46, weight: FontWeight.w700, color: Colors.white).copyWith(shadows: [Shadow(color: NH.a(glow, .6), blurRadius: 26)])),
              ]),
              const SizedBox(height: 10),
              Text(_subtitle(), textAlign: TextAlign.center, style: NH.mono(size: 11, color: NH.ink2, spacing: .6)),
              const SizedBox(height: 22),
              _stat('RESULTADO', _win ? 'VICTORIA' : 'DERROTA', _win ? NH.pl : NH.xp),
              const SizedBox(height: 8),
              _stat('RONDAS', widget.round.toString().padLeft(2, '0'), const Color(0xFFEAF1FB)),
              const SizedBox(height: 8),
              _stat('FIRMA', _sig, const Color(0xFFEAF1FB)),
              if (widget.history.isNotEmpty) ...[
                const SizedBox(height: 16),
                _historyStrip(),
              ],
              const SizedBox(height: 26),
              SizedBox(width: 300, child: BtnWide('REINTENTAR ▸', onTap: widget.onAgain)),
              const SizedBox(height: 10),
              SizedBox(width: 300, child: BtnWide('VOLVER AL MENÚ', variant: BtnVariant.ghost, onTap: widget.onMenu)),
            ]),
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    if (_win) {
      return widget.reason == 'opp_left'
          ? '> rival desconectado · ganas por abandono'
          : '> proceso rival purgado';
    }
    return widget.reason == 'opp_left' ? '> abandonaste el proceso' : '> tu proceso fue terminado';
  }

  // Historial ronda por ronda: un punto por ronda con el color del ganador.
  Widget _historyStrip() {
    final h = widget.history;
    final you = h.where((w) => w == Winner.you).length;
    final opp = h.where((w) => w == Winner.opp).length;
    return Container(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), color: NH.a(NH.panel, .5), border: Border.all(color: NH.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('HISTORIAL DE RONDAS', style: NH.mono(size: 9, color: NH.dim, spacing: 2)),
          Row(children: [
            Text('$you', style: NH.mono(size: 11, weight: FontWeight.w700, color: NH.pl)),
            Text(' · ', style: NH.mono(size: 11, color: NH.dim2)),
            Text('$opp', style: NH.mono(size: 11, weight: FontWeight.w700, color: NH.xp)),
          ]),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (var i = 0; i < h.length; i++) _roundDot(i + 1, h[i]),
          ],
        ),
      ]),
    );
  }

  Widget _roundDot(int n, Winner w) {
    final c = w == Winner.you ? NH.pl : (w == Winner.opp ? NH.xp : NH.amber);
    final glyph = w == Winner.you ? '▲' : (w == Winner.opp ? '▼' : '=');
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 22, height: 22, alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: NH.a(c, .16),
          border: Border.all(color: NH.a(c, .8)),
          boxShadow: [BoxShadow(color: NH.a(c, .35), blurRadius: 7)],
        ),
        child: Text(glyph, style: NH.mono(size: 10, weight: FontWeight.w700, color: c)),
      ),
      const SizedBox(height: 2),
      Text('$n', style: NH.mono(size: 7, color: NH.dim2)),
    ]);
  }

  Widget _stat(String k, String v, Color vc) => Container(
        constraints: const BoxConstraints(minWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: NH.a(NH.panel, .5), border: Border.all(color: NH.line)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k, style: NH.mono(size: 11, color: NH.dim, spacing: 1.4)),
          Text(v, style: NH.mono(size: 11, weight: FontWeight.w700, color: vc, spacing: .6)),
        ]),
      );
}

/// Apagado/desconexión del perdedor: estática roja violenta → colapso a una línea.
class _ShutdownPainter extends CustomPainter {
  final double t; // 0..0.72 (visible)
  _ShutdownPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final phase = (t / .72).clamp(0.0, 1.0); // 0..1 dentro de la intro de derrota
    if (phase < .62) {
      // Fase estática: bandas horizontales rojas/blancas que tiemblan.
      final rnd = Random((t * 120).floor());
      final bands = 22;
      for (var i = 0; i < bands; i++) {
        final y = rnd.nextDouble() * size.height;
        final h = 2 + rnd.nextDouble() * 14;
        final shade = rnd.nextDouble();
        final col = shade < .5
            ? NH.a(NH.xp, .25 + rnd.nextDouble() * .5)
            : NH.a(Colors.white, .06 + rnd.nextDouble() * .14);
        final dx = (rnd.nextDouble() - .5) * 18;
        canvas.drawRect(Rect.fromLTWH(dx, y, size.width, h), Paint()..color = col);
      }
      // Velo rojo de alerta que late.
      final pulse = .12 + .12 * sin(t * 40);
      canvas.drawRect(Offset.zero & size, Paint()..color = NH.a(NH.xp, pulse));
    } else {
      // Colapso CRT: todo se cierra a una línea brillante en el centro.
      final k = ((phase - .62) / .38).clamp(0.0, 1.0); // 0..1
      final half = (size.height / 2) * (1 - k);
      final paint = Paint()..color = Colors.black;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, half), paint);
      canvas.drawRect(Rect.fromLTWH(0, size.height - half, size.width, half), paint);
      final lineY = size.height / 2;
      final glow = Paint()
        ..color = NH.a(NH.xp, 1 - k * .3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRect(Rect.fromLTWH(0, lineY - 1.5, size.width, 3), glow);
      canvas.drawRect(Rect.fromLTWH(0, lineY - .8, size.width, 1.6), Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _ShutdownPainter old) => old.t != t;
}

/// Destello de victoria: anillo verde que se expande.
class _VictoryPainter extends CustomPainter {
  final double t;
  _VictoryPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final k = (t / .9).clamp(0.0, 1.0);
    final center = Offset(size.width / 2, size.height * .42);
    final r = k * size.width * .9;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * (1 - k)
      ..color = NH.a(NH.pl, (1 - k) * .8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, r, ring);
    canvas.drawRect(Offset.zero & size, Paint()..color = NH.a(NH.pl, (1 - k) * .10));
  }

  @override
  bool shouldRepaint(covariant _VictoryPainter old) => old.t != t;
}
