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
  menu('music_menu.mp3'),
  combat('music_combat.mp3');

  final String file;
  const Music(this.file);
}

/// Catálogo de SFX (convención `sfx_<categoria>_<nombre>.mp3`). Aún sin archivos:
/// la estructura ya existe para ir agregándolos cuando los tengas. Algunos ya
/// están cableados (colocar carta, compilar); el resto queda listo para el futuro
/// (p. ej. cuando los reveals tengan un ORDEN y se puedan escuchar uno a uno).
enum Sfx {
  uiTap('sfx_ui_tap.mp3'),
  cardPick('sfx_card_pick.mp3'),
  cardPlace('sfx_card_place.mp3'),
  cardReturn('sfx_card_return.mp3'),
  compile('sfx_compile.mp3'),

  // Revelado (para cuando el revelado sea ordenado y audible).
  revealFirewall('sfx_reveal_firewall.mp3'),
  revealExploit('sfx_reveal_exploit.mp3'),
  revealSignal('sfx_reveal_signal.mp3'),
  revealNull('sfx_reveal_null.mp3'),

  // Resolución.
  damageDealt('sfx_damage_dealt.mp3'),
  damageTaken('sfx_damage_taken.mp3'),
  blocked('sfx_blocked.mp3'), // BLINDAJE anula daño
  acquire('sfx_acquire.mp3'), // robar cartas

  roundWin('sfx_round_win.mp3'),
  roundLose('sfx_round_lose.mp3'),
  roundDraw('sfx_round_draw.mp3'),
  matchWin('sfx_match_win.mp3'),
  matchLose('sfx_match_lose.mp3');

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
