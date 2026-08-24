# lint — 건강검진

0. **시작 전 스킬 경로를 잡는다:** `MESH_SKILL`은 게이트에서 잡은 값과 같다 — 이 스킬이 로드될 때 맨 위에 표시된 `Base directory for this skill: <절대경로>`의 그 절대경로다. 셸은 verb마다 새로 뜨므로 이 bash에서 `MESH_SKILL="<BASE_DIR>"`(그 절대경로로 치환)로 다시 잡아 둔다. 환경변수 `$CLAUDE_PLUGIN_ROOT`는 skill의 bash 블록에 주입되지 않으므로 쓰지 않는다. 그런 뒤 **`$MESH_SKILL/schema.md`를 먼저 정독한다** — 이 프롬프트만 보고 시작하지 말 것. (cwd=storage엔 schema.md가 없다 — 로직은 스킬 폴더에 있다.)
1. 가드: `git status --porcelain` 출력이 비어 있지 않으면 "다른 실행이 진행 중일 수 있음"을 보고하고 즉시 중단한다(끝에 커밋하므로 시작은 깨끗해야 한다).
2. 스킬의 lint.py로 storage를 검사한다 — `python3 "$MESH_SKILL/scripts/lint.py" .` (첫 인자가 검사할 storage 경로; cwd는 storage 그대로 유지). ERROR는 직접 정정한다(깨진 링크·index 정합·frontmatter 보정은 기계적 작업).
3. 의미 진찰 — `wiki/` 전체를 훑으며 찾는다:
   - 페이지 간 **모순되는 주장**
   - 시간이 지나 **낡았을 주장**(lint.py의 stale 후보 INFO 목록 참고)
   - 같은 주제인데 링크가 없는 **누락 상호참조**
   - 합쳐야 할 **중복 페이지**
   - 비어 있는 **데이터 갭**(있어야 할 페이지·절)
4. 자명한 것은 직접 수정한다(`updated` 갱신 잊지 말 것). 판단이 필요한 것은 고치지 말고 목록화한다.
5. `log.md`에 `## [YYYY-MM-DD] lint — <요약>`을 append한다 — 수정한 목록 + "사람 검토 필요" 목록.
6. 스킬의 lint.py를 재실행해 — `python3 "$MESH_SKILL/scripts/lint.py" .` — ERROR 0을 확인한 뒤 `git add -A && git commit` — 메시지 `lint: <요약>`, 모델명 트레일러.
