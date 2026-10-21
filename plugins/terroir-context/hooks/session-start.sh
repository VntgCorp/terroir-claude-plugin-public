#!/usr/bin/env bash
# SessionStart hook — 전 직원 공통 컨텍스트의 목차(docs/index.md)를 세션에 올린다.
# stdout 이 그대로 컨텍스트가 된다. 실패해도 세션을 막지 않는다.
#
# 메인 세션에만 건다(SubagentStart 없음). 서브에이전트는 필요할 때 경로로 직접 읽는다.
set -u
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
DOCS="${ROOT%/}/docs"

# 링크가 달린 목차 항목이 하나도 없으면 빈 머리말만 올라가므로 아무것도 하지 않는다.
grep -qE '^[[:space:]]*[-*] \[' "$DOCS/index.md" 2>/dev/null || exit 0

# Windows(Git Bash)에서는 도구가 읽을 수 있는 경로로 바꿔 보여 준다.
SHOWN="$DOCS"
if command -v cygpath >/dev/null 2>&1; then
  SHOWN="$(cygpath -w "$DOCS" 2>/dev/null || echo "$DOCS")"
fi

printf '# 전 직원 공통 컨텍스트 (terroir-context)\n\n'
printf '**원본은 `%s` 아래에 있다.** 전문이 필요하면 이 절대경로로 읽는다.\n' "$SHOWN"
printf '질문이 아래 목차의 주제에 해당하면 답하기 전에 그 문서를 먼저 읽는다.\n\n'
printf -- '---\n\n'
cat "$DOCS/index.md"
exit 0
