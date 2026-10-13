import { describe, expect, test } from 'claude-code/testing'

import {
  bar,
  baseName,
  buildLines,
  formatLine,
  level,
  modelName,
  rateSegs,
  untilReset,
  usageColor,
} from '../hooks/register'

const NOW = Date.parse('2026-10-13T08:00:00Z')

const text = (segs: { text: string }[]) => segs.map(s => s.text).join('')

describe('baseName', () => {
  test('POSIX 경로의 마지막 이름', async () => {
    expect(baseName('/Users/hong/work/my-repo')).toBe('my-repo')
  })
  test('Windows 역슬래시 경로', async () => {
    expect(baseName('C:\\Users\\hong\\my-repo')).toBe('my-repo')
  })
  test('Windows 슬래시 경로와 끝 구분자', async () => {
    expect(baseName('C:/Users/hong/my-repo/')).toBe('my-repo')
  })
  test('한글 디렉터리 이름', async () => {
    expect(baseName('/home/hong/프로젝트')).toBe('프로젝트')
  })
  test('루트만 있으면 원래 값', async () => {
    expect(baseName('/')).toBe('/')
  })
})

describe('modelName', () => {
  test('ID 를 표시 이름으로', async () => {
    expect(modelName('claude-opus-5-5')).toBe('Opus 5.5')
    expect(modelName('claude-fable-5-1')).toBe('Fable 5.1')
    expect(modelName('claude-haiku-5-5')).toBe('Haiku 5.5')
  })
  test('날짜 접미와 [1m] 은 뺀다', async () => {
    expect(modelName('claude-sonnet-4-5-20250929')).toBe('Sonnet 4.5')
    expect(modelName('claude-opus-5-5[1m]')).toBe('Opus 5.5')
  })
  test('숫자 하나짜리 버전', async () => {
    expect(modelName('claude-opus-5')).toBe('Opus 5')
  })
  test('형식이 다르면 그대로', async () => {
    expect(modelName('Opus 5.5')).toBe('Opus 5.5')
    expect(modelName('us.anthropic.claude-opus-5-5-v1:0')).toBe('us.anthropic.claude-opus-5-5-v1:0')
    expect(modelName('')).toBe('')
  })
})

describe('bar', () => {
  test('0% 는 빈 칸 10개', async () => {
    expect(bar(0)).toBe('░░░░░░░░░░')
  })
  test('34% 는 3칸', async () => {
    expect(bar(34)).toBe('███░░░░░░░')
  })
  test('100% 는 꽉 참', async () => {
    expect(bar(100)).toBe('██████████')
  })
  test('범위 밖 값은 잘라냄', async () => {
    expect(bar(130)).toBe('██████████')
    expect(bar(-5)).toBe('░░░░░░░░░░')
  })
})

describe('level · usageColor', () => {
  test('level 경계값', async () => {
    expect(level(0)).toBe('🟢')
    expect(level(24)).toBe('🟢')
    expect(level(25)).toBe('🟡')
    expect(level(49)).toBe('🟡')
    expect(level(50)).toBe('🟠')
    expect(level(79)).toBe('🟠')
    expect(level(80)).toBe('🔴')
    expect(level(100)).toBe('🔴')
  })
  test('usageColor 경계값은 테마 색', async () => {
    expect(usageColor(0)).toBe('success')
    expect(usageColor(49)).toBe('success')
    expect(usageColor(50)).toBe('warning')
    expect(usageColor(79)).toBe('warning')
    expect(usageColor(80)).toBe('error')
  })
})

describe('untilReset', () => {
  test('값이 없으면 빈 문자열', async () => {
    expect(untilReset(undefined, NOW)).toBe('')
  })
  test('이미 지난 시각이면 빈 문자열', async () => {
    expect(untilReset('2026-10-13T07:59:00Z', NOW)).toBe('')
  })
  test('잘못된 시각이면 빈 문자열', async () => {
    expect(untilReset('not-a-date', NOW)).toBe('')
  })
  test('1시간 미만은 분', async () => {
    expect(untilReset('2026-10-13T08:42:00Z', NOW)).toBe('42m')
  })
  test('초 단위는 올림', async () => {
    expect(untilReset('2026-10-13T08:00:30Z', NOW)).toBe('1m')
  })
  test('시간과 분', async () => {
    expect(untilReset('2026-10-13T10:13:00Z', NOW)).toBe('2h13m')
  })
  test('하루 이상은 일과 시간', async () => {
    expect(untilReset('2026-10-16T11:00:00Z', NOW)).toBe('3d3h')
  })
})

describe('rateSegs', () => {
  test('창이 없으면 빈 배열', async () => {
    expect(rateSegs([], NOW)).toEqual([])
  })
  test('5h·7d 남은 비율과 초기화까지 남은 시간', async () => {
    const segs = rateSegs(
      [
        { kind: 'five_hour', percentUsed: 28, resetsAt: '2026-10-13T10:13:00Z' },
        { kind: 'seven_day', percentUsed: 10 },
      ],
      NOW,
    )
    expect(text(segs)).toBe('📊 5h 72% left (2h13m) · 7d 90% left')
  })
  test('남은 비율 칸은 사용률에 따라 색이 바뀜', async () => {
    const segs = rateSegs([{ kind: 'five_hour', percentUsed: 85 }], NOW)
    const pct = segs.find(s => s.text === '15%')
    expect(pct?.color).toBe('error')
    expect(pct?.bold).toBe(true)
  })
  test('소수 사용률은 반올림', async () => {
    expect(text(rateSegs([{ kind: 'five_hour', percentUsed: 55.4 }], NOW))).toBe('📊 5h 45% left')
  })
  test('초과한 창은 0%', async () => {
    expect(text(rateSegs([{ kind: 'seven_day', percentUsed: 104 }], NOW))).toBe('📊 7d 0% left')
  })
  test('모르는 창(spend_limit)만 있으면 표시하지 않음', async () => {
    expect(rateSegs([{ kind: 'spend_limit', percentUsed: 63 }], NOW)).toEqual([])
  })
})

describe('formatLine · buildLines', () => {
  const full = {
    cwd: '/work/my-repo',
    git: { branch: 'feature/x', isDirty: false },
    model: 'Opus 5.5',
    usage: {
      context: { tokens: 68000, window: 200000, percent: 34 },
      rateLimits: [
        { kind: 'five_hour', percentUsed: 28 },
        { kind: 'seven_day', percentUsed: 10 },
      ],
      cost: { usd: 1.234 },
    },
    now: NOW,
  }
  const LINE2 =
    '   🤖 Opus 5.5 │ 🟡 34% ███░░░░░░░ (68.0k / 200k tokens) │ 📊 5h 72% left · 7d 90% left │ 💰 $1.23'

  test('모든 값이 있으면 두 줄', async () => {
    expect(formatLine(full)).toBe(`➜  📁 my-repo │ 🌿 feature/x ✓\n${LINE2}`)
  })
  test('변경 있는 브랜치는 연필 표시', async () => {
    expect(formatLine({ ...full, git: { branch: 'main', isDirty: true } })).toContain('🌿 main ✏️')
  })
  test('git 저장소가 아니면 브랜치 칸 없음', async () => {
    expect(formatLine({ ...full, git: null })).toBe(`➜  📁 my-repo\n${LINE2}`)
  })
  test('사용량을 아직 못 받았으면 모델만', async () => {
    expect(formatLine({ ...full, git: null, usage: null })).toBe('➜  📁 my-repo\n   🤖 Opus 5.5')
  })
  test('둘째 줄에 아무것도 없으면 한 줄', async () => {
    expect(buildLines({ ...full, git: null, model: '', usage: null })).toHaveLength(1)
  })
  test('첫 응답 전(percent 없음)에는 컨텍스트 칸 없음', async () => {
    const line = formatLine({ ...full, usage: { ...full.usage, context: { window: 200000 } } })
    expect(line).toBe(
      '➜  📁 my-repo │ 🌿 feature/x ✓\n   🤖 Opus 5.5 │ 📊 5h 72% left · 7d 90% left │ 💰 $1.23',
    )
  })
  test('tokens 가 없으면 토큰 수 생략', async () => {
    const line = formatLine({ ...full, usage: { ...full.usage, context: { window: 200000, percent: 80 } } })
    expect(line).toContain('🔴 80% ████████░░ │')
  })
  test('API key 로그인(rateLimits 비어 있음)이면 사용량 칸 없음', async () => {
    expect(formatLine({ ...full, usage: { ...full.usage, rateLimits: [] } })).not.toContain('📊')
  })
  test('비용이 0 이거나 없으면 비용 칸 없음', async () => {
    expect(formatLine({ ...full, usage: { ...full.usage, cost: { usd: 0 } } })).not.toContain('💰')
    expect(formatLine({ ...full, usage: { ...full.usage, cost: undefined } })).not.toContain('💰')
  })
  test('모델 ID 는 표시 이름으로 보여 줌', async () => {
    expect(formatLine({ ...full, model: 'claude-opus-5-5' })).toContain('🤖 Opus 5.5 │')
  })
  test('모델이 비어 있으면 모델 칸 없음', async () => {
    expect(formatLine({ ...full, model: '' })).not.toContain('🤖')
  })
  test('1M 컨텍스트 창', async () => {
    const line = formatLine({
      ...full,
      usage: { ...full.usage, context: { tokens: 123456, window: 1000000, percent: 12 } },
    })
    expect(line).toContain('🟢 12% █░░░░░░░░░ (123.5k / 1000k tokens)')
  })
  test('색: 구분자는 흐리게, 컨텍스트 퍼센트는 사용률 색', async () => {
    const [line1, line2] = buildLines(full)
    expect(line1?.find(s => s.text === ' │ ')?.dim).toBe(true)
    expect(line2?.find(s => s.text === '34%')?.color).toBe('success')
  })
})
