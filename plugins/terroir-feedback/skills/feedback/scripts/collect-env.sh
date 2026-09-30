#!/usr/bin/env bash
# 환경 한 줄 수집 — 마켓플레이스별 terroir 플러그인 커밋·개수, Claude Code 버전, OS.
# 출력 예: private 8b8a07e (8) · public 20523f7 (2) · Claude Code 2.1.250 · macOS (arm64)
set -u
INSTALLED="${HOME}/.claude/plugins/installed_plugins.json"

# python 실행 검증 — 존재 확인이 아니라 실행으로 판정한다. Windows 의 WindowsApps
# python3.exe 스텁은 command -v 를 통과하지만 실행하면 Microsoft Store 만 열고 끝난다.
# Windows 에서 py 런처를 먼저 보는 것도 그 스텁을 건드리지 않고 지나가기 위해서다.
case "$(uname -s 2>/dev/null)" in
  MINGW*|MSYS*|CYGWIN*) PYCANDS="py python python3" ;;
  *)                    PYCANDS="python3 python" ;;
esac
PYBIN=""
for c in $PYCANDS; do
  "$c" -c 'import sys; sys.exit(0 if sys.version_info[0] >= 3 else 1)' >/dev/null 2>&1 && { PYBIN="$c"; break; }
done

plugins=""
if [ -f "$INSTALLED" ] && [ -n "$PYBIN" ]; then
  plugins=$("$PYBIN" - "$INSTALLED" <<'PY'
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
# 구분자 · 가 로케일 인코딩으로 나가지 않도록 UTF-8 바이트로 직접 쓴다
sys.stdout.buffer.write((" · ".join(out) + "\n").encode("utf-8"))
PY
)
fi
[ -z "$plugins" ] && [ -n "$PYBIN" ] && plugins="terroir 플러그인 없음"
[ -z "$plugins" ] && plugins="플러그인 정보 확인 못함 (Python 3 없음)"

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
