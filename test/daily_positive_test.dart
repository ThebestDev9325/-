import 'dart:math';

import 'package:chameulin/daily_positive_store.dart';
import 'package:chameulin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryDailyPositiveStore implements DailyPositiveStore {
  DailyPositiveState? state;

  MemoryDailyPositiveStore([this.state]);

  @override
  Future<DailyPositiveState?> load() async => state;

  @override
  Future<void> save(DailyPositiveState state) async {
    this.state = state;
  }
}

void main() {
  testWidgets('긍정과 명언이 함께 바뀌고 하루 세 번 뒤 다시 보기로 전환된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = MemoryDailyPositiveStore();
    final today = DateTime(2026, 7, 13, 10);

    await tester.pumpWidget(MaterialApp(
      home: PositivePage(
        store: store,
        random: Random(7),
        now: () => today,
      ),
    ));
    await tester.pump();

    expect(find.text('오늘의 긍정'), findsOneWidget);
    expect(find.text('오늘의 명언'), findsOneWidget);
    expect(find.byKey(const ValueKey('daily-quote-card')), findsOneWidget);

    for (var count = 1; count <= 3; count++) {
      await tester.tap(find.text('다른 긍정 보기'));
      await tester.pumpAndSettle();
      expect(store.state?.pairs.length, count);
      if (count < 3) {
        expect(find.text('다른 긍정 보기'), findsOneWidget);
      }
    }

    expect(
      find.text('다음달을 위해 우리 긍정에너지를 아껴두는건 어떨가요?'),
      findsOneWidget,
    );
    expect(
        store.state?.pairs.map((pair) => pair.positiveIndex).toSet().length, 3);
    expect(store.state?.pairs.map((pair) => pair.quoteIndex).toSet().length, 3);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('오늘 긍정 다시 보기'), findsOneWidget);

    final firstPair = store.state!.pairs.first;
    await tester.tap(find.text('오늘 긍정 다시 보기'));
    await tester.pumpAndSettle();
    final title = tester.widget<Text>(
      find.byKey(const ValueKey('positive-story-title')),
    );
    final quote = tester.widget<Text>(
      find.byKey(const ValueKey('daily-quote-text')),
    );
    expect(title.data, isNotEmpty);
    expect(quote.data, isNotEmpty);
    expect(store.state!.pairs.first.positiveIndex, firstPair.positiveIndex);
  });

  testWidgets('저장된 날짜가 오늘과 다르면 횟수와 다시 보기가 초기화된다', (tester) async {
    final store = MemoryDailyPositiveStore(const DailyPositiveState(
      dateKey: '2026-07-12',
      pairs: [
        DailyPositivePair(positiveIndex: 1, quoteIndex: 1),
        DailyPositivePair(positiveIndex: 2, quoteIndex: 2),
        DailyPositivePair(positiveIndex: 3, quoteIndex: 3),
      ],
    ));

    await tester.pumpWidget(MaterialApp(
      home: PositivePage(
        store: store,
        random: Random(3),
        now: () => DateTime(2026, 7, 13, 1),
      ),
    ));
    await tester.pump();

    expect(find.text('다른 긍정 보기'), findsOneWidget);
    expect(find.text('오늘 긍정 다시 보기'), findsNothing);
  });
}
