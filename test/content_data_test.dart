import 'package:chameulin/data/positive_stories.dart';
import 'package:chameulin/data/story_db.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('긍정 콘텐츠는 충분한 수와 고유한 본문을 가진다', () {
    expect(positiveStories.length, greaterThanOrEqualTo(30));
    expect(
      positiveStories.map((story) => story.body).toSet().length,
      positiveStories.length,
    );
    expect(
      positiveStories.any((story) => story.quote.contains('의역')),
      isTrue,
    );
  });

  test('위로 이야기에는 주요 감정 상황이 포함된다', () {
    expect(storyDb.length, greaterThanOrEqualTo(15));
    final ids = storyDb.map((story) => story.id).toSet();
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
}
