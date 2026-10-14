export type StatuslineGit = { branch: string; isDirty: boolean } | null

export type StatuslineUsage = {
  context: { tokens?: number; window: number; percent?: number }
  rateLimits: readonly { kind: string; percentUsed: number; resetsAt?: string }[]
  cost?: { usd: number }
}

export type StatuslineSnapshot = {
  cwd: string
  git: StatuslineGit
  model: string
  usage: StatuslineUsage | null
}

declare module 'claude-code' {
  interface PluginState {
    'terroir-statusline': { snapshot: StatuslineSnapshot | null }
  }
}
