# ADR-002 Adopt the versioning rules of the private marketplace

## 상태 (Status)

`Accepted` — 2026-08-26 ([RDDP-1674](https://vntg.atlassian.net/browse/RDDP-1674))

- 규칙 정본은 사내 마켓플레이스 `terroir-claude-plugin` 의 **ADR-003 Semantic versioning rules for plugins** 다.
  이 문서는 그 규칙을 이 마켓플레이스에 **어떻게 읽어 적용하는지**만 적는다.
- 이 레포의 ADR-001(이름 규칙 채택)과 같은 방식이다.

---

## 맥락 (Context)

ADR-001 로 `terroir-onboarding` 이 `1.0.0` 이 됐다. 리뷰에서 "다음에 버전을 올릴 때 기준이 필요하지 않나"는
질문이 나왔다(PR #32). 사내가 ADR-003 으로 기준을 정했고, 두 마켓플레이스가 서로의 스킬을 부르므로
버전 규칙도 한 가지여야 한다.

---

## 결정 (Decision)

사내 ADR-003 의 V1~V6 을 따른다. 이 마켓플레이스에서 다르게 읽을 것은 없다.

| 규칙 | 여기서 읽는 법 |
|---|---|
| V1 버전은 플러그인별 `plugin.json` | `terroir-onboarding` · `terroir-harness-mesh` 각각. `marketplace.json` `metadata.version` 은 플러그인 추가·삭제·개명 때만 |
| V2 SemVer 원문 세 줄 | 그대로 |
| V3 하위 호환 = 부르는 이름·인자 + 산출물 경로·형식 | 이 레포의 스킬은 산출물 파일을 남기지 않는다. 사실상 **스킬 이름·인자 변경과 삭제**가 MAJOR 다 |
| V4 개명은 deprecated(MINOR) → 삭제(MAJOR) 가능 | 그대로. ADR-001 의 `onboarding-start` → `onboarding` 은 이 규칙 전이라 한 번에 바꿨다 |
| V5 `main` 머지 1회 | 그대로. `@develop` 로 받는 검증 사용자는 버전이 아니라 커밋을 따른다 |
| V6 pre-release 없음 | 그대로 |

---

## 결과 및 영향 (Consequences)

- 온보딩 문구·연결 안내만 고친 PR 도 PATCH 를 올린다. `/plugin update` 가 새 버전을 알아보는 신호가 그것뿐이다.
- 사내 스킬을 부르는 이름(`terroir-*-guide:*`)이 사내 MAJOR 로 바뀌면, 이 레포의 `onboarding` 도 문장을 고치고
  MAJOR 를 올린다(사내 ADR-003 경계 사례).

---

## ✅상태 변경 로그 (Change History)

- 2026-08-26: 결정 (Accepted)
