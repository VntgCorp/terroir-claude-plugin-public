#!/usr/bin/env bash
# 리포트 전송 — 사용법: send.sh <report.json>
# report.json 을 Google Chat 카드(cardsV2)로 만들어 config.json 의 webhook_url 로 POST 한다.
# 성공: "OK <ID>". 실패: outbox 에 저장하고 "FAIL <ID> <경로>" 출력, exit 1.
#
# report.json 필드
#   category  error | feature_request | access_request | other
#   title     증상 한 줄 (분류·스킬 없이)
#   skill     관련 스킬 또는 플러그인 (없으면 "")
#   stage     맵 단계 (예 "5 DEPLOYMENT", 없으면 "")
#   expected / actual / repro[] / cause / fix   ← error
#   want / now                                  ← feature_request
#   tried / blocked / cause / need              ← access_request
#   content                                     ← other
#   reporter  이메일
#   env       collect-env.sh 출력 한 줄
set -u
FILE="${1:-}"
[ -z "$FILE" ] || [ ! -f "$FILE" ] && { echo "usage: send.sh <report.json>" >&2; exit 2; }
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
CONFIG="$ROOT/skills/feedback/config.json"
OUTBOX="${HOME}/.terroir/feedback-outbox"

stamp=$(date +%Y%m%d-%H%M)
if command -v md5sum >/dev/null 2>&1; then hash=$(md5sum "$FILE" | cut -c1-4)
elif command -v md5 >/dev/null 2>&1; then hash=$(md5 -q "$FILE" | cut -c1-4)
else hash=$(printf '%04x' $RANDOM); fi
ID="${stamp}-${hash}"

save_outbox() {
  mkdir -p "$OUTBOX"
  cp "$FILE" "$OUTBOX/${ID}.json"
  echo "FAIL ${ID} ${OUTBOX}/${ID}.json"
  [ "$fallback" != "-" ] && echo "채널에 직접 붙여 넣기: ${fallback}"
  exit 1
}

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
if [ -z "$PYBIN" ]; then
  # 여기서 그냥 끝내면 사용자가 쓴 리포트가 사라진다. outbox 에 남기고 대체 채널을 알린다.
  # config 를 읽을 python 이 없으므로 대체 채널만 sed 로 꺼낸다.
  echo "Python 3 이 필요합니다 — 실행 가능한 python 을 찾지 못했습니다" >&2
  fallback=$(sed -n 's/.*"fallback_channel_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG" 2>/dev/null | head -1)
  [ -z "$fallback" ] && fallback="-"
  save_outbox
fi

url=""; fallback="-"
read -r url fallback < <("$PYBIN" - "$CONFIG" <<'PY'
import json,sys
c=json.load(open(sys.argv[1],encoding="utf-8"))
print(c.get("webhook_url",""), c.get("fallback_channel_url","-"))
PY
)

payload=$("$PYBIN" - "$FILE" "$ID" <<'PY'
import json, os, sys
from datetime import date
from urllib.parse import urlencode, quote_plus
r = json.load(open(sys.argv[1], encoding="utf-8")); ID = sys.argv[2]
# 접수 버튼이 가리키는 곳 — 바뀌면 여기만 고친다
JIRA = "https://vntg.atlassian.net/secure/CreateIssueDetails!init.jspa"
PID, BUG = "11569", "12681"          # RDDP · 버그(분류와 무관하게 고정)
ROOM = "AAQA3-NtKqg"                 # 피드백 채널 — 티켓에서 원문을 찾아가는 입구
cat = r.get("category", "error")
META = {
    "error":           ("🐞", "에러·오동작"),
    "feature_request": ("💡", "기능 요청"),
    "access_request":  ("🔑", "권한 요청"),
    "other":           ("💬", "기타"),
}
emoji, label = META.get(cat, META["error"])
# 분류는 제목에 대괄호로 넣는다 — 알림·검색에는 제목만 보인다
title = f"{emoji} [{label}] " + (r.get("title") or "(제목 없음)")
loc = " · ".join(x for x in [r.get("skill", ""), r.get("stage", "")] if x)

def dt(top, text):
    return {"decoratedText": {"topLabel": top, "text": str(text).strip() or "-", "wrapText": True}}

body = []
if loc:
    # 잘못된 것은 "발생한 위치", 요청은 "대상" — 기능 요청에 발생한 것은 없다
    body.append(dt("발생한 위치" if cat in ("error", "access_request") else "대상", loc))
if cat == "feature_request":
    body += [dt("요청 내용", r.get("want", "")), dt("현재 방식", r.get("now", ""))]
elif cat == "access_request":
    # 추정 원인 — 어느 계층 권한이 빠졌는지. 조치가 초대/팀추가/역할승격으로 갈린다
    body += [dt("시도한 작업", r.get("tried", "")), dt("막힌 화면·문구", r.get("blocked", "")),
             dt("추정 원인", r.get("cause", "")), dt("요청 권한·대상", r.get("need", ""))]
elif cat == "other":
    body += [dt("내용", r.get("content", ""))]
else:
    body += [dt("기대한 동작", r.get("expected", "")), dt("실제 동작", r.get("actual", ""))]
    repro = r.get("repro") or []
    if isinstance(repro, list):
        repro = "\n".join(f"{i+1}. {s}" for i, s in enumerate(repro))
    body.append(dt("재현 순서", repro))
    # 플랫폼 개발팀이 참조하는 항목 — 모르면 "확인하지 못함" 이 들어온다
    body += [dt("추정 원인", r.get("cause", "")), dt("해결방안", r.get("fix", ""))]

env = r.get("env", "")
info = [dt("신고", r.get("reporter", "")), dt("ID", ID), dt("환경", env)]

sections = [
    {"widgets": body},
    {"header": "환경 · 신고 정보", "collapsible": True, "uncollapsibleWidgetsCount": 0, "widgets": info},
]

# ── 접수 버튼 ──────────────────────────────────────────────────────────────
# 누르면 **누른 사람 계정으로** Jira 생성 화면이 열린다. 봇 계정도 토큰도 쓰지 않는다.
#
# ★URL 길이가 전부다. Chat 은 링크가 길면 **카드를 통째로 빈 칸으로** 만든다 —
#   오류도 안 내고 API 는 200 을 준다. 그래서 넘겼다는 것을 보내는 쪽에서 알 수 없다.
#
# ★한글은 URL 인코딩에서 1자당 9바이트(%EA%B0%80)라 전문은 애초에 안 들어간다.
#   그래서 본문을 **앞에서부터 예산까지 자르고** 전문은 채널에 남긴다. 칸 단위로
#   나누지 않는다 — 글자당 비용이 칸마다 4배까지 차이 나서(영문 1.2 ~ 한글 5.3)
#   어느 칸이 살아남을지 내용에 따라 달라진다. 자르는 자리만 정하는 편이 예측 가능하다.
#
# ★칸 순서는 ORDER 로 고정한다. 잘릴 때 무엇이 남을지를 이것이 정한다 — 알맹이 먼저.
INTAKE = os.environ.get("TERROIR_INTAKE", "").strip()
ORDER = {
    "error":           ["실제 동작", "해결방안", "추정 원인", "기대한 동작", "재현 순서", "발생한 위치"],
    "feature_request": ["요청 내용", "현재 방식", "대상"],
    "access_request":  ["막힌 화면·문구", "요청 권한·대상", "추정 원인", "시도한 작업", "발생한 위치"],
    "other":           ["내용", "대상"],
}
if INTAKE:
    # ★900 은 **실측으로 확인된 안전값**이다. 추정식을 쓰지 않는다 —
    #   실제 리포트 카드에서 945 는 떴고 1,400 은 **카드가 통째로 빈 칸**이 됐다.
    #   한계가 정확히 어디인지는 아직 모른다(작은 카드로 재면 1,714 도 통과해서,
    #   길이만으로 설명되지 않는다). 모르는 선에 가까이 가지 않는다 —
    #   넘기면 오류도 없이 카드가 사라지고, 그러면 접수가 조용히 누락된다.
    BUDGET = 900
    flat = {}
    for w in body:
        dtx = w["decoratedText"]
        flat[dtx["topLabel"]] = dtx["text"]
    text = "\n\n".join(f"[{k}]\n{flat[k]}" for k in ORDER.get(cat, []) if k in flat)
    # ★[ID] 는 지우지 않는다 — 티켓에서 원본 Chat 메시지를 되찾는 유일한 열쇠이고,
    #   중복을 찾을 때도 이것으로 건다. 분류는 적지 않는다 — 이슈 타입과 본문으로 드러난다.
    foot = (f"\n\n[신고] {r.get('reporter','')}\n[ID] {ID}"
            f"\n[원문] https://chat.google.com/room/{ROOM}  — 이 채널에서 위 ID 로 검색")

    def mk(n):
        d = text if n >= len(text) else text[:n].rstrip() + " …"
        return JIRA + "?" + urlencode(
            {"pid": PID, "issuetype": BUG, "summary": r.get("title") or "(제목 없음)",
             "description": d + foot, "labels": "auto-intake",
             "customfield_10015": date.today().isoformat()}, doseq=True)

    lo, hi, best = 0, len(text), 0
    while lo <= hi:                       # 예산에 들어가는 가장 긴 본문을 찾는다
        mid = (lo + hi) // 2
        if len(mk(mid)) <= BUDGET: best, lo = mid, mid + 1
        else: hi = mid - 1
    sections.append({"widgets": [{"buttonList": {"buttons": [
        {"text": "🎫 Jira 에 등록", "onClick": {"openLink": {"url": mk(best)}}}]}}]})
card = {"cardsV2": [{"cardId": ID, "card": {
    "header": {"title": title},
    "sections": sections}}]}
# stdout 텍스트 계층은 로케일 코드페이지를 쓴다(한국어 Windows = cp949).
# 카드 본문을 UTF-8 바이트로 직접 써서 그 계층을 건너뛴다.
sys.stdout.buffer.write(json.dumps(card, ensure_ascii=False).encode("utf-8"))
PY
) || { echo "카드 생성 실패 — report.json 형식을 확인하세요" >&2; exit 2; }


case "$url" in
  ""|REPLACE_WITH*) echo "webhook_url 이 설정되지 않았습니다: $CONFIG" >&2; save_outbox ;;
esac

# payload 는 argv 가 아니라 파일로 넘긴다 — MSYS 의 argv 변환과 ARG_MAX 를 피한다
body="${TMPDIR:-/tmp}/terroir-feedback-${ID}.body.json"
printf '%s' "$payload" > "$body"
http=$(curl -sS -o /dev/null -w '%{http_code}' -X POST \
  -H 'Content-Type: application/json; charset=UTF-8' \
  --data-binary "@${body}" "$url" 2>/dev/null)
rm -f "$body"

case "$http" in
  2??) echo "OK ${ID}"; exit 0 ;;
  *)   echo "HTTP ${http:-없음}" >&2; save_outbox ;;
esac
