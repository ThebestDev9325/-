# v10 요구사항 10개 구현 리서치

조사일: 2026-07-12  
원칙: Flutter, Firebase, Android, Apple, Kakao, W3C의 공식 문서를 우선 사용한다.

## 1. 닉네임 중복 방지

- Firestore 트랜잭션은 읽은 문서가 동시에 변경되면 자동으로 재시도하며, 성공한 쓰기는 원자적으로 함께 적용된다. 따라서 정규화한 닉네임을 문서 ID로 삼고 `nicknames/{key}`를 읽은 뒤 생성하는 현재 구조가 동시 선점 방지에 적합하다.
- 트랜잭션은 오프라인에서 실패하므로 “이미 사용 중”과 “네트워크로 확인하지 못함”을 서로 다른 문구로 안내해야 한다.
- 클라이언트 검증만 신뢰하지 않고 Security Rules에서도 소유자, 허용 필드, 문자열 길이를 검증해야 한다.
- Flutter 입력 화면은 제출 시 친절한 필드 오류를 보여주고, 확인 중에는 중복 제출을 막는 방식이 권장된다.

현재 적용: 트랜잭션 선점, 2~12자 검증, 확인 중 버튼 잠금, 중복/네트워크 오류 분리.  
추가 보완: Rules의 허용 필드·문자열 길이·소유권 불변 조건 강화.

출처:
- https://firebase.google.com/docs/firestore/manage-data/transactions
- https://firebase.google.com/docs/firestore/transaction-data-contention
- https://firebase.google.com/docs/firestore/security/rules-fields
- https://docs.flutter.dev/cookbook/forms/validation

## 2. 시작 화면 문구

- 온보딩의 첫 문구는 앱이 사용자에게 제공하는 가치를 짧고 직접적으로 설명해야 한다.
- 현재 문구 `내 마음을 위해, 참을인 하나.`는 행동을 강요하기보다 사용자 자신의 마음을 돌본다는 이점을 먼저 말하므로 앱의 위로 중심 방향과 일치한다.
- 화면 폭이 좁아져도 의미 단위인 `내 마음을 위해,`와 `참을인 하나.`가 분리되도록 고정 2행을 유지한다.

현재 적용: 홈의 이전 문구 제거, 새 문구 2행 적용, 회귀 테스트 추가.

## 3. 획순 이미지 전환

- Flutter의 `precacheImage`는 실제 표시 전에 이미지를 이미지 캐시에 올려 첫 프레임 지연을 줄인다.
- 이미지가 바뀔 때 레이아웃 크기까지 바뀌면 흔들림이 생기므로 고정 `SizedBox` 안에서 동일한 `BoxFit.contain`을 사용해야 한다.
- `AnimatedSwitcher`의 키를 획 번호로 구분하면 짧은 페이드 전환을 적용할 수 있다.
- 다이얼로그를 닫을 때 주기 타이머를 반드시 취소해야 닫힌 위젯을 갱신하는 오류가 생기지 않는다.

현재 적용: 7장 사전 로딩, 240×240 고정 영역, 180ms 전환, 키 분리, 닫기/완료 시 타이머 해제.

출처:
- https://api.flutter.dev/flutter/widgets/precacheImage.html
- https://api.flutter.dev/flutter/widgets/AnimatedSwitcher-class.html

## 4. 하루 세 번째 작성 이스터에그

- 팝업은 선택을 요구하는 화면이 아니라 상황을 알리고 확인받는 `AlertDialog`가 적합하다.
- 사용자가 실제로 저장한 기록만 횟수에 포함하고, 작성 화면 진입이나 중도 취소는 세지 않아야 한다.
- 세 번째에만 표시하고 네 번째 이후 반복하지 않아야 특별한 발견의 느낌이 유지된다.
- 날짜 판정은 현재 기기의 현지 날짜로 하고, 장기적으로 여러 시간대 기기 동기화가 필요하면 사용자 프로필 시간대를 저장하는 편이 안전하다.

현재 적용: 저장된 오늘 기록 수 + 1로 계산, 정확히 세 번째만 표시, 네 번째 미표시 테스트 추가.  
추가 고려: 앱 강제 종료 중 팝업 복원까지 요구될 경우 `Navigator.restorablePush` 방식 검토.

출처:
- https://api.flutter.dev/flutter/material/AlertDialog-class.html
- https://api.flutter.dev/flutter/material/showDialog.html

## 5. `1 / 5` 페이지 번호 제거

- Flutter `AppBar`는 제목이 없어도 이전 경로가 있으면 자동으로 뒤로가기 버튼을 넣는다.
- 따라서 숫자 제목만 제거하고 AppBar를 유지하면 사용자는 언제든 흐름을 취소해 돌아갈 수 있다.
- 각 단계의 큰 제목이 현재 해야 할 일을 설명하므로 별도 진행 숫자가 없어도 이해 가능하다.

현재 적용: 빈 AppBar로 숫자 제거, 자동 뒤로가기 유지, 숫자 부재 테스트 추가.

출처:
- https://api.flutter.dev/flutter/material/AppBar-class.html

## 6. 이야기 평가 색상

- WCAG는 색상만으로 상태를 전달하지 말 것을 요구한다. 색을 달리하더라도 선택 상태, 텍스트, 컨트롤 상태가 함께 전달돼야 한다.
- 연두·노랑·살구색은 감정적 위계를 과도하게 만들지 않으면서 선택지를 구분한다.
- `ChoiceChip.selected`를 유지하면 색 외에도 선택 상태가 의미 구조와 시각 상태로 전달된다.

현재 적용: 좋아요=연두, 잘 모르겠어요=노랑, 별로에요=살구; ChoiceChip의 선택 상태 병행.

출처:
- https://www.w3.org/WAI/WCAG20/Understanding/use-of-color
- https://www.w3.org/WAI/WCAG20/Understanding/contrast-minimum.html

## 7. 공유 및 계정 연동 준비 화면

- 핵심 기록 기능은 로그인 없이 사용할 수 있게 두고, 공개 게시처럼 계정 책임성이 필요한 기능에서만 연동을 요청하는 흐름이 적절하다.
- Firebase는 Flutter에서 Google과 Apple 공급자 로그인을 지원한다.
- 카카오 네이티브 앱은 카카오톡 설치 여부를 확인한 뒤 카카오톡 로그인, 미설치 시 카카오계정 로그인을 제공하는 방식이 권장된다.
- iOS에서 제3자 소셜 로그인을 기본 계정 수단으로 제공하면 Apple의 동등한 로그인 옵션 요구사항을 검토해야 한다. 계정 생성 기능이 있다면 앱 안의 계정 삭제 기능도 계획해야 한다.

현재 적용: 노란 공유 버튼, 계정 연동 안내 페이지, 카카오/Google/Apple 준비 버튼, 실제 게시 차단.  
추후 구현 순서: 공급자 콘솔 설정 → 익명 Firebase 계정에 자격 증명 연결(link) → 기존 기록 보존 → 실패/취소 처리 → 계정 삭제.

출처:
- https://firebase.google.com/docs/auth/flutter/federated-auth
- https://developers.kakao.com/docs/ko/kakaologin/flutter
- https://developer.apple.com/app-store/review/guidelines/

## 8. 공감 탭의 실제 사용자 게시물

- Firestore 실시간 스냅샷 스트림은 서버 데이터 변경을 UI에 반영하는 데 적합하다.
- 최신 글만 제한해 읽고, 장기적으로 글이 늘면 커서 기반 페이지네이션을 추가해야 비용과 메모리를 제어할 수 있다.
- Security Rules는 필터가 아니므로 공개 여부 같은 조건을 추가할 경우 쿼리에도 동일한 조건을 포함해야 한다.
- 샘플 글은 운영 데이터와 섞지 않고 빈 상태 UI로 대체해야 베스트 글 계산이 실제 반응만 반영한다.

현재 적용: 코드 샘플 2개 제거, `sharedPosts` 스트림만 표시, 최대 100개 제한, 빈 상태 안내, 실제 반응 기반 베스트 계산.

출처:
- https://firebase.google.com/docs/firestore/query-data/order-limit-data
- https://firebase.google.com/docs/firestore/query-data/query-cursors
- https://firebase.google.com/docs/firestore/security/rules-query

## 9. 긍정 글의 `아이콘 + 긍정` 제거

- 카드가 이미 `오늘의 긍정` 화면 안에 있으므로 같은 의미의 칩은 정보 위계를 추가하지 않고 반복한다.
- 반복 칩을 제거하면 제목이 첫 번째 핵심 정보가 되고, 작은 화면에서 본문에 더 많은 공간을 줄 수 있다.

현재 적용: 긍정 카드의 Chip 제거, 제목부터 표시, Chip 부재 테스트 추가.

## 10. 앱 아이콘

- Android 적응형 아이콘은 제조사별 원·스퀘어클 마스크에 대응하기 위해 전경과 배경 두 레이어를 제공해야 한다.
- 108×108 기준 중앙 66×66 안전영역은 어떤 마스크에서도 잘리지 않는다. 핵심 `忍`은 이 영역에 들어가야 한다.
- Android 13 이상의 테마 아이콘을 위해 단색 레이어를 제공할 수 있다.
- Google Play 신규/업데이트 앱은 현재 API 35 이상을 대상으로 해야 하며, 현재 빌드는 compile/target API 요구를 충족하는지 APK에서 함께 확인한다.

현재 적용: 모든 레거시 밀도 PNG 교체, 녹색·나무·忍 원본 보관.  
이번 보완: Android 8 이상 적응형 전경/배경 리소스와 Android 13 테마용 단색 레이어 추가.

출처:
- https://developer.android.com/develop/ui/compose/system/icon_design_adaptive
- https://developer.android.com/develop/ui/views/launch/splash-screen
- https://developer.android.com/google/play/requirements/target-sdk

## 결론

현재 v10의 사용자 흐름은 요청과 일치한다. 이번 감사에서 필요한 실질 보완은 다음 세 가지다.

1. 닉네임 Security Rules의 스키마·길이·소유권 불변 조건 강화
2. 요구사항별 자동 회귀 테스트 확대
3. Android 적응형/테마 아이콘 레이어 추가
