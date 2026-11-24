import 'arrow_model.dart';

/// Represents the logical square grid of the puzzle.
///
/// Supports multi-segment winding arrows occupying multiple cells.
class PuzzleBoard {
  final int size; // e.g. 4, 5, 6, 7, 8, 9, 10, 12
  final Map<String, ArrowModel> arrows; // Keyed by arrow ID
  final Map<GridPoint, String> _gridLookup; // Quick position -> arrowId lookup

  PuzzleBoard({
    required this.size,
    Map<String, ArrowModel>? arrows,
  })  : arrows = arrows ?? {},
        _gridLookup = {} {
    _rebuildLookup();
  }

  void _rebuildLookup() {
    _gridLookup.clear();
    for (final arrow in arrows.values) {
      if (arrow.isActive) {
        for (final pt in arrow.allPoints) {
          _gridLookup[pt] = arrow.id;
        }
      }
    }
  }

  /// Factory from a list of arrows.
  factory PuzzleBoard.fromList({
    required int size,
    required List<ArrowModel> arrowsList,
  }) {
    final map = <String, ArrowModel>{};
    for (final a in arrowsList) {
      map[a.id] = a;
    }
    return PuzzleBoard(size: size, arrows: map);
  }

  /// Total count of active arrows remaining on the board.
  int get activeArrowCount => arrows.values.where((a) => a.isActive).length;

  /// Returns true if all arrows have successfully exited.
  bool get isCleared => activeArrowCount == 0;

  /// Returns the arrow occupying the given coordinate, or null if cell is empty / inactive.
  ArrowModel? getActiveArrowAt(int row, int col) {
    if (row < 0 || row >= size || col < 0 || col >= size) return null;
    final id = _gridLookup[GridPoint(row, col)];
    if (id == null) return null;
    final arrow = arrows[id];
    return (arrow != null && arrow.isActive) ? arrow : null;
  }

  /// Returns the arrow with the given ID.
  ArrowModel? getArrowById(String id) => arrows[id];

  /// Checks if an arrow has an unobstructed exit path to the board's edge.
  ///
  /// An arrow exits from its HEAD along its direction.
  bool isPathClear(ArrowModel arrow) {
    if (!arrow.isActive) return false;

    final head = arrow.head;
    int r = head.row + arrow.direction.dy;
    int c = head.col + arrow.direction.dx;

    while (r >= 0 && r < size && c >= 0 && c < size) {
      final blockerId = _gridLookup[GridPoint(r, c)];
      if (blockerId != null && blockerId != arrow.id) {
        return false;
      }
      r += arrow.direction.dy;
      c += arrow.direction.dx;
    }

    return true;
  }

  /// Finds the first active arrow blocking this arrow's exit path, or null if clear.
  ArrowModel? getFirstBlockingArrow(ArrowModel arrow) {
    if (!arrow.isActive) return null;

    final head = arrow.head;
    int r = head.row + arrow.direction.dy;
    int c = head.col + arrow.direction.dx;

    while (r >= 0 && r < size && c >= 0 && c < size) {
      final blockerId = _gridLookup[GridPoint(r, c)];
      if (blockerId != null && blockerId != arrow.id) {
        return arrows[blockerId];
      }
      r += arrow.direction.dy;
      c += arrow.direction.dx;
    }

    return null;
  }

  /// Returns the ray of grid coordinates from the arrow's head to its blocker (or board edge).
  List<GridPoint> getBlockedRay(ArrowModel arrow) {
    final ray = <GridPoint>[];
    final head = arrow.head;
    int r = head.row + arrow.direction.dy;
    int c = head.col + arrow.direction.dx;

    while (r >= 0 && r < size && c >= 0 && c < size) {
      final pt = GridPoint(r, c);
      ray.add(pt);
      final blockerId = _gridLookup[pt];
      if (blockerId != null && blockerId != arrow.id) {
        break; // Stop at blocker
      }
      r += arrow.direction.dy;
      c += arrow.direction.dx;
    }

    return ray;
  }

  /// Returns the full straight exit ray of cells starting right in front of the head to board edge.
  List<GridPoint> getExitRay(ArrowModel arrow) {
    final ray = <GridPoint>[];
    final head = arrow.head;
    int r = head.row + arrow.direction.dy;
    int c = head.col + arrow.direction.dx;

    while (r >= 0 && r < size && c >= 0 && c < size) {
      ray.add(GridPoint(r, c));
      r += arrow.direction.dy;
      c += arrow.direction.dx;
    }

    return ray;
  }

  /// Returns all currently active arrows whose paths are completely clear.
  List<ArrowModel> getClearArrows() {
    return arrows.values
        .where((a) => a.isActive && isPathClear(a))
        .toList(growable: false);
  }

  /// Creates a deep clone of this board.
  PuzzleBoard clone() {
    final clonedMap = <String, ArrowModel>{};
    for (final entry in arrows.entries) {
      clonedMap[entry.key] = entry.value.copyWith();
    }
    return PuzzleBoard(size: size, arrows: clonedMap);
  }

  /// Sets an arrow's active state and updates lookup for all occupied cells.
  void setArrowActive(String id, bool active) {
    final arrow = arrows[id];
    if (arrow != null) {
      arrows[id] = arrow.copyWith(isActive: active);
      for (final pt in arrow.allPoints) {
        if (active) {
          _gridLookup[pt] = id;
        } else {
          _gridLookup.remove(pt);
        }
      }
    }
  }

  /// Sets an arrow's shaking state.
  void setArrowShaking(String id, bool shaking) {
    final arrow = arrows[id];
    if (arrow != null) {
      arrows[id] = arrow.copyWith(isShaking: shaking);
    }
  }

  /// Sets an arrow's highlighted state (for hints).
  void setArrowHighlighted(String id, bool highlighted) {
    final arrow = arrows[id];
    if (arrow != null) {
      arrows[id] = arrow.copyWith(isHighlighted: highlighted);
    }
  }

  /// Clears all highlight flags.
  void clearAllHighlights() {
    for (final entry in arrows.entries) {
      if (entry.value.isHighlighted) {
        arrows[entry.key] = entry.value.copyWith(isHighlighted: false);
      }
    }
  }

  /// Clears all shaking flags.
  void clearAllShaking() {
    for (final entry in arrows.entries) {
      if (entry.value.isShaking) {
        arrows[entry.key] = entry.value.copyWith(isShaking: false);
      }
    }
  }
}
