# mesh — 데이터 storage

harness-mesh 스킬이 관리하는 평문 마크다운 지식 storage(**데이터 전용**).
**로직(schema·prompts·scripts)은 harness-mesh 스킬 폴더에 있다** — 이 폴더엔 데이터만 둔다.

- 흐름: `inbox/`(미처리 소스 큐) → ingest → `wiki/`(상호링크 페이지) + `raw/`(원본 보관, 불변)
- 구조·규약 정본: harness-mesh 스킬의 `schema.md`
- 사용: harness-mesh 스킬의 verb로 — save(저장) / ingest(컴파일) / query(질의) / lint(건강검진)
- Obsidian으로 열면 그래프 뷰 사용 가능(선택, `.obsidian/`은 git 제외)

무인 일괄 처리(`scripts/drain.sh`)는 추후 제공 예정(현재 미제공).
이 repo는 로컬 전용 — push는 사람이 결정한다.
