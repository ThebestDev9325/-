# 참을인 프로젝트 작업 규칙

이 저장소에서 구현 작업을 요청받으면 사용자가 별도로 말하지 않아도 아래 절차를 항상 적용한다.

1. `C:\Users\user\chameulin_flutter_v1`을 기준 로컬 저장소로 사용한다.
2. 작업 전에 `origin`을 fetch/prune하고 최신 `origin/main`을 기준으로 삼는다. 기준 저장소의 `main`이 깨끗하면 fast-forward로 최신화하며, 기존 로컬 변경을 덮어쓰지 않는다.
3. `main`이나 기준 저장소에서 직접 수정하지 않는다. `agent/<task-slug>` 브랜치를 만들고 `C:\Users\user\chameulin-worktrees\<task-slug>`에 별도 Git worktree를 생성한다.
4. 코드 확인, 수정, 의존성 설치, 분석, 테스트, 빌드는 모두 작업용 worktree에서 수행한다.
5. 관련 검증을 통과한 뒤 요청 범위의 파일만 커밋하고 원격 브랜치로 push한다.
6. `main` 대상의 ready-for-review PR을 생성하고 즉시 merge commit 방식으로 병합한다. 필수 체크 때문에 바로 병합할 수 없으면 auto-merge를 활성화하고, 병합을 막는 조건을 보고한다.
7. 병합이 확인되면 `origin`을 다시 fetch하고, 깨끗한 기준 `main`을 fast-forward한 뒤 완료된 worktree와 로컬 작업 브랜치를 안전하게 정리한다. 커밋되지 않은 변경이 남은 worktree는 삭제하지 않는다.

사용자의 참을인 프로젝트 구현 요청은 위 과정에 필요한 브랜치 생성, 커밋, push, PR 생성 및 병합을 수행하라는 명시적 승인으로 간주한다. 관련 없는 변경은 커밋이나 PR에 포함하지 않는다.
