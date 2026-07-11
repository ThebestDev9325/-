class StoryItem {
  final String id;
  final String theme;
  final String title;
  final String body;
  final String quote;
  final List<String> keywords;
  final List<String> emotions;
  final List<String> categories;
  final List<String> styles;

  const StoryItem({
    required this.id,
    required this.theme,
    required this.title,
    required this.body,
    required this.quote,
    this.keywords = const [],
    this.emotions = const [],
    this.categories = const [],
    this.styles = const [],
  });
}

class PositiveStory {
  final String icon;
  final String title;
  final String body;
  final String quote;

  const PositiveStory({
    required this.icon,
    required this.title,
    required this.body,
    required this.quote,
  });

  String get richBody {
    final detail = switch (icon) {
      '🌱' => '자연의 변화는 눈에 바로 보이지 않아도 매일 조금씩 이어집니다. 서두르지 말고 오늘 내가 할 수 있는 작은 선택 하나에 마음을 두어보세요.',
      '🧠' => '마음의 습관은 큰 결심보다 작은 반복에서 바뀌기 시작합니다. 지금의 감정을 판단하지 말고 알아차리는 것만으로도 한 걸음 앞으로 나아갈 수 있습니다.',
      '👤' => '그 삶이 특별한 이유는 힘든 순간이 없었기 때문이 아니라, 그래도 다시 자신의 길을 선택했기 때문입니다. 우리도 완벽해지려기보다 다시 시작하는 용기를 택할 수 있습니다.',
      '📚' => '오래된 이야기가 오늘까지 남은 것은 우리의 일상에도 여전히 적용할 수 있는 지혜가 담겨 있기 때문입니다. 이 메시지를 오늘의 상황에 비추어 나만의 답을 찾아보세요.',
      _ => '이 이야기가 건네는 메시지는 거창한 변화보다 오늘 할 수 있는 작은 선택을 소중히 여기자는 것입니다. 잠시 숨을 고르고, 지금의 나에게 필요한 한 걸음을 천천히 찾아보세요.',
    };
    return '$body\n\n$detail';
  }
}

class EmotionRecord {
  final String id;
  final DateTime createdAt;
  final String category;
  final String moodEmoji;
  final String moodLabel;
  final String text;
  final StoryItem story;
  final bool shared;

  const EmotionRecord({
    required this.id,
    required this.createdAt,
    required this.category,
    required this.moodEmoji,
    required this.moodLabel,
    required this.text,
    required this.story,
    this.shared = false,
  });
}

class SharedPost {
  final String id;
  final String ownerId;
  final String category;
  final String text;
  final String moodEmoji;
  final DateTime createdAt;
  final List<int> reactions;
  int? myReaction;
  int reportCount;

  SharedPost({
    required this.id,
    required this.ownerId,
    required this.category,
    required this.text,
    required this.moodEmoji,
    required this.createdAt,
    List<int>? reactions,
    this.myReaction,
    this.reportCount = 0,
  }) : reactions = reactions ?? [0, 0, 0];
}
