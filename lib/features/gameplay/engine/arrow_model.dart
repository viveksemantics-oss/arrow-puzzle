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
/// Supports multi-segment winding arrows (polylines) with bends (L, U, Z, Spiral)
/// as well as single-cell arrows.
class ArrowModel {
  final String id;
  final int row; // Head row (for backward compatibility)
  final int col; // Head col (for backward compatibility)
  final ArrowDirection direction; // Head direction
  final List<GridPoint> points; // Ordered sequence of cells from tail to head
  final bool isActive;
  final double exitProgress; // 0.0 = on board, 1.0 = exited off screen
  final bool isShaking; // true when blocked tap animation triggers
  final bool isHighlighted; // true when hint is active

  const ArrowModel({
    required this.id,
    required this.row,
    required this.col,
    required this.direction,
    this.points = const [],
    this.isActive = true,
    this.exitProgress = 0.0,
    this.isShaking = false,
    this.isHighlighted = false,
  });

  /// All grid points occupied by this arrow (from tail to head).
  List<GridPoint> get allPoints {
    if (points.isNotEmpty) return points;
    return [GridPoint(row, col)];
  }

  /// Head position where the arrowhead points outward.
  GridPoint get head => allPoints.last;

  /// Tail position where the arrow originates.
  GridPoint get tail => allPoints.first;

  /// Head row coordinate.
  int get headRow => head.row;

  /// Head col coordinate.
  int get headCol => head.col;

  GridPoint get position => head;

  ArrowModel copyWith({
    String? id,
    int? row,
    int? col,
    ArrowDirection? direction,
    List<GridPoint>? points,
    bool? isActive,
    double? exitProgress,
    bool? isShaking,
    bool? isHighlighted,
  }) {
    return ArrowModel(
      id: id ?? this.id,
      row: row ?? this.row,
      col: col ?? this.col,
      direction: direction ?? this.direction,
      points: points ?? this.points,
      isActive: isActive ?? this.isActive,
      exitProgress: exitProgress ?? this.exitProgress,
      isShaking: isShaking ?? this.isShaking,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'row': row,
        'col': col,
        'direction': direction.name,
        'points': points.map((p) => p.toJson()).toList(),
        'isActive': isActive,
      };

  factory ArrowModel.fromJson(Map<String, dynamic> json) {
    final pointsJson = json['points'] as List<dynamic>?;
    final parsedPoints = pointsJson != null
        ? pointsJson
            .map((p) => GridPoint.fromJson(p as Map<String, dynamic>))
            .toList()
        : <GridPoint>[];

    final r = json['row'] as int;
    final c = json['col'] as int;

    return ArrowModel(
      id: json['id'] as String,
      row: r,
      col: c,
      direction: ArrowDirection.fromString(json['direction'] as String),
      points: parsedPoints.isNotEmpty ? parsedPoints : [GridPoint(r, c)],
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  String toString() =>
      'ArrowModel($id points:${allPoints.length} head:$head ${direction.symbol} active:$isActive)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArrowModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          row == other.row &&
          col == other.col &&
          direction == other.direction &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      row.hashCode ^
      col.hashCode ^
      direction.hashCode ^
      isActive.hashCode;
}
