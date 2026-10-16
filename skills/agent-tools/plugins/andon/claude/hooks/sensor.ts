// A passive sensor for harness friction. The engine sees patterns the model
// tends to explain away: a command fails right after the agent read a skill,
// a --help probe follows a failure, the same command fails again. On those it
// adds a one-line reminder to the tool result. It never pulls the cord itself
// and never blocks anything: the model decides.

import { TOOL } from './rule'

export type Observation = {
  tool: string
  input: Record<string, unknown>
  isError: boolean
  level: number
}

const SKILL_FILE = /(?:^|\/)SKILL\.md$/
const HELP_PROBE = /(?:^|\s)(?:--help|-h|help)(?:\s|$)/
const MAX_NUDGES = 5
const MAX_DIRS = 20

function dirname(path: string): string {
  const cut = path.lastIndexOf('/')

  return cut <= 0 ? path : path.slice(0, cut)
}

function basename(path: string): string {
  return path.slice(path.lastIndexOf('/') + 1)
}

export function createSensor() {
  const readDirs: string[] = []
  const failures = new Map<string, number>()
  const used = new Set<string>()
  let lastFailed = false

  function nudge(key: string, text: string): string | null {
    if (used.has(key) || used.size >= MAX_NUDGES) return null
    used.add(key)

    return `Andon: ${text} If documented instructions were wrong or stale, pull the Andon cord (${TOOL}, yellow) in the same batch as your workaround; otherwise ignore this.`
  }

  function onBash(command: string, isError: boolean): string | null {
    const probesHelp = HELP_PROBE.test(command)
    if (!isError) {
      const followsFailure = lastFailed
      lastFailed = false

      return followsFailure && probesHelp
        ? nudge(`help:${command.trim().split(/\s+/)[0]}`, 'you probed --help right after a command failed.')
        : null
    }
    lastFailed = true
    const key = command.trim()
    const count = (failures.get(key) ?? 0) + 1
    failures.set(key, count)
    const skill = readDirs.find(dir => command.includes(dir) || command.includes(`${basename(dir)}/`))
    if (skill !== undefined) {
      return nudge(`read:${skill}`, `this command failed after you read the skill in ${skill}.`)
    }
    if (count >= 2) {
      return nudge(`repeat:${key}`, 'the same command has now failed twice.')
    }

    return null
  }

  return {
    /** Returns a reminder for the model, or null. */
    observe({ tool, input, isError, level }: Observation): string | null {
      if (tool === TOOL) {
        lastFailed = false

        return null
      }
      if (tool === 'Read' && typeof input.file_path === 'string' && SKILL_FILE.test(input.file_path)) {
        const dir = dirname(input.file_path)
        if (!readDirs.includes(dir)) readDirs.unshift(dir)
        readDirs.length = Math.min(readDirs.length, MAX_DIRS)

        return null
      }
      if (tool !== 'Bash' || typeof input.command !== 'string') return null
      const reminder = onBash(input.command, isError)

      return level >= 2 ? reminder : null
    },
  }
}
