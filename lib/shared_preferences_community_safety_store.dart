import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'community_safety.dart';

class SharedPreferencesCommunitySafetyStore implements CommunitySafetyStore {
  static const _keyPrefix = 'community_safety.v1.';
  static const _activeUserKey = 'community_safety.v1.active_user';

  Future<void> _writeQueue = Future.value();

  String _key(String userId) => '$_keyPrefix$userId';

  @override
  Future<CommunitySafetyState> activate(String userId) {
    late CommunitySafetyState activated;
    return _serialize(() async {
      final preferences = await SharedPreferences.getInstance();
      final previousUserId = preferences.getString(_activeUserKey);
      activated = previousUserId == null || previousUserId == userId
          ? await _loadNow(userId)
          : await _migrateNow(previousUserId, userId);
      await preferences.setString(_activeUserKey, userId);
    }).then((_) => activated);
  }

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
      );
    });
  }

  @override
  Future<void> blockAuthor(String userId, String ownerId) {
    return _mutate(userId, (state) {
      return CommunitySafetyState(
        hiddenPostIds: state.hiddenPostIds,
        blockedOwnerIds: {...state.blockedOwnerIds, ownerId},
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
      final preferences = await SharedPreferences.getInstance();
      merged = await _migrateNow(fromUserId, toUserId);
      if (preferences.getString(_activeUserKey) == fromUserId) {
        await preferences.setString(_activeUserKey, toUserId);
      }
    }).then((_) => merged);
  }

  @override
  Future<void> clear(String userId) {
    return _serialize(() async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_key(userId));
      if (preferences.getString(_activeUserKey) == userId) {
        await preferences.remove(_activeUserKey);
      }
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

  Future<CommunitySafetyState> _migrateNow(
    String fromUserId,
    String toUserId,
  ) async {
    final source = await _loadNow(fromUserId);
    final target = await _loadNow(toUserId);
    final merged = CommunitySafetyState(
      hiddenPostIds: {...target.hiddenPostIds, ...source.hiddenPostIds},
      blockedOwnerIds: {...target.blockedOwnerIds, ...source.blockedOwnerIds},
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key(toUserId), jsonEncode(merged.toJson()));
    await preferences.remove(_key(fromUserId));
    return merged;
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
