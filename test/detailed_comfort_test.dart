import 'package:chameulin/data/detailed_comfort_stories.dart';
import 'package:chameulin/main.dart';
import 'package:chameulin/text_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const userExample =
    '어제 늦은시간 까지 야근을 했는데, 오늘 새벽 출근을 회사에서 요구한다. 어쩔수없이 출근을 하는데, 지친다.';

void main() {
  const cases = <(String, String, String)>[
    (userExample, '직장', 'short_rest_shift'),
    ('늦게 퇴근했는데 회사에서 아침 일찍 출근하래', '직장', 'short_rest_shift'),
    ('몸살이 나서 아픈데 출근해야 해', '직장', 'sick_at_work'),
    ('퇴근 후에도 상사가 업무 연락을 해서 못 쉬겠어', '직장', 'after_hours_work'),
    ('연차를 쓰려는데 눈치가 보여서 미안해', '직장', 'leave_guilt'),
    ('동료가 자기 업무를 나한테만 떠넘겨', '직장', 'unfair_workload'),
    ('회의 중에 팀장한테 혼났어. 직원들 앞이라 더 창피해', '직장', 'public_reprimand'),
    ('상사의 지시가 계속 바뀌어서 맞춰도 다시 하래', '직장', 'changing_instructions'),
    ('프로젝트를 열심히 했는데 아무도 알아주지 않아', '직장', 'work_unrecognized'),
    ('신입인데 모르는 게 많고 질문하기 눈치 보여', '직장', 'new_job_overwhelmed'),
    ('내 잘못이 아닌데 손님에게 사과해야 했어', '고객', 'customer_forced_apology'),
    ('독박 육아를 하느라 쉴 시간이 없어', '가족', 'solo_parenting'),
    ('아이에게 소리쳤어. 미안하고 후회돼', '가족', 'parent_guilt'),
    ('엄마 간병하다가 쉬고 싶다는 생각이 들어서 죄책감이 들어', '가족', 'caregiver_guilt'),
    ('남편은 쉬는데 집안일을 나만 해서 서운해', '가족', 'unequal_housework'),
    ('엄마가 사촌이랑 자꾸 비교해서 상처받았어', '가족', 'family_comparison'),
    ('친척들이 언제 결혼하냐고 계속 물어봐서 지쳐', '가족', 'marriage_pressure'),
    ('친구에게 힘들다고 털어놨는데 예민하다고 넘겨', '친구', 'dismissed_feelings'),
    ('연락도 약속도 항상 내가 먼저 해. 나만 애쓰는 기분', '연인', 'one_sided_contact'),
    ('친구가 당일에 약속을 취소했어. 기다렸는데 허탈해', '친구', 'last_minute_cancel'),
    ('친구들이 나 빼고 만났다는 걸 사진 보고 알았어', '친구', 'excluded_friends'),
    ('남친이 약속을 또 어겼어. 믿어보려고 했는데', '연인', 'broken_promise'),
    ('헤어진 남자친구에게 습관처럼 연락하고 싶어', '연인', 'breakup_daily_absence'),
    ('돌아가신 엄마 기일이라 더 보고 싶고 빈자리가 커', '가족', 'grief_anniversary'),
    ('면접에서 세 번째 탈락했어. 지치고 속상해', '직장', 'repeated_rejection'),
    ('열심히 공부했는데 시험 점수가 낮아서 실망했어', '나 자신', 'effort_without_grades'),
    ('친구들은 다 취업했는데 나만 뒤처진 것 같아', '나 자신', 'peers_moving_ahead'),
    ('월급이 들어오자마자 월세와 카드값으로 다 빠져', '나 자신', 'payday_bills'),
    ('월급이 밀려서 생활비를 낼 수가 없어', '직장', 'unpaid_wages'),
    ('갑자기 수리비로 큰돈이 나가서 막막해', '나 자신', 'unexpected_expense'),
    ('검사 결과를 기다리는 동안 계속 불안해', '나 자신', 'waiting_test_results'),
    ('통증이 계속되는데 남들은 멀쩡해 보인다고 해', '나 자신', 'chronic_pain_unseen'),
    ('생일인데 아무도 연락이 없어서 외로워', '나 자신', 'lonely_birthday'),
  ];
  for (final (text, category, id) in cases) {
    test('구체적인 사연: $text', () {
      for (final style in ['comfort', 'reality', 'growth', 'random']) {
        expect(recommendStory(text, category, style).id, id);
        expect(
            recommendStory(text.replaceAll(' ', ''), category, style, '많이 화남')
                .id,
            id);
      }
    });
  }

  test('32개 본문을 모두 실제 추천 사례로 검증하며 내용을 잘라내지 않는다', () {
    expect(detailedComfortStories.length, 32);
    expect(cases.map((c) => c.$3).toSet(),
        detailedComfortStories.map((s) => s.id).toSet());
    for (final story in detailedComfortStories) {
      expect(story.body.length, inInclusiveRange(120, 400));
      expect(story.body, story.body.trim());
      expect(story.quote, isNotEmpty);
    }
    final story = recommendStory(userExample, '직장', 'comfort');
    expect(story.body, contains('쉴 시간이 너무 부족했던 거예요.'));
    expect(story.quote, contains('눈치 보지 않고 쉴 시간'));
  });

  const broadCases = <(String, String)>[
    ('어제 야근을 해서 지쳐', 'overwork'),
    ('새벽에 출근해서 피곤해', 'exhausted'),
    ('야근했지만 오늘 새벽 출근은 안 해. 그냥 피곤해', 'overwork'),
    ('연차를 써서 여행을 가', 'general_support'),
    ('생일에 친구가 축하해줬어', 'general_support'),
    ('아이랑 놀아서 즐거웠어', 'general_support'),
    ('검사 결과가 괜찮다고 해서 안심했어', 'health_worry'),
    ('한 번 면접에 탈락했어', 'failure'),
    ('친구가 나와 약속을 잡았어', 'general_support'),
    ('부모님께 취업 소식을 전했어', 'general_support'),
    ('내가 잘못해서 고객에게 사과하고 싶어', 'apology'),
    ('집안일을 함께 끝냈어', 'general_support'),
  ];
  for (final (text, id) in broadCases) {
    test('구체적인 단서가 없으면 상황을 지어내지 않는다: $text', () {
      expect(recommendStory(text, '나 자신', 'comfort').id, id);
    });
  }

  testWidgets('작은 화면과 큰 글씨에서도 새 긴 본문과 하단 동작을 읽을 수 있다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      ),
      home: const WritingFlow(storyStyle: 'comfort'),
    ));
    await tester.tap(find.text('다 적었습니다'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), userExample);
    tester.testTextInput.hide();
    await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, '다음'), 200,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('많이 화남'));
    await tester.pumpAndSettle();
    final story = recommendStory(userExample, '직장', 'comfort');
    final body =
        tester.widget<Text>(find.byKey(const ValueKey('story-page-body')));
    expect(body.data,
        preventKoreanWordSplits(formatStoryBodyForReadability(story.body)));
    expect(body.maxLines, isNull);
    await tester.scrollUntilVisible(find.text('별로에요'), 200,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    expect(find.text('별로에요').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
