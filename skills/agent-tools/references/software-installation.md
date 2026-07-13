# Software Installation

This document covers installation of CLI tools that are managed as optional
entries in the dotfiles `install.sh` script. These tools are installed manually
and self-update via their own update commands; the `install.sh` script calls
those commands automatically when the tool is present in PATH.

For using the agent CLIs below (`agy`, `claude`, `codex`) as reviewers of plans,
branches, PRs, or documents, see [agent-review.md](agent-review.md).

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

Called automatically by the `install.sh` script when `agy` is in PATH.

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

Called automatically by the `install.sh` script when `claude` is in PATH. Native
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

Called automatically by the `install.sh` script when `codex` is in PATH.

## Build Brief (build-brief)

A Go CLI that wraps Gradle (`gradle` or `./gradlew`) to cut noisy task output,
surface failures/tests/artifacts, and save context-window tokens. Highly
recommended when running Gradle builds or tests inside agent environments to
prevent terminal output from consuming the model's context window.

Docs:

- Website: <https://bb.staticvar.dev/>
- Repository: <https://github.com/static-var/build-brief>

**Install (macOS, Linux):**

```bash
curl -fsSL https://raw.githubusercontent.com/static-var/build-brief/main/install.sh | bash
```

Alternatively, via Homebrew (macOS/Linux):

```bash
brew tap static-var/tap
brew install static-var/tap/build-brief
```

**Usage:**

Replace your standard Gradle commands by prefixing them with `build-brief`. It
will automatically resolve `./gradlew` in your current directory, or fall back
to `gradle` in PATH.

- Run a build: `build-brief build` (equivalent to `./gradlew build`)
- Run tests: `build-brief test` (equivalent to `./gradlew test`)
- Run specific tasks: `build-brief :app:assembleDebug`
- Pass raw flags to Gradle (after `--`): `build-brief -- --stacktrace test`
- Show help/options: `build-brief --help`

Every build writes a complete, raw log to
`/tmp/build-brief/build-brief-*.latest.log` (nothing is lost). You can view the
full logs if the summary is insufficient.

### Agent Integration

To encourage AI coding agents to consistently and correctly utilize
`build-brief` for Gradle commands in your project, it is highly recommended to
add the following stanza to your project's `AGENTS.md` file:

```markdown
## Gradle and build-brief

Use `build-brief` for routine Gradle commands.

Prefer `build-brief gradle ...` or `build-brief ./gradlew ...`
over raw Gradle calls.

For chained shell commands, rewrite each Gradle segment, for
example `build-brief gradle test && build-brief gradle check`.

Use the default output for report-style Gradle commands like
`tasks`, `help`, `projects`, `dependencies`, and
`dependencyInsight`; build-brief preserves their report body.

Fall back to raw Gradle only when the reduced summary is not
enough.
```

For further information on configuring and tuning agentic behavior with
`build-brief`, see the
[Agent Integration guide](https://github.com/static-var/build-brief#agent-integration).

[cc-versioning]: https://code.claude.com/docs/en/setup.md#install-a-specific-version
