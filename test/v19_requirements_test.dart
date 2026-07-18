import 'package:chameulin/audio_service.dart';
import 'package:chameulin/main.dart';
import 'package:chameulin/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SharedPost post({
  required String id,
  required DateTime createdAt,
  required int angryReactions,
}) {
  return SharedPost(
    id: id,
    ownerId: 'owner-$id',
    category: '기타',
    text: '사연 $id',
    moodEmoji: '😐',
    createdAt: createdAt,
    reactions: [angryReactions, 0, 0],
  );
}

void main() {
  test('모든 화면의 배경음은 사용자가 제공한 음악을 사용한다', () {
    expect(
      AppAudioService.homeBgmAsset,
      'assets/audio/soft_rain_meditation.mp3',
    );
    expect(AppAudioService.defaultBackgroundVolume, .20);
  });

  test('오늘의 베스트는 현지 자정 이후 작성된 사연만 대상으로 한다', () {
    final now = DateTime(2026, 7, 13, 0, 1);
    final yesterday = post(
      id: 'yesterday',
      createdAt: DateTime(2026, 7, 12, 23, 59),
      angryReactions: 100,
    );
    final today = post(
      id: 'today',
      createdAt: DateTime(2026, 7, 13, 0, 0),
      angryReactions: 1,
    );

    expect(bestPostForDay([yesterday, today], now)?.id, 'today');
    expect(bestPostForDay([yesterday], now), isNull);
  });

  testWidgets('공감 탭은 선택한 일자의 사연과 베스트만 표시한다', (tester) async {
    final now = DateTime(2026, 7, 18, 10);
    final yesterday = post(
      id: 'yesterday',
      createdAt: DateTime(2026, 7, 17, 20),
      angryReactions: 5,
    );
    final today = post(
      id: 'today',
      createdAt: DateTime(2026, 7, 18, 9),
      angryReactions: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EmpathyPage(
          posts: [yesterday, today],
          currentUserId: 'viewer',
          onReact: (_, __) {},
          onReport: (_) {},
          now: now,
        ),
      ),
    );

    expect(find.text('사연 today'), findsNWidgets(2));
    expect(find.text('사연 yesterday'), findsNothing);
    expect(find.text('오늘의 Best 사연'), findsOneWidget);

    await tester.tap(find.text('17일'));
    await tester.pump();

    expect(find.text('사연 today'), findsNothing);
    expect(find.text('사연 yesterday'), findsNWidgets(2));
    expect(find.text('17일의 Best 사연'), findsOneWidget);
    final reactionButton = tester.widget<OutlinedButton>(
      find.byType(OutlinedButton).first,
    );
    expect(reactionButton.onPressed, isNull);
  });

  testWidgets('내 공유 카드 오른쪽 위에 공유 날짜를 표시한다', (tester) async {
    final shared = post(
      id: 'mine',
      createdAt: DateTime(2026, 7, 18, 11, 30),
      angryReactions: 0,
    );

    await tester.pumpWidget(
      MaterialApp(home: MySharePage(posts: [shared])),
    );

    final date = tester.widget<Text>(
      find.byKey(const ValueKey('my-share-date-mine')),
    );
    expect(date.data, '7/18');
  });
}
