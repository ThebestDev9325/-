import 'data/story_db.dart';
import 'data/daily_stress_stories.dart';
import 'data/classified_comfort_stories.dart';
import 'models.dart';

class _SituationRule {
  final String id;
  final int priority;
  final RegExp signal;
  final RegExp? context;
  final RegExp? excluded;

  _SituationRule(this.id, this.priority, String signal,
      [String? context, String? excluded])
      : signal = RegExp(signal),
        context = context == null ? null : RegExp(context),
        excluded = excluded == null ? null : RegExp(excluded);

  bool matches(String text) =>
      signal.hasMatch(text) &&
      (context == null || context!.hasMatch(text)) &&
      !(excluded?.hasMatch(text) ?? false);
}

// A concrete event outranks a general feeling. Context gates prevent a mere
// mention of a person, phone, exam, etc. from inventing an event.
final _rules = <_SituationRule>[
  _SituationRule('credit_taken', 4, r'가로채|가로챘|뺏|빼앗|자기가했다고|자신이했다고',
      r'공로|성과|보고서|업무|프로젝트|내가한일'),
  _SituationRule(
      'pet_loss', 5, r'무지개다리|떠나보냈|떠나보내|세상을떠|죽었|죽어|죽음|잃었', r'강아지|고양이|반려|멍멍|댕댕'),
  _SituationRule(
      'bereavement',
      4,
      r'돌아가셨|돌아가신|돌아가셔|별세|장례|사별|세상을떠|유산했|유산을|떠나보냈|죽었',
      r'엄마|아빠|어머니|아버지|부모|할머니|할아버지|친구|남편|아내|동생|언니|오빠|누나|형|아이|아기|가족'),
  _SituationRule('bullying', 4, r'왕따|따돌림|따돌려|따돌리|집단괴롭힘|괴롭힘을당|괴롭혀'),
  _SituationRule('job_loss', 4, r'해고|정리해고|권고사직|실직|일자리를잃|계약종료|계약이끝|회사에서잘렸'),
  // Specific combinations precede their broader families. Both the event
  // and its distinguishing detail must be present; category alone is not one.
  _SituationRule(
      'short_rest_shift',
      4,
      r'(새벽|이른아침|아침일찍|몇시간못자|잠도못자).*출근|출근.*(새벽|이른아침|아침일찍)',
      r'야근|밤늦게.*일|늦게.*퇴근|늦은시간까지.*일',
      r'(새벽|이른아침|아침일찍)출근(은|을|이)?(안|없|하지않)'),
  _SituationRule('sick_at_work', 4, r'아픈데|아파도|아파서|몸살|열이나|열이났',
      r'출근|일해야|일을해야|못쉬|쉬지못|병가.*못'),
  _SituationRule('after_hours_work', 4, r'퇴근후|퇴근하고|퇴근했|쉬는날|휴일|주말|밤늦게',
      r'업무연락|업무카톡|일하라는연락|회사.*연락|상사.*연락|팀장.*연락'),
  _SituationRule('leave_guilt', 4, r'연차|휴가|휴직', r'눈치|못쓰|못쉬|미안|죄책|거절|안된'),
  _SituationRule(
      'unfair_workload', 4, r'업무|일을|일이|뒷정리', r'떠넘|나만|나한테만|혼자.*맡|늘내몫|내게만'),
  _SituationRule(
      'public_reprimand', 4, r'사람들앞|직원들앞|다들보는|공개적으로|회의중', r'혼났|혼나|면박|망신|꾸중|질책'),
  _SituationRule('changing_instructions', 4, r'지시|요구|기준|방향|시키는대로',
      r'자꾸바뀌|계속바뀌|또바뀌|말이바뀌|다시하라|다르게하라'),
  _SituationRule('work_unrecognized', 4, r'회사|업무|프로젝트|직장|일했|야근',
      r'알아주지않|안알아|몰라줘|인정.*못받|수고.*말.*없'),
  _SituationRule('new_job_overwhelmed', 4, r'신입|입사한지|첫출근|새직장',
      r'질문.*눈치|물어.*눈치|모르는게|모르는일|서툴|적응.*힘'),
  _SituationRule('customer_forced_apology', 4,
      r'(?=.*(고객|손님|민원))(?=.*사과)(?=.*(내잘못이아|잘못한게없|잘못도없|잘못이없))'),
  _SituationRule('solo_parenting', 4, r'독박육아|육아.*혼자|혼자.*육아|아이.*혼자.*돌보'),
  _SituationRule('parent_guilt', 4,
      r'(?=.*(아이|아기|아들|딸))(?=.*(소리쳤|소리질렀|화를냈))(?=.*(미안|후회|자책|마음이아))'),
  _SituationRule('caregiver_guilt', 4, r'간병|병간호|치매.*돌보', r'쉬고싶|벗어나고싶|미안|죄책'),
  _SituationRule('unequal_housework', 4, r'집안일|가사|설거지|청소',
      r'나만|혼자|내몫|나한테만|아무도안|도와주지않|안도와'),
  _SituationRule('family_comparison', 4, r'엄마|아빠|부모|가족|어머니|아버지',
      r'비교하|비교해|비교해서|비교당|비교를|비교했|남의집.*비교|다른집.*비교'),
  _SituationRule('marriage_pressure', 4, r'부모|엄마|아빠|가족|친척|명절',
      r'결혼.*(언제|재촉|압박|잔소리|강요)|언제.*결혼|결혼하라고'),
  _SituationRule('dismissed_feelings', 4, r'힘들다고|고민을|털어놨|속상하다고',
      r'예민|별일아니|별거아니|다그렇게|유난|대수롭지|넘겨'),
  _SituationRule(
      'one_sided_contact', 4, r'연락|약속', r'나만먼저|늘내가먼저|항상내가먼저|나만하|나만잡'),
  _SituationRule(
      'last_minute_cancel', 4, r'약속', r'(직전|당일|갑자기).*취소|취소.*(직전|당일|갑자기)'),
  _SituationRule(
      'excluded_friends', 4, r'친구', r'나빼고.*(만났|모였|놀았)|나없이.*(만났|모였)|나만.*초대.*못'),
  _SituationRule('broken_promise', 4, r'약속', r'또안지|또어겼|자꾸어|계속어|매번어|반복.*안지'),
  _SituationRule(
      'breakup_daily_absence', 5, r'헤어졌|헤어진|이별', r'연락하고싶|전화하고싶|습관처럼|먼저알려주고싶'),
  _SituationRule(
      'grief_anniversary', 5, r'기일|돌아가신.*생일|떠나보낸.*생일', r'그리|보고싶|빈자리|생각나|슬퍼|힘들'),
  _SituationRule('repeated_rejection', 4, r'불합격|탈락|떨어졌', r'또|계속|번이나|번째|연속'),
  _SituationRule('effort_without_grades', 4,
      r'(?=.*(공부|시험))(?=.*(열심히|밤새|많이했|노력))(?=.*(점수|성적))(?=.*(안나|낮|떨어|못|실망))'),
  _SituationRule('peers_moving_ahead', 4,
      r'(?=.*(친구|동기|주변))(?=.*취업)(?=.*(나만|뒤처|뒤쳐|축하.*불안|축하.*슬))'),
  _SituationRule('payday_bills', 4, r'월급|급여', r'남는게없|남지않|들어오자마자|스쳐|다빠져|전부빠져'),
  _SituationRule('unpaid_wages', 4, r'월급|급여|임금', r'밀려|밀렸|체불|못받|안들어|미지급'),
  _SituationRule(
      'unexpected_expense', 4, r'갑자기|예상치못|예상밖|생각지못', r'큰돈|지출|수리비|병원비|치료비'),
  _SituationRule('waiting_test_results', 4, r'검사결과|검진결과', r'기다|나오기전|아직안나'),
  _SituationRule(
      'chronic_pain_unseen', 4, r'통증|만성|계속아|오래아', r'멀쩡|엄살|안아파보|안아픈줄|티가안'),
  _SituationRule('lonely_birthday', 4, r'생일', r'외로|외롭|연락.*없|아무도|기억.*못|혼자'),
  _SituationRule('breakup', 4, r'이별|헤어졌|헤어지자|헤어진|차였|이혼|결별'),
  _SituationRule('betrayal', 4, r'배신|바람피|바람을피|외도|불륜|거짓말',
      r'친구|연인|남친|여친|남자친구|여자친구|애인|남편|아내|배우자|믿었|믿었던'),
  _SituationRule('rejected_apology', 4,
      r'사과(도|를|는|조차)?(안|하지않|못받|없)|사과받고싶|사과를받고싶|사과해주지|사과하라고'),
  _SituationRule('work_mistake', 4, r'실수|잘못보냈|잘못보내|누락|망쳤',
      r'업무|보고서|회사|직장|프로젝트|상사|팀장|부장|거래처'),
  _SituationRule(
      'customer_hurt', 4, r'욕을|욕하|욕설|욕먹|무례|갑질|폭언|모욕|진상', r'고객|손님|민원|상담|응대|서비스'),
  for (final scenario in dailyStressScenarios)
    _SituationRule(scenario.story.id, 4, scenario.signal, scenario.context,
        scenario.excluded),
  for (final scenario in classifiedComfortScenarios)
    _SituationRule(scenario.story.id, 4, scenario.signal, scenario.context,
        scenario.excluded),
  _SituationRule('workplace_hurt', 3, r'혼났|혼나|무시|면박|소리질|모욕|폭언|욕설|욕을|갈등|막말|꾸중',
      r'상사|팀장|부장|동료|회사|직장|사장|선배'),
  _SituationRule('money_pressure', 3,
      r'생활비|월세|빚|대출|카드값|적자|돈이없|돈없|돈걱정|경제적|금전|급여밀|월급이밀|월급을못|임금체불'),
  _SituationRule('overwork', 3, r'야근|과로|업무과다|일이너무많|일이쌓|업무가쌓|업무량|주말출근|휴일출근'),
  _SituationRule(
      'caregiving', 3, r'간병|병간호|병수발|치매|돌보', r'간병|병간호|병수발|치매|아픈|환자|병원'),
  _SituationRule(
      'parenting', 3, r'육아|독박육아|밤수유|육아휴직|아이.*떼를|아기.*울|아이.*돌보|아기.*돌보'),
  _SituationRule('family_pressure', 3, r'잔소리|강요|간섭|결혼압박|결혼하라고|기대.*부담|비교',
      r'부모|엄마|아빠|어머니|아버지|가족|시댁|시어머니|장모'),
  _SituationRule(
      'couple_conflict', 3, r'싸웠|싸우|다퉜|다투|말다툼|집안일|가사분담', r'남편|아내|배우자'),
  _SituationRule('unanswered', 3,
      r'읽씹|안읽씹|잠수탔|연락두절|(답장|연락|답)(이|을|도|조차)?(안와|안오|없|기다|하지않)|답장을안|연락을안'),
  _SituationRule(
      'health_worry', 3, r'검사결과|검진결과|진단받|진단을받|수술|입원|통증|몸이아|몸살|두통|병원.*걱정'),
  _SituationRule(
      'body_image', 3, r'외모|생김새|몸매|뚱뚱|못생겼|살쪘', r'놀|평가|비교|상처|싫|말|놀림|자신'),
  _SituationRule('moving_loneliness', 3, r'이사|전학|유학|타지|해외생활|새로운환경|낯선곳',
      r'외로|혼자|적응|낯설|친구가없|아는사람'),
  _SituationRule(
      'commute', 3, r'지하철|버스|기차|출근길|퇴근길|차가', r'지연|놓쳤|막혀|막히|늦|만원|힘들|지쳐'),
  _SituationRule('plans_disrupted', 3, r'약속|여행|일정|계획', r'취소|무산|틀어|망쳤|어긋'),
  _SituationRule(
      'failure', 3, r'탈락|불합격|낙방|떨어졌|망쳤|실패', r'면접|시험|입시|지원|취업|공모|성과|실패'),
  _SituationRule('job_search', 2, r'취준|취업준비|구직|입사지원|취직이안|취업이안|일자리를찾'),
  _SituationRule(
      'study_pressure', 2, r'공부|과제|수험|수능|성적|시험', r'부담|힘들|압박|스트레스|집중|지쳐|걱정|불안'),
  _SituationRule('apology', 3, r'사과하고싶|사과를하고싶|화해하고싶'),
  _SituationRule('apology', 2, r'내가잘못|내잘못|미안'),
  _SituationRule('self_kind', 2, r'실수|자책|망쳤|못했|후회'),
  _SituationRule('unfair', 2, r'억울|부당|누명|무시당|차별|오해받|오해를받'),
  _SituationRule('relationship_hurt', 2, r'서운|섭섭|상처|다퉜|싸웠',
      r'친구|가족|연인|남친|여친|엄마|아빠|애인|언니|동생|오빠'),
  _SituationRule('comparison', 2, r'비교|뒤처|뒤쳐|부럽|열등'),
  _SituationRule('rumination', 2, r'곱씹|자꾸생각나|계속생각나|계속떠올|자꾸떠올|머릿속에서떠나지'),
  _SituationRule('decision', 2, r'결정|선택|망설', r'못|어려|고민|망설|모르겠'),
  _SituationRule('good_enough', 2, r'쓸모없|쓸모가없|가치없|가치가없|무능|인정받지못'),
  _SituationRule('small_step', 2, r'미루|시작하기어|시작을못|손에안잡|손에잡히지'),
  _SituationRule('anxiety', 1, r'불안|걱정|두려|무서|막막'),
  _SituationRule('exhausted', 1, r'지쳐|지쳤|피곤|번아웃|무기력|의욕이없|의욕없|아무것도하기싫'),
  _SituationRule('lonely', 1, r'외로|외롭|고독|아무도없|혼자인기분'),
  _SituationRule('anger_pause', 1, r'화나|화났|화가나|화가났|분노|짜증|열받'),
  _SituationRule('sleep_trouble', 1, r'불면|잠이안|잠을못|잠들지못|잠이오지않'),
];

final _baseStories = <String, StoryItem>{
  for (final story in storyDb)
    if (!story.id.contains('__')) story.id: story,
};

String _normalize(String text) {
  var normalized = text.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  // Remove explicitly denied situations before matching. Do not strip whole
  // sentences: a real event may follow the denial in the same sentence.
  normalized = normalized.replaceAll(
    RegExp(
        r'(이별|헤어진|헤어졌|이혼|해고|실직|실수|실패|배신|외도|왕따|따돌림|야근|사별|불안|걱정|외로움|화난)(한|을당한|당한)?(건|것은|게|것|은|는|이|가)?(아니(?:라|고|야|에요|었어|지만)?|없(?:어|다|지만|고)?)'),
    '',
  );
  // Worrying that an event might happen is not evidence that it happened.
  normalized = normalized.replaceAll(
    RegExp(r'(실수|실패|해고|이별|이혼)(할까|당할까|하면|하게될까)'),
    '',
  );
  return normalized;
}

StoryItem recommendStory(
  String text,
  String category,
  String style, [
  String mood = '',
]) {
  final input = _normalize(text);
  _SituationRule? best;
  var bestPreference = -1;
  for (final rule in _rules) {
    if (!rule.matches(input)) continue;
    final story = _baseStories[rule.id]!;
    // Preferences only break ties; they cannot supply missing text evidence.
    final preference = (story.categories.contains(category) ? 2 : 0) +
        (style != 'random' && story.styles.contains(style) ? 1 : 0);
    if (best == null ||
        rule.priority > best.priority ||
        (rule.priority == best.priority && preference > bestPreference)) {
      best = rule;
      bestPreference = preference;
    }
  }
  // The mood picker describes intensity (e.g. "많이 화남"), not the event.
  // It must not turn an unrecognized story into an anger or apology scenario.
  return _baseStories[best?.id ?? 'general_support']!;
}
