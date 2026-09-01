# terroir-feedback

> 떼루아를 쓰다 겪은 **에러·오동작 · 기능 요청 · 권한 요청**을 Claude Code 안에서 바로 플랫폼 개발팀에 보내는 플러그인.
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
| 분류 · 한 줄 제목 | Claude 가 대화에서 추정, 사용자 확정 |
| 분류별 본문 항목 | Claude 가 대화에서 요약 |
| 환경 — 설치된 terroir 플러그인 버전 · Claude Code 버전 · OS | `scripts/collect-env.sh` |
| 리포트 ID · 신고자 이메일 | `scripts/send.sh` · `git config user.email` |

분류는 넷이고 본문 항목이 다르다.

카드 제목은 `{이모지} [{분류}] {한 줄 제목}` 이고, 본문 첫 항목은 스킬 · 맵 단계이고, 라벨이 분류에 따라 갈린다 — 잘못된 것은 「발생한 위치」, 요청은 「대상」이다. 정해지지 않으면 비우며, 그때는 항목이 나타나지 않는다.

| 분류 | 본문 항목 |
|---|---|
| 🐞 에러·오동작 | 발생한 위치 · 기대한 동작 · 실제 동작 · 재현 순서 · 추정 원인 · 해결방안 |
| 💡 기능 요청 | 대상 · 요청 내용 · 현재 방식 |
| 🔑 권한 요청 | 발생한 위치 · 시도한 작업 · 막힌 화면·문구 · 추정 원인 · 요청 권한·대상 |
| 💬 기타 | 대상 · 내용 |

「기능 요청」은 없는 기능과 있는 기능의 불편을 함께 받는다. 「기타」는 앞의 셋 어디에도 넣을 수 없을 때만 쓰며, 분류 질문의 선택지에는 나타나지 않는다.

「추정 원인」과 「해결방안」의 독자는 플랫폼 개발팀이다 — 레포·경로·행 번호, 재현 조건, 바꿀 문자열까지 적는다. 확인하지 못했으면 `확인하지 못함` 이 들어간다.

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
