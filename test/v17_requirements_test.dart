import 'package:chameulin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('홈 앱 이름은 슬로건과 같은 크기의 녹색이다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF617A3F)),
        ),
        home: HomePage(onStart: () {}),
      ),
    );
    final appName = tester.widget<Text>(find.text('참을인'));
    final slogan = tester.widget<Text>(find.text('내 마음을 위해'));
    expect(appName.style?.fontSize, slogan.style?.fontSize);
    expect(appName.style?.fontSize, 34);
    expect(appName.style?.color, isNotNull);
  });

  testWidgets('설정에 카카오 연결 계정 상태가 표시된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          nickname: '따뜻한마음',
          linkedAccountLabel: '카카오 계정 연결됨',
          darkMode: false,
          effectSound: true,
          backgroundMusic: true,
          effectVolume: .2,
          backgroundVolume: .2,
          onDarkMode: (_) {},
          onEffectSound: (_) {},
          onBackgroundMusic: (_) {},
          onEffectVolume: (_) {},
          onBackgroundVolume: (_) {},
          onDeleteData: () async {},
          onDeleteAccount: () async {},
        ),
      ),
    );
    expect(find.text('카카오 계정 연결됨'), findsOneWidget);
    expect(find.text('아직 연결된 계정 없음'), findsNothing);
    expect(find.text('이야기 스타일'), findsNothing);
  });
}
