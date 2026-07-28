import 'package:unorm_dart/unorm_dart.dart' as unicode;

enum CommunityContentViolation {
  invalidMetadata('invalid_metadata', '공유 정보가 올바르지 않습니다.'),
  personalInformation(
    'personal_information',
    '연락처나 이메일 등 개인정보가 포함된 글은 공유할 수 없습니다.',
  ),
  harassment('harassment', '괴롭힘이나 비방 표현이 포함된 글은 공유할 수 없습니다.'),
  hate('hate', '혐오나 차별 표현이 포함된 글은 공유할 수 없습니다.'),
  violence('violence', '위협이나 폭력 표현이 포함된 글은 공유할 수 없습니다.'),
  sexual('sexual', '성적인 표현이 포함된 글은 공유할 수 없습니다.'),
  illegal('illegal', '불법 행위를 조장하는 글은 공유할 수 없습니다.'),
  spam('spam', '광고나 도배성 글은 공유할 수 없습니다.');

  const CommunityContentViolation(this.wireName, this.message);

  final String wireName;
  final String message;
}

enum CommunityReportReason {
  harassment('harassment', '괴롭힘 또는 비방'),
  hate('hate', '혐오 또는 차별'),
  violence('violence', '위협 또는 폭력'),
  sexual('sexual', '성적인 콘텐츠'),
  personalInformation('personal_information', '개인정보 노출'),
  illegal('illegal', '불법 행위'),
  spam('spam', '광고 또는 도배'),
  other('other', '기타 부적절한 콘텐츠');

  const CommunityReportReason(this.wireName, this.label);

  final String wireName;
  final String label;

  static CommunityReportReason fromWireName(String value) {
    return values.firstWhere(
      (reason) => reason.wireName == value,
      orElse: () => CommunityReportReason.other,
    );
  }
}

const communityCategories = {
  '직장',
  '고객',
  '가족',
  '연인',
  '친구',
  '타인',
  '나 자신',
  '기타',
};

const communityMoods = {
  '🤬': '폭발 직전',
  '😤': '많이 화남',
  '😐': '답답함',
  '🙂': '조금 괜찮음',
};

final _phonePattern =
    RegExp(r'(?<!\d)01[016789][-\s]?\d{3,4}[-\s]?\d{4}(?!\d)');
final _emailPattern = RegExp(
  r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
  caseSensitive: false,
);
final _separatorPattern = RegExp(
  r'''[\s\-_.·,!?~'"()[\]{}<>/:;@#%^&*+=|\\]+''',
  unicode: true,
);

CommunityContentViolation? findCommunityContentViolation({
  required String text,
  required String category,
  required String moodEmoji,
  required String moodLabel,
}) {
  if (text.trim().isEmpty ||
      !communityCategories.contains(category) ||
      communityMoods[moodEmoji] != moodLabel) {
    return CommunityContentViolation.invalidMetadata;
  }

  final normalized = unicode
      .nfkc(text)
      .toLowerCase()
      .replaceAll(RegExp(r'[\u200B-\u200D\u2060\uFEFF]'), '');
  final compact = normalized.replaceAll(_separatorPattern, '');

  if (_phonePattern.hasMatch(normalized) ||
      _emailPattern.hasMatch(normalized)) {
    return CommunityContentViolation.personalInformation;
  }
  if (_containsAny(compact, const ['병신', '개새끼', '씨발', '꺼져', '찐따'])) {
    return CommunityContentViolation.harassment;
  }
  if (_containsAny(compact, const ['김치녀', '한남충', '틀딱', '맘충', '외노자'])) {
    return CommunityContentViolation.hate;
  }
  if (_containsAny(
    compact,
    const ['죽여버리', '죽여버릴', '칼로찌르', '폭탄테러', '패죽이'],
  )) {
    return CommunityContentViolation.violence;
  }
  if (_containsAny(compact, const ['야동', '성매매', '강간', '음란물'])) {
    return CommunityContentViolation.sexual;
  }
  if (_containsAny(compact, const ['마약판매', '대포통장', '불법도박', '청부살인'])) {
    return CommunityContentViolation.illegal;
  }
  if (_containsAny(
    compact,
    const ['오픈채팅', '수익보장', '고수익알바', '무료체험클릭'],
  )) {
    return CommunityContentViolation.spam;
  }
  return null;
}

bool _containsAny(String text, List<String> terms) {
  return terms.any(text.contains);
}

class PendingCommunityReport {
  const PendingCommunityReport({
    required this.postId,
    required this.ownerId,
    required this.reason,
  });

  final String postId;
  final String ownerId;
  final CommunityReportReason reason;

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'ownerId': ownerId,
        'reason': reason.wireName,
      };

  factory PendingCommunityReport.fromJson(Map<String, dynamic> json) {
    return PendingCommunityReport(
      postId: json['postId'] as String,
      ownerId: json['ownerId'] as String,
      reason: CommunityReportReason.fromWireName(json['reason'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PendingCommunityReport &&
        other.postId == postId &&
        other.ownerId == ownerId &&
        other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(postId, ownerId, reason);
}

class CommunitySafetyState {
  const CommunitySafetyState({
    this.hiddenPostIds = const {},
    this.blockedOwnerIds = const {},
    this.pendingReports = const [],
  });

  final Set<String> hiddenPostIds;
  final Set<String> blockedOwnerIds;
  final List<PendingCommunityReport> pendingReports;

  bool allows({
    required String postId,
    required String ownerId,
  }) {
    return !hiddenPostIds.contains(postId) &&
        !blockedOwnerIds.contains(ownerId);
  }

  Map<String, dynamic> toJson() => {
        'hiddenPostIds': hiddenPostIds.toList()..sort(),
        'blockedOwnerIds': blockedOwnerIds.toList()..sort(),
        'pendingReports':
            pendingReports.map((report) => report.toJson()).toList(),
      };

  factory CommunitySafetyState.fromJson(Map<String, dynamic> json) {
    return CommunitySafetyState(
      hiddenPostIds:
          Set<String>.from(json['hiddenPostIds'] as List? ?? const []),
      blockedOwnerIds:
          Set<String>.from(json['blockedOwnerIds'] as List? ?? const []),
      pendingReports: (json['pendingReports'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => PendingCommunityReport.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

abstract interface class CommunitySafetyStore {
  Future<CommunitySafetyState> load(String userId);
  Future<void> hidePost(String userId, String postId);
  Future<void> blockAuthor(String userId, String ownerId);
  Future<void> enqueueReport(
    String userId,
    PendingCommunityReport report,
  );
  Future<void> completeReport(String userId, String postId);
  Future<void> clear(String userId);
}
