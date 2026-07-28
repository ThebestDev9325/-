import 'dart:convert';
import 'dart:io';

import 'package:chameulin/community_safety.dart';
import 'package:chameulin/shared_preferences_community_safety_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('공용 fixture의 모든 콘텐츠를 기대한 분류로 판정한다', () {
    final cases = (jsonDecode(
      File('test/fixtures/community_moderation_cases.json').readAsStringSync(),
    ) as List<dynamic>)
        .cast<Map<String, dynamic>>();

    for (final testCase in cases) {
      final violation = findCommunityContentViolation(
        text: testCase['text'] as String,
        category: testCase['category'] as String,
        moodEmoji: testCase['moodEmoji'] as String,
        moodLabel: testCase['moodLabel'] as String,
      );
      expect(
        violation?.wireName,
        testCase['expected'],
        reason: testCase['name'] as String,
      );
    }
  });

  test('공유 글 길이는 2,000자까지 허용한다', () {
    CommunityContentViolation? violation(String text) {
      return findCommunityContentViolation(
        text: text,
        category: '기타',
        moodEmoji: '😐',
        moodLabel: '답답함',
      );
    }

    expect(violation('가' * 2000), isNull);
    expect(violation('가' * 2001), CommunityContentViolation.tooLong);
  });

  test('숨김과 차단만 계정별 상태로 영속화한다', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesCommunitySafetyStore();

    await store.hidePost('user-a', 'post-1');
    await store.blockAuthor('user-a', 'owner-1');

    final state = await store.load('user-a');
    expect(state.hiddenPostIds, contains('post-1'));
    expect(state.blockedOwnerIds, contains('owner-1'));
    expect(state.toJson(), {
      'hiddenPostIds': ['post-1'],
      'blockedOwnerIds': ['owner-1'],
    });
    expect((await store.load('user-b')).hiddenPostIds, isEmpty);
  });

  test('계정 안전 상태를 삭제하면 다른 계정 상태는 유지한다', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesCommunitySafetyStore();
    await store.hidePost('user-a', 'post-a');
    await store.hidePost('user-b', 'post-b');

    await store.clear('user-a');

    expect((await store.load('user-a')).hiddenPostIds, isEmpty);
    expect((await store.load('user-b')).hiddenPostIds, contains('post-b'));
  });

  test('익명 계정의 안전 상태를 연결 계정으로 병합한다', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesCommunitySafetyStore();
    await store.hidePost('anonymous', 'hidden-anonymous');
    await store.blockAuthor('anonymous', 'blocked-anonymous');
    await store.hidePost('linked', 'hidden-linked');

    final migrated = await store.migrate('anonymous', 'linked');

    expect(
      migrated.hiddenPostIds,
      containsAll(['hidden-anonymous', 'hidden-linked']),
    );
    expect(migrated.blockedOwnerIds, contains('blocked-anonymous'));
    expect((await store.load('anonymous')).hiddenPostIds, isEmpty);
    expect((await store.load('linked')).toJson(), migrated.toJson());
  });

  test('로그인 직후 종료돼도 다음 실행에서 익명 상태 이전을 재개한다', () async {
    SharedPreferences.setMockInitialValues({});
    final firstSession = SharedPreferencesCommunitySafetyStore();
    await firstSession.activate('anonymous');
    await firstSession.hidePost('anonymous', 'hidden-before-login');
    await firstSession.blockAuthor('anonymous', 'blocked-before-login');

    final restartedSession = SharedPreferencesCommunitySafetyStore();
    final restored = await restartedSession.activate('linked');

    expect(restored.hiddenPostIds, contains('hidden-before-login'));
    expect(restored.blockedOwnerIds, contains('blocked-before-login'));
    expect((await restartedSession.load('anonymous')).hiddenPostIds, isEmpty);
  });
}
