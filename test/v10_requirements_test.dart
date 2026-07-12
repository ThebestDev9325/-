import 'dart:io';

import 'package:chameulin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('홈의 새 문구가 표시되고 이전 문구는 제거됐다', (tester) async {
    await tester.pumpWidget(MaterialApp(home: HomePage(onStart: () {})));

    expect(find.text('내 마음을 위해,\n참을인 하나.'), findsOneWidget);
    expect(find.textContaining('후회할 말 전에'), findsNothing);
  });

  testWidgets('세 번째 작성에서만 이스터에그가 나타난다', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: WritingFlow(storyStyle: 'random', todayWritingNumber: 3),
    ));

    await tester.tap(find.text('다 적었습니다'));
    await tester.pumpAndSettle();
    expect(find.text('오늘 세 번째 참을인을 쓰셨네요.'), findsOneWidget);
    expect(find.textContaining('오늘 주변이 조금 시끄러웠나 봅니다'), findsOneWidget);

    await tester.tap(find.text('마음 돌보기'));
    await tester.pumpAndSettle();
    expect(find.text('무슨 일이 있었나요?'), findsOneWidget);
  });

  testWidgets('네 번째 작성에는 세 번째 이스터에그가 반복되지 않는다', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: WritingFlow(storyStyle: 'random', todayWritingNumber: 4),
    ));

    await tester.tap(find.text('다 적었습니다'));
    await tester.pumpAndSettle();
    expect(find.text('오늘 세 번째 참을인을 쓰셨네요.'), findsNothing);
    expect(find.text('무슨 일이 있었나요?'), findsOneWidget);
  });

  testWidgets('획순 보기는 고정 영역에서 다음 이미지로 전환된다', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: WritingFlow(storyStyle: 'random'),
    ));

    await tester.tap(find.text('획순 보기'));
    await tester.pump();
    expect(find.byKey(const ValueKey(0)), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const ValueKey(1)), findsOneWidget);
    expect(find.byType(AnimatedSwitcher), findsWidgets);

    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
  });

  testWidgets('공감 탭은 샘플 글 없이 빈 상태를 표시한다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: EmpathyPage(
        posts: const [],
        currentUserId: 'test-user',
        onReact: (_, __) {},
        onReport: (_) {},
      ),
    ));

    expect(find.textContaining('아직 공유된 사연이 없습니다'), findsOneWidget);
    expect(find.textContaining('회의에서 한마디'), findsNothing);
    expect(find.textContaining('무리한 요구'), findsNothing);
    expect(find.text('오늘의 Best 사연'), findsNothing);
  });

  testWidgets('긍정 카드에는 긍정 칩이 표시되지 않는다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PositivePage()));

    expect(find.text('오늘의 긍정'), findsOneWidget);
    expect(find.byType(Chip), findsNothing);
  });

  test('Android 런처 아이콘의 모든 밀도 파일이 교체돼 있다', () {
    const densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];
    for (final density in densities) {
      final icon = File(
        'android/app/src/main/res/mipmap-$density/ic_launcher.png',
      );
      expect(icon.existsSync(), isTrue, reason: '$density 아이콘이 없습니다.');
      expect(
        icon.lengthSync(),
        greaterThan(3000),
        reason: '$density 아이콘이 교체되지 않은 것으로 보입니다.',
      );
    }
    expect(File('assets/branding/app_icon_v10.png').existsSync(), isTrue);
    expect(
      File(
        'android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      ).readAsStringSync(),
      contains('<adaptive-icon'),
    );
    expect(
      File(
        'android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml',
      ).readAsStringSync(),
      contains('<monochrome'),
    );
  });
}
