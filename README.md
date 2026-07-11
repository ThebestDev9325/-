# 참을인 Flutter

화난 마음을 기록하고 이야기를 추천받는 Flutter Android 앱입니다. Firebase 익명 인증과 Cloud Firestore를 사용합니다.

## 포함 기능

- 3초 스플래시
- 첫 실행 닉네임 설정
- 1초 환영 화면
- 참을 인 직접 그리기
- 7단계 획순 이미지 애니메이션
- 상황 및 감정 입력
- 로컬 이야기 추천 엔진
- Firebase 익명 인증
- Firestore 기록 동기화
- 익명 공유 / 공감 / 신고 저장
- 내 기록 달력 / 월 이동 / 2026~2030년 선택
- 한 날짜에 여러 기록 조회
- 공감 탭 / 오늘의 Best / 신고
- 내 글 직접 공감 방지
- 내 공유 탭
- 오늘의 긍정 랜덤 DB
- 다크모드 / 효과음 / 배경음악 토글
- AI 이야기 스타일 선택
- 데이터 삭제 / 회원탈퇴 UI 자리

## 실행 방법

프로젝트 폴더에서 아래 명령을 실행합니다.

```bash
flutter pub get
flutter run
```

## 빌드

```bash
flutter build apk --release
flutter build appbundle --release
```

Firebase 프로젝트는 `thebest-dev`, Android 패키지명은 `com.chameulin.app`입니다.

## 참고

업로드 키(`.jks`)와 `android/key.properties`는 보안을 위해 Git에 포함하지 않습니다.
