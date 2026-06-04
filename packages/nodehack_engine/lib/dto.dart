/// DTOs de red compartidos por app y servidor PVP. Definen el *contrato* de datos
/// (no los sobres de mensaje, que viven en el protocolo del servidor/cliente).
library;

import 'card_instance.dart';
import 'types.dart';

/// Lo que el CLIENTE envía para programar su ronda: referencias **por uid** a
/// cartas de SU mano (el servidor es la autoridad y valida que estén en mano,
/// que la RAM alcance y que sean ≤2 subrutinas). `declaredType` sólo aplica si la
/// Rutina elegida es un NULL-SHARD.
class PlaySubmission {
  final String rutinaUid;
  final CType? declaredType;
  final List<String> subUids;

  PlaySubmission({required this.rutinaUid, this.declaredType, this.subUids = const []});

  Map<String, dynamic> toJson() => {
        'rutinaUid': rutinaUid,
        if (declaredType != null) 'declared': cTypeId(declaredType!),
        'subUids': subUids,
      };

  factory PlaySubmission.fromJson(Map<String, dynamic> j) => PlaySubmission(
        rutinaUid: j['rutinaUid'] as String,
        declaredType: cTypeFromId(j['declared'] as String?),
        subUids: List<String>.from((j['subUids'] as List?) ?? const []),
      );
}

/// Estado PÚBLICO de la partida (sin manos ocultas), **relativo al receptor**
/// (you = el cliente que lo recibe). El servidor lo construye dos veces, una por
/// jugador, intercambiando you↔opp.
class PublicState {
  final int round;
  final int integrityYou;
  final int integrityOpp;
  final int integrityMaxYou;
  final int integrityMaxOpp;
  final String nucYouId;
  final String nucOppId;
  final int rutPileYou;
  final int subPileYou;
  final int rutPileOpp;
  final int subPileOpp;
  final bool gameOver;
  final String? outcome; // 'win' | 'lose' (perspectiva del receptor)

  PublicState({
    required this.round,
    required this.integrityYou,
    required this.integrityOpp,
    required this.integrityMaxYou,
    required this.integrityMaxOpp,
    required this.nucYouId,
    required this.nucOppId,
    required this.rutPileYou,
    required this.subPileYou,
    required this.rutPileOpp,
    required this.subPileOpp,
    this.gameOver = false,
    this.outcome,
  });

  Map<String, dynamic> toJson() => {
        'round': round,
        'integrityYou': integrityYou,
        'integrityOpp': integrityOpp,
        'integrityMaxYou': integrityMaxYou,
        'integrityMaxOpp': integrityMaxOpp,
        'nucYouId': nucYouId,
        'nucOppId': nucOppId,
        'rutPileYou': rutPileYou,
        'subPileYou': subPileYou,
        'rutPileOpp': rutPileOpp,
        'subPileOpp': subPileOpp,
        'gameOver': gameOver,
        if (outcome != null) 'outcome': outcome,
      };

  factory PublicState.fromJson(Map<String, dynamic> j) => PublicState(
        round: j['round'] as int,
        integrityYou: j['integrityYou'] as int,
        integrityOpp: j['integrityOpp'] as int,
        integrityMaxYou: j['integrityMaxYou'] as int,
        integrityMaxOpp: j['integrityMaxOpp'] as int,
        nucYouId: j['nucYouId'] as String,
        nucOppId: j['nucOppId'] as String,
        rutPileYou: j['rutPileYou'] as int,
        subPileYou: j['subPileYou'] as int,
        rutPileOpp: j['rutPileOpp'] as int,
        subPileOpp: j['subPileOpp'] as int,
        gameOver: j['gameOver'] as bool? ?? false,
        outcome: j['outcome'] as String?,
      );

  /// Versión vista desde el otro jugador (intercambia you↔opp). El `outcome` se
  /// invierte salvo cuando aún no hay desenlace.
  PublicState flipped() => PublicState(
        round: round,
        integrityYou: integrityOpp,
        integrityOpp: integrityYou,
        integrityMaxYou: integrityMaxOpp,
        integrityMaxOpp: integrityMaxYou,
        nucYouId: nucOppId,
        nucOppId: nucYouId,
        rutPileYou: rutPileOpp,
        subPileYou: subPileOpp,
        rutPileOpp: rutPileYou,
        subPileOpp: subPileYou,
        gameOver: gameOver,
        outcome: switch (outcome) { 'win' => 'lose', 'lose' => 'win', _ => outcome },
      );
}

/// Serializa una mano (lista de cartas) a JSON y de vuelta.
List<Map<String, dynamic>> handToJson(List<CardInstance> hand) =>
    [for (final c in hand) c.toJson()];

List<CardInstance> handFromJson(List<dynamic> j) =>
    [for (final c in j) CardInstance.fromJson(c as Map<String, dynamic>)];
