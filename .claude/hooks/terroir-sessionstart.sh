#!/usr/bin/env bash
# Managed by gh-terroir-byor. 사내 표준 변경 시 재실행으로 갱신됩니다. 직접 수정하지 마세요.
#
# SessionStart hook — 사내 표준 가이드 인덱스를 세션 컨텍스트로 주입한다.
#   terroir/docs/index.md — 사내 표준 가이드 라우팅 (링크만으로는 세션 시작 시점에
#     라우팅 테이블이 컨텍스트에 없어 AI가 Read해주길 기대해야 함 → 직접 주입해 확정)
# 사용자 프로젝트 문서(docs/)는 주입하지 않는다 — 사내 표준만 세션에 올린다.
# 없는 것은 오류가 아니다 (전사 ADR-036): 아무것도 출력하지 않고 정상 종료한다.
[ -f "$CLAUDE_PROJECT_DIR/terroir/docs/index.md" ] && cat "$CLAUDE_PROJECT_DIR/terroir/docs/index.md"
exit 0
