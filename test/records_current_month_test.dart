import 'package:chameulin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('내 기록 달력은 앱을 연 현재 연월로 시작한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecordsPage(
            records: const [],
            initialDate: DateTime(2026, 8, 1),
          ),
        ),
      ),
    );

    expect(find.text('2026년 8월'), findsOneWidget);
    expect(find.text('2026년 7월'), findsNothing);
  });

  testWidgets('12월에서 다음 달로 이동하면 다음 해 1월이 된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecordsPage(
            records: const [],
            initialDate: DateTime(2026, 12, 1),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();

    expect(find.text('2027년 1월'), findsOneWidget);
  });
}
