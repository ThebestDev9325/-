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

class AdSlotConfig {
  final String id;
  final String title;
  final String url;
  final bool enabled;
  final bool youtube;
  final int backgroundStart;
  final int backgroundEnd;

  const AdSlotConfig({
    required this.id,
    required this.title,
    required this.url,
    this.enabled = true,
    this.youtube = false,
    required this.backgroundStart,
    required this.backgroundEnd,
  });

  static const leftFallback = AdSlotConfig(
    id: 'left',
    title: '조용한 밤의 위로',
    url: 'https://www.youtube.com/@slowhug',
    youtube: true,
    backgroundStart: 0xFF17283A,
    backgroundEnd: 0xFF526B56,
  );

  static const rightFallback = AdSlotConfig(
    id: 'right',
    title: '참을인',
    url: 'https://www.youtube.com/@ThebestDev93',
    youtube: true,
    backgroundStart: 0xFF1D2733,
    backgroundEnd: 0xFF53606B,
  );
}

class SharedPost {
  final String id;
  final String ownerId;
  final String category;
  final String text;
  final String moodEmoji;
  final String moodLabel;
  final DateTime createdAt;
  final List<int> reactions;
  int? myReaction;
  int reportCount;
  bool reportedByMe;

  SharedPost({
    required this.id,
    required this.ownerId,
    required this.category,
    required this.text,
    required this.moodEmoji,
    this.moodLabel = '',
    required this.createdAt,
    List<int>? reactions,
    this.myReaction,
    this.reportCount = 0,
    this.reportedByMe = false,
  }) : reactions = reactions ?? [0, 0, 0];
}
