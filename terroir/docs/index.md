# 사내 표준 개발 가이드 인덱스 — 도구

> Managed by gh-terroir-byor. 사내 표준 변경 시 갱신됩니다. 직접 수정하지 마세요.
> Claude Code 세션 시작 시 SessionStart hook 이 이 파일을 읽어 세션 컨텍스트로 주입합니다.

이 레포는 **개발자가 직접 실행하는 도구**(`spec.type: tool`)입니다. CLI·하네스·플러그인처럼
실행 가능한 산출물이 있지만 서버로 떠 있지 않고, 다른 코드가 의존하지도 않습니다.

**작업과 관련된 문서를 먼저 읽고 진행하세요.**

## 카탈로그 — [architecture/](architecture/)

- [software-types.md](architecture/software-types.md) — 소프트웨어 종류(`spec.type`) 다섯의 정의·판별 기준·예시. **이 레포가 왜 `library` 가 아니라 `tool` 인지가 여기 있습니다**

## 워크플로우 — [workflow/](workflow/)

- [branch-and-commit.md](workflow/branch-and-commit.md) — 브랜치 운영·커밋 메시지 규칙
- [pr-and-merge.md](workflow/pr-and-merge.md) — PR 단위·머지 방식·히스토리 관리

## 코드 — [architecture/](architecture/)

- [coding-conventions.md](architecture/coding-conventions.md) — 이름 짓기·포맷 규칙

## 시작하기 — [getting-started/](getting-started/)

- [version-update.md](getting-started/version-update.md) — terroir 표준 버전 신호와 갱신 대응

## 이 종류에서 특히 주의할 것

**사용자가 이 도구를 어떻게 얻고 어떻게 실행하는지**를 README 에 명확히 적으세요. 도구는
의존성으로 끌려오는 것이 아니라 사람이 찾아서 실행하는 것이라, 설치와 실행 방법이 곧
사용성입니다. 카탈로그 목록에서 이 레포를 발견한 사람이 README 하나로 시작할 수 있어야 합니다.

## 이 종류에 해당하지 않는 것

| 주제 | 왜 해당 없나 |
|------|-------------|
| `terroir.json` · 배포 매니페스트 · 환경 매핑 | 배포 대상이 아니라 이 레포에 `terroir.json` 자체가 없다 |
| 모노레포 구조 · 빌드 시스템 | `apps/`·`libs/` 를 가진 모노레포 전제의 규칙이다 |
| DB · API · Kafka · 관측성 | 런타임 프로세스가 없다 |

## 도움이 필요할 때

- 플랫폼 개발팀 Google Chat: [문의 채널](https://chat.google.com/room/AAQA6AZNGHU?cls=7)
