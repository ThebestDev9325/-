import 'package:chameulin/legal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('필수 항목을 모두 확인해야 참을인을 시작할 수 있다', (tester) async {
    var accepted = false;
    await tester.pumpWidget(MaterialApp(
      home: InitialConsentPage(onAccepted: () => accepted = true),
    ));

    final start = find.widgetWithText(FilledButton, '동의하고 시작하기');
    expect(tester.widget<FilledButton>(start).onPressed, isNull);

    for (var index = 0; index < 4; index++) {
      await tester.tap(find.byType(Checkbox).at(index));
      await tester.pump();
    }
    expect(tester.widget<FilledButton>(start).onPressed, isNotNull);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(accepted, isTrue);
  });

  test('위기 표현을 공백과 관계없이 감지한다', () {
    expect(containsCrisisLanguage('죽고 싶다는 생각이 들어'), isTrue);
    expect(containsCrisisLanguage('오늘은 조금 힘들었어'), isFalse);
  });

  testWidgets('설정에서 열 수 있는 약관 전문에 시행 정보가 표시된다', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: LegalDocumentPage(type: LegalDocumentType.terms),
    ));
    expect(find.text('이용약관'), findsOneWidget);
    expect(find.textContaining(currentTermsVersion), findsOneWidget);
  });

  testWidgets('이용약관 등 보기 화면에서 문서를 한곳에 모아 보여준다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LegalDocumentsPage()));

    expect(find.text('이용약관'), findsOneWidget);
    expect(find.text('개인정보처리방침'), findsOneWidget);
    expect(find.text('커뮤니티 운영정책'), findsOneWidget);
    expect(find.text('기록 및 서비스 이용 안내'), findsOneWidget);
  });

  testWidgets('초기 동의는 만 18세 이상 확인을 요구한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: InitialConsentPage(onAccepted: () {})),
    );

    expect(find.textContaining('만 18세 이상'), findsOneWidget);
    expect(find.textContaining('만 14세 이상'), findsNothing);
  });

  test('커뮤니티 정책은 24시간 신고 처리와 연락처를 명시한다', () {
    final policy = LegalDocumentType.community.body;
    expect(policy, contains('24시간 이내'));
    expect(policy, contains('a01041989325@gmail.com'));
    expect(policy, contains('작성자를 차단'));
  });
}
