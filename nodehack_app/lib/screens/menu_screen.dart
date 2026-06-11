import 'package:flutter/material.dart';

import '../audio/audio_service.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/matrix_rain.dart';

class MenuScreen extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onOnline;
  final VoidCallback onDeck;
  final VoidCallback onNucleo;
  final VoidCallback? onTutorial;
  final VoidCallback? onRules;
  final VoidCallback? onAdventure;
  final bool hasAdventureRun;
  final VoidCallback? onCodex;
  final VoidCallback? onDebugRoutes; // solo en debug: abre el panel de rutas de assets
  final String nucleoName;
  const MenuScreen({
    super.key,
    required this.onPlay,
    required this.onOnline,
    required this.onDeck,
    required this.onNucleo,
    this.onTutorial,
    this.onRules,
    this.onAdventure,
    this.hasAdventureRun = false,
    this.onCodex,
    this.onDebugRoutes,
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
              Expanded(
                child: SingleChildScrollView(
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
              const SizedBox(height: 14),
              _HistoriaBtn(hasRun: hasAdventureRun, onEnter: onAdventure),
              const SizedBox(height: 9),
              _MenuBtn(glyph: '⚔', label: 'PARTIDA vs CPU', sub: 'Duelo de resolución simultánea', onTap: onPlay),
              const SizedBox(height: 9),
              _MenuBtn(glyph: '⇄', label: 'JUGAR ONLINE', sub: '1v1 por código de sala', onTap: onOnline),
              const SizedBox(height: 9),
              _MenuBtn(glyph: '▤', label: 'MAZOS', sub: '10 Rutinas · 20 Subrutinas', onTap: onDeck),
              const SizedBox(height: 9),
              _MenuBtn(glyph: '◈', label: 'NÚCLEO', sub: 'Activo: $nucleoName', onTap: onNucleo),
              const SizedBox(height: 9),
              _MenuBtn(glyph: '❔', label: 'CÓMO JUGAR', sub: 'Tutorial básico y avanzado', onTap: onTutorial),
              const SizedBox(height: 9),
              _MenuBtn(glyph: '☰', label: 'REGLAS', sub: 'Referencia rápida de términos', onTap: onRules),
              const SizedBox(height: 9),
              _MenuBtn(glyph: '⌬', label: 'COLECCIÓN', sub: 'Cartas e historia descubiertas', onTap: onCodex),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: NH.safe + 6),
                child: Row(
                  children: [
                    Text('v0.4 · build_null', style: NH.mono(size: 9, color: NH.dim2)),
                    const Spacer(),
                    if (onDebugRoutes != null) ...[
                      GestureDetector(
                        onTap: onDebugRoutes,
                        child: Text('▤ RUTAS (debug)', style: NH.mono(size: 9, color: NH.fw, spacing: .5)),
                      ),
                      const Spacer(),
                    ],
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
  const _MenuBtn({required this.glyph, required this.label, required this.sub, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? .45 : 1,
      child: GestureDetector(
        onTap: disabled
            ? null
            : () {
                AudioService.instance.playSfx(Sfx.uiTap);
                onTap!();
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: NH.a(NH.panel, .7),
            border: Border.all(color: const Color(0xFF1C2533)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 2),
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
              const Text('▸', style: TextStyle(fontSize: 12, color: NH.dim)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón insignia de HISTORIA: al tocarlo, su texto se transforma con glitch a
/// "NULL DIVE · iniciando inmersión…" y luego entra al modo.
class _HistoriaBtn extends StatefulWidget {
  final bool hasRun;
  final VoidCallback? onEnter;
  const _HistoriaBtn({required this.hasRun, required this.onEnter});

  @override
  State<_HistoriaBtn> createState() => _HistoriaBtnState();
}

class _HistoriaBtnState extends State<_HistoriaBtn> with SingleTickerProviderStateMixin {
  bool _diving = false;
  late final AnimationController _glitch; // se crea en initState (evita init perezosa en dispose)

  @override
  void initState() {
    super.initState();
    _glitch = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  }

  @override
  void dispose() {
    _glitch.dispose();
    super.dispose();
  }

  void _go() {
    if (_diving || widget.onEnter == null) return;
    AudioService.instance.playSfx(Sfx.compile);
    setState(() => _diving = true);
    _glitch.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1250), () {
      if (mounted) widget.onEnter!();
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = _diving
        ? 'NULL DIVE'
        : (widget.hasRun ? 'CONTINUAR INMERSIÓN' : 'HISTORIA');
    final sub = _diving
        ? 'iniciando inmersión…'
        : (widget.hasRun ? 'Retoma tu descenso' : 'Desciende. Desbloquea. Reescríbete.');
    return GestureDetector(
      onTap: _go,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [NH.a(NH.nl, .16), NH.a(NH.panel, .7)],
          ),
          border: Border.all(color: NH.nl),
          boxShadow: [BoxShadow(color: NH.a(NH.nl, .2), blurRadius: 22)],
        ),
        child: Row(children: [
          Container(width: 2, height: 34, color: NH.nl),
          const SizedBox(width: 11),
          SizedBox(width: 26, child: Center(child: Text('∅', style: NH.disp(size: 20, weight: FontWeight.w700, color: NH.nl)))),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diving ? _GlitchLabel(text: label, anim: _glitch) : Text(label, style: NH.disp(size: 16, weight: FontWeight.w700, color: const Color(0xFFEAF1FB), spacing: 1.4)),
                const SizedBox(height: 2),
                Text(sub, style: NH.mono(size: 9, color: _diving ? NH.nl : NH.dim)),
              ],
            ),
          ),
          Text(_diving ? '▾' : '▸', style: TextStyle(fontSize: 12, color: NH.nl)),
        ]),
      ),
    );
  }
}

/// Texto con aberración cromática (glitch) para la transición de inmersión.
class _GlitchLabel extends StatelessWidget {
  final String text;
  final Animation<double> anim;
  const _GlitchLabel({required this.text, required this.anim});

  @override
  Widget build(BuildContext context) {
    final style = NH.disp(size: 16, weight: FontWeight.w700, color: const Color(0xFFEAF1FB), spacing: 1.4);
    return AnimatedBuilder(
      animation: anim,
      builder: (_, _) {
        final dx = (anim.value * 30) % 4 - 2;
        return Stack(children: [
          Transform.translate(offset: Offset(-dx, 0), child: Text(text, style: style.copyWith(color: NH.a(NH.fw, .6)))),
          Transform.translate(offset: Offset(dx, 0), child: Text(text, style: style.copyWith(color: NH.a(NH.xp, .6)))),
          Text(text, style: style),
        ]);
      },
    );
  }
}
