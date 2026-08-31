# terroir-feedback

> 떼루아를 쓰다 겪은 **에러 · 없는 기능 · 기능 요청**을 Claude Code 안에서 바로 플랫폼 개발팀에 보내는 플러그인.
> 사전 인증 없이 설치할 수 있다.

다른 채널을 찾아 옮겨 적는 단계를 없애, 겪은 자리에서 바로 보내게 한다. 보내는 내용은 사용자가 미리보기에서 승인한 요약만이다 — 대화 전체나 소스코드는 나가지 않는다.

## 설치

```
/plugin marketplace add VntgCorp/terroir-claude-plugin-public
/plugin install terroir-feedback@terroir-claude-plugin-public
```

설치 후 Claude Code 를 재시작한다. 세션 시작 시 자동 제안 규칙이 실리기 때문이다.

## 사용

직접 부르기

```
피드백 보내기
떼루아 팀에 알려줘 — 배포 설정 화면 주소가 안 열려
/terroir-feedback:feedback
```

자동 제안 — 떼루아 스킬이 실패했거나 결과가 기대와 다르다고 말하면, 그 작업이 끝난 뒤 Claude 가 리포트 여부를 한 번 묻는다. 세션당 한 번이고 거절하면 다시 묻지 않는다.

## 흐름

```
진입 ─▶ 분류·재료 모으기 ─▶ 미리보기(전문) ─▶ 보내기 / 수정 / 취소
                                                 │
                                                 ├─ 보내기 ─▶ Google Chat 채널 ─▶ "접수 ID: ..."
                                                 └─ 실패 ─▶ ~/.terroir/feedback-outbox/ 저장 + 채널 링크 안내
```

## 무엇이 전달되나

| 항목 | 채우는 주체 |
|---|---|
| 분류 (🐞 에러 / 🚫 없는 기능 / 💡 기능 요청) · 한 줄 제목 | Claude 가 대화에서 추정, 사용자 확정 |
| 기대 · 실제 · 재현 (기능 요청은 원하는 것 · 지금은 · 왜 필요한가) | Claude 가 대화에서 요약 |
| 환경 — 설치된 terroir 플러그인 버전 · Claude Code 버전 · OS | `scripts/collect-env.sh` |
| 리포트 ID · 신고자 이메일 | `scripts/send.sh` · `git config user.email` |

넣지 않는 것 — 대화 전체 · 소스코드 · 파일 내용 · 자격증명. 형식은 [`skills/feedback/report-template.md`](skills/feedback/report-template.md).

## 구조

```
terroir-feedback/
├── .claude-plugin/plugin.json
├── hooks/
│   ├── hooks.json            SessionStart → session-start.sh
│   └── session-start.sh      triggers.md 를 세션 컨텍스트로 출력
└── skills/feedback/
    ├── SKILL.md              정리 → 미리보기 → 승인 → 전송
    ├── triggers.md           자동 제안 조건·빈도 규칙 (hook 이 주입)
    ├── report-template.md    리포트 형식·채우기 규칙·제외 항목
    ├── config.json           webhook_url · fallback_channel_url
    └── scripts/
        ├── collect-env.sh    환경 한 줄 수집
        └── send.sh           POST · 실패 시 outbox 저장
```

## 운영 메모

- `config.json` 의 `webhook_url` 은 Google Chat incoming webhook 주소다. 공개 레포에 노출되는 것을 알고 둔 결정이다 — 남용이 보이면 Chat 에서 webhook 을 지우고 새로 만들어 이 값만 바꾼다.
- 중계 서버(URL 비노출 · rate limit · Jira 자동 생성 · 같은 에러 묶기 · 통계)는 필요해질 때 붙인다. 그때도 플러그인은 `webhook_url` 만 바뀐다.
