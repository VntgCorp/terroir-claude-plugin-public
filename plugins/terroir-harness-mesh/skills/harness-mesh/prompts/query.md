# query — 질문에 답하기

0. **시작 전 스킬 경로를 잡는다:** `MESH_SKILL`은 게이트에서 잡은 값과 같다 — 이 스킬이 로드될 때 맨 위에 표시된 `Base directory for this skill: <절대경로>`의 그 절대경로다. 셸은 verb마다 새로 뜨므로 이 bash에서 `MESH_SKILL="<BASE_DIR>"`(그 절대경로로 치환)로 다시 잡아 둔다. 환경변수 `$CLAUDE_PLUGIN_ROOT`는 skill의 bash 블록에 주입되지 않으므로 쓰지 않는다. 그런 뒤 **`$MESH_SKILL/schema.md`를 먼저 정독한다** — 이 프롬프트만 보고 시작하지 말 것. (cwd=storage엔 schema.md가 없다 — 로직은 스킬 폴더에 있다.)
1. 질문을 받는다(호출 인자 또는 지시문).
2. `index.md`에서 관련 페이지를 찾고(필요하면 grep 보조) 해당 페이지들을 정독한다.
3. `[[링크]]` 인용을 달아 답을 합성한다. storage에 근거가 없으면 없다고 답한다 — 지어내지 말 것.
4. 답이 재사용 가치가 있으면 `note` 페이지로 저장한다:
   - frontmatter의 `sources:`에는 합성에 쓴 근거의 원 출처(raw/ 경로 또는 URL)를 적는다
   - `index.md`·`log.md`(`## [YYYY-MM-DD] query — <제목>`)를 갱신한다
   - 스킬의 lint.py로 storage를 검사한다 — `python3 "$MESH_SKILL/scripts/lint.py" .` (첫 인자가 검사할 storage 경로; cwd는 storage 그대로 유지). 확인 후 `git add -A && git commit` — 메시지 `query: <제목>`, 모델명 트레일러
   저장하지 않는 읽기 전용 답변이면 커밋 없이 끝낸다.
