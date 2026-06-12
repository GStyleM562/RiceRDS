import 'package:flutter/material.dart';

import 'package:nodehack_engine/card_instance.dart';
import 'package:nodehack_engine/cards.dart';
import 'package:nodehack_engine/deck.dart';
import 'package:nodehack_engine/types.dart';
import '../audio/audio_service.dart';
import '../theme/tokens.dart';
import '../widgets/card_view.dart';
import '../widgets/chrome.dart';
import '../widgets/sigil.dart';

class DeckBuilderScreen extends StatefulWidget {
  final Deck initial;
  final VoidCallback onBack;
  final void Function(Deck) onSave;
  final void Function(CardInstance) onInspect;
  /// ¿La carta está bloqueada en multijugador? (y cuántas partidas faltan).
  final bool Function(String id)? cardLocked;
  final int Function(String id)? gamesLeft;
  const DeckBuilderScreen({
    super.key,
    required this.initial,
    required this.onBack,
    required this.onSave,
    required this.onInspect,
    this.cardLocked,
    this.gamesLeft,
  });

  @override
  State<DeckBuilderScreen> createState() => _DeckBuilderScreenState();
}

class _DeckBuilderScreenState extends State<DeckBuilderScreen> {
  late final Deck d = widget.initial.copy();
  bool rutTab = true;
  late final TextEditingController _name = TextEditingController(text: d.name);

  @override
  void initState() {
    super.initState();
    AudioService.instance.playMusic(Music.deckbuild); // música de "armando mazo"
  }

  @override
  void dispose() {
    _name.dispose();
    AudioService.instance.playMusic(Music.menu); // al salir, vuelve la del menú
    super.dispose();
  }

  int get total => rutTab ? d.rutCount : d.subCount;
  int get target => rutTab ? kRutTarget : kSubTarget;
  int get maxCopies => rutTab ? kMaxRutCopies : kMaxSubCopies;

  void inc(String id, int delta) {
    final map = rutTab ? d.rut : d.sub;
    final cur = map[id] ?? 0;
    if (delta > 0 && total >= target) return;
    final nv = (cur + delta).clamp(0, maxCopies);
    setState(() {
      if (nv == 0) {
        map.remove(id);
      } else {
        map[id] = nv;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ready = d.isLegal;
    return Stack(children: [
      const GridBg(),
      Column(children: [
        TopBar(title: 'CONSTRUCTOR DE MAZO', onBack: widget.onBack),
        // nombre
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _name,
            style: NH.disp(size: 15, weight: FontWeight.w600, color: NH.ink),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.edit, size: 14, color: NH.dim),
              prefixIconConstraints: const BoxConstraints(minWidth: 30),
              hintText: 'NOMBRE DEL MAZO',
              hintStyle: NH.mono(size: 12, color: NH.dim2),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1C2533))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: NH.fw)),
            ),
            onChanged: (v) => d.name = v.trim().isEmpty ? 'MAZO' : v.trim(),
          ),
        ),
        // selector de Núcleo (cada mazo lleva el suyo)
        _nucleoSelector(),
        // contadores
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Expanded(child: _counter('RUTINAS', d.rutCount, kRutTarget, rutTab, () => setState(() => rutTab = true))),
            const SizedBox(width: 10),
            Expanded(child: _counter('SUBRUTINAS', d.subCount, kSubTarget, !rutTab, () => setState(() => rutTab = false))),
          ]),
        ),
        // pool
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            children: [
              if (rutTab)
                for (final r in kRutinas) _row(CardInstance.rutina(r), r.name, r.txt, '${r.type.label} · ${r.ciclos} CYC', r.rar, r.id, Color(r.type.color))
              else
                // Las cartas SOLO de Historia no aparecen en el Versus.
                for (final s in kSubrutinas)
                  if (!kStoryOnlyCardIds.contains(s.id))
                    _row(CardInstance.subrutina(s), s.name, s.txt, 'RAM ${s.ram}', s.rar, s.id, NH.ink2),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, NH.safe + 8),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: NH.line))),
          child: BtnWide(
            ready ? 'GUARDAR MAZO ▸' : 'FALTAN ${(kRutTarget - d.rutCount) + (kSubTarget - d.subCount)} CARTAS',
            variant: ready ? BtnVariant.primary : BtnVariant.muted,
            onTap: ready ? () { d.name = _name.text.trim().isEmpty ? 'MAZO' : _name.text.trim(); widget.onSave(d); } : null,
          ),
        ),
      ]),
    ]);
  }

  Widget _nucleoSelector() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('NÚCLEO DEL MAZO', style: NH.mono(size: 8, color: NH.dim, spacing: 1.8)),
          const SizedBox(height: 5),
          Row(children: [
            for (var k = 0; k < kNucleos.length; k++) ...[
              if (k > 0) const SizedBox(width: 6),
              Expanded(child: _nucChip(kNucleos[k])),
            ],
          ]),
        ]),
      );

  Widget _nucChip(NucleoDef n) {
    final sel = d.nucleoId == n.id;
    final col = Color(n.color);
    return GestureDetector(
      onTap: () => setState(() => d.nucleoId = n.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: sel ? NH.mix(col, Colors.transparent, .16) : NH.a(NH.panel, .5),
          border: Border.all(color: sel ? col : const Color(0xFF1C2533)),
          boxShadow: sel ? [BoxShadow(color: NH.a(col, .25), blurRadius: 12)] : null,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Sigil(type: n.type, size: 18),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(n.name, style: NH.mono(size: 8, weight: FontWeight.w700, color: sel ? col : NH.dim, spacing: .4)),
          ),
        ]),
      ),
    );
  }

  Widget _counter(String label, int n, int tgt, bool active, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: NH.a(NH.panel, .6),
            border: Border.all(color: active ? NH.fw : const Color(0xFF1C2533)),
            boxShadow: active ? [BoxShadow(color: NH.a(NH.fw, .18), blurRadius: 16)] : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: NH.mono(size: 9, color: NH.dim, spacing: 1.8)),
            const SizedBox(height: 3),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$n', style: NH.mono(size: 22, weight: FontWeight.w700, color: n == tgt ? NH.pl : NH.ink)),
              Text('/$tgt', style: NH.mono(size: 11, color: NH.dim)),
            ]),
          ]),
        ),
      );

  Widget _row(CardInstance inst, String name, String txt, String meta, Rareza rar, String id, Color metaColor) {
    final c = (rutTab ? d.rut : d.sub)[id] ?? 0;
    final locked = widget.cardLocked?.call(id) ?? false;
    return Opacity(
      opacity: locked ? .55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: NH.a(const Color(0xFF090C12), .6),
          border: Border.all(color: locked ? NH.a(NH.xp, .4) : (c > 0 ? const Color(0xFF243247) : const Color(0xFF151C28))),
        ),
        child: Row(children: [
          GestureDetector(
            onTap: () => widget.onInspect(inst),
            child: ClipRRect(borderRadius: BorderRadius.circular(4), child: CardView(card: inst, width: 50, animate: false)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: NH.disp(size: 14, weight: FontWeight.w600, color: const Color(0xFFEAF1FB))),
              const SizedBox(height: 2),
              Text(txt, style: NH.mono(size: 9, color: NH.dim, height: 1.4)),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(meta, style: NH.mono(size: 8, color: metaColor, spacing: .6)),
                Text(rar.label, style: NH.mono(size: 8, color: NH.dim2, spacing: .6)),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          if (locked)
            SizedBox(
              width: 34,
              child: Column(children: [
                const Text('🔒', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 3),
                Text('${widget.gamesLeft?.call(id) ?? 0}p', style: NH.mono(size: 8, weight: FontWeight.w700, color: NH.xp)),
              ]),
            )
          else
            Column(children: [
              _stepBtn('−', c > 0, () => inc(id, -1)),
              Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('$c', style: NH.mono(size: 14, weight: FontWeight.w700, color: const Color(0xFFEAF1FB)))),
              _stepBtn('+', c < maxCopies && total < target, () => inc(id, 1)),
            ]),
        ]),
      ),
    );
  }

  Widget _stepBtn(String s, bool enabled, VoidCallback onTap) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1 : .3,
          child: Container(
            width: 28, height: 28, alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: const Color(0xFF0C1118), border: Border.all(color: const Color(0xFF2A3344))),
            child: Text(s, style: NH.mono(size: 16, color: NH.ink2, height: 1)),
          ),
        ),
      );
}
