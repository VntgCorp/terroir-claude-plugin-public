# .claude 설정 파일 소유권

> Managed by gh-terroir-byor. 사내 표준 변경 시 재실행으로 갱신됩니다. 직접 수정하지 마세요.

- `.claude/rules/terroir-*.md`와 `.claude/hooks/terroir-*.sh`는 gh-terroir-byor가 관리하는 파일이다 (재실행 시 갱신 대상). 수정하지 않는다.
- `.claude/settings.json`은 사용자 파일이다 (자유롭게 확장 가능). 단, terroir SessionStart hook entry는 도구가 보장한다 — 지워도 다음 재실행에서 재등록된다.
- 개인 커스텀 설정은 `.claude/settings.local.json`에 작성한다 (git 미추적).
- 프로젝트 자체 규칙은 `CLAUDE.md` 또는 `.claude/rules/`의 별도 파일(`terroir-` prefix 없이)에 작성한다.
