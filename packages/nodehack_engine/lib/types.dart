/// Tipos del triángulo y tokens de datos (portado de game-data.js).
/// Motor Flutter-agnóstico: colores como int ARGB (la UI los convierte).
library;

enum CType { firewall, exploit, signal, nul }

/// firewall ▸ vence exploit ▸ vence signal ▸ vence firewall.
const Map<CType, CType?> kTriangle = {
  CType.firewall: CType.exploit,
  CType.exploit: CType.signal,
  CType.signal: CType.firewall,
  CType.nul: null,
};

extension CTypeX on CType {
  String get label => switch (this) {
        CType.firewall => 'CORTAFUEGOS',
        CType.exploit => 'EXPLOIT',
        CType.signal => 'PULSO',
        CType.nul => 'NULL',
      };

  String get short => switch (this) {
        CType.firewall => 'FW',
        CType.exploit => 'XP',
        CType.signal => 'PL',
        CType.nul => '∅',
      };

  /// Color del tipo (ARGB int).
  int get color => switch (this) {
        CType.firewall => 0xFF3FC7EC,
        CType.exploit => 0xFFFF4068,
        CType.signal => 0xFF26E6A4,
        CType.nul => 0xFFB061FF,
      };

  CType? get beats => kTriangle[this];

  /// Tipo siguiente en el ciclo (firewall→exploit→signal→firewall).
  CType get next => switch (this) {
        CType.firewall => CType.exploit,
        CType.exploit => CType.signal,
        CType.signal => CType.firewall,
        CType.nul => CType.nul,
      };

  /// Tipo anterior en el ciclo.
  CType get prev => switch (this) {
        CType.exploit => CType.firewall,
        CType.signal => CType.exploit,
        CType.firewall => CType.signal,
        CType.nul => CType.nul,
      };

  /// ¿`this` vence a `o` por triángulo puro (sin Ciclos/NULL)?
  bool venceA(CType o) => kTriangle[this] == o;
}

CType? cTypeFromId(String? id) => switch (id) {
      'firewall' => CType.firewall,
      'exploit' => CType.exploit,
      'signal' => CType.signal,
      'null' => CType.nul,
      _ => null,
    };

String cTypeId(CType t) => switch (t) {
      CType.firewall => 'firewall',
      CType.exploit => 'exploit',
      CType.signal => 'signal',
      CType.nul => 'null',
    };

enum Rareza { c, r, e, n }

extension RarezaX on Rareza {
  String get label => switch (this) {
        Rareza.c => 'COMÚN',
        Rareza.r => 'RARA',
        Rareza.e => 'ÉPICA',
        Rareza.n => 'NULL',
      };
}

/// Acento ámbar (RAM / aviso).
const int kAmber = 0xFFFFB43F;
