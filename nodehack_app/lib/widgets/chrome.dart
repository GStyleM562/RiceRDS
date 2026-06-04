/// Cromos compartidos: fondo de rejilla, topbar, botón ancho.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class GridBg extends StatelessWidget {
  final Color color;
  const GridBg({super.key, this.color = NH.fw});
  @override
  Widget build(BuildContext context) =>
      Positioned.fill(child: CustomPaint(painter: _GridBgPainter(color)));
}

class _GridBgPainter extends CustomPainter {
  final Color color;
  _GridBgPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = NH.a(color, .05)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _GridBgPainter old) => false;
}

class TopBar extends StatelessWidget {
  final String title;
  final String backLabel;
  final VoidCallback onBack;
  const TopBar({super.key, required this.title, required this.onBack, this.backLabel = '‹ MENÚ'});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, NH.safe + 6, 16, 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: NH.line)),
        ),
        child: Row(
          children: [
            _BackBtn(label: backLabel, onTap: onBack),
            Expanded(
              child: Center(
                child: Text(title, style: NH.mono(size: 11, color: NH.dim, spacing: 2.4)),
              ),
            ),
            const SizedBox(width: 54),
          ],
        ),
      );
}

class _BackBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BackBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF232C3B)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(label, style: NH.mono(size: 11, color: NH.ink2, spacing: 1.1)),
        ),
      );
}

enum BtnVariant { primary, muted, ghost, loading }

class BtnWide extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final BtnVariant variant;
  const BtnWide(this.label, {super.key, this.onTap, this.variant = BtnVariant.primary});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && variant != BtnVariant.muted;
    final isPrimary = variant == BtnVariant.primary && enabled;
    final isLoading = variant == BtnVariant.loading;
    final accent = isLoading ? NH.amber : NH.fw;
    return GestureDetector(
      onTap: enabled && !isLoading ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isPrimary || isLoading ? accent : const Color(0xFF2A3344),
          ),
          gradient: isPrimary
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [NH.a(NH.fw, .16), NH.a(NH.fw, .04)],
                )
              : null,
          color: isPrimary ? null : const Color(0xFF0C1118),
          boxShadow: isPrimary
              ? [BoxShadow(color: NH.a(NH.fw, .22), blurRadius: 18)]
              : isLoading
                  ? [BoxShadow(color: NH.a(NH.amber, .2), blurRadius: 18)]
                  : null,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: NH.mono(
              size: 13,
              weight: FontWeight.w600,
              color: isPrimary
                  ? const Color(0xFFEAF7FF)
                  : isLoading
                      ? NH.amber
                      : (variant == BtnVariant.ghost ? NH.ink2 : NH.dim),
              spacing: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}
