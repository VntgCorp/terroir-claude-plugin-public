# terroir-context

> 직군과 상관없이 **전 직원에게 필요한 컨텍스트**를 세션 시작 때 Claude 에 올리는 플러그인.
> 사전 인증 없이 설치할 수 있다.

개발자가 받는 private `terroir-project-context` 가 사내 개발 표준을 올리듯, 이 플러그인은 모두에게 필요한 사내 안내를 올린다. Claude 는 목차를 보고 관련 질문이 오면 원문을 읽어 답한다.

## 설치

```
/plugin marketplace add VntgCorp/terroir-claude-plugin-public
/plugin install terroir-context@terroir-claude-plugin-public
```

설치 후 Claude Code 를 재시작한다. 세션 시작 시 목차가 실리기 때문이다.

직접 설치하지 않아도 된다. 온보딩(`/onboarding`)이 묻지 않고 설치하고, 이미 온보딩을 마친 사람에게는 `terroir-onboarding` 이 세션 시작 때 설치를 한 번 묻는다.

## 동작

```
세션 시작 ─▶ docs/index.md 에 목차 항목이 있나?
              ├─ 없음 ─▶ 아무것도 올리지 않음
              └─ 있음 ─▶ 원본 경로 + 목차를 메인 세션에 올림
```

- 메인 세션에만 올린다. 서브에이전트에는 올리지 않는다.
- 문서 본문은 올리지 않는다. Claude 가 필요할 때 원본 경로로 읽는다.

## 스킬

| 스킬 | 하는 일 |
|---|---|
| `/terroir-context:changelog-write` | CHANGELOG 항목을 [변경 이력 쓰는 법](docs/changelog-writing.md)대로 쓴다. 규칙은 그 문서가 원본이고, 스킬은 문서를 읽는 절차만 갖는다 |

목차에도 같은 문서가 올라가 있어, 스킬을 부르지 않아도 CHANGELOG 를 쓸 때 Claude 가 문서를 먼저 읽는다.

## 문서 추가

1. `docs/` 아래에 문서를 만든다.
2. `docs/index.md` 에 `- [제목](파일.md) — 한 줄 설명` 을 더한다. 한 줄 설명은 Claude 가 언제 이 문서를 읽을지 판단하는 근거다.
3. `plugin.json` 버전과 `CHANGELOG.md` 를 함께 올린다 (ADR-002). `docs/` 만 바꿔도 올린다 — 버전이 그대로면 설치본이 갱신되지 않아 문서가 퍼지지 않는다.
