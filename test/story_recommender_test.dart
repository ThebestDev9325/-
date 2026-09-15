import 'package:chameulin/data/story_db.dart';
import 'package:chameulin/data/detailed_comfort_stories.dart';
import 'package:chameulin/story_recommender.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cases = <(String, String, String)>[
    ('동료가 내 성과를 가로챘어. 너무 억울해', '직장', 'credit_taken'),
    ('친구가 죽었어. 아직도 믿기지 않아', '친구', 'bereavement'),
    ('회사에서 해고당할까 걱정되고 불안해', '직장', 'anxiety'),
    ('남자친구랑 헤어졌어. 계속 생각나고 잠도 못 자겠어', '연인', 'breakup'),
    ('여자친구가 문자로 헤어지자고 해서 화가 나', '연인', 'breakup'),
    ('이혼하고 혼자 지내니 너무 외로워', '가족', 'breakup'),
    ('할머니가 돌아가셨어. 자꾸 생각나고 너무 슬퍼', '가족', 'bereavement'),
    ('아버지 장례를 치렀는데 아직 실감이 안 나', '가족', 'bereavement'),
    ('엄마를 떠나보냈어. 내가 잘못한 일만 생각나', '가족', 'bereavement'),
    ('우리 강아지가 무지개다리를 건넜어. 너무 보고 싶어', '가족', 'pet_loss'),
    ('고양이를 떠나보냈는데 내가 잘못한 것 같아', '나 자신', 'pet_loss'),
    ('반려견이 죽었어. 매일 같이 걷던 길이 슬퍼', '가족', 'pet_loss'),
    ('생활비랑 월세 때문에 잠을 못 자고 있어', '나 자신', 'money_pressure'),
    ('빚이 쌓여서 막막하고 나 자신이 무능한 것 같아', '나 자신', 'money_pressure'),
    ('월급이 밀려서 카드값을 못 내겠어', '직장', 'unpaid_wages'),
    ('회사에서 해고당했어. 너무 억울하고 불안해', '직장', 'job_loss'),
    ('권고사직 얘기를 듣고 머리가 하얘졌어', '직장', 'job_loss'),
    ('매일 야근해서 피곤하고 친구에게 연락도 못 해', '직장', 'overwork'),
    ('업무량이 너무 많아서 실수할까 걱정돼', '직장', 'overwork'),
    ('팀장이 사람들 앞에서 면박을 줘서 상처받았어', '직장', 'public_reprimand'),
    ('동료가 나한테 막말해서 너무 화가 나', '직장', 'workplace_hurt'),
    ('친구들이 나를 왕따시키고 자꾸 괴롭혀', '친구', 'bullying'),
    ('직장에서 따돌림을 당해. 내가 잘못한 건가 싶어', '직장', 'bullying'),
    ('아픈 엄마를 간병하느라 너무 지쳤어', '가족', 'caregiving'),
    ('치매 아버지를 돌보는데 쉬고 싶어서 미안해', '가족', 'caregiver_guilt'),
    ('독박 육아로 하루 종일 지쳐 있고 자꾸 짜증이 나', '가족', 'solo_parenting'),
    ('아기가 밤마다 울어서 잠을 못 자', '가족', 'parenting'),
    ('부모님이 결혼하라고 잔소리해서 스트레스야', '가족', 'marriage_pressure'),
    ('엄마가 다른 집 자녀와 비교해서 서운해', '가족', 'family_comparison'),
    ('남편이랑 집안일 때문에 싸웠어', '가족', 'couple_conflict'),
    ('아내와 다퉜는데 집에 가기가 불편해', '가족', 'couple_conflict'),
    ('친구가 읽씹해서 내가 뭘 잘못했나 계속 생각나', '친구', 'unanswered'),
    ('남친한테 답장이 안 와서 걱정돼', '연인', 'unanswered'),
    ('여자친구에게 연락이 없어서 서운해', '연인', 'unanswered'),
    ('믿었던 친구가 거짓말을 해서 상처받았어', '친구', 'betrayal'),
    ('남편의 외도를 알게 됐어. 내가 부족했나', '가족', 'betrayal'),
    ('검사 결과를 기다리는데 무서워', '나 자신', 'waiting_test_results'),
    ('몸이 아파서 병원에 갔는데 지쳐', '나 자신', 'health_worry'),
    ('입원한 아빠가 걱정돼서 잠이 안 와', '가족', 'health_worry'),
    ('요즘 잠이 안 와서 밤이 너무 길어', '나 자신', 'sleep_trouble'),
    ('불면 때문에 오늘도 제대로 못 잤어', '나 자신', 'sleep_trouble'),
    ('공부에 집중이 안 되고 성적 때문에 스트레스야', '나 자신', 'study_pressure'),
    ('수능 준비가 너무 부담돼', '나 자신', 'study_pressure'),
    ('취업 준비가 길어져서 미래가 불안해', '나 자신', 'job_search'),
    ('구직 중인데 연락 오는 곳이 없어서 지쳤어', '직장', 'job_search'),
    ('보고서를 잘못 보냈어. 내가 너무 한심해', '직장', 'work_mistake'),
    ('업무에서 실수해서 팀장한테 혼났어', '직장', 'work_mistake'),
    ('친구가 상처 주고 사과도 안 해. 내가 왜 참아야 하지', '친구', 'rejected_apology'),
    ('사과를 받고 싶은데 상대가 잘못을 인정하지 않아', '연인', 'rejected_apology'),
    ('친구들이 내 외모를 놀려서 상처받았어', '친구', 'body_image'),
    ('가족이 살쪘다고 말해서 속상해', '가족', 'body_image'),
    ('타지로 이사해서 아는 사람이 없고 외로워', '나 자신', 'moving_loneliness'),
    ('전학 와서 적응하기 어렵고 혼자 있어', '친구', 'moving_loneliness'),
    ('기대했던 여행이 취소돼서 너무 아쉬워', '나 자신', 'plans_disrupted'),
    ('친구와 약속이 무산돼서 서운해', '친구', 'plans_disrupted'),
    ('출근길 지하철이 지연돼서 늦었어', '직장', 'commute'),
    ('버스를 놓쳤는데 차도 막혀서 짜증 나', '나 자신', 'commute'),
    ('고객이 욕을 하고 무례하게 말해서 너무 화가 났어', '고객', 'customer_hurt'),
    ('손님이 갑질을 하고 폭언했어', '직장', 'customer_hurt'),
    ('면접에서 또 탈락해서 실패한 기분이야', '직장', 'repeated_rejection'),
    ('시험에 떨어졌어. 공부를 더 했어야 했나 후회돼', '나 자신', 'failure'),
    ('미래가 너무 걱정되고 불안해서 잠이 안 와', '나 자신', 'anxiety'),
    ('친구에게 상처 주는 말을 해서 미안해. 사과하고 싶어', '친구', 'apology'),
    ('실수한 내가 싫고 자책하게 돼', '나 자신', 'self_kind'),
    ('누명을 써서 너무 억울해', '직장', 'unfair'),
    ('친구의 말에 서운하고 상처받았어', '친구', 'relationship_hurt'),
    ('남들과 비교하면 내가 뒤처지는 것 같아', '나 자신', 'comparison'),
    ('그 장면이 자꾸 떠올라서 곱씹고 있어', '나 자신', 'rumination'),
    ('어떤 선택을 해야 할지 모르겠어', '나 자신', 'decision'),
    ('나는 쓸모없는 사람인 것 같아', '나 자신', 'good_enough'),
    ('해야 할 일을 자꾸 미루고 시작을 못 하겠어', '나 자신', 'small_step'),
    ('그냥 너무 지쳤고 아무것도 하기 싫어', '나 자신', 'exhausted'),
    ('사람들 사이에 있어도 외로워', '나 자신', 'lonely'),
    ('정말 화가 나고 짜증이 나', '나 자신', 'anger_pause'),
    ('헤어진 건 아니고 답장이 안 와서 서운해', '연인', 'unanswered'),
    ('내 실수가 아니라 누명을 쓴 거야', '직장', 'unfair'),
    ('해고당한 건 아니고 야근 때문에 힘들어', '직장', 'overwork'),
    ('오늘 무슨 말을 해야 할지 모르겠어', '나 자신', 'general_support'),
    ('친구에게 전화하고 문자를 보냈어', '친구', 'general_support'),
    ('식욕이 없고 오늘 늦게 일어났어', '나 자신', 'general_support'),
    ('오늘 계속 비가 왔어', '나 자신', 'general_support'),
    ('고객에게 연락을 보냈어', '고객', 'general_support'),
    ('', '직장', 'general_support'),
    ('ㅁㄴㅇㄹ ㅠㅠ', '나 자신', 'general_support'),
  ];

  for (final (text, category, expected) in cases) {
    test('사연: $text', () {
      expect(recommendStory(text, category, 'comfort').id, expected);
      // Intensity labels and optional style must not replace the event.
      for (final style in ['comfort', 'reality', 'growth', 'random']) {
        expect(recommendStory(text, category, style, '많이 화남').id, expected,
            reason: style);
      }
      expect(recommendStory(text.replaceAll(' ', ''), category, 'comfort').id,
          expected,
          reason: '띄어쓰기 없는 입력');
    });
  }

  test('사연에 없는 상황을 카테고리와 기분만으로 단정하지 않는다', () {
    for (final category in ['직장', '고객', '친구', '연인', '가족', '나 자신']) {
      expect(recommendStory('오늘은 마음이 복잡해', category, 'random', '많이 화남').id,
          'general_support');
      expect(recommendStory('할머니가 돌아가셨어', category, 'growth', '많이 화남').id,
          'bereavement');
    }
  });

  test('추천 결과는 저장 가능한 기존 모델이며 임의 확장 문구를 붙이지 않는다', () {
    for (final (text, category, _) in cases) {
      final story = recommendStory(text, category, 'comfort');
      expect(storyDb, contains(story));
      expect(story.id, isNot(contains('__')));
      expect(
          story.body.length,
          lessThanOrEqualTo(
              detailedComfortStories.contains(story) ? 400 : 100));
    }
  });
}
