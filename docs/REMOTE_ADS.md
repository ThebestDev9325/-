# 하단 광고 원격 관리

앱은 Firestore의 `adSlots/left`, `adSlots/right` 문서를 실시간으로 구독한다. Firebase Console에서 두 문서를 각각 수정하면 앱 배포나 스토어 업데이트 없이 반영된다.

## 문서 필드

| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `title` | string | 광고에 표시할 이름 |
| `url` | string | 터치 시 외부 브라우저로 열 HTTPS 주소 |
| `enabled` | boolean | `false`면 해당 칸을 빈 상태로 표시 |
| `youtube` | boolean | `true`면 YouTube 재생 아이콘 표시 |
| `backgroundStart` | number | 배경 시작색 ARGB 정수값 |
| `backgroundEnd` | number | 배경 끝색 ARGB 정수값 |

ARGB는 Flutter의 `0xFF17283A`를 10진수 `4279707706`처럼 입력한다. 색상 필드를 생략하면 앱에 내장된 기본색을 사용한다.

## 초기 값

`left`:

- `title`: `조용한 밤의 위로`
- `url`: `https://www.youtube.com/@slowhug`
- `enabled`: `true`
- `youtube`: `true`

`right`:

- `title`: `참을인`
- `url`: `https://www.youtube.com/@ThebestDev93`
- `enabled`: `true`
- `youtube`: `true`

문서가 아직 없거나 네트워크가 끊긴 경우에는 위 기본 광고가 표시된다. 앱 클라이언트의 수정은 보안 규칙으로 금지되므로 Firebase Console 또는 Admin SDK로만 변경한다.
