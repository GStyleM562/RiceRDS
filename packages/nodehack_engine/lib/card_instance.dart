/// Instancia de carta en juego (un proceso manifestado desde datos).
library;

import 'cards.dart';
import 'types.dart';

int _uidCounter = 0;

class CardInstance {
  final String uid;
  final bool isSub;
  final RutinaDef? rut;
  final SubDef? sub;
  CType? declaredType; // NULL-SHARD declara su tipo

  CardInstance._(this.uid, this.isSub, this.rut, this.sub);

  factory CardInstance.rutina(RutinaDef def) =>
      CardInstance._('c${++_uidCounter}', false, def, null);
  factory CardInstance.subrutina(SubDef def) =>
      CardInstance._('c${++_uidCounter}', true, null, def);

  String get name => isSub ? sub!.name : rut!.name;
  String get proc => isSub ? sub!.proc : rut!.proc;
  Rareza get rar => isSub ? sub!.rar : rut!.rar;
  String get txt => isSub ? sub!.txt : rut!.txt;
  int get ram => isSub ? sub!.ram : 0;
  int get ciclos => isSub ? 0 : rut!.ciclos;

  /// Tipo de triángulo (para Rutinas): el declarado si existe, si no el base.
  CType get type => isSub ? CType.nul : (declaredType ?? rut!.type);

  /// Tipo "base" sin declarar (para saber si es comodín NULL).
  CType get baseType => isSub ? CType.nul : rut!.type;

  bool get esComodinNull => !isSub && rut!.type == CType.nul;

  String get defId => isSub ? sub!.id : rut!.id;

  // ---- Serialización (red PVP) ----
  // Sólo el id de definición + uid + tipo declarado: la definición completa se
  // reconstruye desde el catálogo (kRutById/kSubById), idéntico en cliente y servidor.
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'isSub': isSub,
        'defId': defId,
        if (declaredType != null) 'declared': cTypeId(declaredType!),
      };

  /// Restaura una instancia **conservando su uid** (para poder referenciarla de
  /// vuelta por uid al programar la jugada).
  factory CardInstance.fromJson(Map<String, dynamic> j) {
    final uid = j['uid'] as String;
    final isSub = j['isSub'] as bool;
    final defId = j['defId'] as String;
    final c = isSub
        ? CardInstance._(uid, true, null, kSubById[defId]!)
        : CardInstance._(uid, false, kRutById[defId]!, null);
    c.declaredType = cTypeFromId(j['declared'] as String?);
    return c;
  }
}
