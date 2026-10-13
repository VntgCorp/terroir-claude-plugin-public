# Claude Code status line - Windows PowerShell port of statusline-command.sh
# ASCII only: emoji are built from code points so file encoding does not matter.
$ErrorActionPreference = 'SilentlyContinue'
[Console]::InputEncoding  = New-Object System.Text.UTF8Encoding $false
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$inv = [System.Globalization.CultureInfo]::InvariantCulture

function U([int[]]$cps) { -join ($cps | ForEach-Object { [char]::ConvertFromUtf32($_) }) }

$data = [Console]::In.ReadToEnd() | ConvertFrom-Json

# -- Extract fields from JSON --------------------------------------------------
$cwd = $data.workspace.current_dir
if (-not $cwd) { $cwd = $data.cwd }
$model      = $data.model.display_name
$used_pct   = $data.context_window.used_percentage
$ctx_size   = $data.context_window.context_window_size
$ctx_input  = $data.context_window.current_usage.input_tokens
$five_pct   = $data.rate_limits.five_hour.used_percentage
$week_pct   = $data.rate_limits.seven_day.used_percentage
$transcript = $data.transcript_path

# -- ANSI palette --------------------------------------------------------------
$e = [char]27
$reset = "$e[0m"; $bold = "$e[1m"; $dim = "$e[2m"
$fg_white = "$e[97m"; $fg_cyan = "$e[96m"; $fg_green = "$e[92m"; $fg_yellow = "$e[93m"
$fg_red = "$e[91m"; $fg_orange = "$e[38;5;208m"; $fg_purple = "$e[38;5;141m"
$fg_sky = "$e[38;5;117m"; $fg_gold = "$e[38;5;220m"; $fg_teal = "$e[38;5;43m"

# -- Symbols -------------------------------------------------------------------
$s_arrow = U 0x279C; $s_folder = U 0x1F4C1; $s_leaf = U 0x1F33F; $s_pencil = U 0x270F,0xFE0F
$s_check = U 0x2713; $s_vbar = U 0x2502;    $s_robot = U 0x1F916; $s_chart = U 0x1F4CA
$s_money = U 0x1F4B0; $s_bolt = U 0x26A1;   $s_full = U 0x2588;   $s_empty = U 0x2591
$s_dot = U 0x00B7
$s_red = U 0x1F534; $s_orange = U 0x1F7E0; $s_yellow = U 0x1F7E1; $s_green = U 0x1F7E2

# -- Directory (basename) ------------------------------------------------------
$dir_name = ''
if ($cwd) { $dir_name = Split-Path -Leaf $cwd }

# -- Git branch + dirty flag ---------------------------------------------------
$git_part = ''
if ($cwd -and (Get-Command git -ErrorAction SilentlyContinue)) {
  git -C "$cwd" rev-parse --git-dir 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) {
    $branch = git -C "$cwd" symbolic-ref --short HEAD 2>$null
    if (-not $branch) { $branch = git -C "$cwd" rev-parse --short HEAD 2>$null }
    if ($branch) {
      $changes = git -C "$cwd" status --porcelain 2>$null
      if ($changes) { $dirty = "$fg_yellow $s_pencil $reset" } else { $dirty = "$fg_green $s_check$reset" }
      $git_part = " $dim$s_vbar$reset $fg_purple$s_leaf $bold$branch$reset$dirty"
    }
  }
}

# -- Model ---------------------------------------------------------------------
$model_part = ''
if ($model) { $model_part = "$fg_sky$s_robot $bold$model$reset" }

# -- Context usage bar + token counts ------------------------------------------
$ctx_part = ''
if ($null -ne $used_pct) {
  $ctx_used = [int][math]::Round([double]$used_pct)
  if     ($ctx_used -ge 80) { $bar_color = $fg_red;    $bar_emoji = $s_red }
  elseif ($ctx_used -ge 50) { $bar_color = $fg_orange; $bar_emoji = $s_orange }
  elseif ($ctx_used -ge 25) { $bar_color = $fg_yellow; $bar_emoji = $s_yellow }
  else                      { $bar_color = $fg_green;  $bar_emoji = $s_green }
  $filled = [math]::Floor($ctx_used / 10)
  $bar = ''
  for ($i = 1; $i -le 10; $i++) { if ($i -le $filled) { $bar += $s_full } else { $bar += $s_empty } }
  $token_info = ''
  if (($null -ne $ctx_input) -and ($null -ne $ctx_size)) {
    $cur_k = ([double]$ctx_input / 1000).ToString('0.0', $inv)
    $max_k = ([double]$ctx_size / 1000).ToString('0', $inv)
    $token_info = " $dim(${cur_k}k / ${max_k}k tokens)$reset"
  }
  $ctx_part = "$bar_emoji $bar_color$bold$ctx_used%$reset $dim$bar$reset$token_info"
}

# -- Rate limits (5h session / 7d weekly) --------------------------------------
function RateColor([int]$used) {
  if ($used -ge 80) { $fg_red } elseif ($used -ge 50) { $fg_orange } else { $fg_green }
}
$rate_segments = @()
if ($null -ne $five_pct) {
  $five_used = [int][math]::Round([double]$five_pct)
  $rate_segments += "${fg_sky}5h$reset $(RateColor $five_used)$bold$(100 - $five_used)%$reset$dim left$reset"
}
if ($null -ne $week_pct) {
  $week_used = [int][math]::Round([double]$week_pct)
  $rate_segments += "${fg_purple}7d$reset $(RateColor $week_used)$bold$(100 - $week_used)%$reset$dim left$reset"
}
$rate_part = ''
if ($rate_segments.Count -gt 0) { $rate_part = "$s_chart " + ($rate_segments -join " $dim$s_dot$reset ") }

# -- Cost & Latency from transcript --------------------------------------------
$cost_part = ''; $latency_part = ''
if ($transcript -and (Test-Path -LiteralPath $transcript -PathType Leaf)) {
  $text = [System.IO.File]::ReadAllText($transcript)
  $costs = [regex]::Matches($text, '"costUSD":([0-9.]+)')
  $total = 0.0
  foreach ($m in $costs) { $total += [double]::Parse($m.Groups[1].Value, $inv) }
  if ($total -gt 0) { $cost_part = "$fg_gold$s_money `$$($total.ToString('0.0000', $inv))$reset" }

  $durs = [regex]::Matches($text, '"durationMs":([0-9]+)')
  if ($durs.Count -gt 0) {
    $last_ms = [long]$durs[$durs.Count - 1].Groups[1].Value
    $latency_sec = ($last_ms / 1000).ToString('0.00', $inv)
    if     ($last_ms -gt 10000) { $lat_color = $fg_red }
    elseif ($last_ms -gt 5000)  { $lat_color = $fg_yellow }
    else                        { $lat_color = $fg_teal }
    $latency_part = "$lat_color$s_bolt $bold${latency_sec}s$reset"
  }
}

# -- Assemble status line ------------------------------------------------------
$sep = " $dim$s_vbar$reset "
$line1 = "$fg_cyan$bold$s_arrow$reset  $fg_teal$s_folder $bold$fg_white$dir_name$reset$git_part"

$meta_parts = @($model_part, $ctx_part, $rate_part, $cost_part, $latency_part) | Where-Object { $_ }
if (@($meta_parts).Count -gt 0) {
  [Console]::Out.Write("$line1`n   " + (@($meta_parts) -join $sep) + "`n")
} else {
  [Console]::Out.Write("$line1`n")
}
