import 'package:chameulin/data/classified_comfort_stories.dart';
import 'package:chameulin/data/story_db.dart';
import 'package:chameulin/story_recommender.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cases = <(String, String, String)>[
    ('회복이 너무 더디고 답답해', '나 자신', 'slow_recovery'),
    ('자취하는데 몸살로 아파서 혼자 챙기기 힘들어', '나 자신', 'sick_alone'),
    ('통원 치료 일정이 계속 반복돼서 지쳐', '나 자신', 'treatment_routine'),
    ('수술을 앞두고 무서워', '나 자신', 'before_surgery'),
    ('아파서 여행을 취소했어. 너무 아쉬워', '나 자신', 'illness_missed_plans'),
    ('진단을 받고 앞으로의 생활이 막막해', '나 자신', 'diagnosis_adjustment'),
    ('승진에서 누락돼서 허탈해', '직장', 'promotion_passed'),
    ('인사평가가 낮게 나와서 억울해', '직장', 'unfair_review'),
    ('원치 않는 부서 이동을 통보받아서 막막해', '직장', 'unwanted_transfer'),
    ('재계약 확답이 없어서 불안해', '직장', 'contract_uncertainty'),
    ('회의에서 의견을 못 내서 아쉬워', '직장', 'meeting_anxiety'),
    ('인수인계 없이 일을 맡아서 어떻게 할지 막막해', '직장', 'no_handover'),
    ('모의고사 점수가 계속 제자리라 답답해', '나 자신', 'mock_plateau'),
    ('시험이 내일이라 긴장되고 불안해', '나 자신', 'exam_countdown'),
    ('시험장에서 머리가 하얘져 아는 것도 못 풀었어', '나 자신', 'exam_blank'),
    ('재수 중인데 이번에도 안 될까 부담돼', '나 자신', 'retake_burden'),
    ('퇴근하고 자격증 공부까지 하니까 너무 피곤해', '직장', 'work_and_study'),
    ('시험에 대한 부모님 기대가 너무 부담돼', '가족', 'exam_expectations'),
    ('엄마랑 아빠가 자꾸 싸워서 집이 불편해', '가족', 'parents_fighting'),
    ('가족 사이에서 중재하느라 양쪽 눈치를 봐', '가족', 'family_mediator'),
    ('시어머니가 생활에 간섭해서 불편해', '가족', 'inlaw_boundaries'),
    ('성인인데 부모님이 내 선택에 간섭해서 지쳐', '가족', 'adult_child_autonomy'),
    ('가족 생계를 책임지는 외벌이라 너무 버거워', '가족', 'family_provider'),
    ('아이가 학교에 적응하기 힘들어해서 걱정돼', '가족', 'child_school_worry'),
  ];
  for (final (text, category, id) in cases) {
    test('세부 상황: $text', () {
      for (final style in ['comfort', 'reality', 'growth', 'random']) {
        expect(recommendStory(text, category, style).id, id);
        expect(
            recommendStory(text.replaceAll(' ', ''), category, style, '많이 화남')
                .id,
            id);
      }
    });
  }

  const negativeCases = <(String, String)>[
    ('승진해서 기뻐', 'general_support'),
    ('인수인계를 잘 받았어', 'general_support'),
    ('회의에서 의견을 잘 냈어', 'general_support'),
    ('모의고사 점수가 올랐어', 'general_support'),
    ('시험은 내일인데 불안이 없어', 'general_support'),
    ('퇴근하고 공부해서 뿌듯해', 'general_support'),
    ('부모님과 산책했어', 'general_support'),
    ('시어머니와 즐겁게 식사했어', 'general_support'),
    ('아이가 학교에 잘 적응했어', 'general_support'),
    ('반려견이 죽었어. 너무 보고 싶어', 'pet_loss'),
    ('층간소음 때문에 스트레스를 너무많이 받아', 'neighbor_noise'),
    ('어제 야근했는데 오늘 새벽 출근하래. 지친다', 'short_rest_shift'),
  ];
  for (final (text, id) in negativeCases) {
    test('단순 언급 및 기존 상황: $text', () {
      expect(recommendStory(text, '나 자신', 'random').id, id);
    });
  }

  test('네 분류에 여섯 세부 상황씩 본문과 추천 사례를 갖춘다', () {
    expect(classifiedComfortScenarios.length, 24);
    expect(cases.map((e) => e.$3).toSet(),
        classifiedComfortStories.map((s) => s.id).toSet());
    for (final group in ['건강', '직장생활', '시험준비', '가족']) {
      final items =
          classifiedComfortScenarios.where((s) => s.group == group).toList();
      expect(items.length, 6);
      expect(items.map((s) => s.situation).toSet().length, 6);
    }
    for (final item in classifiedComfortScenarios) {
      expect(item.story.body.length, inInclusiveRange(120, 400));
      expect(storyDb, contains(item.story));
      expect(item.story.theme, startsWith('${item.group} · '));
    }
  });
}
