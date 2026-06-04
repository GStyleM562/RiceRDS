/// Design tokens (colores, tipografías, helpers) — del handoff `game.css`.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nodehack_engine/types.dart';

class NH {
  NH._();

  // Fondos / superficies
  static const bg = Color(0xFF06080D);
  static const bg2 = Color(0xFF080B12);
  static const panel = Color(0xFF0B0F17);
  static const line = Color(0xFF161C28);
  static const cardBg = Color(0xFF05070B);

  // Tinta
  static const ink = Color(0xFFCDD6E6);
  static const ink2 = Color(0xFFAEB8C8);
  static const dim = Color(0xFF5F6B7E);
  static const dim2 = Color(0xFF46506A);

  // Tipos
  static const fw = Color(0xFF3FC7EC);
  static const xp = Color(0xFFFF4068);
  static const pl = Color(0xFF26E6A4);
  static const nl = Color(0xFFB061FF);
  static const amber = Color(0xFFFFB43F);

  static const device = Size(390, 844);
  static const safe = 20.0;

  static Color ofType(CType t) => Color(t.color);

  /// Mezcla estilo CSS color-mix(a p%, b).
  static Color mix(Color a, Color b, double pa) =>
      Color.lerp(b, a, pa.clamp(0, 1))!;

  static Color a(Color c, double opacity) => c.withValues(alpha: opacity);

  // Tipografías
  static TextStyle disp({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color color = ink,
    double spacing = 0,
    double height = 1.1,
  }) =>
      GoogleFonts.chakraPetch(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
        height: height,
      );

  static TextStyle mono({
    double size = 10,
    FontWeight weight = FontWeight.w400,
    Color color = ink2,
    double spacing = 0,
    double height = 1.3,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
        height: height,
      );
}
