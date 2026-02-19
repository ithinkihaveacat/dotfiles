# Context Files

This directory contains reusable reference documents for local agent workflows.

- `markdown.md`: Markdown formatting and linting guidance used when editing
  docs.
- `cli-tools.md`: Command-line interface design rules and conventions.
- `shell.md`: Shell scripting quality and safety guidance.
- `android.md`: Android-specific workflows and tool usage notes.
- `git.md`: Git operation policies and commit conventions.

How these files are used:

- `AGENTS.md` references these files so agents can load focused guidance on
  demand.
- `./update` links this directory into tool-specific config locations (for
  example, `~/.gemini/context`, `~/.claude/context`, and `~/.codex/context`).
- Skills and prompts may refer agents to these files for project-specific
  standards.
