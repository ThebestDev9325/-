import 'package:chameulin/data/daily_stress_stories.dart';
import 'package:chameulin/data/story_db.dart';
import 'package:chameulin/story_recommender.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cases = <(String, String, String)>[
    ('층간소음 때문에 스트레스를 너무많이 받아', '기타', 'neighbor_noise'),
    ('윗집에서 밤마다 쿵쿵거려서 스트레스야', '타인', 'neighbor_noise'),
    ('위층 발소리가 시끄러워서 집에서 못 쉬겠어', '타인', 'neighbor_noise'),
    ('층간소음 때문에 잠을 못 자서 피곤해', '나 자신', 'noise_lost_sleep'),
    ('옆집 소리 때문에 자꾸 잠에서 깨', '기타', 'noise_lost_sleep'),
    ('아랫집 담배 냄새가 화장실로 들어와서 답답해', '타인', 'neighbor_smoke'),
    ('이웃의 담배 연기 때문에 창문을 못 열겠어', '기타', 'neighbor_smoke'),
    ('이중주차한 차가 안 빼줘서 못 나가고 있어', '타인', 'parking_conflict'),
    ('주차 자리가 없어서 돌아다니느라 짜증이 나', '기타', 'parking_conflict'),
    ('누수인데 집주인이 안 고쳐줘서 스트레스야', '타인', 'home_repair_delay'),
    ('보일러 수리를 계속 미뤄서 기다리고 있어', '기타', 'home_repair_delay'),
    ('룸메가 청소를 안 해서 불편하고 스트레스야', '친구', 'roommate_friction'),
    ('지하철이 만원이라 사람에 치여 출근부터 지쳐', '직장', 'crowded_commute'),
    ('출퇴근 왕복 세 시간이 걸려서 내 시간이 없어', '직장', 'long_commute'),
    ('모르는 사람이 시비를 걸고 욕을 해서 얼어붙었어', '타인', 'rude_stranger'),
    ('기다렸는데 내 앞에서 새치기를 해서 너무 화나', '타인', 'queue_cutting'),
    ('택배가 파손돼서 왔어. 너무 속상해', '기타', 'delivery_problem'),
    ('음식 배달이 너무 늦어서 짜증나', '기타', 'delivery_problem'),
    ('환불을 안 해주고 계속 문의하라고 떠넘겨', '타인', 'refund_runaround'),
    ('밤새 만든 과제 파일이 날아갔어. 허탈해', '나 자신', 'lost_work_file'),
    ('급한데 노트북이 먹통이라 아무것도 못 해', '직장', 'device_failure'),
    ('인터넷이 자꾸 끊겨서 답답해', '기타', 'device_failure'),
    ('제출 기한이 촉박해서 불안하고 쫓겨', '나 자신', 'deadline_pressure'),
    ('일하는데 동료가 자꾸 불러서 집중이 계속 끊겨', '직장', 'constant_interruptions'),
    ('회식에 가기 싫은데 빠지면 눈치가 보여', '직장', 'forced_socializing'),
    ('친구가 내 뒷담화를 했다는 말을 들었어', '친구', 'gossip_hurt'),
    ('부탁을 거절하지 못해서 또 맡아버렸어', '친구', 'hard_to_refuse'),
    ('친구에게 빌려준 돈을 안 갚아서 속이 타', '친구', 'unreturned_loan'),
    ('물가가 올라서 생활비 부담이 너무 커', '나 자신', 'rising_living_costs'),
    ('관리비가 인상돼서 부담이야', '가족', 'rising_living_costs'),
    ('빨래와 설거지가 쌓였는데 할 기운이 없어', '나 자신', 'chores_piling_up'),
    ('강아지가 아파서 병원에 갔는데 걱정이 돼', '가족', 'pet_health_worry'),
    ('고양이가 밥을 안 먹어서 걱정돼', '나 자신', 'pet_health_worry'),
    ('댓글로 욕설과 조롱을 받아서 상처받았어', '타인', 'online_hostility'),
  ];

  for (final (text, category, id) in cases) {
    test('일상 스트레스: $text', () {
      for (final style in ['comfort', 'reality', 'growth', 'random']) {
        expect(recommendStory(text, category, style).id, id);
        expect(
          recommendStory(text.replaceAll(' ', ''), category, style, '많이 화남').id,
          id,
        );
      }
    });
  }

  const negatives = <(String, String)>[
    ('층간소음은 없고 회사 야근이 힘들어', 'overwork'),
    ('층간소음이 아니라 면접에 탈락해서 속상해', 'failure'),
    ('층간소음 문제가 해결됐어', 'general_support'),
    ('담배 냄새가 안 나서 집이 쾌적해', 'general_support'),
    ('윗집에서 떡을 나눠줬어', 'general_support'),
    ('주차를 하고 집에 왔어', 'general_support'),
    ('룸메랑 즐거운 하루를 보냈어', 'general_support'),
    ('택배를 잘 받았어', 'general_support'),
    ('환불이 완료됐어', 'general_support'),
    ('노트북을 새로 샀어', 'general_support'),
    ('파일을 저장하고 퇴근했어', 'general_support'),
    ('마감 전에 여유 있게 끝냈어', 'general_support'),
    ('회식이 즐거웠어', 'general_support'),
    ('부탁을 흔쾌히 들어줬어', 'general_support'),
    ('친구에게 빌려준 돈을 잘 받았어', 'general_support'),
    ('강아지와 산책해서 즐거웠어', 'general_support'),
    ('고양이가 죽었어. 너무 보고 싶어', 'pet_loss'),
    ('댓글로 응원을 받았어', 'general_support'),
    ('지하철이 지연돼서 늦었어', 'commute'),
    ('업무 중 실수해서 후회하고 있어', 'work_mistake'),
  ];
  for (final (text, id) in negatives) {
    test('단어만으로 새 상황을 단정하지 않는다: $text', () {
      expect(recommendStory(text, '나 자신', 'comfort').id, id);
    });
  }

  test('24개 상황의 본문·추천 연결·사례가 빠짐없이 존재한다', () {
    expect(dailyStressScenarios.length, 24);
    expect(
      cases.map((e) => e.$3).toSet(),
      dailyStressStories.map((s) => s.id).toSet(),
    );
    for (final scenario in dailyStressScenarios) {
      final story = scenario.story;
      expect(storyDb, contains(story));
      expect(story.body.length, inInclusiveRange(120, 400));
      expect(story.body, story.body.trim());
      expect(story.title.trim(), isNotEmpty);
      expect(story.quote.trim(), isNotEmpty);
      expect(story.id, isNot(contains('__')));
    }
  });

  test('사용자 층간소음 사연은 카테고리와 무관하게 휴식 침해를 짚는다', () {
    for (final category in ['직장', '고객', '가족', '친구', '연인', '타인', '나 자신', '기타']) {
      final story = recommendStory(
        '층간소음 때문에 스트레스를 너무많이 받아',
        category,
        'random',
      );
      expect(story.id, 'neighbor_noise');
      expect(story.body, contains('내 휴식이 방해받는 일'));
      expect(story.body, contains('조용히 쉬고 싶다는 마음은 무리한 바람이 아니에요'));
    }
  });
}
