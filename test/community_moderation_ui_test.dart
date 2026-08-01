import 'package:chameulin/main.dart';
import 'package:chameulin/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SharedPost post({String ownerId = 'owner'}) => SharedPost(
      id: 'post',
      ownerId: ownerId,
      category: '기타',
      text: '공유한 사연',
      moodEmoji: '😐',
      moodLabel: '답답함',
      createdAt: DateTime(2026, 7, 28),
    );

Widget card({
  bool mine = false,
  ValueChanged<SharedPost>? onHide,
  ValueChanged<SharedPost>? onBlock,
  void Function(SharedPost, String)? onReport,
  ValueChanged<SharedPost>? onDelete,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SharedPostCard(
        post: post(ownerId: mine ? 'me' : 'owner'),
        mine: mine,
        onReact: (_, __) {},
        onHide: onHide ?? (_) {},
        onBlock: onBlock ?? (_) {},
        onReportWithReason: onReport ?? (_, __) {},
        onDelete: onDelete ?? (_) {},
      ),
    ),
  );
}

Future<void> openActions(WidgetTester tester) async {
  await tester.tap(find.byTooltip('게시물 관리'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('다른 사람 게시물을 즉시 숨길 수 있다', (tester) async {
    SharedPost? hidden;
    await tester.pumpWidget(card(onHide: (value) => hidden = value));

    await openActions(tester);
    await tester.tap(find.text('이 게시물 숨기기'));
    await tester.pumpAndSettle();

    expect(hidden?.id, 'post');
  });

  testWidgets('신고 메뉴는 사이렌 아이콘이며 작성자 차단을 제공하지 않는다', (tester) async {
    await tester.pumpWidget(card());

    expect(find.byIcon(Icons.notification_important_rounded), findsOneWidget);
    await openActions(tester);
    expect(find.text('이 작성자 차단'), findsNothing);
    expect(find.text('신고하기'), findsOneWidget);
    expect(find.text('이 게시물 숨기기'), findsOneWidget);
  });

  testWidgets('신고 사유를 직접 입력해 게시물을 신고할 수 있다', (tester) async {
    String? reason;
    await tester.pumpWidget(
      card(onReport: (_, selectedReason) => reason = selectedReason),
    );

    await openActions(tester);
    await tester.tap(find.text('신고하기'));
    await tester.pumpAndSettle();
    expect(find.text('신고 사유'), findsOneWidget);
    expect(find.text('신고 사유를 입력해주세요.'), findsOneWidget);
    final submit = find.widgetWithText(FilledButton, '신고하기');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '욕설이 포함된 게시물입니다.');
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(reason, '욕설이 포함된 게시물입니다.');
  });

  testWidgets('내 공유 게시물을 삭제할 수 있다', (tester) async {
    SharedPost? deleted;
    await tester.pumpWidget(
      card(mine: true, onDelete: (value) => deleted = value),
    );

    await openActions(tester);
    await tester.tap(find.text('내 게시물 삭제'));
    await tester.pumpAndSettle();

    expect(deleted?.id, 'post');
    expect(find.text('신고하기'), findsNothing);
  });
}
