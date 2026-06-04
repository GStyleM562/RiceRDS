/// Carta "Terminal" — render fiel a `.gc-*` del handoff. Base 172×240; el padre la escala.
library;

import 'package:flutter/material.dart';

import 'package:nodehack_engine/card_instance.dart';
import 'package:nodehack_engine/types.dart';
import '../theme/tokens.dart';
import 'sigil.dart';

const double kCardW = 172;
const double kCardH = 240;
const Color _subAccent = Color(0xFF7D8AA0);
const Color _nameColor = Color(0xFFEAF1FB);

class GameCard extends StatefulWidget {
  final CardInstance card;
  final bool dim;
  final bool animate;
  const GameCard({super.key, required this.card, this.dim = false, this.animate = true});

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> with SingleTickerProviderStateMixin {
  AnimationController? _scan;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _scan = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
        ..repeat();
    }
  }

  @override
  void dispose() {
    _scan?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.card;
    final sub = c.isSub;
    final ac = sub ? _subAccent : NH.ofType(c.type);

    Widget content = Container(
      width: kCardW,
      height: kCardH,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: NH.cardBg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: NH.mix(ac, Colors.transparent, .55)),
        boxShadow: [
          BoxShadow(color: NH.a(ac, .18), blurRadius: 18),
          BoxShadow(color: Colors.black, blurRadius: 0, spreadRadius: 1),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter(ac))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _top(c, sub, ac),
              const SizedBox(height: 5),
              Text(c.name,
                  style: NH.disp(size: 14, weight: FontWeight.w700, color: _nameColor, spacing: .3)),
              const SizedBox(height: 6),
              _art(c, sub, ac),
              const SizedBox(height: 6),
              Expanded(child: _foot(c, sub, ac)),
            ],
          ),
        ],
      ),
    );

    if (widget.dim) {
      content = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          .5, .5, 0, 0, 0, //
          .3, .6, 0, 0, 0, //
          .2, .3, .4, 0, 0, //
          0, 0, 0, 1, 0,
        ]),
        child: content,
      );
    }
    return content;
  }

  Widget _top(CardInstance c, bool sub, Color ac) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sub ? 'SUBRUTINA' : 'RUTINA',
              style: NH.mono(size: 8, color: ac, spacing: 1.6).copyWith(height: 1)),
          const Spacer(),
          if (sub)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('RAM', style: NH.mono(size: 8, color: ac, spacing: .6)),
              Text('${c.ram}',
                  style: NH.mono(size: 24, weight: FontWeight.w700, color: ac, height: .8)),
            ])
          else
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${c.ciclos}',
                  style: NH.disp(size: 26, weight: FontWeight.w700, color: ac, height: .8)),
              Text('CYC', style: NH.mono(size: 7, color: NH.a(ac, .6), spacing: 1.4)),
            ]),
        ],
      );

  Widget _art(CardInstance c, bool sub, Color ac) => Container(
        height: 78,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: NH.mix(ac, Colors.transparent, .3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: CustomPaint(painter: _StripesPainter(ac))),
            if (_scan != null)
              AnimatedBuilder(
                animation: _scan!,
                builder: (_, child) => Positioned(
                  top: -14 + _scan!.value * 92,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [NH.a(ac, .4), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
            if (!sub)
              Sigil(type: c.type, size: 40)
            else
              Text('{ }', style: NH.disp(size: 26, weight: FontWeight.w700, color: ac)),
            Positioned(
              left: 5,
              bottom: 3,
              child: Text('> ${sub ? "compiling" : "rendering"} ${c.proc}',
                  style: NH.mono(size: 7, color: NH.a(ac, .8))),
            ),
          ],
        ),
      );

  Widget _foot(CardInstance c, bool sub, Color ac) {
    Widget? typeLine;
    if (!sub) {
      final beats = c.type.beats;
      typeLine = Text(
        '${c.type.label}${beats != null ? ' ▸ ${beats.label}' : ''}',
        style: NH.mono(size: 7.5, color: NH.a(ac, .9), spacing: 1),
      );
    } else if (c.declaredType != null) {
      typeLine = Text('DECL: ${c.declaredType!.label}',
          style: NH.mono(size: 7.5, color: NH.a(ac, .9), spacing: 1));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ?typeLine,
        const SizedBox(height: 4),
        // El texto rellena el espacio restante y se recorta si la carta es pequeña.
        Expanded(
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(c.txt,
                style: NH.mono(size: 8.5, color: NH.ink2, height: 1.35),
                overflow: TextOverflow.fade),
          ),
        ),
        const SizedBox(height: 5),
        Text(c.rar.label, style: NH.mono(size: 7, color: NH.dim, spacing: 2.1)),
      ],
    );
  }
}

class GameCardBack extends StatelessWidget {
  final int seed;
  const GameCardBack({super.key, this.seed = 0});

  @override
  Widget build(BuildContext context) {
    const ac = Color(0xFF3A4760);
    final hex = (seed & 0xFFFFF).toRadixString(16).padLeft(5, '0');
    return Container(
      width: kCardW,
      height: kCardH,
      decoration: BoxDecoration(
        color: NH.cardBg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: NH.mix(ac, Colors.transparent, .55)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter(ac))),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('∅', style: NH.disp(size: 40, color: NH.a(ac, .6))),
                const SizedBox(height: 6),
                Text('> proceso oculto', style: NH.mono(size: 7, color: NH.a(ac, .8))),
                Text('0x$hex', style: NH.mono(size: 7, color: NH.a(ac, .4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color ac;
  _GridPainter(this.ac);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = NH.a(ac, .10)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => false;
}

class _StripesPainter extends CustomPainter {
  final Color ac;
  _StripesPainter(this.ac);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = NH.a(ac, .07)
      ..strokeWidth = 1;
    for (double d = -size.height; d < size.width; d += 6) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant _StripesPainter old) => false;
}
