/// Constructor del MAZO DE AVENTURA: eliges cuántas copias de lo que posees llevas
/// (legalidad relajada: ≥3 Rutinas). Las SUBRUTINAS aparecen BLOQUEADAS (rojo
/// glitcheado) hasta ganar 3 duelos. Accesible desde el menú de las 3 rutas.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:nodehack_engine/card_instance.dart';
import 'package:nodehack_engine/cards.dart';

import '../theme/tokens.dart';
import '../widgets/card_view.dart';
import 'adventure_data.dart';
import 'adventure_state.dart';

class AdventureDeckScreen extends StatelessWidget {
  final AdventureState st;
  final VoidCallback onBack;
  final void Function(CardInstance) onZoom;
  const AdventureDeckScreen({super.key, required this.st, required this.onBack, required this.onZoom});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: st,
      builder: (context, _) {
        final rutIds = st.collection.keys.where((id) => kRutById.containsKey(id)).toList()..sort();
        final subIds = st.collection.keys.where((id) => kSubById.containsKey(id)).toList()..sort();
        final deck = st.advDeck;
        final legal = deck.isLegalAdventure;
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, NH.safe + 6, 14, 6),
            child: Row(children: [
              GestureDetector(onTap: onBack, child: Text('‹ VOLVER', style: NH.mono(size: 11, color: NH.ink2, spacing: 1))),
              Expanded(
                child: Center(
                  child: Text('MAZO DE AVENTURA',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: NH.disp(size: 14, weight: FontWeight.w700, color: const Color(0xFFEAF7FF), spacing: 2)),
                ),
              ),
              Text('R:${deck.rutCount} S:${deck.subCount}',
                  style: NH.mono(size: 10, weight: FontWeight.w700, color: legal ? NH.pl : NH.xp)),
            ]),
          ),
          if (!legal)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('Lleva al menos 3 Rutinas para poder sumergirte.',
                  style: NH.mono(size: 9, color: NH.xp, spacing: .5)),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, NH.safe + 16),
              children: [
                _sectionHeader('RUTINAS', NH.fw),
                for (final id in rutIds) _ownedRow(id),
                const SizedBox(height: 14),
                _sectionHeader('SUBRUTINAS', st.subsUnlocked ? NH.nl : NH.xp),
                if (!st.subsUnlocked) ...[
                  const SizedBox(height: 6),
                  Text('BLOQUEADAS · gana 3 duelos para descifrarlas.',
                      style: NH.mono(size: 9.5, weight: FontWeight.w700, color: NH.xp, spacing: .5)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final id in kLockedSub) _LockedSub(id: id)]),
                ] else if (subIds.isEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Aún no tienes Subrutinas. Consíguelas como botín o en la tienda.',
                      style: NH.mono(size: 9.5, color: NH.dim, height: 1.4)),
                ] else
                  for (final id in subIds) _ownedRow(id),
              ],
            ),
          ),
        ]);
      },
    );
  }

  Widget _sectionHeader(String t, Color c) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Container(width: 3, height: 14, color: c),
          const SizedBox(width: 8),
          Text(t, style: NH.mono(size: 11, weight: FontWeight.w700, color: c, spacing: 2)),
        ]),
      );

  Widget _ownedRow(String id) {
    final card = cardInstanceOf(id);
    final inDeck = st.inDeck(id);
    final owned = st.owned(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: NH.a(const Color(0xFF090C12), .7),
        border: Border.all(color: NH.line),
      ),
      child: Row(children: [
        GestureDetector(onTap: () => onZoom(card), child: CardView(card: card, width: 50)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(card.name, style: NH.disp(size: 13, weight: FontWeight.w700, color: const Color(0xFFEAF1FB), spacing: .5)),
            const SizedBox(height: 2),
            Text('en mazo $inDeck / $owned', style: NH.mono(size: 8.5, color: NH.dim, spacing: 1)),
          ]),
        ),
        _stepper(
          onMinus: inDeck > 0 ? () => st.setInDeck(id, inDeck - 1) : null,
          onPlus: inDeck < owned ? () => st.setInDeck(id, inDeck + 1) : null,
          value: inDeck,
        ),
      ]),
    );
  }

  Widget _stepper({required VoidCallback? onMinus, required VoidCallback? onPlus, required int value}) {
    Widget btn(String s, VoidCallback? on) => GestureDetector(
          onTap: on,
          child: Container(
            width: 30, height: 30, alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: on == null ? NH.dim2 : NH.fw),
              color: on == null ? null : NH.a(NH.fw, .08),
            ),
            child: Text(s, style: NH.mono(size: 16, weight: FontWeight.w700, color: on == null ? NH.dim2 : NH.fw)),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      btn('−', onMinus),
      SizedBox(width: 26, child: Center(child: Text('$value', style: NH.mono(size: 14, weight: FontWeight.w700, color: const Color(0xFFEAF1FB))))),
      btn('+', onPlus),
    ]);
  }
}

/// Subrutina BLOQUEADA: placeholder rojizo con un glitch sutil (no jugable aún).
class _LockedSub extends StatefulWidget {
  final String id;
  const _LockedSub({required this.id});
  @override
  State<_LockedSub> createState() => _LockedSubState();
}

class _LockedSubState extends State<_LockedSub> with SingleTickerProviderStateMixin {
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
    final name = kSubById[widget.id]?.name ?? '???';
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final p = (sin(_c.value * pi * 6).abs()); // parpadeo
        final dx = sin(_c.value * pi * 8) * 1.6;
        Widget glyph(Color col, double off) => Transform.translate(
              offset: Offset(off, 0),
              child: Text('?', style: NH.disp(size: 26, weight: FontWeight.w700, color: col)),
            );
        return Container(
          width: 84, height: 96,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: NH.a(NH.xp, .06),
            border: Border.all(color: NH.a(NH.xp, .55)),
            boxShadow: [BoxShadow(color: NH.a(NH.xp, .12 + .12 * p), blurRadius: 10)],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              height: 34,
              child: Stack(alignment: Alignment.center, children: [
                glyph(NH.a(NH.fw, .5 * p), -dx),
                glyph(NH.a(NH.xp, .6), dx),
                glyph(NH.a(const Color(0xFFEAF1FB), .85), 0),
              ]),
            ),
            const SizedBox(height: 4),
            Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: NH.mono(size: 7.5, color: NH.a(NH.xp, .9), height: 1.2)),
            const SizedBox(height: 2),
            Text('🔒', style: NH.mono(size: 9, color: NH.xp)),
          ]),
        );
      },
    );
  }
}
