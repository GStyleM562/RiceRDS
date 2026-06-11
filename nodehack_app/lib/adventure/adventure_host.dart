/// Anfitrión visual del modo INMERSIÓN: pinta la sub-pantalla según `ctrl.step`
/// (elección de 3 caminos, lore pre-combate, draft de botín, tienda, fragmento/
/// mutación, intro de jefe, fin de tramo). El COMBATE lo monta `main` con la mesa.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:nodehack_engine/card_instance.dart';

import '../theme/tokens.dart';
import '../widgets/card_view.dart';
import '../widgets/matrix_rain.dart';
import 'adventure_controller.dart';
import 'adventure_data.dart';
import 'adventure_state.dart';

class AdventureHost extends StatelessWidget {
  final AdventureController ctrl;
  final void Function(CardInstance) onZoom;
  final VoidCallback onExit;
  final VoidCallback onEnterCombat; // monta el duelo (lo crea main)
  const AdventureHost({
    super.key,
    required this.ctrl,
    required this.onZoom,
    required this.onExit,
    required this.onEnterCombat,
  });

  AdventureState get st => ctrl.st;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) => Stack(children: [
        const Positioned.fill(child: ColoredBox(color: NH.bg)),
        Positioned.fill(child: MatrixRain(intensity: 3, message: 'NULL_DIVE', opacity: .22)),
        SafeArea(
          child: Column(children: [
            _topBar(),
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: _body())),
          ]),
        ),
      ]),
    );
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Row(children: [
          GestureDetector(onTap: onExit, child: Text('‹ SALIR', style: NH.mono(size: 11, color: NH.ink2, spacing: 1))),
          const Spacer(),
          Text('INMERSIÓN · sector ${st.sector}', style: NH.mono(size: 10, color: NH.dim, spacing: 1)),
          const Spacer(),
          Text('◆ ${st.credits}', style: NH.mono(size: 12, weight: FontWeight.w700, color: NH.amber)),
        ]),
      );

  Widget _body() {
    switch (ctrl.step) {
      case AdvStep.path:
        return _pathView();
      case AdvStep.loreIntro:
        return _loreView(boss: false);
      case AdvStep.bossIntro:
        return _loreView(boss: true);
      case AdvStep.reward:
        return _rewardView();
      case AdvStep.shop:
        return _shopView();
      case AdvStep.fragment:
        return _fragmentView();
      case AdvStep.sectorEnd:
        return _sectorEndView();
      case AdvStep.combat:
        return const SizedBox.shrink(); // lo monta main (MatchScreen)
    }
  }

  // ── ELECCIÓN DE CAMINO (3 cartas crípticas) ──
  Widget _pathView() {
    return Column(children: [
      const SizedBox(height: 8),
      Text('TRES RUTAS', style: NH.disp(size: 22, weight: FontWeight.w700, color: const Color(0xFFEAF7FF), spacing: 3)),
      const SizedBox(height: 6),
      Text('El sistema no te muestra a dónde llevan.\nElige con el instinto.',
          textAlign: TextAlign.center, style: NH.mono(size: 10, color: NH.dim, height: 1.5)),
      const Spacer(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [for (var i = 0; i < ctrl.paths.length; i++) _pathCard(i)],
      ),
      const Spacer(flex: 2),
    ]);
  }

  Widget _pathCard(int i) {
    return GestureDetector(
      onTap: () => ctrl.choosePath(i),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(alignment: Alignment.center, children: [
          CardBackView(width: 92, seed: 13 + i * 7),
          Container(
            width: 92,
            height: 128,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: NH.a(NH.bg, .35),
              border: Border.all(color: NH.a(NH.fw, .55)),
              boxShadow: [BoxShadow(color: NH.a(NH.fw, .18), blurRadius: 14)],
            ),
            child: Text(const ['?', '▒', '∅'][i % 3],
                style: NH.disp(size: 34, weight: FontWeight.w700, color: NH.a(NH.fw, .8))),
          ),
        ]),
        const SizedBox(height: 6),
        _signalBar(i),
      ]),
    );
  }

  // Barra de "señal" cosmética (no revela el tipo — sigue siendo críptico).
  Widget _signalBar(int i) {
    final bars = 1 + ((i * 2 + ctrl.st.battles) % 3);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var b = 0; b < 3; b++)
        Container(
          width: 7, height: 4, margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: b < bars ? NH.a(NH.fw, .8) : NH.a(NH.dim2, .6),
          ),
        ),
    ]);
  }

  // ── LORE PRE-COMBATE / INTRO DE JEFE ──
  Widget _loreView({required bool boss}) {
    final e = ctrl.enemy;
    final accent = boss ? NH.nl : NH.fw;
    return Column(children: [
      const Spacer(),
      Text(boss ? '∅ // KERNEL' : '∅ // SYS', style: NH.mono(size: 11, color: accent, spacing: 3)),
      const SizedBox(height: 16),
      _Typed(text: ctrl.preLore, color: const Color(0xFFEAF7FF)),
      const SizedBox(height: 22),
      if (e != null) ...[
        Text(boss ? 'EL PROCESO FINAL DEL TRAMO' : 'PROCESO DETECTADO', style: NH.mono(size: 8.5, color: NH.dim, spacing: 2)),
        const SizedBox(height: 4),
        Text(e.name, style: NH.disp(size: 20, weight: FontWeight.w700, color: accent, spacing: 1)),
        const SizedBox(height: 6),
        Text(e.flavor, textAlign: TextAlign.center, style: NH.mono(size: 10, color: NH.ink2, height: 1.5)),
      ],
      const Spacer(flex: 2),
      _wideBtn(boss ? 'ENFRENTAR AL KERNEL ▸' : 'EJECUTAR DUELO ▸', accent, onEnterCombat),
      const SizedBox(height: 24),
    ]);
  }

  // ── BOTÍN (draft 1 de 3) ──
  Widget _rewardView() {
    return Column(children: [
      const SizedBox(height: 12),
      Text('BOTÍN RECUPERADO', style: NH.disp(size: 20, weight: FontWeight.w700, color: NH.pl, spacing: 2)),
      const SizedBox(height: 4),
      Text('Elige una carta para tu colección de aventura.',
          textAlign: TextAlign.center, style: NH.mono(size: 10, color: NH.dim)),
      const Spacer(),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [for (final id in ctrl.rewardChoices) _rewardCard(id)],
      ),
      const Spacer(),
      GestureDetector(
        onTap: () => ctrl.chooseReward(null),
        child: Text('SALTAR · +$kRewardCredits ◆', style: NH.mono(size: 11, color: NH.dim, spacing: 1)),
      ),
      const SizedBox(height: 20),
    ]);
  }

  Widget _rewardCard(String id) {
    final card = cardInstanceOf(id);
    final isNew = st.owned(id) == 0;
    return GestureDetector(
      onTap: () => ctrl.chooseReward(id),
      onLongPress: () => onZoom(card),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CardView(card: card, width: 92),
        const SizedBox(height: 4),
        Text(isNew ? 'NUEVA' : 'COPIA +1',
            style: NH.mono(size: 8, weight: FontWeight.w700, color: isNew ? NH.pl : NH.dim, spacing: 1)),
      ]),
    );
  }

  // ── TIENDA (CUARENTENA) ──
  Widget _shopView() {
    return Column(children: [
      const SizedBox(height: 12),
      Text('CUARENTENA', style: NH.disp(size: 20, weight: FontWeight.w700, color: NH.fw, spacing: 3)),
      const SizedBox(height: 4),
      Text('Intercambia créditos por procesos contenidos.',
          textAlign: TextAlign.center, style: NH.mono(size: 10, color: NH.dim)),
      const SizedBox(height: 16),
      Expanded(
        child: ListView(
          children: [for (final o in ctrl.shopOffers) _shopRow(o)],
        ),
      ),
      _wideBtn('SALIR DE LA CUARENTENA', NH.fw, ctrl.leaveShop),
      const SizedBox(height: 18),
    ]);
  }

  Widget _shopRow(ShopOffer o) {
    final card = cardInstanceOf(o.cardId);
    final canBuy = st.credits >= o.price && !st.atCap(o.cardId);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: NH.a(const Color(0xFF090C12), .7),
        border: Border.all(color: NH.line),
      ),
      child: Row(children: [
        GestureDetector(onTap: () => onZoom(card), child: CardView(card: card, width: 56)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(card.name, style: NH.disp(size: 13, weight: FontWeight.w700, color: const Color(0xFFEAF1FB), spacing: .5)),
            const SizedBox(height: 3),
            Text(st.atCap(o.cardId) ? 'AL MÁXIMO' : '◆ ${o.price}',
                style: NH.mono(size: 11, weight: FontWeight.w700, color: st.atCap(o.cardId) ? NH.dim : NH.amber)),
          ]),
        ),
        GestureDetector(
          onTap: canBuy ? () => ctrl.buy(o) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: canBuy ? NH.fw : NH.dim2),
              color: canBuy ? NH.a(NH.fw, .1) : null,
            ),
            child: Text('COMPRAR', style: NH.mono(size: 10, weight: FontWeight.w700, color: canBuy ? NH.fw : NH.dim2, spacing: 1)),
          ),
        ),
      ]),
    );
  }

  // ── FRAGMENTO / MUTACIÓN ──
  Widget _fragmentView() {
    if (ctrl.isMutation) return _mutationView();
    final f = ctrl.frag!;
    return Column(children: [
      const Spacer(),
      Text('∅ // FRAGMENTO', style: NH.mono(size: 11, color: NH.fw, spacing: 3)),
      const SizedBox(height: 16),
      _Typed(text: f.text, color: const Color(0xFFEAF7FF)),
      const Spacer(flex: 2),
      _wideBtn(f.optA, NH.pl, () => ctrl.chooseFragment(true)),
      const SizedBox(height: 10),
      _wideBtn(f.optB, NH.dim, () => ctrl.chooseFragment(false), ghost: true),
      const SizedBox(height: 24),
    ]);
  }

  Widget _mutationView() {
    return Column(children: [
      const SizedBox(height: 10),
      Text('MUTACIÓN', style: NH.disp(size: 22, weight: FontWeight.w700, color: NH.nl, spacing: 3)),
      const SizedBox(height: 10),
      _Typed(text: kMutationIntro, color: const Color(0xFFEAF7FF)),
      const SizedBox(height: 14),
      Expanded(
        child: ListView(children: [
          for (final n in ctrl.mutationChoices) _natureRow(n),
        ]),
      ),
      GestureDetector(
        onTap: () => ctrl.chooseMutation(null),
        child: Text('CONSERVAR MI NATURALEZA (${st.nature.name})', style: NH.mono(size: 10, color: NH.dim, spacing: 1)),
      ),
      const SizedBox(height: 18),
    ]);
  }

  Widget _natureRow(NatureDef n) => GestureDetector(
        onTap: () => ctrl.chooseMutation(n.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: NH.a(NH.nl, .06),
            border: Border.all(color: NH.a(NH.nl, .5)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(n.name, style: NH.disp(size: 14, weight: FontWeight.w700, color: const Color(0xFFEAF1FB), spacing: 1)),
            const SizedBox(height: 3),
            Text(n.blurb, style: NH.mono(size: 9.5, color: NH.ink2, height: 1.4)),
            const SizedBox(height: 4),
            Text(n.endingHint, style: NH.mono(size: 8.5, weight: FontWeight.w700, color: NH.a(NH.nl, .9), spacing: .5)),
          ]),
        ),
      );

  // ── FIN DE TRAMO ──
  Widget _sectorEndView() {
    return Column(children: [
      const Spacer(),
      Text('TRAMO PURGADO', style: NH.disp(size: 24, weight: FontWeight.w700, color: NH.pl, spacing: 2)),
      const SizedBox(height: 10),
      Text('Has llegado más lejos que casi todos los procesos.',
          textAlign: TextAlign.center, style: NH.mono(size: 10, color: NH.ink2, height: 1.5)),
      const SizedBox(height: 18),
      Text('NATURALEZA ACTUAL', style: NH.mono(size: 8.5, color: NH.dim, spacing: 2)),
      const SizedBox(height: 4),
      Text(st.nature.name, style: NH.disp(size: 18, weight: FontWeight.w700, color: NH.nl, spacing: 1)),
      const SizedBox(height: 4),
      Text(st.nature.endingHint, textAlign: TextAlign.center, style: NH.mono(size: 10, color: NH.a(NH.nl, .9))),
      const Spacer(flex: 2),
      _wideBtn('SEGUIR DESCENDIENDO ▸', NH.pl, ctrl.continueAfterSector),
      const SizedBox(height: 10),
      GestureDetector(onTap: onExit, child: Text('GUARDAR Y SALIR', style: NH.mono(size: 11, color: NH.dim, spacing: 1))),
      const SizedBox(height: 24),
    ]);
  }

  // ── Botón ancho reutilizable ──
  Widget _wideBtn(String label, Color accent, VoidCallback onTap, {bool ghost = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: ghost ? null : NH.a(accent, .1),
          border: Border.all(color: ghost ? NH.a(accent, .5) : accent, width: 1.2),
          boxShadow: ghost ? null : [BoxShadow(color: NH.a(accent, .22), blurRadius: 14)],
        ),
        child: Center(
          child: Text(label, textAlign: TextAlign.center, style: NH.mono(size: 12, weight: FontWeight.w700, color: ghost ? NH.dim : accent, spacing: 1.5)),
        ),
      ),
    );
  }
}

/// Texto que se escribe carácter a carácter (typewriter), como el intro.
class _Typed extends StatefulWidget {
  final String text;
  final Color color;
  const _Typed({required this.text, required this.color});
  @override
  State<_Typed> createState() => _TypedState();
}

class _TypedState extends State<_Typed> {
  int _chars = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(_Typed old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _start();
  }

  void _start() {
    _chars = 0;
    _t?.cancel();
    _t = Timer.periodic(const Duration(milliseconds: 24), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_chars >= widget.text.length) {
        t.cancel();
        return;
      }
      setState(() => _chars++);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text.substring(0, _chars.clamp(0, widget.text.length)),
      textAlign: TextAlign.center,
      style: NH.mono(size: 14, color: widget.color, height: 1.6),
    );
  }
}
