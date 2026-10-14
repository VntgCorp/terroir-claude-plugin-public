import { atom, read, update } from 'claude-code'
import type { Color, EngineInterface, Register } from 'claude-code'

import type { StatuslineGit, StatuslineSnapshot, StatuslineUsage } from '../types'

// Claude 사용량 표시 — 터미널은 프롬프트 아래 힌트 줄 밑에, 데스크톱은 입력창 위 띠에 두 줄을 그린다.
// settings.json 의 statusLine 을 쓰지 않으므로 사용자가 만든 표시줄과 겹치지 않는다.

export type Seg = { text: string; color?: Color; bold?: boolean; dim?: boolean }

export type LineInput = StatuslineSnapshot & { now: number }

const snapshot = atom({ plugin: 'terroir-statusline', key: 'snapshot' } as const, null)

const CYAN = '#5fffff'
const TEAL = '#00d7af'
const PURPLE = '#af87ff'
const SKY = '#87d7ff'
const GOLD = '#ffd700'
const WINDOWS: Record<string, string> = { five_hour: '5h', seven_day: '7d' }
const SEP: Seg = { text: ' │ ', dim: true }

export function baseName(path: string): string {
  const parts = path.split(/[\\/]+/).filter(Boolean)
  return parts[parts.length - 1] ?? path
}

// claude-opus-5-5 → Opus 5.5, claude-sonnet-4-5-20250929[1m] → Sonnet 4.5. 형식이 다르면 그대로 둔다.
export function modelName(id: string): string {
  const m = /^claude-([a-z]+)((?:-\d{1,2})+)(?:-\d{8})?(?:\[[^\]]*\])?$/.exec(id)
  if (!m || !m[1] || !m[2]) return id
  const family = m[1].charAt(0).toUpperCase() + m[1].slice(1)
  return `${family} ${m[2].slice(1).split('-').join('.')}`
}

export function bar(percent: number): string {
  const filled = Math.max(0, Math.min(10, Math.floor(percent / 10)))
  return '█'.repeat(filled) + '░'.repeat(10 - filled)
}

export function level(percent: number): string {
  if (percent >= 80) return '🔴'
  if (percent >= 50) return '🟠'
  if (percent >= 25) return '🟡'
  return '🟢'
}

// 사용률이 높을수록 경고 색. 테마 색을 써서 다크·라이트 모두에서 보이게 한다.
export function usageColor(percentUsed: number): Color {
  if (percentUsed >= 80) return 'error'
  if (percentUsed >= 50) return 'warning'
  return 'success'
}

export function untilReset(resetsAt: string | undefined, now: number): string {
  if (!resetsAt) return ''
  const ms = Date.parse(resetsAt) - now
  if (!(ms > 0)) return ''
  const minutes = Math.ceil(ms / 60000)
  const d = Math.floor(minutes / 1440)
  const h = Math.floor((minutes % 1440) / 60)
  const m = minutes % 60
  if (d > 0) return `${d}d${h}h`
  if (h > 0) return `${h}h${m}m`
  return `${m}m`
}

export function rateSegs(limits: StatuslineUsage['rateLimits'], now: number): Seg[] {
  const windows = limits.filter(r => WINDOWS[r.kind])
  if (windows.length === 0) return []
  const segs: Seg[] = [{ text: '📊 ' }]
  windows.forEach((r, i) => {
    if (i > 0) segs.push({ text: ' · ', dim: true })
    const left = Math.max(0, Math.round(100 - r.percentUsed))
    const reset = untilReset(r.resetsAt, now)
    segs.push(
      { text: `${WINDOWS[r.kind]} `, color: r.kind === 'five_hour' ? SKY : PURPLE },
      { text: `${left}%`, color: usageColor(r.percentUsed), bold: true },
      { text: ` left${reset ? ` (${reset})` : ''}`, dim: true },
    )
  })
  return segs
}

export function buildLines(input: LineInput): Seg[][] {
  const line1: Seg[] = [
    { text: '➜', color: CYAN, bold: true },
    { text: '  📁 ', color: TEAL },
    { text: baseName(input.cwd), bold: true },
  ]
  if (input.git) {
    line1.push(SEP, { text: '🌿 ', color: PURPLE }, { text: input.git.branch, color: PURPLE, bold: true })
    line1.push(input.git.isDirty ? { text: ' ✏️', color: 'warning' } : { text: ' ✓', color: 'success' })
  }

  const parts: Seg[][] = []
  if (input.model) parts.push([{ text: '🤖 ', color: SKY }, { text: modelName(input.model), color: SKY, bold: true }])

  const context = input.usage?.context
  if (context?.percent !== undefined) {
    const p = context.percent
    const tokens =
      context.tokens !== undefined
        ? ` (${(context.tokens / 1000).toFixed(1)}k / ${Math.round(context.window / 1000)}k tokens)`
        : ''
    parts.push([
      { text: `${level(p)} ` },
      { text: `${p}%`, color: usageColor(p), bold: true },
      { text: ` ${bar(p)}${tokens}`, dim: true },
    ])
  }

  const rate = rateSegs(input.usage?.rateLimits ?? [], input.now)
  if (rate.length > 0) parts.push(rate)

  const cost = input.usage?.cost
  if (cost && cost.usd > 0) parts.push([{ text: `💰 $${cost.usd.toFixed(2)}`, color: GOLD }])

  if (parts.length === 0) return [line1]
  const line2: Seg[] = [{ text: '   ' }]
  parts.forEach((p, i) => {
    if (i > 0) line2.push(SEP)
    line2.push(...p)
  })
  return [line1, line2]
}

export function formatLine(input: LineInput): string {
  return buildLines(input)
    .map(line => line.map(s => s.text).join(''))
    .join('\n')
}

async function readGit($: EngineInterface, cwd: string): Promise<StatuslineGit> {
  try {
    const head = await $.process.run(['git', 'symbolic-ref', '--short', '-q', 'HEAD'], { cwd, timeoutMs: 3000 })
    let branch = head.exitCode === 0 ? head.stdout.trim() : ''
    if (!branch) {
      const sha = await $.process.run(['git', 'rev-parse', '--short', 'HEAD'], { cwd, timeoutMs: 3000 })
      if (sha.exitCode !== 0) return null
      branch = sha.stdout.trim()
    }
    const status = await $.process.run(['git', 'status', '--porcelain'], { cwd, timeoutMs: 3000 })
    return { branch, isDirty: status.exitCode === 0 && status.stdout.trim().length > 0 }
  } catch {
    return null
  }
}

async function refresh($: EngineInterface): Promise<void> {
  const cwd = await $.session.cwd()
  const [git, model, usage] = await Promise.all([readGit($, cwd), $.session.model(), $.session.usage()])
  await update($, snapshot, () => ({ cwd, git, model, usage }))
}

async function measure($: EngineInterface, usage: StatuslineUsage): Promise<void> {
  await update($, snapshot, prev => (prev ? { ...prev, usage } : prev))
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    $.ui.status(undefined)
    await refresh($).catch(() => undefined)
    return result
  })

  on('session.measure', async ($, e, next) => {
    await measure($, { context: e.context, rateLimits: e.rateLimits, cost: e.cost }).catch(() => undefined)
    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    await refresh($).catch(() => undefined)
    return result
  })

  // 터미널은 입력창 아래 힌트 줄(PromptHint)에 붙인다.
  on('ui.render', { component: 'PromptHint' }, async ($, e, next) => {
    const hint = await next(e)
    if (e.surface !== 'terminal') return hint
    const snap = await read($, snapshot)
    if (!snap) return hint
    const { Box, Text } = $.ui.resolve(e)
    const lines = buildLines({ ...snap, now: await $.clock.now() })
    return (
      <Box flexDirection="column">
        {hint}
        {lines.map((line, i) => (
          <Text key={`l${i}`} wrap="truncate-end">
            {line.map((s, j) => (
              <Text key={`s${j}`} color={s.color} bold={s.bold} dimColor={s.dim}>
                {s.text}
              </Text>
            ))}
          </Text>
        ))}
      </Box>
    )
  })

  // 데스크톱 애플리케이션은 PromptHint 를 그리지 않으므로 입력창 위 띠(AbovePrompt)에 그린다.
  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.surface === 'terminal' || e.props.hasSurvey) return next(e)
    const snap = await read($, snapshot)
    if (!snap) return next(e)
    const { Box, Text } = $.ui.resolve(e)
    const lines = buildLines({ ...snap, now: await $.clock.now() })
    return (
      <Box flexDirection="column">
        {lines.map((line, i) => (
          <Text key={`l${i}`} wrap="truncate-end">
            {line.map((s, j) => (
              <Text key={`s${j}`} color={s.color} bold={s.bold} dimColor={s.dim}>
                {s.text}
              </Text>
            ))}
          </Text>
        ))}
      </Box>
    )
  })
}
