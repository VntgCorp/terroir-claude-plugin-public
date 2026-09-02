#!/usr/bin/env bash
# 환경 한 줄 수집 — 마켓플레이스별 terroir 플러그인 커밋·개수, Claude Code 버전, OS.
# 출력 예: private 8b8a07e (8) · public 20523f7 (2) · Claude Code 2.1.250 · macOS (arm64)
set -u
INSTALLED="${HOME}/.claude/plugins/installed_plugins.json"

plugins=""
if [ -f "$INSTALLED" ] && command -v python3 >/dev/null 2>&1; then
  plugins=$(python3 - "$INSTALLED" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1], encoding="utf-8")).get("plugins", {})
except Exception:
    sys.exit(0)
groups = {}
for key, entries in data.items():
    if "@terroir-claude-plugin" not in key:
        continue
    market = key.split("@", 1)[1]
    scope = "public" if market.endswith("-public") else "private"
    ver = ""
    for e in entries or []:
        ver = (e.get("gitCommitSha") or e.get("version") or "")[:7]
        if ver:
            break
    g = groups.setdefault(scope, {"vers": set(), "n": 0})
    g["n"] += 1
    if ver:
        g["vers"].add(ver)
out = []
for scope in ("private", "public"):
    if scope in groups:
        g = groups[scope]
        out.append(f"{scope} {'/'.join(sorted(g['vers'])) or '?'} ({g['n']})")
print(" · ".join(out))
PY
)
fi
[ -z "$plugins" ] && plugins="terroir 플러그인 없음"

cc=$(claude --version 2>/dev/null | awk '{print $1}')
[ -z "$cc" ] && cc="?"

case "$(uname -s 2>/dev/null)" in
  Darwin) os="macOS" ;;
  Linux)  grep -qi microsoft /proc/version 2>/dev/null && os="WSL" || os="Linux" ;;
  MINGW*|MSYS*|CYGWIN*) os="Windows" ;;
  *) os="$(uname -s 2>/dev/null)" ;;
esac
arch=$(uname -m 2>/dev/null)

echo "${plugins} · Claude Code ${cc} · ${os} (${arch})"
