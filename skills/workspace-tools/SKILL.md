---
name: workspace-tools
description: >-
  Sets up per-workspace scripting-language environments, direnv configuration
  and git hook profiles without version control seeing them. Manages Node.js,
  Ruby, and Python environments (the runtime version plus workspace-local
  packages and command-line tools, activated by direnv .envrc blocks), .envrc
  blocks and variables, and git hook profiles. Use when a project needs a
  runtime, or a command-line tool its own dependency install does not provide
  (a gem, npm CLI, or Python tool), including when a command the project relies
  on is not found; when local results differ from CI or an API is missing from
  the installed runtime; when a version file, engines field, Gemfile, CI
  workflow, or Dockerfile names a different version; or when managing git hooks
  or editing .envrc blocks.
compatibility: >-
  Requires git. Optional: python3, uv, direnv.
---

# Workspace Tools

This skill configures a workspace for development without version control ever
seeing the configuration. It consists of two tools:

1. **`hook`**: The git hook manager. Synchronizes git hooks to match
   `AGENT_REQUIRED_HOOKS` (profiles `agent`, `node`, `gerrit`), managing them
   via trampoline stubs in `.git/hooks/`.
1. **`envrc`**: The configuration manager. Manages marker-delimited blocks in
   `.envrc` files for direnv integration.

Alongside them, the runtime installers `node-install`, `ruby-install`, and
`python-install` install per-user Node.js and Ruby versions (and check for `uv`)
that `envrc` blocks activate per directory, together with a workspace-local
place for the project's packages and command-line tools; see
[Language Environments](#language-environments-node-install-ruby-install-python-install).

## Gotchas

- **Agent shells usually do not load direnv.** A command run in the workspace
  still sees the system runtime unless it goes through
  `direnv exec . <command>`; the `.envrc` blocks below only take effect that
  way, or in an interactive shell with the direnv hook.
- **Install a project's tools into its environment, never user-wide or
  system-wide** unless the user asks for that. `gem install --user-install`,
  `sudo gem install`, `npm install -g`, `pip install --user` and
  `uv tool install` give every project one shared version, ignore the version
  the project pins, and user-level bin directories are often not on `PATH`, so
  the tool goes missing again in the next shell. See
  [Installing Project Tools](#installing-project-tools).
- **If the workspace environment cannot be set up, stop and ask.** A missing
  `ruby-build` or `uv`, or a failed runtime build, is not a reason to fall back
  to a user-wide install or the system runtime: report what failed and let the
  user decide.

______________________________________________________________________

## Managing Git Hooks (`hook`)

The `hook` tool (symlinked in `bin/`) manages Git hooks in your repository as
lightweight trampolines pointing into bundled source scripts under
`resources/hooks/`, allowing hook updates to propagate instantly to all
configured workspaces without external repository dependencies.

```bash
hook [options] <command> [arguments]
```

### Options

- **`-C DIR`** (alias: **`--directory DIR`**): Run as if started in `DIR`
  instead of the current working directory.
- **`--source-dir DIR`** (alias: **`-S DIR`**): Override the hook source
  directory (default: bundled `resources/hooks/` or `$HOOK_SOURCE_DIR`).
- **`--copy`**: Copy hook sources rather than installing trampolines (for
  machines with no persistent dotfiles/skill tree).
- **`--external`**: Make `add`/`remove` operate on an external sub-hook (see
  below) rather than a profile.
- **`--quiet`** (alias: **`-q`**): Suppress informational messages during `add`,
  `apply`, `remove`, and `clean`; errors are still printed.
- **`--all`**: Delete all hooks during `clean` (requires `--force`).
- **`--force`**: Confirm deletion for `clean --all`.

### Profiles

- **`agent`**: Re-wraps commit message body text, bullet lists, and blockquotes
  to fit 72 characters, strips dropped trailers (`Co-Authored-By:`,
  `Assisted-by:`, `TAG=`, `CONV=`), and enforces Conventional Commits formatting
  rules (`commit-msg`).
- **`markdown`**: Verifies that staged Markdown files are formatted according to
  `markdown-format` in `--check` mode, rejecting commits if formatting errors
  are found (`pre-commit`).
- **`node`**: Formats staged TypeScript and Markdown files via Prettier prior to
  committing (`pre-commit`).
- **`gerrit`**: Downloads and installs the Gerrit `Change-Id` commit-msg hook
  (`commit-msg`).

### Commands

- **`apply`**: Synchronize `.git/hooks/` to match `AGENT_REQUIRED_HOOKS`
  (default: `agent`).
- **`add PROFILE...`**: Install one or more hook profiles in the current
  repository.
- **`remove PROFILE...`** (alias: **`rm`**): Remove managed hook profiles.
- **`list`** (alias: **`ls`**): List currently installed hook profiles in this
  repository.
- **`catalog`**: List all available hook profiles and their descriptions.
- **`doctor`**: Audit `.git/hooks/` for missing, drifted, or unmanaged hooks
  (read-only).
- **`clean`**: Remove all managed hooks and restore legacy/original hooks.
- **`add --external HOOK-NAME:KEY SOURCE`**: Install `SOURCE`, a hook script
  kept outside this tree (for example in another repository), as sub-hook `KEY`
  of `HOOK-NAME` (e.g. `pre-push:90-check`). `KEY` is two digits, a dash and a
  name; the digits set its run order after `00-legacy`. Keys owned by a profile
  are refused.
- **`remove --external HOOK-NAME:KEY`**: Remove an external sub-hook, restoring
  a preserved `00-legacy` hook if nothing else is left.

External sub-hooks are trampolines like profile sub-hooks, so editing the source
takes effect immediately. `list` shows them as `external`, `doctor` checks that
their source still exists, and `apply` and `clean` leave them in place.

### Environment Variables

- `AGENT_REQUIRED_HOOKS`: Space-separated hook profile names required by this
  workspace (default: `agent`).
- `HOOK_SOURCE_DIR` (alias: `AGENT_HOOKS_DIR`): Directory containing hook
  profile sources (default: bundled `resources/hooks/`).

______________________________________________________________________

## Managing `.envrc` (`envrc`)

The `envrc` tool (symlinked in `bin/`) is the single write path for `.envrc`
files: it manages marker-delimited configuration blocks so multiple
configurations co-exist safely and other tools never edit `.envrc` directly.

- **`create <type> [args...]`** / **`delete <type>`** / **`show <type>`**:
  Create, delete, or print a typed block (`node`, `ruby`, `uv`, `firebase`,
  `appengine`, or a raw `block NAME` whose content is read from stdin).
- **`list`**: List the active blocks.
- **`set VAR VALUE`** / **`unset VAR`** / **`get VAR`**: Manage individual
  environment variables in a managed `env` block. Values are written
  single-quoted, so they are always literal data — shell syntax is never
  evaluated when direnv loads the file — and `get` reads the file statically
  without executing any shell.

Because `envrc create block` writes arbitrary stdin content that direnv later
executes, it is declared unsafe (see `permissions/unsafe`) and always prompts.

A `.envrc` that still has a `skills` block from before the `skill` tool's
defaults scope prints a reminder on every load; `envrc migrate skills`
(`--dry-run` first) links its skills with `skill add` and deletes the block.

See the [Command Index](references/command-index.md) for full help details.

______________________________________________________________________

## Language Environments (`node-install`, `ruby-install`, `python-install`)

Each project selects its own Node.js, Ruby, or Python through a typed `.envrc`
block; the system-wide runtime is only a fallback. Each block pairs a runtime
version with a `layout` that keeps the project's packages and tools inside the
workspace:

| Block                   | Runtime        | Packages and tools                                                |
| ----------------------- | -------------- | ----------------------------------------------------------------- |
| `envrc create node 22`  | `use node 22`  | `layout node`: `node_modules/.bin` on `PATH`                      |
| `envrc create ruby 3.4` | `use ruby 3.4` | `layout ruby`: gems in `.direnv/ruby` (`GEM_HOME`), bin on `PATH` |
| `envrc create uv`       | uv-managed     | `layout uv`: a `.venv` in the workspace, activated                |

The installers (symlinked in `bin/`) put runtime versions where those blocks
look for them:

- **`node-install VERSION`**: Downloads the official Node.js binary for the
  latest matching release (`22` → newest `22.x.x`) into `$NODE_VERSIONS`
  (`~/.local/share/node/versions`). Takes seconds. It exits non-zero when that
  exact version is already installed, so check `node-install --installed` first.
  `node-install --default 24` instead succeeds either way and makes that version
  the per-user default (`~/.local/share/node/default`, on `PATH` in fish and
  bash when it exists); `install.sh` uses it only on Linux machines whose
  distribution Node.js is too old, and removes it once that changes.
  `node-install --default` alone prints the current default.
- **`ruby-install VERSION`**: Compiles Ruby from source with `ruby-build` into
  `$RUBY_VERSIONS` (`~/.local/share/ruby/versions`). Takes minutes (over ten on
  a small machine) and is declared unsafe, so it always prompts. Run it in the
  background or with a long timeout and wait for it to finish; a command timeout
  is not a build failure. `ruby-build` compiles under `$TMPDIR`; on a host whose
  `/tmp` is a small tmpfs, point `TMPDIR` at a disk directory for the build.
  Rebuild a version that fails to start with a library load error (e.g. after an
  OpenSSL upgrade). It needs a current `ruby-build` (looked up on `PATH`, then
  `~/.local/bin`) and Ruby's build dependencies, both installed by
  `~/.dotfiles/install.sh --with ruby`. If `ruby-build` is missing, follow the
  instructions `ruby-install` prints; never install the distribution's
  `ruby-build` package, which is too old for current Ruby releases.
- **`python-install`**: Checks that `uv` is installed and prints how to install
  it if not. `uv` itself manages Python interpreters (`.python-version`,
  `uv python install`), so there is no per-version Python install step.

### Fixing a Runtime Mismatch

Use this when local results disagree with CI, or a failure names an API the
installed runtime lacks (e.g. `fs.globSync is not a function` on Node.js 20):

1. **Find the version the project expects**, in roughly this order: a version
   file (`.nvmrc`, `.node-version`, `.ruby-version`, `.python-version`),
   `package.json` `engines`, `Gemfile` `ruby`, `pyproject.toml`
   `requires-python`, the CI workflow (e.g. `node-version:` in
   `.github/workflows/*.yml`), and the Dockerfile `FROM` image.
1. **Compare it with what the directory loads:** `node --version` (or
   `ruby --version`) and `envrc show node` (or `envrc show ruby`). No block
   means the system runtime is in use.
1. **Install the version if it is missing:** `node-install --installed`, then
   `node-install 22`; or `ruby-install 3.4`.
1. **Activate it for the directory:** `envrc create node 22` (or
   `envrc create ruby 3.4`, `envrc create uv`). This replaces any existing block
   of that type and runs `direnv allow`. `.envrc` is untracked local
   configuration, so this changes nothing in the repository.
1. **Run the project's commands inside the environment.** An agent's shell may
   not load direnv on `cd`, so run commands through it explicitly and confirm
   the version first:
   ```bash
   direnv exec . node --version
   direnv exec . npm ci
   direnv exec . npm test
   ```
   Reinstall dependencies after switching versions; native modules built for the
   old runtime will not load.

Prefer the version the project already declares. If it declares none and CI pins
one, match CI and suggest that the user add a version file, rather than adding
one to the repository unasked.

`envrc create node` and `envrc create ruby` require `NODE_VERSIONS` and
`RUBY_VERSIONS` to name existing directories (the dotfiles shell configuration
sets both); `use ruby` is defined in `~/.direnvrc`, and `use node` comes from
the direnv standard library.

### Installing Project Tools

Use this when a project needs a command-line tool or package that is not part of
its own dependency install: a deploy tool such as a Ruby gem, a Python CLI, or a
command the project's scripts or README call that is not found.

1. **Find the version the project pins.** Look in the CI workflow (e.g.
   `gem install <tool> -v <version>` or `ruby-version:` in
   `.github/workflows/*.yml`), `Gemfile`, `package.json`, `pyproject.toml`, and
   the README. Match both the runtime and the tool version. If nothing pins the
   tool, install the latest release and tell the user which version you chose,
   so they can pin it.
1. **Activate the matching environment** as in
   [Fixing a Runtime Mismatch](#fixing-a-runtime-mismatch): install the runtime
   if needed, then `envrc create ruby 3.4` (or `node`, `uv`).
1. **Install into the workspace through direnv.** If the project has a `Gemfile`
   that lists the tool, run `direnv exec . bundle install` and invoke the tool
   as `direnv exec . bundle exec <tool>`; Bundler installs into the same
   `.direnv/ruby`. Otherwise:
   ```bash
   direnv exec . gem install <gem> -v <version>         # into .direnv/ruby
   direnv exec . uv pip install '<package>==<version>'  # into .venv
   ```
   For a Node.js tool, prefer the version in `package.json` (installed by
   `npm ci` into `node_modules/.bin`), or run a pinned version once with
   `direnv exec . npx <package>@<version>`. `npx` keeps its download in npm's
   cache and puts nothing on `PATH`, so it is not a user-wide install.
1. **Run the tool through direnv** (`direnv exec . <tool> ...`), and confirm it
   resolves inside the workspace (`direnv exec . sh -c 'command -v <tool>'`).

Adding a tool to the repository's own dependency files (`Gemfile`,
`package.json`, `pyproject.toml`) is a repository change: suggest it rather than
making it unasked.

## Reference Material

- **[Command Index](references/command-index.md)** — Detailed synopsis, options,
  and examples for `hook`, `envrc`, and the runtime installers.
