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

  testWidgets('이메일 입력 중 취소해도 계정 연결 화면을 유지한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountLinkPage()));

    await tester.tap(find.text('이메일로 로그인'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '이메일'),
      'review@example.com',
    );
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(AlertDialog, '이메일로 로그인'), findsNothing);
    expect(find.text('공유하려면\n계정 연동이 필요합니다.'), findsOneWidget);
  });
}
