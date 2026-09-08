# terroir-feedback 변경 이력

실제 배포 버전은 [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json)을 따른다.

## 1.0.0 - 2026-09-02

최초 배포.

### 추가

- `/feedback` — 에러·오동작, 기능 요청, 권한 요청, 기타 피드백을 Claude Code에서 플랫폼 개발팀 채널로 전송한다.
- 전송 전에 전체 내용을 미리 보여주고 사용자 승인을 받는다.
- 설치된 Terroir 플러그인 버전, Claude Code 버전, OS 정보를 자동으로 수집한다.
- 세션당 한 번 자동으로 피드백 전송을 제안하고, 사용자가 거절하면 다시 묻지 않는다.
- 전송에 실패한 리포트를 `~/.terroir/feedback-outbox/`에 저장한다.
