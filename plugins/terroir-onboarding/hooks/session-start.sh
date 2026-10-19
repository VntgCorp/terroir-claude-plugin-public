#!/usr/bin/env bash
# SessionStart hook — 사용자 업무 지도(work-map.md)의 위치와 목차, 떼루아 레슨 목차를 세션 컨텍스트에 넣는다.
# stdout 이 그대로 컨텍스트가 되므로 칸 제목과 "언제 읽나" 줄만 넣고 값은 넣지 않는다.
# 지난 세션에 새로 연결한 도구가 있으면(env-setup 이 남긴 표시 파일) 후보 찾기를 한 번 제안하게 한다.
# 실패해도 세션을 막지 않는다.
set -u

BASE="${CLAUDE_CONFIG_DIR:-}"
if [ -z "$BASE" ]; then
  [ -n "${HOME:-}" ] || exit 0
  BASE="$HOME/.claude"
fi
MAP="$BASE/terroir/work-map.md"
PENDING="$BASE/terroir/lookup-pending.md"

# Windows(Git Bash)에서는 도구가 읽을 수 있는 경로로 바꿔 보여 준다.
SHOWN="$MAP"
if command -v cygpath >/dev/null 2>&1; then
  SHOWN="$(cygpath -w "$MAP" 2>/dev/null || echo "$MAP")"
fi

echo "# [terroir-onboarding] 업무 지도"
echo

if [ -f "$MAP" ]; then
  echo "이 사용자의 업무 지도: \`$SHOWN\`"
  echo "아래 칸에 해당하는 일이면 검색·조회하기 전에 이 파일의 그 칸을 먼저 읽는다."
  echo
  # 칸 형식: "## 제목" 바로 다음 줄이 "> 언제 읽나: …". CRLF 파일도 읽는다.
  awk '
    function flush() {
      if (title == "") return
      if (when != "") print "- " title " — " when
      else print "- " title
      title = ""; when = ""
    }
    { sub(/\r$/, "") }
    /^## / { flush(); title = substr($0, 4); want = 1; next }
    want && /^> 언제 읽나:/ { when = $0; sub(/^> 언제 읽나: */, "", when); want = 0; next }
    { want = 0 }
    END { flush() }
  ' "$MAP" 2>/dev/null
  cat <<'EOF'

규칙
- 지도의 값이 실제와 다르다는 것을 알게 되면 `work-map` 스킬로 그 값만 고치고 사용자에게 한 줄로 알린다.
- 사용자가 일하다 지도에 없는 자주 쓰는 곳(채널 주소, 동료 호칭, 레포 등)을 알려 주면, 그 일을 마친 뒤 응답 끝에 "업무 지도에 저장해 둘까요?"를 한 번 묻고, 동의하면 `work-map` 스킬로 저장한다. 같은 대상은 이 대화에서 다시 묻지 않는다.
- 지도에는 어디에 무엇이 있는지(주소·ID·사람)만 둔다. 일하는 방식·판단·피드백은 지도에 쓰지 않는다.
EOF
else
  cat <<'EOF'
이 사용자는 아직 업무 지도가 없다. 업무 지도는 자주 쓰는 자리(지라 프로젝트·컨플루언스 스페이스·드라이브 폴더·
GitHub 레포·채팅방)와 사람의 주소와 ID 를 모아 두는 파일이다.

언제 알리나 — 아래를 모두 만족하는 응답에서만, 그 응답 끝에 한 줄로 알린다.
- 이번 요청을 처리하며 특정한 대상을 실제로 썼다. 대상은 사람(메일·채팅 상대)·채팅 채널·레포·문서·지라 티켓·드라이브 파일이고, 쓴다는 것은 읽기·보내기·조회·작성이다. 사용자가 알려 준 대상도, 찾아낸 대상도 포함한다. 여럿일 수 있다.
- 이 대화에서 아직 알리지 않았다.

알리지 않는 경우
- 지라·깃·채널 같은 낱말이 대화에 나오기만 했고, 특정한 대상을 쓰지 않았다.
- 대상의 주소나 ID 를 사용자가 따로 쓰는 지도·메모 파일에서 읽었거나 그 파일에 적었다. 이 사용자는 이미 자기 지도를 쓰고 있다.
- 이번 응답이 대상을 쓴 일과 다른 주제를 다룬다. 알릴 자리는 대상을 쓴 그 응답뿐이다.
- 이번 응답이 사용자에게 답을 요구하며 끝난다. 질문 앞뒤에 안내를 붙이지 않는다.

어떻게 알리나 — 고정 문장을 쓰지 않는다. 이번에 쓴 대상이 속한 자리나 사람을 이름으로 짚는다. 여럿이면 모두 짚는다.
- 개별 티켓·문서·파일·스레드는 짚지 않는다. 티켓 `ABC-123` 이면 지라 `ABC` 프로젝트, 컨플루언스 페이지면 그 스페이스, 드라이브 파일이면 그 폴더, 스레드면 그 채팅방을 짚는다.
- 예: "방금 쓴 지라 `ABC` 프로젝트와 `<채팅방 이름>` 채팅방을 업무 지도(work-map)에 저장해 두면 다음 세션부터 찾지 않고 바로 씁니다. "업무 정보 등록해줘"라고 말씀하시면 저장합니다."
EOF
fi

if [ -f "$PENDING" ]; then
  cat <<'EOF'

지난 세션에 새로 연결한 업무 도구가 있다(`env-setup` 이 남긴 표시 파일 `terroir/lookup-pending.md`).
- 이번 세션 첫 응답 끝에 "지난번에 연결한 도구에서 업무 지도(work-map)에 넣을 후보를 찾아 볼까요?"라고 한 번 묻는다. 첫 응답이 사용자에게 묻는 질문으로 끝나면, 그 답을 처리한 다음 응답 끝에 묻는다. 이 대화에서 이미 물었으면 다시 묻지 않는다.
- 동의하면 `env-setup` 스킬의 §3-1 만 실행한다. 거절하면 표시 파일을 지운다 — 다음 세션에 같은 질문을 반복하지 않기 위해서다.
EOF
fi

# 떼루아 레슨 — 목차와 원본 경로만 넣고 본문은 질문이 오면 읽게 한다.
LESSONS="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}/lessons"
if [ -f "$LESSONS/index.md" ]; then
  SHOWN="$LESSONS"
  if command -v cygpath >/dev/null 2>&1; then
    SHOWN="$(cygpath -w "$LESSONS" 2>/dev/null || echo "$LESSONS")"
  fi
  echo
  echo "# [terroir-onboarding] 떼루아 레슨"
  echo
  echo "레슨 원본: \`$SHOWN\`"
  echo "떼루아(Terroir)나 그 구성 요소가 무엇이고 무엇을 해 주는지 물으면 \`terroir-onboarding:lessons\` 스킬로 답한다. 무엇부터 할지 · 시작 방법은 떼루아 시작 안내 스킬이 있으면 그쪽이 받는다."
  echo "스킬이 아래 목차에서 레슨을 골라 본문을 읽고 출처를 밝힌다. 레슨에 없는 내용은 지어내지 않는다."
  echo
  grep '^- ' "$LESSONS/index.md"
fi

exit 0
