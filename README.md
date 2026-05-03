# .dotfiles

Public dotfiles for [fish](https://fishshell.com/), [git](https://git-scm.com/),
[jed](https://www.jedsoft.org/jed/), [VS Code](https://code.visualstudio.com/),
and various other tools.

## Repository layout

```text
.dotfiles/
├── bin/                 # Shell scripts added directly to $PATH
├── fish/
│   ├── config.fish      # Main fish config; loads .private overlay if present
│   ├── conf.d/          # Fish startup snippets
│   ├── completions/     # Fish completions
│   └── functions/       # Fish functions (autoloaded)
├── home/                # Dotfiles symlinked into $HOME by update
├── etc/                 # Tool-specific config (git templates, VS Code, etc.)
├── skills/              # Agent skill definitions
├── tests/               # TAP tests for bin/ scripts
└── update               # Idempotent install script
```

`update` symlinks `home/.*` into `$HOME`, installs packages, and wires up
tool-specific config. It is safe to run multiple times.

## Overlays

**SECURITY NOTE:** The `.dotfiles` repository is public. To prevent the leakage
of sensitive information (such as API keys, corporate tool configurations, or
internal pathnames), two private companion repositories can optionally be
cloned: `~/.private` and `~/.corp`.

This architecture is specifically designed to help both humans and AI agents
understand what goes where and ensures private information remains strictly out
of the public repository. This repository works fine without them.

### Purpose of each layer

| Repo | Intended for |
| --- | --- |
| `~/.dotfiles` | Public config, tools, and scripts |
| `~/.private` | Personal secrets, API keys, private tooling |
| `~/.corp` | Work machine config, internal tooling |

### Precedence

`update` processes overlays in this order: `.dotfiles` → `.private` → `.corp`.
Later layers win on conflict. A file in `~/.corp` always beats the same path in
`~/.private` or `~/.dotfiles`.

### How files are applied

Two functions handle overlay merging, with different semantics:

- **`link_overlay_path rel dst`** — symlinks `dst` to the single highest-priority
  source that provides `rel`. Used for whole-file configs where only one version
  makes sense (e.g. `etc/starship/starship.toml`).

- **`link_overlay_files rel dst`** — iterates every overlay in order and symlinks
  each file it finds under `rel/` into `dst/`. All overlays contribute; later
  layers win on filename collision. Used when multiple overlays may each add
  files to a directory (e.g. `etc/code/`).

`home/` dotfiles are linked by iterating all overlays in order with `ln -sf`, so
the last overlay to provide a given filename wins.

### Overlay-aware paths

| Path | Mechanism | Notes |
| --- | --- | --- |
| `home/.*` | `link_home_dotfiles` (all overlays) | Last overlay wins per filename |
| `etc/agents/AGENTS.md` | `overlay_path` (highest wins) | Symlinked to `~/.codex/`, `~/.gemini/`, `~/.claude/` |
| `etc/shpool/config.toml` | `link_overlay_path` | |
| `etc/starship/starship.toml` | `link_overlay_path` | |
| `etc/ghostty/config` | `link_overlay_path` | |
| `etc/code/` | `link_overlay_files` | VS Code `settings.json`, `keybindings.json`, etc. |
| `etc/macos/KeyBindings` | `overlay_path` | rsync'd (not symlinked) due to macOS bug |
| `etc/macos/Solarized.clr` | `overlay_path` | Copied to `~/Library/Colors/` |
| `skills/*/` | all overlays | Each skill dir linked into `~/.agents/skills/` and `~/.claude/skills/`; later overlays shadow by name |

### Per-overlay `update` hooks

After the main install, `update` runs `~/.private/update` and `~/.corp/update`
if they exist and are executable. These hooks handle overlay-specific setup that
cannot be expressed as file overlays (package installs, auth setup, etc.).

### Expected layout

```text
.private/               # same structure for .corp
├── fish/
│   ├── conf.d/         # Startup snippets sourced by config.fish
│   ├── completions/    # Completions prepended to fish_complete_path
│   ├── functions/      # Functions prepended to fish_function_path
│   └── secrets.fish    # API keys and tokens (chmod 600)
├── home/               # Dotfiles symlinked into $HOME (e.g. .gitconfig.local)
├── etc/                # Tool-specific config (see overlay-aware paths above)
├── skills/             # Agent skills that shadow ~/.dotfiles/skills/ by name
└── update              # Optional hook run at end of ./update
```

`fish/config.fish` prepends `~/.private/fish/functions` (and `.corp`
equivalents) and `~/.private/fish/completions` to the fish search paths, and
sources any `~/.private/fish/conf.d/*.fish` snippets at shell startup.

To install: clone your private repos to `~/.private` and/or `~/.corp`, then run
`./update` again.

## Secret management

Secrets (API keys, tokens) live in `~/.private/fish/secrets.fish` and are not
sourced in full at shell startup. Three fish functions provide on-demand access:

<!-- markdownlint-disable MD013 -->

| Function    | Usage                           | Description                                  |
| ----------- | ------------------------------- | -------------------------------------------- |
| `setsecret` | `setsecret NAME [NAME...]`      | Load secret(s) into the current shell        |
| `getsecret` | `getsecret NAME`                | Print secret value(s) to stdout (array-safe) |
| `envsecret` | `envsecret NAME [...] [--] CMD` | Run a command with secret(s) injected        |

<!-- markdownlint-restore MD013 -->

`envsecret` is the safest option for scripts: secrets are injected into the
child process and never leak into the calling shell.

A `~/.private/fish/conf.d/` snippet uses `setsecret --if-unset` to auto-load a
small set of everyday secrets at shell startup.

Run `setsecret --help`, `getsecret --help`, or `envsecret --help` for details.

## Environment management

[direnv](https://direnv.net/) handles per-project environment switching,
configured via `~/.direnvrc` (symlinked from `home/.direnvrc`). To activate it
in a project, create an `.envrc` file in the project root.

### Node.js

Node.js versions are managed by `bin/node-install` and direnv.

```sh
node-install 22        # installs latest 22.x into ~/.local/share/node/versions
```

Add to `.envrc`:

```sh
use node 22
layout node            # adds node_modules/.bin to PATH
```

### Python

Python environments use [uv](https://github.com/astral-sh/uv). Add to `.envrc`:

```sh
layout uv              # creates .venv if absent, activates it
```

## Installation

```sh
cd $HOME
git clone https://github.com/ithinkihaveacat/dotfiles.git .dotfiles
cd .dotfiles
git remote set-url origin --push git@github.com:ithinkihaveacat/dotfiles.git
./update
```

After cloning `~/.private` and/or `~/.corp` (if available), run `./update` again
so the overlay is applied.

> **Note:** `update` may overwrite unmanaged files in locations such as
> `~/Library/KeyBindings`. It is otherwise safe to run multiple times.

## Prerequisites

### git

- **Ubuntu/Debian**: `sudo apt-get install git`
- **macOS**: `xcode-select --install`

### fish

- **Ubuntu/Debian**: `sudo apt-get install fish`
- **macOS**: `brew install fish`
- **Other**: <https://fishshell.com/>

<!-- markdownlint-disable MD013 -->

> Standard apt packages lag significantly (Ubuntu 24.04: 3.7.0, Debian
> bookworm/Raspberry Pi OS: 3.6.0, Debian trixie: 4.0.2). For fish 4.2+, install
> from the OpenSUSE Build Service:
>
> ```bash
> curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:4/Debian_Unstable/Release.key | \
>   gpg --dearmor | sudo tee /usr/share/keyrings/fish-shell.gpg > /dev/null
> echo 'deb [signed-by=/usr/share/keyrings/fish-shell.gpg] https://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_Unstable/ /' | \
>   sudo tee /etc/apt/sources.list.d/fish-shell.list
> sudo apt update && sudo apt install -y fish
> ```

<!-- markdownlint-restore MD013 -->

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

### Ubuntu

```sh
# Emacs keybindings across GTK apps
gsettings set org.gnome.desktop.interface gtk-key-theme "Emacs"
```

**Compose key:** Set to Caps Lock via Settings > Keyboard. Enables e.g. Caps
Lock + `---` → em dash.

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

1. Install fish (see [Prerequisites](#fish) for the OpenSUSE Build Service
   instructions to get fish 4.2+, or use the older distro version):

   ```sh
   sudo apt-get install fish
   ```

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

## Author

<mjs@beebo.org>
