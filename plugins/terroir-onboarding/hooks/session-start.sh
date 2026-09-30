#!/usr/bin/env bash
# SessionStart hook — 사용자 업무 지도(work-map.md)의 위치와 목차를 세션 컨텍스트에 넣는다.
# stdout 이 그대로 컨텍스트가 되므로 칸 제목과 "언제 읽나" 줄만 넣고 값은 넣지 않는다.
# 실패해도 세션을 막지 않는다.
set -u

MAP="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/terroir/work-map.md"

# Windows(Git Bash)에서는 도구가 읽을 수 있는 경로로 바꿔 보여 준다.
SHOWN="$MAP"
if command -v cygpath >/dev/null 2>&1; then
  SHOWN="$(cygpath -w "$MAP" 2>/dev/null || echo "$MAP")"
fi

if [ ! -f "$MAP" ]; then
  cat <<'EOF'
# [terroir-onboarding] 업무 지도

이 사용자는 아직 업무 지도가 없다. 사용자가 지라 티켓·채팅 채널·동료·리포·드라이브 문서를
찾거나 쓰는 일을 요청하면, 그 일을 처리한 뒤 응답 끝에 한 줄로 한 번만 알린다 —
"`/work-map` 으로 자주 쓰는 프로젝트·채널·사람을 등록해 두면 다음부터 찾지 않고 바로 씁니다."
같은 세션에서 다시 알리지 않는다. 그런 요청이 없으면 알리지 않는다.
EOF
  exit 0
fi

echo "# [terroir-onboarding] 업무 지도"
echo
echo "이 사용자의 업무 지도: \`$SHOWN\`"
echo "아래 칸에 해당하는 일이면 검색·조회하기 전에 이 파일의 그 칸을 먼저 읽는다."
echo
awk '
  /^## / {
    title = substr($0, 4)
    getline nextline
    when = ""
    if (nextline ~ /^> 언제 읽나:/) { when = nextline; sub(/^> 언제 읽나: */, "", when) }
    if (title == "조회 대기") { pending = 1; next }
    if (when != "") print "- " title " — " when
    else print "- " title
  }
  END { if (pending) exit 3 }
' "$MAP"
PENDING=$?

cat <<'EOF'

규칙
- 지도의 값이 실제와 다르다는 것을 알게 되면 그 자리에서 고치고 사용자에게 한 줄로 알린다.
- 지도에는 어디에 무엇이 있는지(주소·ID·사람)만 둔다. 일하는 방식·판단·피드백은 지도에 쓰지 않는다.
- 사용자가 "이것도 지도에 넣어줘"라고 하면 `work-map` 스킬로 칸을 더하거나 값을 적는다.
EOF

if [ "$PENDING" -eq 3 ]; then
  cat <<'EOF'
- 지도에 "조회 대기" 칸이 있다. 지난 세션에 연결한 도구로 지도 후보를 조회할 차례다.
  이번 세션 첫 응답 끝에 한 번만 "`/work-map` 으로 방금 연결한 도구에서 후보를 찾아 지도를 채울까요?"라고 묻는다.
EOF
fi

exit 0
