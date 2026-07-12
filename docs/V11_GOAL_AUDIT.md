# v11 GOAL 완료 감사

감사일: 2026-07-12

## 번호별 체크리스트와 증거

### 1. 닉네임 중복 방지

- [x] 2~12자 및 허용 문자 입력 검증
- [x] 정규화한 닉네임 문서를 Firestore 트랜잭션으로 선점
- [x] 동시 변경 시 Firestore 자동 재시도 구조
- [x] 중복 문구와 네트워크 오류 문구 분리
- [x] 버튼 중복 제출 방지
- [x] 기존 익명 사용자 닉네임 복원
- [x] Rules에서 허용 필드·길이·소유자 불변·서버 시간 검증

증거: `lib/main.dart`의 `SplashNicknameFlow`, `lib/firebase_service.dart`의 `claimNickname`, `firestore.rules`; Firebase 프로젝트 `thebest-dev` 규칙 컴파일·배포 성공.

### 2. 홈 문구

- [x] `내 마음을 위해,\n참을인 하나.` 적용
- [x] 이전 문구 제거
- [x] 위젯 회귀 테스트

증거: `test/v10_requirements_test.dart`의 홈 문구 테스트.

### 3. 획순 전환

- [x] 7장 사전 로딩
- [x] 240×240 고정 영역
- [x] `AnimatedSwitcher`와 획별 키 적용
- [x] 닫기·완료 시 타이머 해제
- [x] 실제 다음 획 이미지 전환 테스트

증거: `WritingFlow.showStrokeOrder`, 획순 전환 위젯 테스트.

### 4. 세 번째 작성 이스터에그

- [x] 저장된 오늘 기록만 계산
- [x] 정확히 세 번째에만 안내
- [x] 안내 후 다음 단계 이동
- [x] 네 번째 이후 반복하지 않음
- [x] 세 번째·네 번째 경계 자동 테스트

증거: `todayWritingNumber`, `completeDrawing`, 경계 위젯 테스트 2개.

### 5. 페이지 번호 제거

- [x] `1 / 5`~`5 / 5` 제거
- [x] AppBar 자동 뒤로가기 유지
- [x] 페이지 숫자 부재 테스트

증거: `WritingFlow`의 빈 `AppBar`, `test/v10_flow_test.dart`.

### 6. 이야기 평가 색상

- [x] 좋아요 연두색
- [x] 잘 모르겠어요 노란색
- [x] 별로에요 살구색
- [x] 색 외에 `ChoiceChip.selected` 상태 유지
- [x] 한 줄 레이블 유지

증거: `_storyPage`의 `ChoiceChip` 설정과 선택 상태.

### 7. 저장·공유 및 계정 연동 준비

- [x] 내 기록 저장 녹색 유지
- [x] 공유 버튼 노란색 적용
- [x] 공유 버튼이 즉시 게시하지 않음
- [x] 계정 연동 안내 페이지
- [x] 카카오·Google·Apple 선택지
- [x] 현재 준비 단계 안내 및 실제 가입 차단
- [x] 계정 연동 페이지 위젯 테스트

증거: `_savePage`, `AccountLinkPage`, `test/v10_flow_test.dart`.

### 8. 실제 사용자 공감 글

- [x] 코드 샘플 사연 2개 제거
- [x] Firebase `sharedPosts` 스냅샷만 사용
- [x] 실제 반응 수 기반 베스트 계산
- [x] 게시물 0건 빈 상태
- [x] 샘플 문구·가짜 베스트 부재 테스트

증거: `AppShell.sharedPosts`, `watchSharedPosts`, `EmpathyPage`, 빈 상태 위젯 테스트.

### 9. 긍정 칩 제거

- [x] 카드의 `아이콘 + 긍정` 칩 제거
- [x] 제목부터 표시
- [x] Chip 부재 테스트

증거: `PositivePage`와 긍정 카드 위젯 테스트.

### 10. 앱 아이콘

- [x] 녹색·나무·`忍` 디자인
- [x] mdpi~xxxhdpi 레거시 PNG
- [x] Android 8+ 적응형 배경·전경 레이어
- [x] Android 13+ 단색 테마 레이어
- [x] 전경 핵심 요소를 중앙 안전영역 안에 배치
- [x] 모든 리소스 존재 자동 테스트
- [x] APK 리소스 테이블에서 배경·전경·mipmap 확인

증거: `assets/branding/app_icon_foreground_v11.png`, Android `mipmap-anydpi-v26/v33`, 아이콘 리소스 테스트, `aapt dump resources`.

## 통합 게이트

- [x] `flutter analyze`: No issues found
- [x] `flutter test`: 13 tests passed
- [x] Firestore Rules: compile and deploy succeeded
- [x] Release APK build succeeded
- [x] 패키지 `com.chameulin.app`
- [x] versionName `1.7.1`, versionCode `11`
- [x] 릴리스 인증서 `CN=Chameulin`
- [x] APK SHA-256 `6B0C05C101F4C2EDFF9CB3BD4FE3D0D5E5C8C69750EC5698A78E74EB15A5D01C`
- [x] 다운로드 결과물 `C:\Users\user\Downloads\참을인-v11.apk`
