# App Store 재심사 체크리스트

대상 버전: `1.9.21 (39)`
거절 제출 ID: `ac68bab8-eec8-41cf-8eba-77efe9f6e5e3`

## App Store Connect 설정

- 앱 정보 → 연령 등급에서 익명 UGC 요구에 맞게 `18+`로 설정
- 앱 정보 → 연령 등급 → `Advertising`을 `Yes`로 설정
- Support URL을 `https://thebestdev9325.github.io/-/`로 변경
- GitHub Issues URL `https://github.com/ThebestDev9325/-/issues`는 사용하지 않음

## 배포 및 운영

1. `firebase deploy --only functions`
2. 신규 Functions의 구버전 신고 및 게시물 필터 smoke test
3. `node functions/scripts/migrate_reported_by.js`
4. `firebase deploy --only firestore:rules`
5. Cloud Logging의 `content_report_received`, `deadline_approaching`, `deadline_overdue` 로그를 개발자 이메일 알림 채널에 연결
6. 신고 접수 시 `contentReports`를 확인하고 24시간 이내 다음 명령으로 처리

```bash
node functions/scripts/resolve_content_report.js REPORT_ID remove-and-suspend
node functions/scripts/resolve_content_report.js REPORT_ID reject
```

## 검증 명령

```bash
flutter analyze --no-pub
flutter test --no-pub
flutter build ios --simulator --no-pub
PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH" \
  firebase emulators:exec --only firestore,functions,auth \
  "npm --prefix functions test"
```

검증 결과: Flutter 테스트 64개, Functions/Firestore/Auth Emulator 테스트
21개, iPhone 17 Pro Max 및 iPad Air 11-inch 시뮬레이터 렌더링을 통과했다.

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
