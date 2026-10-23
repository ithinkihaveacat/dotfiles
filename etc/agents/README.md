# Agent integration

This directory holds the configuration that `install.sh` applies to coding
agents (Claude Code, Codex, Antigravity, OpenCode). It is one of several places
that set up an agent; the [matrix](#per-agent-matrix) below lists all of them,
so adding or auditing an agent starts here.

## Layout

```text
etc/agents/
├── AGENTS.md          # Global instructions shared by every agent
├── hooks/             # Hook bodies any agent can run
│   └── ensure-commit-hooks
├── agy/               # Antigravity and Jetski adapters
│   ├── hooks.json
│   ├── hooks/         # PreToolUse, SessionStart
│   └── statusline.sh
├── claude/            # Claude Code adapters
│   └── statusline.sh
└── opencode/          # OpenCode adapters
    └── plugins/
        └── ensure-commit-hooks.ts
```

- **Top level: shared by every agent.** `AGENTS.md` is written once and linked
  under each agent's own name for its global instructions file.
- **`hooks/`: hook bodies with no agent-specific output.** A script here reads
  the tool-call JSON on stdin, accepts each supported agent's payload shape,
  writes nothing, and always exits 0. An agent whose hook API needs a reply
  (Antigravity must answer `{"decision":"allow"}`) wraps the script; one that
  accepts a silent exit (Claude Code) runs it directly. Keeping the reply in a
  wrapper means no agent's decision format can leak into another: Claude Code,
  for example, reads an `allow` decision as "skip the permission prompt".
  OpenCode exposes hooks through a plugin API rather than a command manifest, so
  `opencode/plugins/ensure-commit-hooks.ts` is a thin adapter that forwards its
  shell command and working directory to the same script.
- **`<agent>/`: adapters for one agent.** These are the files only that agent
  understands: its hook manifest, wrappers that adapt shared hooks to its API,
  and its status line script.

Every path here is resolved through the overlays (`overlay_path` or
`link_overlay_path`), so `~/.private` or `~/.corp` can replace any file by
providing the same relative path. See
[Overlay-aware paths](../../README.md#overlay-aware-paths) for how each one is
applied.

## Per-agent matrix

What each agent receives, and where it comes from. "Manual" means the setting is
configured by hand, as described in the script's header.

| Concern                 | Source                                                       | Claude Code                     | Codex                               | Antigravity                         | OpenCode                            |
| ----------------------- | ------------------------------------------------------------ | ------------------------------- | ----------------------------------- | ----------------------------------- | ----------------------------------- |
| Global instructions     | `AGENTS.md`, linked by `install.sh`                          | `~/.claude/CLAUDE.md`           | `~/.codex/AGENTS.md`                | `~/.gemini/GEMINI.md`               | `~/.config/opencode/AGENTS.md`      |
| Launch wrapper          | `fish/functions/<agent>.fish`                                | Session directory and preflight | Sandbox defaults and preflight      | Preflight                           | Preflight                           |
| Preflight               | `fish/functions/_agent_preflight.fish`                       | Session-scope default skills    | Workspace default skills, git hooks | Workspace default skills, git hooks | Workspace default skills, git hooks |
| Commit-hook safety net  | `hooks/ensure-commit-hooks`                                  | `~/.claude/settings.json`       | None                                | `agy/hooks/PreToolUse`              | `plugins/ensure-commit-hooks.ts`    |
| Status line             | `<agent>/statusline.sh`                                      | Manual                          | None                                | Manual                              | None                                |
| Skills                  | `skill` ([agent-config](../../skills/agent-config/SKILL.md)) | Workspace, session, user        | Workspace, user                     | Workspace, session, user            | Workspace                           |
| Command permissions     | `permission` (agent-config)                                  | Yes                             | Yes                                 | Yes                                 | No                                  |
| MCP servers             | `mcp` (agent-config)                                         | Yes                             | Yes                                 | No                                  | Yes                                 |
| Andon plugin            | [`plugins/andon/`](../../skills/agent-config/plugins/andon/) | `claude/`                       | `chatgpt/`                          | No                                  | `opencode/`                         |
| Directory pre-approvals | `permission path add`, run by `install.sh`                   | Yes                             | Yes                                 | Yes                                 | No                                  |

Codex reads skills from the shared `.agents/skills` directory and has no session
scope (see
[the agent-config model](../../skills/agent-config/references/model.md#launchers-and-per-session-skills)).
OpenCode reads the same shared directory (and `.claude/skills`) directly, so
workspace links work there, but `skill` has no OpenCode backend: there is no
session scope and no user scope. The Codex Andon plugin lives in `chatgpt/`
because it also serves the ChatGPT desktop app.

## Adding an agent

1. **Instructions:** in `feature_agents` in `install.sh`, link `AGENTS.md` to
   the agent's global instructions path, gated on the agent's binary.
1. **Launcher:** add `fish/functions/<agent>.fish`, calling `_agent_preflight`
   if the agent runs in a repository and should get default skills and git hooks
   at launch.
1. **Adapters:** put files only this agent reads under `etc/agents/<agent>/`,
   and link or register them in `feature_agents`. Add a row to the
   [Overlay-aware paths](../../README.md#overlay-aware-paths) table for each.
1. **Shared hooks:** if the agent has a pre-tool hook, run
   `hooks/ensure-commit-hooks` from it, wrapping it if the agent requires a
   reply (or adapting it in the agent's plugin, as OpenCode does), and extend
   that script's payload parsing if the agent's JSON shape differs.
1. **Tools:** add a backend to `skill`, `permission` or `mcp` in
   `skills/agent-config/scripts/` where the agent has the matching feature.
1. **Matrix:** add the agent's column above.
