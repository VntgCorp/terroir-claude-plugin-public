# ADR-002 Versioning of marketplace and plugins

## 상태 (Status)

`Accepted` — 2026-09-02 ([RDDP-1746](https://vntg.atlassian.net/browse/RDDP-1746))

- **같은 문서가 두 마켓플레이스에 있다** — 사내 ADR-003 · 퍼블릭 `terroir-claude-plugin-public` ADR-002.
  퍼블릭 사용자는 사내 레포를 볼 수 없어 채택 문서만으로는 규칙에 닿지 못한다. **한쪽을 고치면 다른 쪽도
  같은 PR 묶음에서 고친다.**
- 관련 문서
  - 루트 `README.md` 「버전 정책」·「최근 릴리즈」 — 이 결정을 사용자 안내로 옮긴 곳
  - 각 플러그인 `CHANGELOG.md` — 플러그인별 변경 이력

---

## 맥락 (Context)

버전이 두 곳에 있다. 마켓플레이스 `.claude-plugin/marketplace.json` 의 최상위 `version` 과, 플러그인마다
있는 `.claude-plugin/plugin.json` 의 `version` 이다. 둘을 **언제 올리는지** 정한 결정 문서가 없었다.

그 사이 세 가지가 일어났다.

- "GA 전까지 모든 플러그인은 1.0.0 을 유지한다"는 해석이 커밋으로 들어와, 1.0.1 이던 guide·kickoff 가
  1.0.0 으로 내려갔다.
- development·deployment 는 스킬·문서가 바뀌었는데 버전이 오르지 않았다.
- 변경 이력이 어디에도 없어, 사용자가 업데이트 뒤 무엇이 달라졌는지 알 수 없었다.

Claude Code 는 **플러그인 `version` 이 바뀌어야** 설치본을 갱신한다. 마켓플레이스 `version` 은 갱신을
일으키지 않는다. 두 값의 역할이 다르므로 규칙도 따로 둔다.

---

## 결정 (Decision)

### V1 — 플러그인 버전은 SemVer, 변경은 그 플러그인의 CHANGELOG 에

플러그인 `version` 은 `Major.Minor.Patch` 다. 사용자에게 닿는 파일(`skills/`·`agents/`·`hooks/`·
`templates/`·`references/`)이 바뀌면 **같은 PR 에서** `version` 과 그 플러그인의 `CHANGELOG.md` 를 함께
올린다. `README.md`·`CHANGELOG.md` 만 고친 PR 은 올리지 않는다.

### V2 — Major · Minor · Patch 의 기준은 "호환"

**호환 = 이전 버전에 기대던 것이 그대로 동작한다.** 기대는 쪽은 넷이다.

| 기대는 쪽 | 기대는 것 |
|---|---|
| 사용자 | 스킬·에이전트 이름, 호출 방식 |
| 사용자의 기존 산출물 | 템플릿·파일 형식, 마커 파일 위치 |
| 다른 플러그인 | 산출물 계약 (예: planning 이 만든 FRD 를 handoff·development 가 읽는 구조) |
| 설치 환경 | 훅이 건드리는 설정 |

- **Major** — 넷 중 하나가 깨진다. 스킬·에이전트 이름 변경이나 제거, 기존 산출물을 그대로 못 쓰는
  템플릿·형식 변경, 다른 플러그인이 읽는 계약 변경, 사용자 조치가 필요한 훅·설정 변경.
- **Minor** — 새 스킬이나 새 능력. 기존 것은 그대로 동작한다.
- **Patch** — 기존 동작·문구 수정.

판단이 갈리면 Major 쪽으로 본다. 경계 사례 — planning 의 PRD·FRD 템플릿 v2 → v3 교체는 1.1.0 으로
나갔다. 기존 FRD 를 새 스킬이 이어서 읽지 못했다면 Major 였다.

### V3 — 마켓플레이스 버전은 호환성 세대

최상위 `version` 은 `N.0.0` 이다. **기존 사용자가 마켓플레이스를 다시 등록하거나 플러그인을 다시 설치해야
하는 변경**에만 Major 를 올린다 — 마켓플레이스 이름 변경, 자동 이관이 불가능한 플러그인의 대규모
개명·제거, 소스 구조나 접근 정책의 근본 변경. 플러그인 추가·변경·수정은 올리지 않는다.

### V4 — CHANGELOG 형식

플러그인마다 `CHANGELOG.md` 를 둔다. 최신이 위. `## <version> - <YYYY-MM-DD>` 아래 `### 추가`·`### 변경`·
`### 제거`. **1.0.0 은 "최초 배포"** 와 제공 스킬만 적는다 — 그 앞에 비교할 버전이 없다.
정본은 `plugin.json` 이다. CHANGELOG 가 어긋나면 `plugin.json` 이 맞다.

루트 README 「최근 릴리즈」 표는 **최신 날짜의 배포만** 보인다. 이전 것은 CHANGELOG 에서 본다.

---

## 대안 (Alternatives considered)

| 대안 | 거부 이유 |
|---|---|
| GA 전까지 모든 플러그인 1.0.0 동결 | 버전이 안 바뀌면 Claude Code 가 설치본을 갱신하지 않는다. 사용자가 수정을 받지 못한다 |
| 모든 플러그인 같은 버전 (모노 버전) | 한 플러그인을 고쳐도 열 개가 올라간다. 무엇이 바뀌었는지 알 수 없고 사내 ADR-001 의 독립 원칙과 어긋난다 |
| 플러그인 릴리즈마다 마켓플레이스 버전도 올림 | 갱신을 일으키지 않는 값을 올리는 노이즈다. "호환성 세대"라는 뜻이 흐려진다 |

---

## 결과 및 영향 (Consequences)

- 플러그인을 고치는 PR 에는 `version`·`CHANGELOG.md` 변경이 함께 있어야 한다. 없으면 리뷰에서 돌려보낸다.
- 적용 — 11 개 플러그인에 CHANGELOG 신설, guide 1.1.0 · kickoff 1.0.1 복원 (RDDP-1629, PR #112 · #39).
- development·deployment 의 버전 없이 들어간 변경은 다음 릴리즈에서 올린다.
- 후속 — `version` 미증가를 CI 가 잡는 워크플로(RDDP-1629 작업 5)가 붙으면 사람 리뷰에 기대지 않아도 된다.

---

## ✅상태 변경 로그 (Change History)

- 2026-09-02: 결정·적용 (Accepted)
