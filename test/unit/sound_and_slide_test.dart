import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eklavyas_aim/features/gameplay/engine/arrow_model.dart';
import 'package:eklavyas_aim/features/gameplay/engine/level_repository.dart';
import 'package:eklavyas_aim/game/animation_config.dart';
import 'package:eklavyas_aim/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part A & B: Smooth Slide-Out Config & Sound Assets', () {
    test('Every sound asset exists in asset bundle and SoundService.init completes', () async {
      for (final type in SoundType.values) {
        final data = await rootBundle.load('assets/${type.assetPath}');
        expect(data.lengthInBytes, greaterThan(44), reason: '${type.assetPath} must be a valid WAV');
        expect(data.lengthInBytes, lessThan(102400), reason: '${type.assetPath} must be < 100 KB');
      }

      await SoundService().init(soundEnabled: true);
      expect(SoundService().isInitialized, isTrue);
    });

    test('Slide duration scales with distance and clamps between 350ms and 1100ms', () {
      final shortArrow = ArrowModel(
        id: 'short',
        points: const [GridPoint(0, 8), GridPoint(0, 9)], // 1 seg + 1 to edge
      );
      final longArrow = ArrowModel(
        id: 'long',
        points: List.generate(18, (i) => GridPoint(5, i)), // 17 segs + 13 to edge
      );

      final shortMs = AnimationConfig.computeSlideDurationMs(shortArrow, 10);
      final longMs = AnimationConfig.computeSlideDurationMs(longArrow, 30);

      expect(shortMs, equals(AnimationConfig.minSlideMs));
      expect(longMs, equals(AnimationConfig.maxSlideMs));
      expect(AnimationConfig.easeInThenConstant(0.0, 500), equals(0.0));
      expect(AnimationConfig.easeInThenConstant(1.0, 500), closeTo(1.0, 1e-6));
    });

    test('Levels 1 and 100 compute valid slide durations for free arrows', () {
      final repo = LevelRepository();
      for (final lvlNum in [1, 100]) {
        final level = repo.getLevel(lvlNum);
        final board = level.createBoard();
        final free = board.getClearArrows();
        expect(free, isNotEmpty);
        for (final arrow in free) {
          final ms = AnimationConfig.computeSlideDurationMs(arrow, level.boardSize);
          expect(ms, inInclusiveRange(AnimationConfig.minSlideMs, AnimationConfig.maxSlideMs));
        }
      }
    });
  });
}
