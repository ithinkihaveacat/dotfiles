#!/usr/bin/env bash
# bash 3.2+ compatible (macOS default). Do not use bash 4+ features
# (declare -A, readarray, ${var,,}, |&).

# When piped from the network the caller picks the interpreter
# (`curl ... | bash`), so the shebang above is bypassed. The body of this script
# is bash (arrays, [[ ]], process substitution, printf %q), so fail fast with a
# clear message if it is fed to a non-bash shell, an ancient bash, or a bash in
# POSIX mode (which disables process substitution). These three checks use only
# POSIX sh syntax so they degrade gracefully under dash/sh/zsh/ksh instead of
# emitting cryptic syntax errors. They run before `set -euo pipefail` because
# `pipefail` itself is not POSIX.
if [ -z "${BASH_VERSION:-}" ]; then
  echo "install.sh: must be run with bash, e.g.:" >&2
  echo "  curl -fsSL https://raw.githubusercontent.com/ithinkihaveacat/dotfiles/master/install.sh | bash" >&2
  exit 1
fi
if [ "${BASH_VERSINFO[0]}" -lt 3 ] || { [ "${BASH_VERSINFO[0]}" -eq 3 ] && [ "${BASH_VERSINFO[1]}" -lt 2 ]; }; then
  echo "install.sh: bash 3.2 or newer required (found ${BASH_VERSION})" >&2
  exit 1
fi
if [ -n "${POSIXLY_CORRECT+1}" ]; then
  echo "install.sh: bash must not run in POSIX mode; unset POSIXLY_CORRECT and retry" >&2
  exit 1
fi

set -euo pipefail

# Symlinks and copies files from the ~/.dotfiles directory into their
# correct locations: $HOME, $HOME/.config/fish, $HOME/.config/templates,
# etc.

# Bootstrap: when piped from curl (e.g. `curl -fsSL .../install.sh | bash`) the
# script has no path on disk, so BASH_SOURCE[0] is empty and the self-location
# logic below cannot find the repo. In that case, clone the repo to ~/.dotfiles
# if it is not already present, point the push remote at SSH, then re-exec the
# on-disk copy with the same arguments. A local run (./install.sh) has a real
# BASH_SOURCE and skips this block entirely; an existing checkout is left for
# the `git pull` step further down to fast-forward.
if [ ! -f "${BASH_SOURCE[0]:-}" ]; then
  DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
  if [ ! -d "$DOTFILES/.git" ]; then
    command -v git >/dev/null 2>&1 || {
      echo "install.sh: git not found; install git and re-run" >&2
      exit 127
    }
    echo "Cloning dotfiles into $DOTFILES..."
    git clone https://github.com/ithinkihaveacat/dotfiles.git "$DOTFILES"
    git -C "$DOTFILES" remote set-url origin --push \
      git@github.com:ithinkihaveacat/dotfiles.git
  fi
  exec "$DOTFILES/install.sh" "$@"
fi

# Show usage information
function usage {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Installs and updates dotfiles. Symlinks and copies dotfiles from ~/.dotfiles to
their correct locations, installs packages, and wires up tool-specific config.
Safe to run repeatedly; an existing checkout is fast-forwarded first.

Can also be run directly from the network, which clones the repo to ~/.dotfiles
(if absent) before installing:

  curl -fsSL https://raw.githubusercontent.com/ithinkihaveacat/dotfiles/master/install.sh | bash

OPTIONS:
  --help        Show this help message and exit
  --trace       Print each wrapped command to stderr before running it
  --force       Overwrite existing real files when laying down overlay symlinks
                (default: refuse and exit)
  --non-interactive
                Run without prompting or interactive terminal-session validation

EXAMPLES:
  $(basename "$0")            # Install or update dotfiles
  $(basename "$0") --trace    # Same, but log each wrapped command

  # Install/update over the network, passing flags after '-s --':
  curl -fsSL https://raw.githubusercontent.com/ithinkihaveacat/dotfiles/master/install.sh | bash -s -- --force

EOF
  exit "${1:-0}"
}

TRACE=0
FORCE=0
HAS_SUDO=false
REBOOT_REQUIRED=0
NON_INTERACTIVE=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --help)
      usage 0
      ;;
    --trace)
      TRACE=1
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE=1
      shift
      ;;
    -*)
      echo "$(basename "$0"): unknown option: $1" >&2
      usage 1 >&2
      ;;
    *)
      echo "$(basename "$0"): no arguments expected" >&2
      usage 1 >&2
      ;;
  esac
done

# Auto-detect non-interactive mode if stdin is not a TTY
if [ ! -t 0 ]; then
  NON_INTERACTIVE=1
fi

case "$(uname -s)" in
  Darwin) PLATFORM=darwin ;;
  Linux) PLATFORM=linux ;;
  *)
    echo "$(basename "$0"): unsupported platform $(uname -s)" >&2
    exit 1
    ;;
esac

# Ask for sudo upfront if we're likely to need it
if [ "$PLATFORM" = "linux" ]; then
  export DEBIAN_FRONTEND="noninteractive"
  # Check if sudo requires a password first
  if sudo -n true 2>/dev/null; then
    # Passwordless sudo is configured, no need to prompt
    HAS_SUDO=true
  elif [ "$NON_INTERACTIVE" = 1 ]; then
    echo "Non-interactive mode: skipping interactive sudo validation"
    HAS_SUDO=true
  else
    echo "This script requires sudo access for package management."
    echo "You may be prompted for your password."
    # Good for 5 mins; for more see https://github.com/mathiasbynens/dotfiles/blob/master/.macos#L13
    if ! sudo -v; then
      echo "$(basename "$0"): failed to obtain sudo access" >&2
      exit 1
    fi
    HAS_SUDO=true
  fi
fi

# Runs the command, optionally logging it first when --trace is set.
function x {
  if [ "$TRACE" = 1 ]; then
    printf '+ %s\n' "$(printf '%q ' "$@")" >&2
  fi
  "$@"
}

# Ensure directory exists
function xmkdir {
  if [ ! -d "$1" ]; then
    x mkdir -p "$1"
  fi
}

# Returns success if found
function exists {
  type -P "$1" >/dev/null
}

# Returns success if the Codex agent (not the system file viewer) is found
function is_codex_agent {
  exists codex || return 1
  local path
  path=$(type -P codex)
  [ "$path" != "/usr/bin/codex" ] && [ "$path" != "/bin/codex" ]
}

function heading {
  printf '# %s\n' "$@"
}

# SRCDIR is the root of the git repo
# From http://stackoverflow.com/a/246128/11543
SRCDIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# DSTDIR is the parent of the git repo.
# This is intentional to allow for safe testing in an isolated directory
# (e.g., cloning to /tmp/fake-home/.dotfiles) and flexibility for non-standard locations.
DSTDIR="$(cd -P "$(dirname "${SRCDIR}")" && pwd)"

# Source roots in overlay order: ~/.dotfiles first, ~/.private second, ~/.corp
# last so later roots win on conflict.
SRCDIRS=("$SRCDIR")
if [ -d "$DSTDIR/.private" ]; then
  SRCDIRS+=("$DSTDIR/.private")
fi
if [ -d "$DSTDIR/.corp" ]; then
  SRCDIRS+=("$DSTDIR/.corp")
fi

# Pull each source repo to its upstream before applying. Mirrors the `git up`
# alias in ~/.gitconfig. Non-fast-forward or detached states are surfaced as
# errors via --ff-only so they can't be silently skipped.
git_up() {
  local dir=$1
  [ -d "$dir/.git" ] || return 0
  if ! git -C "$dir" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
    return 0
  fi
  x git -C "$dir" remote update -p
  x git -C "$dir" merge --ff-only '@{upstream}'
}

heading "git pull"
for src in "${SRCDIRS[@]}"; do
  git_up "$src"
done

overlay_path() {
  local rel=$1
  local i
  local candidate

  for ((i = ${#SRCDIRS[@]} - 1; i >= 0; i--)); do
    candidate="${SRCDIRS[$i]}/$rel"
    if [ -e "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

link_overlay_files() {
  local rel=$1
  local dst=$2
  local src
  local f
  local target

  for src in "${SRCDIRS[@]}"; do
    [ -d "$src/$rel" ] || continue
    for f in "$src/$rel"/*; do
      [ -e "$f" ] || continue
      target="$dst/$(basename "$f")"
      if [ -e "$target" ] && [ ! -L "$target" ] && [ "$FORCE" -ne 1 ]; then
        echo "$(basename "$0"): refusing to overwrite real file: $target" >&2
        echo "hint: move it aside or re-run with --force" >&2
        exit 1
      fi
      x rm -rf "$target"
      x ln -sf "$f" "$target"
    done
  done
}

link_overlay_path() {
  local rel=$1
  local dst=$2
  local src

  src=$(overlay_path "$rel") || return 0
  if [ ! -L "$dst" ] || [ "$(readlink "$dst")" != "$src" ]; then
    x rm -rf "$dst"
    x ln -s "$src" "$dst"
  fi
}

# "dotfiles" that will end up in $HOME

link_home_dotfiles() {
  local src=$1
  [ -d "$src/home" ] || return 0
  for f in "$src"/home/.*; do
    if [ -d "$f" ]; then
      continue
    fi
    if [ "$(basename "$f")" = ".DS_Store" ]; then
      continue
    fi
    x ln -sf "$f" "$DSTDIR"
  done
}

for src in "${SRCDIRS[@]}"; do
  link_home_dotfiles "$src"
done

# Remove dangling symlinks

for f in "$DSTDIR"/.*; do

  if [ -L "$f" ]; then
    target=$(readlink "$f")
    # If target is relative, make it absolute relative to DSTDIR
    if [[ "$target" != /* ]]; then
      target="$DSTDIR/$target"
    fi
    if [ ! -e "$target" ]; then
      x rm "$f"
    fi
  fi

done

LOCAL="$HOME/.local"
xmkdir "$LOCAL"
BINDIR="$LOCAL/bin"
xmkdir "$BINDIR"
export PATH="$BINDIR:$PATH"

case "$PLATFORM" in

  darwin)
    heading "macos"
    # For some reason *some* applications (like TextEdit) won't read
    # DefaultKeyBinding.dict if it's symlinked, or is in a symlinked directory,
    # so rsync instead of symlink... http://apple.stackexchange.com/a/53110/890
    # rdar://12429092
    keybindings_dir=$(overlay_path "etc/macos/KeyBindings") || keybindings_dir=""
    if [ -n "$keybindings_dir" ]; then
      x rsync -a --delete "$keybindings_dir/" "$DSTDIR/Library/KeyBindings/"
    fi

    "$SRCDIR/etc/macos/apply-defaults"

    if [ ! -e "$HOME/iCloud" ] && [ -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs" ]; then
      x ln -s "$HOME/Library/Mobile Documents/com~apple~CloudDocs" "$HOME/iCloud"
    fi

    # https://github.com/altercation/ethanschoonover.com/tree/master/projects/solarized/apple-colorpalette-solarized
    solarized_clr=$(overlay_path "etc/macos/Solarized.clr") || solarized_clr=""
    if [ -n "$solarized_clr" ]; then
      x cp "$solarized_clr" "$DSTDIR/Library/Colors/Solarized.clr"
    fi

    if [[ -x /System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport ]]; then
      x ln -sf /System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport "$BINDIR"
    fi

    if [[ -x "$(which networkQuality)" ]]; then
      x ln -sf "$(which networkQuality)" "$BINDIR/speedtest"
    fi

    #	if [[ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]]; then
    #	  x ln -sf /Applications/Tailscale.app/Contents/MacOS/Tailscale "$BINDIR/tailscale"
    #	fi

    if [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
      x ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" "$BINDIR/code"
    fi
    ;;

esac

# fish

heading "fish"

# Fish configuration needs to be in ~/.config/fish

if [ ! -L "$HOME/.config/fish" ] || [ "$(readlink "$HOME/.config/fish")" != "$SRCDIR/fish" ]; then

  if [ -d "$HOME/.config/fish" ] || [ -L "$HOME/.config/fish" ]; then
    x rm -rf "$HOME/.config/fish"
  fi
  xmkdir "$HOME/.config"
  x ln -s "$SRCDIR/fish" "$HOME/.config/fish"

fi

# Update completions if completions more than 7 days old

if exists fish; then

  # shellcheck disable=SC2016 # Variable expands in fish shell, not bash
  fish_completions_dir=$(fish -c 'echo $__fish_cache_dir/generated_completions' 2>/dev/null)
  if [[ -n "$fish_completions_dir" ]] && ! find "$fish_completions_dir" -maxdepth 0 -mtime -7 2>/dev/null | grep -q .; then
    echo "Updating fish completions..."
    fish -c fish_update_completions
  fi

fi

# Generated fish completions

heading "fish completions"

XDG_COMPLETIONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fish/completions"
xmkdir "$XDG_COMPLETIONS_DIR"

if exists hcloud; then
  x hcloud completion fish >"$XDG_COMPLETIONS_DIR/hcloud.fish"
fi

if exists gog; then
  x gog completion fish >"$XDG_COMPLETIONS_DIR/gog.fish"
fi

# shpool

if exists shpool; then

  heading "shpool"

  xmkdir "$HOME/.config/shpool"
  link_overlay_path "etc/shpool/config.toml" "$HOME/.config/shpool/config.toml"

fi

# starship

if exists starship; then

  heading "starship"

  link_overlay_path "etc/starship/starship.toml" "$HOME/.config/starship.toml"

fi

# ghostty

if exists ghostty; then

  heading "ghostty"

  xmkdir "$HOME/.config/ghostty"
  link_overlay_path "etc/ghostty/config" "$HOME/.config/ghostty/config"

fi

# Scripts for $LOCAL/bin

if exists brew; then

  heading "brew"

  brew analytics off

  echo "Updating brew (this may prompt for Xcode license agreement)..."
  if ! brew update; then
    echo "$(basename "$0"): brew update failed" >&2
    echo "hint: sudo xcodebuild -license accept" >&2
    exit 1
  fi

  # The non-HEAD version is years old...
  if ! brew leaves | grep -q jed; then
    x brew install jed --HEAD
  fi

  expected="fish coreutils dict tig wget direnv entr jq pv prettyping exiftool mtr htop pwgen pidcat shellcheck mosh shfmt yazi fzf sevenzip ripgrep viu chafa uv"
  # These packages have non-standard installation mechanisms (see above)
  custom="jed"
  # These packages are optional (don't remove if present)
  optional="imagemagick-full yt-dlp go ffmpeg apktool git composer protobuf bundletool scrcpy git-lfs llm firebase-cli mosquitto gh openclaw/tap/gogcli"

  # These packages are versioned packages that need to be force-linked
  # (typically used when a specific version is needed instead of the default)
  # To completely remove a versioned package: brew remove --force node@24
  versioned="node@24" # e.g. node@24

  comm -13 <(brew leaves | sort) <(echo "$expected" | tr ' ' '\n' | sort) | xargs -n 1 brew install

  # Install versioned packages (specific versions for compatibility/requirements)
  for pkg in $versioned; do
    if ! brew list "$pkg" >/dev/null 2>&1; then
      x brew install "$pkg"
    fi
    # Force link versioned packages to make them available in PATH
    # This may override the default version of the package
    if ! brew link --dry-run "$pkg" 2>&1 | grep -q "Already linked"; then
      x brew link --force --overwrite "$pkg"
    fi
  done

  # Special handling for imagemagick-full (needs manual linking due to conflicts)
  if brew list imagemagick-full >/dev/null 2>&1; then
    if ! brew link --dry-run imagemagick-full 2>&1 | grep -q "Already linked"; then
      x brew link --overwrite imagemagick-full
    fi
  fi

  # Upgrade all packages
  brew upgrade --yes

  comm -23 <(brew leaves | sort) <(echo "$expected" "$custom" "$optional" "$versioned" | tr ' ' '\n' | sort) | xargs -n 1 brew remove

  # Final cleanup of unused dependencies and cache
  brew autoremove
  brew cleanup

  # JDK: Temurin casks are installed below. They land in:
  #   /Library/Java/JavaVirtualMachines/temurin-*.jdk/Contents/Home
  # JAVA_HOME is set in fish/config.fish; consult that for the current value,
  # how to override it for a single command, etc.
  for jdk in temurin@17 temurin@21; do
    if ! brew list --cask "$jdk" >/dev/null 2>&1; then
      x brew install --cask "$jdk"
    fi
  done

fi

if [ "$PLATFORM" = "linux" ]; then

  heading "apt-get"

  if exists apt-get && $HAS_SUDO; then

    x sudo apt-get update # refresh package lists

    expected="apt-file direnv command-not-found dnsutils apache2-utils htop iftop iotop lsof mosh traceroute mtr-tiny whois sysstat dstat hdparm psmisc locate wget curl pv zip unzip libxml2-utils jed sqlite3 jq entr ripgrep nodejs npm shfmt chafa fzf"
    # Optional packages to consider adding to the list above:
    # zlib1g-dev repo

    # TODO: JDK installation on Linux (not yet documented; see fish/config.fish
    # for context on how JAVA_HOME is set and what the macOS approach looks like)

    comm -13 <(dpkg-query -f '${binary:Package}\n' -W | sort) <(echo "$expected" | tr ' ' '\n' | sort) | xargs -r sudo apt-get -y install || echo "warning: some package installations failed"
    # Can't remove any packages because not possible to determine which were
    # user-installed. Use `apt-get remove` to remove manually.

    # Try autoremove with --purge, fallback to standard autoremove if restricted, and ignore failure
    x sudo apt-get -y autoremove --purge || x sudo apt-get -y autoremove || echo "warning: apt-get autoremove failed, skipping"

    # Autoclean is typically restricted, so ignore failures gracefully
    x sudo apt-get -y autoclean || echo "warning: apt-get autoclean failed, skipping"
    # x sudo apt-get -y clean # remove current .deb files
    # x sudo apt-get -y upgrade # update packages, if no new dependencies needed

    # Ignore upgrade failures if they are restricted
    x sudo apt-get -y full-upgrade || echo "warning: apt-get full-upgrade failed, skipping"

    if [ -f /var/run/reboot-required ]; then
      REBOOT_REQUIRED=1
    fi

  else
    echo "$(basename "$0"): no supported package manager (apt-get) found, skipping" >&2
  fi

fi

if [ "$PLATFORM" = "linux" ]; then
  heading "uv"
  if ! exists uv; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
  else
    echo "Updating uv..."
    uv self update
  fi
  echo "Upgrading uv tools..."
  uv tool upgrade --all
fi

heading "git"

if [ "$PLATFORM" = "darwin" ]; then
  git config --file ~/.gitconfig.local credential.helper osxkeychain
fi

heading "vscode"

# Don't use system tools to update VS Code
if [ -e /etc/apt/sources.list.d/vscode.list ] && $HAS_SUDO; then
  x sudo rm -f /etc/apt/sources.list.d/vscode.list || true
fi

if ! exists code; then
  if [ -d "/Applications/Visual Studio Code.app" ]; then
    x ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" "$BINDIR/code"
  fi
fi

if exists code; then

  if [ "$PLATFORM" = "linux" ]; then
    DST="$DSTDIR/.config/Code/User"
  else
    DST="$DSTDIR/Library/Application Support/Code/User"
  fi

  xmkdir "$DST"

  link_overlay_files "etc/code" "$DST"

  # Let's try Settings Sync for now https://code.visualstudio.com/docs/editor/settings-sync

  # expected=$(echo "ms-vscode.vscode-typescript-tslint-plugin golang.go stkb.rewrap esbenp.prettier-vscode eg2.vscode-npm-script GitHub.vscode-pull-request-github DavidAnson.vscode-markdownlint github.github-vscode-theme" | tr '[:upper:]' '[:lower:]')
  # actual=$(code --list-extensions | perl -pe '$_ = lc; chomp if eof' | tr '\n' ' ') # perl to remove trailing newline

  # # can't use xargs because GNU xargs need -r; macOS xargs does -r by default, but rejects the switch
  # for ext in $(comm -23 <(echo "$actual" | tr ' ' '\n' | sort) <(echo "$expected" | tr ' ' '\n' | sort)); do
  #   code --uninstall-extension "$ext"
  # done
  # for ext in $(comm -13 <(echo "$actual" | tr ' ' '\n' | sort) <(echo "$expected" | tr ' ' '\n' | sort)); do
  #   code --install-extension "$ext"
  # done

fi

if exists npm; then

  heading "npm"

  x npm config set prefix "$HOME/.local/share/npm"

  # Packages are installed into $(npm config get prefix)

fi

heading "gradle"

if [ "$PLATFORM" = "darwin" ]; then
  # macOS: hw.memsize is usually the exact physical RAM in bytes
  mem_bytes=$(sysctl -n hw.memsize)
  mem_gb=$((mem_bytes / 1024 / 1024 / 1024))
elif [ "$PLATFORM" = "linux" ]; then
  # Linux: MemTotal is often less than physical RAM due to hardware reservations (GPU, etc.)
  # Round to the nearest GB to infer the physical capacity.
  mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  mem_gb=$(((mem_kb + 524288) / 1048576))
else
  mem_gb=0
fi

echo "Detected ${mem_gb} GB RAM"

if [ "$mem_gb" -ge 64 ]; then
  heap="6g"
elif [ "$mem_gb" -ge 32 ]; then
  heap="4g"
elif [ "$mem_gb" -ge 16 ]; then
  heap="3g"
elif [ "$mem_gb" -ge 8 ]; then
  heap="2g"
elif [ "$mem_gb" -ge 4 ]; then
  heap="1g"
else
  # For 1GB or 2GB machines, use a very small heap
  heap="512m"
fi

gradle_dir="$HOME/.gradle"
gradle_props="$gradle_dir/gradle.properties"

xmkdir "$gradle_dir"

xmkdir "$gradle_dir/init.d"
link_overlay_files "etc/gradle/init.d" "$gradle_dir/init.d"

if [ ! -f "$gradle_props" ]; then
  echo "Creating $gradle_props with heap=${heap}"
  cat >"$gradle_props" <<EOF
# Generated by dotfiles update
org.gradle.jvmargs=-Xmx${heap} -XX:+UseG1GC
org.gradle.parallel=true
org.gradle.caching=true
EOF
else
  if grep -q "# Generated by dotfiles update" "$gradle_props"; then
    echo "Updating generated $gradle_props with heap=${heap}"
    cat >"$gradle_props" <<EOF
# Generated by dotfiles update
org.gradle.jvmargs=-Xmx${heap} -XX:+UseG1GC
org.gradle.parallel=true
org.gradle.caching=true
EOF
  else
    echo "Skipping $gradle_props as it was not generated by this script and already exists."
  fi
fi

if exists android || exists compose-preview; then
  heading "android"
  if exists android; then
    x android update
  fi
  if exists compose-preview; then
    x compose-preview update
  fi
fi

heading "skill plugins"

# Clean up legacy skill-select configuration and registry
x rm -rf "$HOME/.config/skill-select"

# Plugins for 'skill' and 'permission'
# (overlay repos provide these under config/<tool>/plugins).
xmkdir "$HOME/.config/skill/plugins"
link_overlay_files "config/skill/plugins" "$HOME/.config/skill/plugins"
xmkdir "$HOME/.config/permission/plugins"
link_overlay_files "config/permission/plugins" "$HOME/.config/permission/plugins"

heading "agents"

# Symlink user-supplied context for all agents
agents_context=$(overlay_path "etc/agents/AGENTS.md") || agents_context=""
if [ -n "$agents_context" ]; then
  if is_codex_agent; then
    xmkdir "$HOME/.codex"
    x ln -sf "$agents_context" "$HOME/.codex/AGENTS.md"
  fi
  if exists agy; then
    xmkdir "$HOME/.gemini"
    x ln -sf "$agents_context" "$HOME/.gemini/GEMINI.md"
  fi
  if exists claude; then
    xmkdir "$HOME/.claude"
    x ln -sf "$agents_context" "$HOME/.claude/CLAUDE.md"
  fi
fi

# Skills are intentionally NOT installed globally. Per-repo skills are added
# by `git setup` (or `skill add ...`) using ~/.dotfiles/skills (plus .private
# and .corp overlays) as the source. Keeping ~/.agents/skills and
# ~/.claude/skills empty prevents every project from seeing every skill.

# Warn (but do not fail) if any generated command-index blocks have drifted
# from their scripts' --help output.
if exists agy || exists claude || is_codex_agent; then

  heading "agent CLIs"

  if exists agy; then
    x agy update
  fi
  if exists claude; then
    x claude update
  fi
  if is_codex_agent; then
    x codex update
  fi

fi

if command -v python3 >/dev/null 2>&1; then
  heading "command index drift"
  if ! (cd "$SRCDIR" && bin/command-index-sync --check --all); then
    echo "warning: generated command-index blocks are stale"
    echo "hint: (cd $SRCDIR && bin/command-index-sync --all)"
  fi
fi

if [ -x "$DSTDIR/.private/update" ]; then
  heading "private update"
  "$DSTDIR/.private/update"
fi

if [ -x "$DSTDIR/.corp/update" ]; then
  heading "corp update"
  "$DSTDIR/.corp/update"
fi

if [ "$REBOOT_REQUIRED" = 1 ]; then
  echo "warning: a reboot is required to complete updates"
  if [ -f /var/run/reboot-required.pkgs ]; then
    sed 's/^/warning: /' /var/run/reboot-required.pkgs
  fi
  echo "hint: sudo reboot"
fi
