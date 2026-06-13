import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:nodehack_engine/card_instance.dart';
import 'package:nodehack_engine/resolve.dart';
import 'package:nodehack_engine/types.dart';
import '../audio/audio_service.dart';
import '../state/match_view.dart';
import '../theme/tokens.dart';
import '../widgets/anims.dart';
import '../widgets/card_view.dart';
import '../widgets/sigil.dart';

class _Drag {
  final CardInstance card;
  Offset pos;
  final Offset start;
  _Drag(this.card, this.pos) : start = pos;
}

class MatchScreen extends StatefulWidget {
  final MatchView ctrl;
  final VoidCallback onExit;
  final void Function(CardInstance) onInspect;
  /// Claves de "spots" para el tutorial (señalar RAM/CICLOS/espacios…). null = partida normal.
  final Map<String, GlobalKey>? spotKeys;
  const MatchScreen({super.key, required this.ctrl, required this.onExit, required this.onInspect, this.spotKeys});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final _rootKey = GlobalKey();
  final _slotKeys = {'sub0': GlobalKey(), 'active': GlobalKey(), 'sub1': GlobalKey()};
  final Set<String> _seenHand = {}; // para animar solo las cartas nuevas (handDraw)
  List<CardInstance> _lastHand = const []; // mano anterior (detecta robos/rebarajeos)
  Set<String> _lastSlotUids = {}; // cartas que estaban en slots (no re-animan al volver)
  List<CardInstance> _handGhosts = const []; // cartas desmaterializándose (rebarajeo)
  int _ghostSeq = 0;
  Timer? _ghostTimer;
  _Drag? _drag;
  bool _dragActive = false; // el arrastre empieza tras mover el dedo (slop)
  String? _hover;
  String? _dropRipple; // slot donde acaba de caer una carta (onda)
  int _dropRippleSeq = 0; // re-dispara la onda al re-soltar en el mismo slot
  Color _dropRippleColor = NH.pl;
  bool _confirmExit = false; // overlay "¿RENDIRSE?"
  bool _warnedLow = false; // aviso de "1 de vida" ya sonó esta partida

  // ---- Secuenciador de EJECUCIÓN (un solo reloj: enfoca carta → muestra su log) ----
  String _prevPhase = '';
  Timer? _execTimer;
  int _execStep = -1; // índice de la carta enfocada (-1 = ninguna)
  List<String> _execIds = const []; // orden: tú (activo, subs) → rival (activo, subs)
  List<List<String>> _stepLines = const []; // líneas del log por paso

  MatchView get c => widget.ctrl;
  RenderBox? get _rootBox => _rootKey.currentContext?.findRenderObject() as RenderBox?;

  // Envuelve una zona con su clave de "spot" (solo en tutorial) para que el overlay
  // pueda localizarla y señalarla. En partida normal devuelve el hijo sin tocar.
  Widget _spot(String name, Widget child) {
    final k = widget.spotKeys?[name];
    return k == null ? child : KeyedSubtree(key: k, child: child);
  }

  @override
  void initState() {
    super.initState();
    _updateCombatMusic(); // combate normal o "peligro" según integridad
    _prevPhase = c.phase.id;
    _lastHand = List.of(c.handYou);
    c.addListener(_onCtrl);
  }

  // Combate normal vs "peligro" (1-2 de integridad). Idempotente: si te curas y
  // subes de 2, vuelve a la normal; si bajas otra vez, vuelve a peligro.
  void _updateCombatMusic() {
    if (c.gameOver) return; // el flush pondrá victoria/derrota
    AudioService.instance.playMusic(c.integrityYou <= 2 ? Music.combatDanger : Music.combat);
  }

  // Aviso 1 SOLA vez por partida cuando caes a 1 de integridad (sigues vivo).
  void _maybeLowWarning() {
    if (_warnedLow || c.gameOver) return;
    if (c.integrityYou == 1) {
      _warnedLow = true;
      AudioService.instance.playSfx(Sfx.lowWarning);
    }
  }

  @override
  void dispose() {
    c.removeListener(_onCtrl);
    _execTimer?.cancel();
    _ghostTimer?.cancel();
    AudioService.instance.playMusic(Music.menu); // al salir, vuelve la del menú
    super.dispose();
  }

  // Diferencia la mano contra la anterior: detecta robos reales (materializan)
  // y cartas que se fueron SIN pasar por un slot = rebarajeo (desmaterializan).
  void _diffHand() {
    final hand = c.handYou;
    final slotUids = {
      if (c.active != null) c.active!.uid,
      if (c.subs[0] != null) c.subs[0]!.uid,
      if (c.subs[1] != null) c.subs[1]!.uid,
    };
    final lastUids = {for (final h in _lastHand) h.uid};
    final curUids = {for (final h in hand) h.uid};
    // Robos reales (no vuelven de un slot): re-animan aunque sean recicladas.
    for (final h in hand) {
      if (!lastUids.contains(h.uid) && !_lastSlotUids.contains(h.uid)) _seenHand.remove(h.uid);
    }
    final reshuffled = [
      for (final h in _lastHand)
        if (!curUids.contains(h.uid) && !slotUids.contains(h.uid)) h
    ];
    _lastHand = List.of(hand);
    _lastSlotUids = slotUids;
    if (reshuffled.isEmpty) return;
    for (final h in reshuffled) {
      _seenHand.remove(h.uid);
    }
    _ghostSeq++;
    _handGhosts = reshuffled;
    _ghostTimer?.cancel();
    _ghostTimer = Timer(const Duration(milliseconds: 720), () {
      if (mounted) setState(() => _handGhosts = const []);
    });
  }

  // Detecta el paso a EJECUCIÓN para arrancar el secuenciador (y lo apaga al salir).
  void _onCtrl() {
    _diffHand();
    final p = c.phase.id;
    if (p == _prevPhase) return;
    _prevPhase = p;
    _updateCombatMusic();
    _maybeLowWarning();
    if (p == 'resultado') {
      // Rayo + impacto (quién recibe el daño) y estática si el enemigo se desconecta.
      final hit = c.hit;
      if (hit != null) {
        AudioService.instance.playSfx(hit.side == 'you' ? Sfx.damageTaken : Sfx.damageDealt);
      }
      if (c.gameOver && c.outcome == 'win') {
        AudioService.instance.playSfx(Sfx.enemyLose);
      }
    }
    if (p == 'ejecucion') {
      _startExecSequence();
    } else {
      _execTimer?.cancel();
      if (_execStep != -1 && mounted) setState(() => _execStep = -1);
    }
  }

  // Construye el orden de cartas + sus líneas de log, y avanza el foco a kExecStepMs.
  void _startExecSequence() {
    final r = c.result;
    final ids = <String>[];
    if (c.active != null) ids.add('you-active');
    for (var i = 0; i < 2; i++) {
      if (c.subs[i] != null) ids.add('you-sub$i');
    }
    final opp = c.oppPlay;
    if (opp != null) {
      ids.add('opp-active');
      for (var i = 0; i < opp.subs.length && i < 2; i++) {
        ids.add('opp-sub$i');
      }
    }
    _execIds = ids;
    _stepLines = _buildStepLines(r, ids);

    _execTimer?.cancel();
    setState(() => _execStep = 0);
    _focusTick();
    final maxStep = ids.length; // último paso = líneas de resultado/sistema
    _execTimer = Timer.periodic(Duration(milliseconds: kExecStepMs), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_execStep >= maxStep) {
        t.cancel();
        return;
      }
      setState(() => _execStep++);
      _focusTick();
    });
  }

  // SFX al recibir el foco en EJECUCIÓN: las RUTINAS suenan ÚNICO por tipo (cian/
  // rojo/verde/null → identidad sonora); las Subrutinas, un tick sutil compartido.
  void _focusTick() {
    final id = _focusedExecId;
    if (id == null) return; // paso final (resultado/sistema)
    if (id == 'you-active') {
      AudioService.instance.playSfx(_typeSfx(c.active?.type), volume: .8);
    } else if (id == 'opp-active') {
      AudioService.instance.playSfx(_typeSfx(c.oppPlay?.rutina.type), volume: .8);
    } else {
      AudioService.instance.playSfx(Sfx.execFocus, volume: .55);
    }
  }

  Sfx _typeSfx(CType? t) => switch (t) {
        CType.firewall => Sfx.revealFirewall,
        CType.exploit => Sfx.revealExploit,
        CType.signal => Sfx.revealSignal,
        _ => Sfx.revealNull,
      };

  // Reparte las líneas del log en pasos: una "ranura" por carta (en el orden de
  // [ids]) + una final con las líneas de resultado/sistema. Mapea por las marcas
  // (tú)/(rival)+efecto que ya trae cada línea.
  List<List<String>> _buildStepLines(RoundResult? r, List<String> ids) {
    final steps = List<List<String>>.generate(ids.length + 1, (_) => <String>[]);
    if (r == null) return steps;
    final lines = r.log;
    final used = List<bool>.filled(lines.length, false);

    ({String owner, String? subId}) targetOf(String id) {
      if (id == 'you-active') return (owner: 'you', subId: null);
      if (id == 'opp-active') return (owner: 'opp', subId: null);
      final youSub = id.startsWith('you-sub');
      final slot = int.parse(id.substring(id.length - 1));
      final card = youSub ? c.subs[slot] : c.oppPlay?.subs[slot];
      return (owner: youSub ? 'you' : 'opp', subId: card?.sub?.id);
    }

    for (var s = 0; s < ids.length; s++) {
      final tgt = targetOf(ids[s]);
      for (var i = 0; i < lines.length; i++) {
        if (used[i]) continue;
        final tag = _tagOf(lines[i]);
        if (tag.owner == tgt.owner && tag.subId == tgt.subId) {
          steps[s].add(lines[i]);
          used[i] = true;
        }
      }
    }
    // Líneas restantes (resultado del enfrentamiento, espejos anulados…) al final.
    for (var i = 0; i < lines.length; i++) {
      if (!used[i]) steps[ids.length].add(lines[i]);
    }
    return steps;
  }

  // Id de la carta enfocada ahora mismo (o null).
  String? get _focusedExecId =>
      (_execStep >= 0 && _execStep < _execIds.length) ? _execIds[_execStep] : null;

  List<String> _validTargets(CardInstance card) {
    if (!card.isSub) return ['active'];
    final out = <String>[];
    for (var i = 0; i < 2; i++) {
      if (c.subs[i] == null && c.subCabe(card)) out.add('sub$i');
    }
    return out;
  }

  String? _hitTest(Offset local, CardInstance card) {
    final root = _rootBox;
    if (root == null) return null;
    for (final id in _validTargets(card)) {
      final box = _slotKeys[id]!.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final tl = box.localToGlobal(Offset.zero, ancestor: root);
      final r = Rect.fromLTWH(tl.dx, tl.dy, box.size.width, box.size.height).inflate(26);
      if (r.contains(local)) return id;
    }
    return null;
  }

  void _onCardDown(PointerDownEvent e, CardInstance card) {
    if (c.phase.id != 'programacion') return;
    _drag = _Drag(card, _rootBox!.globalToLocal(e.position));
    _dragActive = false; // se activa al mover el dedo (>8px)
  }

  void _onMove(PointerMoveEvent e) {
    final d = _drag;
    if (d == null) return;
    final local = _rootBox!.globalToLocal(e.position);
    if (!_dragActive) {
      if ((local - d.start).distance <= 8) return;
      _dragActive = true; // empieza el arrastre real
      AudioService.instance.playSfx(Sfx.cardPick); // carta levantada
    }
    setState(() {
      d.pos = local;
      _hover = _hitTest(local, d.card);
    });
  }

  void _onUp(PointerUpEvent e) {
    final d = _drag;
    if (d == null) return;
    final local = _rootBox!.globalToLocal(e.position);
    if (_dragActive) {
      final target = _hitTest(local, d.card);
      if (target == 'active') {
        c.placeActive(d.card);
      } else if (target == 'sub0') {
        c.placeSub(d.card, 0);
      } else if (target == 'sub1') {
        c.placeSub(d.card, 1);
      }
      if (target != null) {
        AudioService.instance.playSfx(Sfx.cardPlace);
        _dropRipple = target;
        // Las subrutinas reportan CType.nul: usamos su gris (como en el zoom).
        _dropRippleColor = d.card.isSub ? const Color(0xFF7D8AA0) : Color(d.card.type.color);
        _dropRippleSeq++;
      }
    } else {
      widget.onInspect(d.card); // toque (sin arrastrar) = ver carta en zoom
    }
    setState(() {
      _drag = null;
      _dragActive = false;
      _hover = null;
    });
  }

  void _requestExit() => setState(() => _confirmExit = true);

  void _compile() {
    AudioService.instance.playSfx(Sfx.compile);
    c.compile();
  }

  // Banner de aviso sobre la mesa (rival desconectado / conexión perdida).
  Widget _noticeBanner(String msg) {
    return Positioned(
      top: 86,
      left: 20,
      right: 20,
      child: IgnorePointer(
        child: OneShot(
          key: ValueKey('notice$msg'),
          duration: const Duration(milliseconds: 280),
          builder: (_, t) => Opacity(
            opacity: t,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                color: NH.a(const Color(0xFF06080D), .94),
                border: Border.all(color: NH.amber),
                boxShadow: [BoxShadow(color: NH.a(NH.amber, .3), blurRadius: 16)],
              ),
              child: Text('⚠ $msg',
                  textAlign: TextAlign.center,
                  style: NH.mono(size: 9.5, weight: FontWeight.w700, color: NH.amber, height: 1.4, spacing: .5)),
            ),
          ),
        ),
      ),
    );
  }

  // Viñeta global de "hubo daño en la mesa": bordes del color del lado golpeado.
  Widget _hitVignette() {
    final col = c.hit?.side == 'you' ? NH.xp : NH.pl;
    return Positioned.fill(
      child: IgnorePointer(
        child: OneShot(
          key: ValueKey('vig${c.round}'),
          duration: const Duration(milliseconds: 420),
          builder: (_, t) {
            final a = (t < .35 ? t / .35 : 1 - (t - .35) / .65).clamp(0.0, 1.0);
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.0,
                  colors: [Colors.transparent, NH.a(col, .22 * a)],
                  stops: const [.55, 1.0],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // El "atrás" del sistema NO sale directo: abre la confirmación de rendición.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _confirmExit = !_confirmExit);
      },
      child: AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          final e = c;
          return Listener(
            onPointerMove: _onMove,
            onPointerUp: _onUp,
            behavior: HitTestBehavior.translucent,
            child: Stack(
              key: _rootKey,
              children: [
                Positioned.fill(child: Container(color: NH.cardBg, child: CustomPaint(painter: _MatBgPainter()))),
                Column(children: [
                  _topbar(),
                  _battleTrack(),
                  // Al GANAR la partida, el rival se "desconecta" en el tablero.
                  (c.gameOver && c.outcome == 'win')
                      ? _DisconnectFx(oppName: c.oppName, child: _oppZone())
                      : HitEffects(active: c.hit?.side == 'opp', child: _oppZone()),
                  _spot('center', _center()),
                  const Spacer(),
                  HitEffects(active: c.hit?.side == 'you', child: _youZone()),
                ]),
                // Aviso transitorio (online: rival desconectado / conexión perdida).
                if (c.notice != null) _noticeBanner(c.notice!),
                // En RESULTADO con golpe: ilumina al ganador y le "descarga" al perdedor.
                if (c.phase.id == 'resultado' && c.hit != null) _hitVignette(),
                if (c.phase.id == 'resultado' && c.hit != null) _winnerGlow(),
                if (c.phase.id == 'resultado' && c.hit != null) _dischargeFx(),
                if (_drag != null && _dragActive)
                  Positioned(
                    left: _drag!.pos.dx - 45,
                    top: _drag!.pos.dy - 63,
                    child: IgnorePointer(
                      child: OneShot(
                        key: ValueKey('ghost${_drag!.card.uid}'),
                        duration: const Duration(milliseconds: 130),
                        builder: (_, t) => Transform.scale(
                          scale: 1.0 + 0.12 * t,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: NH.a(Colors.black, .5 * t), blurRadius: 22 * t, offset: Offset(0, 10 * t))],
                            ),
                            child: CardView(card: _drag!.card, width: 90, animate: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (c.phase.id == 'programacion' && e.needsNullDeclaration) _nullPicker(),
                if (_confirmExit) _confirmExitOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _topbar() => Padding(
        padding: const EdgeInsets.fromLTRB(14, NH.safe + 4, 14, 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          GestureDetector(onTap: _requestExit, child: Text('‹ RENDIRSE', style: NH.mono(size: 11, color: NH.ink2, spacing: 1))),
          Text('RONDA ${c.round.toString().padLeft(2, '0')}', style: NH.mono(size: 11, color: NH.ink2, spacing: 2)),
          Text('0x${(c.round * 4079).toRadixString(16).toUpperCase()}', style: NH.mono(size: 10, color: NH.dim2)),
        ]),
      );

  // Marcador de seguimiento (TÚ n · puntos · n RIVAL) — altura acotada.
  Widget _battleTrack() {
    final h = c.history;
    final you = h.where((w) => w == Winner.you).length;
    final opp = h.where((w) => w == Winner.opp).length;
    final last = h.length > 7 ? h.sublist(h.length - 7) : h;
    return SizedBox(
      height: 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Text('TÚ ', style: NH.mono(size: 9, color: NH.dim, spacing: 1.4)),
          Text('$you', style: NH.mono(size: 13, weight: FontWeight.w700, color: NH.pl)),
          Expanded(
            child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < last.length; i++)
                  Container(
                    key: ValueKey('bt$i${last[i]}'),
                    width: 9, height: 9, margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: last[i] == Winner.you ? NH.pl : (last[i] == Winner.opp ? NH.xp : NH.amber),
                      boxShadow: [BoxShadow(color: NH.a(last[i] == Winner.you ? NH.pl : (last[i] == Winner.opp ? NH.xp : NH.amber), .5), blurRadius: 6)],
                    ),
                  ),
                if (last.isEmpty) Text('— sin rondas —', style: NH.mono(size: 8, color: NH.dim2, spacing: 1)),
              ]),
            ),
          ),
          Text('$opp', style: NH.mono(size: 13, weight: FontWeight.w700, color: NH.xp)),
          Text(' RIVAL', style: NH.mono(size: 9, color: NH.dim, spacing: 1.4)),
        ]),
      ),
    );
  }

  Widget _oppZone() {
    final e = c;
    final opp = e.oppPlay;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      child: Stack(children: [
        Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('RIVAL · proc_0x4F', style: NH.mono(size: 9, color: const Color(0xFFFF6B86), spacing: 1)),
            _pips(e.integrityOpp, c.integrityMaxOpp, NH.xp, base: e.nucOpp.integrity, brokeForSide: 'opp'),
          ]),
          const SizedBox(height: 3),
          SizedBox(
            height: 36,
            child: Stack(alignment: Alignment.topCenter, children: [
              for (var i = 0; i < 4; i++)
                Transform.translate(
                  offset: Offset((i - 1.5) * 24, 0),
                  child: Transform.rotate(angle: (i - 1.5) * .14, child: CardBackView(width: 30, seed: i + e.round * 7)),
                ),
            ]),
          ),
          const SizedBox(height: 3),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _slot(width: 52, height: 73, child: _execWrapMaybe(_oppSub(opp, 0), 'opp-sub0', NH.xp)),
            const SizedBox(width: 10),
            _spot('oppCard', _morphOverlay(
              _slot(width: 72, height: 100, filled: opp != null, child: opp != null
                  ? (c.revealed ? _execWrap(_oppCard(opp.rutina, 72), 'opp-active', NH.xp) : const CardBackView(width: 72, seed: 42))
                  : null),
              c.result?.oppType, opp?.rutina.type)),
            const SizedBox(width: 10),
            _slot(width: 52, height: 73, child: _execWrapMaybe(_oppSub(opp, 1), 'opp-sub1', NH.xp)),
          ]),
        ]),
        if (c.hit?.side == 'opp') _floatingDmg(youLost: false),
      ]),
    );
  }

  // Pip de fase. El activo hace un pop (1→1.6→1) al cambiar de fase (re-key por phaseIdx).
  Widget _phaseDot(int i) {
    final active = i == c.phaseIdx;
    final dot = Container(
      width: 18, height: 3, margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: active ? NH.fw : (i < c.phaseIdx ? const Color(0xFF2C4A5C) : const Color(0xFF1B2230)),
        boxShadow: active ? [BoxShadow(color: NH.fw, blurRadius: 8)] : null,
      ),
    );
    if (!active) return dot;
    return OneShot(
      key: ValueKey('phasedot${c.phaseIdx}'),
      duration: const Duration(milliseconds: 220),
      builder: (_, t) => Transform.scale(scale: 1 + sin(t.clamp(0.0, 1.0) * pi) * 0.6, child: dot),
    );
  }

  Widget _center() {
    final r = c.result;
    final showResult = r != null && (c.phase.id == 'ejecucion' || c.phase.id == 'resultado');
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 0),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: NH.line), bottom: BorderSide(color: NH.line))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < kPhases.length; i++) _phaseDot(i),
        ]),
        const SizedBox(height: 4),
        Text(c.phase.label, style: NH.mono(size: 12, weight: FontWeight.w600, color: const Color(0xFFDBE3F0), spacing: 3.6)),
        if (!showResult) ...[
          const SizedBox(height: 3),
          Text(c.phase.hint, textAlign: TextAlign.center, style: NH.mono(size: 8.5, color: NH.dim)),
          const SizedBox(height: 6),
          _spot('legend', _cycleLegend()),
        ],
        if (showResult) _resultBanner(r),
        if (showResult) _explanation(r),
      ]),
    );
  }

  // Ciclo de fuerza: CORTAFUEGOS ▸ EXPLOIT ▸ PULSO ▸ (vuelve). El ▸ = "vence a" y
  // es la dirección de AVANCE (las subrutinas de retroceso van al revés).
  Widget _cycleLegend() {
    Widget chip(CType t) => Row(mainAxisSize: MainAxisSize.min, children: [
          Sigil(type: t, size: 13),
          const SizedBox(width: 3),
          Text(t.short, style: NH.mono(size: 9, weight: FontWeight.w700, color: Color(t.color))),
        ]);
    Widget arrow() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text('▸', style: NH.mono(size: 11, color: NH.dim)),
        );
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        chip(CType.firewall),
        arrow(),
        chip(CType.exploit),
        arrow(),
        chip(CType.signal),
        Padding(padding: const EdgeInsets.only(left: 5), child: Text('↻', style: NH.mono(size: 11, color: NH.dim))),
      ]),
      const SizedBox(height: 2),
      Text('▸ vence / AVANCE   ·   ◂ RETROCESO', style: NH.mono(size: 7, color: NH.dim2, spacing: 1)),
    ]);
  }

  // Si una Rutina cambió de tipo por shifts/mirror, muestra "origen ▸ tipo final"
  // sobre la carta activa durante ejecución/resultado.
  Widget _morphOverlay(Widget card, CType? finalType, CType? orig) {
    final phaseOk = c.phase.id == 'ejecucion' || c.phase.id == 'resultado';
    if (!phaseOk || finalType == null || orig == null || finalType == orig) return card;
    return Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
      card,
      // Velo del color nuevo sobre la carta: se nota A SIMPLE VISTA que mutó.
      Positioned.fill(
        child: IgnorePointer(
          child: OneShot(
            key: ValueKey('morphveil${c.round}$finalType'),
            duration: const Duration(milliseconds: 900),
            builder: (_, t) {
              final a = t < .3 ? t / .3 : 1 - (t - .3) / .7 * .55; // sube y se asienta
              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NH.a(Color(finalType.color), .9 * a), width: 1.6),
                  color: NH.a(Color(finalType.color), .14 * a),
                ),
              );
            },
          ),
        ),
      ),
      Positioned(bottom: -6, left: -30, right: -30, child: Center(child: _morphChip(orig, finalType))),
    ]);
  }

  // Chip grande y animado: sigil origen ▸ sigil NUEVO + nombre completo del tipo.
  Widget _morphChip(CType from, CType to) => OneShot(
        key: ValueKey('morph${c.round}$to'),
        duration: const Duration(milliseconds: 420),
        builder: (_, t) {
          final pop = Curves.easeOutBack.transform(t);
          return Transform.scale(
            scale: 0.5 + 0.5 * pop,
            child: Opacity(
              opacity: t.clamp(0.0, 1.0),
              // FittedBox: si el hueco es estrecho (cartas pequeñas), el chip se
              // encoge en vez de desbordar.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: NH.a(const Color(0xFF06080D), .96),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: Color(to.color), width: 1.3),
                    boxShadow: [BoxShadow(color: NH.a(Color(to.color), .6), blurRadius: 14)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Sigil(type: from, size: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Text('▸', style: NH.mono(size: 9, weight: FontWeight.w700, color: Color(to.color))),
                    ),
                    Sigil(type: to, size: 14),
                    const SizedBox(width: 3),
                    Text(to.label.toUpperCase(),
                        style: NH.mono(size: 9, weight: FontWeight.w700, color: Color(to.color), spacing: .6)),
                  ]),
                ),
              ),
            ),
          );
        },
      );

  // Deduce a quién (tú/rival) y a qué subrutina pertenece una línea del log, a
  // partir de sus marcas de texto (que genera resolve()). 'sys' = línea de
  // resultado/sistema (no atada a una carta concreta).
  ({String owner, String? subId}) _tagOf(String l) {
    final owner = l.contains('(rival)') ? 'opp' : (l.contains('(tú)') ? 'you' : 'sys');
    String? sub;
    if (l.contains('MIRROR ↔')) {
      sub = null; // espejos anulados → línea de sistema
    } else if (l.contains('OVERCLOCK')) {
      sub = 'overclock';
    } else if (l.contains('THROTTLE')) {
      sub = 'throttle';
    } else if (l.contains('MIRROR')) {
      sub = 'mirror';
    } else if (l.contains('INTRUSIÓN')) {
      sub = 'shift_fwd';
    } else if (l.contains('RECALIBRAR')) {
      sub = 'shift_back';
    } else if (l.contains('SABOTAJE')) {
      sub = 'shift_opp_back';
    } else if (l.contains('AVANCE')) {
      sub = 'shift_you_fwd';
    } else if (l.contains('CUARENTENA')) {
      sub = 'cuarentena';
    } else if (l.contains('SIGKILL')) {
      sub = 'sigkill';
    } else if (l.contains('FORK-BOMB')) {
      sub = 'forkbomb';
    }
    return (owner: owner, subId: sub);
  }

  // Log mostrado durante EJECUCIÓN/RESULTADO. En ejecución, acumula las líneas
  // de los pasos ya enfocados (_execStep) → cada carta "suelta" su línea cuando se
  // ilumina. En resultado, muestra todo. Cada línea nueva entra con un fade.
  Widget _execLogView(RoundResult r, TextStyle style) {
    final executing = c.phase.id == 'ejecucion';
    final visible = <String>[];
    if (!executing || _stepLines.isEmpty) {
      visible.addAll(r.log);
    } else {
      final upto = _execStep.clamp(0, _stepLines.length - 1);
      for (var s = 0; s <= upto; s++) {
        visible.addAll(_stepLines[s]);
      }
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < visible.length; i++)
        OneShot(
          key: ValueKey('logl-${c.round}-$i'),
          duration: const Duration(milliseconds: 280),
          builder: (_, t) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 5),
              child: Text('· ${visible[i]}', textAlign: TextAlign.center, style: style),
            ),
          ),
        ),
    ]);
  }

  // Log persistente que EXPLICA por qué fue ese resultado.
  Widget _explanation(RoundResult r) {
    final e = c;
    final you = e.active;
    final opp = e.oppPlay;
    if (you == null || opp == null) return const SizedBox.shrink();

    String subsTxt(Iterable<CardInstance> subs) {
      final names = subs.map((s) => s.name).toList();
      return names.isEmpty ? '' : '  + ${names.join(' + ')}';
    }

    final youSubs = subsTxt(e.subs.whereType<CardInstance>());
    final oppSubs = subsTxt(opp.subs);
    final verdict = r.winner == Winner.draw
        ? 'EMPATE · nadie pierde integridad'
        : (r.winner == Winner.you
            ? 'GANAS · el rival pierde ${r.damage}'
            : 'PIERDES · pierdes ${r.damage}');
    final vColor = r.winner == Winner.draw ? NH.amber : (r.winner == Winner.you ? NH.pl : NH.xp);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: NH.a(const Color(0xFF090C12), .7),
        border: Border.all(color: NH.line),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('REGISTRO DE EJECUCIÓN', style: NH.mono(size: 7.5, color: NH.dim, spacing: 2.4)),
        const SizedBox(height: 5),
        Text('TÚ ▸ ${you.type.label}$youSubs',
            textAlign: TextAlign.center, style: NH.mono(size: 9.5, weight: FontWeight.w700, color: NH.pl)),
        const SizedBox(height: 2),
        Text('RIVAL ▸ ${opp.rutina.type.label}$oppSubs',
            textAlign: TextAlign.center, style: NH.mono(size: 9.5, weight: FontWeight.w700, color: const Color(0xFFFF6B86))),
        if (r.log.isNotEmpty) ...[
          const SizedBox(height: 5),
          // El log se llena efecto por efecto durante la EJECUCIÓN, SINCRONIZADO con
          // el secuenciador: cada línea aparece cuando se ilumina la carta que la
          // causó (tú primero, luego rival); el resultado, al final.
          _execLogView(r, NH.mono(size: 8.5, color: NH.ink2, height: 1.35)),
        ],
        const SizedBox(height: 5),
        Text('→ $verdict',
            textAlign: TextAlign.center, style: NH.mono(size: 10, weight: FontWeight.w700, color: vColor, spacing: .5)),
      ]),
    );
  }

  Widget _resultBanner(RoundResult r) {
    final isYou = r.winner == Winner.you;
    final isDraw = r.winner == Winner.draw;
    final color = isDraw ? NH.amber : (isYou ? NH.pl : NH.xp);
    final label = isDraw ? 'EMPATE' : (isYou ? 'PROCESO GANADO' : 'PROCESO PERDIDO');
    final dmg = isDraw
        ? null
        : (isYou ? 'EL RIVAL SUFRE DAÑO · −${r.damage}' : 'TU PROCESO SUFRE DAÑO · −${r.damage}');
    return OneShot(
      key: ValueKey('banner${c.round}${r.winner}'),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (_, t) => Transform.scale(
        scale: 0.7 + t * 0.3,
        child: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: NH.mono(size: 14, weight: FontWeight.w700, color: color, spacing: 2).copyWith(shadows: [Shadow(color: NH.a(color, .5), blurRadius: 14)])),
            if (dmg != null) Text(dmg, style: NH.mono(size: 8.5, weight: FontWeight.w700, color: const Color(0xFFFF6B86), spacing: 1)),
          ]),
        ),
      ),
    );
  }

  Widget _youZone() {
    final e = c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, NH.safe + 2),
      child: Stack(children: [
        Column(mainAxisSize: MainAxisSize.min, children: [
          _spot('slots', Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _dropSlot('sub0', 52, 73, e.subs[0]),
            const SizedBox(width: 10),
            _morphOverlay(_dropSlot('active', 72, 100, e.active, glow: true), c.result?.youType, e.active?.type),
            const SizedBox(width: 10),
            _dropSlot('sub1', 52, 73, e.subs[1]),
          ])),
          const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _spot('ram', _ramMeter()),
            _spot('integrity', Row(children: [
              Text(e.nucYou.name, style: NH.mono(size: 9, color: Color(e.nucYou.color), spacing: 1)),
              const SizedBox(width: 8),
              _pips(e.integrityYou, c.integrityMaxYou, NH.pl, base: e.nucYou.integrity, brokeForSide: 'you'),
            ])),
          ]),
          _deckBar(),
          _spot('hand', _hand()),
          _spot('cta', _cta()),
        ]),
        if (c.hit?.side == 'you') _floatingDmg(youLost: true),
      ]),
    );
  }

  // Barra de mazos del jugador (pilas con contador) + insignia de adquisición.
  Widget _deckBar() {
    final e = c;
    return SizedBox(
      height: 30,
      // La insignia "+N" flota hacia arriba; Clip.none evita que se recorte y el
      // anclaje solo-abajo le da altura libre (sin overflow de 2px).
      child: Stack(clipBehavior: Clip.none, children: [
        Center(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _deckStack('RUTINAS', e.rutPileYou, NH.fw),
            const SizedBox(width: 14),
            _deckStack('SUBRUT', e.subPileYou, NH.nl),
          ]),
        ),
        if (c.showAcquire && e.acquiredN > 0)
          Positioned(right: 4, bottom: 0, child: _acquireBadge(e.acquiredN, e.acquiredRut, e.acquiredSub)),
      ]),
    );
  }

  Widget _deckStack(String label, int count, Color dc) => Container(
        padding: const EdgeInsets.fromLTRB(6, 2, 8, 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: NH.a(const Color(0xFF090C12), .7),
          border: Border.all(color: NH.mix(dc, Colors.transparent, .35)),
          boxShadow: [BoxShadow(color: NH.a(dc, .12), blurRadius: 12)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 18, height: 22,
            child: Stack(children: [
              for (var k = 0; k < 3; k++)
                Positioned(
                  left: 3.0 - k * 1.5, top: 3.0 - k * 1.5, right: k * 1.5, bottom: k * 1.5,
                  child: Container(decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: NH.mix(dc, NH.bg, .18),
                    border: Border.all(color: NH.mix(dc, Colors.transparent, .55)),
                  )),
                ),
            ]),
          ),
          const SizedBox(width: 7),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: NH.mono(size: 7, color: NH.dim, spacing: 1.4, height: 1)),
            TweenAnimationBuilder<double>(
              key: ValueKey('$label$count'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 400),
              builder: (_, t, _) => Transform.scale(
                scale: 1 + (1 - t) * 0.5,
                child: Text('$count', style: NH.mono(size: 14, weight: FontWeight.w700, color: Color.lerp(dc, const Color(0xFFEAF1FB), t)!, height: 1)),
              ),
            ),
          ]),
        ]),
      );

  Widget _acquireBadge(int n, int rut, int sub) => OneShot(
        key: ValueKey('acq${c.round}'),
        duration: const Duration(milliseconds: 1900),
        curve: Curves.linear,
        builder: (_, t) {
          final rise = t < .14 ? -30 + (t / .14) * -20 : -50 - ((t - .14) / .86) * 70;
          final op = t < .14 ? t / .14 : (t > .78 ? (1 - (t - .78) / .22) : 1.0);
          return Transform.translate(
            offset: Offset(0, rise.clamp(-120, 0)),
            child: Opacity(
              opacity: op.clamp(0, 1),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), gradient: const LinearGradient(colors: [Color(0xFF7EF0B0), NH.pl]), boxShadow: [BoxShadow(color: NH.a(NH.pl, .6), blurRadius: 16)]),
                  child: Text('ADQUIRIDAS +$n', style: NH.mono(size: 11, weight: FontWeight.w700, color: const Color(0xFF0A0D12), spacing: .6)),
                ),
                const SizedBox(height: 2),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('R+$rut', style: NH.mono(size: 8, weight: FontWeight.w700, color: NH.fw)),
                  const SizedBox(width: 6),
                  Text('S+$sub', style: NH.mono(size: 8, weight: FontWeight.w700, color: const Color(0xFF9A7DFF))),
                ]),
              ]),
            ),
          );
        },
      );

  Widget _ramMeter() {
    final e = c;
    return Row(children: [
      Text('RAM', style: NH.mono(size: 9, color: const Color(0xFF7A8499), spacing: 1)),
      const SizedBox(width: 4),
      for (var i = 0; i < e.ramMax; i++)
        Container(
          width: 9, height: 9, margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < e.ramLeft ? NH.amber : const Color(0xFF1B2230),
            border: i < e.ramLeft ? null : Border.all(color: const Color(0xFF2A3344)),
            boxShadow: i < e.ramLeft ? [BoxShadow(color: NH.amber, blurRadius: 7)] : null,
          ),
        ),
      Text('${e.ramLeft}/${e.ramMax}', style: NH.mono(size: 9, color: NH.dim)),
    ]);
  }

  Widget _hand() {
    final hand = c.handYou;
    final n = hand.length;
    if (n == 0 && _handGhosts.isEmpty) return const SizedBox(height: 92);
    final mid = (n - 1) / 2;
    final gn = _handGhosts.length;
    final gmid = (gn - 1) / 2;
    return SizedBox(
      height: 92,
      child: LayoutBuilder(
        builder: (ctx, cons) {
          // Cada carta ocupa una banda igual (toda tocable); si hay muchas, se
          // solapan visualmente pero cada una conserva su zona de toque.
          final cellW = (cons.maxWidth / max(n, 1)).clamp(30.0, 66.0);
          final gCellW = (cons.maxWidth / max(gn, 1)).clamp(30.0, 66.0);
          return Stack(children: [
            if (n > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [for (var i = 0; i < n; i++) _handCell(hand[i], i, mid, cellW)],
              ),
            // Cartas rebarajadas: se desmaterializan donde estaba la mano vieja.
            if (gn > 0)
              IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [for (var i = 0; i < gn; i++) _ghostCell(_handGhosts[i], i, gmid, gCellW)],
                ),
              ),
          ]);
        },
      ),
    );
  }

  Widget _handCell(CardInstance card, int i, double mid, double cellW) {
    final dragging = _dragActive && _drag?.card.uid == card.uid;
    final fresh = !_seenHand.contains(card.uid);
    if (fresh) _seenHand.add(card.uid);
    Widget visual = Transform.rotate(
      angle: (i - mid) * .05,
      alignment: Alignment.bottomCenter,
      child: CardView(card: card, width: 64),
    );
    if (fresh) {
      // Robo: la carta se "materializa" (escalonado por posición). Si hubo
      // rebarajeo, espera a que la mano vieja termine de desvanecerse.
      final resh = _handGhosts.isNotEmpty;
      visual = Materialize(
        key: ValueKey('mat${card.uid}'),
        duration: Duration(milliseconds: resh ? 820 : 460),
        delay: ((resh ? .42 : 0.0) + i * .055).clamp(0.0, .85),
        child: visual,
      );
    }
    return SizedBox(
      width: cellW,
      height: 92,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (ev) => _onCardDown(ev, card),
        child: Opacity(
          opacity: dragging ? .25 : 1,
          child: OverflowBox(
            minWidth: 64,
            maxWidth: 64,
            alignment: Alignment.bottomCenter,
            child: visual,
          ),
        ),
      ),
    );
  }

  // Carta que dejó la mano por un rebarajeo: misma pose, desmaterializándose.
  Widget _ghostCell(CardInstance card, int i, double mid, double cellW) {
    return SizedBox(
      width: cellW,
      height: 92,
      child: OverflowBox(
        minWidth: 64,
        maxWidth: 64,
        alignment: Alignment.bottomCenter,
        child: Materialize(
          key: ValueKey('demat$_ghostSeq${card.uid}'),
          reverse: true,
          duration: const Duration(milliseconds: 400),
          delay: (i * .05).clamp(0.0, .5),
          child: Transform.rotate(
            angle: (i - mid) * .05,
            alignment: Alignment.bottomCenter,
            child: CardView(card: card, width: 64, animate: false),
          ),
        ),
      ),
    );
  }

  Widget _cta() {
    final e = c;
    final p = c.phase.id;
    if (p == 'programacion') {
      final label = e.needsNullDeclaration
          ? 'DECLARA EL TIPO DEL NULL-SHARD'
          : (e.active != null ? 'COMPILAR ▸' : 'ARRASTRA UNA RUTINA AL PUESTO ACTIVO');
      final enabled = e.canCompile;
      return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _wideBtn(label, enabled: enabled, onTap: enabled ? _compile : null));
    } else if (p == 'compilar' || p == 'revelacion' || p == 'ejecucion') {
      final t = p == 'compilar' ? 'SELLANDO PROCESO…' : (p == 'revelacion' ? 'REVELANDO…' : 'EJECUTANDO…');
      return Padding(padding: const EdgeInsets.only(top: 2), child: _wideBtn(t, loading: true));
    } else if (p == 'resultado' && !e.gameOver) {
      return Padding(padding: const EdgeInsets.only(top: 2), child: _wideBtn('SIGUIENTE RONDA ▸', enabled: true, onTap: c.nextRound));
    }
    return const SizedBox(height: 46);
  }

  Widget _wideBtn(String label, {bool enabled = false, bool loading = false, VoidCallback? onTap}) {
    final accent = loading ? NH.amber : NH.fw;
    return GestureDetector(
      onTap: enabled && !loading ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: enabled || loading ? accent : const Color(0xFF2A3344)),
          gradient: enabled && !loading ? LinearGradient(colors: [NH.a(NH.fw, .16), NH.a(NH.fw, .04)], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
          color: enabled || loading ? null : const Color(0xFF0C1118),
          boxShadow: enabled && !loading ? [BoxShadow(color: NH.a(NH.fw, .22), blurRadius: 16)] : (loading ? [BoxShadow(color: NH.a(NH.amber, .2), blurRadius: 16)] : null),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label, textAlign: TextAlign.center, style: NH.mono(size: 12, weight: FontWeight.w600, color: enabled ? const Color(0xFFEAF7FF) : (loading ? NH.amber : NH.dim), spacing: 1.4)),
          if (loading) ...[const SizedBox(height: 7), const _LoadingBar()],
        ]),
      ),
    );
  }

  // Subrutina del rival en el slot [i]: dorso antes de revelar, carta (zoomable) al revelar.
  Widget? _oppSub(Play? opp, int i) {
    if (opp == null || i >= opp.subs.length) return null;
    if (!c.revealed) return CardBackView(width: 52, seed: 91 + i);
    return _oppCard(opp.subs[i], 52);
  }

  // Carta revelada del rival: tocarla la abre en zoom (para poder leerla).
  Widget _oppCard(CardInstance card, double width) => GestureDetector(
        onTap: () => widget.onInspect(card),
        child: _popCard(card, width),
      );

  // Carta colocada con animación pop (al entrar a un slot).
  Widget _popCard(CardInstance card, double width) => OneShot(
        key: ValueKey('pop${card.uid}'),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (_, t) => Transform.scale(scale: 0.55 + t * 0.45, child: CardView(card: card, width: width, animate: false)),
      );

  // Spotlight de EJECUCIÓN: la carta se levanta/ilumina mientras el secuenciador
  // la tiene enfocada (su línea de log aparece a la vez). Un solo reloj coordina todo.
  Widget _execWrap(Widget card, String execId, Color glow) {
    if (c.phase.id != 'ejecucion') return card;
    return _ExecFx(
      key: ValueKey('exec-$execId-${c.round}'),
      spotlighted: _focusedExecId == execId,
      glow: glow,
      child: card,
    );
  }

  Widget? _execWrapMaybe(Widget? card, String execId, Color glow) =>
      card == null ? null : _execWrap(card, execId, glow);

  // Descarga del GANADOR hacia el perdedor (rayo de energía) — además del daño recibido.
  Widget _dischargeFx() {
    final hit = c.hit;
    if (hit == null) return const SizedBox.shrink();
    final youWon = hit.side == 'opp'; // el rival recibió el daño ⇒ ganaste tú
    final color = youWon ? NH.pl : NH.xp; // color del GANADOR
    return Positioned.fill(
      child: IgnorePointer(
        child: OneShot(
          key: ValueKey('disch${c.round}'),
          duration: const Duration(milliseconds: 750),
          builder: (_, t) => CustomPaint(painter: _DischargePainter(t: t, towardTop: youWon, color: color)),
        ),
      ),
    );
  }

  // Iluminación del GANADOR (su zona se enciende: "absorbió"/ganó fuerza).
  Widget _winnerGlow() {
    final hit = c.hit;
    if (hit == null) return const SizedBox.shrink();
    final youWon = hit.side == 'opp';
    final color = youWon ? NH.pl : NH.xp;
    final center = youWon ? const Alignment(0, .74) : const Alignment(0, -.66);
    return Positioned.fill(
      child: IgnorePointer(
        child: OneShot(
          key: ValueKey('wglow${c.round}'),
          duration: const Duration(milliseconds: 950),
          builder: (_, t) {
            final p = (t < .3 ? t / .3 : 1 - (t - .3) / .7).clamp(0.0, 1.0);
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(center: center, radius: .8, colors: [NH.a(color, .3 * p), Colors.transparent]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _slot({required double width, required double height, Widget? child, bool filled = false}) => Container(
        width: width, height: height, alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: filled ? const Color(0xFF243247) : const Color(0xFF2C3546)),
        ),
        child: child,
      );

  Widget _dropSlot(String id, double width, double height, CardInstance? card, {bool glow = false}) {
    final hot = _hover == id;
    final filled = card != null;
    // Slot compatible con la carta que se está arrastrando (aún sin enganchar).
    final validDrag = _drag != null && _dragActive && !filled && _validTargets(_drag!.card).contains(id);
    // Los overlays (pulso/onda) van en un Stack EXTERNO: así Positioned.fill mide
    // el slot completo (width×height) y no el contenido (p. ej. el texto 'SUB').
    return Stack(children: [
      Container(
        key: _slotKeys[id],
        width: width, height: height, alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: hot ? NH.a(NH.pl, .08) : (validDrag ? NH.a(NH.pl, .04) : null),
          border: Border.all(
            color: hot ? NH.pl : (validDrag ? NH.a(NH.pl, .55) : (filled && glow ? NH.pl : (filled ? const Color(0xFF243247) : const Color(0xFF2C3546)))),
            width: hot ? 1.4 : 1,
          ),
          boxShadow: hot || (filled && glow) ? [BoxShadow(color: NH.a(NH.pl, hot ? .5 : .4), blurRadius: hot ? 22 : 18)] : null,
        ),
        child: filled
            ? GestureDetector(
                onTap: () {
                  if (c.phase.id != 'programacion') {
                    widget.onInspect(card); // ya resuelto: tocar = zoom
                  } else if (id == 'active') {
                    c.returnActive();
                  } else {
                    c.returnSub(id == 'sub0' ? 0 : 1);
                  }
                },
                child: _execWrap(_popCard(card, width), id == 'active' ? 'you-active' : (id == 'sub0' ? 'you-sub0' : 'you-sub1'), NH.pl),
              )
            : Text(id == 'active' ? 'ACTIVO' : 'SUB', style: NH.mono(size: 8, color: const Color(0xFF34405A), spacing: 1.8)),
      ),
      // Pulso del slot válido mientras se arrastra (y aún no está enganchado).
      if (validDrag && !hot) const Positioned.fill(child: IgnorePointer(child: _SlotPulse(color: NH.pl))),
      // Onda expansiva al soltar (color del tipo de la carta).
      if (_dropRipple == id)
        Positioned.fill(
          child: IgnorePointer(
            child: OneShot(
              key: ValueKey('ripple$id$_dropRippleSeq'),
              duration: const Duration(milliseconds: 460),
              builder: (_, t) => CustomPaint(painter: _RipplePainter(t, _dropRippleColor)),
            ),
          ),
        ),
    ]);
  }

  // [max] es el máximo EFECTIVO; [base] la integridad del núcleo sin modificar.
  // Con bonus (+N): los pips extra llevan borde ámbar. Con malus (−N): se dibujan
  // huecos "bloqueados" rojos donde DEBERÍA haber integridad, y un chip ±N.
  Widget _pips(int n, int max, Color color, {String? brokeForSide, int? base}) {
    final hit = c.hit;
    final breaking = hit != null && hit.side == brokeForSide;
    final breakStart = n; // los pips n..n+amount-1 acaban de apagarse
    final b = base ?? max;
    final bonus = max - b;
    return Row(children: [
      if (bonus != 0) _intModChip(bonus),
      for (var i = 0; i < max; i++)
        _pip(i, n, color, breaking && i >= breakStart && i < breakStart + hit.amount, boosted: i >= b),
      for (var i = max; i < b; i++) _voidPip(),
    ]);
  }

  // Chip "±N" junto a los pips: ámbar = integridad extra, rojo = reducida.
  Widget _intModChip(int bonus) {
    final col = bonus > 0 ? NH.amber : NH.xp;
    return Container(
      margin: const EdgeInsets.only(left: 3),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: NH.a(col, .8)),
        color: NH.a(col, .12),
      ),
      child: Text(bonus > 0 ? '+$bonus' : '$bonus',
          style: NH.mono(size: 7.5, weight: FontWeight.w700, color: col)),
    );
  }

  // Hueco de integridad BLOQUEADA por un malus: ahí debería haber un pip.
  Widget _voidPip() => Container(
        width: 15, height: 5, margin: const EdgeInsets.only(left: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1),
          color: NH.a(NH.xp, .08),
          border: Border.all(color: NH.a(NH.xp, .55)),
        ),
        child: Center(
          child: Container(width: 7, height: 1.2, color: NH.a(NH.xp, .75)),
        ),
      );

  Widget _pip(int i, int n, Color color, bool broke, {bool boosted = false}) {
    final on = i < n;
    final base = Container(
      width: 15, height: 5, margin: const EdgeInsets.only(left: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        color: on ? color : const Color(0xFF1B2230),
        border: boosted
            ? Border.all(color: NH.a(NH.amber, on ? 1 : .5), width: .9)
            : (on ? null : Border.all(color: const Color(0xFF2A3344))),
        boxShadow: on
            ? [BoxShadow(color: boosted ? NH.amber : color, blurRadius: 8)]
            : null,
      ),
    );
    if (!broke) return base;
    return OneShot(
      key: ValueKey('pip$i${c.round}'),
      duration: const Duration(milliseconds: 700),
      builder: (_, t) {
        // Flash blanco breve (≈80 ms) antes de apagarse.
        final scale = t < .12 ? 1.7 : (t < .3 ? 1.6 - (t - .12) / .18 * .45 : 1.15 - (t - .3) / .7 * .15);
        final col = t < .12
            ? Color.lerp(Colors.white, NH.xp, t / .12)!
            : Color.lerp(NH.xp, const Color(0xFF1B2230), (t - .12) / .88)!;
        final glow = t < .12 ? 18.0 : 16 * (1 - t);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 15, height: 5, margin: const EdgeInsets.only(left: 3),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(1), color: col, boxShadow: [BoxShadow(color: NH.a(t < .12 ? Colors.white : NH.xp, 1 - t), blurRadius: glow)]),
          ),
        );
      },
    );
  }

  // Número de daño flotante. [youLost] → sobre TU zona (rojo); si no, sobre el
  // rival cuando le pegas (verde). Pop de impacto + jitter + ascenso + fade.
  Widget _floatingDmg({required bool youLost}) {
    final amount = c.hit?.amount ?? 1;
    final col = youLost ? NH.xp : NH.pl;
    final title = youLost ? 'RONDA PERDIDA' : 'PROCESO DAÑADO';
    return Positioned.fill(
      child: IgnorePointer(
        child: OneShot(
          key: ValueKey('dmg${c.round}${youLost ? "y" : "o"}'),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.linear,
          builder: (_, t) {
            final pop = Curves.easeOutBack.transform((t / .18).clamp(0.0, 1.0));
            final numScale = 1.7 - 0.7 * pop; // 1.7 → 1.0 (impacto)
            final rise = t < .2 ? 0.0 : -(t - .2) / .8 * 46;
            final jitter = t < .25 ? sin(t * 60) * 1.5 : 0.0;
            final op = t < .12 ? t / .12 : (t > .72 ? (1 - (t - .72) / .28) : 1.0);
            return Center(
              child: Transform.translate(
                offset: Offset(jitter, rise),
                child: Opacity(
                  opacity: op.clamp(0, 1),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Transform.scale(
                      scale: numScale,
                      child: Text('−$amount',
                          style: NH.disp(size: 36, weight: FontWeight.w700, color: col).copyWith(
                              shadows: [Shadow(color: NH.a(col, .7), blurRadius: 20), const Shadow(color: Colors.black, blurRadius: 6)])),
                    ),
                    const SizedBox(height: 2),
                    Text(title, style: NH.mono(size: 11, weight: FontWeight.w700, color: col, spacing: 2)),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Selector OBLIGATORIO del tipo del NULL-SHARD. Modal: absorbe los toques para
  // que no se pueda interactuar con el tablero hasta declarar (firewall/exploit/signal).
  Widget _nullPicker() => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque, // bloquea el tablero detrás
          onTap: () {},
          child: Container(
            color: NH.a(const Color(0xFF020408), .9),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: const Color(0xFF0A0712), borderRadius: BorderRadius.circular(12), border: Border.all(color: NH.nl), boxShadow: [BoxShadow(color: NH.a(NH.nl, .35), blurRadius: 40)]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('NULL-SHARD', style: NH.disp(size: 18, weight: FontWeight.w700, color: NH.nl, spacing: 1)),
                  const SizedBox(height: 3),
                  Text('Declara su tipo para compilar (obligatorio)', style: NH.mono(size: 9, color: NH.dim, spacing: .6)),
                  const SizedBox(height: 14),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    for (final t in [CType.firewall, CType.exploit, CType.signal])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: GestureDetector(
                          onTap: () => c.declareNull(t),
                          child: Container(
                            width: 82, padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), color: NH.mix(Color(t.color), NH.bg, .10), border: Border.all(color: Color(t.color), width: 1.4), boxShadow: [BoxShadow(color: NH.a(Color(t.color), .25), blurRadius: 12)]),
                            child: Column(children: [
                              Sigil(type: t, size: 34),
                              const SizedBox(height: 6),
                              Text(t.label, textAlign: TextAlign.center, style: NH.mono(size: 8, weight: FontWeight.w700, color: Color(t.color), spacing: .8)),
                            ]),
                          ),
                        ),
                      ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      );

  // Confirmación de rendición (evita salir por accidente con el botón "atrás").
  Widget _confirmExitOverlay() => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _confirmExit = false), // tocar fuera = continuar
          child: Container(
            color: NH.a(const Color(0xFF020408), .86),
            child: Center(
              child: GestureDetector(
                onTap: () {}, // no cerrar al tocar el panel
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  decoration: BoxDecoration(color: const Color(0xFF0B0F17), borderRadius: BorderRadius.circular(14), border: Border.all(color: NH.xp), boxShadow: [BoxShadow(color: NH.a(NH.xp, .3), blurRadius: 34)]),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('¿RENDIRSE?', style: NH.disp(size: 24, weight: FontWeight.w700, color: const Color(0xFFEAF1FB), spacing: 1)),
                    const SizedBox(height: 8),
                    Text('Si sales ahora, pierdes esta partida y el rival gana.',
                        textAlign: TextAlign.center, style: NH.mono(size: 10, color: NH.ink2, height: 1.5)),
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _confirmExit = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: NH.fw), gradient: LinearGradient(colors: [NH.a(NH.fw, .16), NH.a(NH.fw, .04)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                            child: Center(child: Text('CONTINUAR', style: NH.mono(size: 11, weight: FontWeight.w700, color: const Color(0xFFEAF7FF), spacing: 1.2))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onExit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: NH.a(NH.xp, .7))),
                            child: Center(child: Text('RENDIRSE', style: NH.mono(size: 11, weight: FontWeight.w700, color: NH.xp, spacing: 1.2))),
                          ),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

class _MatBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = NH.a(NH.fw, .06)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _MatBgPainter old) => false;
}

/// Efecto de "desconexión" del rival en el TABLERO (cuando ganas la partida):
/// breve estado intacto → glitch (RGB + cortes) con "SEÑAL PERDIDA" → colapso/apagado.
class _DisconnectFx extends StatefulWidget {
  final Widget child;
  final String oppName;
  const _DisconnectFx({required this.child, required this.oppName});

  @override
  State<_DisconnectFx> createState() => _DisconnectFxState();
}

class _DisconnectFxState extends State<_DisconnectFx> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        if (t < .66) {
          // Intacto (0..0.22) → glitch creciente (0.22..0.66).
          final g = ((t - .22) / .44).clamp(0.0, 1.0);
          final jitter = g <= 0 ? 0.0 : sin(t * 90) * 4 * g;
          return Stack(children: [
            Transform.translate(offset: Offset(jitter, 0), child: widget.child),
            if (g > 0)
              Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _GlitchPainter(t, g)))),
            if (g > .25)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Opacity(
                      opacity: (sin(t * 55).abs()).clamp(.2, 1.0),
                      child: Text('▓ ${widget.oppName} :: SEÑAL PERDIDA ▓',
                          style: NH.mono(size: 11, weight: FontWeight.w700, color: NH.xp, spacing: 1.5)
                              .copyWith(shadows: [Shadow(color: NH.a(NH.xp, .7), blurRadius: 10)])),
                    ),
                  ),
                ),
              ),
          ]);
        }
        // Colapso/apagado: se cierra a una línea y se desvanece.
        final k = ((t - .66) / .34).clamp(0.0, 1.0);
        return Opacity(
          opacity: 1 - k,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(1.0, (1 - k).clamp(0.02, 1.0), 1.0),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _GlitchPainter extends CustomPainter {
  final double t; // tiempo global (para variar el ruido por frame)
  final double g; // intensidad 0..1
  _GlitchPainter(this.t, this.g);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random((t * 90).floor());
    final n = (6 + g * 12).round();
    for (var i = 0; i < n; i++) {
      final y = rnd.nextDouble() * size.height;
      final h = 2 + rnd.nextDouble() * 11;
      final dx = (rnd.nextDouble() - .5) * 26 * g;
      final col = rnd.nextBool() ? NH.xp : NH.fw; // cortes rojo/cian (RGB split)
      canvas.drawRect(
        Rect.fromLTWH(dx, y, size.width, h),
        Paint()
          ..color = NH.a(col, .4 * g)
          ..blendMode = BlendMode.screen,
      );
    }
    canvas.drawRect(Offset.zero & size, Paint()..color = NH.a(NH.xp, .07 * g));
  }

  @override
  bool shouldRepaint(covariant _GlitchPainter old) => true;
}

/// Spotlight de una carta durante la EJECUCIÓN: cuando el secuenciador la ENFOCA
/// (`spotlighted`), pulsa (sube + escala + ilumina) y queda algo elevada mientras
/// dure su turno; al perder el foco vuelve a su sitio.
class _ExecFx extends StatefulWidget {
  final Widget child;
  final bool spotlighted;
  final Color glow;
  const _ExecFx({super.key, required this.child, required this.spotlighted, required this.glow});

  @override
  State<_ExecFx> createState() => _ExecFxState();
}

class _ExecFxState extends State<_ExecFx> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void initState() {
    super.initState();
    if (widget.spotlighted) _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(_ExecFx old) {
    super.didUpdateWidget(old);
    if (widget.spotlighted && !old.spotlighted) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final pulse = sin(_c.value.clamp(0.0, 1.0) * pi); // 0 → 1 → 0
        final held = widget.spotlighted ? 1.0 : 0.0; // se mantiene enfocada su turno
        final lift = 9 * pulse + 3 * held;
        final scale = 1 + 0.15 * pulse + 0.03 * held;
        final glowP = (pulse * .8 + held * .35).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, -lift),
          child: Transform.scale(
            scale: scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: NH.a(widget.glow, .7 * glowP), blurRadius: 26 * glowP, spreadRadius: 2 * glowP)],
              ),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Rayo de "descarga" del ganador hacia el perdedor (recorre la pantalla y estalla).
class _DischargePainter extends CustomPainter {
  final double t; // 0..1
  final bool towardTop; // el perdedor está arriba (rival) si true
  final Color color;
  _DischargePainter({required this.t, required this.towardTop, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final winnerY = towardTop ? size.height * .80 : size.height * .20;
    final loserY = towardTop ? size.height * .20 : size.height * .80;
    final headY = winnerY + (loserY - winnerY) * t.clamp(0.0, 1.0);
    final rnd = Random((t * 60).floor() * 7 + 3); // re-aleatoriza por frame (flicker)

    final path = Path()..moveTo(cx, winnerY);
    const steps = 11;
    final pts = <Offset>[Offset(cx, winnerY)];
    for (var i = 1; i <= steps; i++) {
      final f = i / steps;
      final y = winnerY + (headY - winnerY) * f;
      final x = cx + (rnd.nextDouble() - .5) * 42 * (1 - f * .25);
      path.lineTo(x, y);
      pts.add(Offset(x, y));
    }
    // Doble pulso: el rayo "parpadea" una vez a mitad de recorrido.
    final flicker = (t > .35 && t < .5) ? .45 : 1.0;
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = NH.a(color, .55 * flicker)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..color = NH.a(Colors.white, flicker));

    // Ramificaciones: 2-3 ramas cortas desde puntos del rayo principal.
    final branchPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = NH.a(color, .5 * flicker);
    for (var b = 0; b < 3; b++) {
      final from = pts[3 + b * 2];
      final len = 14.0 + rnd.nextDouble() * 16;
      final dir = (rnd.nextBool() ? 1 : -1);
      canvas.drawLine(from, from + Offset(dir * len, (rnd.nextDouble() - .3) * len), branchPaint);
    }

    // Estallido en el perdedor cuando el rayo llega: relleno + anillo + chispas.
    if (t > .5) {
      final f = ((t - .5) / .5).clamp(0.0, 1.0);
      final c2 = Offset(cx, loserY);
      canvas.drawCircle(c2, 70 * f,
          Paint()..color = NH.a(color, .4 * (1 - f))..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
      // Anillo expandiéndose (radio 0→46, stroke 3→0).
      canvas.drawCircle(c2, 46 * f,
          Paint()..style = PaintingStyle.stroke..strokeWidth = 3 * (1 - f)..color = NH.a(Colors.white, .8 * (1 - f)));
      // 6 chispas radiales.
      final spark = Paint()..color = NH.a(color, 1 - f)..strokeWidth = 2..strokeCap = StrokeCap.round;
      for (var s = 0; s < 6; s++) {
        final ang = s * pi / 3;
        final r0 = 10 + 30 * f;
        canvas.drawLine(c2 + Offset(cos(ang), sin(ang)) * r0, c2 + Offset(cos(ang), sin(ang)) * (r0 + 8 * (1 - f)), spark);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DischargePainter old) => true;
}

/// Barra de 2 px con un segmento ámbar que recorre el ancho (estados de carga del botón).
class _LoadingBar extends StatefulWidget {
  const _LoadingBar();
  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      width: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: Stack(children: [
          Positioned.fill(child: ColoredBox(color: NH.a(NH.amber, .12))),
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final t = _c.value;
              return Align(
                alignment: Alignment(-1 + 2 * t, 0),
                child: Container(
                  width: 38,
                  height: 2,
                  decoration: BoxDecoration(
                    color: NH.amber,
                    boxShadow: [BoxShadow(color: NH.a(NH.amber, .6), blurRadius: 6)],
                  ),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}

/// Borde que respira sobre un slot compatible mientras se arrastra una carta.
class _SlotPulse extends StatefulWidget {
  final Color color;
  const _SlotPulse({required this.color});
  @override
  State<_SlotPulse> createState() => _SlotPulseState();
}

class _SlotPulseState extends State<_SlotPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final p = Curves.easeInOut.transform(_c.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: NH.a(widget.color, .25 + .55 * p), width: 1.2),
            boxShadow: [BoxShadow(color: NH.a(widget.color, .10 + .22 * p), blurRadius: 8 + 8 * p)],
          ),
        );
      },
    );
  }
}

/// Anillo que se expande y se desvanece al soltar una carta en el slot.
class _RipplePainter extends CustomPainter {
  final double t;
  final Color color;
  _RipplePainter(this.t, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide * 0.62 * Curves.easeOut.transform(t);
    final a = 1 - t;
    canvas.drawCircle(center, r,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4 * a..color = NH.a(color, .8 * a));
    if (t < .35) canvas.drawCircle(center, r, Paint()..color = NH.a(color, .12 * (1 - t / .35)));
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) => old.t != t;
}
