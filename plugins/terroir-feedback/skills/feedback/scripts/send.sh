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
command -v python3 >/dev/null 2>&1 || { echo "python3 가 필요합니다" >&2; exit 2; }

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
CONFIG="$ROOT/skills/feedback/config.json"
OUTBOX="${HOME}/.terroir/feedback-outbox"

stamp=$(date +%Y%m%d-%H%M)
if command -v md5sum >/dev/null 2>&1; then hash=$(md5sum "$FILE" | cut -c1-4)
elif command -v md5 >/dev/null 2>&1; then hash=$(md5 -q "$FILE" | cut -c1-4)
else hash=$(printf '%04x' $RANDOM); fi
ID="${stamp}-${hash}"

read -r url fallback < <(python3 - "$CONFIG" <<'PY'
import json,sys
c=json.load(open(sys.argv[1],encoding="utf-8"))
print(c.get("webhook_url",""), c.get("fallback_channel_url","-"))
PY
)

payload=$(python3 - "$FILE" "$ID" <<'PY'
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8")); ID = sys.argv[2]
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
card = {"cardsV2": [{"cardId": ID, "card": {
    "header": {"title": title},
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
