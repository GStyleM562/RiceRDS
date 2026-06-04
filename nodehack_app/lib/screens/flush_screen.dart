import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/chrome.dart';

class FlushScreen extends StatelessWidget {
  final String outcome; // 'win' | 'lose'
  final int round;
  final VoidCallback onMenu;
  final VoidCallback onAgain;
  const FlushScreen({super.key, required this.outcome, required this.round, required this.onMenu, required this.onAgain});

  @override
  Widget build(BuildContext context) {
    final win = outcome == 'win';
    final glow = win ? NH.pl : NH.xp;
    final sig = '0x${Random().nextInt(0xFFFFFF).toRadixString(16).toUpperCase()}';
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(center: const Alignment(0, -.2), radius: 1.1, colors: [NH.a(glow, .10), NH.cardBg]),
      ),
      child: Stack(children: [
        const GridBg(),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // glitch title
              Stack(alignment: Alignment.center, children: [
                Transform.translate(offset: const Offset(-3, 1), child: Text(win ? 'FLUSH' : 'CORE DUMP', style: NH.disp(size: 46, weight: FontWeight.w700, color: NH.a(NH.xp, .5)))),
                Transform.translate(offset: const Offset(3, -1), child: Text(win ? 'FLUSH' : 'CORE DUMP', style: NH.disp(size: 46, weight: FontWeight.w700, color: NH.a(NH.fw, .5)))),
                Text(win ? 'FLUSH' : 'CORE DUMP', style: NH.disp(size: 46, weight: FontWeight.w700, color: Colors.white).copyWith(shadows: [Shadow(color: NH.a(glow, .6), blurRadius: 26)])),
              ]),
              const SizedBox(height: 10),
              Text(win ? '> proceso rival purgado' : '> tu proceso fue terminado', style: NH.mono(size: 11, color: NH.ink2, spacing: .6)),
              const SizedBox(height: 26),
              _stat('RESULTADO', win ? 'VICTORIA' : 'DERROTA', win ? NH.pl : NH.xp),
              const SizedBox(height: 8),
              _stat('RONDAS', round.toString().padLeft(2, '0'), const Color(0xFFEAF1FB)),
              const SizedBox(height: 8),
              _stat('FIRMA', sig, const Color(0xFFEAF1FB)),
              const SizedBox(height: 30),
              SizedBox(width: 300, child: BtnWide('REINTENTAR ▸', onTap: onAgain)),
              const SizedBox(height: 10),
              SizedBox(width: 300, child: BtnWide('VOLVER AL MENÚ', variant: BtnVariant.ghost, onTap: onMenu)),
            ]),
          ),
        ),
      ]),
    );
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
