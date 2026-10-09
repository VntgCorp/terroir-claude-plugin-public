# 떼루아 레슨 목차

원본은 podo `content/lessons` 다. `scripts/sync-lessons.py` 로 다시 만든다 — 직접 고치지 않는다.

- [Terroir가 대신 해주는 일](terroir-overview.md) — Terroir는 VNTG의 소프트웨어 개발 플랫폼입니다.
- [프로젝트를 만들어 첫 배포까지](getting-started.md) — 떼루아에서 새 프로젝트를 만들어 개발 환경에 배포하기까지를 다룹니다.
- [떼루아에게 질문하기](ask-terroir.md) — 플러그인을 깔고 나면 명령어를 외울 필요가 없습니다.
- [Terroir 안에서의 보안에 대하여](terroir-security.md) — Terroir는 저장소를 만드는 순간부터 요청을 받는 순간까지 여러 단계에서 검사합니다.
- [Sealed Secrets — 비밀값을 git에 안전하게 두는 법](sealed-secrets.md) — Terroir에 올린 앱의 DB 비밀번호와 API 키는 git 저장소에 암호화된 상태로만 기록됩니다.
- [LGTM — 배포한 앱을 계속 지켜보는 법](lgtm.md) — Terroir에 올린 앱은 배포되는 순간부터 로그와 메트릭이 자동으로 쌓이고, 모든 데이터는 모니터링 전용 화면인 Grafana에서 봅니다.
- [AI Gateway — 모든 AI 호출을 한곳으로 모으는 법](ai-gateway.md) — Terroir 안에서 AI 모델을 호출하는 요청은 모두 AI 게이트웨이 한 곳을 지납니다.
- [alert-bot · code-review-agent — 1차 확인을 맡은 두 AI 봇](alert-bot-code-review.md) — Terroir에서는 알림이 오면 alert-bot이 원인과 조치를 답글로 달고, PR이 열리면 code-review-agent가 사내 규칙으로 판정을 남깁니다.
- [GitHub 처음 쓰기](github-basics.md) — Terroir로 만든 프로젝트의 파일은 GitHub라는 서비스에 보관됩니다.
