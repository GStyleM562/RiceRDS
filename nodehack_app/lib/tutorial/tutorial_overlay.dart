/// Capa de instrucciones del tutorial: tarjeta con el personaje anónimo (`∅ // SYS`)
/// y el texto del paso actual + un "señalador" pulsante (crece/reduce) que ilumina
/// la zona de la mesa que se está explicando (RAM, CICLOS, espacios, etc.). En pasos
/// `info`/`done` muestra un botón para avanzar; en pasos con `gate` oculta el botón.
/// Se oculta durante la animación de ejecución para dejar ver la mesa. No bloquea los
/// toques fuera de la tarjeta.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'tutorial_match_controller.dart';

class TutorialOverlay extends StatefulWidget {
  final TutorialMatchController ctrl;
  final Map<String, GlobalKey> spotKeys;
  const TutorialOverlay({super.key, required this.ctrl, required this.spotKeys});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  static String? _spotName(Spot s) => switch (s) {
        Spot.slots => 'slots',
        Spot.ram => 'ram',
        Spot.legend => 'legend',
        Spot.oppCard => 'oppCard',
        Spot.cta => 'cta',
        Spot.hand => 'hand',
        Spot.center => 'center',
        Spot.integrity => 'integrity',
        Spot.none => null,
      };

  // Rect de la zona a señalar, en el espacio local de este overlay (o null si aún
  // no está medida). Recalcula cada frame (el pulso fuerza rebuilds) → siempre actual.
  Rect? _spotRect(Spot spot) {
    final name = _spotName(spot);
    if (name == null) return null;
    final box = widget.spotKeys[name]?.currentContext?.findRenderObject() as RenderBox?;
    final self = context.findRenderObject() as RenderBox?;
    if (box == null || self == null || !box.attached || !self.attached) return null;
    final tl = self.globalToLocal(box.localToGlobal(Offset.zero));
    final br = self.globalToLocal(box.localToGlobal(box.size.bottomRight(Offset.zero)));
    return Rect.fromPoints(tl, br);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.ctrl, _pulse]),
      builder: (context, _) {
        final c = widget.ctrl;
        final id = c.phase.id;
        // Durante la jugada animada, deja ver la mesa sin estorbo.
        if (id == 'compilar' || id == 'revelacion' || id == 'ejecucion') {
          return const SizedBox.shrink();
        }
        final step = c.step;
        final rect = _spotRect(step.spot);
        final self = context.findRenderObject() as RenderBox?;
        final h = self?.size.height ?? 844;
        // La tarjeta se coloca lejos del señalador: si la zona está arriba, va abajo.
        final cardAtBottom = rect != null && rect.center.dy < h * 0.46;

        final breath = 0.5 + 0.5 * _pulse.value; // 0..1 (crece y reduce)
        return Stack(children: [
          if (rect != null) _spotRing(rect, breath),
          Positioned(
            top: cardAtBottom ? null : NH.safe + 46,
            bottom: cardAtBottom ? NH.safe + 120 : null,
            left: 12,
            right: 12,
            child: _Card(
              text: step.text,
              showNext: c.showNextButton,
              nextLabel: c.isDone ? 'FINALIZAR ▸' : 'SIGUIENTE ▸',
              onNext: c.next,
              actionHint: _actionHint(step.gate),
            ),
          ),
        ]);
      },
    );
  }

  // Anillo pulsante alrededor de la zona señalada (crece/reduce su tamaño).
  Widget _spotRing(Rect rect, double breath) {
    final pad = 6 + 7 * breath;
    final r = rect.inflate(pad);
    return Positioned.fromRect(
      rect: r,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NH.a(NH.fw, .55 + .45 * breath), width: 2),
            boxShadow: [BoxShadow(color: NH.a(NH.fw, .18 + .25 * breath), blurRadius: 14 + 12 * breath, spreadRadius: 1)],
          ),
        ),
      ),
    );
  }

  String? _actionHint(TutGate g) => switch (g) {
        TutGate.place => '▸ arrastra la carta indicada al espacio resaltado',
        TutGate.placeSub => '▸ arrastra la Subrutina a un espacio lateral resaltado',
        TutGate.compile => '▸ pulsa el botón resaltado',
        TutGate.nextRound => '▸ pulsa el botón resaltado',
        _ => null,
      };
}

class _Card extends StatelessWidget {
  final String text;
  final bool showNext;
  final String nextLabel;
  final VoidCallback onNext;
  final String? actionHint;
  const _Card({
    required this.text,
    required this.showNext,
    required this.nextLabel,
    required this.onNext,
    required this.actionHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: NH.a(const Color(0xFF03080C), .95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NH.a(NH.fw, .7), width: 1.2),
        boxShadow: [BoxShadow(color: NH.a(NH.fw, .22), blurRadius: 18)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          _Avatar(),
          const SizedBox(width: 8),
          Text('∅ // SYS', style: NH.mono(size: 11, color: NH.fw, spacing: 3)),
          const Spacer(),
          Text('TUTORIAL', style: NH.mono(size: 9, color: NH.dim2, spacing: 2)),
        ]),
        const SizedBox(height: 10),
        Text(text, style: NH.mono(size: 13, color: const Color(0xFFE8F6FF), height: 1.5)),
        if (actionHint != null) ...[
          const SizedBox(height: 10),
          Text(actionHint!, style: NH.mono(size: 11, weight: FontWeight.w700, color: NH.pl, spacing: .3)),
        ],
        if (showNext) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onNext,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: NH.a(NH.fw, .1),
                  border: Border.all(color: NH.a(NH.fw, .75), width: 1.2),
                  boxShadow: [BoxShadow(color: NH.a(NH.fw, .25), blurRadius: 12)],
                ),
                child: Text(nextLabel, style: NH.mono(size: 12, weight: FontWeight.w700, color: NH.fw, spacing: 2)),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _Avatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: NH.a(NH.fw, .08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: NH.a(NH.fw, .6)),
      ),
      child: Text('∅', style: NH.disp(size: 15, weight: FontWeight.w700, color: NH.fw)),
    );
  }
}
