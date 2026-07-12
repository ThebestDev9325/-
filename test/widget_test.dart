// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chameulin/main.dart';

void main() {
  testWidgets('참을인 앱이 시작 화면을 표시한다', (WidgetTester tester) async {
    await tester.pumpWidget(const ChameulinApp());
    expect(find.text('참을인'), findsOneWidget);
    expect(find.text('화난 마음에, 이야기 하나.'), findsOneWidget);
  });

  testWidgets('하단 광고 영역을 동일한 너비로 나눈다', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(bottomNavigationBar: BottomAdSlots()),
    ));

    final first = tester.getSize(find.byKey(const ValueKey('bottom-ad-slot-1')));
    final second = tester.getSize(find.byKey(const ValueKey('bottom-ad-slot-2')));
    expect(first.width, second.width);
    expect(tester.getSize(find.byType(BottomAdSlots)).height, BottomAdSlots.height);
    expect(find.text('광고'), findsNWidgets(2));
    expect(find.text('NAVER 검색'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('NAVER 뉴스'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
