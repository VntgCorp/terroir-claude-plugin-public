# ADR-001 Adopt the naming convention of the private marketplace

## 상태 (Status)

`Accepted` — 2026-08-26 ([RDDP-1627](https://vntg.atlassian.net/browse/RDDP-1627))

- 규칙 정본은 사내 마켓플레이스 `terroir-claude-plugin` 의 **ADR-002 Naming convention for plugins and
  skills** 다. 이 문서는 그 규칙을 이 마켓플레이스에 **어떻게 읽어 적용하는지**만 적는다.
- 관련 문서: 사내 `docs/CONTRIBUTING.md` 「공통 준수 사항 › 네이밍」

---

## 맥락 (Context)

사내 마켓플레이스가 플러그인·스킬·에이전트 이름 규칙을 정했다(사내 ADR-002). 두 마켓플레이스는
서로의 스킬을 부른다 — 이 레포의 `onboarding` 은 사내 라우터를 `terroir-*-guide:*` 로 찾고, 사내
라우터는 이 레포의 온보딩을 안내한다. 규칙이 한쪽에만 있으면 부르는 문장의 형식이 갈린다.

이 레포에는 스킬 5개가 있었고 그중 `onboarding-start` 하나가 플러그인 이름(`terroir-onboarding`)을
접두어로 되풀이했다. 세션 표기 `terroir-onboarding:onboarding-start` 에 `onboarding` 이 두 번 나온다.

---

## 결정 (Decision)

사내 ADR-002 의 N1~N7 을 따른다. 이 마켓플레이스에서 다르게 읽는 것은 하나다.

| 규칙 | 사내 | 여기서 읽는 법 |
|---|---|---|
| N1 플러그인 이름 | `terroir-project-<맵 단계>` | **`terroir-<기능>`** — 이 마켓플레이스는 단계 무관 부가 기능(사내 ADR-001 D2)이라 `project-<단계>` 묶음이 없다. `terroir-onboarding` · `terroir-harness-mesh` 가 이미 이 꼴이다 |
| N2 스킬에 플러그인 접두어 없음 | 그대로 | `onboarding-start` → **`onboarding`** |
| N3 묶음 폴더 = 접두어 · N6 에이전트 `-agent` | 그대로 | 묶음 폴더·에이전트가 없어 지금은 해당 없음. 생기면 따른다 |
| N4 유일성은 플러그인 안 · N4-보조 다른 플러그인 스킬은 `plugin:skill` | 그대로 | 사내 라우터는 `terroir-*-guide:*` 로 부른다(이미 적용) |
| N5 version 1.0.0 | 그대로 | `terroir-onboarding` 에 빠져 있던 `version` 을 1.0.0 으로 채움. 마켓플레이스 `metadata.version` 도 1.0.0 |
| N7 description | plugin.json = marketplace.json | 그대로. 서두 `N STAGE —` 는 단계 플러그인용이라 붙이지 않는다 |

### 적용 결과

| 대상 | 이전 | 이후 |
|---|---|---|
| 스킬 | `onboarding-start` | `onboarding` |
| 스킬 | `env-setup` · `github-connect` · `org-access-request` · `harness-mesh` | 변경 없음 |
| 플러그인 | `terroir-onboarding` · `terroir-harness-mesh` | 변경 없음 |

`harness-mesh` 는 플러그인 이름에서 `terroir-` 만 뗀 꼴이다. 사내 `terroir-project-guide` 의 스킬
`project-guide` 와 같은 선례라 그대로 둔다.

`onboarding` 이라는 스킬 이름은 플러그인 이름과 같은 말이다. 세션 표기는 `terroir-onboarding:onboarding`
이 된다. 대안 `start` 는 이름 하나로 무엇의 시작인지 읽히지 않아 택하지 않았다.

---

## 결과 및 영향 (Consequences)

- 플러그인 이름은 그대로라 설치한 사용자는 **재설치 없이 업데이트**로 새 스킬 이름을 받는다.
  `/onboarding-start` 를 치던 사람은 `/onboarding` 으로 바꿔야 한다.
- 사내 레포에서 `/onboarding-start` 를 부르던 문장은 `/terroir-onboarding:onboarding` 으로 바꿨다.
- 이 레포에 새 스킬·플러그인을 더할 때 사내 ADR-002 와 이 문서를 함께 본다.

---

## ✅상태 변경 로그 (Change History)

- 2026-08-26: 결정·적용 (Accepted)
