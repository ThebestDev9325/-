import 'package:chameulin/main.dart';
import 'package:chameulin/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const story = StoryItem(
  id: 'story-1',
  theme: '위로',
  title: '괜찮아요',
  body: '천천히 가도 괜찮아요.',
  quote: '오늘도 충분합니다.',
);

EmotionRecord record({bool shared = false}) => EmotionRecord(
      id: 'record-1',
      createdAt: DateTime(2026, 7, 18),
      category: '직장',
      moodEmoji: '😐',
      moodLabel: '보통',
      text: '오늘 있었던 일',
      story: story,
      shared: shared,
    );

void main() {
  testWidgets('비공개 기록은 상세 화면에서 다시 공유할 수 있다', (tester) async {
    var shareCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: RecordDetailPage(
          record: record(),
          onShare: (_) async {
            shareCalls++;
            return true;
          },
        ),
      ),
    );

    expect(find.text('공유하기'), findsOneWidget);
    await tester.tap(find.text('공유하기'));
    await tester.pumpAndSettle();

    expect(shareCalls, 1);
    expect(find.text('공유 완료'), findsOneWidget);
  });

  testWidgets('이미 공유된 기록은 중복 공유할 수 없다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecordDetailPage(
          record: record(shared: true),
          onShare: (_) async => true,
        ),
      ),
    );

    expect(find.text('공유 완료'), findsOneWidget);
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);
  });
}
