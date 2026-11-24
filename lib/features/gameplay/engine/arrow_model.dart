import 'arrow_direction.dart';

/// Represents a 2D coordinate on the puzzle grid.
class GridPoint {
  final int row;
  final int col;

  const GridPoint(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPoint &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => '($row, $col)';

  Map<String, dynamic> toJson() => {'row': row, 'col': col};

  factory GridPoint.fromJson(Map<String, dynamic> json) =>
      GridPoint(json['row'] as int, json['col'] as int);
}

/// Represents an arrow element situated on the puzzle board.
///
/// Every arrow is a 4-connected polyline with at least 2 cells.
/// The HEAD is the LAST cell of the path (points.last).
/// Its exit direction is derived strictly from the last step (points[n-2] -> points[n-1]).
class ArrowModel {
  final String id;
  final List<GridPoint> points; // Ordered sequence of cells from tail (points.first) to head (points.last)
  final bool isActive;
  final double exitProgress; // 0.0 = on board, 1.0 = exited off screen
  final bool isShaking; // true when blocked tap animation triggers
  final bool isHighlighted; // true when hint is active

  ArrowModel({
    required this.id,
    List<GridPoint>? points,
    int? row,
    int? col,
    ArrowDirection? direction,
    this.isActive = true,
    this.exitProgress = 0.0,
    this.isShaking = false,
    this.isHighlighted = false,
  }) : points = List<GridPoint>.unmodifiable(
          points ?? _makeStraightPoints(row ?? 0, col ?? 0, direction ?? ArrowDirection.up),
        ) {
    assert(this.points.length >= 2,
        'Arrow $id must have at least 2 cells, got ${this.points.length}');
    for (int i = 0; i < this.points.length - 1; i++) {
      final dr = (this.points[i + 1].row - this.points[i].row).abs();
      final dc = (this.points[i + 1].col - this.points[i].col).abs();
      assert(
        (dr == 1 && dc == 0) || (dr == 0 && dc == 1),
        'Consecutive cells must be 4-neighbors (differ by 1 in row OR col, never both): ${this.points[i]} -> ${this.points[i + 1]} in arrow $id',
      );
    }
  }

  static List<GridPoint> _makeStraightPoints(
      int row, int col, ArrowDirection direction) {
    return [
      GridPoint(row - direction.dy, col - direction.dx),
      GridPoint(row, col)
    ];
  }

  /// All grid points occupied by this arrow (from tail to head).
  List<GridPoint> get allPoints => points;

  /// Head position where the arrowhead points outward (index n-1).
  GridPoint get head => points.last;

  /// Tail position where the arrow originates (index 0).
  GridPoint get tail => points.first;

  /// Head row coordinate.
  int get headRow => head.row;

  /// Head col coordinate.
  int get headCol => head.col;

  int get row => head.row;
  int get col => head.col;

  GridPoint get position => head;

  /// Exit direction: derived strictly from the last step (from cell n-2 to cell n-1).
  /// Line and arrowhead can never disagree.
  ArrowDirection get direction {
    final prev = points[points.length - 2];
    final last = points.last;
    return ArrowDirection.fromDelta(last.row - prev.row, last.col - prev.col);
  }

  ArrowModel copyWith({
    String? id,
    List<GridPoint>? points,
    bool? isActive,
    double? exitProgress,
    bool? isShaking,
    bool? isHighlighted,
    // Backwards compatibility params for any callers:
    int? row,
    int? col,
    ArrowDirection? direction,
  }) {
    return ArrowModel(
      id: id ?? this.id,
      points: points ?? this.points,
      isActive: isActive ?? this.isActive,
      exitProgress: exitProgress ?? this.exitProgress,
      isShaking: isShaking ?? this.isShaking,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'points': points.map((p) => p.toJson()).toList(),
        'isActive': isActive,
      };

  factory ArrowModel.fromJson(Map<String, dynamic> json) {
    final pointsJson = json['points'] as List<dynamic>?;
    List<GridPoint> parsedPoints;
    if (pointsJson != null && pointsJson.isNotEmpty) {
      parsedPoints = pointsJson
          .map((p) => GridPoint.fromJson(p as Map<String, dynamic>))
          .toList();
    } else {
      final r = json['row'] as int? ?? 0;
      final c = json['col'] as int? ?? 0;
      final dirStr = json['direction'] as String? ?? 'up';
      final dir = ArrowDirection.fromString(dirStr);
      parsedPoints = [GridPoint(r - dir.dy, c - dir.dx), GridPoint(r, c)];
    }

    return ArrowModel(
      id: json['id'] as String,
      points: parsedPoints,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  String toString() =>
      'ArrowModel($id len:${points.length} tail:$tail head:$head ${direction.symbol} active:$isActive)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArrowModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isActive == other.isActive &&
          _listEquals(points, other.points);

  static bool _listEquals(List<GridPoint> a, List<GridPoint> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => id.hashCode ^ isActive.hashCode ^ points.length.hashCode;
}
