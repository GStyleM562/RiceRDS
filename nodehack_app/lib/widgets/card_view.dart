/// Renderiza una carta (172×240 base) escalada a un ancho objetivo, manteniendo nitidez.
library;

import 'package:flutter/material.dart';

import 'package:nodehack_engine/card_instance.dart';
import 'game_card.dart';

double cardHeightFor(double width) => width * kCardH / kCardW;

class CardView extends StatelessWidget {
  final CardInstance card;
  final double width;
  final bool animate;
  final bool dim;
  const CardView({super.key, required this.card, required this.width, this.animate = true, this.dim = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: cardHeightFor(width),
        child: FittedBox(
          fit: BoxFit.contain,
          child: GameCard(card: card, animate: animate, dim: dim),
        ),
      );
}

class CardBackView extends StatelessWidget {
  final double width;
  final int seed;
  const CardBackView({super.key, required this.width, this.seed = 0});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: cardHeightFor(width),
        child: FittedBox(fit: BoxFit.contain, child: GameCardBack(seed: seed)),
      );
}
