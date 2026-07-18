import '../models.dart';

const _storySeeds = <StoryItem>[
  StoryItem(
      id: 'self_kind',
      theme: '마음 돌봄',
      title: '오늘은 내 편이 되어 주세요',
      body:
          '실수한 뒤에는 이미 마음이 충분히 아픕니다. 그 위에 모진 말을 더 얹지 않아도 괜찮아요. 친한 사람이 같은 일을 겪었다면 해주었을 말을 오늘의 나에게도 건네보세요.',
      quote: '“많이 속상했지. 그래도 다시 해볼 수 있어.”',
      keywords: ['실수', '자책', '망쳤', '못했', '후회'],
      emotions: ['자책', '실수'],
      categories: ['나 자신', '직장'],
      styles: ['comfort']),
  StoryItem(
      id: 'exhausted',
      theme: '회복',
      title: '버티느라 지친 날',
      body:
          '아무것도 하기 싫은 건 게으른 것이 아니라 오래 애쓴 마음의 신호일 수 있어요. 오늘은 문제를 다 해결하는 날이 아니라, 나를 더 다치지 않게 쉬게 하는 날이어도 됩니다.',
      quote: '회복도 오늘 해야 할 중요한 일입니다.',
      keywords: ['지쳐', '피곤', '번아웃', '힘들', '의욕'],
      emotions: ['지침', '무기력'],
      categories: ['나 자신', '직장'],
      styles: ['comfort']),
  StoryItem(
      id: 'anger_pause',
      theme: '감정 돌봄',
      title: '화가 난 나를 먼저 안전하게',
      body:
          '화가 났다는 건 무언가 소중한 것이 침해되었다는 신호일 수 있어요. 감정을 틀렸다고 몰아세우지 말고, 답장이나 결정은 숨이 조금 고르게 돌아온 뒤로 미뤄도 괜찮습니다.',
      quote: '지금의 감정은 존중하고, 행동은 천천히 고르세요.',
      keywords: ['화나', '분노', '짜증', '카톡', '문자', '답장'],
      emotions: ['분노', '충동'],
      categories: ['직장', '고객', '친구', '연인', '가족'],
      styles: ['reality', 'comfort']),
  StoryItem(
      id: 'unfair',
      theme: '위로',
      title: '억울함이 오래 남는 이유',
      body:
          '억울한 일을 겪으면 자꾸 그 장면으로 돌아가는 것이 자연스러워요. 마음이 아직 “나는 그렇게 대우받을 사람이 아니었다”고 말하고 있는 거예요. 당신이 느낀 부당함을 먼저 믿어주세요.',
      quote: '상처받은 내 마음을 이해하는 것이 회복의 시작입니다.',
      keywords: ['억울', '무시', '부당', '오해', '차별'],
      emotions: ['억울함', '분노'],
      categories: ['직장', '고객', '친구', '가족'],
      styles: ['comfort']),
  StoryItem(
      id: 'comparison',
      theme: '마음 돌봄',
      title: '남의 속도에서 내려오기',
      body:
          '다른 사람의 좋은 장면과 내 힘든 하루를 나란히 놓으면 누구라도 작아집니다. 오늘은 남이 어디까지 갔는지보다 내가 무엇을 견디고 있는지 살펴봐 주세요.',
      quote: '내 삶은 남의 시간표로 늦어지지 않습니다.',
      keywords: ['비교', '뒤처', '부럽', '열등', '늦'],
      emotions: ['불안', '자책'],
      categories: ['나 자신', '직장'],
      styles: ['comfort', 'growth']),
  StoryItem(
      id: 'lonely',
      theme: '연결',
      title: '외로운 밤에',
      body:
          '사람들 사이에 있어도 마음이 닿지 않으면 외로울 수 있어요. 외로움은 당신에게 문제가 있다는 증거가 아니라 연결이 필요하다는 신호입니다. 짧은 안부 하나를 먼저 보내도 괜찮아요.',
      quote: '당신은 혼자 견뎌야만 하는 사람이 아닙니다.',
      keywords: ['외로', '혼자', '고독', '아무도', '연락'],
      emotions: ['외로움', '슬픔'],
      categories: ['나 자신', '친구', '연인', '가족'],
      styles: ['comfort']),
  StoryItem(
      id: 'anxiety',
      theme: '마음 돌봄',
      title: '아직 오지 않은 일을 걱정할 때',
      body:
          '불안은 나를 지키려는 마음이 너무 멀리까지 내다볼 때 커집니다. 미래 전체를 해결하려 하지 말고, 지금 발이 닿은 곳에서 할 수 있는 한 가지로 돌아와 보세요.',
      quote: '모르는 미래에는 나쁜 일뿐 아니라 좋은 가능성도 있습니다.',
      keywords: ['불안', '걱정', '두려', '미래', '어떡'],
      emotions: ['불안'],
      categories: ['나 자신', '직장', '가족'],
      styles: ['comfort', 'reality']),
  StoryItem(
      id: 'failure',
      theme: '성장',
      title: '잘되지 않았던 오늘',
      body:
          '노력한 만큼 결과가 나오지 않으면 허탈한 것이 당연해요. 하지만 이번 결과는 당신의 능력 전체가 아니라 한 시도의 기록입니다. 무엇이 맞지 않았는지 하나만 찾고 나머지는 내려놓아도 됩니다.',
      quote: '결과 하나가 당신을 설명하게 두지 마세요.',
      keywords: ['실패', '탈락', '시험', '면접', '성과', '거절'],
      emotions: ['실망', '자책'],
      categories: ['나 자신', '직장'],
      styles: ['growth', 'comfort']),
  StoryItem(
      id: 'relationship_hurt',
      theme: '관계',
      title: '가까운 사람에게 받은 상처',
      body:
          '가까운 사람의 말은 기대가 있었던 만큼 더 깊게 아픕니다. 괜찮은 척 서둘러 넘기지 않아도 돼요. 어떤 말이 아팠고 앞으로 무엇을 지켜주길 바라는지 천천히 정리해보세요.',
      quote: '사랑하는 관계에서도 내 마음의 경계는 소중합니다.',
      keywords: ['연인', '가족', '친구', '상처', '서운', '배신'],
      emotions: ['서운함', '슬픔'],
      categories: ['연인', '가족', '친구'],
      styles: ['comfort', 'reality']),
  StoryItem(
      id: 'customer_hurt',
      theme: '존중',
      title: '함부로 대하는 말을 들었을 때',
      body:
          '누군가의 무례를 견뎠다고 해서 그 말이 옳아지는 것은 아닙니다. 일을 잘 해내는 것과 모욕까지 참아야 하는 것은 다른 문제예요. 가능하다면 기록하고, 혼자 감당하지 말고 도움을 요청하세요.',
      quote: '상대의 무례가 당신의 가치를 정하지 못합니다.',
      keywords: ['고객', '손님', '욕', '무례', '갑질', '민원'],
      emotions: ['억울함', '분노'],
      categories: ['고객', '직장'],
      styles: ['reality', 'comfort']),
  StoryItem(
      id: 'rumination',
      theme: '마음 돌봄',
      title: '같은 장면이 자꾸 떠오를 때',
      body:
          '마음은 끝내지 못한 일을 해결하려고 같은 장면을 반복합니다. 하지만 생각을 오래 한다고 답이 가까워지는 것은 아니에요. 종이에 한 번 적고, 오늘 다시 생각할 시간을 따로 정해두세요.',
      quote: '생각에서 잠시 나오는 것도 문제를 다루는 방법입니다.',
      keywords: ['계속', '곱씹', '하루종일', '반복', '머리'],
      emotions: ['반추', '불안'],
      categories: ['나 자신', '직장'],
      styles: ['reality', 'comfort']),
  StoryItem(
      id: 'apology',
      theme: '관계',
      title: '미안함을 전하고 싶을 때',
      body:
          '진심 어린 사과는 나를 낮추는 일이 아니라 관계를 소중히 여긴다는 표현입니다. 이유를 길게 설명하기보다 무엇이 미안한지, 상대가 어떻게 느꼈을지, 앞으로 무엇을 바꿀지 담아보세요.',
      quote: '변명보다 이해받은 마음이 관계를 다시 잇습니다.',
      keywords: ['미안', '사과', '잘못', '후회', '화해'],
      emotions: ['미안함', '자책'],
      categories: ['연인', '가족', '친구', '직장'],
      styles: ['reality', 'growth']),
  StoryItem(
      id: 'decision',
      theme: '선택',
      title: '결정을 못 내리겠을 때',
      body:
          '중요한 선택 앞에서 망설이는 건 그만큼 진지하게 살고 있다는 뜻이에요. 완벽한 답을 찾기보다 내가 감당할 수 있는 선택, 나를 덜 잃게 하는 선택부터 살펴보세요.',
      quote: '확신이 생겨야 움직이는 것이 아니라, 움직이며 확신을 만들어가기도 합니다.',
      keywords: ['결정', '선택', '고민', '망설', '모르겠'],
      emotions: ['불안', '혼란'],
      categories: ['나 자신', '직장', '연인'],
      styles: ['growth', 'comfort']),
  StoryItem(
      id: 'small_step',
      theme: '다시 시작',
      title: '아무것도 손에 잡히지 않을 때',
      body:
          '해야 할 일이 클수록 마음은 시작조차 피하고 싶어집니다. 물 한 잔 마시기, 파일 열기, 한 줄 쓰기처럼 너무 작아서 실패하기 어려운 행동부터 해보세요.',
      quote: '작은 시작은 마음에게 “다시 움직일 수 있다”고 알려줍니다.',
      keywords: ['시작', '미루', '막막', '귀찮', '아무것도'],
      emotions: ['무기력', '불안'],
      categories: ['나 자신', '직장'],
      styles: ['growth', 'reality']),
  StoryItem(
      id: 'good_enough',
      theme: '자기 존중',
      title: '잘해야만 괜찮은 사람은 아니에요',
      body:
          '성과가 없던 날에도 당신은 존중받을 사람입니다. 오늘의 쓸모를 증명하느라 지쳤다면 잠시 멈춰도 괜찮아요. 존재의 가치는 하루의 생산량으로 계산되지 않습니다.',
      quote: '무언가를 해내기 전에도 당신은 이미 소중합니다.',
      keywords: ['쓸모', '가치', '무능', '성과', '인정'],
      emotions: ['자책', '무기력'],
      categories: ['나 자신', '직장'],
      styles: ['comfort']),
];

const _storyExpansions = <({
  String id,
  String lead,
  String intro,
  String action,
  String quote,
})>[
  (
    id: 'breath',
    lead: '숨을 고르고',
    intro: '먼저 천천히 숨을 세 번 쉬어보세요.',
    action: '숨이 고르게 돌아온 뒤 지금 필요한 한 가지를 골라보세요.',
    quote: '숨을 고르는 동안 마음은 다음 걸음을 준비합니다.'
  ),
  (
    id: 'name',
    lead: '마음에 이름을 붙이며',
    intro: '지금 느끼는 감정을 한 단어로 불러보는 것부터 시작해도 좋아요.',
    action: '감정의 이름을 적고 그 감정이 바라는 것을 한 줄로 덧붙여보세요.',
    quote: '이름을 붙인 감정은 다룰 수 있는 마음이 됩니다.'
  ),
  (
    id: 'distance',
    lead: '한 걸음 떨어져',
    intro: '이 일을 가까운 친구의 이야기라고 생각해보세요.',
    action: '친구에게 건넬 말을 오늘의 나에게도 같은 목소리로 들려주세요.',
    quote: '따뜻한 거리는 마음을 더 선명하게 보여줍니다.'
  ),
  (
    id: 'body',
    lead: '몸의 신호를 살피며',
    intro: '마음보다 먼저 굳어진 어깨와 턱의 힘을 알아차려보세요.',
    action: '몸의 긴장을 조금 풀고 물 한 잔을 마신 뒤 다시 생각해보세요.',
    quote: '몸을 돌보는 일은 마음을 설득하는 가장 조용한 방법입니다.'
  ),
  (
    id: 'today',
    lead: '오늘만큼만',
    intro: '앞으로의 모든 날이 아니라 오늘 하루만 바라봐도 괜찮아요.',
    action: '오늘 안에 할 수 있는 가장 작은 선택 하나만 정해보세요.',
    quote: '오늘을 건너는 힘이 내일의 길을 만듭니다.'
  ),
  (
    id: 'fact',
    lead: '사실과 생각을 나누며',
    intro: '일어난 사실과 마음속 해석을 잠시 두 칸으로 나누어보세요.',
    action: '확실한 사실 하나와 아직 모르는 것 하나를 구분해 적어보세요.',
    quote: '사실을 바라보면 걱정이 차지한 자리에 여백이 생깁니다.'
  ),
  (
    id: 'boundary',
    lead: '내 경계를 지키며',
    intro: '참는 것과 나를 지키는 것은 같은 일이 아니에요.',
    action: '받아들일 수 있는 것과 어려운 것을 짧고 분명하게 정리해보세요.',
    quote: '건강한 경계는 관계를 밀어내는 벽이 아니라 지키는 선입니다.'
  ),
  (
    id: 'pause',
    lead: '잠시 멈춘 뒤',
    intro: '지금 바로 답하거나 결정하지 않아도 괜찮아요.',
    action: '가능하다면 십 분의 여유를 만들고 그 뒤에 행동을 선택해보세요.',
    quote: '멈춤은 포기가 아니라 더 나은 방향을 고르는 시간입니다.'
  ),
  (
    id: 'support',
    lead: '혼자 두지 말고',
    intro: '이 마음을 혼자 감당해야 한다는 규칙은 어디에도 없어요.',
    action: '믿을 수 있는 사람 한 명에게 지금 필요한 도움을 구체적으로 말해보세요.',
    quote: '도움을 청하는 순간 외로웠던 짐의 무게가 나뉩니다.'
  ),
  (
    id: 'record',
    lead: '한 줄로 기록하며',
    intro: '복잡한 마음을 완벽히 설명하려 애쓰지 않아도 돼요.',
    action: '가장 마음에 남는 장면과 그때의 바람을 한 줄씩 적어보세요.',
    quote: '기록은 흩어진 마음이 돌아올 작은 자리를 만듭니다.'
  ),
  (
    id: 'kindness',
    lead: '나를 다그치지 않고',
    intro: '이미 충분히 애쓴 사람에게 더 큰 채찍은 필요하지 않아요.',
    action: '오늘의 나에게 허락해주고 싶은 것을 하나 정해보세요.',
    quote: '다정함은 느슨함이 아니라 다시 움직일 힘입니다.'
  ),
  (
    id: 'choice',
    lead: '내가 고를 수 있는 것부터',
    intro: '바꿀 수 없는 것과 지금 선택할 수 있는 것을 나누어보세요.',
    action: '내 손에 남아 있는 가장 작은 선택에 에너지를 모아보세요.',
    quote: '작은 선택은 흔들리는 하루에 방향을 돌려줍니다.'
  ),
  (
    id: 'rest',
    lead: '회복을 먼저 두고',
    intro: '지친 마음으로 내린 판단은 세상을 더 어둡게 보이게 할 수 있어요.',
    action: '잠깐 눈을 감거나 짧게 걸으며 판단보다 회복을 먼저 챙겨보세요.',
    quote: '쉼은 해야 할 일을 미루는 시간이 아니라 나를 되찾는 시간입니다.'
  ),
  (
    id: 'tomorrow',
    lead: '내일의 나에게 맡기며',
    intro: '오늘 해결되지 않은 일이 실패를 뜻하지는 않아요.',
    action: '내일 다시 볼 시간과 첫 행동을 정하고 오늘의 고민은 내려놓아보세요.',
    quote: '내일로 미룬 걱정에는 다시 만날 약속이 필요합니다.'
  ),
  (
    id: 'evidence',
    lead: '해낸 일을 기억하며',
    intro: '마음은 어려울 때 못한 일만 크게 보여주곤 해요.',
    action: '최근에 버티거나 해낸 작은 일 세 가지를 떠올려보세요.',
    quote: '지나온 증거는 앞으로 갈 힘을 조용히 증명합니다.'
  ),
  (
    id: 'pace',
    lead: '내 속도를 존중하며',
    intro: '빠른 답보다 나에게 맞는 속도가 더 오래갑니다.',
    action: '비교의 기준을 내려놓고 어제의 나보다 한 걸음만 정해보세요.',
    quote: '나의 속도로 가는 길도 분명 앞으로 가는 길입니다.'
  ),
  (
    id: 'need',
    lead: '진짜 필요를 묻고',
    intro: '감정 아래에는 이해받고 싶거나 쉬고 싶은 바람이 숨어 있어요.',
    action: '지금 가장 필요한 것이 위로인지 해결인지 휴식인지 골라보세요.',
    quote: '필요를 알아차리면 마음은 막연함에서 방향으로 움직입니다.'
  ),
  (
    id: 'release',
    lead: '내 몫만 남기며',
    intro: '모든 책임과 모든 감정을 혼자 품을 필요는 없어요.',
    action: '내 책임이 아닌 부분을 문장으로 구분하고 마음에서 내려놓아보세요.',
    quote: '내 몫을 아는 사람은 불필요한 무게를 내려놓을 수 있습니다.'
  ),
  (
    id: 'next',
    lead: '다음 장면을 그리며',
    intro: '지금의 장면이 이야기의 마지막은 아니에요.',
    action: '상황이 조금 나아진 다음 장면과 그곳으로 가는 첫 행동을 떠올려보세요.',
    quote: '다음 장면을 상상하는 마음은 이미 그쪽으로 움직이고 있습니다.'
  ),
];

final storyDb = <StoryItem>[
  for (final seed in _storySeeds) ...[
    seed,
    for (final expansion in _storyExpansions)
      StoryItem(
        id: '${seed.id}__${expansion.id}',
        theme: seed.theme,
        title: '${expansion.lead} ${seed.title}',
        body: '${expansion.intro} ${seed.body} ${expansion.action}',
        quote: expansion.quote,
        keywords: seed.keywords,
        emotions: seed.emotions,
        categories: seed.categories,
        styles: seed.styles,
      ),
  ],
];
