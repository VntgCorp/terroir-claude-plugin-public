# terroir-claude-plugin-public

> Terroir 공개 Claude Code 플러그인 마켓플레이스.
> **GitHub 인증이나 조직 가입 없이** 설치할 수 있다.

## 최근 릴리즈

### 2026-09-02

| 플러그인 | 버전 | 주요 변경사항 | 사용자 조치 |
|---|---|---|---|
| [`terroir-onboarding`](plugins/terroir-onboarding/CHANGELOG.md) | `1.0.1` | `/onboarding`이 public 마켓플레이스의 자동 업데이트를 활성화하고, private 플러그인 설치 경로에서는 private 마켓플레이스에도 같은 설정을 적용 | 플러그인 업데이트 후 `/reload-plugins` |

이 표는 최신 릴리즈만 보여준다. 이전 버전의 변경사항은 플러그인별 변경 이력에서 확인한다.

## 버전 정책

마켓플레이스 최상위 `version`은 카탈로그의 **호환성 세대**를 나타낸다. `1.0.0` → `2.0.0`처럼
Major만 올리고 Minor와 Patch는 `0`으로 유지한다. 기존 사용자가 마켓플레이스를 다시 등록하거나
플러그인을 다시 설치해야 하는 등 별도 마이그레이션이 필요한 비호환 변경에만 올린다. 예를 들면
마켓플레이스 이름 변경, 자동 이관할 수 없는 플러그인의 대규모 개명·제거, 접근 정책이나 소스 구조의
근본적인 변경이 해당한다.

플러그인 추가·기능 변경·버그 수정과 README·카탈로그 설명 변경은 마켓플레이스 버전을 올리지
않는다. 플러그인 변경은 각 `.claude-plugin/plugin.json`의 SemVer와 플러그인별 변경 이력으로
관리한다. 마켓플레이스 최상위 버전 자체는 설치된 플러그인의 업데이트를 발생시키지 않는다.
버전 필드의 역할은 [Claude Code 공식 문서](https://code.claude.com/docs/en/plugin-marketplaces)를
따른다.

## 설치

Claude Code 세션에서 아래 두 명령을 순서대로 입력한다.

```
/plugin marketplace add VntgCorp/terroir-claude-plugin-public
```

```
/plugin install terroir-onboarding@terroir-claude-plugin-public
```

설치 후 `/plugin` 메뉴에서 `terroir-onboarding`이 보이면 정상이다.
`/onboarding`을 처음 실행하면 public 마켓플레이스의 자동 업데이트를 사용자 전역 설정에 켜고
결과를 안내한다. 프로덕트 직군의 private 플러그인 설치까지 진행하면 private 마켓플레이스도 함께
설정한다.

## 이름 변경 안내 (2026-08-26)

온보딩 진입 스킬 이름이 `/onboarding-start` 에서 **`/onboarding`** 으로 바뀌었다. 플러그인 이름은
그대로라 재설치 없이 아래 명령과 `/reload-plugins`로 반영된다.

```bash
claude plugin update terroir-onboarding@terroir-claude-plugin-public
```

규칙은 [ADR-001](docs/adr/001-ADR-Adopt%20the%20naming%20convention%20of%20the%20private%20marketplace.md).

## 제공 플러그인

| 플러그인 | 설명 |
| --- | --- |
| [`terroir-onboarding`](plugins/terroir-onboarding) | Terroir 온보딩 진입점. 처음 시작하는 사람을 위한 안내 |
| [`terroir-harness-mesh`](plugins/terroir-harness-mesh) | 평문 마크다운 지식 베이스 — save/ingest/query/lint 로 자료를 위키로 컴파일하고 근거 기반 질의 |

### 검증 채널

**마켓플레이스를 어느 브랜치에서 등록했는지**에 따라 설치되는 코드가 달라진다.

| 등록 명령 | 설치되는 코드 |
| --- | --- |
| `add VntgCorp/terroir-claude-plugin-public` | `main` — 배포 버전 |
| `add VntgCorp/terroir-claude-plugin-public@develop` | `develop` — 검증 버전 |

플러그인 버전은 각 플러그인의 `.claude-plugin/plugin.json`에서 관리한다. 개발 브랜치에 반영된
변경은 셸에서 아래 두 명령으로 받는다.

```bash
claude plugin marketplace update terroir-claude-plugin-public
claude plugin update terroir-onboarding@terroir-claude-plugin-public
```

갱신 후에는 `/reload-plugins`를 실행하거나 Claude Code를 다시 시작해야 반영된다.

채널을 바꿀 때는 마켓플레이스를 **지우고 다시 등록**한다. 이미 등록된 이름에 `add`를 다시 실행하면 기존 ref가 남는 경우가 있어, `remove`를 먼저 해야 확실하다.

```
/plugin uninstall terroir-onboarding
/plugin marketplace remove terroir-claude-plugin-public
/plugin marketplace add VntgCorp/terroir-claude-plugin-public@develop
/plugin install terroir-onboarding@terroir-claude-plugin-public
```

설치 후에는 `/plugin`에서 **skill 개수**로 어느 채널인지 확인할 수 있다. 설치가 잘못돼도 오류 없이 skill 0개로 깔리는 경우가 있으므로 개수 확인을 권한다.

## 업데이트

### 자동 업데이트 (권장)

공식 Anthropic 마켓플레이스와 달리 서드파티 마켓플레이스의 자동 업데이트는 기본 OFF다.
`/onboarding`은 실행 초기에 `terroir-claude-plugin-public`의 사용자 전역 설정을
`autoUpdate: true`로 바꾸고 결과를 안내한다. private 플러그인 설치 경로에서는
`terroir-claude-plugin`에도 같은 설정을 적용한다.

Claude Code는 세션 시작 후 최대 10분의 임의 지연을 두고 자동 업데이트를 확인한다. 새 버전은
백그라운드에서 디스크에 내려받고, 실행 중인 세션에는 `/reload-plugins`를 실행하거나 다음 세션부터
적용된다.

기존 사용자처럼 온보딩 자동 설정을 받지 못했다면 `/plugin` → `Marketplaces` → 대상 마켓플레이스
→ `Enable auto-update`에서 최초 1회 켠다.

### 수동 업데이트

자동 확인을 기다리지 않고 즉시 갱신하려면 셸에서 실행한다.

```bash
# 마켓플레이스 카탈로그 갱신
claude plugin marketplace update terroir-claude-plugin-public

# 설치된 플러그인 갱신
claude plugin update terroir-onboarding@terroir-claude-plugin-public
```

완료 후 실행 중인 Claude Code 세션에서 `/reload-plugins`를 실행하거나 Claude Code를 다시 시작한다.

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
