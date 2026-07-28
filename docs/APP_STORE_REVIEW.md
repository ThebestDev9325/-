# App Store 재심사 체크리스트

대상 버전: `1.9.21 (39)`
거절 제출 ID: `ac68bab8-eec8-41cf-8eba-77efe9f6e5e3`

## App Store Connect 설정

- [x] 앱 정보 → 연령 등급에서 익명 UGC 요구에 맞게 `18+`로 설정
- [x] 앱 정보 → 연령 등급 → `Advertising`을 `Yes`로 설정
- [x] Support URL을 `https://thebestdev9325.github.io/-/`로 변경
- GitHub Issues URL `https://github.com/ThebestDev9325/-/issues`는 사용하지 않음
- 지원 페이지는 PR 병합 후 GitHub Pages에서 공개되는지 확인

## 심사 필수 범위

| 요구사항 | 구현 |
|---|---|
| `18+` 연령 등급 | App Store Connect 및 앱 초기 동의 문구 |
| 부적절한 콘텐츠 필터 | 클라이언트 사전 검사 + `publishSharedRecord` 서버 재검사 |
| 콘텐츠 신고 | 게시물 메뉴의 신고 사유 선택 + private `contentReports` |
| 피드에서 즉시 제거 | 신고 또는 숨김 선택 즉시 로컬 피드에서 제거 |
| 가해 사용자 차단 | 작성자 차단 후 해당 작성자의 모든 게시물 제거·영속화 |
| 본인 게시물 삭제 | 게시물 메뉴와 내 공유 화면 |
| 24시간 내 삭제·퇴출 | `deadlineAt` 신고함 + `resolve_content_report` |
| 앱 내 연락처 | 설정의 고객지원 및 신고 이메일 |
| 공개 Support URL | GitHub Pages 고객지원 페이지 |

심사에 필요하지 않은 오프라인 신고 재전송, 별도 요청 멱등 레지스트리,
시간당 신고 제한, 해결 신고 TTL, 자동 스케줄러는 사용하지 않는다.

## 배포 및 운영

1. `firebase deploy --only firestore:indexes`
2. `firebase firestore:indexes`에서 `contentReports` 복합 인덱스가
   `READY`인지 확인
3. `firebase deploy --only functions`
4. `publishSharedRecord`와 구버전 `reportSharedPost` smoke test
5. App Store 재심사 전에 `firebase deploy --only firestore:rules`
6. 새 iOS/Android 앱을 배포하고 서버 전용 게시 경로 사용 여부 확인
7. 구버전 앱의 직접 공유가 차단되는 기간에는 공유 실패 문의를 모니터링
8. `content_report_received` 로그와 비공개 `contentReports` 신고함을 매일 확인
9. 신고 접수 후 24시간 이내 다음 명령으로 처리

```bash
node functions/scripts/resolve_content_report.js REPORT_ID remove-and-suspend
node functions/scripts/resolve_content_report.js REPORT_ID reject
```

### 호환 배포 원칙

- 비공개 `contentReports`가 신고 중복과 운영 상태의 기준이다.
- 운영자 정지는 비공개 `moderationSuspensions` marker를 게시물 제거와
  원자적으로 기록한다. Rules와 callable이 marker를 확인하므로 기존 ID
  token이 남아 있어도 사용자 write와 재게시가 즉시 차단된다.
- 새 앱은 신고 당시 `ownerId`를 callable에 전달한다. 서버는 현재 소유자와
  일치할 때만 신고를 기록하므로 삭제된 post ID가 다른 소유자에게
  재사용되어도 새 게시물을 잘못 신고하지 않는다.
- `contentReports` 문서 ID가 같은 사용자·게시물 lifecycle의 중복 신고를
  방지하며 공개 게시물에는 신고자 UID를 기록하지 않는다.
- Firestore의 직접 게시 차단 규칙은 App Store 재심사 전에 운영에 배포한다.
  구버전 앱의 직접 공유는 새 앱 배포 전까지 일시 중단될 수 있다.

## 검증 명령

```bash
flutter analyze --no-pub
flutter test --no-pub
flutter build ios --simulator --no-pub
PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH" \
  firebase emulators:exec --only firestore,functions,auth \
  "npm --prefix functions test"
```

검증 결과: Flutter 테스트 68개, Functions/Firestore/Auth Emulator 테스트
43개, iOS Simulator 빌드, iPhone 17 Pro Max 및 iPad Air 11-inch
시뮬레이터 렌더링을 통과했다.

## 심사 노트

```text
We implemented all required safeguards for anonymous user-generated content.

1. Objectionable content is filtered before sharing and revalidated by Firebase server-side moderation.
2. Users can report a post and select a report reason from the post's (...) menu.
3. Users can immediately hide a post from the same menu.
4. Users can block an anonymous author from the same menu. All posts from that author are immediately removed from the feed.
5. Users can delete their own posts from the post menu or the My Shares tab.
6. Reports are recorded in a private moderation inbox and reviewed within 24 hours. Violating content is removed and the offending account is suspended.
7. In-app contact information is available under Settings > Customer Support and Report.
8. The public support page is https://thebestdev9325.github.io/-/

The app is restricted to users aged 18 or older.
```

## 심사 기기 확인

- iPhone 17 Pro Max 크기에서 게시물 메뉴와 신고 사유 sheet 확인
- iPad Air 11-inch 크기에서 게시물 메뉴와 설정 지원 항목 확인
- 신고 직후 게시물이 피드에서 사라지는지 확인
- 작성자 차단 직후 동일 작성자의 모든 게시물이 사라지는지 확인
- 내 게시물 삭제 후 내 공유 및 공감 피드에서 사라지는지 확인
- 설정의 이메일과 지원 페이지가 실제로 열리는지 확인
