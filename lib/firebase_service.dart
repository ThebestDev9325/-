import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'data/story_db.dart';
import 'models.dart';

class AppFirebaseService {
  AppFirebaseService._();

  static final instance = AppFirebaseService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String get userId => _auth.currentUser!.uid;

  Future<String> signIn() async {
    final current = _auth.currentUser;
    if (current != null) return current.uid;
    return (await _auth.signInAnonymously()).user!.uid;
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
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_postFromDoc).toList());
  }

  Future<void> saveRecord(EmotionRecord record) async {
    final data = <String, Object?>{
      'ownerId': userId,
      'createdAt': Timestamp.fromDate(record.createdAt),
      'category': record.category,
      'moodEmoji': record.moodEmoji,
      'moodLabel': record.moodLabel,
      'text': record.text,
      'storyId': record.story.id,
      'shared': record.shared,
    };
    final batch = _db.batch();
    batch.set(
      _db.collection('users').doc(userId).collection('records').doc(record.id),
      data,
    );
    if (record.shared) {
      batch.set(_db.collection('sharedPosts').doc(record.id), {
        ...data,
        'reactions': [0, 0, 0],
        'reactedBy': <String>[],
        'reportCount': 0,
        'reportedBy': <String>[],
      });
    }
    await batch.commit();
  }

  Future<void> react(SharedPost post, int reactionIndex) async {
    final ref = _db.collection('sharedPosts').doc(post.id);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final reactedBy = List<String>.from(data['reactedBy'] as List? ?? const []);
      if (reactedBy.contains(userId) || data['ownerId'] == userId) return;
      final reactions = List<int>.from(data['reactions'] as List? ?? const [0, 0, 0]);
      reactions[reactionIndex]++;
      transaction.update(ref, {
        'reactions': reactions,
        'reactedBy': FieldValue.arrayUnion([userId]),
      });
    });
  }

  Future<void> report(SharedPost post) async {
    final ref = _db.collection('sharedPosts').doc(post.id);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final reportedBy = List<String>.from(data['reportedBy'] as List? ?? const []);
      if (reportedBy.contains(userId)) return;
      transaction.update(ref, {
        'reportCount': FieldValue.increment(1),
        'reportedBy': FieldValue.arrayUnion([userId]),
      });
    });
  }

  EmotionRecord _recordFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
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

  SharedPost _postFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final reactedBy = List<String>.from(data['reactedBy'] as List? ?? const []);
    return SharedPost(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      category: data['category'] as String? ?? '기타',
      text: data['text'] as String? ?? '',
      moodEmoji: data['moodEmoji'] as String? ?? '😐',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reactions: List<int>.from(data['reactions'] as List? ?? const [0, 0, 0]),
      myReaction: reactedBy.contains(userId) ? 0 : null,
      reportCount: data['reportCount'] as int? ?? 0,
    );
  }

  StoryItem _storyById(String? id) {
    return storyDb.firstWhere(
      (story) => story.id == id,
      orElse: () => storyDb.first,
    );
  }
}
