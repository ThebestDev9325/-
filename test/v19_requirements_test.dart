import 'package:chameulin/audio_service.dart';
import 'package:chameulin/main.dart';
import 'package:chameulin/models.dart';
import 'package:flutter_test/flutter_test.dart';

SharedPost post({
  required String id,
  required DateTime createdAt,
  required int angryReactions,
}) {
  return SharedPost(
    id: id,
    ownerId: 'owner-$id',
    category: '기타',
    text: '사연 $id',
    moodEmoji: '😐',
    createdAt: createdAt,
    reactions: [angryReactions, 0, 0],
  );
}

void main() {
  test('홈 배경음은 자연 소리 대신 오리지널 명상 패드를 사용한다', () {
    expect(
      AppAudioService.homeBgmAsset,
      'assets/audio/meditation_pad_v20.mp3',
    );
  });

  test('오늘의 베스트는 현지 자정 이후 작성된 사연만 대상으로 한다', () {
    final now = DateTime(2026, 7, 13, 0, 1);
    final yesterday = post(
      id: 'yesterday',
      createdAt: DateTime(2026, 7, 12, 23, 59),
      angryReactions: 100,
    );
    final today = post(
      id: 'today',
      createdAt: DateTime(2026, 7, 13, 0, 0),
      angryReactions: 1,
    );

    expect(bestPostForDay([yesterday, today], now)?.id, 'today');
    expect(bestPostForDay([yesterday], now), isNull);
  });
}
