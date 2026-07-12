# Codex 인수인계

작성일: 2026-07-12 (Asia/Seoul)

## 최신 상태

- 기준 브랜치: `main`
- 광고 영역 추가 커밋: `4162e57`
- 병합 PR: [#4](https://github.com/ThebestDev9325/-/pull/4)
- 병합 커밋: `9f79de3`
- 광고 SDK는 아직 연동하지 않았고, 화면에 배너 자리만 예약한 상태다.

## 광고 레이아웃

- `lib/main.dart`의 `AppShell` 하단 내비게이션 아래에 `BottomAdSlots`를 추가했다.
- 전체 높이는 50px이고 화면 너비를 1:1로 나눈다.
- 왼쪽 영역은 `홈 ~ 공감`, 오른쪽 영역은 `내 공유 ~ 설정` 탭 구간과 맞닿는다.
- 하단 시스템 제스처 영역은 `SafeArea` 처리했다.
- 밝은/어두운 테마의 `ColorScheme`을 사용하며, 현재 각 슬롯에 옆게 `광고`가 표시된다.
- 슬롯 식별 키는 `bottom-ad-slot-1`, `bottom-ad-slot-2`이다.

## 검증

- `test/widget_test.dart`에 두 광고 슬롯의 너비가 같고 전체 높이가 50px인지 확인하는 위젯 테스트가 있다.
- 추가 당시 `flutter test` 2개가 모두 통과했다.
- `flutter analyze`에는 변경과 무관한 기존 info 수준 경고 5개가 남아 있다.

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
