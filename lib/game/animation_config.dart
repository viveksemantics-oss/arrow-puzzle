import '../features/gameplay/engine/arrow_direction.dart';
import '../features/gameplay/engine/arrow_model.dart';

/// Tuning constants for arrow slide-out and shake animations.
/// Slower [slideSpeedCellsPerSec] = slower arrow glide.
class AnimationConfig {
  static const double slideSpeedCellsPerSec = 14.0;
  static const int easeInMs = 120;
  static const int minSlideMs = 350;
  static const int maxSlideMs = 1100;
  static const double fadeFraction = 0.2;

  // Blocked-tap shake & flash
  static const double shakeOffsetCells = 0.12;
  static const int shakeOscillations = 3;
  static const int shakeDurationMs = 250;
  static const int blockFlashDurationMs = 300;

  // Sound volume (0.0 to 1.0)
  static const double masterSoundVolume = 0.75;
  static const double tapSoundVolume = 0.7;
  static const double slideSoundVolume = 0.65;
  static const double errorSoundVolume = 0.8;
  static const double winSoundVolume = 0.85;
  static const double loseSoundVolume = 0.8;
  static const double hintSoundVolume = 0.75;
  static const double buttonSoundVolume = 0.6;

  /// Exact cells from [arrow.head] to the board edge along its exit direction (plus 1 cell margin).
  static int distanceToBoardEdgeCells(ArrowModel arrow, int boardSize) {
    final head = arrow.head;
    switch (arrow.direction) {
      case ArrowDirection.up:
        return head.row + 1;
      case ArrowDirection.down:
        return boardSize - head.row;
      case ArrowDirection.left:
        return head.col + 1;
      case ArrowDirection.right:
        return boardSize - head.col;
    }
  }

  /// Computes slide duration in ms from total travel distance and [slideSpeedCellsPerSec],
  /// clamped between [minSlideMs] and [maxSlideMs].
  static int computeSlideDurationMs(ArrowModel arrow, int boardSize) {
    final arrowLenCells = (arrow.allPoints.length - 1).toDouble();
    final edgeDistCells = distanceToBoardEdgeCells(arrow, boardSize).toDouble();
    const headLenCells = 0.55;
    final totalCells = arrowLenCells + edgeDistCells + headLenCells;
    final rawMs = ((totalCells / slideSpeedCellsPerSec) * 1000.0).round();
    return rawMs.clamp(minSlideMs, maxSlideMs);
  }

  /// Maps linear time [t] in [0, 1] to travel fraction in [0, 1]:
  /// smooth quadratic ease-in over the first [easeInMs], then constant speed.
  static double easeInThenConstant(double t, int durationMs) {
    if (t <= 0.0) return 0.0;
    if (t >= 1.0) return 1.0;
    final easeFrac = (easeInMs / durationMs).clamp(0.0, 0.45);
    if (easeFrac <= 0.0) return t;

    final vConst = 1.0 / (1.0 - 0.5 * easeFrac);
    if (t < easeFrac) {
      return 0.5 * vConst * (t * t / easeFrac);
    }
    return 0.5 * vConst * easeFrac + vConst * (t - easeFrac);
  }
}
