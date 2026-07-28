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

### 검증 채널

플러그인은 하나이며, **마켓플레이스를 어느 브랜치에서 등록했는지**에 따라 설치되는 코드가 달라진다.

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

채널을 바꿀 때는 마켓플레이스를 다시 등록(`add`가 덮어쓴다)한 뒤 위 두 명령을 실행하면 된다. 브랜치가 다르면 커밋도 다르므로 갱신이 감지되어, 플러그인을 지웠다 다시 설치할 필요가 없다.

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
