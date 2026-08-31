#!/usr/bin/env bash
# SessionStart hook — 자동 제안 규칙(triggers.md)을 세션 컨텍스트에 주입한다.
# stdout 이 그대로 컨텍스트가 되므로 짧게 유지한다. 실패해도 세션을 막지 않는다.
set -u
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
FILE="$ROOT/skills/feedback/triggers.md"
[ -f "$FILE" ] && cat "$FILE"
exit 0
