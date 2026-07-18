# Codex 인수인계

작성일: 2026-07-18 (Asia/Seoul)

## 최신 상태

- 기준 브랜치: `main`
- 현재 앱 버전: `1.9.15+31`
- Android Google Play 내부 테스트 v31 업데이트 확인 완료
- 저장된 비공개 기록의 다시 공유 기능까지 구현 완료
- 공감 탭 연·월·일 선택과 날짜별 BEST 조회 구현 완료
- 맞춤 위로 이야기 300개와 상황 분석 추천 구현 완료
- 저장소: https://github.com/ThebestDev9325/-
- 현재 확인된 즉시 수정 사항 없음

## 최신 Android 배포

- Play Console 내부 테스트 활성 버전: v31 (`1.9.15`)
- 배포 AAB 이름: `chameulin-1.9.15-build31.aab`
- 로컬 산출물: `C:\Users\user\Downloads\chameulin-1.9.15-build31.aab`
- SHA-256: `829E331071172DE515D448B06C8D9A212FF07ABB7E289669ED67D7F65AE84A09`
- v30의 versionCode 30은 Play Console에 한 번 등록되어 재사용할 수 없으므로 v31을 사용했다.

## iOS 출시 인계

- 친구의 Apple Developer 계정과 Mac에서 iOS 출시를 진행할 예정이다.
- Mac에서 `git clone https://github.com/ThebestDev9325/-.git`로 같은 Flutter 프로젝트를 내려받는다.
- 비공개 저장소라면 친구 GitHub 계정을 Collaborator로 먼저 초대한다.
- Apple Bundle ID, Signing Team, 인증서, 프로비저닝 프로파일과 App Store Connect 앱 등록은 친구 계정 기준으로 설정해야 한다.
- Android/Firebase/Kakao 설정과 별도로 iOS용 Firebase 및 Kakao 플랫폼 설정을 확인해야 한다.

## 광고 레이아웃

- `lib/main.dart`의 `AppShell` 하단 내비게이션 아래에 `BottomAdSlots`를 추가했다.
- 전체 높이는 50px이고 화면 너비를 1:1로 나눈다.
- 왼쪽 영역은 `홈 ~ 공감`, 오른쪽 영역은 `내 공유 ~ 설정` 탭 구간과 맞닿는다.
- 하단 시스템 제스처 영역은 `SafeArea` 처리했다.
- 밝은/어두운 테마의 `ColorScheme`을 사용하며, 현재 각 슬롯에 옆게 `광고`가 표시된다.
- 슬롯 식별 키는 `bottom-ad-slot-1`, `bottom-ad-slot-2`이다.

## 최신 검증

- `flutter analyze` 통과
- 전체 `flutter test` 39개 통과
- `flutter build appbundle --release` 성공

## APK v7

- 로컬 산출물: `C:\Users\user\Downloads\chameulin-v7.apk`
- 빌드 번호: 7
- SHA-256: `DF4863170D33ACE0BC881A065DB1A380A5FC4AE29CB48634A12600A6FCCC8651`
- 용량: 153,053,531 bytes
- 정식 업로드 키가 로컬에 없어 Android 디버그 키로 서명한 테스트용 APK다.

## 다음 광고 작업 시

1. 사용할 광고 네트워크/SDK와 Android 앱 ID, 왼쪽·오른쪽 광고 단위 ID를 확인한다.
2. 실제 광고 위젯을 `_AdSlot`에 연결하되, 로딩/실패/미설정 상태에서도 50px 레이아웃이 흔들리지 않게 한다.
3. 개발 중에는 광고 사업자의 테스트 광고 ID만 사용한다.
4. 정식 배포 APK/AAB를 만들려면 Git에 포함되지 않는 기존 업로드 키(`.jks`)와 `android/key.properties`가 필요하다.
