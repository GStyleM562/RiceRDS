import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/matrix_rain.dart';

class MenuScreen extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onOnline;
  final VoidCallback onDeck;
  final VoidCallback onNucleo;
  final String nucleoName;
  const MenuScreen({
    super.key,
    required this.onPlay,
    required this.onOnline,
    required this.onDeck,
    required this.onNucleo,
    required this.nucleoName,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const MatrixRain(intensity: 5, message: 'DESPIERTA', opacity: .7),
        const GridBg(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: NH.safe + 30),
              _boot(),
              const SizedBox(height: 14),
              Center(
                child: Text('NODEHACK',
                    style: NH.disp(size: 54, weight: FontWeight.w700, color: const Color(0xFFEAF7FF), spacing: 2, height: .9)
                        .copyWith(shadows: [Shadow(color: NH.a(NH.fw, .5), blurRadius: 24)])),
              ),
              const SizedBox(height: 8),
              Center(child: Text(':: PROGRAM_NULL', style: NH.mono(size: 13, color: NH.fw, spacing: 5.4))),
              const SizedBox(height: 12),
              Center(child: Text('Dos procesos. Una máquina muriendo.', style: NH.mono(size: 10, color: NH.dim, spacing: .6))),
              const SizedBox(height: 34),
              _MenuBtn(glyph: '⚔', label: 'PARTIDA vs CPU', sub: 'Duelo de resolución simultánea', onTap: onPlay, primary: true),
              const SizedBox(height: 11),
              _MenuBtn(glyph: '⇄', label: 'JUGAR ONLINE', sub: '1v1 por código de sala', onTap: onOnline),
              const SizedBox(height: 11),
              _MenuBtn(glyph: '▤', label: 'MAZOS', sub: '10 Rutinas · 20 Subrutinas', onTap: onDeck),
              const SizedBox(height: 11),
              _MenuBtn(glyph: '◈', label: 'NÚCLEO', sub: 'Activo: $nucleoName', onTap: onNucleo),
              const SizedBox(height: 11),
              const _MenuBtn(glyph: '⌬', label: 'COLECCIÓN', sub: 'Bloqueado — próximamente', ghost: true),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: NH.safe + 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('v0.4 · build_null', style: NH.mono(size: 9, color: NH.dim2)),
                    Row(children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: NH.pl, shape: BoxShape.circle, boxShadow: [BoxShadow(color: NH.pl, blurRadius: 6)])),
                      const SizedBox(width: 5),
                      Text('conexión: local', style: NH.mono(size: 9, color: NH.dim2)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _boot() => DefaultTextStyle(
        style: NH.mono(size: 9, color: NH.dim, height: 1.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BootLine(delay: 120, child: Row(children: [Text('> init kernel...... ', style: NH.mono(size: 9, color: NH.dim)), Text('OK', style: NH.mono(size: 9, color: NH.pl))])),
            _BootLine(delay: 360, child: Row(children: [Text('> mount /dev/null... ', style: NH.mono(size: 9, color: NH.dim)), Text('OK', style: NH.mono(size: 9, color: NH.pl))])),
            _BootLine(delay: 600, child: Row(children: [Text('> load PROGRAM_NULL ', style: NH.mono(size: 9, color: NH.dim)), Text('⚠ inestable', style: NH.mono(size: 9, color: NH.amber))])),
          ],
        ),
      );
}

class _BootLine extends StatefulWidget {
  final int delay;
  final Widget child;
  const _BootLine({required this.delay, required this.child});
  @override
  State<_BootLine> createState() => _BootLineState();
}

class _BootLineState extends State<_BootLine> {
  double _o = 0;
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) setState(() => _o = 1);
    });
  }

  @override
  Widget build(BuildContext context) =>
      AnimatedOpacity(opacity: _o, duration: const Duration(milliseconds: 400), child: widget.child);
}

class _MenuBtn extends StatelessWidget {
  final String glyph, label, sub;
  final VoidCallback? onTap;
  final bool primary, ghost;
  const _MenuBtn({required this.glyph, required this.label, required this.sub, this.onTap, this.primary = false, this.ghost = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: ghost ? .45 : 1,
      child: GestureDetector(
        onTap: ghost ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: primary ? null : NH.a(NH.panel, .7),
            gradient: primary
                ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [NH.a(NH.fw, .12), NH.a(NH.panel, .7)])
                : null,
            border: Border.all(color: primary ? NH.fw : const Color(0xFF1C2533)),
            boxShadow: primary ? [BoxShadow(color: NH.a(NH.fw, .16), blurRadius: 22)] : null,
          ),
          child: Row(
            children: [
              Container(width: 2, height: 34, color: primary ? NH.fw : Colors.transparent),
              const SizedBox(width: 11),
              SizedBox(width: 26, child: Center(child: Text(glyph, style: TextStyle(fontSize: 20, color: NH.fw)))),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: NH.disp(size: 15, weight: FontWeight.w600, color: const Color(0xFFEAF1FB), spacing: 1.2)),
                    const SizedBox(height: 2),
                    Text(sub, style: NH.mono(size: 9, color: NH.dim)),
                  ],
                ),
              ),
              Text(ghost ? '🔒' : '▸', style: NH.mono(size: 12, color: NH.dim)),
            ],
          ),
        ),
      ),
    );
  }
}
