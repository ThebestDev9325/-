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

  testWidgets('네 광고가 두 칸씩 10초마다 교대한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(bottomNavigationBar: BottomAdSlots())),
    );
    expect(find.text('조용한 밤의 위로'), findsOneWidget);
    expect(find.text('참을인'), findsOneWidget);
    expect(find.text('광고'), findsNWidgets(2));
    expect(find.byIcon(Icons.play_circle_fill), findsNWidgets(2));
    expect(find.byKey(const ValueKey('bottom-ad-slot1')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-ad-slot2')), findsOneWidget);
    final slot1 = find.byKey(const ValueKey('bottom-ad-slot1'));
    final slot1Icon = find.descendant(
      of: slot1,
      matching: find.byIcon(Icons.play_circle_fill),
    );
    final slot1Title = find.descendant(
      of: slot1,
      matching: find.text('조용한 밤의 위로'),
    );
    final iconRect = tester.getRect(slot1Icon);
    final titleRect = tester.getRect(slot1Title);
    final slotRect = tester.getRect(slot1);
    expect(titleRect.left - iconRect.right, lessThanOrEqualTo(6));
    expect(
      (iconRect.left + titleRect.right) / 2,
      closeTo(slotRect.center.dx, 1),
    );
    final slot1Background = tester.widget<DecoratedBox>(
      find.descendant(
        of: slot1,
        matching: find.byType(DecoratedBox),
      ),
    );
    final slot1Image = (slot1Background.decoration as BoxDecoration).image;
    expect(
      slot1Image?.image,
      const AssetImage('assets/branding/quiet_night_banner_2048x1152.jpg'),
    );
    expect(
      slot1Image?.colorFilter,
      const ColorFilter.mode(Color(0x8CFFFFFF), BlendMode.srcOver),
    );
    final slot2Background = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const ValueKey('bottom-ad-slot2')),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect((slot2Background.decoration as BoxDecoration).image, isNotNull);
    final slot2AdLabel = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('bottom-ad-slot2')),
        matching: find.text('광고'),
      ),
    );
    expect(slot2AdLabel.style?.color, Colors.white.withValues(alpha: 0.82));

    await tester.pump(const Duration(seconds: 10));

    expect(find.text('광고'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('bottom-ad-slot3')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-ad-slot4')), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_fill), findsNothing);
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
