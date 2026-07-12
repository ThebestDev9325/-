import 'package:chameulin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('닉네임 서버 오류가 나도 오프라인으로 앱을 시작할 수 있다', (tester) async {
    String? completedNickname;
    await tester.pumpWidget(MaterialApp(
      home: SplashNicknameFlow(
        onDone: (nickname) => completedNickname = nickname,
        claimNickname: (_) async => throw Exception('offline'),
      ),
    ));

    await tester.pump(const Duration(seconds: 3));
    await tester.enterText(find.byType(TextField), '따뜻한마음');
    await tester.tap(find.text('시작하기'));
    await tester.pump();

    expect(find.text('닉네임 서버에 연결할 수 없습니다.'), findsOneWidget);
    expect(find.text('오프라인으로 시작하기'), findsOneWidget);

    await tester.tap(find.text('오프라인으로 시작하기'));
    await tester.pump(const Duration(milliseconds: 2500));
    expect(completedNickname, '따뜻한마음');
  });
}
