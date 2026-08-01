import 'dart:async';

import 'package:chameulin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openSharePage(WidgetTester tester) async {
  await tester.tap(find.text('테스트 글쓰기 열기'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('다 적었습니다'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '심사 중 작성한 익명 게시물입니다.');
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  final nextButton = find.widgetWithText(FilledButton, '다음');
  await tester.ensureVisible(nextButton);
  await tester.tap(nextButton);
  await tester.pumpAndSettle();
  await tester.tap(find.text('많이 화남'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, '다음'));
  await tester.pumpAndSettle();
  expect(find.text('어떻게 기록할까요?'), findsOneWidget);
}

Widget testApp(
  Future<WritingShareOutcome> Function(WritingResult) onShare, {
  ValueChanged<int>? onTabSelected,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => WritingFlow(
                  storyStyle: 'random',
                  onShare: onShare,
                  onTabSelected: onTabSelected,
                ),
              ),
            ),
            child: const Text('테스트 글쓰기 열기'),
          ),
        ),
      ),
    ),
  );
}

Future<void> pumpTestApp(WidgetTester tester,
    Future<WritingShareOutcome> Function(WritingResult) onShare,
    {ValueChanged<int>? onTabSelected}) async {
  tester.view.physicalSize = const Size(1024, 1366);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    testApp(onShare, onTabSelected: onTabSelected),
  );
}

void main() {
  testWidgets('공유 실패 후 작성 화면과 동일 identity를 유지해 재시도한다', (tester) async {
    final attempts = <WritingResult>[];
    await pumpTestApp(tester, (result) async {
      attempts.add(result);
      return attempts.length > 1
          ? WritingShareOutcome.succeeded
          : WritingShareOutcome.failed;
    });
    await openSharePage(tester);

    await tester.tap(find.widgetWithText(FilledButton, '공유하기'));
    await tester.pumpAndSettle();
    expect(find.text('어떻게 기록할까요?'), findsOneWidget);
    final textField = tester.widget<TextField>(
      find.byType(TextField, skipOffstage: false),
    );
    expect(textField.controller?.text, '심사 중 작성한 익명 게시물입니다.');

    await tester.tap(find.widgetWithText(FilledButton, '공유하기'));
    await tester.pumpAndSettle();
    expect(attempts, hasLength(2));
    expect(attempts[1].id, attempts[0].id);
    expect(attempts[1].createdAt, attempts[0].createdAt);
    expect(find.text('테스트 글쓰기 열기'), findsOneWidget);
  });

  testWidgets('공유 callback 예외에도 화면을 유지하고 버튼을 복구한다', (tester) async {
    var calls = 0;
    await pumpTestApp(tester, (_) async {
      calls++;
      throw StateError('test failure');
    });
    await openSharePage(tester);

    await tester.tap(find.widgetWithText(FilledButton, '공유하기'));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.text('어떻게 기록할까요?'), findsOneWidget);
    expect(find.text('공유하지 못했습니다. 잠시 후 다시 시도해주세요.'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '공유하기'))
            .onPressed,
        isNotNull);
  });

  testWidgets('공유 요청 중 중복 제출과 뒤로가기를 막고 성공 후 닫는다', (tester) async {
    final completion = Completer<WritingShareOutcome>();
    var calls = 0;
    var tabSelections = 0;
    await pumpTestApp(
      tester,
      (_) {
        calls++;
        return completion.future;
      },
      onTabSelected: (_) => tabSelections++,
    );
    await openSharePage(tester);

    await tester.tap(find.widgetWithText(FilledButton, '공유하기'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '공유 중...'));
    await tester.pump();
    expect(calls, 1);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, '내 기록으로 저장'),
          )
          .onPressed,
      isNull,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const ValueKey('writing-bottom-navigation-lock')),
          )
          .ignoring,
      isTrue,
    );
    tester
        .widget<NavigationBar>(find.byType(NavigationBar))
        .onDestinationSelected
        ?.call(2);
    await tester.pump();
    expect(tabSelections, 0);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pump();
    expect(find.text('어떻게 기록할까요?'), findsOneWidget);

    completion.complete(WritingShareOutcome.succeeded);
    await tester.pumpAndSettle();
    expect(find.text('어떻게 기록할까요?'), findsNothing);
  });

  testWidgets('공유 결과가 불명확하면 이탈을 막고 같은 identity 재시도만 허용한다', (tester) async {
    final attempts = <WritingResult>[];
    var tabSelections = 0;
    await pumpTestApp(
      tester,
      (result) async {
        attempts.add(result);
        return attempts.length > 1
            ? WritingShareOutcome.succeeded
            : WritingShareOutcome.indeterminate;
      },
      onTabSelected: (_) => tabSelections++,
    );
    await openSharePage(tester);

    await tester.tap(find.widgetWithText(FilledButton, '공유하기'));
    await tester.pumpAndSettle();

    expect(find.text('어떻게 기록할까요?'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, '내 기록으로 저장'),
          )
          .onPressed,
      isNull,
    );
    expect(find.byType(BackButton), findsNothing);
    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const ValueKey('writing-bottom-navigation-lock')),
          )
          .ignoring,
      isTrue,
    );
    tester
        .widget<NavigationBar>(find.byType(NavigationBar))
        .onDestinationSelected
        ?.call(2);
    await tester.pump();
    expect(tabSelections, 0);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pump();
    expect(find.text('어떻게 기록할까요?'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '공유하기'))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.widgetWithText(FilledButton, '공유하기'));
    await tester.pumpAndSettle();
    expect(attempts, hasLength(2));
    expect(attempts[1].id, attempts[0].id);
    expect(attempts[1].createdAt, attempts[0].createdAt);
    expect(find.text('테스트 글쓰기 열기'), findsOneWidget);
  });
}
