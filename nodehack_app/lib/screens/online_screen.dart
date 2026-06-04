/// PVP por salas con código. Lobby (crear / unirse / esperar) y, al arrancar la
/// partida, reutiliza la MISMA mesa de duelo ([MatchScreen]) alimentada por el
/// [NetworkMatchController].
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nodehack_engine/card_instance.dart';
import 'package:nodehack_engine/deck.dart';

import '../net/ws_client.dart';
import '../state/network_match_controller.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import 'match_screen.dart';

class OnlineScreen extends StatefulWidget {
  final Deck deck;
  final String playerName;
  final String serverUrl;
  final void Function(String name) onSetName;
  final void Function(String url) onSetServerUrl;
  final VoidCallback onExit; // volver al menú
  final void Function(String outcome, int round) onFlush;
  final void Function(CardInstance) onInspect;

  const OnlineScreen({
    super.key,
    required this.deck,
    required this.playerName,
    required this.serverUrl,
    required this.onSetName,
    required this.onSetServerUrl,
    required this.onExit,
    required this.onFlush,
    required this.onInspect,
  });

  @override
  State<OnlineScreen> createState() => _OnlineScreenState();
}

enum _Mode { choose, host, join }

class _OnlineScreenState extends State<OnlineScreen> {
  late final TextEditingController _name = TextEditingController(text: widget.playerName);
  late final TextEditingController _server = TextEditingController(text: widget.serverUrl);
  final TextEditingController _code = TextEditingController();

  _Mode _mode = _Mode.choose;
  NetworkMatchController? _ctrl;

  @override
  void dispose() {
    _ctrl?.dispose();
    _name.dispose();
    _server.dispose();
    _code.dispose();
    super.dispose();
  }

  void _persist() {
    widget.onSetName(_name.text);
    widget.onSetServerUrl(_server.text);
  }

  NetworkMatchController _newCtrl() {
    final url = _server.text.trim().isEmpty ? widget.serverUrl : _server.text.trim();
    final ctrl = NetworkMatchController(
      ws: WsClient(url),
      deckYou: widget.deck,
      playerName: _name.text.trim().isEmpty ? widget.playerName : _name.text.trim(),
      onFlush: widget.onFlush,
    );
    return ctrl;
  }

  void _host() {
    _persist();
    final ctrl = _newCtrl();
    setState(() {
      _mode = _Mode.host;
      _ctrl = ctrl;
    });
    ctrl.host();
  }

  void _join() {
    _persist();
    final code = _code.text.trim();
    if (code.isEmpty) return;
    final ctrl = _newCtrl();
    setState(() => _ctrl = ctrl);
    ctrl.join(code);
  }

  void _back() {
    _ctrl?.leave();
    _ctrl?.dispose();
    _ctrl = null;
    widget.onExit();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    if (ctrl != null) {
      return AnimatedBuilder(
        animation: ctrl,
        builder: (context, _) {
          if (ctrl.matchStarted && !ctrl.gameOver) {
            return MatchScreen(ctrl: ctrl, onExit: _back, onInspect: widget.onInspect);
          }
          return _lobbyStatus(ctrl);
        },
      );
    }
    return _chooser();
  }

  // ---------------- Lobby ----------------
  Widget _shell({required Widget child}) => Stack(children: [
        const GridBg(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: NH.safe + 18),
            Row(children: [
              GestureDetector(
                onTap: _back,
                child: Text('‹ MENÚ', style: NH.mono(size: 12, color: NH.ink2, spacing: 1)),
              ),
              const Spacer(),
              Text('PVP · SALAS', style: NH.mono(size: 11, color: NH.fw, spacing: 3)),
            ]),
            const SizedBox(height: 18),
            Expanded(child: SingleChildScrollView(child: child)),
          ]),
        ),
      ]);

  Widget _chooser() => _shell(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('JUGAR ONLINE',
              style: NH.disp(size: 30, weight: FontWeight.w700, color: const Color(0xFFEAF7FF), spacing: 1)),
          const SizedBox(height: 4),
          Text('Reta a un amigo con un código de sala.', style: NH.mono(size: 10, color: NH.dim)),
          const SizedBox(height: 22),
          _field('TU NOMBRE', _name, hint: 'OPERADOR', max: 16),
          const SizedBox(height: 12),
          _field('SERVIDOR (wss://…/ws)', _server, hint: kHintServer, mono: true),
          const SizedBox(height: 8),
          Text('Mazo: ${widget.deck.name}  ·  núcleo ${widget.deck.nucleoId}',
              style: NH.mono(size: 9, color: NH.dim2)),
          const SizedBox(height: 22),
          _bigBtn('CREAR SALA ▸', 'Genera un código y comparte', _host, primary: true),
          const SizedBox(height: 12),
          _bigBtn('UNIRSE A SALA', 'Escribe el código de un amigo', () => setState(() => _mode = _Mode.join)),
          if (_mode == _Mode.join) ...[
            const SizedBox(height: 14),
            _joinForm(),
          ],
        ]),
      );

  Widget _joinForm() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: NH.a(NH.panel, .7),
          border: Border.all(color: const Color(0xFF1C2533)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('CÓDIGO DE SALA', style: NH.mono(size: 9, color: NH.dim, spacing: 2)),
          const SizedBox(height: 8),
          TextField(
            controller: _code,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              LengthLimitingTextInputFormatter(4),
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              TextInputFormatter.withFunction((_, n) => n.copyWith(text: n.text.toUpperCase())),
            ],
            style: NH.disp(size: 34, weight: FontWeight.w700, color: const Color(0xFFEAF7FF), spacing: 10),
            decoration: _dec('····'),
          ),
          const SizedBox(height: 12),
          _bigBtn('CONECTAR ▸', '', _join, primary: true),
        ]),
      );

  Widget _lobbyStatus(NetworkMatchController ctrl) {
    String title, sub;
    Widget? extra;
    switch (ctrl.stage) {
      case OnlineStage.connecting:
        title = 'CONECTANDO…';
        sub = 'Estableciendo enlace con el servidor';
      case OnlineStage.waitingOpponent:
        title = 'SALA CREADA';
        sub = 'Comparte el código. Esperando al rival…';
        extra = _codeBadge(ctrl.roomCode ?? '····');
      case OnlineStage.lobby:
        title = 'EN SALA';
        sub = 'Esperando inicio…';
        extra = _codeBadge(ctrl.roomCode ?? '····');
      case OnlineStage.error:
        title = 'SIN CONEXIÓN';
        sub = ctrl.errorMsg ?? 'No se pudo conectar';
      case OnlineStage.ended:
        title = 'PARTIDA TERMINADA';
        sub = '';
      case OnlineStage.match:
        title = 'INICIANDO…';
        sub = '';
    }
    return _shell(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 30),
        Center(child: Text(title, style: NH.disp(size: 26, weight: FontWeight.w700, color: const Color(0xFFEAF7FF), spacing: 1))),
        const SizedBox(height: 8),
        Center(child: Text(sub, textAlign: TextAlign.center, style: NH.mono(size: 10, color: NH.dim))),
        if (extra != null) ...[const SizedBox(height: 26), extra],
        const SizedBox(height: 30),
        if (ctrl.stage == OnlineStage.connecting || ctrl.stage == OnlineStage.waitingOpponent || ctrl.stage == OnlineStage.lobby)
          const Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2, color: NH.fw))),
        if (ctrl.stage == OnlineStage.error) ...[
          const SizedBox(height: 10),
          _bigBtn('VOLVER', '', _back, primary: true),
        ],
      ]),
    );
  }

  Widget _codeBadge(String code) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: NH.a(const Color(0xFF090C12), .8),
            border: Border.all(color: NH.fw),
            boxShadow: [BoxShadow(color: NH.a(NH.fw, .25), blurRadius: 22)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('CÓDIGO', style: NH.mono(size: 9, color: NH.dim, spacing: 3)),
            const SizedBox(height: 4),
            Text(code, style: NH.disp(size: 44, weight: FontWeight.w700, color: NH.fw, spacing: 10)),
          ]),
        ),
      );

  // ---------------- Widgets pequeños ----------------
  Widget _field(String label, TextEditingController c, {String? hint, bool mono = false, int? max}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: NH.mono(size: 9, color: NH.dim, spacing: 2)),
        const SizedBox(height: 5),
        TextField(
          controller: c,
          inputFormatters: max != null ? [LengthLimitingTextInputFormatter(max)] : null,
          style: mono ? NH.mono(size: 12, color: const Color(0xFFEAF1FB)) : NH.disp(size: 16, color: const Color(0xFFEAF1FB)),
          decoration: _dec(hint),
        ),
      ]);

  InputDecoration _dec(String? hint) => InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: NH.mono(size: 12, color: NH.dim2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1C2533))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: NH.fw)),
      );

  Widget _bigBtn(String label, String sub, VoidCallback onTap, {bool primary = false}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: primary
                ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [NH.a(NH.fw, .14), NH.a(NH.panel, .7)])
                : null,
            color: primary ? null : NH.a(NH.panel, .7),
            border: Border.all(color: primary ? NH.fw : const Color(0xFF1C2533)),
            boxShadow: primary ? [BoxShadow(color: NH.a(NH.fw, .16), blurRadius: 20)] : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: NH.disp(size: 15, weight: FontWeight.w600, color: const Color(0xFFEAF1FB), spacing: 1.2)),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(sub, style: NH.mono(size: 9, color: NH.dim)),
            ],
          ]),
        ),
      );
}

const String kHintServer = 'ws://… o wss://…';
