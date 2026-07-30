---
name: github-connect
description: GitHub 계정 보유자를 위한 온보딩 경로. GitHub 계정 연결 → Git 연결 → private 플러그인 접근 확인 → 설치까지 진행하고, 접근 불가면 org-access-request로 분기한다. 조직 소속 여부는 묻지 않고 접근 확인으로 판별한다.
when_to_use: onboarding-start에서 "프로덕트 관련 직군 + GitHub 계정 있음"으로 분기됐을 때. 사용자가 직접 "GitHub 연결", "gh 인증", "/github-connect"를 요청할 때도 단독 실행할 수 있다. 또한 조직 접근 승인 후 사용자가 "VNTG 조직 초대를 수락했음"(및 유사 표현 — 조직 초대 수락·GitHub 승인이 끝났다는 취지)이라고 말했을 때 이어받기 진입점으로 실행된다.
---

# github-connect

GitHub 계정 보유자의 해피패스. git·gh 설치부터 gh 인증, git 사용자 설정, private 플러그인 설치까지 이 스킬이 진행한다.

## 절차

각 단계는 먼저 상태를 확인하고, 이미 완료된 단계는 건너뛴다.

사용자에게 제시하는 모든 명령은 bash 문법으로 쓴다 — `!` 실행은 Windows에서도 bash(Git Bash)로 동작하므로 PowerShell 문법(`&`, 백슬래시 경로)을 쓰지 않고, Windows 경로는 슬래시(`C:/Program Files/...`)로 쓴다.

### 1. git·gh 설치 확인

`git --version`, `gh --version`을 실행한다. 없는 도구는 OS에 맞게 설치를 안내한다.

- macOS: `brew install git gh`
- Windows: `winget install --id Git.Git`, `winget install --id GitHub.cli` — git 설치 전에는 Bash 도구가 없어 PowerShell로 실행되므로 `apt`를 안내하지 않는다. 설치 후 Bash 도구가 붙으려면 Claude Code 재시작이 필요하다.
- WSL/Linux: `sudo apt update && sudo apt install -y git gh`

### 2. GitHub 계정 연결

`gh auth status`로 인증 상태를 확인한다. 미인증이면 사용자에게 명령을 시키지 말고, Claude가 직접 Bash 백그라운드로 실행한다 (플래그로 대화형 질문을 전부 선점한다).

```
gh auth login --hostname github.com --git-protocol https --web --scopes "repo,workflow,read:org"
```

실행 직후 백그라운드 출력에서 8자리 디바이스 코드를 읽어, 사용자에게는 아래 형식만 보여준다.

> **지금 바로 하실 일**
> 1. 브라우저에서 열기 → https://github.com/login/device
> 2. 코드 입력 → `XXXX-XXXX`
> 3. VNTG 조직에 초대된 본인 GitHub 계정으로 로그인 → 권한 승인
>
> ⏱️ 코드는 몇 분 후 만료됩니다. 만료되면 다시 발급해 드릴게요.

승인되면 백그라운드 프로세스가 스스로 완료된다. `gh auth status`로 재확인한 뒤 다음 단계로 간다.

폴백: gh가 비대화형 실행을 거부하면 같은 명령을 사용자가 `!`로 직접 실행하게 안내한다. 이때 120초 후 타임아웃 → 백그라운드 이동은 **정상 동작**이다 — 즉시 출력 파일을 Read해 디바이스 코드를 추출하고 위 형식으로 안내한다.

### 3. Git 연결

조직 계정 연결 직후 수행한다.

1. `git config --global user.name` / `user.email`을 확인하고, 비어 있으면 사용자에게 이름·회사 이메일을 물어 설정한다.
2. `gh auth setup-git`을 실행해 git이 gh 인증 정보를 쓰도록 연결한다. private 레포 clone(다음 단계의 플러그인 설치 포함)에 필요하다.

### 4. private 플러그인 접근 확인

```
gh repo view VntgCorp/terroir-claude-plugin --json name
```

- **성공** → §5로.
- **실패(404/권한 오류)** → 바로 분기하지 말고 조직 멤버십 상태를 먼저 확인한다.

```
gh api /user/memberships/orgs/VntgCorp --jq .state
```

- `pending` → 초대를 아직 수락하지 않은 상태다. **본인이 수락하면 끝나므로 `org-access-request`로 보내지 않는다** (담당자는 이미 초대를 보냈다). https://github.com/orgs/VntgCorp/invitation 에서 수락하도록 안내하고, 수락 후 §4를 재시도한다.
- `active` → 조직 가입은 됐고 레포 권한만 없다. `org-access-request`로 분기하되, "조직 가입은 완료됐고 레포 접근 권한만 필요하다"는 점을 사용자에게 알려 담당자에게 그대로 전달하게 한다.
- 그 외(조회 실패 등) → 조직 미가입. `org-access-request`로 분기한다.

`pending`을 제외하면 이 스킬은 여기서 종료.

### 5. private 플러그인 설치

사용자에게 명령을 시키지 말고 Claude가 직접 Bash로 실행한다. (§3의 `gh auth setup-git` 덕분에 private 레포도 clone된다)

1. 마켓플레이스 추가: `claude plugin marketplace add VntgCorp/terroir-claude-plugin`
2. 마켓플레이스의 플러그인 목록을 확인하고(마켓플레이스 레포의 `.claude-plugin/marketplace.json`), **전체 플러그인**을 각각 설치한다: `claude plugin install <플러그인>@terroir-claude-plugin --scope user`
3. 설치 결과를 요약해 보여주고, 사용자에게 `/reload-plugins` 입력을 안내한 뒤 **턴을 끝내고 기다린다** — 내장 명령이라 사용자만 입력할 수 있다.

설치 후에도 스킬이 안 보이면 설치됨+비활성 상태일 수 있다 — `claude plugin enable <플러그인>@terroir-claude-plugin` 실행 후 `/reload-plugins` 재안내.

### 6. 개발 런타임 셋팅 위임·완료

`/reload-plugins` 실행(또는 사용자의 완료 확인)을 확인한 뒤에만 실행한다 — §5 안내와 같은 턴에서 완료를 선언하지 않는다.

개발 런타임(Node.js·pnpm) 셋팅은 §5에서 설치된 private 플러그인의 개발 환경 셋팅 스킬이 담당한다 — 리로드 후 스킬 목록에서 해당 스킬을 찾아 실행해 이어간다 (진행/건너뛰기는 그 스킬이 묻는다). 스킬이 보이지 않으면 셋팅 없이 진행하고, 필요해지면 나중에 실행할 수 있음을 한 줄 안내한다.

이후 `onboarding-start` 스킬의 "공통 종료 출력" 섹션(제공 기능 안내 + "무엇을 도와드릴까요")을 실행하고 온보딩을 마친다.

## 이어받기 (승인 후 재개)

조직 접근 승인 후 사용자가 **"VNTG 조직 초대를 수락했음"** 이라고 입력하면 이 스킬이 실행된다 (`org-access-request` 스킬 §3에서 안내한 재개 문구).

- 재개 시작 시 "승인이 실제 반영됐는지 확인부터 진행하겠다"고 말하고 시작한다. 승인 완료로 단정하는 표현은 §4 접근 확인 성공 후에만 쓴다.
- 재개 시에도 §1부터 순서대로 진행한다. 각 단계가 상태를 확인하고 완료된 것은 건너뛰므로, 자연스럽게 중단 지점(대개 §2 계정 연결)부터 이어진다.
- 승인 직후이므로 §4 접근 확인은 성공해야 정상이다. 실패하면 §4의 멤버십 상태 확인 분기를 따른다 — 초대를 수락하지 않았으면 `pending`으로 잡힌다. `active`인데도 실패하면 반영 지연일 수 있으니 몇 분 후 재시도를 안내하고, 계속 실패하면 플랫폼개발팀 확인을 안내한다.
- 이후 §5 설치 → §6(개발 런타임 위임·공통 종료 출력)까지 완주한다.
