---
name: harness-mesh
description: ~/harness-mesh-storage 지식 storage를 save/ingest/query/lint 4개 verb로 다루는 능동 스킬(저장·컴파일·근거기반 질의·건강검진). 사용자가 저장·검색·질의하거나 저장할 가치 있는 지식이 나오면 능동 발동. 예 "mesh에 저장/ingest/물어봐", "storage에서 찾아줘", "mesh lint", "/harness-mesh".
---

# harness-mesh — 지식 storage 능동 스킬

mesh를 직접 부르는 4개 동작(save / ingest / query / lint).
**로직은 이 스킬 폴더에 있다** — `schema.md`·`prompts/`·`scripts/`가 유일 정본이다.
**데이터는 storage(`~/harness-mesh-storage`)에만 있다** — inbox/raw/wiki/index/log. verb는
스킬의 로직을 읽고 storage의 데이터에서 작업한다. 로직을 storage로 복사하지 않는다(복제 금지 →
drift 원천 차단). 스킬이 업데이트되면 로직은 즉시 반영된다.

## 0. 게이트 (모든 verb 공통 — 먼저)

경로 두 개를 잡는다 — **로직=스킬 폴더, 데이터=storage**. 스킬 경로(`MESH_SKILL`)는 이 스킬이
로드될 때 맨 위에 표시되는 **`Base directory for this skill: <절대경로>`** 헤더의 그 절대경로로
잡는다(prompts와 동일 방식 — 플러그인 설치든 personal skill 설치든 항상 실제 설치 위치를 가리킨다).
아래 bash의 `<BASE_DIR>`를 그 절대경로로 치환해 실행한다. 환경변수(`$CLAUDE_PLUGIN_ROOT`·
`$CLAUDE_SKILL_DIR`)는 bash 블록에 주입되지 않으므로 쓰지 않는다 — 혹시 치환이 안 돼
`MESH_SKILL`에서 schema.md를 못 찾으면 게이트가 `NO_SKILL_LOGIC`으로 잡아낸다.

```bash
MESH_SKILL="<BASE_DIR>"   # ← 맨 위 'Base directory for this skill:'에 표시된 절대경로로 치환(prompts와 동일). env 변수는 bash 블록에 주입 안 됨
HARNESS_MESH_STORAGE="$HOME/harness-mesh-storage"
[ -f "$MESH_SKILL/schema.md" ] || echo "NO_SKILL_LOGIC $MESH_SKILL"
[ -d "$HARNESS_MESH_STORAGE" ] && echo "OK $HARNESS_MESH_STORAGE" || echo "NO_STORAGE $HARNESS_MESH_STORAGE"
```

- `NO_SKILL_LOGIC`이면 스킬 로직을 못 찾은 것(설치·경로 문제) — verb를 실행하지 말고 사용자에게 알린다.
- `OK <경로>`면 그 storage를 데이터로 쓴다. 셸은 verb마다 새로 뜨므로(변수 비휘발성 없음)
  **각 verb bash 앞에 위 네 줄을 그대로 붙여 재확인**한다.
- `NO_STORAGE <경로>`면 storage가 아직 없는 것 — verb 대신 아래 setup을 제안한다. 임의 폴더에 저장하지 말 것.

## 0b. setup (게이트가 NO_STORAGE일 때만)

고정 위치 `~/harness-mesh-storage`에 **데이터 골격만** 생성한다(로직은 스킬에 있으므로 복사하지 않는다).
스킬의 `storage-seed/`(빈 inbox/raw/wiki + index.md + log.md + README + .gitignore)를 그대로 복사하고 `git init`:

```bash
cp -R "$MESH_SKILL/storage-seed/." "$HOME/harness-mesh-storage/"
cd "$HOME/harness-mesh-storage" && git init && git add -A && git commit -m "init: harness-mesh storage seed" -m "Co-Authored-By: <실제 모델명>"
```

씨앗만 복사하므로 새 storage엔 로직 파일이 처음부터 없다(= drift 원천 차단).
**초기 커밋까지 해야** 트리가 깨끗해져 이후 ingest/lint의 트리-클린 가드가 통과한다 —
커밋을 빠뜨리면 미추적 seed 파일 때문에 save 직후 첫 ingest부터 중단된다. 트레일러엔
save·ingest와 동일하게 실행한 실제 모델명을 넣는다.
생성 뒤 게이트를 다시 확인하고 원래 요청한 verb로 진행한다.

## 0c. 무인 drain (추후 제공 예정 — 현재 미제공)

inbox를 주기적으로 자동 ingest하는 무인 drain은 **설계만 완료된 상태로 이번 배포에는 포함되지 않는다.**
사용자가 "무인 drain 등록해줘" 같은 요청을 해도 **아직 제공하지 않는다고 안내하고 등록 작업(launchd/cron)을 수행하지 않는다.**
현재는 `save` → `ingest` 자동 연쇄로 저장 즉시 컴파일되므로 무인 모드 없이도 곧바로 정리된다.
(설계 개요는 ARCHITECTURE.md §7 참조. `scripts/drain.sh`·`launchd.plist.template`은 추후 제공용으로 보존만 한다.)

## 1. verb 분기 (사용자 요청으로 판단)

각 verb는 **먼저 `cd "$HARNESS_MESH_STORAGE"`** 한 뒤, 스킬의 로직(`$MESH_SKILL/...`)을 읽어
그대로 따른다. 데이터 작업(inbox/wiki/git)은 storage(cwd)에서 일어난다.

- **save** — 사용자가 준 자료(텍스트·파일·URL 메모)를 `$HARNESS_MESH_STORAGE/inbox/`에 새 파일로
  저장한 뒤 **그 파일만 커밋**한다. 파일명은 짧은 슬러그.
  `git add <그 파일> && git commit -m "save: <슬러그>"` (트레일러에 실행한 실제 모델명,
  예: `Co-Authored-By: <실제 모델명>`). 커밋까지가 save.
  schema의 **"save → ingest 자동 연쇄"** 정책에 따라, save 후 같은 실행에서 곧바로 ingest까지 이어서 수행한다.
- **ingest** (compile) — `$MESH_SKILL/prompts/ingest.md`를 정독하고 그 규약을 **그대로 실행**한다
  (inbox/지정 소스 → wiki 컴파일). 절차·단계는 그 파일에 있다.
- **query** (read) — `$MESH_SKILL/prompts/query.md`를 정독하고 그 규약으로 근거기반 질의응답.
  storage에 근거가 없으면 **지어내지 않고** "근거 없음"이라고 답한다.
- **lint** — `python3 "$MESH_SKILL/scripts/lint.py" "$HARNESS_MESH_STORAGE"`를 실행(기계 검사)한 뒤
  `$MESH_SKILL/prompts/lint.md`를 정독해 의미 진찰(모순·stale·고아·정합)을 수행한다.

## Do NOT

- 로직(schema·prompts·scripts)을 storage로 복사하지 말 것 — 로직은 스킬 단일 정본, storage엔 데이터만(복제 = drift).
- storage가 아직 없으면(미생성) 임의 폴더에 저장하지 말 것 — 고정 위치 `~/harness-mesh-storage`에 setup 안내 후 중단.
- `NO_SKILL_LOGIC`이면(스킬 로직 경로 해석 실패) verb를 실행하지 말 것 — 설치·경로 문제로 보고한다.
- query에서 storage에 없는 내용을 지어내지 말 것.
