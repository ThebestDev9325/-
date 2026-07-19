import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const currentTermsVersion = '2026.07.19';
const currentTermsEffectiveDate = '2026년 7월 19일';

class LegalConsentStore {
  LegalConsentStore._();
  static final instance = LegalConsentStore._();

  static const _termsKey = 'legal.terms_version';
  static const _communityKey = 'legal.community_policy_version';

  Future<bool> hasCurrentConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_termsKey) == currentTermsVersion;
  }

  Future<void> acceptCurrentTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_termsKey, currentTermsVersion);
  }

  Future<bool> hasAcceptedCommunityPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_communityKey) == currentTermsVersion;
  }

  Future<void> acceptCommunityPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_communityKey, currentTermsVersion);
  }
}

enum LegalDocumentType { terms, privacy, community, disclaimer }

extension LegalDocumentTypeText on LegalDocumentType {
  String get title => switch (this) {
        LegalDocumentType.terms => '이용약관',
        LegalDocumentType.privacy => '개인정보처리방침',
        LegalDocumentType.community => '커뮤니티 운영정책',
        LegalDocumentType.disclaimer => '서비스 이용 안내',
      };

  String get body => switch (this) {
        LegalDocumentType.terms => '''제1조 목적
이 약관은 참을인이 제공하는 감정 기록, 이야기 추천 및 공감 공간 서비스의 이용 조건을 정합니다.

제2조 서비스 이용
사용자는 자신의 감정을 기록하고, 선택한 기록을 공감 공간에 공유할 수 있습니다. 서비스의 안정적인 운영을 방해하거나 타인의 권리를 침해해서는 안 됩니다.

제3조 계정
기록 공유와 관리를 위해 카카오 계정을 연결할 수 있습니다. 계정 정보 관리 책임은 사용자에게 있습니다.

제4조 사용자 게시물
사용자는 자신이 작성한 글에 대한 책임을 집니다. 운영정책을 위반하거나 다른 사람의 권리를 침해하는 게시물은 신고 검토 후 제한 또는 삭제될 수 있습니다.

제5조 서비스 변경 및 중단
점검, 장애 또는 운영상 필요한 경우 서비스 일부가 변경되거나 일시 중단될 수 있습니다. 중요한 변경은 앱에서 안내합니다.

제6조 책임의 제한
참을인은 의료기관이나 전문 상담기관이 아니며, 앱의 콘텐츠는 의학적 진단이나 치료를 대신하지 않습니다.

제7조 탈퇴
사용자는 설정에서 회원탈퇴를 요청할 수 있습니다. 탈퇴 시 법령상 보관 의무가 있는 정보를 제외한 계정과 관련 데이터가 삭제됩니다.''',
        LegalDocumentType.privacy => '''1. 처리하는 정보
참을인은 서비스 제공을 위해 Firebase 익명·연결 계정 식별자, 사용자가 설정한 닉네임, 감정 기록, 공개한 글, 공감·신고 내역 및 서비스 이용 과정에서 생성되는 기술 정보를 처리할 수 있습니다. 카카오 계정 연결 시 카카오 계정 식별 정보가 처리됩니다.

2. 처리 목적
본인 식별, 기록 저장·복원, 공개 글 관리, 신고 처리, 부정 이용 방지 및 서비스 안정성 확보에 사용합니다.

3. 보관 및 삭제
정보는 서비스 이용 기간 동안 보관하며, 사용자가 데이터 삭제 또는 회원탈퇴를 요청하면 지체 없이 삭제합니다. 관계 법령에 따라 보관해야 하는 정보는 해당 기간 동안 분리 보관합니다.

4. 외부 서비스
인증과 데이터 저장을 위해 Google Firebase 및 카카오 로그인을 이용합니다. 각 서비스 제공 과정에서 정보가 국외에서 처리될 수 있으므로 출시 전 실제 처리 위치와 위탁·이전 내역을 최종 문서에 반영합니다.

5. 사용자의 권리
사용자는 설정에서 자신의 데이터를 삭제하거나 회원탈퇴를 요청할 수 있습니다. 동의 철회 및 개인정보 관련 문의는 a01041989325@gmail.com 또는 공개 개인정보처리방침의 문의 페이지를 통해 접수할 수 있습니다.

6. 안전성 확보
참을인은 접근 권한 관리와 전송 구간 보호 등 개인정보 보호를 위한 조치를 적용합니다.

공개 개인정보처리방침: https://thebestdev9325.github.io/-/''',
        LegalDocumentType.community => '''공감 공간은 서로의 마음을 존중하는 곳입니다.

다음 내용은 게시할 수 없습니다.
• 이름, 연락처, 주소 등 개인을 알아볼 수 있는 정보
• 타인을 비방하거나 괴롭히는 내용
• 혐오, 차별, 위협 또는 폭력적인 표현
• 불법 행위나 자해를 조장하는 내용
• 광고, 도배 및 서비스 목적과 관계없는 내용

공유한 글은 다른 사용자가 보고 공감하거나 신고할 수 있습니다. 운영정책을 위반한 게시물은 신고 검토 후 제한 또는 삭제될 수 있습니다.''',
        LegalDocumentType.disclaimer => '''참을인은 감정을 기록하고 돌아보는 데 도움을 주는 서비스입니다.

작성한 기록은 기본적으로 본인만 볼 수 있으며, 사용자가 직접 공유를 선택한 경우에만 공감 공간에 공개됩니다. 공유 전에는 이름, 연락처, 주소 등 개인을 알아볼 수 있는 정보가 포함되지 않았는지 확인해 주세요.

참을인은 의료기관이나 전문 상담 서비스가 아니며, 제공되는 이야기와 반응은 의학적 진단이나 치료를 대신하지 않습니다.

자신이나 다른 사람을 해칠 급박한 위험이 있다면 혼자 견디지 말고 즉시 주변의 믿을 수 있는 사람에게 알리고 112 또는 119 등 긴급기관에 도움을 요청해 주세요.''',
      };
}

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({super.key, required this.type});
  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(type.title)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '시행일 $currentTermsEffectiveDate · 버전 $currentTermsVersion',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SelectableText(type.body, style: const TextStyle(height: 1.65)),
          ],
        ),
      );
}

class LegalDocumentsPage extends StatelessWidget {
  const LegalDocumentsPage({super.key});

  void _open(BuildContext context, LegalDocumentType type) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalDocumentPage(type: type)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('이용약관 등 보기')),
        body: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('이용약관'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, LegalDocumentType.terms),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('개인정보처리방침'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, LegalDocumentType.privacy),
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('커뮤니티 운영정책'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, LegalDocumentType.community),
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined),
              title: const Text('기록 및 서비스 이용 안내'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, LegalDocumentType.disclaimer),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.verified_outlined),
              title: Text('동의 내역'),
              subtitle: Text(
                '$currentTermsEffectiveDate 동의 · $currentTermsVersion',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('오픈소스 라이선스'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(
                context: context,
                applicationName: '참을인',
              ),
            ),
          ],
        ),
      );
}

class InitialConsentGate extends StatefulWidget {
  const InitialConsentGate({super.key, required this.child});
  final Widget child;

  @override
  State<InitialConsentGate> createState() => _InitialConsentGateState();
}

class _InitialConsentGateState extends State<InitialConsentGate> {
  bool? accepted;

  @override
  void initState() {
    super.initState();
    LegalConsentStore.instance.hasCurrentConsent().then((value) {
      if (mounted) setState(() => accepted = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (accepted == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (accepted!) return widget.child;
    return InitialConsentPage(
      onAccepted: () => setState(() => accepted = true),
    );
  }
}

class InitialConsentPage extends StatefulWidget {
  const InitialConsentPage({super.key, required this.onAccepted});
  final VoidCallback onAccepted;

  @override
  State<InitialConsentPage> createState() => _InitialConsentPageState();
}

class _InitialConsentPageState extends State<InitialConsentPage> {
  bool terms = false;
  bool privacy = false;
  bool recordNotice = false;
  bool age = false;

  bool get canContinue => terms && privacy && recordNotice && age;

  void _open(LegalDocumentType type) => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => LegalDocumentPage(type: type)));

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.eco_outlined,
                  size: 58, color: Color(0xFF617A3F)),
              const SizedBox(height: 20),
              const Text(
                '참을인을 시작하기 전에',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                '안전한 서비스 이용을 위해 아래 내용을 확인해 주세요.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _check(
                '필수',
                '이용약관에 동의합니다',
                terms,
                (v) => setState(() => terms = v),
                () => _open(LegalDocumentType.terms),
              ),
              _check(
                '필수',
                '개인정보 처리 안내를 확인했습니다',
                privacy,
                (v) => setState(() => privacy = v),
                () => _open(LegalDocumentType.privacy),
              ),
              _check(
                '필수',
                '기록 및 서비스 이용 안내를 확인했습니다',
                recordNotice,
                (v) => setState(() => recordNotice = v),
                () => _open(LegalDocumentType.disclaimer),
              ),
              _check(
                '필수',
                '만 14세 이상입니다',
                age,
                (v) => setState(() => age = v),
                null,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: canContinue
                    ? () async {
                        await LegalConsentStore.instance.acceptCurrentTerms();
                        if (mounted) widget.onAccepted();
                      }
                    : null,
                child: const Text('동의하고 시작하기'),
              ),
            ],
          ),
        ),
      );

  Widget _check(
    String badge,
    String text,
    bool value,
    ValueChanged<bool> changed,
    VoidCallback? open,
  ) =>
      Card(
        child: CheckboxListTile(
          value: value,
          onChanged: (v) => changed(v ?? false),
          title: Text('[$badge] $text'),
          secondary: open == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: open,
                  tooltip: '전문 보기',
                ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      );
}

Future<bool> ensureCommunityPolicy(BuildContext context) async {
  if (await LegalConsentStore.instance.hasAcceptedCommunityPolicy()) {
    return true;
  }
  if (!context.mounted) return false;
  var checked = false;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('공감 공간에 공유할까요?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '공유한 글은 다른 사용자가 볼 수 있습니다. 이름, 연락처, 주소 등 개인을 알아볼 수 있는 정보가 포함되지 않았는지 확인해 주세요.',
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: checked,
                onChanged: (v) => setState(() => checked = v ?? false),
                title: const Text('커뮤니티 운영정책을 확인했습니다'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LegalDocumentPage(
                      type: LegalDocumentType.community,
                    ),
                  ),
                ),
                child: const Text('운영정책 전문 보기'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: checked ? () => Navigator.pop(context, true) : null,
            child: const Text('공유하기'),
          ),
        ],
      ),
    ),
  );
  if (accepted == true) {
    await LegalConsentStore.instance.acceptCommunityPolicy();
  }
  return accepted == true;
}

bool containsCrisisLanguage(String text) {
  final normalized = text.replaceAll(' ', '');
  return ['죽고싶', '자살', '극단적선택', '나를해치', '자해', '사라지고싶'].any(normalized.contains);
}

Future<bool> showCrisisSupportIfNeeded(
  BuildContext context,
  String text,
) async {
  if (!containsCrisisLanguage(text)) return true;
  final proceed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.favorite_outline, size: 38),
      title: const Text('지금 많이 힘든 상태인가요?'),
      content: const Text(
        '참을인은 전문적인 위기 상담을 제공할 수 없습니다. 자신이나 다른 사람을 해칠 급박한 위험이 있다면 혼자 견디지 말고 주변의 믿을 수 있는 사람에게 알리거나 112·119에 즉시 도움을 요청해 주세요.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('작성 멈추기'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('계속 작성하기'),
        ),
      ],
    ),
  );
  return proceed == true;
}
