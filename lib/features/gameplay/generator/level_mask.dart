import 'dart:math' as math;

/// Supported silhouette shapes for puzzle boards.
enum SilhouetteShape {
  square,
  trophy,
  anchor,
  dog,
  butterfly,
  knight,
  heart,
  star,
  diamond,
  circle,
  tree,
  house;

  String get displayName {
    switch (this) {
      case SilhouetteShape.square:
        return 'Square Maze';
      case SilhouetteShape.trophy:
        return 'Trophy Cup';
      case SilhouetteShape.anchor:
        return 'Anchor';
      case SilhouetteShape.dog:
        return 'Puppy';
      case SilhouetteShape.butterfly:
        return 'Butterfly';
      case SilhouetteShape.knight:
        return 'Knight';
      case SilhouetteShape.heart:
        return 'Heart';
      case SilhouetteShape.star:
        return 'Star';
      case SilhouetteShape.diamond:
        return 'Diamond';
      case SilhouetteShape.circle:
        return 'Circle';
      case SilhouetteShape.tree:
        return 'Pine Tree';
      case SilhouetteShape.house:
        return 'House';
    }
  }

  /// Picks a silhouette shape deterministically based on level number.
  static SilhouetteShape forLevel(int levelNumber) {
    if (levelNumber <= 10) {
      return SilhouetteShape.square;
    }
    // Specific iconic levels matching game design references
    if (levelNumber == 11 || levelNumber == 24) return SilhouetteShape.trophy;
    if (levelNumber == 27) return SilhouetteShape.anchor;
    if (levelNumber == 40) return SilhouetteShape.dog;
    if (levelNumber == 99) return SilhouetteShape.butterfly;
    if (levelNumber == 199 || levelNumber == 200) return SilhouetteShape.square;

    // Cycle through rich silhouettes deterministically
    const shapes = [
      SilhouetteShape.trophy,
      SilhouetteShape.anchor,
      SilhouetteShape.knight,
      SilhouetteShape.heart,
      SilhouetteShape.dog,
      SilhouetteShape.butterfly,
      SilhouetteShape.star,
      SilhouetteShape.diamond,
      SilhouetteShape.tree,
      SilhouetteShape.house,
      SilhouetteShape.circle,
      SilhouetteShape.square,
    ];
    return shapes[(levelNumber * 7) % shapes.length];
  }
}

/// Generates rasterized 2D boolean masks for board shapes.
class LevelMask {
  /// Rasterizes the requested shape into an [size] x [size] boolean grid.
  /// True = playable cell, False = background / empty void.
  static List<List<bool>> generate(SilhouetteShape shape, int size) {
    final mask = List.generate(size, (_) => List.filled(size, false));

    for (int r = 0; r < size; r++) {
      final v = (r + 0.5) / size; // Normalized row [0..1]
      for (int c = 0; c < size; c++) {
        final u = (c + 0.5) / size; // Normalized col [0..1]
        mask[r][c] = _isPointInside(shape, u, v);
      }
    }

    // Safety fallback: if shape rasterization yielded too few cells (< 30%), fill square center
    int cellCount = 0;
    for (final row in mask) {
      for (final cell in row) {
        if (cell) cellCount++;
      }
    }

    if (cellCount < size * size * 0.3) {
      final pad = (size * 0.1).round().clamp(1, size ~/ 3);
      for (int r = pad; r < size - pad; r++) {
        for (int c = pad; c < size - pad; c++) {
          mask[r][c] = true;
        }
      }
    }

    return mask;
  }

  static bool _isPointInside(SilhouetteShape shape, double u, double v) {
    switch (shape) {
      case SilhouetteShape.square:
        return u >= 0.05 && u <= 0.95 && v >= 0.05 && v <= 0.95;

      case SilhouetteShape.circle:
        final du = u - 0.5;
        final dv = v - 0.5;
        return (du * du + dv * dv) <= (0.44 * 0.44);

      case SilhouetteShape.diamond:
        return (u - 0.5).abs() + (v - 0.5).abs() <= 0.44;

      case SilhouetteShape.heart:
        // Mathematical cardioid/heart equation
        final x = (u - 0.5) * 2.3;
        final y = -(v - 0.52) * 2.3;
        final f = (x * x + y * y - 1);
        return (f * f * f - x * x * y * y * y) <= 0.0;

      case SilhouetteShape.trophy:
        // Trophy Cup: Rim, Bowl, Handles, Stem, Base Pedestal
        // Pedestal base
        if (v >= 0.82 && v <= 0.93 && u >= 0.22 && u <= 0.78) return true;
        // Stem
        if (v >= 0.60 && v < 0.82 && u >= 0.42 && u <= 0.58) return true;
        // Cup Bowl
        if (v >= 0.12 && v < 0.60) {
          final bowlWidth = 0.22 + (0.60 - v) * 0.5;
          if ((u - 0.5).abs() <= bowlWidth) return true;
          // Handles on left & right
          if (v >= 0.22 && v <= 0.48) {
            if ((u >= 0.14 && u <= 0.26) || (u >= 0.74 && u <= 0.86)) return true;
          }
        }
        return false;

      case SilhouetteShape.anchor:
        // Anchor: Crown flukes, central shank, top crossbar & ring
        // Ring at top
        final du = u - 0.5;
        final dv = v - 0.14;
        if ((du * du + dv * dv) <= (0.09 * 0.09)) return true;
        // Top crossbar
        if (v >= 0.25 && v <= 0.32 && u >= 0.18 && u <= 0.82) return true;
        // Central shank
        if (v >= 0.16 && v <= 0.86 && (u - 0.5).abs() <= 0.08) return true;
        // Curved bottom flukes
        if (v >= 0.60 && v <= 0.88) {
          final arcY = 0.65 + math.pow((u - 0.5) / 0.38, 2) * 0.22;
          if ((v - arcY).abs() <= 0.09 && (u - 0.5).abs() <= 0.42) return true;
        }
        return false;

      case SilhouetteShape.knight:
        // Chess Knight Piece
        // Base
        if (v >= 0.82 && v <= 0.94 && u >= 0.20 && u <= 0.80) return true;
        // Body / Chest
        if (v >= 0.48 && v < 0.82 && u >= 0.32 && u <= 0.76) return true;
        // Snout pointing left
        if (v >= 0.35 && v <= 0.52 && u >= 0.16 && u <= 0.54) return true;
        // Head, Ear, and Mane
        if (v >= 0.14 && v < 0.48 && u >= 0.32 && u <= 0.68) return true;
        // Ear tip
        if (v >= 0.08 && v <= 0.20 && u >= 0.38 && u <= 0.52) return true;
        return false;

      case SilhouetteShape.butterfly:
        // Central body
        if (v >= 0.20 && v <= 0.86 && (u - 0.5).abs() <= 0.06) return true;
        // Upper wings
        final dx1 = (u - 0.5).abs();
        final dy1 = v - 0.38;
        if (dx1 <= 0.44 && (dx1 * dx1 / (0.42 * 0.42) + dy1 * dy1 / (0.24 * 0.24)) <= 1.0) {
          return true;
        }
        // Lower wings
        final dy2 = v - 0.66;
        if (dx1 <= 0.36 && (dx1 * dx1 / (0.34 * 0.34) + dy2 * dy2 / (0.20 * 0.20)) <= 1.0) {
          return true;
        }
        return false;

      case SilhouetteShape.dog:
        // Head & Muzzle
        if (v >= 0.18 && v <= 0.42 && u >= 0.58 && u <= 0.88) return true;
        // Ear
        if (v >= 0.10 && v <= 0.28 && u >= 0.54 && u <= 0.68) return true;
        // Body
        if (v >= 0.38 && v <= 0.66 && u >= 0.22 && u <= 0.78) return true;
        // Forelegs
        if (v >= 0.66 && v <= 0.92 && u >= 0.62 && u <= 0.76) return true;
        // Hindlegs
        if (v >= 0.66 && v <= 0.92 && u >= 0.24 && u <= 0.38) return true;
        // Tail
        if (v >= 0.26 && v <= 0.46 && u >= 0.12 && u <= 0.24) return true;
        return false;

      case SilhouetteShape.star:
        // 5-pointed star
        final cx = 0.5;
        final cy = 0.52;
        final dx = u - cx;
        final dy = v - cy;
        final r = math.sqrt(dx * dx + dy * dy);
        final angle = math.atan2(dy, dx);
        final starRadius = 0.28 + 0.16 * math.cos(5 * angle);
        return r <= starRadius;

      case SilhouetteShape.tree:
        // Pine Tree: 3 triangular tiers + trunk
        if (v >= 0.76 && v <= 0.94 && (u - 0.5).abs() <= 0.08) return true; // Trunk
        if (v >= 0.10 && v <= 0.35 && (u - 0.5).abs() <= (v - 0.10) * 1.0) return true; // Top
        if (v >= 0.30 && v <= 0.55 && (u - 0.5).abs() <= (v - 0.22) * 1.1) return true; // Mid
        if (v >= 0.50 && v <= 0.78 && (u - 0.5).abs() <= (v - 0.36) * 1.2) return true; // Bottom
        return false;

      case SilhouetteShape.house:
        // Roof
        if (v >= 0.15 && v <= 0.48 && (u - 0.5).abs() <= (v - 0.15) * 1.1) return true;
        // House base
        if (v >= 0.45 && v <= 0.92 && u >= 0.18 && u <= 0.82) return true;
        return false;
    }
  }
}
