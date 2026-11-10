# 버전 규칙

이 레포지토리의 버전 번호는 떼루아 공통 규칙(RND-INFRA ADR-075)을 따른다. 번호의 정본은 각 플러그인 `.claude-plugin/plugin.json` 의 `version` 이다.

| 자리 | 올리는 조건 |
|---|---|
| 메이저 | 평소에는 올리지 않는다. 지금 메이저 안에서 호환을 지킬 방법이 없을 때만 팀장과 논의해 올리고 그 결정을 기록한다 |
| 마이너 | 사용자가 쓰는 것이 생기거나 없어질 때 (스킬 · 명령 · 템플릿 선택지 · 설정 항목의 추가 · 제거 · 이름 변경), 기존 사용자가 손대야 하는 변경 |
| 패치 | 그 밖의 모든 변경 — 버그 · 보안 수정, 의존성 상향, 내부 리팩터, 문서 · 문구 |

- 사용자가 받는 산출물이 바뀌는 PR 이 번호를 올린다. 한 PR 에 여러 변경이 있으면 가장 높은 자리 하나만 올린다.
- 기존 사용자가 손대야 하는 변경은 이력(플러그인 `CHANGELOG.md`)에 「필수 조치」로 적는다.
- 메이저로 판단되면 번호를 올리기 전에 멈추고 사람에게 확인한다.
- 커밋 제목에 `!` 를 쓰지 않는다. 커밋 접두와 번호 자리는 따로 판정한다 — 기존 기능을 개선한 `feat` 은 패치다.
- 이미 올라간 번호는 내리지 않는다.
- `README.md` 만 고친 PR 은 올리지 않는다. 마켓플레이스 최상위 `version` 과 CHANGELOG 형식은 `docs/adr/002-ADR-Versioning of marketplace and plugins.md` 를 따른다.

정본: [RND-INFRA ADR-075](https://github.com/VntgCorp/RND-INFRA/blob/main/docs/adr/global/ADR-075-terroir-versioning-policy-P.md)
