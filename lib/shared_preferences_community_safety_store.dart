import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'community_safety.dart';

class SharedPreferencesCommunitySafetyStore implements CommunitySafetyStore {
  static const _keyPrefix = 'community_safety.v1.';

  Future<void> _writeQueue = Future.value();

  String _key(String userId) => '$_keyPrefix$userId';

  @override
  Future<CommunitySafetyState> load(String userId) async {
    await _writeQueue;
    return _loadNow(userId);
  }

  @override
  Future<void> hidePost(String userId, String postId) {
    return _mutate(userId, (state) {
      return CommunitySafetyState(
        hiddenPostIds: {...state.hiddenPostIds, postId},
        blockedOwnerIds: state.blockedOwnerIds,
        pendingReports: state.pendingReports,
      );
    });
  }

  @override
  Future<void> blockAuthor(String userId, String ownerId) {
    return _mutate(userId, (state) {
      return CommunitySafetyState(
        hiddenPostIds: state.hiddenPostIds,
        blockedOwnerIds: {...state.blockedOwnerIds, ownerId},
        pendingReports: state.pendingReports,
      );
    });
  }

  @override
  Future<void> enqueueReport(
    String userId,
    PendingCommunityReport report,
  ) {
    return _mutate(userId, (state) {
      final pending = [
        ...state.pendingReports.where((item) => item.postId != report.postId),
        report,
      ];
      return CommunitySafetyState(
        hiddenPostIds: {...state.hiddenPostIds, report.postId},
        blockedOwnerIds: state.blockedOwnerIds,
        pendingReports: pending,
      );
    });
  }

  @override
  Future<void> completeReport(String userId, String postId) {
    return _mutate(userId, (state) {
      return CommunitySafetyState(
        hiddenPostIds: state.hiddenPostIds,
        blockedOwnerIds: state.blockedOwnerIds,
        pendingReports: state.pendingReports
            .where((item) => item.postId != postId)
            .toList(),
      );
    });
  }

  @override
  Future<CommunitySafetyState> migrate(
    String fromUserId,
    String toUserId,
  ) {
    if (fromUserId == toUserId) return load(toUserId);
    late CommunitySafetyState merged;
    return _serialize(() async {
      final source = await _loadNow(fromUserId);
      final target = await _loadNow(toUserId);
      final reportsByPostId = {
        for (final report in target.pendingReports) report.postId: report,
        for (final report in source.pendingReports) report.postId: report,
      };
      merged = CommunitySafetyState(
        hiddenPostIds: {...target.hiddenPostIds, ...source.hiddenPostIds},
        blockedOwnerIds: {
          ...target.blockedOwnerIds,
          ...source.blockedOwnerIds,
        },
        pendingReports: reportsByPostId.values.toList(),
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _key(toUserId),
        jsonEncode(merged.toJson()),
      );
      await preferences.remove(_key(fromUserId));
    }).then((_) => merged);
  }

  @override
  Future<void> clear(String userId) {
    return _serialize(() async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_key(userId));
    });
  }

  Future<void> _mutate(
    String userId,
    CommunitySafetyState Function(CommunitySafetyState) update,
  ) {
    return _serialize(() async {
      final state = await _loadNow(userId);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _key(userId),
        jsonEncode(update(state).toJson()),
      );
    });
  }

  Future<CommunitySafetyState> _loadNow(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_key(userId));
    if (encoded == null) return const CommunitySafetyState();
    try {
      return CommunitySafetyState.fromJson(
        Map<String, dynamic>.from(jsonDecode(encoded) as Map),
      );
    } on FormatException {
      return const CommunitySafetyState();
    } on TypeError {
      return const CommunitySafetyState();
    }
  }

  Future<void> _serialize(Future<void> Function() operation) {
    final completer = Completer<void>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        await operation();
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
