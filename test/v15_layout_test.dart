import 'package:chameulin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('글쓰기 제목은 한 줄이며 캔버스 바로 위에 배치된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: WritingFlow(storyStyle: 'random')),
    );

    expect(find.text('참을인을 직접 써보세요.'), findsOneWidget);
    expect(find.text('참을 인을\n직접 써보세요.'), findsNothing);
    final headerBottom = tester
        .getBottomLeft(find.byKey(const ValueKey('writing-header')))
        .dy;
    final canvasTop = tester
        .getTopLeft(find.byKey(const ValueKey('writing-canvas')))
        .dy;
    expect(canvasTop - headerBottom, lessThanOrEqualTo(16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('긍정 버튼은 이야기 스크롤과 무관하게 하단에 고정된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: PositivePage()));

    final button = find.byKey(const ValueKey('positive-next-button'));
    final before = tester.getRect(button);
    await tester.drag(
      find.byKey(const ValueKey('positive-story-scroll')),
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
    final after = tester.getRect(button);
    expect(after.top, before.top);
    expect(after.bottom, before.bottom);
    expect(before.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });
}
