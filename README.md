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
| `terroir-onboarding-dev` | 위 플러그인의 검증용 채널. 배포 전 확인에만 쓴다 — 일반 사용자는 설치하지 않는다 |

### 채널 구분

`terroir-onboarding`은 `main` 브랜치의 코드를, `terroir-onboarding-dev`는 `develop` 브랜치의 코드를 설치한다.
검증 채널은 커밋마다 새 버전으로 인식되므로, `develop`에 반영된 변경을 아래 두 명령으로 받을 수 있다.

```
/plugin marketplace update terroir-claude-plugin-public
/plugin update terroir-onboarding-dev@terroir-claude-plugin-public
```

갱신 후에는 Claude Code를 다시 시작해야 반영된다. `update`에는 `플러그인@마켓플레이스` 전체 이름을 써야 한다 — 플러그인 이름만 쓰면 찾지 못한다.

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
