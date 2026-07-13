import 'package:chameulin/main.dart';
import 'package:chameulin/plant_progress_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryPlantProgressStore implements PlantProgressStore {
  PlantProgress? progress;

  MemoryPlantProgressStore([this.progress]);

  @override
  Future<PlantProgress?> load() async => progress;

  @override
  Future<void> save(PlantProgress progress) async {
    this.progress = progress;
  }
}

void main() {
  test('요일마다 서로 다른 완성 꽃 이미지를 사용한다', () {
    final assets = [
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        weekdayPlantAsset(weekday),
    ];
    expect(assets.toSet().length, 7);
    expect(assets.first, contains('monday_daisy'));
    expect(assets.last, contains('sunday_hydrangea'));
  });

  testWidgets('다섯 번 터치할 때마다 꽃이 다음 단계로 자란다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = MemoryPlantProgressStore();

    await tester.pumpWidget(MaterialApp(
      home: HomePage(
        onStart: () {},
        plantStore: store,
        now: () => DateTime(2026, 7, 13, 10),
      ),
    ));
    await tester.pump();

    expect(find.byKey(const ValueKey('home-plant-stage-0')), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const ValueKey('home-plant-tap')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('home-plant-stage-0')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-plant-tap')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-plant-stage-1')), findsOneWidget);
    expect(store.progress?.tapCount, 5);

    for (var i = 0; i < 15; i++) {
      await tester.tap(find.byKey(const ValueKey('home-plant-tap')));
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-plant-stage-4')), findsOneWidget);
    expect(store.progress?.tapCount, 20);
  });

  testWidgets('요일이 바뀌면 새 꽃과 첫 단계로 시작한다', (tester) async {
    final store = MemoryPlantProgressStore(const PlantProgress(
      dateKey: '2026-07-12',
      tapCount: 20,
    ));

    await tester.pumpWidget(MaterialApp(
      home: HomePage(
        onStart: () {},
        plantStore: store,
        now: () => DateTime(2026, 7, 13, 9),
      ),
    ));
    await tester.pump();

    expect(find.byKey(const ValueKey('home-plant-stage-0')), findsOneWidget);
    final image = tester.widget<Image>(
      find.byKey(const ValueKey('home-plant-image')),
    );
    expect((image.image as AssetImage).assetName, contains('monday_daisy'));
  });
}
