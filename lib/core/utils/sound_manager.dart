import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Sound and Haptic feedback manager for Arrow Escape.
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  AudioPlayer? _player;
  bool soundEnabled = true;
  bool musicEnabled = true;
  bool hapticsEnabled = true;

  Future<void> init({
    required bool sound,
    required bool music,
    required bool haptics,
  }) async {
    soundEnabled = sound;
    musicEnabled = music;
    hapticsEnabled = haptics;
    try {
      _player = AudioPlayer();
    } catch (_) {
      // Headless / unsupported audio fallback
    }
  }

  /// Arrow tap sound
  void playTap() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    if (!soundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Successful arrow exit sound
  void playExit() {
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (!soundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Blocked move error shake sound
  void playBlocked() {
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (!soundEnabled) return;
    SystemSound.play(SystemSoundType.alert);
  }

  /// Level victory sound
  void playWin() {
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (!soundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Generic UI button click
  void playClick() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    if (!soundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  void dispose() {
    _player?.dispose();
  }
}
