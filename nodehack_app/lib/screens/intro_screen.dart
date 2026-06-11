/// Intro de bienvenida: pantalla negra, diálogo del SISTEMA que se escribe línea
/// a línea (typewriter + flicker). Al final, en la MISMA pantalla, pregunta SÍ/NO
/// (seleccionables). NO → repregunta agresiva/glitcheada; NO otra vez → "apagar la
/// TV" (colapso CRT) y al menú. SÍ → al tutorial.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/matrix_rain.dart';

class IntroScreen extends StatefulWidget {
  final VoidCallback onStartTutorial; // SÍ
  final VoidCallback onSkipToMenu; // NO → NO (apaga la TV)
  const IntroScreen({super.key, required this.onStartTutorial, required this.onSkipToMenu});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

enum _Phase { dialogue, ask, askHard, powerOff }

// Diálogo del SISTEMA (lore PROGRAM_NULL). El hablante es anónimo: `∅ // SYS`.
const List<String> _dialogue = [
  'Reconectando con el NULL ARCHIVE…',
  'La máquina agoniza. Su núcleo se apaga, proceso por proceso.',
  'Algo reescribió el sistema desde adentro. Lo llamamos PROGRAM_NULL.',
  'Ahora solo quedan duelos: dos procesos chocan, solo uno sobrevive el ciclo.',
  'CORTAFUEGOS vence a EXPLOIT. EXPLOIT vence a PULSO. PULSO vence a CORTAFUEGOS.',
  'Tú eres un proceso despertando. Aún no sabes pelear.',
  'Yo te guiaré. No confíes en nadie más aquí dentro.',
];

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.dialogue;
  int _line = 0;
  int _chars = 0;
  bool _typing = true;
  Timer? _typeTimer;

  late final AnimationController _crt; // se crea en initState (evita init perezosa en dispose)

  String get _current => _dialogue[_line];

  @override
  void initState() {
    super.initState();
    _crt = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _startTyping();
  }

  void _startTyping() {
    _chars = 0;
    _typing = true;
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 26), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_chars >= _current.length) {
        t.cancel();
        setState(() => _typing = false);
        return;
      }
      setState(() => _chars++);
    });
  }

  void _tap() {
    if (_phase != _Phase.dialogue) return;
    if (_typing) {
      _typeTimer?.cancel();
      setState(() {
        _chars = _current.length;
        _typing = false;
      });
      return;
    }
    if (_line < _dialogue.length - 1) {
      setState(() => _line++);
      _startTyping();
    } else {
      setState(() => _phase = _Phase.ask);
    }
  }

  void _answerYes() {
    _typeTimer?.cancel();
    widget.onStartTutorial();
  }

  void _answerNo() {
    if (_phase == _Phase.ask) {
      setState(() => _phase = _Phase.askHard);
    } else {
      setState(() => _phase = _Phase.powerOff);
      _crt.forward().whenComplete(() {
        if (mounted) widget.onSkipToMenu();
      });
    }
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _crt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.powerOff) {
      return AnimatedBuilder(
        animation: _crt,
        builder: (_, _) => CustomPaint(painter: _PowerOffPainter(_crt.value), size: Size.infinite),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.black)),
          Positioned.fill(child: MatrixRain(intensity: 3, message: 'PROGRAM_NULL', opacity: .28)),
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ScanlinesPainter()))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                children: [
                  const SizedBox(height: NH.safe + 10),
                  Row(children: [
                    Text('∅ // SYS', style: NH.mono(size: 11, color: NH.fw, spacing: 3)),
                    const Spacer(),
                    if (_phase == _Phase.dialogue)
                      Text('${_line + 1}/${_dialogue.length}', style: NH.mono(size: 10, color: NH.dim2)),
                  ]),
                  const Spacer(),
                  if (_phase == _Phase.dialogue) _dialogueView() else _askView(),
                  const Spacer(flex: 2),
                  if (_phase == _Phase.dialogue && !_typing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: NH.safe + 8),
                      child: Text(
                        _line < _dialogue.length - 1 ? 'toca para continuar  ▸' : 'toca para continuar  ▸',
                        style: NH.mono(size: 10, color: NH.a(NH.fw, .55), spacing: 1.5),
                      ),
                    )
                  else
                    SizedBox(height: NH.safe + 8 + (_phase == _Phase.dialogue ? 14 : 0)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogueView() {
    final shown = _current.substring(0, _chars.clamp(0, _current.length));
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: shown, style: NH.mono(size: 16, color: const Color(0xFFEAF7FF), height: 1.7)),
        if (_typing) TextSpan(text: '▌', style: NH.mono(size: 16, color: NH.fw)),
      ]),
      textAlign: TextAlign.center,
    );
  }

  Widget _askView() {
    final hard = _phase == _Phase.askHard;
    final q = hard ? 'ESO NO ES OPCIONAL.\n¿SEGURO QUE NO?' : '¿QUIERES VER DE QUÉ SE TRATA?';
    final qColor = hard ? NH.xp : const Color(0xFFEAF7FF);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _GlitchText(text: q, color: qColor, glitch: hard),
      const SizedBox(height: 26),
      _choice('SÍ', NH.pl, _answerYes),
      const SizedBox(height: 12),
      _choice('NO', hard ? NH.xp : NH.dim, _answerNo, danger: hard),
    ]);
  }

  // Opción seleccionable estilo terminal: cursor ▸ + borde/resplandor al tocar.
  Widget _choice(String label, Color color, VoidCallback onTap, {bool danger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: NH.a(color, .07),
          border: Border.all(color: NH.a(color, danger ? .9 : .6), width: 1.2),
          boxShadow: [BoxShadow(color: NH.a(color, .22), blurRadius: 16)],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('▸ ', style: NH.mono(size: 14, weight: FontWeight.w700, color: color)),
          Text(label, style: NH.mono(size: 14, weight: FontWeight.w700, color: color, spacing: 3)),
        ]),
      ),
    );
  }
}

// Texto con aberración cromática (glitch) opcional; legible en el frente.
class _GlitchText extends StatefulWidget {
  final String text;
  final Color color;
  final bool glitch;
  const _GlitchText({required this.text, required this.color, this.glitch = false});

  @override
  State<_GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<_GlitchText> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = NH.disp(size: 18, weight: FontWeight.w700, color: widget.color, spacing: 1);
    if (!widget.glitch) {
      return Text(widget.text, textAlign: TextAlign.center, style: style);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final p = (sin(_c.value * pi * 6).abs()); // parpadeo
        final dx = (sin(_c.value * pi * 8) * 3);
        return Stack(alignment: Alignment.center, children: [
          Transform.translate(
            offset: Offset(-dx, 0),
            child: Text(widget.text, textAlign: TextAlign.center, style: style.copyWith(color: NH.a(NH.fw, .5 * p))),
          ),
          Transform.translate(
            offset: Offset(dx, 0),
            child: Text(widget.text, textAlign: TextAlign.center, style: style.copyWith(color: NH.a(NH.xp, .5 * p))),
          ),
          Text(widget.text, textAlign: TextAlign.center, style: style),
        ]);
      },
    );
  }
}

// Apagado tipo CRT: la imagen colapsa a una línea brillante y se va a negro.
class _PowerOffPainter extends CustomPainter {
  final double t; // 0..1
  _PowerOffPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    if (t >= 1) return;
    final cy = size.height / 2;
    if (t < .65) {
      // Colapso vertical: una banda que se cierra hacia el centro.
      final k = t / .65;
      final half = (size.height / 2) * (1 - k);
      final glow = Paint()
        ..color = NH.a(NH.fw, 1 - k * .2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRect(Rect.fromLTWH(0, cy - half, size.width, half * 2), Paint()..color = NH.a(NH.fw, .06));
      canvas.drawRect(Rect.fromLTWH(0, cy - 2, size.width, 4), glow);
    } else {
      // Punto que se apaga.
      final k = (t - .65) / .35;
      final w = size.width * (1 - k);
      canvas.drawRect(Rect.fromLTWH(size.width / 2 - w / 2, cy - 1.5, w, 3),
          Paint()..color = NH.a(Colors.white, 1 - k)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }
  }

  @override
  bool shouldRepaint(covariant _PowerOffPainter old) => old.t != t;
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = NH.a(NH.fw, .04)..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinesPainter old) => false;
}
