# App Store 재심사 체크리스트

대상 버전: `1.9.21 (39)`
거절 제출 ID: `ac68bab8-eec8-41cf-8eba-77efe9f6e5e3`

## App Store Connect 설정

- [x] 앱 정보 → 연령 등급에서 익명 UGC 요구에 맞게 `18+`로 설정
- [x] 앱 정보 → 연령 등급 → `Advertising`을 `Yes`로 설정
- [x] Support URL을 `https://thebestdev9325.github.io/-/`로 변경
- GitHub Issues URL `https://github.com/ThebestDev9325/-/issues`는 사용하지 않음
- 지원 페이지는 PR 병합 후 GitHub Pages에서 공개되는지 확인

## 배포 및 운영

1. `firebase deploy --only firestore:indexes`
2. `firebase firestore:indexes`에서 `contentReports` 복합 인덱스가
   `READY`인지 확인
3. `firebase deploy --only functions`
4. `publishSharedRecord`와 구버전 `reportSharedPost` smoke test
5. `node functions/scripts/migrate_reported_by.js`
6. App Store 재심사 전에 `firebase deploy --only firestore:rules`
7. 새 iOS/Android 앱을 배포하고 서버 전용 게시 경로 사용 여부 확인
8. 구버전 앱의 직접 공유가 차단되는 기간에는 공유 실패 문의를 모니터링
9. Cloud Logging의 `content_report_received`, `deadline_approaching`,
   `deadline_overdue`, `moderation_action_required`,
   `moderation_action_overdue` 로그를 개발자 이메일 알림 채널에 연결
10. 신고 접수 시 `contentReports`를 확인하고 24시간 이내 다음 명령으로 처리

```bash
node functions/scripts/resolve_content_report.js REPORT_ID remove-and-suspend
node functions/scripts/resolve_content_report.js REPORT_ID reject
```

### 호환 배포 원칙

- 확장 단계에서는 `reportedBy`를 유지하면서 비공개 `contentReports`를 함께
  기록한다. 마이그레이션도 `reportedBy`를 삭제하지 않는다.
- 이 단계에서 Functions를 롤백해야 하면 `reportedBy`와
  `contentReports`를 모두 이해하는 이 커밋으로 롤백한다.
- 모든 활성 클라이언트와 롤백 기간이 지난 뒤 별도 축소 배포에서
  `reportedBy` 쓰기와 기존 필드를 제거한다.
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
37개, iOS Simulator 빌드, iPhone 17 Pro Max 및 iPad Air 11-inch
시뮬레이터 렌더링을 통과했다.

## 심사 노트

```text
We implemented all required safeguards for anonymous user-generated content.

1. Objectionable content is filtered before sharing and revalidated by Firebase server-side moderation.
2. Users can report a post and select a report reason from the post's (...) menu.
3. Users can immediately hide a post from the same menu.
4. Users can block an anonymous author from the same menu. All posts from that author are immediately removed from the feed.
5. Users can delete their own posts from the post menu or the My Shares tab.
6. Reports are added to a private moderation queue and reviewed within 24 hours. Violating content is removed and the offending account is suspended.
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
