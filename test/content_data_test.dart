import 'package:chameulin/data/positive_stories.dart';
import 'package:chameulin/data/daily_quotes.dart';
import 'package:chameulin/data/story_db.dart';
import 'package:chameulin/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('긍정 콘텐츠는 충분한 수와 고유한 본문을 가진다', () {
    expect(positiveStories.length, 100);
    expect(
      positiveStories.map((story) => story.body).toSet().length,
      positiveStories.length,
    );
    expect(
      positiveStories.any((story) => story.quote.contains('의역')),
      isTrue,
    );
    for (final story in positiveStories) {
      expect(story.title, story.title.trim());
      expect(story.body, story.body.trim());
      expect(story.quote, story.quote.trim());
      expect(story.body, isNot(contains('\n')));
      expect(story.body, isNot(contains('  ')));
    }
  });

  test('오늘의 명언은 400개이며 문장과 출처가 비어 있지 않다', () {
    expect(dailyQuotes.length, 400);
    expect(dailyQuotes.map((quote) => quote.text).toSet().length, 400);
    for (final quote in dailyQuotes) {
      expect(quote.text.trim(), isNotEmpty);
      expect(quote.attribution.trim(), isNotEmpty);
    }
  });

  test('위로 이야기에는 주요 감정 상황이 포함된다', () {
    expect(storyDb.length, 300);
    final ids = storyDb.map((story) => story.id).toSet();
    expect(ids.length, 300);
    expect(storyDb.map((story) => story.body).toSet().length, 300);
    expect(
        ids,
        containsAll(<String>{
          'self_kind',
          'exhausted',
          'anger_pause',
          'unfair',
          'lonely',
          'anxiety',
        }));
  });

  test('작성한 사연의 핵심 상황에 맞는 위로 이야기군을 추천한다', () {
    expect(
      recommendStory('고객이 욕을 하고 무례하게 말해서 너무 화가 났어', '고객', 'reality').id,
      startsWith('customer_hurt'),
    );
    expect(
      recommendStory('면접에서 또 탈락해서 실패한 기분이야', '직장', 'comfort').id,
      startsWith('failure'),
    );
    expect(
      recommendStory('미래가 너무 걱정되고 불안해서 잠이 안 와', '나 자신', 'comfort').id,
      startsWith('anxiety'),
    );
  });
}
