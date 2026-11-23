import 'arrow_model.dart';

/// Status of an attempted arrow move.
enum MoveStatus {
  success,
  blocked,
  invalid,
  completed,
}

/// The result returned when a player attempts to tap or move an arrow.
class MoveResult {
  final MoveStatus status;
  final ArrowModel? movedArrow;
  final ArrowModel? blockingArrow;
  final List<GridPoint> blockedRay;
  final int remainingArrows;
  final bool isGameWon;

  const MoveResult({
    required this.status,
    this.movedArrow,
    this.blockingArrow,
    this.blockedRay = const [],
    required this.remainingArrows,
    this.isGameWon = false,
  });

  bool get isSuccess => status == MoveStatus.success || status == MoveStatus.completed;
  bool get isBlocked => status == MoveStatus.blocked;
}
