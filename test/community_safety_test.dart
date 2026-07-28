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

  test('숨김, 차단, pending 신고를 계정별 단일 상태로 영속화한다', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesCommunitySafetyStore();
    const report = PendingCommunityReport(
      postId: 'post-1',
      ownerId: 'owner-1',
      reason: CommunityReportReason.harassment,
    );

    await store.hidePost('user-a', 'post-1');
    await store.blockAuthor('user-a', 'owner-1');
    await store.enqueueReport('user-a', report);

    final state = await store.load('user-a');
    expect(state.hiddenPostIds, contains('post-1'));
    expect(state.blockedOwnerIds, contains('owner-1'));
    expect(state.pendingReports, contains(report));
    expect((await store.load('user-b')).hiddenPostIds, isEmpty);

    await store.completeReport('user-a', 'post-1');
    expect((await store.load('user-a')).pendingReports, isEmpty);
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
}
