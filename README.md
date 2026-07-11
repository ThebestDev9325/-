# 참을인 Flutter v1

Firebase를 연결하기 전 단계의 로컬 Flutter MVP입니다.

## 포함 기능

- 3초 스플래시
- 첫 실행 닉네임 설정
- 1초 환영 화면
- 참을 인 직접 그리기
- 7단계 획순 이미지 애니메이션
- 상황 및 감정 입력
- 로컬 추천 엔진
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

이 압축본은 Flutter 소스 프로젝트입니다.

1. Flutter SDK와 Android Studio를 설치합니다.
2. 압축을 풉니다.
3. 프로젝트 폴더에서 아래 명령을 실행합니다.

```bash
flutter create . --platforms=android
flutter pub get
flutter run
```

`flutter create .`는 Android 빌드용 폴더만 생성하며, 이 프로젝트의 `lib`와 `assets`는 유지됩니다.

## 다음 단계: Firebase

추후 아래 기능을 Firebase에 연결하면 됩니다.

- Firebase Authentication
- Cloud Firestore
- 신고 데이터
- 공감 중복 방지
- 사용자별 기록 동기화
- 회원탈퇴 및 데이터 삭제
- 관리자 게시글 숨김/삭제

## 참고

현재 소셜 로그인 버튼과 실제 서버 저장은 연결하지 않은 1단계 버전입니다.
