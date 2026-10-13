# terroir-statusline

> **Claude 사용량 표시** — Claude Code 입력창 아래에 Claude 를 얼마나 더 쓸 수 있는지(5시간·주간 한도), 컨텍스트 사용률, 모델, git 브랜치를 표시한다.
> Claude Code mod 로 만들어 Windows · WSL · macOS · 리눅스에서 같은 코드로 동작한다.

```
📁 my-repo │ 🌿 feature/x ✓ │ 🤖 Opus 5.5 │ 🟡 34% ███░░░░░░░ (68.0k / 200k) │ 📊 5h 72% left (2h13m) · 7d 90% left │ 💰 $1.23
```

| 칸 | 내용 |
|---|---|
| 📁 | 현재 디렉터리 이름 |
| 🌿 | git 브랜치. 커밋하지 않은 변경이 있으면 ✏️, 없으면 ✓. git 저장소가 아니면 빠진다 |
| 🤖 | 모델 |
| 🟢🟡🟠🔴 | 컨텍스트 사용률(25·50·80% 기준으로 색이 바뀐다)과 토큰 수 |
| 📊 | 5시간·주간(7일) 한도에서 남은 비율과 초기화까지 남은 시간. claude.ai 계정(Pro·Max)으로 로그인했을 때만 나온다 |
| 💰 | 이 세션의 예상 비용(정가 기준) |

## 설치

Claude Code **2.1.287 이상**이 필요하다(`claude --version`). 온보딩(`/onboarding`) 중에 설치할지 묻는다. 따로 설치하려면 아래를 실행한 뒤 `/reload-plugins` 를 입력한다.

```
claude plugin install terroir-statusline@terroir-claude-plugin-public --scope user
```

## 기존 표시줄과의 관계

`settings.json` 의 `statusLine` 을 쓰지 않는다. 직접 설정한 표시줄이 있으면 그대로 두고 그 옆에 이 줄이 함께 표시된다.

## 끄기

```
claude plugin uninstall terroir-statusline@terroir-claude-plugin-public
```

## 개발

- 구조: `hooks/register.tsx`(mod 본체) · `types/index.d.ts`(상태 타입) · `tests/format.test.ts`(표시 문자열 테스트)
- 검사: `claude plugin validate plugins/terroir-statusline` · `claude plugin test plugins/terroir-statusline`
- 로컬 실행: `claude --plugin-dir plugins/terroir-statusline` (저장할 때마다 다시 로드)
- mod API 는 early access 다. Claude Code 업데이트로 API 가 바뀌면 표시가 사라질 수 있다 — `claude --debug` 로그에서 `terroir-statusline:` 줄을 확인한다.
