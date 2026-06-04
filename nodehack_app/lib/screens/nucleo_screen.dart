import 'package:flutter/material.dart';

import 'package:nodehack_engine/cards.dart';
import 'package:nodehack_engine/types.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/matrix_rain.dart';
import '../widgets/sigil.dart';

class NucleoScreen extends StatefulWidget {
  final NucleoDef current;
  final VoidCallback onBack;
  final void Function(NucleoDef) onConfirm;
  const NucleoScreen({super.key, required this.current, required this.onBack, required this.onConfirm});

  @override
  State<NucleoScreen> createState() => _NucleoScreenState();
}

class _NucleoScreenState extends State<NucleoScreen> with SingleTickerProviderStateMixin {
  late NucleoDef sel = widget.current;
  late final AnimationController _ring =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nc = Color(sel.color);
    return Stack(children: [
      MatrixRain(intensity: 2, color: nc, message: 'ELIGE QUÉ ERES', opacity: .4),
      const GridBg(),
      Column(children: [
        TopBar(title: 'SELECCIÓN DE NÚCLEO', onBack: widget.onBack),
        // Hero
        Container(
          margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NH.mix(nc, Colors.transparent, .45)),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [NH.mix(nc, const Color(0xFF070912), .16), const Color(0xFF070912)]),
            boxShadow: [BoxShadow(color: NH.a(nc, .18), blurRadius: 24)],
          ),
          child: Stack(children: [
            Positioned(
              right: -40, top: -40,
              child: RotationTransition(
                turns: _ring,
                child: Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: NH.mix(nc, Colors.transparent, .4)))),
              ),
            ),
            Row(children: [
              Sigil(type: sel.type, size: 84),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(sel.handle, style: NH.mono(size: 10, color: nc, spacing: 1)),
                  const SizedBox(height: 2),
                  Text(sel.name, style: NH.disp(size: 30, weight: FontWeight.w700, color: Colors.white).copyWith(shadows: [Shadow(color: NH.a(nc, .6), blurRadius: 14)])),
                  const SizedBox(height: 4),
                  Text(sel.tag, style: NH.mono(size: 10, color: NH.ink2)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 12, runSpacing: 4, children: [
                    _stat('RAM', '${sel.ram}', NH.ink),
                    _stat('INTEGRIDAD', '${sel.integrity}', NH.ink),
                    _stat('TIPO', sel.type.label, nc),
                  ]),
                ]),
              ),
            ]),
          ]),
        ),
        // Pasiva (barra de acento a la izquierda)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            color: NH.a(NH.panel, .6),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: NH.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(width: 2, color: nc),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('PASIVA', style: NH.mono(size: 8, color: nc, spacing: 2.6)),
                    const SizedBox(height: 5),
                    Text(sel.passive, style: NH.mono(size: 11, color: NH.ink2, height: 1.5)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        // Selector 2x2
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 9, crossAxisSpacing: 9, childAspectRatio: 3.1,
            children: [for (final n in kNucleos) _chip(n)],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, NH.safe + 8),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: NH.line))),
          child: BtnWide('CONFIRMAR NÚCLEO ▸', onTap: () => widget.onConfirm(sel)),
        ),
      ]),
    ]);
  }

  Widget _stat(String k, String v, Color vc) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$k ', style: NH.mono(size: 9, color: NH.dim)),
        Text(v, style: NH.mono(size: 13, weight: FontWeight.w700, color: vc)),
      ]);

  Widget _chip(NucleoDef n) {
    final c = Color(n.color);
    final active = n.id == sel.id;
    return GestureDetector(
      onTap: () => setState(() => sel = n),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: active ? NH.mix(c, NH.a(NH.panel, .6), .14) : NH.a(NH.panel, .6),
          border: Border.all(color: active ? c : const Color(0xFF1C2533)),
          boxShadow: active ? [BoxShadow(color: NH.a(c, .22), blurRadius: 16)] : null,
        ),
        child: Row(children: [
          Sigil(type: n.type, size: 30),
          const SizedBox(width: 9),
          Expanded(child: Text(n.name, style: NH.disp(size: 13, weight: FontWeight.w600, color: NH.ink, spacing: 1), overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}
