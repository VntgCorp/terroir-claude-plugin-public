# 변경 이력 쓰는 법

CHANGELOG 항목을 어떤 모양으로 쓰는가의 기준입니다.

이 문서가 원본입니다. Claude 에서는 `/terroir-context:changelog-write` 가 이 문서를 읽고 항목을 씁니다.

## 개요

우리가 잘못 쓰고 있어서 만든 문서입니다. 지금 CHANGELOG 에 이런 항목이 있습니다.

- 구현하며 정한 규칙을 그대로 옮긴 항목
- 무엇이 달라졌는지 대신 어느 절을 건드렸는지 나열한 항목
- 참조 번호를 저마다 다르게 단 항목 — 공개 이슈 번호 · 사내 PR 번호 · 지라 키가 한 저장소 안에 함께 있습니다

앞의 둘은 아래 「Do / Don't」에 같은 모양의 예로 있습니다.

기준이 없으면 새로 쓰는 사람은 기존 파일을 흉내 냅니다. 잘못 쓴 항목이 다음 항목의 본보기가 되므로, 그대로 두면 번지기만 하고 멈추지 않습니다. 그래서 기준을 문서로 고정합니다.

기준을 임의로 정하지 않고, 널리 쓰이는 CHANGELOG 13개를 실물로 대조해 뽑았습니다. **13개 전부가 지키는 것은 규칙으로, 일부만 하는 것은 저장소가 고르는 항목으로** 갈랐습니다. 규칙 8 과 9, 규칙 1 의 둘째 문장은 13개에서 나온 것이 아니라 우리가 겪은 것에서 더했습니다. 조사한 문서는 참고자료에 있습니다(2026-09-22 기준).

CHANGELOG 를 두는 모든 저장소에 적용합니다. 갈리던 항목에 저장소가 무엇으로 답했는지는 그 저장소가 적습니다 — 이 문서는 고르는 기준까지만 다룹니다.

## 구조

| 절 | 내용 |
|---|---|
| 사용법 | 규칙 아홉과, 같은 변경에서 나온 글을 어디에 적는지. 따릅니다 |
| 갈릴 수 있는 것과 고르는 기준 | 13개에서 하는 곳과 안 하는 곳이 갈리던 항목 여섯. 항목마다 어느 쪽으로 고르면 되는지를 함께 적었습니다 |

## 사용법

### 규칙 1 — 항목은 한 문장이다

한 항목에 한 문장을 씁니다. 두 문장 이상을 쓰는 경우는 조사한 13개 모두에서 파괴적 변경뿐이었습니다.

하나만 더 허용합니다. 이 변경으로 사용자가 **새로 해야 할 행동**이 생겼으면 그 행동을 둘째 문장으로 붙입니다. 행동이 없으면 첫 문장으로 끝냅니다. 바뀐 결과를 다시 설명하는 둘째 문장은 쓰지 않습니다.

### 규칙 2 — 동사로 열고, 그 동사는 우리가 한 일이다

`고쳤습니다` · `더했습니다` · `바꿨습니다` 로 엽니다. 「제품이 이제 이렇게 동작합니다」같은 상태 서술로 여는 곳은 13개 중 한 곳도 없었습니다.

```
Fixed being unexpectedly logged out when an older Claude Code build runs on the same machine
Fixed a regression in Django 5.2 that caused unnecessary queries when prefetching nullable foreign key relationships
Adds support for the Sui network and USDsui token for crypto payments
```

### 규칙 3 — 동사 뒤에는 사용자 쪽에서 일어난 일을 적는다

고친 자리가 아니라 사용자 쪽에서 일어난 일을 적습니다. 사용자가 겪은 것이면 그것을, 겪었는지 모르더라도 사용자 쪽에서 벌어진 일이면 그것을 적습니다. 위 Django 항목이 적은 것은 「쿼리셋 내부 분기를 수정」이 아니라 「불필요한 쿼리가 나갔다」입니다.

수정이 아니면 겪던 일이 없습니다. 더한 것이면 사용자가 새로 할 수 있게 된 것을, 없앤 것이면 더 이상 할 수 없게 된 것을 적습니다.

### 규칙 4 — 어떤 경우에 해당하는지를 붙인다

조건 없이 적은 항목은 없었습니다. 수정이면 그 증상을 언제 겪는지를 붙입니다.

```
Fixed being unexpectedly logged out when an older Claude Code build runs on the same machine
Fixed a regression … when prefetching nullable foreign key relationships
Ensure `@tailwindcss/oxide` falls back to WASM on platforms without native bindings
```

더한 것이면 그 기능이 어떤 경우에 쓰이는지를 붙입니다.

```
Detect classes in Ruby percent literals using angle brackets or custom delimiters
  (e.g. `%w<flex>`, `%w|flex|`), including in Slim and Haml templates        (Tailwind)
```

읽는 사람은 이것으로 자기 일인지 아닌지를 가릅니다.

### 규칙 5 — 변경의 종류로 묶는다

항목을 종류별 제목 아래 모읍니다. 제목 이름은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/) 의 추가 · 변경 · 사용 중단 · 제거 · 수정 · 보안을 기본으로 하고, 해당하는 것만 씁니다.

```
### Fixed                          (React)
### Features / ### Bug Fixes       (Vite)
Breaking changes / Features / Fixes (Prisma)
Changes by Kind → Bug or Regression (Kubernetes)
```

### 규칙 6 — 제목은 버전과 날짜, 최신이 위

`## 1.1.1 - 2026-09-22` 형식으로 적고 새 버전을 위에 쌓습니다.

```
## 19.2.7 (June 1, 2026)                                    (React)
Version 1.98.1 (2026-09-03)                                 (Rust)
## [3.5.43](https://github.com/vuejs/core/compare/...) (2026-09-17)  (Vue)
```

### 규칙 7 — 못 여는 번호는 달지 않는다

참조 번호는 **읽는 사람이 열 수 있을 때만** 답니다. 조사한 13개 중 사설 트래커의 티켓 키를 단 곳은 없었습니다. 공개 저장소는 공개 PR·이슈 번호를 달고, 트래커가 비공개인 제품(Claude Code)은 번호를 아예 달지 않습니다.

```
Fixed a regression … when prefetching nullable foreign key relationships
  ([#36290](https://code.djangoproject.com/ticket/36290))     ← 공개 트래커라 단다
Fixed being unexpectedly logged out when an older Claude Code build runs
  on the same machine                                          ← 비공개라 안 단다
```

⚠️ **추적은 CHANGELOG 의 일이 아닙니다.** 티켓 키는 커밋 메시지와 PR 본문에 남깁니다. 읽는 사람이 열 수 없는 번호는 정보가 아니라 잡음입니다.

### 규칙 8 — 마지막 상태만 적는다

A 였던 것을 B 와 C 를 거쳐 D 로 바꿨더라도 적는 것은 D 하나입니다. 중간에 뒤집힌 안, 시행착오, 검증하며 되돌린 것은 적지 않습니다. 읽는 사람이 받는 것은 D 이고 B 와 C 는 겪지 않습니다.

한 변경을 여러 번 고쳐 커밋이 여럿이 됐더라도 항목이 여럿이 되지는 않습니다.

### 규칙 9 — 올리기 전에 사람이 읽는다

AI 가 만든 항목을 그대로 올리지 않습니다. 작업자가 한 번 읽고 올립니다.

AI 는 CHANGELOG 를 그대로 인용합니다. 읽기 어려운 문장이 한 번 올라가면 그 문장이 그대로 다시 퍼집니다.

무엇을 보고 고칠지는 아래 「쓰기 전 확인」의 두 번째 묶음에 있습니다.

### 어디에 적나

한 번의 변경에서 글이 넷 나옵니다. 자리를 섞으면 CHANGELOG 가 커밋 메시지나 PR 본문이 됩니다.

| 무엇 | 어디 |
|---|---|
| 이 버전부터 사용자에게 달라지는 것. 수정이면 겪던 증상까지 | CHANGELOG |
| 무엇을 왜 그렇게 바꿨는지, 그렇게 정한 근거 | 커밋 메시지 |
| 변경 범위 · 검증 방법 · 리뷰어가 볼 곳 | PR 본문 |
| 그 줄을 읽는 사람이 알아야 할 것 | 코드 주석 |
| 티켓 키 | 커밋 메시지 · PR 본문 |

아래 「Do / Don't」의 두 Don't 가 자리를 섞은 예입니다. 예 1 은 커밋 메시지에 갈 근거를, 예 2 는 PR 본문에 갈 변경 범위를 CHANGELOG 에 옮겼습니다.

### Do / Don't

#### 예 1 — 정한 규칙을 그대로 옮긴 경우

```markdown
# ❌ Don't
### 수정

- 저장된 토큰이 만료된 것으로 보일 때 **곧바로 로그아웃으로 단정하지 않는다.** 「만료됨」과
  「다른 기기에서 갱신됨」은 토큰만 보고는 갈리지 않는다. 가르려 하지 말고 **갱신을 먼저
  시도하고**(`app auth refresh`), 갱신도 실패하면 로그인 화면으로 보낸다.
  - 전에는 곧바로 로그인 화면으로 보냈는데, 다시 로그인해도 같은 토큰을 읽어 **사용자가 제자리를 돌았다**
  - 설정 화면은 이미 같은 규칙을 쓴다 — 명령줄에서 직접 부른 경로만 남아 있었다 [PROJ-1234]
```

규칙 1·2·3·7 을 어깁니다. 세 문장에 하위 항목이 둘이고, 동사 대신 규칙 선언으로 열고, 사용자 쪽에서 일어난 일 대신 판정 근거를 적고, 열 수 없는 사내 트래커 키를 달았습니다.

```markdown
# ✅ Do
### 수정

- 다른 기기에서 로그인한 뒤 이 기기에서 명령을 실행하면 다시 로그인해도 로그인 화면으로
  돌아오던 문제를 고쳤습니다. 로그인 화면이 다시 뜨면 `app auth refresh` 를 먼저 실행합니다.
```

`고쳤습니다`로 열고(규칙 2), 사용자 쪽에서 일어난 일을 적고(규칙 3), `다른 기기에서 로그인한 뒤`로 조건을 달았습니다(규칙 4). 사용자가 새로 할 행동이 생겨 둘째 문장을 붙였습니다(규칙 1).

판정 근거와 설계 경위는 티켓 본문에 있습니다. 티켓 링크는 커밋과 PR 에 답니다.

#### 예 2 — 변경한 자리를 나열한 경우

```markdown
# ❌ Don't
### 수정

버그 신고 템플릿(`bug`·`regression` 공용)에서 비워 두면 담당자가 재현하며 혼자 짐작하게 되는
자리를 채웠다 (리뷰 반영).

- §1 에 `발생 버전`·`영향 범위` 행 — 어느 버전부터인지 적을 자리가 없었다
- §2.3 재현 환경 — OS·브라우저 표(스크린숏만으로는 버전이 남지 않는다) +
  설정 파일 첨부 칸(§5 는 첨부가 있을 때만 생겨 빈칸이 남지 않았다)
- §3.1 기대 결과 표를 2행으로 + 접수 검사가 기대 결과 행을 센다 — 기대 결과가 0개여도 통과했다
- §4 `긴급도` 칸 → `영향 받는 사람` — 높음·낮음 이분법만 담겼다
- §6 이 `[담당자]` 메모도 지우지 않는다 — 사람이 바꾼 판단의 근거가 사라졌다
```

규칙 1·2·3 을 어깁니다.

- **한 항목에 하위 줄이 다섯입니다**(규칙 1). 하나의 커밋이었다는 이유로 한 덩어리가 됐습니다
- **하위 줄에 동사가 없습니다**(규칙 2). `§1 에 발생 버전·영향 범위 행` 은 무엇을 했는지 적지 않은 명사구입니다
- **가리키는 대상이 문서의 절 번호입니다**(규칙 3). `§2.3`·`§3.1`·`§4` 는 템플릿 파일을 열어야 뜻이 통합니다. 읽는 사람이 겪는 일은 도입 문장의 「혼자 짐작하게 된다」뿐인데, 그것이 여러 줄 중 한 줄입니다

한 커밋이라도 사용자가 겪는 일이 여럿이면 항목을 나눕니다. 종류가 갈리면 종류 제목도 갈립니다.

```markdown
# ✅ Do
### 추가

- 버그를 신고할 때 재현 환경(OS·브라우저)과 설정 파일을 적는 칸을 템플릿에 더했습니다.

### 수정

- 버그 신고 접수 검사가 기대 결과를 한 줄도 적지 않은 신고를 통과시키던 문제를 고쳤습니다.
```

나머지 줄(`§1` 행 추가, `§4` 칸 이름, `§6` 의 메모 보존 등)은 사용자가 신고하는 방식을 바꾸지 않으므로 적지 않습니다. 어디를 어떻게 고쳤는지는 PR 이 갖습니다.

### 쓰기 전 확인

올리기 전에 훑습니다. 전부 「예」여야 합니다.

**무엇을 적었나**

- [ ] 한 문장인가 — 둘째 문장이 있다면 사용자가 새로 할 행동인가 (규칙 1)
- [ ] 동사로 여는가 (규칙 2)
- [ ] 고친 자리가 아니라 사용자 쪽에서 일어난 일을 적었는가 (규칙 3)
- [ ] 어떤 경우에 해당하는지 붙였는가 (규칙 4)
- [ ] 종류 제목 아래에 있는가 (규칙 5)
- [ ] 버전과 날짜가 제목이고 최신이 위인가 (규칙 6)
- [ ] 읽는 사람이 못 여는 번호를 뺐는가 (규칙 7)
- [ ] 이전 버전과 이번 버전만 비교해 적었는가 — 그 사이에 바꾼 안을 넣지 않았는가 (규칙 8)
- [ ] 커밋 메시지 · PR 본문 · 주석에 갈 내용을 뺐는가 (어디에 적나)

**사람에게 읽히나** (규칙 9)

- [ ] 주어가 문장 앞에 나오는가 — 앞에 붙은 수식이 길지 않은가
- [ ] 한 문장이 한 가지만 다루는가 — 도중에 주어가 바뀌지 않는가
- [ ] 동사가 있는가 — 명사구만 나열하지 않았는가
- [ ] 같은 말을 두 번 하지 않았는가 — 조건을 적고 그것을 이유로 다시 설명하지 않았는가
- [ ] 저장소 밖에서도 통하는 말로 가리키는가 — 절 번호, 파일 경로, 내부 함수 이름이 아닌가
- [ ] 뜻이 분명한 말로 문장을 닫았는가 — 「적절한」 「등」 「필요 시」가 아닌가

## 갈릴 수 있는 것과 고르는 기준

조사한 CHANGELOG 13개에서 하는 곳과 안 하는 곳이 갈리던 항목 여섯입니다. 규칙이 아니므로 저장소마다 어느 쪽인지 정합니다. **무엇을 골랐는지는 그 저장소가 적습니다 — 이 문서는 고르는 기준까지입니다.**

| 항목 | 하는 곳 | 안 하는 곳 | 이럴 때 하기를 권합니다 |
|---|---|---|---|
| 스코프 접두 | Vue · Vite · NestJS | Django · Tailwind · Rust · Claude Code | 파일 하나에 여러 패키지의 변경이 섞일 때 |
| 층을 둘로 나누기 | React · NestJS | Django · Rust · Claude Code | 배포 단위가 여럿이거나 한 릴리스의 항목이 수십 개일 때 |
| 기여자 크레딧 | React · Kubernetes · NestJS | Django · Stripe · Claude Code | 저장소 밖에서 기여를 받을 때 |
| 파괴적 변경 별도 절 | Prisma · Astro · Stripe | Vue · Tailwind · Rust | 그런 변경이 이번 버전에 있을 때 |
| `Unreleased` 누적 | Tailwind | 나머지 | 릴리스 사이가 길어 머지할 때마다 쌓아 둬야 할 때 |
| 표 형식 | Stripe | 나머지 | 한 릴리스의 항목이 많아 제품·파괴 여부로 걸러 봐야 할 때 |

아래는 항목마다 실물과 함께 본 것입니다.

### 스코프 접두

패키지 이름을 항목 앞에 붙입니다. 파일 하나에 여러 패키지의 변경이 섞일 때만 값을 합니다.

```
* **compiler-sfc:** ignore comment delimiters inside strings and url() when parsing css vars   (Vue)
* **cli:** support naming the CPU profile via --profile [name]                                 (Vite)
```

### 층을 둘로 나누기

훑는 층과 읽는 층을 가릅니다. React 는 같은 릴리스 안에서 제목으로 가르고, NestJS 는 패키지별로 중첩합니다.

```
### Notable changes      ← 사람이 고른 것
### All Changes          ← 전부                                                (React)

*   `microservices`
    *   [#17766] fix(microservices): always run the kafka processing end hook   (NestJS)
```

### 기여자 크레딧

외부 기여를 받는 저장소가 답니다. 사내 저장소는 달 이유가 없습니다.

```
Transitions now render independently … (@acdlite [#37290])                      (React)
Kubernetes 1.34 is now built with Go 1.26 ([#140919], [@kmala])                 (Kubernetes)
```

### 파괴적 변경 별도 절

종류 제목 중 가장 위에 두고, 무엇이 깨지는지와 무엇을 고쳐야 하는지를 함께 적습니다. 조사한 13개에서 **한 항목이 두 문장을 넘는 경우는 여기뿐이었습니다.**

```
### Breaking changes
… the engine peer moves to `@prisma/cli-engine@0.4.0`.
Make the two agree. Rename it in your schema.                                   (Prisma)

If you were setting `experimental.rustCompiler` in your `astro.config.mjs`,
you can now remove it.                                                          (Astro)
```

### `Unreleased` 누적

아직 나가지 않은 변경을 쌓아 두고, 릴리스할 때 그 덩어리를 버전으로 올립니다.

```
## Unreleased
- Add `@tailwindcss/turbopack` package to run Tailwind CSS with Next.js ([#20367])
- Ensure watch mode detects changes to symlinked `@source` files … ([#20356])    (Tailwind)
```

### 표 형식

항목이 수십 개여서 걸러 봐야 할 때 씁니다. 제목 · 영향 제품 · 파괴 여부 · 분류를 열로 둡니다.

```
| Title | Affected Products | Breaking change? | Category |
| Adds support for the Sui network and USDsui token for crypto payments | … | No | api |   (Stripe)
```

## 참고자료

기준을 뽑은 문서 13개입니다.

- [React](https://github.com/facebook/react/blob/main/CHANGELOG.md) · [Vue](https://github.com/vuejs/core/blob/main/CHANGELOG.md) · [Vite](https://github.com/vitejs/vite/blob/main/packages/vite/CHANGELOG.md) · [Tailwind CSS](https://github.com/tailwindlabs/tailwindcss/blob/main/CHANGELOG.md) · [Astro](https://github.com/withastro/astro/blob/main/packages/astro/CHANGELOG.md)
- [Prisma](https://github.com/prisma/prisma/blob/main/CHANGELOG.md) · [Django](https://docs.djangoproject.com/en/5.2/releases/5.2.1/) · [Rust](https://github.com/rust-lang/rust/blob/master/RELEASES.md) · [Kubernetes](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.34.md) · [NestJS](https://github.com/nestjs/nest/releases)
- [Stripe](https://docs.stripe.com/changelog) · [Slack](https://docs.slack.dev/changelog) · [Claude Code](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)

그 밖에

- [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/) — 종류별 제목의 출처
- 저장소가 고른 값을 적은 예 — [terroir-community-plugin `docs/versioning.md`](https://github.com/VntgCorp/terroir-community-plugin/blob/main/docs/versioning.md)
