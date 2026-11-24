import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../game/animation_config.dart';

enum SoundType {
  tap('sounds/tap.wav'),
  slide('sounds/slide.wav'),
  error('sounds/error.wav'),
  win('sounds/win.wav'),
  lose('sounds/lose.wav'),
  hint('sounds/hint.wav'),
  button('sounds/button.wav');

  final String assetPath;
  const SoundType(this.assetPath);
}

/// Low-latency singleton sound service with pooled players for overlapping playback.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final Map<SoundType, List<AudioPlayer>> _pools = {};
  final Map<SoundType, int> _poolIndex = {};
  final Map<SoundType, String> _loadErrors = {};

  bool _isInitialized = false;
  bool _soundEnabled = true;
  bool _isBackgrounded = false;
  bool _isAdShowing = false;

  bool get isInitialized => _isInitialized;
  bool get soundEnabled => _soundEnabled;
  Map<SoundType, String> get loadErrors => Map.unmodifiable(_loadErrors);

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      _stopAll();
    }
  }

  void setBackgrounded(bool backgrounded) {
    _isBackgrounded = backgrounded;
    if (backgrounded) {
      _stopAll();
    }
  }

  void setAdShowing(bool showing) {
    _isAdShowing = showing;
    if (showing) {
      _stopAll();
    }
  }

  double _volumeFor(SoundType type) {
    final base = switch (type) {
      SoundType.tap => AnimationConfig.tapSoundVolume,
      SoundType.slide => AnimationConfig.slideSoundVolume,
      SoundType.error => AnimationConfig.errorSoundVolume,
      SoundType.win => AnimationConfig.winSoundVolume,
      SoundType.lose => AnimationConfig.loseSoundVolume,
      SoundType.hint => AnimationConfig.hintSoundVolume,
      SoundType.button => AnimationConfig.buttonSoundVolume,
    };
    return (base * AnimationConfig.masterSoundVolume).clamp(0.0, 1.0);
  }

  /// Preloads all sound assets into low-latency pools.
  Future<void> init({bool soundEnabled = true}) async {
    _soundEnabled = soundEnabled;
    if (_isInitialized) return;

    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[SoundService] AudioContext notice: $e');
    }

    for (final type in SoundType.values) {
      final poolSize = (type == SoundType.tap || type == SoundType.slide) ? 4 : 2;
      final players = <AudioPlayer>[];
      _poolIndex[type] = 0;

      for (int i = 0; i < poolSize; i++) {
        try {
          final player = AudioPlayer();
          await player.setPlayerMode(PlayerMode.lowLatency);
          await player.setReleaseMode(ReleaseMode.stop);
          await player.setVolume(_volumeFor(type));
          await player.setSource(AssetSource(type.assetPath));
          players.add(player);
        } catch (e) {
          _loadErrors[type] = e.toString();
          debugPrint('[SoundService] Failed to preload ${type.assetPath}: $e');
        }
      }
      _pools[type] = players;
    }

    _isInitialized = true;
  }

  /// Plays [type] immediately with zero delay, rotating through pooled players.
  Future<void> play(SoundType type) async {
    if (!_soundEnabled || _isBackgrounded || _isAdShowing) return;
    await _playInternal(type);
  }

  /// Debug helper to test a sound directly and return any error message.
  Future<String?> testPlay(SoundType type) async {
    if (_loadErrors.containsKey(type) && (_pools[type]?.isEmpty ?? true)) {
      return _loadErrors[type];
    }
    try {
      await _playInternal(type, forceIgnoreMute: true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _playInternal(SoundType type, {bool forceIgnoreMute = false}) async {
    if (!forceIgnoreMute && (!_soundEnabled || _isBackgrounded || _isAdShowing)) {
      return;
    }
    try {
      final pool = _pools[type];
      if (pool == null || pool.isEmpty) {
        return;
      }

      final idx = (_poolIndex[type] ?? 0) % pool.length;
      _poolIndex[type] = (idx + 1) % pool.length;
      final player = pool[idx];

      await player.stop();
      await player.setVolume(_volumeFor(type));
      await player.play(AssetSource(type.assetPath));
    } catch (e) {
      debugPrint('[SoundService] Error playing ${type.name}: $e');
      if (forceIgnoreMute) rethrow;
    }
  }

  Future<void> _stopAll() async {
    for (final pool in _pools.values) {
      for (final p in pool) {
        try {
          await p.stop();
        } catch (_) {}
      }
    }
  }

  Future<void> dispose() async {
    for (final pool in _pools.values) {
      for (final p in pool) {
        try {
          await p.dispose();
        } catch (_) {}
      }
    }
    _pools.clear();
    _isInitialized = false;
  }
}
