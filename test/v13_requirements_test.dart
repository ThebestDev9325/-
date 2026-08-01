import 'package:chameulin/data/story_db.dart';
import 'package:chameulin/main.dart';
import 'package:chameulin/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EmotionRecord record(String mood, String emoji, int minute) => EmotionRecord(
  id: '$mood$minute',
  createdAt: DateTime(2026, 7, 12, 10, minute),
  category: '직장',
  moodEmoji: emoji,
  moodLabel: mood,
  text: '기록',
  story: storyDb.first,
  shared: false,
);

void main() {
  test('날짜 대표 감정은 최빈값이며 동률이면 최신 기록이다', () {
    expect(
      representativeMoodEmoji([
        record('매우 화남', '🤬', 1),
        record('매우 화남', '🤬', 2),
        record('답답함', '😐', 3),
      ]),
      '🤬',
    );
    expect(
      representativeMoodEmoji([
        record('매우 화남', '🤬', 1),
        record('답답함', '😐', 3),
      ]),
      '😐',
    );
  });

  testWidgets('네 광고 슬롯이 동일한 너비로 표시된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(bottomNavigationBar: BottomAdSlots())),
    );
    expect(find.text('조용한 밤의 위로'), findsOneWidget);
    expect(find.text('참을인'), findsOneWidget);
    expect(find.text('광고'), findsNWidgets(4));
    expect(find.byIcon(Icons.play_circle_fill), findsNWidgets(2));
    final widths = List.generate(
      4,
      (index) => tester
          .getSize(find.byKey(ValueKey('bottom-ad-slot-${index + 1}')))
          .width,
    );
    expect(widths.toSet(), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('글쓰기 화면에서도 하단 탭과 광고가 유지된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WritingFlow(storyStyle: 'random')),
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(BottomAdSlots), findsOneWidget);
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
  });
}
