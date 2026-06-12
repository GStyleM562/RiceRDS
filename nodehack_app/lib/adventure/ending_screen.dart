/// Pantalla de FINAL del modo INMERSIÓN: título + narrativa escrita poco a poco,
/// tematizada por el color de la Naturaleza (o gris para el básico, oro para el
/// secreto GÉNESIS). Al cerrar, la run ya se reinició (`concludeRun`).
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/matrix_rain.dart';
import 'adventure_data.dart';

class EndingScreen extends StatefulWidget {
  final EndingView view;
  final VoidCallback onClose;
  const EndingScreen({super.key, required this.view, required this.onClose});

  @override
  State<EndingScreen> createState() => _EndingScreenState();
}

class _EndingScreenState extends State<EndingScreen> {
  int _chars = 0;
  bool _done = false;
  Timer? _t;

  String get _text => widget.view.narrative;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 22), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_chars >= _text.length) {
        t.cancel();
        setState(() => _done = true);
        return;
      }
      setState(() => _chars++);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _skip() {
    if (_done) return;
    _t?.cancel();
    setState(() {
      _chars = _text.length;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.view;
    final col = Color(v.colorArgb);
    return GestureDetector(
      onTap: _skip,
      behavior: HitTestBehavior.opaque,
      child: Stack(children: [
        const Positioned.fill(child: ColoredBox(color: NH.bg)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(center: const Alignment(0, -.35), radius: 1.1, colors: [NH.a(col, .14), NH.cardBg]),
            ),
          ),
        ),
        Positioned.fill(child: MatrixRain(intensity: 3, message: v.isTrue ? 'GENESIS' : 'NULL', color: col, opacity: .2)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(children: [
              const SizedBox(height: NH.safe + 10),
              Text(v.isTrue ? (v.id == kSecretEndingId ? 'FINAL SECRETO' : 'FINAL VERDADERO') : 'FINAL',
                  style: NH.mono(size: 10, color: NH.dim, spacing: 4)),
              const SizedBox(height: 8),
              Text(v.title,
                  textAlign: TextAlign.center,
                  style: NH.disp(size: 34, weight: FontWeight.w700, color: col, spacing: 2)
                      .copyWith(shadows: [Shadow(color: NH.a(col, .55), blurRadius: 24)])),
              const Spacer(),
              Text(
                _text.substring(0, _chars.clamp(0, _text.length)),
                textAlign: TextAlign.center,
                style: NH.mono(size: 13.5, color: const Color(0xFFEAF7FF), height: 1.7),
              ),
              const Spacer(flex: 2),
              if (_done)
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: NH.a(col, .12),
                      border: Border.all(color: col, width: 1.2),
                      boxShadow: [BoxShadow(color: NH.a(col, .25), blurRadius: 16)],
                    ),
                    child: Center(child: Text('CERRAR ▸', style: NH.mono(size: 12, weight: FontWeight.w700, color: col, spacing: 2))),
                  ),
                )
              else
                Text('toca para continuar', style: NH.mono(size: 9, color: NH.a(NH.fw, .5), spacing: 1.5)),
              const SizedBox(height: NH.safe + 14),
            ]),
          ),
        ),
      ]),
    );
  }
}
