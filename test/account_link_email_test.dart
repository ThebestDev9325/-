import 'package:chameulin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('계정 연결 페이지에 이메일 로그인 진입점이 함께 표시된다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountLinkPage()));

    expect(find.text('카카오로 계속하기'), findsOneWidget);
    expect(find.text('이메일로 로그인'), findsOneWidget);
  });

  testWidgets('이메일 로그인을 누르면 이메일과 비밀번호 입력 창이 열린다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountLinkPage()));

    await tester.tap(find.text('이메일로 로그인'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AlertDialog, '이메일로 로그인'), findsOneWidget);
    expect(find.text('이메일'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
  });
}
