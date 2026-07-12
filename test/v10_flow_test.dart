import 'package:chameulin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('계정 연동 안내 화면에 세 가지 가입 선택지가 표시된다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountLinkPage()));

    expect(find.text('공유하려면\n계정 연동이 필요합니다.'), findsOneWidget);
    expect(find.text('카카오로 계속하기'), findsOneWidget);
    expect(find.text('Google로 계속하기'), findsOneWidget);
    expect(find.text('Apple로 계속하기'), findsOneWidget);
  });

  testWidgets('글쓰기 화면에는 페이지 숫자 표시가 없다', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: WritingFlow(storyStyle: 'random'),
    ));

    expect(find.text('1 / 5'), findsNothing);
    expect(find.text('참을 인을\n직접 써보세요.'), findsOneWidget);
  });
}
