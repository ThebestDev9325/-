# App Store 재심사 — 2026-07-31 정보 요청

- Submission ID: `04b13d14-e196-4b62-9683-786c175b9424`
- 심사 기기: iPad Air 11-inch (M3)
- 심사 버전: `1.9.21 (40)`
- 수정 버전: `1.9.23 (42)`
- 가이드라인: 2.1 — Information Needed

## 커뮤니티 피드 접근 경로

로그인 후 모든 주요 화면 하단에 표시되는 내비게이션에서 하트 아이콘의 **공감** 탭을 누른다. 공감 탭이 전체 커뮤니티 피드이며, 본인이 공유한 글은 바로 옆 **내 공유** 탭에서도 확인할 수 있다.

## 게시 실패 원인과 수정

빌드 40에 심사용 이메일 로그인을 추가했지만 앱과 서버의 연결 계정 정책이 달랐다.

- 앱은 이메일/비밀번호 사용자를 연결 계정으로 판단했다.
- `publishSharedRecord` 서버 함수는 카카오와 Apple provider만 허용해 이메일 심사 계정을 `permission-denied`로 거부했다.
- 글쓰기 화면은 서버 결과 전에 닫혔고, 클라이언트가 모든 저장 예외를 인터넷 연결 오류로 표시했다.

빌드 42에서는 다음을 수정했다.

- 서버가 `sharedRecordPublisher` capability를 발급받은 Firebase `password` 심사 계정을 허용한다. 임의 이메일 계정과 Firebase anonymous 사용자의 게시는 계속 차단한다.
- 게시 transaction이 성공한 뒤에만 글쓰기 화면을 닫는다. 실패하면 입력과 현재 화면을 유지해 재시도할 수 있다.
- 같은 화면의 재시도는 같은 record ID를 사용해 중복 글을 만들지 않는다.
- 네트워크 응답 유실로 게시 성공 여부가 불명확하면 같은 record ID로 공개 상태를 확인한다. 확인할 수 없으면 비공개 저장과 화면 이탈을 잠그고 동일 글 재시도만 허용한다.
- 네트워크 오류에만 연결 확인 문구를 표시하고, 인증·권한·검증 오류는 원인에 맞게 안내한다.
- 이메일 계정의 provider 표시와 서버측 회원탈퇴 경로를 추가했다.

## Resolution Center 회신 초안

```text
Hello,

Thank you for your review and for reporting this issue.

1. How to access the community feed
After signing in, tap the heart-shaped “공감” (Empathy) tab in the bottom
navigation bar. This tab is the community feed. A reviewer can also view posts
created by the current account in the adjacent “내 공유” (My Shares) tab.

2. Anonymous post creation issue
We identified a provider-policy mismatch in the reviewed version 1.9.21 (40).
The app accepted our pre-created email/password review account as a connected
account, while the server-side publishing function allowed only Kakao and Apple
providers. The server therefore rejected the publish request. The app also
closed the writing screen before the server response and incorrectly presented
all failures as an internet connectivity problem.

We fixed the issue in version 1.9.23 (42). The server now authorizes the supplied
email/password review account while continuing to block unapproved and Firebase
anonymous accounts. The writing screen remains open with its content intact if publishing
fails, retrying uses the same post ID, and only actual network errors display a
connectivity message. The screen closes only after the server confirms that the
post was published.

Verification steps:
1. Sign in with the review email account supplied in App Review Information.
2. Tap the home action to begin a new entry and complete the writing flow.
3. On “어떻게 기록할까요?”, tap “공유하기”.
4. Confirm that the post appears in “내 공유”.
5. Tap the heart-shaped “공감” tab to open the community feed.

We tested this flow on iPhone and iPad simulators and with Firebase Auth,
Firestore, and Functions emulators.
```

## 배포 및 제출 순서

운영 계정 상태(2026-08-01): 기존 password 리뷰 계정 1개와 사용자 DB 문서를 확인했고, 다른 claim을 보존한 채 `sharedRecordPublisher: true`를 발급했다. 심사 전 해당 계정으로 다시 로그인해 새 ID token을 받아야 한다.

1. Firebase Auth/Firestore/Functions 에뮬레이터에서 승인된 password 게시·재시도·삭제 및 미승인/anonymous 차단 테스트를 통과시킨다.
2. App Review Information에 등록한 이메일 계정에 Admin SDK로 `{sharedRecordPublisher: true}` custom claim을 기존 claim과 병합해 발급한다. claim 발급 후 심사 계정을 다시 로그인해 새 ID token을 받는다.
3. `deletePasswordAccount`와 수정된 `publishSharedRecord`가 포함된 Functions를 운영에 배포한다.
4. 운영 Functions 배포를 확인한 뒤 `1.9.23 (42)`를 Archive하여 App Store Connect에 업로드한다.
5. App Review Information의 이메일 심사 계정이 유효한지 확인하고 빌드 42를 선택한다.
6. 위 회신을 Resolution Center에 제출하고 재심사를 요청한다.

심사 계정 capability 발급 예시(프로젝트 접근 권한이 있는 ADC 환경에서 실행):

```bash
cd functions
REVIEW_EMAIL="App Review Information에 등록한 이메일" node - <<'NODE'
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");

initializeApp({projectId: "thebest-dev"});
getAuth().getUserByEmail(process.env.REVIEW_EMAIL).then((user) =>
  getAuth().setCustomUserClaims(user.uid, {
    ...user.customClaims,
    sharedRecordPublisher: true,
  }),
);
NODE
```

## 검증 명령

```bash
flutter analyze --no-pub
flutter test --no-pub
flutter build ios --simulator --no-pub
PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH" \
  firebase emulators:exec --only firestore,functions,auth \
  "npm --prefix functions test"
```

검증 결과(2026-08-01): 정적 분석 무경고, Flutter 테스트 79개 통과, Firebase Auth/Firestore/Functions 에뮬레이터 테스트 52개 통과, iOS Simulator 빌드 통과. iPad Air 11-inch (M3) 시뮬레이터에 빌드 42를 설치해 앱 시작 화면 렌더링을 확인했다.
