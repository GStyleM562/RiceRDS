/// Overlay de inspección de carta (zoom) con FX: entrada con perspectiva, glow del
/// color del tipo que respira, panel de lectura con el texto COMPLETO, inclinación
/// y "arrastrar para cerrar". Reemplaza el overlay plano de `main._zoomOverlay`.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nodehack_engine/card_instance.dart';
import 'package:nodehack_engine/types.dart';

import '../theme/tokens.dart';
import 'card_view.dart';
import 'sigil.dart';

class CardZoomOverlay extends StatefulWidget {
  final CardInstance card;
  final VoidCallback onClose;
  const CardZoomOverlay({super.key, required this.card, required this.onClose});

  @override
  State<CardZoomOverlay> createState() => _CardZoomOverlayState();
}

class _CardZoomOverlayState extends State<CardZoomOverlay> with TickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 260))..forward();
  late final AnimationController _glow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);

  double _dragX = 0, _dragY = 0;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _in.dispose();
    _glow.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_closing) return;
    _closing = true;
    widget.onClose();
  }

  Color get _accent => widget.card.isSub ? const Color(0xFF7D8AA0) : Color(widget.card.type.color);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_in, _glow]),
      builder: (context, _) {
        final ti = _in.value;
        final eb = Curves.easeOutBack.transform(ti);
        final scale = 0.82 + 0.18 * eb;
        final entryY = (1 - eb) * 24;
        final rotX = (1 - ti) * 0.10;
        final dragFade = (1 - _dragY.abs() / 320).clamp(0.0, 1.0);
        final glowA = 0.18 + 0.12 * _glow.value;
        return Stack(children: [
          // Fondo oscuro + blur — capta el toque para cerrar.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismiss,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6 * ti, sigmaY: 6 * ti),
                child: ColoredBox(color: NH.a(Colors.black, .88 * ti)),
              ),
            ),
          ),
          // Carta + panel (la zona vacía deja pasar el toque al fondo).
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: Opacity(
                  opacity: ti,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (d) => setState(() {
                          _dragX += d.delta.dx;
                          _dragY += d.delta.dy;
                        }),
                        onPanEnd: (_) {
                          if (_dragY.abs() > 80) {
                            _dismiss();
                          } else {
                            setState(() {
                              _dragX = 0;
                              _dragY = 0;
                            });
                          }
                        },
                        child: _cardWithGlow(scale, entryY, rotX, dragFade, glowA),
                      ),
                      const SizedBox(height: 14),
                      Opacity(opacity: dragFade, child: _readingPanel()),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: (0.45 + 0.45 * _glow.value) * dragFade,
                        child: Text('toca o desliza para cerrar', style: NH.mono(size: 10, color: NH.a(NH.fw, .8), spacing: 1.5)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }

  Widget _cardWithGlow(double scale, double entryY, double rotX, double dragFade, double glowA) {
    final rotZ = (_dragX * 0.0009).clamp(-0.12, 0.12);
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0015)
      ..translateByDouble(0.0, entryY + _dragY, 0.0, 1.0)
      ..rotateX(rotX)
      ..rotateZ(rotZ)
      ..scaleByDouble(scale, scale, scale, 1.0);
    return Transform(
      alignment: Alignment.center,
      transform: transform,
      child: Opacity(
        opacity: dragFade,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: NH.a(_accent, glowA), blurRadius: 60, spreadRadius: 8)],
          ),
          child: CardView(card: widget.card, width: 240),
        ),
      ),
    );
  }

  Widget _readingPanel() {
    final c = widget.card;
    final beats = c.isSub ? null : c.type.beats;
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: NH.a(NH.panel, .8),
        border: Border.all(color: NH.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Text(c.isSub ? 'SUBRUTINA' : 'RUTINA', style: NH.mono(size: 8, color: _accent, spacing: 2)),
          const Spacer(),
          Text(c.isSub ? 'RAM ${c.ram}' : '${c.ciclos} CYC',
              style: NH.mono(size: 8, weight: FontWeight.w700, color: c.isSub ? NH.amber : _accent)),
        ]),
        const SizedBox(height: 4),
        Text(c.name, style: NH.disp(size: 16, weight: FontWeight.w700, color: const Color(0xFFEAF1FB), spacing: .5)),
        if (beats != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            Sigil(type: c.type, size: 15),
            const SizedBox(width: 4),
            Text(c.type.short, style: NH.mono(size: 9, weight: FontWeight.w700, color: Color(c.type.color))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('▸ vence a', style: NH.mono(size: 8, color: NH.dim))),
            Sigil(type: beats, size: 15),
            const SizedBox(width: 4),
            Text(beats.short, style: NH.mono(size: 9, weight: FontWeight.w700, color: Color(beats.color))),
          ]),
        ],
        const SizedBox(height: 8),
        Text(c.txt, style: NH.mono(size: 10.5, color: NH.ink2, height: 1.5)),
        const SizedBox(height: 8),
        Row(children: [
          Text(c.rar.label, style: NH.mono(size: 8, color: NH.dim2, spacing: 1)),
          const Spacer(),
          Text(c.proc, style: NH.mono(size: 8, color: NH.dim)),
        ]),
      ]),
    );
  }
}
