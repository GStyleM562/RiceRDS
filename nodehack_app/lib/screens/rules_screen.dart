/// REGLAS: referencia rápida de una sola página (scrollable). Cada término explica,
/// de forma corta y directa, QUÉ ES · FUNCIÓN · CÓMO FUNCIONA · EJEMPLO/FAQ. Pensada
/// para repasar un concepto puntual sin rejugar el tutorial avanzado.
library;

import 'package:flutter/material.dart';

import 'package:nodehack_engine/types.dart';
import '../audio/audio_service.dart';
import '../theme/tokens.dart';
import '../widgets/sigil.dart';

class RulesScreen extends StatelessWidget {
  final VoidCallback onBack;
  const RulesScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, NH.safe + 6, 14, 6),
        child: Row(children: [
          GestureDetector(onTap: onBack, child: Text('‹ VOLVER', style: NH.mono(size: 11, color: NH.ink2, spacing: 1))),
          const Spacer(),
          Text('REGLAS', style: NH.disp(size: 16, weight: FontWeight.w700, color: const Color(0xFFEAF7FF), spacing: 3)),
          const Spacer(),
          const SizedBox(width: 56),
        ]),
      ),
      _triangleStrip(),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, NH.safe + 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 2),
              child: Text('Toca cada apartado para desplegarlo.', style: NH.mono(size: 9.5, color: NH.dim, spacing: .5)),
            ),
            const _RuleCard('LA PARTIDA', NH.fw, [
              ('Qué es', 'Un duelo 1v1 de resolución simultánea: cada ronda ambos programan una jugada en secreto y se revelan a la vez.'),
              ('Función', 'Reducir la INTEGRIDAD del rival a 0 antes de que él reduzca la tuya.'),
              ('Cómo funciona', 'Fases por ronda: ROBO → PROGRAMACIÓN → COMPILAR → REVELACIÓN → EJECUCIÓN → RESULTADO. Quien gana la ronda quita integridad al perdedor.'),
              ('FAQ', '¿Empate? Nadie pierde integridad esa ronda.'),
            ]),
            _RuleCard('INTEGRIDAD', NH.pl, [
              ('Qué es', 'Tu vida, mostrada como una fila de segmentos junto a tu Núcleo (y los del rival arriba).'),
              ('Función', 'Si llega a 0, pierdes el duelo. Es la condición de victoria/derrota.'),
              ('Cómo funciona', 'Empiezas con la que fija tu Núcleo (4 por defecto). Cada ronda perdida te quita 1 (o 2 si el rival juega FORK-BOMB). En empate, nadie pierde.'),
              ('FAQ', 'El primero en quedar a 0 pierde. La pasiva de SENTINEL anula el primer daño de la partida.'),
            ]),
            _RuleCard('EL TRIÁNGULO (TIPOS)', NH.fw, [
              ('Qué es', 'Tres tipos de Rutina: CORTAFUEGOS (cian), EXPLOIT (rojo) y PULSO (verde).'),
              ('Función', 'Deciden quién vence a quién sin mirar números.'),
              ('Cómo funciona', 'CORTAFUEGOS ▸ vence ▸ EXPLOIT ▸ vence ▸ PULSO ▸ vence ▸ CORTAFUEGOS. En color: cian aplasta rojo, rojo aplasta verde, verde aplasta cian.'),
              ('Ejemplo', 'Tu EXPLOIT contra su PULSO: ganas (rojo aplasta verde).'),
            ]),
            _RuleCard('CICLOS', NH.amber, [
              ('Qué es', 'La fuerza numérica de una Rutina.'),
              ('Función', 'Desempatan cuando el triángulo no decide (un ESPEJO: mismo tipo en ambos lados).'),
              ('Cómo funciona', 'Si los dos tipos son iguales, gana quien tenga MÁS ciclos. Básicas = 5; avanzadas = 7/8/9 según el tipo.'),
              ('Ejemplo', 'Espejo CORTAFUEGOS 9 vs 5 → gana el de 9.'),
            ]),
            _RuleCard('RAM', NH.amber, [
              ('Qué es', 'Tu energía por ronda para pagar SUBRUTINAS.'),
              ('Función', 'Limita cuántas Subrutinas puedes añadir.'),
              ('Cómo funciona', 'Tu Núcleo fija la RAM (4–6). Cada Subrutina cuesta RAM; si no te alcanza, no puedes colocarla.'),
              ('FAQ', '¿Se acumula? No: vuelve a su máximo cada ronda.'),
            ]),
            _RuleCard('NÚCLEO', NH.nl, [
              ('Qué es', 'Tu identidad: integridad inicial, RAM base y una PASIVA.'),
              ('Función', 'Define tu vida y un truco propio.'),
              ('Cómo funciona', 'SENTINEL: anula el 1er daño de la partida · WRAITH: roba 1 Sub extra al ganar con EXPLOIT · ECHO: +1 RAM si tu activa es PULSO · NULL-KEY: +1 RAM al jugar un NULL-SHARD.'),
            ]),
            _RuleCard('RUTINAS · básica vs avanzada', NH.fw, [
              ('Qué es', 'La carta central de tu jugada (va en el puesto ACTIVO).'),
              ('Función', 'Determina tu TIPO y tus CICLOS.'),
              ('Cómo funciona', 'Cada tipo tiene una básica (5 ciclos) y una avanzada (más ciclos + efecto). Mismo color = mismo tipo en el triángulo.'),
              ('Ejemplo', 'CORTAFUEGOS (5) vs IRON-WALL (7: si gana, no recibe daño de Subrutinas) · EXPLOIT (5) vs ZERO-DAY (9) · PULSO (5) vs EMP-BURST (8).'),
            ]),
            _RuleCard('SUBRUTINAS', NH.nl, [
              ('Qué es', 'Efectos de apoyo en los dos espacios laterales del ACTIVO.'),
              ('Función', 'Tuercen las reglas: cambian ciclos, tipos o anulan efectos.'),
              ('Cómo funciona', 'Cuestan RAM. El ESPACIO donde las pones NO importa; el orden con que se aplican es FIJO (ver ORDEN DE RESOLUCIÓN).'),
            ]),
            _RuleCard('SUBRUTINAS · catálogo', NH.nl, [
              ('OVERCLOCK / THROTTLE', '1 RAM. OVERCLOCK: +4 a TUS ciclos. THROTTLE: −4 a los del rival. (No afectan a NULL-SHARD.)'),
              ('MIRROR', '2 RAM. Copia el TIPO de la Rutina del rival antes de resolver (ajusta tus ciclos a ese tipo). Si ambos la juegan, se anulan.'),
              ('DESPLAZAMIENTOS', '2 RAM. Mueven una Rutina por el ciclo de colores (mantienen su nivel): AVANCE ▸ (tu Rutina adelante) · RECALIBRAR ◂ (tu Rutina atrás) · INTRUSIÓN ▸ (la del rival adelante) · SABOTAJE ◂ (la del rival atrás).'),
              ('CUARENTENA', '2 RAM. Fuerza EMPATE: nadie pierde integridad esa ronda.'),
              ('SIGKILL', '3 RAM. Anula TODAS las Subrutinas del rival esa ronda.'),
              ('FORK-BOMB', '3 RAM. Si ganas la ronda, el rival pierde 1 integridad extra.'),
            ]),
            _RuleCard('ORDEN DE RESOLUCIÓN', NH.xp, [
              ('Qué es', 'La secuencia FIJA con que el motor aplica todos los efectos.'),
              ('Función', 'Hace el resultado predecible: el mismo, lo veas desde donde lo veas.'),
              ('Cómo funciona', 'SIGKILL → MIRROR → DESPLAZAMIENTOS → OVERCLOCK/THROTTLE → CUARENTENA → triángulo y ciclos.'),
              ('FAQ', '¿Importa el espacio donde puse la Subrutina? NO. ¿Si ambos jugamos lo mismo? Se aplican las dos (salvo MIRROR, que se anula). Ej.: MIRROR + RECALIBRAR → primero copias el tipo del rival, DESPUÉS retrocedes.'),
            ]),
            _RuleCard('NULL-SHARD', NH.nl, [
              ('Qué es', 'Rutina comodín (6 ciclos).'),
              ('Función', 'Te deja elegir el tipo al programar.'),
              ('Cómo funciona', 'Declaras CORTAFUEGOS / EXPLOIT / PULSO al colocarla y juega como ese tipo. Es inmune a OVERCLOCK y THROTTLE.'),
            ]),
          ],
        ),
      ),
    ]);
  }

  // Tira superior con el triángulo de colores (recordatorio visual rápido).
  Widget _triangleStrip() {
    Widget chip(CType t) => Row(mainAxisSize: MainAxisSize.min, children: [
          Sigil(type: t, size: 14),
          const SizedBox(width: 4),
          Text(t.label, style: NH.mono(size: 9, weight: FontWeight.w700, color: Color(t.color))),
        ]);
    Widget arrow() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('▸', style: NH.mono(size: 11, color: NH.dim)),
        );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: NH.line))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        chip(CType.firewall),
        arrow(),
        chip(CType.exploit),
        arrow(),
        chip(CType.signal),
        Padding(padding: const EdgeInsets.only(left: 6), child: Text('↻', style: NH.mono(size: 11, color: NH.dim))),
      ]),
    );
  }
}

class _RuleCard extends StatefulWidget {
  final String title;
  final Color accent;
  final List<(String, String)> rows;
  const _RuleCard(this.title, this.accent, this.rows);

  @override
  State<_RuleCard> createState() => _RuleCardState();
}

class _RuleCardState extends State<_RuleCard> {
  bool _open = false; // contraída por defecto

  void _toggle() {
    AudioService.instance.playSfx(Sfx.uiTap);
    setState(() => _open = !_open);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: NH.a(const Color(0xFF090C12), .72),
        border: Border.all(color: _open ? NH.a(accent, .55) : NH.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: NH.a(accent, _open ? .14 : .08),
              border: Border(left: BorderSide(color: accent, width: 3)),
            ),
            child: Row(children: [
              Expanded(
                child: Text(widget.title, style: NH.mono(size: 12, weight: FontWeight.w700, color: const Color(0xFFEAF1FB), spacing: 1.5)),
              ),
              Text(_open ? '▾' : '▸', style: NH.mono(size: 13, weight: FontWeight.w700, color: accent)),
            ]),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < widget.rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: 7),
                  _row(widget.rows[i].$1, widget.rows[i].$2),
                ],
              ],
            ),
          ),
      ]),
    );
  }

  Widget _row(String label, String text) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: NH.mono(size: 8, weight: FontWeight.w700, color: NH.a(widget.accent, .95), spacing: 1.4)),
          const SizedBox(height: 2),
          Text(text, style: NH.mono(size: 10.5, color: NH.ink2, height: 1.45)),
        ],
      );
}
