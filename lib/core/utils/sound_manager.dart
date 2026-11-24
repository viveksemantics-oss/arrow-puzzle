import 'package:flutter/services.dart';
import '../../services/sound_service.dart';

/// Sound and Haptic feedback manager for Eklavya's Aim.
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final SoundService _soundService = SoundService();

  bool get soundEnabled => _soundService.soundEnabled;
  set soundEnabled(bool value) => _soundService.setSoundEnabled(value);

  bool musicEnabled = true;
  bool hapticsEnabled = true;

  Future<void> init({
    required bool sound,
    required bool music,
    required bool haptics,
  }) async {
    musicEnabled = music;
    hapticsEnabled = haptics;
    await _soundService.init(soundEnabled: sound);
  }

  /// Arrow tap + slide sound for a free arrow
  void playTap() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    _soundService.play(SoundType.tap);
  }

  /// Free arrow slide-out sound (plays tap + slide)
  void playExit() {
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    _soundService.play(SoundType.tap);
    _soundService.play(SoundType.slide);
  }

  /// Blocked move error shake sound
  void playBlocked() {
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    _soundService.play(SoundType.error);
  }

  /// Level victory sound
  void playWin() {
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
    _soundService.play(SoundType.win);
  }

  /// Level failed / Game Over sound
  void playLose() {
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
    _soundService.play(SoundType.lose);
  }

  /// Hint activated sound
  void playHint() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    _soundService.play(SoundType.hint);
  }

  /// Generic UI button click
  void playClick() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    _soundService.play(SoundType.button);
  }

  void dispose() {
    _soundService.dispose();
  }
}
