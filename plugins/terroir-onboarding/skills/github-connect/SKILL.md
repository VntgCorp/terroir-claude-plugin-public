---
name: github-connect
description: VNTG 조직 GitHub 계정 보유자를 위한 온보딩 경로. GitHub 계정 연결 → Git 연결 → private 플러그인 접근 확인 → 설치까지 진행하고, 접근 불가면 org-access-request로 분기한다.
when_to_use: onboarding-start에서 "프로덕트 관련 직군 + 조직 GitHub 계정 있음"으로 분기됐을 때. 사용자가 직접 "GitHub 연결", "gh 인증", "/github-connect"를 요청할 때도 단독 실행할 수 있다. 또한 조직 계정 승인 후 사용자가 "테루아 Github 승인이 완료됐음"(및 유사 표현 — 조직 계정·GitHub 승인이 끝났다는 취지)이라고 말했을 때 이어받기 진입점으로 실행된다.
---

# github-connect

VNTG 조직 GitHub 계정 보유자의 해피패스. 기존 `setup-git-gh.sh` 스크립트가 하던 일(git·gh 설치, gh 인증, git 사용자 설정)을 이 스킬이 흡수한다 — 별도 스크립트 다운로드는 필요 없다.

## 절차

각 단계는 먼저 상태를 확인하고, 이미 완료된 단계는 건너뛴다.

### 1. git·gh 설치 확인

`git --version`, `gh --version`을 실행한다. 없는 도구는 OS에 맞게 설치를 안내한다.

- macOS: `brew install git gh`
- Windows(WSL)/Linux: `sudo apt update && sudo apt install -y git gh`

### 2. GitHub 계정 연결

`gh auth status`로 인증 상태를 확인한다. 미인증이면 실행한다.

```
gh auth login --scopes "repo,workflow,read:org"
```

디바이스 플로우로 진행된다: 터미널에 표시된 8자리 코드를 복사 → Enter를 누르면 브라우저가 열림 → 코드 입력 → 본인 GitHub 계정(VNTG 조직에 초대된 계정)으로 승인. 완료 후 `gh auth status`로 재확인한다.

### 3. Git 연결

조직 계정 연결 직후 수행한다.

1. `git config --global user.name` / `user.email`을 확인하고, 비어 있으면 사용자에게 이름·회사 이메일을 물어 설정한다.
2. `gh auth setup-git`을 실행해 git이 gh 인증 정보를 쓰도록 연결한다. private 레포 clone(다음 단계의 플러그인 설치 포함)에 필요하다.

### 4. private 플러그인 접근 확인

```
gh repo view VntgCorp/terroir-claude-plugin --json name
```

- **성공** → §5로.
- **실패(404/권한 오류)** → 조직 미가입 또는 권한 미부여 상태다. `org-access-request` 스킬로 분기해 접근 요청을 진행한다. 이 스킬은 여기서 종료.

### 5. private 플러그인 설치

Claude Code 안에서 사용자에게 아래를 순서대로 실행하도록 안내한다. (§3의 `gh auth setup-git` 덕분에 private 레포도 clone된다)

```
/plugin marketplace add VntgCorp/terroir-claude-plugin
```

이후 `/plugin` 메뉴 → 방금 추가된 마켓플레이스에서 필요한 플러그인을 선택해 설치하고 `/reload-plugins`로 반영한다. 어떤 플러그인이 있는지는 메뉴에 표시되는 각 플러그인의 설명을 보고 고르면 된다.

### 6. 완료

`onboarding-start` 스킬의 "공통 종료 출력" 섹션(제공 기능 안내 + "무엇을 도와드릴까요")을 실행하고 온보딩을 마친다.

## 이어받기 (승인 후 재개)

조직 계정 승인 후 사용자가 **"테루아 Github 승인이 완료됐음"** 이라고 입력하면 이 스킬이 실행된다 (`org-access-request` 스킬 §3에서 안내한 재개 문구).

- 재개 시에도 §1부터 순서대로 진행한다. 각 단계가 상태를 확인하고 완료된 것은 건너뛰므로, 자연스럽게 중단 지점(대개 §2 계정 연결)부터 이어진다.
- 승인 직후이므로 §4 접근 확인은 성공해야 정상이다. 실패하면 승인 반영 지연일 수 있으니 몇 분 후 재시도를 안내하고, 계속 실패하면 플랫폼개발팀 확인을 안내한다.
- 이후 §5 설치 → §6 공통 종료 출력까지 완주한다.
