---
name: coding-standards
description: >-
  Repository coding standards, linters, formatters, CLI design rules, HTTP caching
  guidelines, and git commit message conventions (Conventional Commits). Includes
  scripts for formatting Python, shell, Markdown, Kotlin, JSON, and XML. Use when
  writing, reviewing, formatting, or linting code, verifying CLI ergonomics,
  implementing caching and offline modes, or formatting git commit messages.
compatibility: >-
  Requires uv (runs pinned ruff, shfmt, shellcheck, and mdformat via uv run
  --script), plus jq, xmllint, or java for the JSON, XML, and Kotlin formatters.
---

# Coding Standards

This skill provides coding guidelines, linters, and formatters for making
changes across languages and domains in this repository.

## Formatting Scripts

Helper scripts live in `<skill-dir>/scripts/<tool>` (without `.py` or `.sh`
extensions) and are symlinked onto `PATH` via `~/.dotfiles/bin/<tool>`, so they
can be invoked directly by name (e.g., `markdown-format`) or via
`scripts/<tool>` relative to this skill directory. All formatters accept
`--check`, expand directory arguments recursively, format multiple files in
place, and read from `stdin` / write to `stdout` when given no paths (except
`command-index-format`, which uses `--all` instead of `stdin`). In strict
scratch-only sandboxes where `~/.cache/uv` is read-only, set `UV_CACHE_DIR` to a
writable scratch directory before running `uv`-backed formatters.

- **`scripts/python-format`** (`python-format`): Format and lint Python files
  using `ruff` (supports `--check` and recursive `.py` directory scanning).
- **`scripts/shell-format`** (`shell-format`): Format and lint POSIX/Bash
  scripts using `shfmt` and `shellcheck`, and format Fish scripts (`.fish` or
  `fish` shebang) using `fish_indent` (supports `--check` and recursive
  directory scanning).
- **`scripts/markdown-format`** (`markdown-format`): Format Markdown files using
  `mdformat` with GFM and frontmatter wrapping (supports `--check` and recursive
  `.md` directory scanning).
- **`scripts/command-index-format`** (`command-index-format`): Refresh generated
  `--help` blocks in Markdown files with marker comments (accepts file or
  directory paths, `--check`, and `--all`).
- **`scripts/kotlin-format`** (`kotlin-format`): Format Kotlin files using
  `ktfmt` with kotlinlang style (supports `--check`, recursive `.kt`/`.kts`
  directory scanning, and `AGENT_OFFLINE=1` when the jar is cached).
- **`scripts/json-format`** (`json-format`): Format JSON files using `jq`
  (supports `--check` and recursive `.json` directory scanning).
- **`scripts/xml-format`** (`xml-format`): Format XML files using `xmllint`
  (supports `--check` and recursive `.xml` directory scanning; repository-local
  XML layout rules in `AGENTS.md`, such as multi-line manifest attributes, take
  precedence where specified).

Always prefer the helper scripts in `scripts/` over raw tool invocations to
guarantee consistent repository formatting rules.

## Core Standards & Guidelines

### Markdown Quality

All Markdown files must be formatted with `scripts/markdown-format` (enforced in
CI via `--check`; `.markdownlint-cli2.jsonc` is optional editor configuration).
Keep repository Markdown strictly Unicode-only for symbols and notation (`→`,
`≤`, `×`, code spans)—never use `$...$` or `$$...$$` LaTeX math, which plain GFM
`mdformat` escapes. Headings default to clean, unadorned ATX style
(`## Heading`) without manual bolding, ALL CAPS, or section numbers on topical
headings; see **[references/markdown.md](references/markdown.md)** for
existing-document and sequential-step rules.

### Python Development

All Python files must be linted and formatted with `scripts/python-format`.
Follow type annotation conventions, structured CLI argument parsing with
`argparse`, and error handling standards. See
**[references/python.md](references/python.md)**.

### Shell Script Quality

All shell scripts must pass `scripts/shell-format` (`shellcheck` and `shfmt`).
Use POSIX or Bash idioms with strict error handling (`set -euo pipefail` or
`set -u`), safe quoting, and discoverable help systems conforming to CLI design
guidelines. See **[references/shell.md](references/shell.md)**.

### CLI Tool Design

Language-agnostic rules for designing predictable, discoverable command-line
tools: clean command structures (`tool [verb] [noun]`), dual output streams
(`stdout` for data, `stderr` for diagnostics), deterministic exit codes, and
`--help` formatting. See **[references/cli-tools.md](references/cli-tools.md)**.

### Script Self-Containment

Tools are one executable file by default. Split a script only when its
dependency set is materially different; keep the split file in `scripts/` (never
`libexec/`); and resolve any unavoidable sibling from the script's real path, a
sentinel root, and an environment override. See
**[references/cli-tools.md](references/cli-tools.md#script-self-containment-and-sibling-files)**.

### Caching and Offline Mode

Cross-cutting conventions for tools that fetch remote resources over the
network: caching under `$XDG_CACHE_HOME`, strict offline mode enforcement via
`AGENT_OFFLINE=1`, and cache-age reporting. See
**[references/caching.md](references/caching.md)**.

### Long-Running Servers

Servers log one content-free record per request, bounded on disk, and leave
reading the logs to one separate reader; servers of one kind (this repository's
MCP servers) match each other, taking the existing ones as their specification.
See **[references/servers.md](references/servers.md)**.

### Git Operations & Commit Messages

Agents must not commit changes automatically unless explicitly authorized (or
when running guarded `taskgo` tracker commands—`create`, `checkpoint`, `commit`,
`fix`—in a control repository whose committed `AGENTS.md` declares `taskgo`).
Commit messages must adhere strictly to Conventional Commits syntax
(`type(scope): description`), keeping the subject under 50 characters and
hard-wrapping body prose to 72 characters. See
**[references/git.md](references/git.md)**.

### Web Development

Guidelines for web development focusing on resilient client-side state
management, deep-linking, scroll-position preservation, and navigation behavior.
See **[references/web.md](references/web.md)**.

## Reference Material

- **[Markdown Standards](references/markdown.md)** — GFM rules, frontmatter
  handling, and heading conventions.
- **[Python Standards](references/python.md)** — Code style, typing, and
  packaging practices.
- **[Shell Standards](references/shell.md)** — POSIX/Bash scripting rules, error
  handling, and linters.
- **[CLI Design](references/cli-tools.md)** — Universal CLI UI/UX standards,
  output streams, and exit codes.
- **[Caching & Offline](references/caching.md)** — Network caching patterns and
  offline-mode variables.
- **[Long-Running Servers](references/servers.md)** — Request logs, and
  consistency between servers of one kind.
- **[Git Operations](references/git.md)** — Conventional Commits syntax and
  commit message rules.
- **[Web Guidelines](references/web.md)** — State management and web frontend
  guidelines.
