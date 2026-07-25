import 'dart:math';

import 'package:chameulin/daily_positive_store.dart';
import 'package:chameulin/main.dart';
import 'package:chameulin/positive_bookmark_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryDailyPositiveStore implements DailyPositiveStore {
  DailyPositiveState? state;

  @override
  Future<DailyPositiveState?> load() async => state;

  @override
  Future<void> save(DailyPositiveState state) async {
    this.state = state;
  }
}

class MemoryPositiveBookmarkStore implements PositiveBookmarkStore {
  PositiveBookmarkState state;

  MemoryPositiveBookmarkStore([this.state = const PositiveBookmarkState()]);

  @override
  Future<PositiveBookmarkState> load() async => state;

  @override
  Future<void> save(PositiveBookmarkState state) async {
    this.state = state;
  }
}

void main() {
  testWidgets('긍정 글을 하트로 저장하고 보관함에서 취소할 수 있다', (tester) async {
    final bookmarkStore = MemoryPositiveBookmarkStore();

    await tester.pumpWidget(
      MaterialApp(
        home: PositivePage(
          store: MemoryDailyPositiveStore(),
          bookmarkStore: bookmarkStore,
          random: Random(7),
          now: () => DateTime(2026, 7, 24, 9),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final emptyHeart = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('positive-bookmark-heart')),
        matching: find.byType(Icon),
      ),
    );
    expect(emptyHeart.icon, Icons.favorite_border);

    await tester.tap(find.byKey(const ValueKey('positive-bookmark-heart')));
    await tester.pumpAndSettle();
    expect(bookmarkStore.state.positiveIndexes, hasLength(1));

    await tester.tap(find.byKey(const ValueKey('positive-bookmarks-button')));
    await tester.pumpAndSettle();
    expect(find.text('보관함'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('positive-bookmarks-list')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('보관함에서 삭제'));
    await tester.pumpAndSettle();
    expect(bookmarkStore.state.positiveIndexes, isEmpty);
    expect(
      find.byKey(const ValueKey('positive-bookmarks-empty')),
      findsOneWidget,
    );
  });

  testWidgets('명언 저장 상태가 다시 화면을 열어도 복원된다', (tester) async {
    final dailyStore = MemoryDailyPositiveStore();
    final bookmarkStore = MemoryPositiveBookmarkStore();

    await tester.pumpWidget(
      MaterialApp(
        home: PositivePage(
          store: dailyStore,
          bookmarkStore: bookmarkStore,
          random: Random(3),
          now: () => DateTime(2026, 7, 24, 9),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('다른 긍정 보기'));
    await tester.pumpAndSettle();
    expect(find.text('오늘의 명언'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('positive-bookmark-heart')));
    await tester.pumpAndSettle();
    expect(bookmarkStore.state.quoteIndexes, hasLength(1));

    await tester.pumpWidget(
      MaterialApp(
        home: PositivePage(
          store: dailyStore,
          bookmarkStore: bookmarkStore,
          random: Random(3),
          now: () => DateTime(2026, 7, 24, 9),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final filledHeart = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('positive-bookmark-heart')),
        matching: find.byType(Icon),
      ),
    );
    expect(filledHeart.icon, Icons.favorite);
  });

  testWidgets('다크모드 보관함의 긍정과 명언 카드에 구분되는 배경이 있다',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: PositiveBookmarksPage(
          positiveIndexes: const {0},
          quoteIndexes: const {0},
          onToggle: ({required isQuote, required index}) async {},
        ),
      ),
    );

    final cards = tester.widgetList<Card>(find.byType(Card)).toList();
    expect(cards, hasLength(2));
    for (final card in cards) {
      expect(card.color, const Color(0xFF263329));
      expect(card.elevation, 0);
      final shape = card.shape! as RoundedRectangleBorder;
      expect(shape.side.color, const Color(0xFF718273));
    }
  });
}
