import 'package:chameulin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('라이트모드 유튜브 광고 제목은 검은색으로 표시된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        themeMode: ThemeMode.light,
        home: Scaffold(bottomNavigationBar: BottomAdSlots()),
      ),
    );
    final title = tester.widget<Text>(find.text('조용한 밤의 위로'));
    expect(title.style?.color, Colors.black87);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('다크모드 유튜브 광고 제목은 흰색으로 표시된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        home: const Scaffold(bottomNavigationBar: BottomAdSlots()),
      ),
    );
    final title = tester.widget<Text>(find.text('조용한 밤의 위로'));
    expect(title.style?.color, Colors.black87);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('글쓰기 캔버스는 하단 버튼 위 남은 공간을 충분히 사용한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: WritingFlow(storyStyle: 'random')),
    );
    final canvas = tester.getSize(find.byKey(const ValueKey('writing-canvas')));
    expect(canvas.height, greaterThan(240));
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('writing-canvas')),
        matching: find.byType(ClipRRect),
      ),
      findsOneWidget,
    );
    final canvasBottom =
        tester.getBottomLeft(find.byKey(const ValueKey('writing-canvas'))).dy;
    final buttonTop = tester.getTopLeft(find.text('지우기')).dy;
    expect(buttonTop - canvasBottom, lessThan(30));
  });

  test('그리기 좌표는 캔버스 안에서만 허용된다', () {
    const size = Size(300, 400);

    expect(isPointInsideCanvas(const Offset(0, 0), size), isTrue);
    expect(isPointInsideCanvas(const Offset(300, 400), size), isTrue);
    expect(isPointInsideCanvas(const Offset(-1, 200), size), isFalse);
    expect(isPointInsideCanvas(const Offset(150, 401), size), isFalse);
  });

  testWidgets('감정 선택 카드는 2열 2행으로 배치된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WritingFlow(storyStyle: 'random')),
    );
    await tester.tap(find.text('다 적었습니다'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    final first = tester.getTopLeft(find.text('폭발 직전'));
    final second = tester.getTopLeft(find.text('많이 화남'));
    final third = tester.getTopLeft(find.text('답답함'));
    expect((first.dy - second.dy).abs(), lessThan(2));
    expect(third.dy, greaterThan(first.dy));
    expect(find.byKey(const ValueKey('mood-grid')), findsOneWidget);
  });
}
