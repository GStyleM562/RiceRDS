/// AJUSTES: utilidades de datos. Por ahora, dos acciones (con confirmación):
///  - Reiniciar "primera vez" (vuelve a mostrar intro + tutorial).
///  - Borrar el progreso de Historia (empezar la Inmersión desde cero).
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/matrix_rain.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onResetFirstTime;
  final VoidCallback onWipeStory;
  final bool hasStoryRun;
  const SettingsScreen({
    super.key,
    required this.onBack,
    required this.onResetFirstTime,
    required this.onWipeStory,
    required this.hasStoryRun,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _confirm; // id de la acción pendiente de confirmar

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const Positioned.fill(child: ColoredBox(color: NH.bg)),
      Positioned.fill(child: MatrixRain(intensity: 2, message: 'AJUSTES', opacity: .18)),
      Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, NH.safe + 6, 14, 6),
          child: Row(children: [
            GestureDetector(onTap: widget.onBack, child: Text('‹ VOLVER', style: NH.mono(size: 11, color: NH.ink2, spacing: 1))),
            const Spacer(),
            Text('AJUSTES', style: NH.disp(size: 16, weight: FontWeight.w700, color: const Color(0xFFEAF7FF), spacing: 3)),
            const Spacer(),
            const SizedBox(width: 56),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, NH.safe + 16),
            children: [
              Text('DATOS', style: NH.mono(size: 10, weight: FontWeight.w700, color: NH.fw, spacing: 2)),
              const SizedBox(height: 10),
              _tile(
                id: 'first',
                accent: NH.fw,
                title: 'REINICIAR PRIMERA VEZ',
                desc: 'Vuelve a mostrar la intro y la sugerencia de tutorial, como si abrieras el juego por primera vez. No borra mazos ni Historia.',
                action: 'REINICIAR',
                onConfirm: widget.onResetFirstTime,
              ),
              const SizedBox(height: 12),
              _tile(
                id: 'wipe',
                accent: NH.xp,
                title: 'BORRAR PROGRESO DE HISTORIA',
                desc: widget.hasStoryRun
                    ? 'Borra tu colección, créditos y avance de la Inmersión para empezar desde cero. Irreversible. No toca el Versus.'
                    : 'No hay progreso de Historia que borrar todavía.',
                action: 'BORRAR TODO',
                onConfirm: widget.hasStoryRun ? widget.onWipeStory : null,
              ),
            ],
          ),
        ),
      ]),
    ]);
  }

  Widget _tile({
    required String id,
    required Color accent,
    required String title,
    required String desc,
    required String action,
    required VoidCallback? onConfirm,
  }) {
    final confirming = _confirm == id;
    final enabled = onConfirm != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: NH.a(const Color(0xFF090C12), .72),
        border: Border.all(color: confirming ? accent : NH.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: NH.disp(size: 14, weight: FontWeight.w700, color: const Color(0xFFEAF1FB), spacing: 1)),
        const SizedBox(height: 6),
        Text(desc, style: NH.mono(size: 10, color: NH.ink2, height: 1.5)),
        const SizedBox(height: 12),
        if (!confirming)
          GestureDetector(
            onTap: enabled ? () => setState(() => _confirm = id) : null,
            child: _btn(action, enabled ? accent : NH.dim2, enabled),
          )
        else
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _confirm = null);
                  onConfirm?.call();
                },
                child: _btn('CONFIRMAR', accent, true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _confirm = null),
                child: _btn('CANCELAR', NH.dim, false),
              ),
            ),
          ]),
      ]),
    );
  }

  Widget _btn(String label, Color color, bool solid) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: solid ? NH.a(color, .1) : null,
          border: Border.all(color: NH.a(color, solid ? .8 : .5), width: 1.1),
        ),
        child: Text(label, style: NH.mono(size: 11, weight: FontWeight.w700, color: color, spacing: 1.5)),
      );
}
