import 'dart:math' as math;

/// Cardinal directions an arrow can point towards.
enum ArrowDirection {
  up,
  down,
  left,
  right;

  /// Delta row when moving in this direction.
  int get dy {
    switch (this) {
      case ArrowDirection.up:
        return -1;
      case ArrowDirection.down:
        return 1;
      case ArrowDirection.left:
      case ArrowDirection.right:
        return 0;
    }
  }

  /// Delta column when moving in this direction.
  int get dx {
    switch (this) {
      case ArrowDirection.left:
        return -1;
      case ArrowDirection.right:
        return 1;
      case ArrowDirection.up:
      case ArrowDirection.down:
        return 0;
    }
  }

  /// Opposite direction.
  ArrowDirection get opposite {
    switch (this) {
      case ArrowDirection.up:
        return ArrowDirection.down;
      case ArrowDirection.down:
        return ArrowDirection.up;
      case ArrowDirection.left:
        return ArrowDirection.right;
      case ArrowDirection.right:
        return ArrowDirection.left;
    }
  }

  /// Rotation angle in radians for CustomPainter (up = 0 rad).
  double get rotationAngle {
    switch (this) {
      case ArrowDirection.up:
        return 0.0;
      case ArrowDirection.right:
        return math.pi / 2.0;
      case ArrowDirection.down:
        return math.pi;
      case ArrowDirection.left:
        return 3.0 * math.pi / 2.0;
    }
  }

  /// Unicode arrow symbol for logging / debugging.
  String get symbol {
    switch (this) {
      case ArrowDirection.up:
        return '↑';
      case ArrowDirection.down:
        return '↓';
      case ArrowDirection.left:
        return '←';
      case ArrowDirection.right:
        return '→';
    }
  }

  /// Human-readable label.
  String get label {
    switch (this) {
      case ArrowDirection.up:
        return 'UP';
      case ArrowDirection.down:
        return 'DOWN';
      case ArrowDirection.left:
        return 'LEFT';
      case ArrowDirection.right:
        return 'RIGHT';
    }
  }

  static ArrowDirection fromString(String str) {
    switch (str.toLowerCase()) {
      case 'up':
        return ArrowDirection.up;
      case 'down':
        return ArrowDirection.down;
      case 'left':
        return ArrowDirection.left;
      case 'right':
        return ArrowDirection.right;
      default:
        throw ArgumentError('Invalid arrow direction: $str');
    }
  }
}
