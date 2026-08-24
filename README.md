# terroir-claude-plugin-public

> Terroir 공개 Claude Code 플러그인 마켓플레이스.
> **GitHub 인증이나 조직 가입 없이** 설치할 수 있다.

## 설치

Claude Code 세션에서 아래 두 명령을 순서대로 입력한다.

```
/plugin marketplace add VntgCorp/terroir-claude-plugin-public
```

```
/plugin install terroir-onboarding@terroir-claude-plugin-public
```

설치 후 `/plugin` 메뉴에서 `terroir-onboarding`이 보이면 정상이다.

## 제공 플러그인

| 플러그인 | 설명 |
| --- | --- |
| [`terroir-onboarding`](plugins/terroir-onboarding) | Terroir 온보딩 진입점. 처음 시작하는 사람을 위한 안내 |
| [`terroir-harness-mesh`](plugins/terroir-harness-mesh) | 평문 마크다운 지식 베이스 — save/ingest/query/lint 로 자료를 위키로 컴파일하고 근거 기반 질의 |

여기 있는 것은 **테루아 맵의 단계에 속하지 않는** 플러그인이다. 맵 0 SETUP · 1 PORTAL ~
6 OBSERVABILITY 의 단계별 플러그인은 사내 마켓플레이스 `terroir-claude-plugin` 에 있다
(온보딩은 인증 없이 시작할 수 있어야 하므로 예외로 여기 둔다).

### 검증 채널

**마켓플레이스를 어느 브랜치에서 등록했는지**에 따라 설치되는 코드가 달라진다.

| 등록 명령 | 설치되는 코드 |
| --- | --- |
| `add VntgCorp/terroir-claude-plugin-public` | `main` — 배포 버전 |
| `add VntgCorp/terroir-claude-plugin-public@develop` | `develop` — 검증 버전 |

버전을 명시하지 않으므로 커밋마다 새 버전으로 인식된다. 개발 브랜치에 반영된 변경은 아래 두 명령으로 받는다.

```
/plugin marketplace update terroir-claude-plugin-public
/plugin update terroir-onboarding@terroir-claude-plugin-public
```

갱신 후에는 Claude Code를 다시 시작해야 반영된다. `update`에는 `플러그인@마켓플레이스` 전체 이름을 써야 한다 — 플러그인 이름만 쓰면 찾지 못한다.

채널을 바꿀 때는 마켓플레이스를 **지우고 다시 등록**한다. 이미 등록된 이름에 `add`를 다시 실행하면 기존 ref가 남는 경우가 있어, `remove`를 먼저 해야 확실하다.

```
/plugin uninstall terroir-onboarding
/plugin marketplace remove terroir-claude-plugin-public
/plugin marketplace add VntgCorp/terroir-claude-plugin-public@develop
/plugin install terroir-onboarding@terroir-claude-plugin-public
```

설치 후에는 `/plugin`에서 **skill 개수**로 어느 채널인지 확인할 수 있다. 설치가 잘못돼도 오류 없이 skill 0개로 깔리는 경우가 있으므로 개수 확인을 권한다.

## 사용

플러그인을 설치한 뒤 Claude Code에서 이렇게 물어보면 된다.

```
온보딩 시작해줘
```

## 요구사항

- Claude Code (설치 방법은 [공식 문서](https://docs.claude.com/en/docs/claude-code/overview) 참고)
- 그 외 사전 인증 불필요

## 라이선스

VntgCorp R&D
