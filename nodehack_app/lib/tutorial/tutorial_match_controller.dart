/// Controlador GUIONIZADO de tutorial: implementa `MatchView` con estado fijo
/// (mano, RAM, Subrutinas y jugadas del rival prescritas) y conduce las MISMAS
/// fases que una partida real, usando el `resolve()` auténtico del motor. Un guion
/// de pasos (`script`) describe la voz del personaje anónimo y la acción esperada;
/// las acciones que no corresponden al paso actual se IGNORAN (gating), así la mesa
/// obliga a jugar correctamente. Dos variantes: `.new` (básico) y `.advanced`.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:nodehack_engine/card_instance.dart';
import 'package:nodehack_engine/cards.dart';
import 'package:nodehack_engine/resolve.dart';
import 'package:nodehack_engine/types.dart';

import '../state/match_view.dart';

/// Acción que un paso espera del jugador (o `info`/`done` para avanzar con botón).
enum TutGate { info, place, placeSub, compile, nextRound, done }

/// Zona de la mesa a señalar/iluminar con el "señalador" pulsante del overlay.
enum Spot { none, slots, ram, legend, oppCard, cta, hand, center, integrity }

class TutStep {
  final String text; // voz del personaje anónimo
  final TutGate gate;
  final String? cardDefId; // para place/placeSub: id de la carta exigida
  final Spot spot;
  const TutStep(this.text, this.gate, {this.cardDefId, this.spot = Spot.none});
}

/// Configuración de una ronda guionizada (se construyen instancias frescas al entrar).
class TutRoundSpec {
  final List<String> handRut; // ids de Rutina en la mano
  final List<String> handSub; // ids de Subrutina en la mano
  final String oppRut; // Rutina del rival
  final List<String> oppSub; // Subrutinas del rival
  const TutRoundSpec({required this.handRut, this.handSub = const [], required this.oppRut, this.oppSub = const []});
}

// ───────────────────────── GUION BÁSICO (el triángulo) ─────────────────────────
const List<TutRoundSpec> _basicRounds = [
  TutRoundSpec(handRut: ['fw_base', 'xp_base', 'pl_base'], oppRut: 'xp_base'),
  TutRoundSpec(handRut: ['pl_base', 'fw_base', 'xp_base'], oppRut: 'fw_base'),
];

const List<TutStep> _basicScript = [
  TutStep('Bienvenido, proceso. Antes de soltarte ahí afuera, voy a enseñarte a sobrevivir un duelo.', TutGate.info),
  TutStep('Todo se decide por un triángulo de fuerza:  CORTAFUEGOS ▸ vence ▸ EXPLOIT ▸ vence ▸ PULSO ▸ vence ▸ CORTAFUEGOS.', TutGate.info, spot: Spot.legend),
  TutStep('El COLOR te lo dice de un vistazo:  CIAN = CORTAFUEGOS,  ROJO = EXPLOIT,  VERDE = PULSO. Cian aplasta rojo, rojo aplasta verde, verde aplasta cian.', TutGate.info, spot: Spot.legend),
  TutStep('¿Dudas de una carta? Mantén pulsada cualquiera para abrir su detalle: ahí dice exactamente a quién vence.', TutGate.info, spot: Spot.hand),
  TutStep('Este rival va a ejecutar un EXPLOIT —fíjate en el ROJO—. ¿Qué lo aplasta? El CORTAFUEGOS cian.', TutGate.info),
  TutStep('Arrastra tu CORTAFUEGOS —la carta cian— al puesto ACTIVO, en el centro.', TutGate.place, cardDefId: 'fw_base', spot: Spot.slots),
  TutStep('Sellada. Ahora pulsa COMPILAR para ejecutar tu jugada.', TutGate.compile, spot: Spot.cta),
  TutStep('¿Lo viste? Tu CORTAFUEGOS venció al EXPLOIT y el rival perdió integridad. Así se gana una ronda.', TutGate.info, spot: Spot.center),
  TutStep('Esos segmentos son tu INTEGRIDAD: tu vida. Empiezas con 4; cada ronda perdida te quita uno. El primero en quedar a 0 pierde el duelo.', TutGate.info, spot: Spot.integrity),
  TutStep('Continúa: pulsa SIGUIENTE RONDA.', TutGate.nextRound, spot: Spot.cta),
  TutStep('Ronda nueva, procesos nuevos en tu mano. Ahora el rival ejecuta un CORTAFUEGOS.', TutGate.info),
  TutStep('¿Qué vence a CORTAFUEGOS? El PULSO lo atraviesa.', TutGate.info),
  TutStep('Arrastra tu PULSO —la carta verde— al puesto ACTIVO.', TutGate.place, cardDefId: 'pl_base', spot: Spot.slots),
  TutStep('COMPILA de nuevo y observa.', TutGate.compile, spot: Spot.cta),
  TutStep('Otra victoria limpia. Ese triángulo es el corazón de cada duelo.', TutGate.info, spot: Spot.center),
  TutStep('Eso es lo básico. Las SUBRUTINAS —efectos que tuercen las reglas— las verás en el entrenamiento AVANZADO. Suerte ahí afuera, proceso.', TutGate.done),
];

// ──────────────────── GUION AVANZADO (ciclos, RAM, subrutinas) ──────────────────
// Mismo aprieto en las 3 rondas (tu EXPLOIT contra su CORTAFUEGOS, que te vence)
// resuelto con tres herramientas distintas, para fijar las ideas.
const List<TutRoundSpec> _advRounds = [
  TutRoundSpec(handRut: ['xp_base'], handSub: ['mirror', 'overclock'], oppRut: 'fw_base'),
  TutRoundSpec(handRut: ['xp_base'], handSub: ['shift_you_fwd'], oppRut: 'fw_base'),
  TutRoundSpec(handRut: ['xp_base'], handSub: ['mirror', 'shift_back'], oppRut: 'fw_base'),
];

const List<TutStep> _advScript = [
  // — Conceptos —
  TutStep('Volviste. Esto es el entrenamiento AVANZADO. Aquí no basta el triángulo: se gana con CICLOS, RAM y SUBRUTINAS.', TutGate.info),
  TutStep('El triángulo y los colores ya los dominas: cian ▸ rojo ▸ verde ▸ cian. Eso no cambia.', TutGate.info, spot: Spot.legend),
  TutStep('Hoy tu mano trae un solo EXPLOIT (rojo). Colócalo en el ACTIVO.', TutGate.place, cardDefId: 'xp_base', spot: Spot.slots),
  TutStep('Ese número en la carta son sus CICLOS: 5, su fuerza. Cuando dos Rutinas son del MISMO tipo (un ESPEJO), el triángulo no decide: gana quien tenga MÁS ciclos.', TutGate.info, spot: Spot.slots),
  TutStep('Esto es la RAM: tu energía para SUBRUTINAS. Tu núcleo SENTINEL te da 5 por ronda; si no te alcanza, no puedes colocar la Subrutina.', TutGate.info, spot: Spot.ram),
  TutStep('Las SUBRUTINAS van en estos dos espacios laterales. Son efectos que tuercen las reglas (cambian ciclos, tipos, o anulan cosas) y cada una cuesta RAM.', TutGate.info, spot: Spot.slots),
  TutStep('Problema: el rival juega CORTAFUEGOS (cian), que VENCE a tu EXPLOIT. Así, perderías la ronda.', TutGate.info, spot: Spot.oppCard),
  TutStep('Herramienta 1 — MIRROR: copia el TIPO de la Rutina del rival antes de resolver. Cuesta 2 de RAM. Colócala en un espacio lateral.', TutGate.placeSub, cardDefId: 'mirror', spot: Spot.slots),
  TutStep('Ahora eres CORTAFUEGOS igual que él: un ESPEJO. 5 contra 5 sería EMPATE. Te faltan ciclos.', TutGate.info, spot: Spot.slots),
  TutStep('Herramienta 2 — OVERCLOCK: +4 a TUS ciclos. Cuesta 1 de RAM. Colócala.', TutGate.placeSub, cardDefId: 'overclock', spot: Spot.slots),
  TutStep('Listo: 9 contra 5. Pulsa COMPILAR y observa los ciclos.', TutGate.compile, spot: Spot.cta),
  TutStep('Espejo CORTAFUEGOS → deciden los ciclos: 9 vence a 5. Ganaste una ronda que ibas a perder.', TutGate.info, spot: Spot.center),
  TutStep('Eso fue MIRROR + OVERCLOCK. Su pareja, THROTTLE, hace lo contrario: −4 a los ciclos del rival.', TutGate.info),
  TutStep('Siguiente lección, otra herramienta. Pulsa SIGUIENTE RONDA.', TutGate.nextRound, spot: Spot.cta),
  // — Desplazamientos —
  TutStep('Mismo aprieto: tu EXPLOIT contra su CORTAFUEGOS. Colócalo en el ACTIVO.', TutGate.place, cardDefId: 'xp_base', spot: Spot.slots),
  TutStep('Las cartas de DESPLAZAMIENTO mueven una Rutina por el ciclo de colores (sin cambiar su nivel).', TutGate.info, spot: Spot.legend),
  TutStep('AVANCE ▸ mueve TU Rutina al SIGUIENTE color: EXPLOIT ▸ PULSO. Y PULSO vence a CORTAFUEGOS. Colócala.', TutGate.placeSub, cardDefId: 'shift_you_fwd', spot: Spot.slots),
  TutStep('Ahora eres PULSO contra su CORTAFUEGOS. COMPILA.', TutGate.compile, spot: Spot.cta),
  TutStep('PULSO vence a CORTAFUEGOS: el desplazamiento le dio la vuelta al duelo, sin tocar los ciclos.', TutGate.info, spot: Spot.center),
  TutStep('Hay cuatro:  AVANCE ▸ (tu Rutina, adelante) · RECALIBRAR ◂ (tu Rutina, atrás) · INTRUSIÓN ▸ (la del rival, adelante) · SABOTAJE ◂ (la del rival, atrás).', TutGate.info, spot: Spot.legend),
  TutStep('Última lección, la más importante. Pulsa SIGUIENTE RONDA.', TutGate.nextRound, spot: Spot.cta),
  // — Orden de resolución —
  TutStep('La pregunta del millón: si juegas DOS subrutinas, ¿cuál actúa primero? ¿La tuya? ¿La del rival? ¿Importa el espacio donde la pongo?', TutGate.info),
  TutStep('Regla de oro: el orden es FIJO y NO depende del espacio. Siempre:  SIGKILL → MIRROR → DESPLAZAMIENTOS → OVERCLOCK/THROTTLE → CUARENTENA → y al final, triángulo y ciclos.', TutGate.info),
  TutStep('Veámoslo. El rival vuelve a jugar CORTAFUEGOS. Coloca tu EXPLOIT en el ACTIVO.', TutGate.place, cardDefId: 'xp_base', spot: Spot.slots),
  TutStep('Jugaremos MIRROR + RECALIBRAR juntas. Coloca primero MIRROR (da igual en qué espacio).', TutGate.placeSub, cardDefId: 'mirror', spot: Spot.slots),
  TutStep('Y ahora RECALIBRAR ◂ (retrocede TU Rutina). Ponla en el otro espacio.', TutGate.placeSub, cardDefId: 'shift_back', spot: Spot.slots),
  TutStep('Fíjate en el ORDEN del registro al compilar. COMPILA.', TutGate.compile, spot: Spot.cta),
  TutStep('Primero MIRROR: copiaste CORTAFUEGOS (espejo). DESPUÉS RECALIBRAR: retrocediste a PULSO. Y PULSO vence a CORTAFUEGOS. ¡Ganas!', TutGate.info, spot: Spot.center),
  TutStep('Si el orden fuera al revés acabarías en otro tipo. Por eso el orden FIJO importa — el espacio donde pusiste cada carta, NO.', TutGate.info),
  TutStep('Entre tu Subrutina y la del rival de la MISMA categoría, se aplican las dos. Única excepción: si ambos jugáis MIRROR, se anulan.', TutGate.info),
  TutStep('Tres que no practicamos hoy, pero debes conocer:  SIGKILL anula TODAS las Subrutinas del rival · CUARENTENA fuerza EMPATE (nadie pierde integridad) · FORK-BOMB: si ganas, el rival pierde 1 integridad extra.', TutGate.info),
  TutStep('Y sobre Rutinas: el CORTAFUEGOS básico tiene 5 ciclos; el IRON-WALL (también cian) es su versión avanzada: 7 ciclos y, si gana, no recibe daño de Subrutinas. Mismo tipo, más fuerza.', TutGate.info),
  TutStep('Eso es el juego avanzado completo. Si olvidas un término, en el menú tienes REGLAS: todo resumido. Ahora tuerce el sistema a tu favor, proceso.', TutGate.done),
];

class TutorialMatchController extends ChangeNotifier implements MatchView {
  final VoidCallback onComplete;
  final List<TutStep> script;
  final List<TutRoundSpec> rounds;
  final bool lockPlacements; // avanzado: una vez colocadas, no se devuelven

  TutorialMatchController({required this.onComplete})
      : script = _basicScript,
        rounds = _basicRounds,
        lockPlacements = false {
    _setupRound(1);
  }

  TutorialMatchController.advanced({required this.onComplete})
      : script = _advScript,
        rounds = _advRounds,
        lockPlacements = true {
    _setupRound(1);
  }

  final List<Timer> _timers = [];
  bool _finished = false;
  int _step = 0;

  final NucleoDef _nucYou = kNucById['sentinel']!;
  final NucleoDef _nucOpp = kNucById['wraith']!;
  int _round = 1;
  int _intYou = 4;
  int _intOpp = 4;
  List<CardInstance> _hand = [];
  CardInstance? _active;
  final List<CardInstance?> _subsList = [null, null];
  late CardInstance _oppInst;
  List<CardInstance> _oppSubsInst = const [];
  Play? _oppPlay;
  RoundResult? _result;

  @override
  int phaseIdx = 1; // PROGRAMACIÓN
  @override
  bool revealed = false;
  @override
  ({String side, int amount})? hit;
  @override
  final List<Winner> history = [];
  @override
  bool showAcquire = false;

  TutStep get step => script[_step];
  Spot get spot => step.spot;
  bool get showNextButton => step.gate == TutGate.info || step.gate == TutGate.done;
  bool get isDone => step.gate == TutGate.done;

  void _setupRound(int n) {
    final spec = rounds[n - 1];
    _active = null;
    _subsList[0] = null;
    _subsList[1] = null;
    _hand = [
      for (final id in spec.handRut) CardInstance.rutina(kRutById[id]!),
      for (final id in spec.handSub) CardInstance.subrutina(kSubById[id]!),
    ];
    _oppInst = CardInstance.rutina(kRutById[spec.oppRut]!);
    _oppSubsInst = [for (final id in spec.oppSub) CardInstance.subrutina(kSubById[id]!)];
  }

  /// Avanza un paso de tipo `info`; en `done` finaliza el tutorial.
  void next() {
    if (step.gate == TutGate.done) {
      _finish();
      return;
    }
    if (step.gate == TutGate.info && _step < script.length - 1) {
      _step++;
      notifyListeners();
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    onComplete();
  }

  // ---- MatchView (lectura) ----
  @override
  MatchPhase get phase => kPhases[phaseIdx];
  @override
  int get round => _round;
  @override
  List<CardInstance> get handYou => _hand;
  @override
  List<CardInstance?> get subs => _subsList;
  @override
  CardInstance? get active => _active;
  @override
  Play? get oppPlay => _oppPlay;
  @override
  RoundResult? get result => _result;
  @override
  NucleoDef get nucYou => _nucYou;
  @override
  NucleoDef get nucOpp => _nucOpp;
  @override
  int get integrityYou => _intYou;
  @override
  int get integrityOpp => _intOpp;
  @override
  int get ramMax => _nucYou.ram;
  @override
  int get ramLeft => _nucYou.ram - _subsList.whereType<CardInstance>().fold(0, (a, s) => a + s.ram);
  @override
  bool subCabe(CardInstance s) => s.ram <= ramLeft;
  @override
  int get rutPileYou => 8;
  @override
  int get subPileYou => 15;
  @override
  int get acquiredN => 0;
  @override
  int get acquiredRut => 0;
  @override
  int get acquiredSub => 0;
  @override
  bool get needsNullDeclaration => false;
  @override
  bool get canCompile => _active != null && phase.id == 'programacion' && step.gate == TutGate.compile;
  @override
  bool get gameOver => false;
  @override
  String? get outcome => null;
  @override
  String get oppName => 'proc_0x4F';

  // ---- MatchView (acciones, con gating) ----
  @override
  void placeActive(CardInstance c) {
    if (phase.id != 'programacion') return;
    if (step.gate == TutGate.place && c.defId == step.cardDefId) {
      _active = c;
      _hand.remove(c);
      _step++;
      notifyListeners();
    }
  }

  @override
  void placeSub(CardInstance c, int idx) {
    if (phase.id != 'programacion') return;
    if (step.gate == TutGate.placeSub && c.defId == step.cardDefId && _subsList[idx] == null && subCabe(c)) {
      _subsList[idx] = c;
      _hand.remove(c);
      _step++;
      notifyListeners();
    }
  }

  @override
  void returnActive() {
    if (lockPlacements || phase.id != 'programacion' || _active == null) return;
    _hand.add(_active!);
    _active = null;
    if (step.gate == TutGate.compile && _step > 0) _step--;
    notifyListeners();
  }

  @override
  void returnSub(int idx) {/* bloqueado en el tutorial para mantener el guion */}
  @override
  void declareNull(CType t) {}

  @override
  void compile() {
    if (step.gate != TutGate.compile || _active == null) return;
    _oppPlay = Play(_oppInst, _oppSubsInst);
    _result = resolve(Play(_active!, _subsList.whereType<CardInstance>().toList()), _oppPlay!);
    phaseIdx = 2; // COMPILAR
    notifyListeners();

    final items = 1 + _subsList.whereType<CardInstance>().length + 1 + _oppPlay!.subs.length;
    const execStart = 1900;
    final resultAt = execStart + (items + 1) * kExecStepMs + 300;
    _after(700, () {
      phaseIdx = 3; // REVELACIÓN
      notifyListeners();
    });
    _after(1050, () {
      revealed = true;
      notifyListeners();
    });
    _after(execStart, () {
      phaseIdx = 4; // EJECUCIÓN
      notifyListeners();
    });
    _after(resultAt, () {
      phaseIdx = 5; // RESULTADO
      final r = _result!;
      history.add(r.winner);
      if (r.winner == Winner.you) {
        _intOpp = (_intOpp - r.damage).clamp(0, 99);
        hit = (side: 'opp', amount: r.damage);
      } else if (r.winner == Winner.opp) {
        _intYou = (_intYou - r.damage).clamp(0, 99);
        hit = (side: 'you', amount: r.damage);
      }
      _step++; // pasa al paso de explicación
      notifyListeners();
      if (hit != null) {
        _after(1200, () {
          hit = null;
          notifyListeners();
        });
      }
    });
  }

  @override
  void nextRound() {
    if (step.gate != TutGate.nextRound) return;
    _round++;
    _setupRound(_round);
    phaseIdx = 1;
    revealed = false;
    hit = null;
    _result = null;
    _oppPlay = null;
    _step++;
    notifyListeners();
  }

  void _after(int ms, VoidCallback fn) => _timers.add(Timer(Duration(milliseconds: ms), fn));

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }
}
