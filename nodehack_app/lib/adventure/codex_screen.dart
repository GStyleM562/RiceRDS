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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, NH.safe + 16),
          children: [
            _endingsGallery(),
            const SizedBox(height: 14),
            Row(children: [
              Container(width: 3, height: 14, color: NH.fw),
              const SizedBox(width: 8),
              Text('CARTAS RECUPERADAS', style: NH.mono(size: 11, weight: FontWeight.w700, color: NH.fw, spacing: 2)),
            ]),
            const SizedBox(height: 8),
            if (ids.isEmpty)
              Text('Aún no has recuperado nada del NULL ARCHIVE.\nEntra a la INMERSIÓN para descubrir cartas y su rastro de lore.',
                  style: NH.mono(size: 10.5, color: NH.dim, height: 1.6))
            else
              for (final id in ids) _entry(id),
          ],
        ),
      ),
    ]);
  }

  // Galería de FINALES: los 4 verdaderos + el secreto (los no conseguidos = ???).
  Widget _endingsGallery() {
    final ids = kGalleryEndingIds;
    final got = st.unlockedEndings;
    final allTrue = got.containsAll([for (final n in kNatures) n.trueEndingId]);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: NH.a(const Color(0xFF090C12), .72),
        border: Border.all(color: NH.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 3, height: 14, color: NH.nl),
          const SizedBox(width: 8),
          Text('FINALES', style: NH.mono(size: 11, weight: FontWeight.w700, color: NH.nl, spacing: 2)),
          const Spacer(),
          Text('${got.length}/${ids.length}', style: NH.mono(size: 9, color: NH.dim)),
        ]),
        const SizedBox(height: 4),
        Text('La conciencia recae… y vuelve a intentarlo. Cada final que alcances queda aquí.',
            style: NH.mono(size: 8.5, color: NH.dim, height: 1.4)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final id in ids) _endChip(id, got.contains(id))]),
        if (!allTrue) ...[
          const SizedBox(height: 8),
          Text('Consigue los 4 finales verdaderos para revelar el 5º…',
              style: NH.mono(size: 8, color: NH.a(NH.amber, .8), spacing: .5)),
        ],
      ]),
    );
  }

  Widget _endChip(String id, bool got) {
    final secret = id == kSecretEndingId;
    final col = secret ? const Color(0xFFFFD27A) : Color(natureById(id.substring(5)).nucleo.color);
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: got ? NH.a(col, .1) : NH.a(NH.dim2, .08),
        border: Border.all(color: got ? NH.a(col, .7) : NH.a(NH.dim2, .5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(got ? (secret ? '★' : '✓') : '🔒', style: TextStyle(fontSize: 11, color: got ? col : NH.dim2)),
        const SizedBox(height: 3),
        Text(got ? endingTitleFor(id) : '? ? ?',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: NH.mono(size: 9, weight: FontWeight.w700, color: got ? col : NH.dim2, spacing: .5)),
      ]),
    );
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
