import 'data/story_db.dart';
import 'models.dart';

class _SituationRule {
  final String id;
  final int priority;
  final RegExp signal;
  final RegExp? context;

  _SituationRule(this.id, this.priority, String signal, [String? context])
      : signal = RegExp(signal),
        context = context == null ? null : RegExp(context);

  bool matches(String text) =>
      signal.hasMatch(text) && (context == null || context!.hasMatch(text));
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
  _SituationRule('breakup', 4, r'이별|헤어졌|헤어지자|헤어진|차였|이혼|결별'),
  _SituationRule('betrayal', 4, r'배신|바람피|바람을피|외도|불륜|거짓말',
      r'친구|연인|남친|여친|남자친구|여자친구|애인|남편|아내|배우자|믿었|믿었던'),
  _SituationRule('rejected_apology', 4,
      r'사과(도|를|는|조차)?(안|하지않|못받|없)|사과받고싶|사과를받고싶|사과해주지|사과하라고'),
  _SituationRule('work_mistake', 4, r'실수|잘못보냈|잘못보내|누락|망쳤',
      r'업무|보고서|회사|직장|프로젝트|상사|팀장|부장|거래처'),
  _SituationRule(
      'customer_hurt', 4, r'욕을|욕하|욕설|욕먹|무례|갑질|폭언|모욕|진상', r'고객|손님|민원|상담|응대|서비스'),
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
