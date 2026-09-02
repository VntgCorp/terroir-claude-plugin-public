# mesh — 규약 정본 (schema)

평문 마크다운 지식 그물 storage. 이 파일이 **유일 정본 규약**이며, 모든 에이전트는 어떤 작업이든 이 파일을 먼저 정독한 뒤 시작한다.

## 목차

- [구조와 소유권](#구조와-소유권)
- [페이지 타입 (4종 고정)](#페이지-타입-4종-고정)
- [frontmatter (전 페이지 공통)](#frontmatter-전-페이지-공통)
- [파일명·\[\[링크\]\] 규칙](#파일명링크-규칙)
- [index.md / log.md](#indexmd--logmd)
- [워크플로](#워크플로)
- [git 규약](#git-규약)
- [소스 포맷](#소스-포맷)
- [무인 운용 (추후 제공 예정 — 현재 미제공)](#무인-운용-추후-제공-예정--현재-미제공)

## 구조와 소유권

| 영역 | 소유자 | 규칙 |
|------|--------|------|
| `inbox/` | 사람 | 미처리 소스 큐. 에이전트는 읽기 + 처리 완료 후 raw/로 이동만 |
| `raw/` | 사람 | 처리 완료 원본 보관. **내용 불변** — 에이전트는 읽기 전용 |
| `wiki/`, `index.md`, `log.md` | 에이전트 | 사람은 읽고 지시. 직접 고쳐도 되지만 보통 에이전트 경유 |

위 표는 **이 storage(데이터)** 영역이다. 로직(`schema.md`·`prompts/`·`scripts/`)은 storage가 아니라 harness-mesh **스킬 폴더**에 있다 — 에이전트는 제안만, 수정은 사람 승인 후. 이 storage엔 데이터(inbox/raw/wiki/index/log)만 둔다.

inbox→raw 이동 시 파일명에 `YYYY-MM-DD-` prefix를 붙인다. 이동만 허용, 내용 수정은 절대 금지.

## 페이지 타입 (4종 고정)

| type | 용도 |
|------|------|
| `source` | raw 소스 1건의 요약·takeaway·열린 질문. ingest마다 1개 |
| `entity` | 사람·도구·프로젝트·조직 등 고유 대상 |
| `concept` | 기법·아이디어·패턴 |
| `note` | query 답변 중 보존 가치 있는 합성물 |

타입을 늘리지 않는다. 필요가 증명되면 schema 개정(사람 승인)으로만.

## frontmatter (전 페이지 공통)

```yaml
---
type: source              # source | entity | concept | note
created: 2026-06-10
updated: 2026-06-10       # 내용 수정 시마다 갱신
sources: [raw/2026-06-10-foo.md]   # 근거 출처: raw/ 경로 또는 URL. 빈 리스트 허용
aliases: []               # 선택: 동의어·약칭
---
```

`related` 같은 링크 필드는 두지 않는다 — 링크는 본문에만 둔다.

## 파일명·[[링크]] 규칙

- 파일명 = 슬러그: kebab-case, 영문 권장(한글 허용), `wiki/<슬러그>.md`. wiki/는 flat(하위폴더 없음)
- 링크 표기 `[[슬러그]]`, 표시명 필요 시 `[[슬러그|표시명]]`
- 모든 링크는 wiki/ 내 실재 파일을 가리켜야 한다. 아직 없는 페이지를 의도적으로 가리킬 때만 그 줄에 `<!-- stub -->` 표기
- 연결이 본문 문맥에 안 녹으면 페이지 끝 `## 관련` 절에 모은다
- 모든 페이지는 index.md에 정확히 1번 등재된다
- Obsidian 전용 문법(dataview 등) 금지 — 평문 호환 유지

## index.md / log.md

- `index.md`: type별 섹션(`## source` 등), 페이지당 한 줄 — `- [[슬러그]] — 한 줄 요약 (updated)`
- `log.md`: append-only 연대기. 항목 prefix `## [YYYY-MM-DD] ingest|query|lint — 제목`. 수정·삭제 금지

## 워크플로

| 작업 | 따를 파일 |
|------|----------|
| ingest — inbox 소스 처리 | `prompts/ingest.md` |
| query — 질문 답변·합성 | `prompts/query.md` |
| lint — 건강검진 | `prompts/lint.md` |
| 기계 검사만 | `python3 scripts/lint.py` (ERROR 존재 시 exit 1) |

**save → ingest 자동 연쇄.** save로 inbox에 자료를 추가하면 단독으로 끝내지 말고, **같은 실행에서 곧바로 `prompts/ingest.md`를 따라 ingest까지 이어서 수행**한다(save 커밋 → ingest 커밋 순서로 둘 다 남긴다). 이유: OS 스케줄러·hook 없이 즉시 컴파일하므로 벤더·OS 무관이다. ingest가 실패해도 save 커밋은 남으므로 다음 실행에서 재개된다(idempotent). (무인 일괄 처리용 `scripts/drain.sh`는 추후 제공 예정 — 현재 미제공.)

## git 규약

- storage를 변경하는 실행(save(inbox에 자료 추가), ingest, 자동수정 있는 lint, note를 저장한 query)은 **git commit으로 마무리**한다. git이 감사·복구·동시성 탐지 층이다.
- 실행 시작 시 working tree가 더러우면(미커밋 변경 존재) 다른 실행이 진행 중일 수 있으므로 **중단하고 보고**한다.
- 커밋 메시지: `ingest: <제목>` / `lint: <요약>` / `query: <제목>`. 트레일러에 실행한 실제 모델명을 남긴다 — 예: `Co-Authored-By: <실제 모델명>`
- **push 금지** — 로컬 전용. 원격 연결은 사람이 결정한다.

## 소스 포맷

**텍스트 소스(md·txt)를 권장**한다 — 어떤 벤더로도 안정적으로 읽힌다. rich 포맷(PDF·이미지 등)은 읽기 능력이 벤더마다 다르므로, 지원하는 벤더로만 ingest한다.

## 무인 운용 (추후 제공 예정 — 현재 미제공)

무인 일괄 처리(스킬의 `scripts/drain.sh`)는 설계만 돼 있고 이번 배포에는 포함되지 않는다. 현재는 save → ingest 자동 연쇄로 충분하다.
