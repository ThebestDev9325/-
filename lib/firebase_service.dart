import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'community_safety.dart';
import 'data/story_db.dart';
import 'models.dart';

class AppFirebaseService {
  AppFirebaseService._();

  static final instance = AppFirebaseService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String get userId => _auth.currentUser!.uid;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get hasLinkedAccount =>
      _auth.currentUser != null && !_auth.currentUser!.isAnonymous;

  Future<String?> linkedProvider() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return null;
    final token = await user.getIdTokenResult();
    if (token.claims?['provider'] == 'kakao') return 'kakao';
    if (user.providerData.any(
      (provider) => provider.providerId == 'apple.com',
    )) {
      return 'apple';
    }
    return null;
  }

  Future<String?> linkedAccountLabel() async {
    return switch (await linkedProvider()) {
      'kakao' => '카카오 계정 연결됨',
      'apple' => 'Apple 계정 연결됨',
      _ => hasLinkedAccount ? '계정 연결됨' : null,
    };
  }

  Future<String> signIn() async {
    final current = _auth.currentUser;
    if (current != null) return current.uid;
    return (await _auth.signInAnonymously()).user!.uid;
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<String?> loadNickname() async {
    await signIn();
    final snapshot = await _db.collection('users').doc(userId).get();
    return snapshot.data()?['nickname'] as String?;
  }

  Future<bool> claimNickname(String nickname) async {
    await signIn();
    final key = nickname.trim().toLowerCase();
    final nicknameRef = _db.collection('nicknames').doc(key);
    final userRef = _db.collection('users').doc(userId);
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(nicknameRef);
      if (snapshot.exists && snapshot.data()?['ownerId'] != userId) {
        return false;
      }
      transaction.set(nicknameRef, {
        'nickname': nickname,
        'ownerId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(userRef, {'nickname': nickname}, SetOptions(merge: true));
      return true;
    });
  }

  Future<List<EmotionRecord>> loadRecords() async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('records')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(_recordFromDoc).toList();
  }

  Stream<List<SharedPost>> watchSharedPosts() {
    return _db
        .collection('sharedPosts')
        .orderBy('createdAt', descending: true)
        .limit(300)
        .snapshots()
        .map((snapshot) {
      final posts = <SharedPost>[];
      for (final document in snapshot.docs) {
        final post = _tryPostFromDoc(document);
        if (post != null) posts.add(post);
      }
      return posts;
    });
  }

  Stream<Map<String, AdSlotConfig>> watchAdSlots() {
    return _db.collection('adSlots').snapshots().map((snapshot) {
      final slots = <String, AdSlotConfig>{...AdSlotConfig.fallbacks};
      for (final document in snapshot.docs) {
        if (!slots.containsKey(document.id)) continue;
        final data = document.data();
        final fallback = slots[document.id]!;
        slots[document.id] = AdSlotConfig(
          id: document.id,
          title: data['title'] as String? ?? fallback.title,
          url: data['url'] as String? ?? fallback.url,
          enabled: data['enabled'] as bool? ?? fallback.enabled,
          youtube: data['youtube'] as bool? ?? fallback.youtube,
          imageUrl: data['imageUrl'] as String? ?? fallback.imageUrl,
          imageAsset: fallback.imageAsset,
          darkForeground:
              data['darkForeground'] as bool? ?? fallback.darkForeground,
          backgroundStart: (data['backgroundStart'] as num?)?.toInt() ??
              fallback.backgroundStart,
          backgroundEnd: (data['backgroundEnd'] as num?)?.toInt() ??
              fallback.backgroundEnd,
        );
      }
      return slots;
    });
  }

  Future<void> saveRecord(EmotionRecord record) async {
    final ownerId = userId;
    await _db
        .collection('users')
        .doc(ownerId)
        .collection('records')
        .doc(record.id)
        .set(_recordData(record, shared: false));
    if (record.shared) await _publishRecord(record.id);
  }

  Future<void> shareRecord(EmotionRecord record) async {
    final ownerId = userId;
    await _db
        .collection('users')
        .doc(ownerId)
        .collection('records')
        .doc(record.id)
        .set(_recordData(record, shared: false), SetOptions(merge: true));
    await _publishRecord(record.id);
  }

  Map<String, Object?> _recordData(
    EmotionRecord record, {
    required bool shared,
  }) {
    return {
      'ownerId': userId,
      'createdAt': Timestamp.fromDate(record.createdAt),
      'category': record.category,
      'moodEmoji': record.moodEmoji,
      'moodLabel': record.moodLabel,
      'text': record.text,
      'storyId': record.story.id,
      'shared': shared,
    };
  }

  Future<void> _publishRecord(String recordId) async {
    final callable = FirebaseFunctions.instanceFor(
      region: 'asia-northeast3',
    ).httpsCallable('publishSharedRecord');
    await callable.call<void>(<String, dynamic>{'recordId': recordId});
  }

  Future<void> react(SharedPost post, int reactionIndex) async {
    final ref = _db.collection('sharedPosts').doc(post.id);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final reactedBy = List<String>.from(
        data['reactedBy'] as List? ?? const [],
      );
      if (reactedBy.contains(userId) || data['ownerId'] == userId) return;
      final reactions = List<int>.from(
        data['reactions'] as List? ?? const [0, 0, 0],
      );
      reactions[reactionIndex]++;
      transaction.update(ref, {
        'reactions': reactions,
        'reactedBy': FieldValue.arrayUnion([userId]),
      });
    });
  }

  Future<void> report(
    String postId,
    String reason, {
    String? ownerId,
  }) async {
    final callable = FirebaseFunctions.instanceFor(
      region: 'asia-northeast3',
    ).httpsCallable('reportSharedPost');
    await callable.call<void>(<String, dynamic>{
      'postId': postId,
      'reason': CommunityReportReason.other.wireName,
      'detail': reason,
      if (ownerId != null) 'ownerId': ownerId,
    });
  }

  Future<void> deleteSharedPost(String postId) async {
    final postReference = _db.collection('sharedPosts').doc(postId);
    final recordReference =
        _db.collection('users').doc(userId).collection('records').doc(postId);
    await _db.runTransaction((transaction) async {
      final post = await transaction.get(postReference);
      if (post.exists && post.data()?['ownerId'] != userId) {
        throw StateError('내 공유 글만 삭제할 수 있습니다.');
      }
      final record = await transaction.get(recordReference);
      if (post.exists) transaction.delete(postReference);
      if (record.exists) {
        transaction.update(recordReference, {'shared': false});
      }
    });
  }

  Future<void> submitStoryFeedback(String storyId, String feedback) async {
    final field = switch (feedback) {
      '좋아요' => 'likes',
      '잘 모르겠어요' => 'unsure',
      '별로에요' => 'dislikes',
      _ => null,
    };
    if (field == null) return;

    final ref = _db.collection('storyFeedback').doc(storyId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.exists) {
        transaction.update(ref, {
          field: FieldValue.increment(1),
          'total': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(ref, {
          'storyId': storyId,
          'likes': field == 'likes' ? 1 : 0,
          'unsure': field == 'unsure' ? 1 : 0,
          'dislikes': field == 'dislikes' ? 1 : 0,
          'total': 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> deleteMyData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final records =
        await _db.collection('users').doc(user.uid).collection('records').get();
    final shared = await _db
        .collection('sharedPosts')
        .where('ownerId', isEqualTo: user.uid)
        .get();
    final refs = <DocumentReference>[
      ...records.docs.map((d) => d.reference),
      ...shared.docs.map((d) => d.reference),
    ];
    for (var start = 0; start < refs.length; start += 450) {
      final batch = _db.batch();
      for (final ref in refs.skip(start).take(450)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  Future<void> deleteLinkedAccount() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final nickname = userDoc.data()?['nickname'] as String?;
    await deleteMyData();
    final batch = _db.batch()..delete(userDoc.reference);
    if (nickname != null && nickname.trim().isNotEmpty) {
      batch.delete(
        _db.collection('nicknames').doc(nickname.trim().toLowerCase()),
      );
    }
    await batch.commit();
    await user.delete();
  }

  EmotionRecord _recordFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return EmotionRecord(
      id: doc.id,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      category: data['category'] as String? ?? '기타',
      moodEmoji: data['moodEmoji'] as String? ?? '😐',
      moodLabel: data['moodLabel'] as String? ?? '',
      text: data['text'] as String? ?? '',
      story: _storyById(data['storyId'] as String?),
      shared: data['shared'] as bool? ?? false,
    );
  }

  SharedPost? _tryPostFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final createdAt = data['createdAt'];
    final reactionsValue = data['reactions'];
    final reactedByValue = data['reactedBy'];
    final ownerId = data['ownerId'];
    final category = data['category'];
    final text = data['text'];
    final moodEmoji = data['moodEmoji'];
    final moodLabel = data['moodLabel'];
    if (createdAt is! Timestamp ||
        reactionsValue is! List ||
        reactionsValue.length != 3 ||
        reactionsValue.any((reaction) => reaction is! int) ||
        reactedByValue is! List ||
        reactedByValue.any((user) => user is! String) ||
        ownerId is! String ||
        category is! String ||
        text is! String ||
        moodEmoji is! String ||
        moodLabel is! String) {
      debugPrint('Skipped invalid shared post: ${doc.id}');
      return null;
    }
    if (findCommunityContentViolation(
          text: text,
          category: category,
          moodEmoji: moodEmoji,
          moodLabel: moodLabel,
        ) !=
        null) {
      return null;
    }
    final reactedBy = List<String>.from(reactedByValue);
    return SharedPost(
      id: doc.id,
      ownerId: ownerId,
      category: category,
      text: text,
      moodEmoji: moodEmoji,
      moodLabel: moodLabel,
      createdAt: createdAt.toDate(),
      reactions: List<int>.from(reactionsValue),
      myReaction: reactedBy.contains(userId) ? 0 : null,
      reportCount: data['reportCount'] as int? ?? 0,
      reportedByMe: false,
    );
  }

  StoryItem _storyById(String? id) {
    return storyDb.firstWhere(
      (story) => story.id == id,
      orElse: () => storyDb.first,
    );
  }
}
