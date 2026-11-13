# .dotfiles

Public dotfiles for [fish](https://fishshell.com/), [git](https://git-scm.com/),
[jed](https://www.jedsoft.org/jed/), and
[VS Code](https://code.visualstudio.com/) — plus a large collection of
[agent skills](#agent-skills) and command-line tools for AI-assisted development
with agents such as Claude Code, Codex, and Gemini CLI.

## Repository layout

```text
.dotfiles/
├── bin/                 # Shell scripts added directly to $PATH
├── fish/
│   ├── config.fish      # Main fish config; loads .private overlay if present
│   ├── conf.d/          # Fish startup snippets
│   ├── completions/     # Fish completions for bin/ scripts and functions
│   └── functions/       # Fish functions (autoloaded)
├── home/                # Dotfiles symlinked into $HOME by install.sh
├── etc/                 # Tool-specific config (agents, VS Code, etc.)
├── skills/              # Agent skills (see Agent skills below)
├── config/              # Plugins for the skill and permission tools
├── docker/              # Dockerfile + notes for building an image from this repo
├── tests/               # TAP tests for bin/ scripts
└── install.sh           # Idempotent install/update script
```

`install.sh` symlinks `home/.*` into `$HOME`, installs packages, and wires up
tool-specific config. It is safe to run multiple times, and doubles as the
updater: an existing checkout is fast-forwarded after approval before applying.
Use `./install.sh --apply` to apply local edits without Git updates. It can be
run locally (`./install.sh`) or piped straight from the network (see
[Installation](#installation)).

How coding agents are set up (global instructions, hooks, launch wrappers, and
what each agent receives) is described in
[`etc/agents/README.md`](etc/agents/README.md).

## Agent skills

The [`skills/`](skills/) directory contains
[Agent Skills](https://agentskills.io): folders with a `SKILL.md` (metadata and
instructions) plus supporting scripts and references that teach AI coding agents
how to perform specific tasks — driving Android devices over adb, inspecting
APKs, looking up current AndroidX library facts, enforcing coding standards,
planning award flights, and more.

### Key skills

| Skill                                          | Description                                                                                          |
| ---------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| [`adb`](skills/adb/)                           | ADB device automation with a Wear OS focus: screenshots, screen recording, tiles, dumpsys, logcat    |
| [`agent-tools`](skills/agent-tools/)           | CLI tools delegating analysis to AI models: image description, screenshot diffing, deep research     |
| [`apk`](skills/apk/)                           | Offline APK binary analysis: manifests, resources, launcher icons, split APKs                        |
| [`coding-standards`](skills/coding-standards/) | This repo's coding standards: shell/Python/Markdown formatting, CLI design, commit message style     |
| [`jetpack`](skills/jetpack/)                   | Current AndroidX/Jetpack facts that are wrong from memory: versions, Maven coordinates, dependencies |

More specialised skills: [`android-testing`](skills/android-testing/) (system
state and connectivity testing on phone and Wear OS),
[`wear-widget`](skills/wear-widget/) (reverse-engineering widgets),
[`agent-config`](skills/agent-config/) (skill selection, agent tool permissions,
MCP servers and Andon alerts), and [`workspace-tools`](skills/workspace-tools/)
(runtimes, `.envrc` blocks and git hooks). Personal-workflow skills live here
too: [`agent-review`](skills/agent-review/), [`picgo`](skills/picgo/) (the last
ten photos and videos, for sharing with agents), [`pinboard`](skills/pinboard/),
[`taskgo`](skills/taskgo/), [`technical-writing`](skills/technical-writing/),
and [`travel`](skills/travel/).

### Installing skills into a workspace

Skills are intentionally **not** installed globally — every project seeing every
skill would be noise. Instead, the bundled `skill` command manages them per
workspace as untracked symlinks in `.claude/skills/` or `.agents/skills/`,
auto-detecting which agent is installed:

```sh
skill add --defaults # link the default skills
skill add jetpack    # add one skill by name
skill list           # what's linked here, 'default' or 'added'
```

Skill names resolve against `skills/` in this repo and its `.private`/`.corp`
overlays (later layers shadow by name); plugins in `config/skill/plugins/`
register additional remote skills from third-party catalogs. The default skills
are set by `etc/skill/defaults.sh` in each layer, which `install.sh` runs. A
fresh clone links them into the repository, and the agent wrappers link them
into each session.

## Overlays

**SECURITY NOTE:** The `.dotfiles` repository is public. To prevent the leakage
of sensitive information (such as API keys, corporate tool configurations, or
internal pathnames), two private companion repositories can optionally be
cloned: `~/.private` and `~/.corp`.

This architecture is specifically designed to help both humans and AI agents
understand what goes where and ensures private information remains strictly out
of the public repository. This repository works fine without them.

### Purpose of each layer

| Repo          | Intended for                                |
| ------------- | ------------------------------------------- |
| `~/.dotfiles` | Public config, tools, and scripts           |
| `~/.private`  | Personal secrets, API keys, private tooling |
| `~/.corp`     | Work machine config, internal tooling       |

### Precedence

`install.sh` processes overlays in this order: `.dotfiles` → `.private` →
`.corp`. Later layers win on conflict. A file in `~/.corp` always beats the same
path in `~/.private` or `~/.dotfiles`.

### How files are applied

Two functions handle overlay merging, with different semantics:

- **`link_overlay_path rel dst`** — symlinks `dst` to the single
  highest-priority source that provides `rel`. Used for whole-file configs where
  only one version makes sense (e.g. `etc/starship/starship.toml`).

- **`link_overlay_files rel dst`** — iterates every overlay in order and
  symlinks each file it finds under `rel/` into `dst/`. All overlays contribute;
  later layers win on filename collision. Used when multiple overlays may each
  add files to a directory (e.g. `etc/code/`).

`home/` dotfiles are linked by iterating all overlays in order with `ln -sf`, so
the last overlay to provide a given filename wins.

### Overlay-aware paths

| Path                                                 | Mechanism                           | Notes                                                                                           |
| ---------------------------------------------------- | ----------------------------------- | ----------------------------------------------------------------------------------------------- |
| `home/.*`                                            | `link_home_dotfiles` (all overlays) | Last overlay wins per filename                                                                  |
| `etc/agents/AGENTS.md`                               | `overlay_path` (highest wins)       | Symlinked to `~/.codex/`, `~/.gemini/`, `~/.claude/`, `~/.config/opencode/` (gated on binaries) |
| `etc/agents/agy/hooks.json`                          | `link_overlay_path`                 | Symlinked to `~/.gemini/config/hooks.json` (gated on `agy`)                                     |
| `etc/agents/agy/hooks`                               | `link_overlay_path`                 | Symlinked to `~/.gemini/config/hooks` (gated on `agy`)                                          |
| `etc/agents/hooks/ensure-commit-hooks`               | `overlay_path`                      | Registered as a `PreToolUse` hook in `~/.claude/settings.json` (gated on `claude`)              |
| `etc/agents/opencode/plugins/ensure-commit-hooks.ts` | `link_overlay_path`                 | Symlinked to `~/.config/opencode/plugins/` (gated on `opencode`)                                |
| `skills/agent-config/plugins/andon/opencode`         | `link_overlay_path`                 | Symlinked to `~/.config/opencode/plugins/andon` (gated on `opencode`)                           |
| `etc/shpool/config.toml`                             | `link_overlay_path`                 |                                                                                                 |
| `etc/starship/starship.toml`                         | `link_overlay_path`                 |                                                                                                 |
| `etc/ghostty/config`                                 | `link_overlay_path`                 |                                                                                                 |
| `etc/bat/config`                                     | `link_overlay_path`                 |                                                                                                 |
| `etc/uv/uv.toml`                                     | `link_overlay_path`                 | Restricts uv to its own Python builds (`only-managed`)                                          |
| `etc/code/`                                          | `link_overlay_files`                | VS Code `settings.json`, `keybindings.json`, etc.                                               |
| `etc/macos/KeyBindings`                              | `overlay_path`                      | rsync'd (not symlinked) due to macOS bug                                                        |
| `etc/macos/Solarized.clr`                            | `overlay_path`                      | Copied to `~/Library/Colors/`                                                                   |
| `etc/skill/defaults.sh`                              | run by `install.sh`                 | Adds or removes default skills with `skill --scope defaults`                                    |
| `skills/*/`                                          | `skill` catalog source              | Not linked globally; added per workspace via `skill add` (see [Agent skills](#agent-skills))    |

### Per-overlay `update` hooks

After the main install, `install.sh` runs `~/.private/update` and
`~/.corp/update` if they exist and are executable. These hooks handle
overlay-specific setup that cannot be expressed as file overlays (package
installs, auth setup, etc.).

### Expected layout

```text
.private/               # same structure for .corp
├── fish/
│   ├── conf.d/         # Startup snippets sourced by config.fish
│   ├── completions/    # Completions prepended to fish_complete_path
│   ├── functions/      # Functions prepended to fish_function_path
│   └── secrets.env     # API keys and tokens (chmod 600), or secrets.env.age
├── home/               # Dotfiles symlinked into $HOME (e.g. .gitconfig.local)
├── etc/                # Tool-specific config (see overlay-aware paths above)
├── skills/             # Agent skills that shadow ~/.dotfiles/skills/ by name
└── update              # Optional hook run at end of ./install.sh
```

`fish/config.fish` prepends `~/.private/fish/functions` (and `.corp`
equivalents), `~/.private/fish/completions` and each
`~/.private/skills/*/completions` to the fish search paths, and sources any
`~/.private/fish/conf.d/*.fish` snippets at shell startup.

To install: clone your private repos to `~/.private` and/or `~/.corp`, then run
`./install.sh` again.

## Secret management

Secrets (API keys, tokens) live in plain `NAME=value` files, one per line (blank
lines and `#` comments allowed, nothing expanded). The files are parsed, never
sourced, and nothing loads them in full at shell startup. They sit in the two
private overlays, `~/.private` for personal values and `~/.corp` for work
values, and are read in this order, a later value for the same name winning:

<!-- markdownlint-disable MD013 -->

| File                                 | In Git?   | What belongs there                                           |
| ------------------------------------ | --------- | ------------------------------------------------------------ |
| `~/.private/fish/secrets.shared.env` | Committed | Personal values every machine may hold                       |
| `~/.private/fish/secrets.env.age`    | Ignored   | Personal values for this machine only, encrypted             |
| `~/.private/fish/secrets.env`        | Ignored   | The same, in plaintext, where the machine has no `.age` file |
| `~/.corp/fish/secrets.shared.env`    | Committed | Work values every work machine may hold                      |
| `~/.corp/fish/secrets.env.age`       | Ignored   | Work values for this machine only, encrypted                 |
| `~/.corp/fish/secrets.env`           | Ignored   | The same, in plaintext, where the machine has no `.age` file |

<!-- markdownlint-restore MD013 -->

Missing files are skipped. A **shared** file travels with its overlay's
repository, so a new machine gets its values from `git clone`; put only values
there whose leak would be acceptable (scoped, spend-capped, cheap to rotate),
because anyone who can read the repository, or any agent on any machine that has
it, can read them. Everything else goes in the machine's own file, which each
overlay's `.gitignore` must exclude (`fish/secrets.env`, `fish/secrets.env.age`,
`fish/secrets.env.age~`) and which is copied to a new machine by hand or
re-entered. On a machine where agents run, the machine's own file is readable by
them too, so it should also hold only values acceptable to leak; keep anything
more sensitive on a machine without agents, encrypted.

A `.age` file is the same format encrypted with
[age](https://age-encryption.org/). It is decrypted on each read with the
identity in `~/.config/age/secrets-identity.txt` (for example an `age-plugin-se`
Secure Enclave identity), never written out in plaintext except to a private
temporary directory while it is being edited, and re-encrypted to every
recipient in `~/.config/age/secrets-recipients.txt`, so include a recovery key
there alongside the machine's own. Encryption only helps where the identity is
not a plain file beside the secrets; elsewhere use the plaintext file with mode
`600`.

Four fish functions provide on-demand access:

<!-- markdownlint-disable MD013 -->

| Function      | Usage                           | Description                                    |
| ------------- | ------------------------------- | ---------------------------------------------- |
| `setsecret`   | `setsecret NAME [NAME...]`      | Load secret(s) into the current shell          |
| `getsecret`   | `getsecret NAME`                | Print a secret to stdout                       |
| `envsecret`   | `envsecret NAME [...] [--] CMD` | Run a command with secret(s) injected          |
| `editsecrets` | `editsecrets [FILE]`            | Edit a file in `$EDITOR`, re-encrypting `.age` |

<!-- markdownlint-restore MD013 -->

`envsecret` is the safest option for scripts: secrets are injected into the
child process and never leak into the calling shell. `editsecrets` with no
argument edits this machine's personal file; pass a path to edit a shared or
work file (a missing plaintext file is created with mode `600`).

A `~/.private/fish/conf.d/` snippet uses `setsecret --if-unset` to auto-load a
small set of everyday secrets at shell startup.

Run `getsecret --help` for the file order, and `setsecret --help`,
`envsecret --help` or `editsecrets --help` for details.

## Environment management

[direnv](https://direnv.net/) handles per-project environment switching,
configured via `~/.direnvrc` (symlinked from `home/.direnvrc`). To activate it
in a project, create an `.envrc` file in the project root.

Node.js, Ruby, and Python versions are selected per directory with `envrc`
blocks and installed with `node-install`, `ruby-install`, and `python-install`:

```sh
node-install 22        # latest 22.x into ~/.local/share/node/versions
envrc create node 22   # use node 22 + layout node (node_modules/.bin on PATH)

ruby-install 3.4       # compiles latest 3.4.x into ~/.local/share/ruby/versions
envrc create ruby 3.4  # use ruby 3.4 + layout ruby (gems in .direnv/ruby)

python-install         # checks that uv is installed
envrc create uv        # layout uv (creates and activates .venv)
```

Ruby builds need the `ruby-build` toolchain and its build dependencies, which
install with `install.sh --with ruby`. The installers live in the
`workspace-tools` skill; its
[Language Environments](skills/workspace-tools/SKILL.md#language-environments-node-install-ruby-install-python-install)
section covers the full workflow, including diagnosing a project that runs on
the wrong version.

## Installation

The same `install.sh` script both installs and updates, and runs in two ways.
`git` must already be installed either way (see
[Prerequisites](#prerequisites)).

### Option 1: Straight from the network

Clones the repo to `~/.dotfiles` (if absent), points the push remote at SSH,
then installs — and on later runs, updates (it fast-forwards `~/.dotfiles`
before applying):

```sh
curl -fsSL https://raw.githubusercontent.com/ithinkihaveacat/dotfiles/main/install.sh | bash
```

It must be piped to `bash`, not `sh` — the script is bash and refuses to run
under other shells. Pass flags after `-s --`, e.g. `… | bash -s -- --force`. To
download the whole script before running anything (rather than streaming it into
the interpreter), use the equivalent:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ithinkihaveacat/dotfiles/main/install.sh)"
```

### Option 2: From a local checkout

```sh
cd $HOME
git clone https://github.com/ithinkihaveacat/dotfiles.git .dotfiles
cd .dotfiles
git remote set-url origin --push git@github.com:ithinkihaveacat/dotfiles.git
./install.sh
```

After cloning `~/.private` and/or `~/.corp` (if available), run `./install.sh`
again so the overlay is applied.

> **Note:** `install.sh` may overwrite unmanaged files in locations such as
> `~/Library/KeyBindings`. It is otherwise safe to run multiple times.

### Choosing what runs

`install.sh` is split into features (linking dotfiles, packages, uv, agent
setup, and so on), and a profile picks which of them run. The default,
`workstation`, sets up a long-lived machine for interactive use: dotfiles, fish
and its completions, core packages and interactive extras, and a daily upgrade
of everything installed. Heavier package sets (`android`, `ruby`, `media`,
`services`) are in no profile and are added with `--with`:

```sh
./install.sh --with android,ruby  # also install Android and Ruby tooling
./install.sh --without upgrades   # skip the daily upgrades
./install.sh --prune              # also remove brew packages no feature installs
```

`--only` names the features outright, and `-n`/`--dry-run` prints the selection
without running anything; `./install.sh --help` lists the features and profiles.
Once installed, a package is kept current by later runs whether or not its
feature is selected again.

A failing feature is reported and the rest still run; the exit status is
non-zero if any failed. Set `AGENT_OFFLINE=1` to skip every feature that needs
the network.

On Linux, the default run ends with `restart-warnings`: it checks this user's
native Claude and OpenCode processes for executables replaced on disk. This also
catches application-managed updates and runs even when daily upgrades are
skipped. Warnings include the PID and a restart command when the launcher is
recognizable; nothing is restarted automatically. Run the check alone with
`./install.sh --only restart-warnings`. It does not monitor continuously or
detect outdated libraries, script-based installations, or processes on macOS.

### Developing and publishing changes

These checkouts are live working environments, not release installations. Edit
and try scripts, configuration, and skills locally on any machine; commit and
publish completed changes promptly. Public, personal, and work content stay in
their respective repositories. Existing tools and local commits work offline.

```bash
./install.sh --apply     # Apply this checkout; do not fetch or change Git history
git push-pr             # Publish committed work and open a draft PR
```

`git push-pr` fetches remote refs but never updates the checkout. It stops if
upstream has commits missing locally. It publishes all commits ahead of
upstream, not a selection of files, and reports the exact published commit. Use
follow-up commits for review changes; `git push-pr -f` is available for
deliberate topic rewrites and uses `--force-with-lease`. Offline publication
fails without losing local commits.

Merge PRs with **merge commits**, not squash or rebase merges, so the original
local commits remain in upstream history. Agents may merge routine changes after
CI passes. No custom merge helper is needed: inspect the PR and checks with
`gh pr view <PR>` and `gh pr checks <PR>`, then use
`gh pr merge <PR> --merge --match-head-commit <full-PR-head-SHA>`. Only merge a
ready PR whose relevant checks passed for that SHA; do not use `--admin` or
`--auto`. Marking a draft ready and notifying people are separate actions.

### Adopting incoming changes

Publishing and merging do not activate changes on other machines. Run
`./install.sh` deliberately to inspect incoming commits and a diffstat; enter
`d` for the full diff, `y` to approve, or anything else to stop. All overlays
are checked and approved before any checkout advances. Dirty incoming updates,
unfinished Git operations, and divergence stop the run. Failed updates stop
before applying features. If an update fails after earlier repositories
advanced, they stay advanced: no rollback or history repair is attempted.

The installer never rebases, resets, or stashes, regardless of `pull.rebase`.
Diagnose unusual states separately using `git status` and
`git log --graph --oneline --all`. In particular, old squash-merged local
commits need individual reconciliation, not a blanket reset. Local commits with
no incoming updates are left intact and reported.

Macs, work computers, and server host configuration should use manual
interactive updates, not unattended pulls. Agent hosts can explicitly accept
fast-forwards with `./install.sh --accept-updates --no-input`; `--no-input`
alone does not approve incoming code. `--apply` skips only Git updates; use
`AGENT_OFFLINE=1` to skip network-dependent features too. The installer does not
update `~/.ssh`.

Local edits to live scripts and startup configuration can execute immediately,
before a commit or PR. Use worktrees for broad agent changes on trusted devices,
and for independent concurrent tasks. Serialize work in a shared live checkout.
PRs and CI provide workflow and reliability checks, not proof against malicious
code; local push guards are not access controls.

The `curl ... | bash` installation command executes downloaded code immediately;
it is for deliberate bootstrap, not reviewed updates on trusted machines. Use
the existing local installer there to inspect changes before adoption.

### Cloud environments

For the setup script of a disposable cloud or agent container, use the `cloud`
profile:

```sh
curl -fsSL https://raw.githubusercontent.com/ithinkihaveacat/dotfiles/main/install.sh | bash -s -- --profile cloud
```

It links the dotfiles and fish config, prefetches what the uv-based scripts
need, and sets up skill plugins and default skills. It does not use `sudo`,
install or upgrade packages, update uv or agent CLIs, pull the repositories, or
change npm's prefix, so it needs no access beyond GitHub and uv's package index.
The platform's own agent setup is left alone.

## Prerequisites

### git

- **Ubuntu/Debian**: `sudo apt-get install git`
- **macOS**: `xcode-select --install`

## Platform-specific setup

### macOS

- **Terminal:** Import `etc/macos/Solarized Dark.terminal` and set it as the
  default profile.
- **Keyboard:** System Preferences > Keyboard > Shortcuts > Services > File and
  Folders: enable "New Terminal at Folder".
- **Text Replacements:** If not shared via iCloud, restore from
  `etc/macos/Text Replacements.plist` — see
  [Back up and share text replacements on Mac](https://support.apple.com/en-gb/guide/mac-help/mchl2a7bd795/mac).
- **Lock Screen:** Add to Menu Bar via Keychain Access preferences.
- **Volume:** Add to Menu Bar via Control Center > Sound > Always Show in Menu
  Bar.
- **Time Machine:** Disable local snapshots: `sudo tmutil disablelocal`
- **Hot Corners:** Disable via System Preferences.
- **Fonts:** See <https://typography.guru/journal/awesome-catalina-fonts/>.
- **iA Writer theme:** <https://ia.net/writer/templates/>
- **Network Link Conditioner** (for simulating degraded network conditions):
  <https://developer.apple.com/download/more/?q=Additional%20Tools>

### Raspberry Pi

Complete setup sequence for a fresh Raspberry Pi OS install.

1. Use the [Raspberry Pi Imager](https://www.raspberrypi.com/software/) to write
   the OS to an SD card or SSD.

   - For a headless install: Raspberry Pi OS (other) > Raspberry Pi OS Lite.
   - In OS customisation: enable SSH (Remote access section).
   - (Optional) Configure Wi-Fi.

1. SSH in: `ssh mjs@lil.local` (substitute your username and hostname).

   - (Optional) If using Ghostty, copy the terminfo from your local machine:
     `infocmp -x xterm-ghostty | ssh mjs@lil.local -- tic -x -`

1. Update the OS:

   ```sh
   sudo apt-get update && sudo apt-get upgrade -y
   ```

   Reboot if `/var/run/reboot-required` exists: `sudo reboot`

1. Install git: `sudo apt-get install git`

1. Install Tailscale: `curl -fsSL https://tailscale.com/install.sh | sh` then
   `sudo tailscale up`

1. (Optional) Install Node.js and npm: `sudo apt-get install nodejs npm` (for
   newer versions see [Node.js](#nodejs)).

1. (Optional) Disable WiFi and Bluetooth: add these lines under `[all]` in
   `/boot/firmware/config.txt`:

   ```text
   dtoverlay=disable-wifi
   dtoverlay=disable-bt
   ```

1. (Optional) Change hostname: edit `/etc/hostname` and `/etc/hosts`.

1. Reboot after any optional steps above: `sudo reboot`

Once complete, proceed to [Installation](#installation).

> **Tip:** Use VS Code's
> [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)
> extension to edit files on the Pi.

## Local binaries

Put manually installed binaries in `~/.local/bin`.

## Testing and CI

Scripts are tested with TAP-format tests run via `prove`. Tests are co-located
with the code they cover: `tests/test-*` for `bin/` scripts and
`skills/*/tests/test-*` for skill scripts. Run them with:

```sh
prove -j 9 tests/test-* skills/*/tests/test-*
```

See [tests/README.md](tests/README.md) for details, including how to run tests
offline and in isolated environments.

A GitHub Actions workflow (`.github/workflows/lint.yml`) runs on every push:
`shellcheck` and `shfmt` via `skills/coding-standards/scripts/shell-format` over
all Bash scripts (`bin/`, `skills/*/scripts/`, `install.sh`), `ruff` via
`skills/coding-standards/scripts/python-format` over all Python scripts, plus
the full test suite.

## Offline environments

Tools managed by [uv](https://github.com/astral-sh/uv), meaning scripts with a
`uv run --script` shebang (including the `ruff`, `shfmt`/`shellcheck`, and
`mdformat` formatters), download their dependencies on first use. To prepare a
CI job or cloud agent environment that will later lose network access, run this
once while online, e.g. from the environment's setup script:

```sh
./install.sh --only uv               # install uv; fetch everything into uv's cache
UV_OFFLINE=1 ./install.sh --only uv  # check, without the network, that nothing is missing
```

The check downloads nothing and puts nothing on `PATH`, but it is not read-only:
it builds each script's environment inside uv's cache from the packages already
there, which is how it proves they work offline.

`--only uv` runs just the uv feature of `install.sh`: no `git pull`, no symlinks
into `$HOME`, no `sudo`, and no other packages.

Afterwards, run with `UV_OFFLINE=1` and `AGENT_OFFLINE=1` (see
[tests/README.md](tests/README.md)). CI does exactly this before running the
tests. Dependencies installed outside uv (e.g. `fish`, `xmllint`, `java`) are
not covered.

## Author

<mjs@beebo.org>
