import 'package:flutter/material.dart';

import 'package:nodehack_engine/deck.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/matrix_rain.dart';

class DeckListScreen extends StatelessWidget {
  final List<Deck> decks;
  final int activeIndex;
  final VoidCallback onBack;
  final VoidCallback onNew;
  final void Function(int) onSelect;
  final void Function(int) onEdit;
  final void Function(int) onDelete;

  const DeckListScreen({
    super.key,
    required this.decks,
    required this.activeIndex,
    required this.onBack,
    required this.onNew,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const MatrixRain(intensity: 3, message: 'SOLO QUEDA MEMORIA', opacity: .35),
      const GridBg(),
      Column(children: [
        TopBar(title: 'MAZOS', onBack: onBack),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            itemCount: decks.length,
            itemBuilder: (_, i) {
              final d = decks[i];
              final active = i == activeIndex;
              final legal = d.isLegal;
              return GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: NH.a(NH.panel, .6),
                    border: Border.all(color: active ? NH.pl : const Color(0xFF1C2533)),
                    boxShadow: active ? [BoxShadow(color: NH.a(NH.pl, .18), blurRadius: 16)] : null,
                  ),
                  child: Row(children: [
                    Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: active ? NH.pl : NH.dim2, width: 2),
                        color: active ? NH.pl : Colors.transparent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: NH.disp(size: 15, weight: FontWeight.w600, color: const Color(0xFFEAF1FB))),
                        const SizedBox(height: 3),
                        Wrap(spacing: 8, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
                          Text('RUT ${d.rutCount}/10 · SUB ${d.subCount}/20', style: NH.mono(size: 9, color: NH.dim)),
                          if (!legal) Text('INCOMPLETO', style: NH.mono(size: 8, color: NH.amber, spacing: 1)),
                          if (legal && active) Text('ACTIVO', style: NH.mono(size: 8, color: NH.pl, spacing: 1)),
                        ]),
                      ]),
                    ),
                    _iconBtn(Icons.edit, NH.fw, () => onEdit(i)),
                    const SizedBox(width: 6),
                    if (decks.length > 1) _iconBtn(Icons.delete_outline, NH.xp, () => onDelete(i)),
                  ]),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, NH.safe + 8),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: NH.line))),
          child: BtnWide('+ NUEVO MAZO', onTap: onNew),
        ),
      ]),
    ]);
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32, height: 32, alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF2A3344))),
          child: Icon(icon, size: 16, color: color),
        ),
      );
}
