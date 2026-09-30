#!/usr/bin/env bash
# SessionStart hook — 사용자 업무 지도(work-map.md)의 위치와 목차를 세션 컨텍스트에 넣는다.
# stdout 이 그대로 컨텍스트가 되므로 칸 제목과 "언제 읽나" 줄만 넣고 값은 넣지 않는다.
# 실패해도 세션을 막지 않는다.
set -u

BASE="${CLAUDE_CONFIG_DIR:-}"
if [ -z "$BASE" ]; then
  [ -n "${HOME:-}" ] || exit 0
  BASE="$HOME/.claude"
fi
MAP="$BASE/terroir/work-map.md"

# Windows(Git Bash)에서는 도구가 읽을 수 있는 경로로 바꿔 보여 준다.
SHOWN="$MAP"
if command -v cygpath >/dev/null 2>&1; then
  SHOWN="$(cygpath -w "$MAP" 2>/dev/null || echo "$MAP")"
fi

if [ ! -f "$MAP" ]; then
  cat <<'EOF'
# [terroir-onboarding] 업무 지도

이 사용자는 아직 업무 지도가 없다. 사용자가 지라 티켓·채팅 채널·동료·레포·드라이브 문서를
찾거나 쓰는 일을 요청하면, 그 일을 처리한 뒤 응답 끝에 한 줄로 알린다 —
"자주 쓰는 프로젝트·채널·동료를 업무 지도(work-map)에 등록해 두면 다음 세션부터 Claude 가 따로 찾지 않고 바로 씁니다. `/work-map` 으로 등록할 수 있습니다."
이 대화에서 이미 알렸으면 다시 알리지 않는다. 그런 요청이 없으면 알리지 않는다.
EOF
  exit 0
fi

echo "# [terroir-onboarding] 업무 지도"
echo
echo "이 사용자의 업무 지도: \`$SHOWN\`"
echo "아래 칸에 해당하는 일이면 검색·조회하기 전에 이 파일의 그 칸을 먼저 읽는다."
echo

# 칸 형식: "## 제목" 바로 다음 줄이 "> 언제 읽나: …". CRLF 파일도 읽는다.
# "## 조회 대기" 는 목차가 아니라 신호라 목차에서 빼고 종료 코드 3 으로 알린다.
awk '
  function flush() {
    if (title == "") return
    if (title == "조회 대기") pending = 1
    else if (when != "") print "- " title " — " when
    else print "- " title
    title = ""; when = ""
  }
  { sub(/\r$/, "") }
  /^## / { flush(); title = substr($0, 4); want = 1; next }
  want && /^> 언제 읽나:/ { when = $0; sub(/^> 언제 읽나: */, "", when); want = 0; next }
  { want = 0 }
  END { flush(); if (pending) exit 3 }
' "$MAP" 2>/dev/null
PENDING=$?

cat <<'EOF'

규칙
- 지도의 값이 실제와 다르다는 것을 알게 되면 `work-map` 스킬(§4)로 그 값만 고치고 사용자에게 한 줄로 알린다.
- 지도에는 어디에 무엇이 있는지(주소·ID·사람)만 둔다. 일하는 방식·판단·피드백은 지도에 쓰지 않는다.
- 사용자가 "이것도 지도에 넣어줘"라고 하면 `work-map` 스킬로 칸을 더하거나 값을 적는다.
EOF

if [ "$PENDING" -eq 3 ]; then
  cat <<'EOF'
- 지도에 "조회 대기" 칸이 있다. 지난 세션에 연결한 도구로 지도 후보를 조회할 차례다.
  이번 세션 첫 응답 끝에 "지난번에 연결한 도구에서 업무 지도(work-map)에 넣을 후보를 찾아 볼까요?"라고 묻는다.
  첫 응답이 사용자에게 묻는 질문으로 끝나면, 그 답을 처리한 다음 응답 끝에 묻는다.
  이 대화에서 이미 물었으면 다시 묻지 않는다.
  사용자가 동의하면 `work-map` 스킬로 처리하고, 거절하면 `work-map` 스킬로 "## 조회 대기" 칸만 지운다 — 다음 세션에 같은 질문을 반복하지 않기 위해서다.
EOF
fi

exit 0
