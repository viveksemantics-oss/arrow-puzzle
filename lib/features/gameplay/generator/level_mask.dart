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
  /// Early levels (1-25) are full square mazes as specified; later levels are silhouettes.
  static SilhouetteShape forLevel(int levelNumber) {
    if (levelNumber <= 25) {
      return SilhouetteShape.square;
    }
    // Specific iconic levels matching game design references
    if (levelNumber == 27) return SilhouetteShape.anchor;
    if (levelNumber == 40) return SilhouetteShape.trophy;
    if (levelNumber == 99 || levelNumber == 100) return SilhouetteShape.dog;
    if (levelNumber == 199 || levelNumber == 200) return SilhouetteShape.square;
    if (levelNumber == 300) return SilhouetteShape.trophy;

    // For early levels (26-40), use compact silhouettes without thin 1-cell spikes
    if (levelNumber <= 40) {
      const easyShapes = [
        SilhouetteShape.trophy,
        SilhouetteShape.anchor,
        SilhouetteShape.knight,
        SilhouetteShape.heart,
        SilhouetteShape.house,
        SilhouetteShape.circle,
        SilhouetteShape.square,
      ];
      return easyShapes[(levelNumber * 7) % easyShapes.length];
    }

    // Cycle through rich silhouettes deterministically for Medium, Hard, Expert
    const shapes = [
      SilhouetteShape.trophy,
      SilhouetteShape.anchor,
      SilhouetteShape.knight,
      SilhouetteShape.heart,
      SilhouetteShape.dog,
      SilhouetteShape.butterfly,
      SilhouetteShape.star,
      SilhouetteShape.tree,
      SilhouetteShape.house,
      SilhouetteShape.diamond,
      SilhouetteShape.circle,
      SilhouetteShape.square,
    ];
    return shapes[(levelNumber * 7) % shapes.length];
  }
}

/// Generates rasterized 2D boolean masks for board shapes.
class LevelMask {
  /// Rasterizes the requested shape into an [size] x [size] boolean grid,
  /// normalized so that the silhouette spans at least 90% of the board area.
  /// True = playable cell, False = background / empty void.
  static List<List<bool>> generate(SilhouetteShape shape, int size) {
    if (shape == SilhouetteShape.square) {
      // Full square with 1 cell border padding
      final pad = 1;
      final mask = List.generate(size, (_) => List.filled(size, false));
      for (int r = pad; r < size - pad; r++) {
        for (int c = pad; c < size - pad; c++) {
          mask[r][c] = true;
        }
      }
      return mask;
    }

    // 1. Initial high-resolution rasterization to find raw bounds
    const sampleRes = 120;
    int minSampleR = sampleRes, maxSampleR = 0;
    int minSampleC = sampleRes, maxSampleC = 0;

    for (int r = 0; r < sampleRes; r++) {
      final v = (r + 0.5) / sampleRes;
      for (int c = 0; c < sampleRes; c++) {
        final u = (c + 0.5) / sampleRes;
        if (_isRawPointInside(shape, u, v)) {
          if (r < minSampleR) minSampleR = r;
          if (r > maxSampleR) maxSampleR = r;
          if (c < minSampleC) minSampleC = c;
          if (c > maxSampleC) maxSampleC = c;
        }
      }
    }

    if (minSampleR >= maxSampleR || minSampleC >= maxSampleC) {
      // Fallback to square
      return generate(SilhouetteShape.square, size);
    }

    final rawMinU = minSampleC / sampleRes;
    final rawMaxU = (maxSampleC + 1) / sampleRes;
    final rawMinV = minSampleR / sampleRes;
    final rawMaxV = (maxSampleR + 1) / sampleRes;

    final rawW = rawMaxU - rawMinU;
    final rawH = rawMaxV - rawMinV;

    // 2. Rasterize into target [size] x [size], scaling to fill >= 90% of width & height
    final targetSpan = 0.92; // 92% of board area
    final margin = (1.0 - targetSpan) / 2.0; // 0.04 margin

    final mask = List.generate(size, (_) => List.filled(size, false));

    for (int r = 0; r < size; r++) {
      final vGrid = (r + 0.5) / size;
      // Map normalized grid v [margin .. 1-margin] to raw shape v [rawMinV .. rawMaxV]
      final vShape = rawMinV + ((vGrid - margin) / targetSpan) * rawH;

      for (int c = 0; c < size; c++) {
        final uGrid = (c + 0.5) / size;
        final uShape = rawMinU + ((uGrid - margin) / targetSpan) * rawW;

        if (uShape >= 0.0 && uShape <= 1.0 && vShape >= 0.0 && vShape <= 1.0) {
          mask[r][c] = _isRawPointInside(shape, uShape, vShape);
        }
      }
    }

    // Ensure solid silhouette density: if sparse, dilate to thicken corridors
    int cellCount = 0;
    for (final row in mask) {
      for (final cell in row) {
        if (cell) cellCount++;
      }
    }

    if (cellCount < size * size * 0.45) {
      final dilated = _dilate(mask, size);
      return dilated;
    }

    return mask;
  }

  static List<List<bool>> _dilate(List<List<bool>> mask, int size) {
    final result = List.generate(size, (r) => List<bool>.from(mask[r]));
    for (int r = 1; r < size - 1; r++) {
      for (int c = 1; c < size - 1; c++) {
        if (mask[r][c]) {
          result[r - 1][c] = true;
          result[r + 1][c] = true;
          result[r][c - 1] = true;
          result[r][c + 1] = true;
        }
      }
    }
    return result;
  }

  static bool _isRawPointInside(SilhouetteShape shape, double u, double v) {
    switch (shape) {
      case SilhouetteShape.square:
        return u >= 0.04 && u <= 0.96 && v >= 0.04 && v <= 0.96;

      case SilhouetteShape.circle:
        final du = u - 0.5;
        final dv = v - 0.5;
        return (du * du + dv * dv) <= (0.45 * 0.45);

      case SilhouetteShape.diamond:
        return (u - 0.5).abs() + (v - 0.5).abs() <= 0.45;

      case SilhouetteShape.heart:
        final x = (u - 0.5) * 1.85;
        final y = -(v - 0.50) * 1.85;
        final f = (x * x + y * y - 1);
        return (f * f * f - x * x * y * y * y) <= 0.0;

      case SilhouetteShape.trophy:
        // Base pedestal
        if (v >= 0.82 && v <= 0.94 && u >= 0.22 && u <= 0.78) return true;
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
        final du = u - 0.5;
        final dv = v - 0.14;
        if ((du * du + dv * dv) <= (0.09 * 0.09)) return true; // Top ring
        if (v >= 0.25 && v <= 0.32 && u >= 0.18 && u <= 0.82) return true; // Crossbar
        if (v >= 0.16 && v <= 0.86 && (u - 0.5).abs() <= 0.08) return true; // Shank
        if (v >= 0.60 && v <= 0.88) {
          final arcY = 0.65 + math.pow((u - 0.5) / 0.38, 2) * 0.22;
          if ((v - arcY).abs() <= 0.09 && (u - 0.5).abs() <= 0.42) return true; // Flukes
        }
        return false;

      case SilhouetteShape.knight:
        if (v >= 0.82 && v <= 0.94 && u >= 0.20 && u <= 0.80) return true; // Base
        if (v >= 0.48 && v < 0.82 && u >= 0.32 && u <= 0.76) return true; // Body
        if (v >= 0.35 && v <= 0.52 && u >= 0.16 && u <= 0.54) return true; // Snout
        if (v >= 0.14 && v < 0.48 && u >= 0.32 && u <= 0.68) return true; // Head
        if (v >= 0.08 && v <= 0.20 && u >= 0.38 && u <= 0.52) return true; // Ear
        return false;

      case SilhouetteShape.butterfly:
        if (v >= 0.20 && v <= 0.86 && (u - 0.5).abs() <= 0.06) return true; // Body
        final dx1 = (u - 0.5).abs();
        final dy1 = v - 0.38;
        if (dx1 <= 0.44 && (dx1 * dx1 / (0.42 * 0.42) + dy1 * dy1 / (0.24 * 0.24)) <= 1.0) {
          return true; // Upper wings
        }
        final dy2 = v - 0.66;
        if (dx1 <= 0.36 && (dx1 * dx1 / (0.34 * 0.34) + dy2 * dy2 / (0.20 * 0.20)) <= 1.0) {
          return true; // Lower wings
        }
        return false;

      case SilhouetteShape.dog:
        if (v >= 0.18 && v <= 0.42 && u >= 0.58 && u <= 0.88) return true; // Head
        if (v >= 0.10 && v <= 0.28 && u >= 0.54 && u <= 0.68) return true; // Ear
        if (v >= 0.38 && v <= 0.66 && u >= 0.22 && u <= 0.78) return true; // Body
        if (v >= 0.66 && v <= 0.92 && u >= 0.62 && u <= 0.76) return true; // Forelegs
        if (v >= 0.66 && v <= 0.92 && u >= 0.24 && u <= 0.38) return true; // Hindlegs
        if (v >= 0.26 && v <= 0.46 && u >= 0.12 && u <= 0.24) return true; // Tail
        return false;

      case SilhouetteShape.star:
        final dx = u - 0.5;
        final dy = v - 0.52;
        final r = math.sqrt(dx * dx + dy * dy);
        final angle = math.atan2(dy, dx);
        final starRadius = 0.28 + 0.16 * math.cos(5 * angle);
        return r <= starRadius;

      case SilhouetteShape.tree:
        if (v >= 0.74 && v <= 0.94 && (u - 0.5).abs() <= 0.15) return true; // Trunk
        if (v >= 0.10 && v <= 0.38 && (u - 0.5).abs() <= 0.12 + (v - 0.10) * 0.9) return true;
        if (v >= 0.32 && v <= 0.60 && (u - 0.5).abs() <= 0.18 + (v - 0.25) * 1.0) return true;
        if (v >= 0.52 && v <= 0.78 && (u - 0.5).abs() <= 0.24 + (v - 0.40) * 1.1) return true;
        return false;

      case SilhouetteShape.house:
        if (v >= 0.15 && v <= 0.48 && (u - 0.5).abs() <= (v - 0.15) * 1.1) return true; // Roof
        if (v >= 0.45 && v <= 0.92 && u >= 0.18 && u <= 0.82) return true; // Base
        return false;
    }
  }
}
