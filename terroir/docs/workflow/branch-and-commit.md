# 브랜치와 커밋

브랜치 운영과 커밋 메시지 규칙입니다. 커밋 규칙은 husky hook이 자동으로 강제합니다.

## 규칙 요약

1. `develop` = DEV 환경, `main` = PROD 환경(지원 예정). 작업은 항상 `feature/*`에서.
2. `feature/*` → `develop` PR → 머지되면 DEV에 자동 배포.
3. 커밋 메시지는 `type(scope): subject` — **scope 필수.** husky가 검증하며 형식이 틀리면 커밋이 차단된다.
4. 커밋 시 변경 파일에 `eslint --fix` + `prettier`가 자동 적용된다(lint-staged).
5. git hook은 원칙적으로 우회(`--no-verify`)하지 않는다 — 긴급 예외로 우회해도 "갚아야 할 빚"이다. AI 어시스턴트는 예외 없이 금지.

## 브랜치 → 환경 매핑

| 브랜치 | 환경 | 상태 |
|--------|------|------|
| `develop` | DEV | ✅ 머지 시 자동 배포 |
| `main` | PROD | 브랜치 플로우는 정의됨(아래) — PROD **배포**만 지원 예정 |
| `feature/*` | — | 작업 브랜치. `develop`으로만 PR (develop행 작업 브랜치는 이 패턴만 허용) |
| `hotfix/*` | — | `main`으로 PR — CI에서 이미 허용. 운영 긴급 수정용 |
| `release/*` | — | 미정 — 허용 목록에 없음(배포 묶음 준비용, 필요 시 정의) |

허용되는 PR 흐름은 CI가 강제합니다(`feature/*→develop`, `hotfix/*→main`, `develop→main` 세 가지만 통과 —
`100-terroir-pr-checks.yml`의 `branch-flow`). `fix/*`·`chore/*` 같은 다른 작업 브랜치는 `develop`행이라도 차단됩니다.

브랜치→환경 매핑은 현재 **CI/CD 워크플로에 직접** 있습니다(delivery 워크플로가 `base_ref`로 판정 — `develop→dev`, `main→prod`).
`terroir.json`의 `environments` 필드는 이 매핑을 **선언적으로 표기**하며, 아직 워크플로가 실제로 읽는 입력원은 아닙니다(향후 연동 후보).

## 작업 흐름

```bash
# 1) develop에서 분기
git checkout develop && git pull
git checkout -b feature/add-user-auth      # 작업 단위로 짧고 명확하게

# 2) 작업 + 커밋 (컨벤션은 hook이 검증)
git commit -m "feat(auth): add login endpoint"

# 3) 푸시 + PR (base: develop)
git push -u origin feature/add-user-auth
```

브랜치명은 `feature/<주제>` (영문 kebab-case)가 기본입니다.
추적성을 높이고 싶으면 티켓 번호를 포함하는 형태도 좋습니다(선택): `feature/<티켓ID>-add-user-auth`
— 티켓과 브랜치·커밋이 자동으로 연결되어 "이 코드가 왜 생겼나"를 찾기 쉬워집니다.

큰 작업(에픽)의 브랜치 운영은 [pr-and-merge.md](pr-and-merge.md)를 보세요.

## 커밋 메시지 — `type(scope): subject`

- **type** = 무슨 종류의 변경인가 (기능? 버그수정? 문서?)
- **scope** = **어디를 바꿨나** — 도메인/모듈명(`auth`, `orders`), 앱명(`fe-user-client`), 관례어(`deps`=의존성) 등.
  히스토리에서 영역별 추적이 가능해지고, squash 커밋 제목만 봐도 영향 범위가 보입니다. **우리는 scope를 필수로 강제**합니다.
- **subject** = 무엇을 했나 (한 줄 요약)
- 검사 대상은 **첫 줄(제목)만**입니다. 본문·불릿은 자유롭게 씁니다.

```bash
✅ git commit -m "feat(api): add health check endpoint"
✅ git commit -m "fix(auth): handle expired token"
✅ git commit -m "chore(deps): bump prisma to 6.15"

❌ git commit -m "feat: add foo"          # scope 없음 — 차단됨
❌ git commit -m "added new feature"      # type 없음 — 차단됨
❌ git commit -m "update"                 # 형식 불일치 — 차단됨
```

허용 type:

| type | 용도 |
|------|------|
| `feat` | 신규 기능 |
| `fix` | 버그 수정 |
| `refactor` | 동작 변화 없는 코드 정리 |
| `perf` | 성능 개선 |
| `test` | 테스트 추가/수정 |
| `docs` | 문서만 변경 |
| `style` | 포매팅 (코드 의미 변화 없음) |
| `chore` | 빌드/의존성/설정 |
| `build`, `ci`, `revert` | 빌드 시스템 / CI 설정 / 되돌리기 |

- scope는 변경 영역을 짧게: `api`, `auth`, `orders`, `deps` 등. 애매하면 도메인/모듈명.
- Merge/Revert 등 git이 자동 생성하는 커밋은 hook이 그대로 통과시킵니다.
- type 추가가 필요하면 플랫폼팀에 요청하세요(반영 가능).

## hook이 하는 일

git hook = 특정 git 동작 시점에 자동 실행되는 검사 스크립트입니다. greenfield가 `.husky/`에 깔아주고(managed),
`pnpm install` 때 활성화됩니다. 우리는 3종을 씁니다.

| hook | 실행 시점 | 하는 일 | 실패하면 |
|------|----------|---------|----------|
| `pre-commit` | `git commit` 순간 (메시지 검사 전) | ① lint-staged — **변경된 파일에만** `eslint --fix` + `prettier --write` 자동 적용 ② gitleaks — staged 내용의 시크릿 검사 | 자동 수정 불가한 lint 오류·시크릿 감지면 커밋 차단 |
| `commit-msg` | 커밋 메시지 확정 순간 | 첫 줄이 `type(scope): subject` 형식인지 검증 (Merge/Revert 자동 커밋은 통과) | 커밋 차단 |
| `pre-push` | `git push` 순간 | 단위 테스트 실행 | 푸시 차단 |

순서감: **커밋할 때** 코드 정리(pre-commit) → 메시지 검증(commit-msg), **푸시할 때** 테스트(pre-push).

**hook 실패는 우회할 문제가 아니라 고칠 문제입니다.** 원칙적으로 `--no-verify`로 우회하지 않습니다.
정말 긴박한 상황(운영 장애 대응 등)에서 예외적으로 한 번 우회하더라도, 그건 **끄는 게 아니라 미룬 빚**입니다 —
hook이 잡았어야 할 문제(lint·테스트 실패)를 곧바로 고쳐 갚으세요. hook 스크립트가 안내하는 우회 문구도 이 전제에서 읽으세요.
단, **AI 어시스턴트에게는 예외 없이 금지**됩니다(프로젝트 `CLAUDE.md`에 명시 — 사용자가 요청해도 거부).

## Do / Don't

```bash
# ❌ Don't
git push --no-verify                        # 테스트 게이트 우회
git commit -m "fix: 여러가지 수정" (실제로는 기능 3개)   # 커밋 하나에 무관한 변경 섞기
git checkout -b feature/작업                 # 브랜치명은 영문 kebab-case

# ✅ Do
git commit -m "feat(orders): add cancel API"
git commit -m "test(orders): cover cancel edge cases"    # 논리 단위별로 쪼개 커밋
```

## 근거

- 원본 문서: [greenfield 컨벤션 가이드(03-conventions)](https://github.com/VntgCorp/gh-terroir-greenfield/tree/main/templates/terroir/docs/guide/03-conventions) — branch-strategy, commit-and-env
- 강제 구현: `.husky/commit-msg`(형식 검증), `.husky/pre-commit`(lint-staged), `.husky/pre-push`(테스트)
- Conventional Commits: https://www.conventionalcommits.org
