# LOC-582 iOS 앱 배포 마무리 및 회원탈퇴 복구 계획

## 1. 쉬운 설명

iOS에서 사용할 Firebase 앱·서명·로그인 구성을 고정하고, Kakao와 Apple로 가입한 사용자가 자신의 기록과 인증 계정을 함께 삭제할 수 있게 만든다. 마지막으로 실제 iPhone과 시뮬레이터에서 실행을 확인하고, 외부 콘솔에서 배포에 필요한 설정을 검증한다.

## 2. 범위와 가중치

- **요약:** iOS Bundle ID `com.chameulin.app`, Firebase iOS 설정, Sign in with Apple, Kakao iOS 설정, 회원탈퇴 callable을 앱과 Functions에 연결한다.
- **가중치:** Full — Flutter 앱·Firebase Functions·Apple Developer·Firebase·Kakao·실기기 서명이 함께 변경된다.

## 3. 요구사항

- [x] Apple Developer App ID 및 Team ID 확인
- [x] App Store Connect 앱 등록
- [x] Firebase iOS 앱 등록 및 `GoogleService-Info.plist` 연결
- [x] iOS Bundle ID/서명/Apple entitlement 구성
- [x] Apple 로그인 및 Apple 계정 삭제 경로 구현
- [x] Firebase에서 Anonymous/Apple provider 활성화
- [ ] Kakao 전용 앱 생성 및 `com.chameulin.app` iOS 플랫폼 등록
- [ ] Apple 회원탈퇴 callable 배포
- [x] iPhone 및 iOS Simulator 빌드·설치·실행 검증
- [ ] 변경 커밋 및 PR 생성

## 4. 비범위

- Android 로그인 동작 변경
- Firestore 데이터 모델 또는 보안 규칙 재설계
- 앱스토어 심사 제출·심사 대응
- Kakao/Apple의 외부 계정 정책 변경

## 5. 구현 대상

| 영역 | 파일/외부 설정 | 책임 |
|---|---|---|
| iOS | `ios/Runner.xcodeproj`, `Info.plist`, `Runner.entitlements`, AppIcon | Bundle ID, Team, URL scheme, Apple entitlement |
| Firebase | `firebase.json`, `lib/firebase_options.dart`, `GoogleService-Info.plist` | iOS Firebase 앱 초기화 |
| 인증 UI | `lib/main.dart`, `lib/apple_auth_service.dart`, `lib/kakao_auth_service.dart` | provider별 로그인·재인증·탈퇴 |
| 데이터/인증 | `lib/firebase_service.dart`, `functions/index.js` | 기록 삭제와 Firebase Auth 계정 삭제 |
| 검증 | `test/v10_flow_test.dart`, `test/ios_release_config_test.dart` | UI/배포 설정 회귀 방지 |
| 외부 콘솔 | Firebase, Apple Developer, App Store Connect, Kakao Developers | 실제 provider·앱 등록 |

## 6. 계약과 흐름

```text
설정 > 회원탈퇴
  ├─ Kakao 계정 → Firebase callable deleteKakaoAccount
  │                → Firestore 사용자/공유 기록 삭제
  │                → Firebase Auth 삭제
  │                → Kakao unlink(실패해도 Firebase 탈퇴는 유지)
  └─ Apple 계정 → Apple 재인증 + authorizationCode
                  → Apple token revoke
                  → Firebase callable deleteAppleAccount
                  → Firestore 사용자/공유 기록 삭제
                  → Firebase Auth 삭제
```

Callable은 인증 사용자만 허용하고, provider claim이 해당 provider인지 확인한다. 익명 사용자는 기존 데이터 삭제 경로와 구분하며, 네트워크/재인증 실패 시 계정을 삭제했다고 표시하지 않는다.

## 7. 엣지 케이스

- Apple authorization code가 없으면 token revoke를 시도하지 않고 탈퇴를 중단한다.
- 이미 익명 사용자라면 provider 재인증 없이 기존 익명 데이터 삭제 경로를 사용한다.
- Kakao unlink가 실패해도 Firebase 계정 삭제 결과는 되돌리지 않는다.
- callable 배포 권한(`iam.serviceAccounts.ActAs`)이 없으면 배포를 중단하고 관리자 조치를 기록한다.
- Kakao 앱 키가 현재 소유 계정의 앱과 다르면 코드 키를 교체한 뒤 iOS Bundle ID를 다시 등록한다.

## 8. 테스트 계획 및 현재 결과

- `flutter analyze --no-pub` — 통과
- `flutter test --no-pub` — 통과(52 tests)
- `node --check functions/index.js` — 통과
- `plutil -lint` 및 Xcode 프로젝트 검사 — 통과
- iOS debug/release/simulator build — 통과
- 실제 iPhone 설치·실행 — 통과
- 남은 검증: Kakao 전용 앱 등록, Functions 배포 후 실제 provider 탈퇴 시나리오

## 9. 리스크와 완화

- **Functions 배포 권한 부족:** Firebase 관리자에게 `thebest-dev@appspot.gserviceaccount.com` 대상 `roles/iam.serviceAccountUser` 부여를 요청한 뒤 재시도한다.
- **Kakao 앱 키 불일치:** 현재 계정의 새 앱을 만들고 iOS Bundle ID를 등록한 뒤 native app key를 단일 상수로 교체한다.
- **실기기 디버그 네트워크 제한:** release/devicectl 설치·실행으로 서명과 런타임을 검증하고, 디버그는 로컬 네트워크 권한이 허용된 환경에서 재시도한다.

## 10. 문서 영향

- DOCS-IMPACT: `README.md`에 빌드·서명·Firebase 안내를 반영함. 추가 공개 문서 없음.
- ARCH-SSOT: 없음. 기존 앱 인증/데이터 삭제 경계를 유지한다.
- ISSUE-NOTE: `~/notes/projects/chameulin/LOC-582 iOS 앱 배포 마무리.md`

## 11. 완료 게이트

1. Kakao 앱과 iOS Bundle ID 등록이 확인된다.
2. `deleteAppleAccount`가 Firebase에 배포된다.
3. 분석·테스트·iOS build가 통과한다.
4. 실기기에서 앱이 실행된다.
5. 변경사항이 커밋되고 PR이 생성된다.
