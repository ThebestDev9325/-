import 'package:chameulin/data/relationship_life_stories.dart';
import 'package:chameulin/data/story_db.dart';
import 'package:chameulin/story_recommender.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cases = <(String, String, String)>[
    ('남친의 애정 표현이 줄어서 서운해', '연인', 'affection_changed'),
    ('아내가 다툰 뒤 대화를 피해. 답답해', '가족', 'partner_silence'),
    ('연애하면서 나만 화해하려고 노력해', '연인', 'one_sided_repair'),
    ('헤어져야 할지 모르겠어. 결정이 어려워', '연인', 'breakup_ambivalence'),
    ('친구랑 서로 바빠서 연락이 뜸해지고 멀어져', '친구', 'friend_drift'),
    ('친구가 필요할 때만 나한테 연락해', '친구', 'used_for_favors'),
    ('친구가 내 비밀을 다른 사람에게 말했어', '친구', 'secret_shared'),
    ('사람들을 만나고 돌아오면 기운이 없어', '나 자신', 'social_exhaustion'),
    ('아이에게 같은 말을 반복해서 하느라 지쳐', '가족', 'parent_repeating'),
    ('아이를 다른 애랑 비교해서 미안하고 후회돼', '가족', 'parent_comparison_guilt'),
    ('육아 때문에 내 삶이 사라진 것 같아', '가족', 'parent_identity'),
    ('아들이 독립하고 나니 집이 허전해', '가족', 'empty_nest'),
    ('보증금을 못 받을까 봐 너무 걱정돼', '나 자신', 'deposit_worry'),
    ('대출 상환이 부담되고 매달 버거워', '나 자신', 'loan_repayment'),
    ('친구 모임에 가고 싶은데 비용이 부담돼', '친구', 'money_social_distance'),
    ('이사해야 하는데 예산에 맞는 집을 못 구하겠어', '나 자신', 'housing_search'),
    ('작은 실수가 자꾸 떠올라서 자책해', '나 자신', 'small_mistake_replay'),
    ('쉬면서도 죄책감이 들어', '나 자신', 'rest_guilt'),
    ('칭찬을 받아도 부족하고 운이 좋았을 뿐인 것 같아', '직장', 'praise_discomfort'),
    ('내가 원하는 게 뭔지 모르겠어', '나 자신', 'unclear_wants'),
    ('퇴사하고 싶은데 생활비 때문에 못 하겠어', '직장', 'quit_but_bills'),
    ('경력 단절 뒤 다시 일하려니 두려워', '직장', 'career_return'),
    ('전공이 적성에 안 맞아서 후회돼', '나 자신', 'major_mismatch'),
    ('은퇴하고 나니 내 역할이 없고 허전해', '나 자신', 'retirement_role'),
    ('돌아가신 엄마의 물건을 정리하기 어려워', '가족', 'grief_belongings'),
    ('돌아가신 아빠에게 못 한 말이 남아 있어', '가족', 'grief_unsaid'),
    ('장례 후 주변은 일상으로 돌아갔는데 나만 슬퍼', '가족', 'grief_out_of_step'),
    ('인스타를 보면 내 삶이 초라하고 비교하게 돼', '나 자신', 'social_feed_comparison'),
    ('단체방에서 내 말에 반응이 없어서 신경 쓰여', '친구', 'group_chat_response'),
    ('친구의 좋은 소식을 진심으로 축하하기 어려워', '친구', 'mixed_congratulations'),
  ];
  for (final (text, category, id) in cases) {
    test('사연: $text', () {
      for (final style in ['comfort', 'reality', 'growth', 'random']) {
        expect(recommendStory(text, category, style).id, id);
        expect(
            recommendStory(text.replaceAll(' ', ''), category, style, '많이 화남')
                .id,
            id);
      }
    });
  }
  const negatives = <(String, String)>[
    ('남친이 다정하게 대해줘', 'general_support'),
    ('아내와 대화해서 잘 풀었어', 'general_support'),
    ('친구가 내 비밀을 지켜줬어', 'general_support'),
    ('친구와 만나고 즐거웠어', 'general_support'),
    ('아이에게 즐겁게 책을 읽어줬어', 'general_support'),
    ('아들이 독립해서 뿌듯해', 'general_support'),
    ('보증금을 잘 돌려받았어', 'general_support'),
    ('모임 비용이 충분해서 마음이 편해', 'general_support'),
    ('이사할 집을 구했어', 'general_support'),
    ('칭찬을 받아서 기뻐', 'general_support'),
    ('내가 원하는 것을 찾았어', 'general_support'),
    ('전공이 적성에 잘 맞아', 'general_support'),
    ('단체방에서 따뜻한 답을 받았어', 'general_support'),
    ('친구에게 진심으로 축하한다고 말했어', 'general_support'),
    ('층간소음 때문에 스트레스를 너무많이 받아', 'neighbor_noise'),
    ('어제 야근하고 오늘 새벽 출근해서 지친다', 'short_rest_shift'),
  ];
  for (final (text, id) in negatives) {
    test('긍정·기존 상황: $text', () {
      expect(recommendStory(text, '나 자신', 'comfort').id, id);
    });
  }
  test('8개 분류의 모든 세부 상황과 본문이 추천 사례에 포함된다', () {
    const counts = {
      '연애·부부관계': 4,
      '친구·대인관계': 4,
      '육아·부모 역할': 4,
      '돈·주거·생활': 4,
      '자존감·내 마음': 4,
      '진로·인생의 전환': 4,
      '상실·그리움': 3,
      '온라인·사회적 비교': 3,
    };
    expect(relationshipLifeScenarios.length, 30);
    expect(cases.map((e) => e.$3).toSet(),
        relationshipLifeStories.map((s) => s.id).toSet());
    for (final entry in counts.entries) {
      final items =
          relationshipLifeScenarios.where((s) => s.group == entry.key);
      expect(items.length, entry.value);
      expect(items.map((s) => s.situation).toSet().length, entry.value);
    }
    for (final item in relationshipLifeScenarios) {
      expect(storyDb, contains(item.story));
      expect(item.story.body.length, inInclusiveRange(120, 400));
      expect(item.story.theme, startsWith('${item.group} · '));
    }
  });
}
