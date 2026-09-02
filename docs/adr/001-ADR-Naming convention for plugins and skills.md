# ADR-001 Naming convention for plugins and skills

## 상태 (Status)

`Accepted` — 2026-08-26 ([RDDP-1627](https://vntg.atlassian.net/browse/RDDP-1627))

- 관련 문서: 루트 `README.md` 「이름 변경 안내」 — 설치한 사용자가 옛 스킬 이름에서 넘어오는 절차

---

## 맥락 (Context)

이 마켓플레이스는 GitHub 인증이나 조직 가입 없이 설치하는 **단계 무관 부가 기능**(온보딩 · 지식
베이스 · 피드백)을 담는다. 규칙 없이 스킬 5개가 생겼고, 그중 `onboarding-start` 는 플러그인 이름
`terroir-onboarding` 을 접두어로 되풀이했다.

Claude Code 는 스킬을 세션에 `plugin:skill` 로 올린다. `terroir-onboarding:onboarding-start` 에는
`onboarding` 이 두 번 나온다. 접두어가 정보를 더하지 않고 이름만 길어진다.

플러그인 이름은 설치 단위다. 이름이 바뀌면 자동 업데이트가 따라오지 않고, 옛 이름 플러그인이 남아
새 이름과 스킬이 이중으로 로드된다. 그래서 규칙을 먼저 정하고 한 번에 바꿨다.

---

## 결정 (Decision)

| # | 결정 |
|:---:|---|
| **N1** | 플러그인 이름은 **`terroir-<기능>`** 다. 이 마켓플레이스는 단계 묶음이 없으므로 여정·단계를 뜻하는 말을 접두어에 넣지 않는다. `terroir-onboarding` · `terroir-harness-mesh` · `terroir-feedback` |
| **N2** | 스킬 이름에는 **플러그인 접두어를 붙이지 않는다.** `onboarding-start` 가 아니라 `onboarding` 이다 |
| **N3** | 스킬 이름은 **플러그인 안에서** 유일하면 된다. 플러그인 사이의 중복은 세션 표기 `plugin:skill` 이 구분한다 |
| **N3-보조** | 문서·스킬 본문에서 **다른 플러그인의 스킬을 부를 때는 `plugin:skill` 로 쓴다**(슬래시는 `/terroir-onboarding:onboarding`). 다른 마켓플레이스의 플러그인도 같다. 같은 플러그인 안의 스킬은 이름만 쓴다 |
| **N4** | 묶음 폴더를 두면 안의 스킬은 그 폴더 이름을 접두어로 갖는다. 에이전트 이름은 `-agent` 로 끝난다. 지금은 둘 다 없고, 생기면 따른다 |
| **N5** | 플러그인 메타데이터(description · version · author · keywords)의 **정본은 `plugin.json` 하나**다. `marketplace.json` 의 `plugins[]` 엔트리는 **`name` + `source` 만** 쓴다. 마켓플레이스 화면은 엔트리에 없는 값을 `plugin.json` 에서 읽어 오므로 빠져 보이지 않는다 |
| **N6** | 이 규칙을 적용한 시점에 `plugin.json` 의 `version` 을 **1.0.0** 으로 두었다. 그 전에는 `version` 필드가 없었다. 이후 버전은 ADR-002 *Versioning of marketplace and plugins* 를 따른다 |

### 적용 결과

| 대상 | 이전 | 이후 |
|---|---|---|
| 스킬 | `onboarding-start` | `onboarding` |
| 스킬 | `env-setup` · `github-connect` · `org-access-request` · `harness-mesh` | 변경 없음 |
| 플러그인 | `terroir-onboarding` · `terroir-harness-mesh` | 변경 없음 |
| `marketplace.json` 엔트리 | description 포함 | `name` + `source` 만 |

`harness-mesh` 는 플러그인 이름에서 `terroir-` 만 뗀 꼴이다. N2 는 접두어를 금하는 것이고 플러그인
이름과 같은 말을 금하지 않으므로 규칙에 맞다.

`onboarding` 은 플러그인 이름과 같은 말이라 세션 표기가 `terroir-onboarding:onboarding` 이 된다.
대안 `start` 는 이름 하나로 무엇의 시작인지 읽히지 않아 택하지 않았다.

---

## 대안 (Alternatives considered)

| 대안 | 기각 이유 |
|---|---|
| 스킬 접두어를 전부 붙이는 쪽으로 통일 (`env-setup` → `onboarding-env-setup`) | 세션 표기 `plugin:skill` 과 중복이 더 커진다 |
| 스킬 이름을 다른 마켓플레이스까지 포함해 유일하게 | 우리가 통제할 수 없는 범위다. 사용자가 다른 마켓플레이스를 함께 설치하면 언제든 겹친다. 네임스페이스가 있는데 이름 유일성으로 다시 막을 이유가 없다 |
| `plugin.json` 과 `marketplace.json` 에 같은 문장을 둘 다 두고 동기화 | 어긋날 사본이 둘 남는다. 한 곳만 남기는 쪽이 맞다 |

---

## 결과 및 영향 (Consequences)

- 플러그인 이름은 그대로라 설치한 사용자는 **재설치 없이 업데이트**로 새 스킬 이름을 받는다.
  `/onboarding-start` 를 치던 사람은 `/onboarding` 으로 바꿔야 한다.
- 이 레포에 새 스킬·플러그인을 더할 때는 이 문서만 본다.
- N3-보조는 사람이 지켜야 한다. 다른 플러그인의 스킬을 이름만으로 부른 문장을 잡는 자동 검사는 없다.

---

## ✅상태 변경 로그 (Change History)

- 2026-08-26: 결정·적용 (Accepted)
- 2026-08-26: N5 반영 — `marketplace.json` 엔트리를 `name` + `source` 로 축소 ([RDDP-1194](https://vntg.atlassian.net/browse/RDDP-1194))
- 2026-09-02: 다른 마켓플레이스의 결정을 참조하던 본문을 이 문서 하나로 규칙을 알 수 있게 다시 썼다.
  파일명을 *Adopt the naming convention of the private marketplace* 에서 바꿨다. 결정 내용은 바꾸지
  않았다 ([RDDP-1747](https://vntg.atlassian.net/browse/RDDP-1747))
