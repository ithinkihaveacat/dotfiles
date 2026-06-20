# Software Installation

This document covers installation of CLI tools that are managed as optional
entries in the dotfiles `install` script. These tools are installed manually and
self-update via their own update commands; the `install` script calls those
commands automatically when the tool is present in PATH.

## Antigravity (agy)

Google's terminal coding agent.

Docs (check here if steps below are stale):
<https://antigravity.google/download>

**Install (macOS, Linux):**

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

**Update:**

```bash
agy update
```

Called automatically by the `install` script when `agy` is in PATH.

## Claude Code

Anthropic's terminal coding agent.

Docs (check here if steps below are stale):
<https://code.claude.com/docs/en/quickstart.md>

**Install (macOS, Linux, WSL):**

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

*Not recommended — via Homebrew (macOS):*

```bash
brew install --cask claude-code
```

Two casks are available: `claude-code` (stable, ~1 week behind) and
`claude-code@latest` (ships immediately). Homebrew installs do not auto-update.

**Update:**

```bash
claude update
```

Called automatically by the `install` script when `claude` is in PATH. Native
installs also auto-update in the background. For Homebrew installs, use
`brew upgrade claude-code` instead.

**Release channels:**

Native installs follow a release channel that controls when updates arrive:

- `latest` — every release ships immediately (default)
- `stable` — about a week behind latest

To switch to a channel (or reinstall from it to pick up the latest build):

```bash
claude install latest   # switch to latest channel
claude install stable   # switch to stable channel
```

You can also install a specific version number:

```bash
claude install 2.1.89
```

If a new model or feature isn't appearing, running `claude install latest` is
often the fix. See [Install a specific version][cc-versioning] in the docs for
full details.

## Codex

OpenAI's terminal coding agent. Open source, built in Rust.

Docs (check here if steps below are stale):
<https://developers.openai.com/codex/cli>

**Install (macOS, Linux):**

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

*Not recommended — via Homebrew (macOS):*

```bash
brew install --cask codex
```

**Update:**

```bash
codex update
```

Called automatically by the `install` script when `codex` is in PATH.

[cc-versioning]: https://code.claude.com/docs/en/setup.md#install-a-specific-version
