# ADR-002 Adopt the versioning rules of the private marketplace

## 상태 (Status)

`Accepted` — 2026-09-02 ([RDDP-1746](https://vntg.atlassian.net/browse/RDDP-1746))

- 규칙 정본은 사내 마켓플레이스 `terroir-claude-plugin` 의 **ADR-003 Versioning of marketplace and
  plugins** 다. 이 문서는 그 규칙을 이 마켓플레이스에 **어떻게 읽어 적용하는지**만 적는다.
- 관련 문서: 루트 `README.md` 「버전 정책」·「최근 릴리즈」, 각 플러그인 `CHANGELOG.md`

---

## 맥락 (Context)

두 마켓플레이스가 각자 README 에 버전 정책을 적어 왔다. 이 레포의 `onboarding` 은 사내 플러그인을
설치하는 진입점이라, 규칙이 갈리면 사용자는 두 가지 안내를 받는다. 이름 규칙(ADR-001)과 같은 이유로
버전 규칙도 사내 결정을 채택한다.

---

## 결정 (Decision)

사내 ADR-003 의 V1~V4 를 그대로 따른다. 다르게 읽는 것은 없다.

| 규칙 | 여기서 적용 |
|---|---|
| V1 플러그인은 SemVer, 변경은 CHANGELOG 에 | `terroir-onboarding` · `terroir-harness-mesh` · `terroir-feedback` 모두 `CHANGELOG.md` 를 둔다 |
| V2 호환 기준 (사용자 · 기존 산출물 · 다른 플러그인 · 설치 환경) | `/onboarding-start` → `/onboarding` 개명은 이 기준으로 Major 다. 버전을 붙이기 전(1.0.0 이전)에 일어나 소급하지 않는다 |
| V3 마켓플레이스 버전은 호환성 세대 | 최상위 `version` 1.0.0. 플러그인 추가·변경으로는 올리지 않는다 |
| V4 CHANGELOG 형식 · README 최근 릴리즈 표 | 1.0.0 은 "최초 배포". 표는 최신 날짜만 |

---

## 결과 및 영향 (Consequences)

- 이 레포의 플러그인을 고치는 PR 에도 `version`·`CHANGELOG.md` 변경이 함께 있어야 한다.
- 사내 ADR-003 이 바뀌면 이 문서도 함께 본다. 이 레포만의 예외가 생기면 여기에 적는다.

---

## ✅상태 변경 로그 (Change History)

- 2026-09-02: 결정·적용 (Accepted)
