import 'package:chameulin/main.dart';
import 'package:chameulin/plant_progress_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryPlantStore implements PlantProgressStore {
  PlantProgress? progress;
  var clearCount = 0;

  @override
  Future<PlantProgress?> load() async => progress;

  @override
  Future<void> save(PlantProgress progress) async {
    this.progress = progress;
  }

  @override
  Future<void> clear() async {
    clearCount++;
    progress = null;
  }
}

void main() {
  testWidgets('내 데이터 삭제 시 화분 저장값과 화면이 첫 단계로 초기화된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final plantStore = MemoryPlantStore();

    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          darkMode: false,
          effectSound: false,
          backgroundMusic: false,
          effectVolume: .2,
          backgroundVolume: .2,
          onDarkMode: (_) {},
          onEffectSound: (_) {},
          onBackgroundMusic: (_) {},
          onEffectVolume: (_) {},
          onBackgroundVolume: (_) {},
          plantStore: plantStore,
        ),
      ),
    );
    await tester.pump();

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const ValueKey('home-plant-tap')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('home-plant-stage-1')), findsOneWidget);
    expect(plantStore.progress?.tapCount, 5);

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    final deleteButton = find.widgetWithText(TextButton, '삭제');
    await tester.scrollUntilVisible(
      deleteButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '확인'));
    await tester.pumpAndSettle();

    expect(plantStore.clearCount, 1);
    expect(plantStore.progress, isNull);
    expect(find.textContaining('화분이 초기화되었습니다'), findsOneWidget);

    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-plant-stage-0')), findsOneWidget);
  });
}
