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
  testWidgets('닉네임 입력 없이 홈 화면으로 바로 진입한다', (WidgetTester tester) async {
    await tester.pumpWidget(const ChameulinApp());
    expect(find.text('참을인'), findsOneWidget);
    expect(find.text('내 마음을 위해,\n참을인 하나.'), findsOneWidget);
    expect(find.textContaining('닉네임을 정해주세요'), findsNothing);
  });

  testWidgets('하단 광고 영역을 동일한 너비로 나눈다', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(bottomNavigationBar: BottomAdSlots()),
    ));

    final first =
        tester.getSize(find.byKey(const ValueKey('bottom-ad-slot-1')));
    final second =
        tester.getSize(find.byKey(const ValueKey('bottom-ad-slot-2')));
    expect(first.width, second.width);
    expect(tester.getSize(find.byType(BottomAdSlots)).height,
        BottomAdSlots.height);
    expect(find.text('광고'), findsNWidgets(2));
    expect(find.text('NAVER 검색'), findsOneWidget);
    expect(find.text('어슬렁 개발'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('조용한 밤의 위로'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
