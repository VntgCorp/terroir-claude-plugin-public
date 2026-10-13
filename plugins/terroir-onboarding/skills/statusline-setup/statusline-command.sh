#!/usr/bin/env bash
# Claude Code status line — Artistic edition with emoji & color
input=$(cat)

# ── Extract fields from JSON ──────────────────────────────────────────────────
cwd=$(echo "$input"         | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input"       | jq -r '.model.display_name // empty')
used_pct=$(echo "$input"    | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input"    | jq -r '.context_window.context_window_size // empty')
ctx_input=$(echo "$input"   | jq -r '.context_window.current_usage.input_tokens // empty')
five_pct=$(echo "$input"    | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input"    | jq -r '.rate_limits.seven_day.used_percentage // empty')
transcript=$(echo "$input"  | jq -r '.transcript_path // empty')

# ── ANSI palette ──────────────────────────────────────────────────────────────
reset=$'\033[0m'
bold=$'\033[1m'
dim=$'\033[2m'
# Foreground colours
fg_white=$'\033[97m'
fg_cyan=$'\033[96m'
fg_green=$'\033[92m'
fg_yellow=$'\033[93m'
fg_magenta=$'\033[95m'
fg_blue=$'\033[94m'
fg_red=$'\033[91m'
fg_orange=$'\033[38;5;208m'
fg_purple=$'\033[38;5;141m'
fg_pink=$'\033[38;5;213m'
fg_sky=$'\033[38;5;117m'
fg_gold=$'\033[38;5;220m'
fg_teal=$'\033[38;5;43m'

# ── Directory (basename) ──────────────────────────────────────────────────────
dir_name=$(basename "$cwd")

# ── Git branch + dirty flag ───────────────────────────────────────────────────
git_part=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    if git -C "$cwd" status --porcelain 2>/dev/null | grep -q .; then
      dirty="${fg_yellow} ✏️ ${reset}"
    else
      dirty="${fg_green} ✓${reset}"
    fi
    git_part=" ${dim}│${reset} ${fg_purple}🌿 ${bold}${branch}${reset}${dirty}"
  fi
fi

# ── Model ─────────────────────────────────────────────────────────────────────
model_part=""
if [ -n "$model" ]; then
  model_part="${fg_sky}🤖 ${bold}${model}${reset}"
fi

# ── Context usage bar + token counts ─────────────────────────────────────────
ctx_part=""
if [ -n "$used_pct" ]; then
  ctx_used=$(printf "%.0f" "$used_pct")
  # Pick colour by usage level
  if   [ "$ctx_used" -ge 80 ]; then bar_color="${fg_red}";    bar_emoji="🔴"
  elif [ "$ctx_used" -ge 50 ]; then bar_color="${fg_orange}"; bar_emoji="🟠"
  elif [ "$ctx_used" -ge 25 ]; then bar_color="${fg_yellow}"; bar_emoji="🟡"
  else                               bar_color="${fg_green}";  bar_emoji="🟢"
  fi
  # Mini progress bar (10 chars)
  filled=$(( ctx_used / 10 ))
  bar=""
  for i in $(seq 1 10); do
    if [ "$i" -le "$filled" ]; then bar="${bar}█"; else bar="${bar}░"; fi
  done
  # Token counts: current input / total context window
  token_info=""
  if [ -n "$ctx_input" ] && [ -n "$ctx_size" ]; then
    # Format with K suffix for readability
    cur_k=$(awk "BEGIN {printf \"%.1f\", $ctx_input/1000}")
    max_k=$(awk "BEGIN {printf \"%.0f\", $ctx_size/1000}")
    token_info=" ${dim}(${cur_k}k / ${max_k}k tokens)${reset}"
  fi
  ctx_part="${bar_emoji} ${bar_color}${bold}${ctx_used}%${reset} ${dim}${bar}${reset}${token_info}"
fi

# ── Rate limits (5h session / 7d weekly) ─────────────────────────────────────
rate_part=""
if [ -n "$five_pct" ] || [ -n "$week_pct" ]; then
  rate_segments=()
  if [ -n "$five_pct" ]; then
    five_used=$(printf "%.0f" "$five_pct")
    five_rem=$(( 100 - five_used ))
    if   [ "$five_used" -ge 80 ]; then five_color="${fg_red}"
    elif [ "$five_used" -ge 50 ]; then five_color="${fg_orange}"
    else                               five_color="${fg_green}"
    fi
    rate_segments+=("${fg_sky}5h${reset} ${five_color}${bold}${five_rem}%${reset}${dim} left${reset}")
  fi
  if [ -n "$week_pct" ]; then
    week_used=$(printf "%.0f" "$week_pct")
    week_rem=$(( 100 - week_used ))
    if   [ "$week_used" -ge 80 ]; then week_color="${fg_red}"
    elif [ "$week_used" -ge 50 ]; then week_color="${fg_orange}"
    else                               week_color="${fg_green}"
    fi
    rate_segments+=("${fg_purple}7d${reset} ${week_color}${bold}${week_rem}%${reset}${dim} left${reset}")
  fi
  rate_part="📊 "
  first_r=1
  for seg in "${rate_segments[@]}"; do
    if [ "$first_r" -eq 1 ]; then
      rate_part="${rate_part}${seg}"
      first_r=0
    else
      rate_part="${rate_part} ${dim}·${reset} ${seg}"
    fi
  done
fi

# ── Cost & Latency from transcript ───────────────────────────────────────────
cost_part=""
latency_part=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  # Last assistant message with costUSD
  last_cost=$(grep -o '"costUSD":[0-9.]*' "$transcript" 2>/dev/null | tail -1 | grep -o '[0-9.]*')
  # Cumulative cost: sum all costUSD values
  total_cost=$(grep -o '"costUSD":[0-9.]*' "$transcript" 2>/dev/null \
               | grep -o '[0-9.]*' \
               | awk '{s+=$1} END {if(s>0) printf "%.4f", s}')
  if [ -n "$total_cost" ]; then
    cost_part="${fg_gold}💰 \$${total_cost}${reset}"
  fi

  # Last durationMs → convert to seconds
  last_ms=$(grep -o '"durationMs":[0-9]*' "$transcript" 2>/dev/null | tail -1 | grep -o '[0-9]*')
  if [ -n "$last_ms" ]; then
    latency_sec=$(awk "BEGIN {printf \"%.2f\", $last_ms/1000}")
    if   [ "$last_ms" -gt 10000 ]; then lat_color="${fg_red}"
    elif [ "$last_ms" -gt 5000  ]; then lat_color="${fg_yellow}"
    else                                lat_color="${fg_teal}"
    fi
    latency_part="${lat_color}⚡ ${bold}${latency_sec}s${reset}"
  fi
fi

# ── Assemble status line ──────────────────────────────────────────────────────
# Line 1: ➜  📁 dir  🌿 branch ✓/✏️
# Line 2: 🤖 model  │  🟢 ctx%  │  💰 cost  │  ⚡ latency
sep=" ${dim}│${reset} "

line1="${fg_cyan}${bold}➜${reset}  ${fg_teal}📁 ${bold}${fg_white}${dir_name}${reset}${git_part}"

meta_parts=()
[ -n "$model_part"   ] && meta_parts+=("$model_part")
[ -n "$ctx_part"     ] && meta_parts+=("$ctx_part")
[ -n "$rate_part"    ] && meta_parts+=("$rate_part")
[ -n "$cost_part"    ] && meta_parts+=("$cost_part")
[ -n "$latency_part" ] && meta_parts+=("$latency_part")

if [ "${#meta_parts[@]}" -gt 0 ]; then
  line2="   "
  first=1
  for part in "${meta_parts[@]}"; do
    if [ "$first" -eq 1 ]; then
      line2="${line2}${part}"
      first=0
    else
      line2="${line2}${sep}${part}"
    fi
  done
  printf "%s\n%s\n" "$line1" "$line2"
else
  printf "%s\n" "$line1"
fi

