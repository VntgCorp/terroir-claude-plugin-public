---
name: statusline-setup
description: Claude Code 화면 아래에 사용량 표시줄(statusline)을 설치한다. 현재 디렉터리·git 브랜치·모델·컨텍스트 사용률·5시간/7일 남은 사용량을 보여 준다. Windows · WSL · macOS · 리눅스를 지원한다.
when_to_use: 온보딩 진입점(onboarding)이 업무 지도 등록 뒤에 설치 여부를 물어 사용자가 설치를 고르면 호출한다. 사용자가 직접 "사용량 표시줄 설치해줘", "statusline 설정해줘", "남은 사용량 보이게 해줘", "/statusline-setup"을 요청할 때도 단독 실행할 수 있다.
---

# statusline-setup

Claude Code 화면 아래에 두 줄짜리 표시줄을 설치한다. 사용자가 5시간·7일 사용 한도에 얼마나 남았는지 대화 중에 바로 볼 수 있게 하는 것이 목적이다.

```
➜  📁 my-repo │ 🌿 feature/x ✓
   🤖 Opus │ 🟡 34% ███░░░░░░░ (68.0k / 200k tokens) │ 📊 5h 72% left · 7d 90% left
```

- 1줄: 현재 디렉터리 · git 브랜치(변경 있으면 ✏️, 없으면 ✓)
- 2줄: 모델 · 컨텍스트 사용률 막대와 토큰 수 · 5시간/7일 남은 사용량 · 누적 비용 · 마지막 응답 시간
- 5h·7d 남은 사용량은 claude.ai 계정(Pro·Max)으로 로그인했을 때만 나온다. API key 로 쓰면 그 칸은 빠진다.

## 0. 경로 (모든 절차 공통 — 먼저)

- **스크립트 원본:** 이 스킬이 로드될 때 맨 위에 표시되는 `Base directory for this skill: <절대경로>` 아래의 `statusline-command.sh`(macOS · 리눅스 · WSL)와 `statusline-command.ps1`(Windows). 환경변수(`$CLAUDE_PLUGIN_ROOT`·`$CLAUDE_SKILL_DIR`)는 bash 블록에 주입되지 않으므로 쓰지 않는다. 아래 명령의 `<BASE_DIR>` 자리에 이 절대경로를 쓴다.
- **설치 위치:** `CLAUDE_CONFIG_DIR` 가 있으면 그 디렉터리, 없으면 `~/.claude`. 이후 `<CONFIG>` 로 적는다. 설정 파일은 `<CONFIG>/settings.json` 이다 — 프로젝트의 `.claude/settings.json` 이 아니다.

**스크립트 내용을 직접 다시 쓰지 않는다.** 원본 파일을 복사한다. 두 스크립트는 같은 입력에 같은 출력을 내도록 맞춰 두었다. 손으로 옮기면 그 보장이 깨진다.

## 1. 환경 판별

Claude Code 가 **어디서 실행 중인지**로 정한다. 사용자가 어떤 터미널을 쓰는지는 기준이 아니다. Bash 도구로 아래를 실행한다.

```bash
uname -s; grep -qi microsoft /proc/version 2>/dev/null && echo WSL
```

| 결과 | 환경 | 따를 절 |
|---|---|---|
| `Darwin` | macOS | §2 |
| `Linux` 와 `WSL` | WSL | §2 |
| `Linux` | 리눅스 | §2 |
| `MINGW64_NT-…` · `MSYS_NT-…` · `CYGWIN_NT-…`, 또는 Bash 도구가 없어 PowerShell 로만 실행됨 | Windows | §3 |

WSL 과 Windows 는 설정 파일이 따로 있다. WSL 안에서 실행한 Claude Code 는 WSL 의 `~/.claude/settings.json` 을 읽는다. Windows 에서 실행한 Claude Code 는 `C:\Users\<사용자>\.claude\settings.json` 을 읽는다. 지금 실행 중인 쪽에만 설치한다. 사용자가 다른 쪽에서도 Claude Code 를 쓴다고 하면 그쪽에서 이 스킬을 한 번 더 실행하라고 안내한다.

## 2. 설치 — macOS · 리눅스 · WSL

1. `command -v jq` 로 `jq` 가 있는지 확인한다. 없으면 설치한다.
   - macOS: `brew install jq` (최근 macOS 는 `/usr/bin/jq` 가 기본으로 있다)
   - Ubuntu · Debian · WSL(기본 Ubuntu): `sudo apt-get install -y jq`
   - Fedora · RHEL 계열: `sudo dnf install -y jq`

   `sudo` 는 비밀번호를 물어 Claude 가 직접 실행할 수 없다. 사용자에게 프롬프트에 `! sudo apt-get install -y jq` 처럼 입력해 달라고 안내한 뒤 기다린다. `jq` 가 없으면 표시줄이 비어 나오므로 설치될 때까지 다음 단계로 가지 않는다.
2. 스크립트를 복사한다. `<CONFIG>/statusline-command.sh` 가 이미 있고 원본과 다르면 덮어쓰기 전에 사용자에게 묻는다 — 사용자가 직접 만든 표시줄일 수 있다.
   ```bash
   CONFIG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
   if [ -f "$CONFIG/statusline-command.sh" ] && ! cmp -s "<BASE_DIR>/statusline-command.sh" "$CONFIG/statusline-command.sh"; then echo DIFFERENT; else cp "<BASE_DIR>/statusline-command.sh" "$CONFIG/statusline-command.sh" && echo COPIED; fi
   ```
3. `<CONFIG>/settings.json` 에 아래 항목을 추가한다. §4 의 병합 규칙을 따른다.
   ```json
   "statusLine": {
     "type": "command",
     "command": "bash ~/.claude/statusline-command.sh"
   }
   ```
   `CLAUDE_CONFIG_DIR` 가 있으면 `~/.claude` 자리에 그 절대경로를 쓴다.
4. 동작을 확인한다. 아래 명령이 두 줄을 출력하면 정상이다.
   ```bash
   echo '{"cwd":"'"$HOME"'","model":{"display_name":"Test"},"context_window":{"used_percentage":30}}' | bash "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/statusline-command.sh"
   ```

## 3. 설치 — Windows

Windows 에서는 PowerShell 스크립트를 쓴다. `jq` 는 필요 없다.

Claude Code 는 Windows 에서 Git Bash 가 설치돼 있으면 Git Bash 로, 없으면 PowerShell 로 표시줄 명령을 실행한다. 아래 `command` 는 `powershell` 을 직접 호출하므로 어느 쪽으로 실행돼도 동작한다.

1. 설치 위치를 슬래시(`/`) 형식의 절대경로로 구한다. 이후 `<CONFIG_ABS>` 로 적는다.
   - Git Bash: `cygpath -m "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` → `C:/Users/hong/.claude`
   - PowerShell: `$(if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { "$env:USERPROFILE\.claude" }) -replace '\\','/'`
2. 스크립트를 복사한다. 기존 파일이 원본과 다르면 덮어쓰기 전에 사용자에게 묻는 규칙은 §2 의 2번과 같다.
   - Git Bash: §2 의 2번 명령에서 `.sh` 를 `.ps1` 로 바꿔 실행한다.
   - PowerShell:
     ```powershell
     $dst = "<CONFIG_ABS>/statusline-command.ps1"
     if ((Test-Path $dst) -and ((Get-FileHash $dst).Hash -ne (Get-FileHash "<BASE_DIR>/statusline-command.ps1").Hash)) { 'DIFFERENT' } else { Copy-Item "<BASE_DIR>/statusline-command.ps1" $dst; 'COPIED' }
     ```
3. `<CONFIG_ABS>/settings.json` 에 아래 항목을 추가한다. §4 의 병합 규칙을 따른다.
   ```json
   "statusLine": {
     "type": "command",
     "command": "powershell -NoProfile -ExecutionPolicy Bypass -File C:/Users/hong/.claude/statusline-command.ps1"
   }
   ```
   - 경로는 `<CONFIG_ABS>/statusline-command.ps1` 로 바꾸며 **반드시 슬래시(`/`)로** 쓴다. 역슬래시(`\`)로 쓰면 Git Bash 가 이스케이프 문자로 처리해 경로 구분자가 사라진다. 그러면 오류 메시지 없이 표시줄이 비어 있게 된다.
   - `-ExecutionPolicy Bypass` 는 빼지 않는다. Windows 기본 실행 정책(`Restricted`)은 `.ps1` 파일 실행을 차단한다. 이 옵션은 이 명령 한 번에만 적용되고 시스템 정책은 바꾸지 않는다.
4. 동작을 확인한다. 아래 명령이 두 줄을 출력하면 정상이다.
   - Git Bash:
     ```bash
     echo '{"cwd":"C:/","model":{"display_name":"Test"},"context_window":{"used_percentage":30}}' | powershell -NoProfile -ExecutionPolicy Bypass -File "<CONFIG_ABS>/statusline-command.ps1"
     ```
   - PowerShell:
     ```powershell
     '{"cwd":"C:/","model":{"display_name":"Test"},"context_window":{"used_percentage":30}}' | powershell -NoProfile -ExecutionPolicy Bypass -File "<CONFIG_ABS>/statusline-command.ps1"
     ```

이모지는 Windows Terminal 에서 정상으로 보인다. 예전 콘솔 창(`conhost.exe`)에서는 네모로 보일 수 있으니 그때는 Windows Terminal 을 쓰라고 안내한다.

## 4. settings.json 병합 규칙

1. 파일이 없으면 `{ "statusLine": … }` 하나만 담아 새로 만든다.
2. 파일이 있으면 전체 JSON 을 읽고 **다른 최상위 키는 모두 그대로 둔다.** 파일 전체를 고정된 템플릿으로 덮어쓰지 않는다.
3. `statusLine` 이 이미 있을 때:
   - 이번에 추가할 값과 같으면 바꾸지 않고 "이미 설치돼 있다"고 알린다.
   - 다르면 AskUserQuestion 으로 기존 값을 보여 주고 **교체 / 그대로 두기** 를 묻는다. 그대로 두기를 고르면 §5 의 완료 안내 없이 끝낸다.
4. 기존 JSON 을 파싱할 수 없으면 고치지 않는다. 사용자에게 알린 뒤 멈춘다.
5. 저장한 뒤 파일을 다시 읽어 JSON 파싱과 `statusLine.command` 값을 확인한다.

## 5. 완료 안내

동작 확인까지 성공하면 아래를 출력한다.

> ✅ 사용량 표시줄을 설치했습니다. Claude Code 를 다시 시작하면 화면 아래에 표시됩니다.
> 5시간·7일 남은 사용량은 첫 응답을 받은 뒤부터 나옵니다.

- 온보딩에서 호출됐으면 재시작을 지금 시키지 않는다. 온보딩이 끝난 뒤 재시작하면 된다고 덧붙이고 온보딩 다음 단계로 돌아간다 — 지금 재시작하면 온보딩 대화가 끊긴다.
- 어느 단계에서 실패했으면 성공으로 보고하지 않는다. 실패한 단계와 원인을 한 줄로 알린 뒤 나중에 `/statusline-setup` 으로 다시 시도할 수 있다고 안내한다. 온보딩에서 호출됐으면 실패해도 온보딩을 멈추지 않는다.

## 문제 해결

| 증상 | 원인 | 조치 |
|---|---|---|
| 재시작해도 표시줄이 안 보임 | 이 폴더를 신뢰하지 않았음 · `disableAllHooks` 가 켜져 있음 | 폴더 신뢰를 허용하고 `settings.json` 의 `disableAllHooks` 를 확인 |
| 표시줄이 비어 있음 (macOS · 리눅스 · WSL) | `jq` 없음 | §2 의 1번 |
| 표시줄이 비어 있음 (Windows) | `command` 경로에 역슬래시 · `-ExecutionPolicy Bypass` 누락 | §3 의 3번 |
| 5h·7d 칸이 없음 | API key 로그인 · 첫 응답 전 | claude.ai 계정 로그인 후 한 번 응답을 받으면 나옴 |
| 원인을 모르겠음 | — | `claude --debug` 로 실행하면 스크립트 오류가 로그에 남음 |
