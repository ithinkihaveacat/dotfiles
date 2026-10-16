export type AndonColor = 'yellow' | 'red'

export type AndonStatus = 'open' | 'resolved' | 'dismissed'

/** Which alerts the board shows. */
export type AndonFilter = 'open' | 'red' | 'yellow' | 'closed' | 'all'

/** An alert as `andon list --json` prints it (the fields the board reads). */
export type AndonAlert = {
  id: string
  created_at: string
  status: AndonStatus
  color: AndonColor
  kind: string
  level: number
  summary: string
  sources: string[]
  fingerprint: string
  recurrences: number
  conversation_id?: string | null
}

/** Open alerts across every session, as `andon stats --json` counts them. */
export type AndonCounts = { open: number; red: number }

declare module 'claude-code' {
  interface PluginState {
    andon: {
      /** The level set in this conversation; null follows the default. */
      sessionLevel: number | null
      /** The persistent default: ANDON_LEVEL, else `andon level`, else 3. */
      defaultLevel: number
      /** From the classic hook envelope; tool calls do not carry it. */
      transcriptPath: string | null
      counts: AndonCounts
      board: AndonAlert[]
      filter: AndonFilter
      isSessionOnly: boolean
      /** One line under the board's header: the last action or failure. */
      notice: string | null
    }
  }
}
