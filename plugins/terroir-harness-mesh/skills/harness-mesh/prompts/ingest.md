# ingest — inbox 소스 처리

0. **시작 전 스킬 경로를 잡는다:** `MESH_SKILL`은 게이트에서 잡은 값과 같다 — 이 스킬이 로드될 때 맨 위에 표시된 `Base directory for this skill: <절대경로>`의 그 절대경로다. 셸은 verb마다 새로 뜨므로 이 bash에서 `MESH_SKILL="<BASE_DIR>"`(그 절대경로로 치환)로 다시 잡아 둔다. 환경변수 `$CLAUDE_PLUGIN_ROOT`는 skill의 bash 블록에 주입되지 않으므로 쓰지 않는다. 그런 뒤 **`$MESH_SKILL/schema.md`를 먼저 정독한다** — 이 프롬프트만 보고 시작하지 말 것. (cwd=storage엔 schema.md가 없다 — 로직은 스킬 폴더에 있다.)
1. 가드: `git status --porcelain` 출력이 비어 있지 않으면 "다른 실행이 진행 중일 수 있음"을 보고하고 즉시 중단한다.
2. `inbox/`에서 가장 오래된 파일 1건을 고른다(기본 1건, 명시적 지시가 있을 때만 최대 3건). 비어 있으면 "할 일 없음"으로 종료한다.
   - 텍스트(md·txt)가 기본 — 어떤 벤더로도 안정적으로 읽힌다. PDF·이미지 등 rich 포맷은 읽을 수 없으면 건너뛰고 보고한다.
3. 소스를 정독하고:
   - `wiki/`에 `source` 페이지를 작성한다 — 요약, 핵심 takeaway, `## 열린 질문` 절(사람과 논의하지 못한 논점을 표면화)
   - 본문에 등장한 대상·개념의 `entity`/`concept` 페이지를 생성·갱신하고 본문 `[[교차링크]]`로 잇는다
   - 생성·갱신한 `entity`/`concept` 페이지의 `## 관련` 절에 이번 source 페이지로의 역링크를 한 줄 추가한다
   - `index.md`를 갱신한다(새·수정 페이지마다 해당 type 섹션에 한 줄)
   - `log.md`에 `## [YYYY-MM-DD] ingest — <제목>` 항목을 append한다(만들거나 고친 페이지 목록 포함)
4. 원본을 `raw/YYYY-MM-DD-<원래이름>`으로 **이동**한다(내용 수정 금지). 이 이동이 완료 표시다.
5. 스킬의 lint.py로 storage를 검사한다 — `python3 "$MESH_SKILL/scripts/lint.py" .` (첫 인자가 검사할 storage 경로; cwd는 storage 그대로 유지). ERROR가 있으면 기계적으로 정정한다.
6. `git add -A && git commit` — 메시지 `ingest: <제목>`, 트레일러에 실행한 실제 모델명(`Co-Authored-By: <모델명>`).
