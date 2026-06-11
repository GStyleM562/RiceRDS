/// Servicio de audio (música + SFX), portado de la estructura de claudenodecombat.
/// Claves heredadas de ahí (ya probadas):
///  - El player de música se RECREA en cada cambio de pista (reusarlo se corrompe).
///  - AudioContext global con `audioFocus: none` (los SFX NO cortan la música);
///    el player de música usa su propio contexto con `audioFocus: gain`.
///  - Pool pequeño de players de SFX en round-robin.
///  - Si un archivo no existe, se ignora en silencio → el juego corre igual hasta
///    que sueltes el `.mp3` en `assets/audio/`.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Pistas de música (loops por contexto). Archivos en `assets/audio/`.
enum Music {
  menu('music_menu.mp3'), // menú y fuera de partida
  deckbuild('music_deckbuild.mp3'), // armando mazo
  combat('music_combat.mp3'), // combate normal
  combatDanger('music_combat_danger.mp3'), // combate con 1-2 de integridad (peligro)
  victory('music_victory.mp3'), // pantalla de victoria
  defeat('music_defeat.mp3'); // pantalla de derrota

  final String file;
  const Music(this.file);
}

/// Catálogo de SFX (convención `sfx_<categoria>_<nombre>.mp3`). Aún sin archivos:
/// la estructura ya existe para ir agregándolos cuando los tengas. Algunos ya
/// están cableados (colocar carta, compilar); el resto queda listo para el futuro
/// (p. ej. cuando los reveals tengan un ORDEN y se puedan escuchar uno a uno).
enum Sfx {
  // ── EN USO (cableados) ──
  uiTap('sfx_ui_tap.mp3'), // presionar botón
  cardZoom('sfx_card_zoom.mp3'), // abrir carta en zoom (clic)
  cardPick('sfx_card_pick.mp3'), // empezar a arrastrar la carta
  cardPlace('sfx_card_place.mp3'), // soltar la carta en el campo
  compile('sfx_compile.mp3'), // COMPILAR
  execFocus('sfx_exec_focus.mp3'), // highlight de SUBRUTINA en EJECUCIÓN (tick sutil)
  // Highlight ÚNICO por TIPO de Rutina (identidad sonora del tipo) en EJECUCIÓN.
  revealFirewall('sfx_reveal_firewall.mp3'), // CORTAFUEGOS (cian)
  revealExploit('sfx_reveal_exploit.mp3'), // EXPLOIT (rojo)
  revealSignal('sfx_reveal_signal.mp3'), // PULSO (verde)
  revealNull('sfx_reveal_null.mp3'), // NULL (púrpura)
  damageDealt('sfx_damage_dealt.mp3'), // rayo+impacto: el RIVAL recibe daño
  damageTaken('sfx_damage_taken.mp3'), // rayo+impacto: TÚ recibes daño (distorsión)
  lowWarning('sfx_low_warning.mp3'), // aviso 1 sola vez/partida al caer a 1 de integridad
  enemyLose('sfx_enemy_lose_static.mp3'), // estática lejana: el enemigo pierde (se desconecta)
  playerLose('sfx_player_lose_static.mp3'), // estática/distorsión fuerte: TÚ pierdes

  // ── OPCIONALES / FUTUROS (definidos, aún sin cablear) ──
  cardReturn('sfx_card_return.mp3'), // devolver carta a la mano
  acquire('sfx_acquire.mp3'), // robar cartas
  blocked('sfx_blocked.mp3'); // BLINDAJE anula daño

  final String file;
  const Sfx(this.file);
}

class AudioService with WidgetsBindingObserver {
  AudioService._();
  static final AudioService instance = AudioService._();

  // Música — player recreado por pista.
  AudioPlayer? _musicPlayer;
  Music? _currentMusic;
  Music? _suspendedMusic;
  double _lastMusicVolume = 0.55;

  // SFX — pool round-robin.
  static const int _sfxPoolSize = 4;
  final List<AudioPlayer> _sfxPool = List.generate(_sfxPoolSize, (_) => AudioPlayer());
  int _nextSlot = 0;

  bool _initialized = false;

  // Ajustes (sin UI todavía; defaults encendidos). Listos para un futuro menú.
  bool musicEnabled = true;
  bool soundsEnabled = true;
  double musicVolume = 1.0;
  double soundsVolume = 1.0;

  static AudioContext _ctx(AndroidAudioFocus focus) => AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: focus,
        ),
        iOS: AudioContextIOS(
          category: focus == AndroidAudioFocus.gain
              ? AVAudioSessionCategory.playback
              : AVAudioSessionCategory.ambient,
          options: focus == AndroidAudioFocus.gain
              ? const {AVAudioSessionOptions.mixWithOthers}
              : const {},
        ),
      );

  /// Llamar UNA vez antes de `runApp()`.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    try {
      await AudioPlayer.global.setAudioContext(_ctx(AndroidAudioFocus.none));
    } catch (_) {/* silencioso */}
    // Los players del pool se crean antes del contexto global → aplícalo ahora.
    for (final p in _sfxPool) {
      try {
        await p.setAudioContext(_ctx(AndroidAudioFocus.none));
      } catch (_) {/* silencioso */}
    }
  }

  // ── Lifecycle: pausa al ir a background, restaura al volver ──
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      final m = _currentMusic;
      if (m == null) return;
      _suspendedMusic = m;
      _currentMusic = null;
      _stopMusicPlayer();
    } else if (state == AppLifecycleState.resumed) {
      final m = _suspendedMusic;
      _suspendedMusic = null;
      if (m != null) playMusic(m);
    }
  }

  // ── API ──
  void playMusic(Music track, {double volume = 0.55}) {
    if (_currentMusic == track && musicEnabled) return; // ya suena: no reiniciar
    _currentMusic = track;
    _lastMusicVolume = volume;
    if (!musicEnabled) return;
    _startMusicTrack(track, volume * musicVolume);
  }

  void stopMusic() {
    _currentMusic = null;
    _stopMusicPlayer();
  }

  void playSfx(Sfx sfx, {double volume = 1.0}) {
    if (!soundsEnabled) return;
    _playOnPool(sfx.file, volume * soundsVolume);
  }

  /// Rutas de assets esperadas (para el panel de RUTAS en debug). Si el archivo no
  /// existe todavía, el juego corre igual; este listado dice dónde dejarlo.
  static List<({String label, String path})> musicAssets() =>
      [for (final m in Music.values) (label: m.name, path: 'assets/audio/${m.file}')];
  static List<({String label, String path})> sfxAssets() =>
      [for (final s in Sfx.values) (label: s.name, path: 'assets/audio/${s.file}')];

  /// Activa/desactiva la música en vivo (para un futuro botón de mute).
  void setMusicEnabled(bool on) {
    musicEnabled = on;
    if (!on) {
      _stopMusicPlayer();
    } else if (_currentMusic != null) {
      _startMusicTrack(_currentMusic!, _lastMusicVolume * musicVolume);
    }
  }

  // ── Internos ──
  void _startMusicTrack(Music track, double volume) {
    final path = 'audio/${track.file}';
    final previous = _musicPlayer;
    final p = AudioPlayer();
    _musicPlayer = p;
    () async {
      if (previous != null) {
        try {
          await previous.stop();
        } catch (_) {}
        try {
          await previous.dispose();
        } catch (_) {}
      }
      try {
        await p.setAudioContext(_ctx(AndroidAudioFocus.gain));
        await p.setReleaseMode(ReleaseMode.loop);
        await p.setVolume(volume);
        await p.play(AssetSource(path));
      } catch (e) {
        if (kDebugMode) debugPrint('[Audio] música $path no disponible: $e');
      }
    }();
  }

  void _stopMusicPlayer() {
    final p = _musicPlayer;
    _musicPlayer = null;
    if (p == null) return;
    () async {
      try {
        await p.stop();
      } catch (_) {}
      try {
        await p.dispose();
      } catch (_) {}
    }();
  }

  void _playOnPool(String relativePath, double volume) {
    final player = _sfxPool[_nextSlot];
    _nextSlot = (_nextSlot + 1) % _sfxPoolSize;
    final path = 'audio/$relativePath';
    () async {
      try {
        await player.stop();
        await player.setVolume(volume);
        await player.play(AssetSource(path));
      } catch (e) {
        if (kDebugMode) debugPrint('[Audio] sfx $path no disponible: $e');
      }
    }();
  }
}
