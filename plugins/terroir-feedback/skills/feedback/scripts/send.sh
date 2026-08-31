#!/usr/bin/env bash
# 리포트 전송 — 사용법: send.sh <report.json>
# report.json 을 Google Chat 카드(cardsV2)로 만들어 config.json 의 webhook_url 로 POST 한다.
# 성공: "OK <ID>". 실패: outbox 에 저장하고 "FAIL <ID> <경로>" 출력, exit 1.
#
# report.json 필드
#   category  error | missing | request
#   title     증상 한 줄 (분류·스킬 없이)
#   skill     관련 스킬 또는 플러그인 (없으면 "")
#   stage     맵 단계 (예 "5 DEPLOYMENT", 없으면 "")
#   expected / actual / repro[]        ← error · missing
#   want / now / why                   ← request
#   reporter  이메일
#   env       collect-env.sh 출력 한 줄
set -u
FILE="${1:-}"
[ -z "$FILE" ] || [ ! -f "$FILE" ] && { echo "usage: send.sh <report.json>" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "python3 가 필요합니다" >&2; exit 2; }

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
CONFIG="$ROOT/skills/feedback/config.json"
OUTBOX="${HOME}/.terroir/feedback-outbox"

stamp=$(date +%Y%m%d-%H%M)
if command -v md5sum >/dev/null 2>&1; then hash=$(md5sum "$FILE" | cut -c1-4)
elif command -v md5 >/dev/null 2>&1; then hash=$(md5 -q "$FILE" | cut -c1-4)
else hash=$(printf '%04x' $RANDOM); fi
ID="${stamp}-${hash}"

read -r url fallback jira < <(python3 - "$CONFIG" <<'PY'
import json,sys
c=json.load(open(sys.argv[1],encoding="utf-8"))
print(c.get("webhook_url",""), c.get("fallback_channel_url","-"), c.get("jira_create_url","-"))
PY
)

payload=$(python3 - "$FILE" "$ID" "$jira" <<'PY'
import json, sys, urllib.parse
r = json.load(open(sys.argv[1], encoding="utf-8")); ID = sys.argv[2]; jira = sys.argv[3]
cat = r.get("category", "error")
META = {"error": ("🐞", "에러"), "missing": ("🚫", "없는 기능"), "request": ("💡", "기능 요청")}
emoji, label = META.get(cat, META["error"])
sub = " · ".join(x for x in [label, r.get("skill", ""), r.get("stage", "")] if x)

def dt(top, text):
    return {"decoratedText": {"topLabel": top, "text": str(text).strip() or "-", "wrapText": True}}

body = []
if cat == "request":
    body += [dt("원하는 것", r.get("want", "")), dt("지금은", r.get("now", "")), dt("왜 필요한가", r.get("why", ""))]
else:
    body += [dt("기대", r.get("expected", "")), dt("실제", r.get("actual", ""))]
    repro = r.get("repro") or []
    if isinstance(repro, list):
        repro = "\n".join(f"{i+1}. {s}" for i, s in enumerate(repro))
    body.append(dt("재현", repro))

env = r.get("env", "")
info = [dt("신고", r.get("reporter", "")), dt("ID", ID), dt("환경", env)]

sections = [
    {"widgets": body},
    {"header": "환경 · 신고 정보", "collapsible": True, "uncollapsibleWidgetsCount": 0, "widgets": info},
]
if jira and jira != "-":
    # incoming webhook 카드의 버튼은 클릭이 봇 요청으로 처리돼 오류가 난다 — 링크 텍스트로 넣는다
    summary = f"[{label}] {r.get('skill','')}: {r.get('title','')}".strip()
    link = jira + ("&" if "?" in jira else "?") + "summary=" + urllib.parse.quote(summary)
    sections.append({"widgets": [{"textParagraph": {"text": f'<a href="{link}">Jira 티켓 만들기</a>'}}]})

card = {"cardsV2": [{"cardId": ID, "card": {
    "header": {"title": f"{emoji} {r.get('title','(제목 없음)')}", "subtitle": sub},
    "sections": sections}}]}
print(json.dumps(card, ensure_ascii=False))
PY
) || { echo "report.json 파싱 실패" >&2; exit 2; }

save_outbox() {
  mkdir -p "$OUTBOX"
  cp "$FILE" "$OUTBOX/${ID}.json"
  echo "FAIL ${ID} ${OUTBOX}/${ID}.json"
  [ "$fallback" != "-" ] && echo "채널에 직접 붙여 넣기: ${fallback}"
  exit 1
}

case "$url" in
  ""|REPLACE_WITH*) echo "webhook_url 이 설정되지 않았습니다: $CONFIG" >&2; save_outbox ;;
esac

http=$(curl -sS -o /dev/null -w '%{http_code}' -X POST \
  -H 'Content-Type: application/json; charset=UTF-8' \
  --data "$payload" "$url" 2>/dev/null)

case "$http" in
  2??) echo "OK ${ID}"; exit 0 ;;
  *)   echo "HTTP ${http:-없음}" >&2; save_outbox ;;
esac
