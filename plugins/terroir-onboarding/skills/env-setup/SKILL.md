---
name: env-setup
description: 공통 업무 환경 셋팅 모듈. 직무와 무관하게 모두에게 필요한 도구 연결(지라·컨플루언스 / 이메일·캘린더·구글 드라이브)을 점검하고, 미연결 항목만 연결을 안내한다. GitHub·Git 연결은 다루지 않는다.
when_to_use: 온보딩 진입점(onboarding-start)이 직무 확인 직후, 직무별 분기 앞에서 1회 호출한다. 사용자가 직접 "업무 도구 연결해줘", "환경 셋팅", "/env-setup"을 요청할 때도 단독 실행할 수 있다.
---

# env-setup

직무 분기와 무관한 공통 도구 연결을 점검·안내하는 독립 모듈이다. 온보딩 밖에서도 재사용할 수 있다.

**이 모듈은 GitHub 계정 상태를 참조하지 않는다.** Git·GitHub 연결은 `github-connect` 스킬 소관이다.

## 연결 대상

| 그룹 | 도구 | 연결 수단 |
| --- | --- | --- |
| Atlassian | 지라, 컨플루언스 | Claude가 `claude mcp add`로 등록 → 사용자는 `/mcp` 인증만 |
| Google | Gmail(이메일), 캘린더, 드라이브 | claude.ai 웹 Settings → Connectors에서 연결 (Claude Code로 자동 동기화) |

## 절차

### 1. 연결 상태 확인

현재 세션에서 각 서비스의 MCP 도구가 사용 가능한지 확인한다 (도구 목록에 해당 서비스 도구가 보이는지, 또는 가벼운 조회 호출이 성공하는지).

- 도구가 보이고 호출이 성공하면 **연결됨** — 해당 항목은 건너뛴다.
- 도구가 없거나 인증 오류가 나면 **미연결** — §2에서 안내한다.

### 2. 미연결 항목 안내

미연결 항목만 골라, 항목별로 아래를 안내하고 사용자가 완료할 때까지 하나씩 진행한다. 신규 환경의 `/mcp` 목록은 비어 있는 게 정상이다 — "목록에서 골라라"로 안내하지 않는다.

- **지라·컨플루언스 (Atlassian)**: 사용자에게 명령을 시키지 말고 Claude가 직접 등록한다 (`claude mcp list`에 `atlassian`이 이미 있으면 건너뛴다):

  ```
  claude mcp add --transport http atlassian https://mcp.atlassian.com/v1/mcp/authv2 --scope user
  ```

  등록 후 사용자에게 `/mcp` 실행 → `atlassian` 선택 → 브라우저에서 회사 Atlassian 계정으로 로그인·허용을 안내한다. `/mcp` 목록에 안 보이면 Claude Code 재시작 후 재시도를 안내한다. (구 엔드포인트 `/v1/sse`는 2026-06 폐기 — 쓰지 않는다)

- **Gmail / 캘린더 / 드라이브 (Google)**: **Claude Code에서는 인증할 수 없다** — Google이 claude.ai가 등록한 리다이렉트 URL만 허용한다. 대신 사용자가 설정 메뉴를 찾아 헤매지 않도록 **Claude가 커넥터 설정 페이지를 브라우저로 직접 연다**:

  - macOS: `open "https://claude.ai/settings/connectors"`
  - Windows: `cmd.exe /c start "" "https://claude.ai/settings/connectors"`
  - WSL: 브라우저 자동 실행이 불안정하므로 열지 말고 URL을 출력해 Windows 브라우저에서 직접 열도록 안내

  열린 페이지에서 Gmail·Google Calendar·Google Drive를 각각 **Connect** → 회사 Google 계정으로 허용하도록 안내한다. 연결하면 Claude Code에 자동 반영된다 (재시작 불필요, 다음 `/mcp`에서 확인).

주의: claude.ai 커넥터 동기화는 Claude Code가 **claude.ai 구독 로그인**일 때만 동작한다. Google 항목이 연결 후에도 안 보이면 `/status`에서 로그인 방식을 확인하게 한다 (`ANTHROPIC_API_KEY` 등 다른 인증이 활성화돼 있으면 커넥터가 로드되지 않는다).

완료 확인은 AskUserQuestion을 쓰지 말고 일반 출력으로 턴을 끝낸다 (사용자가 `/mcp`를 입력해야 하므로 입력창을 막지 않는다). 안내 끝에 "연결을 마치면 알려주세요. 건너뛰려면 '건너뛰기'라고 답해주세요." 한 줄을 붙인다.

### 3. 재확인 및 종료

연결을 마친 항목은 §1 방식으로 재확인한다. 전 항목이 연결(또는 사용자가 명시적으로 건너뜀)되면 결과를 한 줄 요약으로 보여주고 모듈을 종료한다.

> 환경 셋팅 결과 — 지라·컨플루언스 ✅ / 메일 ✅ / 캘린더 ✅ / 드라이브 ✅

온보딩 흐름에서 호출된 경우, 이후 어느 경로로 가든 이 모듈을 다시 호출하지 않는다.
