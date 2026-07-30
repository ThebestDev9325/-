import 'package:chameulin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('2,001자 비공개 기록은 잘리지 않고 공유만 차단된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WritingFlow(storyStyle: 'random')),
    );
    await tester.tap(find.text('다 적었습니다'));
    await tester.pumpAndSettle();
    final longText = '가' * 2001;
    final textField = find.byType(TextField);
    await tester.enterText(textField, longText);
    expect(tester.widget<TextField>(textField).controller?.text, longText);

    final storyNextButton = find.widgetWithText(FilledButton, '다음');
    tester.widget<FilledButton>(storyNextButton).onPressed?.call();
    await tester.pumpAndSettle();
    await tester.tap(find.text('많이 화남'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    final recommendationNextButton = find.widgetWithText(FilledButton, '다음');
    tester.widget<FilledButton>(recommendationNextButton).onPressed?.call();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    final shareButton = find.widgetWithText(FilledButton, '공유하기');
    tester.widget<FilledButton>(shareButton).onPressed?.call();
    await tester.pump();

    expect(find.text('공유 글은 2,000자 이내로 작성해주세요.'), findsOneWidget);
  });
}
