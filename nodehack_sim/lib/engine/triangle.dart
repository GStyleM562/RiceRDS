/// Lógica del triángulo y resolución de espejos.
/// CORTAFUEGOS > EXPLOIT > PULSO > CORTAFUEGOS.
library;

import 'models.dart';

/// ¿`a` vence a `b` por triángulo (sin contar Ciclos/Núcleo)?
/// `invertido` aplica INVERSIÓN DE POLARIDAD.
bool venceTipo(Tipo a, Tipo b, {bool invertido = false}) {
  if (a == b) return false;
  final normal = a.siguiente == b; // a vence al siguiente (cortafuegos vence exploit)
  return invertido ? !normal : normal;
}

/// Resultado de comparar dos Rutinas ya resueltas (tras anulaciones/ciclo/ciclos).
/// Devuelve 0 = empate, 1 = gana A, 2 = gana B.
int matchup({
  required Tipo tipoA,
  required Tipo tipoB,
  required int ciclosA,
  required int ciclosB,
  required bool anuladaA,
  required bool anuladaB,
  required bool invertido,
  required Tipo? alineacionA,
  required Tipo? alineacionB,
}) {
  // Cualquier anulación ⇒ EMPATE (negación, no robo) — v0.3.
  if (anuladaA || anuladaB) return 0;

  if (tipoA == tipoB) {
    // Espejo: gana mayor Ciclos → Núcleo alineado → empate.
    if (ciclosA != ciclosB) return ciclosA > ciclosB ? 1 : 2;
    final aAlineado = alineacionA == tipoA;
    final bAlineado = alineacionB == tipoB;
    if (aAlineado && !bAlineado) return 1;
    if (bAlineado && !aAlineado) return 2;
    return 0; // ambos o ninguno alineado
  }

  return venceTipo(tipoA, tipoB, invertido: invertido) ? 1 : 2;
}
