# Android 1.9.27 (47)

## 변경 사항

- 사연의 구체적인 상황을 우선하는 위로글 추천 개선.
- 건강, 직장생활, 시험준비, 가족, 연애, 대인관계, 육아, 생활, 자존감, 진로, 상실, 온라인 비교 등의 세부 상황별 위로글 보강.
- 층간소음과 야근 뒤 새벽 출근 등 일상 스트레스 상황에 맞는 본문 추가.
- 전체 콘텐츠 436개, 서로 다른 추천 상황 150개와 공통 위로.

## 버전

- applicationId: `com.chameulin.app`
- versionName: `1.9.27`
- versionCode: `47`
- 파일명: `chameulin-1.9.27-build47.aab`
- 기존 Android 릴리스 업로드 키 사용. 서명 비밀정보는 저장소에 포함하지 않는다.

## 검증

- `flutter analyze --no-pub`: 문제 없음.
- `flutter test --no-pub`: 356개 통과.

이 작업은 업로드용 파일 생성까지이며 Play Console 업로드 및 배포는 수행하지 않는다.

## 빌드 결과

- flutter build appbundle --release: 성공.
- jarsigner 검증: jar verified.
- 이전 1.9.20 (36) 릴리스와 서명 인증서 SHA-256 일치 확인.
- 파일 크기: 75,700,056 bytes.
- AAB SHA-256: 5E0C9C5CB6A590717DECA2C11A65EEB40F8AFA30980DD661835F441845177929.
