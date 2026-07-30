# App Store 재심사 체크리스트

대상 버전(재제출): `1.9.21 (39)` — 심사 리젝된 `1.9.20 (36)`을 대체
직전 리젝 제출 ID: `ac68bab8-eec8-41cf-8eba-77efe9f6e5e3` (Review date 2026-07-30)

## 이번 리젝 사유 (실제 원문 기준)

### Guideline 1.5 - Safety (Support URL)

Support URL `https://thebestdev9325.github.io/-/ios-support.html`이 작동하지 않고 에러(404)를 표시.

- 원인: `docs/ios-support.html`이 origin `main`에 병합되지 않아 GitHub Pages(source: `main` `/docs`)에 배포되지 않음.
- 해결: PR을 `main`에 병합 → GitHub Pages 배포 → URL 200. 병합 후 반드시 `curl -I`로 200을 확인한다.

### Guideline 2.1(a) - Performance - App Completeness (게시물 저장 실패)

"The app failed to save the post." (iPhone 17 Pro Max, iOS 26.5.2, 인터넷 연결됨)

- 근본 원인: 심사 빌드 36은 `sharedPosts`에 **직접 write**(`batch.set`)하는데, 운영 배포된 `firestore.rules`가 `allow create: if false`로 직접 생성을 차단 → `PERMISSION_DENIED` → 게시 저장 실패.
  - 빌드 36(`1.9.20+36`, 2026-07-24)은 `publishSharedRecord` 도입(`f50daa4`, 2026-07-28) 이전이라 직접 write한다.
  - 운영 `firestore.rules`(2026-07-28 배포)는 `sharedPosts { allow create: if false }`이다.
- 해결: 서버 callable(`publishSharedRecord`)로 게시하는 **빌드 39를 제출**한다. 빌드 39는 rules와 정합한다(callable은 admin 권한으로 write하므로 `allow create: if false`의 영향을 받지 않는다). `publishSharedRecord`는 `asia-northeast3`에 배포되어 있다.

## 재발 방지 (배포 순서 — 이번 리젝의 직접 원인)

직접게시 차단 rules(`allow create: if false`)는 **callable 게시를 쓰는 빌드가 심사를 통과한 뒤** 배포한다.

심사 중인 빌드가 `sharedPosts`에 직접 write하는 동안 그 경로를 막는 rules를 먼저 배포하면, 심사 리뷰어가 게시 실패를 겪어 2.1(a)로 리젝된다. rules 배포와 심사 중 빌드의 게시 경로 호환성을 항상 함께 확인한다.

## 재제출 순서 (MUST — 이 순서를 지킨다)

1. PR을 origin `main`에 병합 → `docs/ios-support.html` 배포 → `curl -I https://thebestdev9325.github.io/-/ios-support.html`로 **200 확인** (Guideline 1.5)
2. `main`에서 빌드 39 아카이브(Xcode) → App Store Connect 업로드
3. App Store Connect에서 빌드 39 선택 → 아래 심사 노트 첨부 → 재심사 제출 (빌드 36 대체) (Guideline 2.1(a))
4. `firestore.rules`(`allow create: if false`)와 `functions`(`publishSharedRecord`)는 이미 운영 배포됨 → 빌드 39 게시는 정상 동작한다. 추가 배포는 불필요하다.

## 심사 노트 (Resolution Center 회신 / App Review Notes)

```text
Thank you for the detailed feedback. We addressed both issues.

Guideline 1.5 (Support URL):
The support page is now live and returns HTTP 200:
https://thebestdev9325.github.io/-/ios-support.html
It provides in-app support contact, account deletion guidance, and content/user
reporting information.

Guideline 2.1(a) (The app failed to save the post):
The reviewed build (36) wrote shared posts directly to Firestore, but our updated
security rules route all post creation through a server-side callable
(publishSharedRecord) that performs moderation. This build (39) uses that callable
path, so saving a post now works correctly with the deployed rules.

Test steps: sign in, write a record, tap Share — the post is saved and appears in
the community feed. Tested on iPhone 17 Pro Max and iPad Air 11-inch simulators.
```

## 이전 리젝(UGC 안전장치) 대응 — 유지

빌드 39는 이전 리젝(익명 UGC 안전장치)에 대한 대응을 포함한다. 이번 리젝에서는 재지적되지 않았으나 계속 유지한다.

| 요구사항 | 구현 |
|---|---|
| `18+` 연령 등급 | App Store Connect 및 앱 초기 동의 문구 |
| 부적절한 콘텐츠 필터 | 클라이언트 사전 검사 + `publishSharedRecord` 서버 재검사 |
| 콘텐츠 신고 | 게시물 메뉴의 신고 사유 선택 + private `contentReports` |
| 피드에서 즉시 제거 | 신고·숨김 즉시 로컬 피드에서 제거 |
| 가해 사용자 차단 | 작성자 차단 후 해당 작성자의 모든 게시물 제거·영속화 |
| 본인 게시물 삭제 | 게시물 메뉴와 내 공유 화면 |
| 24시간 내 삭제·퇴출 | `deadlineAt` 신고함 + `resolve_content_report` |
| 앱 내 연락처 | 설정의 고객지원 및 신고 이메일 |
| 공개 Support URL | GitHub Pages iOS 전용 고객지원 페이지 |

## 후속 (심사와 별개)

운영 hardening 3건(정지 marker provider 우회, 신고 App Check/rate limit, 계정 삭제 시 reaction/report 카운터 정합)은 ETC-641로 분리한다. 심사 통과에 필요하지 않으므로 재제출을 지연시키지 않는다.

## 검증 명령

```bash
flutter analyze --no-pub
flutter test --no-pub
flutter build ios --simulator --no-pub
PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH" \
  firebase emulators:exec --only firestore,functions,auth \
  "npm --prefix functions test"
```

검증 결과: Flutter 68개, Functions/Firestore/Auth Emulator 48개 테스트 통과, iOS Simulator 빌드 통과.
