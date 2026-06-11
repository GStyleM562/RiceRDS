/// CÓDICE: cartas descubiertas en la Inmersión, cada una con su pedacito de lore
/// (placeholder críptico). Es lo que muestra el botón COLECCIÓN del menú.
library;

import 'package:flutter/material.dart';

import 'package:nodehack_engine/card_instance.dart';

import '../theme/tokens.dart';
import '../widgets/card_view.dart';
import 'adventure_data.dart';
import 'adventure_state.dart';

class CodexScreen extends StatelessWidget {
  final AdventureState st;
  final VoidCallback onBack;
  final void Function(CardInstance) onZoom;
  const CodexScreen({super.key, required this.st, required this.onBack, required this.onZoom});

  @override
  Widget build(BuildContext context) {
    final ids = st.codex.toList()..sort();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, NH.safe + 6, 14, 6),
        child: Row(children: [
          GestureDetector(onTap: onBack, child: Text('‹ VOLVER', style: NH.mono(size: 11, color: NH.ink2, spacing: 1))),
          const Spacer(),
          Text('CÓDICE', style: NH.disp(size: 16, weight: FontWeight.w700, color: const Color(0xFFEAF7FF), spacing: 3)),
          const Spacer(),
          Text('${ids.length}', style: NH.mono(size: 11, color: NH.dim)),
        ]),
      ),
      Expanded(
        child: ids.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text('Aún no has recuperado nada del NULL ARCHIVE.\nEntra a la INMERSIÓN para descubrir cartas y su rastro de lore.',
                      textAlign: TextAlign.center, style: NH.mono(size: 11, color: NH.dim, height: 1.6)),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, NH.safe + 16),
                children: [for (final id in ids) _entry(id)],
              ),
      ),
    ]);
  }

  Widget _entry(String id) {
    final card = cardInstanceOf(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: NH.a(const Color(0xFF090C12), .72),
        border: Border.all(color: NH.line),
      ),
      child: Row(children: [
        GestureDetector(onTap: () => onZoom(card), child: CardView(card: card, width: 62)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(card.name, style: NH.disp(size: 14, weight: FontWeight.w700, color: const Color(0xFFEAF1FB), spacing: .5)),
            const SizedBox(height: 4),
            Text('×${st.owned(id)} en tu colección', style: NH.mono(size: 8.5, color: NH.dim, spacing: 1)),
            const SizedBox(height: 5),
            Text(codexLoreFor(id), style: NH.mono(size: 10, color: NH.ink2, height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}
