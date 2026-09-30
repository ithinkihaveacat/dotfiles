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

Packages are grouped into tiers: a core set that is always installed, an
optional set, and a full set. By default only core is installed. Pass
--install-optional to add the optional set, or --install-all to add both the
optional and full sets. Packages outside every tier are left alone and merely
reported, unless --prune is given.

OPTIONS:
  --help        Show this help message and exit
  --trace       Print each wrapped command to stderr before running it
  --force       Overwrite existing real files when laying down overlay symlinks
                and bypass the 24-hour package/tool update TTL
                (default: refuse and exit)
  --install-optional
                Install the core and optional package sets
  --install-all Install the core, optional, and full package sets
  --prune       Remove installed packages not in any tier (brew), and apt
                packages this script has retired (keeping any that other
                installed packages depend on). Prompts first when
                interactive; removes without asking when non-interactive.
                Default: warn only
  --non-interactive
                Run without prompting or interactive terminal-session validation
  --only PART   Run only the named part of the script, then exit: no git pull,
                no symlinks, no sudo, no other packages. Parts: uv (install uv
                and fetch everything this repository's uv-based
                scripts download on first use, so they then work offline).
                For preparing CI jobs and cloud agent environments

ENVIRONMENT:
  UV_OFFLINE    With --only uv, set to 1 to check offline readiness without
                the network: nothing is downloaded or put on PATH, but each
                script's environment is (re)built inside uv's cache from
                packages already there, which is what proves it works.
                Exits non-zero, naming each item, if any package is missing

EXAMPLES:
  $(basename "$0")                   # Install or update; core packages only
  $(basename "$0") --trace           # Same, but log each wrapped command
  $(basename "$0") --install-optional  # Also install the optional package set
  $(basename "$0") --install-all --prune  # Full set; offer to remove extras
  $(basename "$0") --only uv         # Prepare a CI/cloud environment for offline use
  UV_OFFLINE=1 $(basename "$0") --only uv  # Check it is ready, without the network

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
INSTALL_TIER=core
PRUNE=0
ONLY=""

# XDG Base Directory specification defaults
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

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
    --install-optional)
      if [ "$INSTALL_TIER" = all ]; then
        echo "$(basename "$0"): --install-optional and --install-all are mutually exclusive" >&2
        usage 1 >&2
      fi
      INSTALL_TIER=optional
      shift
      ;;
    --install-all)
      if [ "$INSTALL_TIER" = optional ]; then
        echo "$(basename "$0"): --install-optional and --install-all are mutually exclusive" >&2
        usage 1 >&2
      fi
      INSTALL_TIER=all
      shift
      ;;
    --prune)
      PRUNE=1
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE=1
      shift
      ;;
    --only)
      if [ $# -lt 2 ]; then
        echo "$(basename "$0"): --only requires an argument" >&2
        usage 1 >&2
      fi
      ONLY=$2
      shift 2
      ;;
    --only=*)
      ONLY=${1#--only=}
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

case "$ONLY" in
  "" | uv) ;;
  *)
    echo "$(basename "$0"): --only: unknown part '$ONLY' (supported: uv)" >&2
    exit 1
    ;;
esac

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

# Ask for sudo upfront if we're likely to need it (no --only part needs it)
if [ "$PLATFORM" = "linux" ] && [ -z "$ONLY" ]; then
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

PACKAGE_STAMP="$XDG_CACHE_HOME/dotfiles/last_package_update"

# Returns success (0) if the stamp file exists and was modified within the last
# 24 hours (1 day), and --force was not specified.
function is_fresh {
  local stamp=$1
  [ "$FORCE" -ne 1 ] && [ -f "$stamp" ] && find "$stamp" -maxdepth 0 -mtime -1 2>/dev/null | grep -q .
}

function touch_stamp {
  local stamp=$1
  xmkdir "$(dirname "$stamp")"
  touch "$stamp"
}

function heading {
  printf '# %s\n' "$@"
}

# Echo the space-separated package list for the active INSTALL_TIER, given the
# core, optional, and full sets as $1, $2, $3. core is always included.
function install_set_for_tier {
  case "$INSTALL_TIER" in
    all) printf '%s %s %s' "$1" "$2" "$3" ;;
    optional) printf '%s %s' "$1" "$2" ;;
    *) printf '%s' "$1" ;;
  esac
}

# Report brew leaves that are not in the allowlist ($1, space-separated). With
# --prune, remove them: after a confirmation prompt when interactive, without
# one when non-interactive. Without --prune, warn and leave them in place.
function prune_brew_extras {
  local allowlist=$1
  local extras indented
  extras=$(comm -23 <(brew leaves | sort) <(echo "$allowlist" | tr ' ' '\n' | sort))
  [ -n "$extras" ] || return 0
  # shellcheck disable=SC2001 # sed prefixes every line, including the first
  indented=$(echo "$extras" | sed 's/^/  /')

  if [ "$PRUNE" != 1 ]; then
    echo "warning: unmanaged brew packages present (not in any tier):" >&2
    echo "$indented" >&2
    echo "hint: remove with 'brew remove <pkg>', or re-run with --prune" >&2
    return 0
  fi

  if [ "$NON_INTERACTIVE" = 1 ]; then
    echo "Removing unmanaged brew packages (--prune specified):" >&2
    echo "$indented" >&2
    echo "$extras" | xargs -n 1 brew remove
    return 0
  fi

  echo "The following unmanaged brew packages will be removed:" >&2
  echo "$indented" >&2
  printf 'Remove these packages? [y/N] ' >&2
  local reply=""
  read -r reply || reply=""
  case "$reply" in
    [yY] | [yY][eE][sS])
      echo "$extras" | xargs -n 1 brew remove
      ;;
    *)
      echo "Skipping removal." >&2
      ;;
  esac
}

# Report retired apt packages ($1, space-separated) that are still installed:
# packages this script used to install and no longer does. Unlike brew, apt
# cannot be pruned against an allowlist (it also manages the OS itself), so
# only these explicitly retired names are ever candidates, and only those that
# can go on their own: another installed package may still depend on a retired
# one (e.g. a distribution metapackage that depends on sysstat), and such
# packages are kept. With --prune, remove them, prompting first only when
# interactive (like prune_brew_extras); without it, warn.
function prune_apt_retired {
  local retired=$1
  local candidates pkg changes collateral removable="" indented
  candidates=$(comm -12 <(dpkg-query -W -f='${binary:Package}\t${Status}\n' | awk '$2=="install" && $4=="installed" {print $1}' | sort) <(echo "$retired" | tr ' ' '\n' | sort))
  [ -n "$candidates" ] || return 0

  # apt-get satisfies a removal by also removing everything that depends on
  # the package (or installing an alternative for an `a | b` dependency), so
  # simulate each removal (no root needed) and keep any package whose removal
  # would change anything outside the retired list.
  for pkg in $candidates; do
    if ! changes=$(LC_ALL=C apt-get -s remove --purge "$pkg" 2>/dev/null | awk '/^(Purg|Remv|Inst|Conf) / {print $2}'); then
      [ "$PRUNE" != 1 ] || echo "note: keeping $pkg: could not simulate its removal" >&2
      continue
    fi
    collateral=$(comm -23 <(printf '%s\n' "$changes" | sort -u) <(printf '%s\n' "$retired" | tr ' ' '\n' | sort) | paste -sd ' ' -)
    if [ -n "$collateral" ]; then
      [ "$PRUNE" != 1 ] || echo "note: keeping $pkg: other installed packages depend on it (removing it would also remove or install: $collateral)" >&2
      continue
    fi
    removable="${removable:+$removable }$pkg"
  done
  [ -n "$removable" ] || return 0
  indented=$(echo "$removable" | tr ' ' '\n' | sed 's/^/  /')

  if [ "$PRUNE" != 1 ]; then
    echo "warning: retired apt packages present (no longer managed by this script):" >&2
    echo "$indented" >&2
    echo "hint: remove with 'sudo dpkg --purge <pkg>', or re-run with --prune" >&2
    return 0
  fi

  if [ "$NON_INTERACTIVE" != 1 ]; then
    echo "The following retired apt packages will be removed:" >&2
    echo "$indented" >&2
    printf 'Remove these packages? [y/N] ' >&2
    local reply=""
    read -r reply || reply=""
    case "$reply" in
      [yY] | [yY][eE][sS]) ;;
      *)
        echo "Skipping removal." >&2
        return 0
        ;;
    esac
  else
    echo "Removing retired apt packages (--prune specified):" >&2
    echo "$indented" >&2
  fi
  # dpkg, unlike apt-get, refuses to remove a package that another installed
  # package depends on, so exactly the confirmed packages are removed, never
  # more, even if the system changed since the simulation above.
  # Package names contain no whitespace, so word splitting is intended here.
  # shellcheck disable=SC2086
  x sudo dpkg --purge $removable ||
    echo "warning: dpkg --purge of retired packages failed" >&2
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

# uv: installs uv itself, then fetches everything this repository's uv-based
# scripts download on first use, so they keep working once the network is gone
# (CI jobs, sandboxed cloud agents, planes).
#
# Architecture note: uv is the preferred way to get tools, because it works the
# same on macOS, Debian, CI runners, and cloud containers where brew and apt
# often do not. Skills stay self-contained: a skill's scripts need only uv, and
# fetch their own pinned tools through uvx (or `uv run --script` metadata) on
# first use, so each tool version is pinned in exactly one place. install.sh
# does not duplicate those installs; its uv part only makes sure uv exists and
# warms uv's cache ahead of time. The longer-term aim is to split this script
# into parts that can run on their own; --only is the first step, with a stanza
# becoming a function, selectable with --only, once there is a reason to run it
# alone.

# Bash wrappers that run pinned tools via uvx, each paired (after "|") with a
# small valid input in printf %b notation. A wrapper is warmed by checking that
# input, so it fetches exactly the versions it pins and the pins stay in the
# wrapper; the input must pass, or later tools in the wrapper never run. Add a
# wrapper here when it starts calling uvx. Scripts with a `uv run --script`
# shebang need no entry: they are discovered below.
UVX_WRAPPERS=(
  'skills/coding-standards/scripts/python-format|x = 1'
  'skills/coding-standards/scripts/shell-format|#!/bin/sh\ntrue'
)

# Run a uv command quietly, reporting one git-style status line and, on
# failure, the command's output (indented) so the cause is visible.
function uv_item {
  local ok=$1 bad=$2 label=$3 out
  shift 3
  if [ "$TRACE" = 1 ]; then
    printf '+ %s\n' "$(printf '%q ' "$@")" >&2
  fi
  if out=$("$@" 2>&1); then
    printf '%s  %s\n' "$ok" "$label"
    return 0
  fi
  printf '%s  %s\n' "$bad" "$label" >&2
  # shellcheck disable=SC2001 # sed prefixes every line, including the first
  echo "$out" | sed 's/^/    /' >&2
  return 1
}

# Returns non-zero if anything failed (or, with UV_OFFLINE, is not cached), so
# `--only uv` exits non-zero; a full run only warns.
function stanza_uv {
  heading "uv"

  local offline=0 ok bad failed=0
  case "$(echo "${UV_OFFLINE:-}" | tr '[:upper:]' '[:lower:]')" in
    1 | true | yes | on) offline=1 ;;
  esac
  if [ "$offline" = 1 ]; then
    ok="cached " bad="missing"
  else
    ok="fetched" bad="failed "
  fi

  # The standalone installer puts uv in ~/.local/bin; a full run has already
  # put that on PATH, --only has not.
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac

  # uv is installed via the standalone astral installer on every platform (it
  # is not a brew/apt package here) because many scripts use `uv run` shebangs.
  if ! exists uv; then
    if [ "$offline" = 1 ]; then
      echo "$(basename "$0"): uv not found" >&2
      return 1
    fi
    echo "Installing uv..."
    if ! curl -LsSf https://astral.sh/uv/install.sh | sh || ! exists uv; then
      echo "warning: uv installation failed" >&2
      return 1
    fi
  elif [ -z "$ONLY" ] && ! is_fresh "$PACKAGE_STAMP"; then
    # Periodic upgrades belong to full runs; --only only fills in what is
    # missing, and leaves a uv it did not install (e.g. CI's) alone.
    echo "Updating uv..."
    # `uv self update` only works for the standalone installer; a uv provided
    # by a package manager (e.g. a leftover brew uv mid-migration) will refuse,
    # so warn rather than abort.
    uv self update || echo "warning: uv self update failed (uv may be package-managed)"
    echo "Upgrading uv tools..."
    uv tool upgrade --all || echo "warning: uv tool upgrade failed"
  fi

  # Tools such as shellcheck and shfmt are deliberately not installed on PATH
  # here: the scripts that need them run their own pinned versions via uvx, so
  # a skill needs nothing but uv, and each tool version is pinned in exactly
  # one place (the script). This part only warms uv's cache for those scripts.
  # For an ad-hoc run, use e.g. `uvx --from shellcheck-py==<pin> shellcheck`.

  # Fetch what the repository's scripts need. With UV_OFFLINE, uv builds the
  # same environments from its cache alone, which checks offline readiness
  # (it writes to uv's cache, so it is not read-only).
  local entry rel f first_line
  for entry in "${UVX_WRAPPERS[@]}"; do
    rel=${entry%%|*}
    uv_item "$ok" "$bad" "$rel" "$SRCDIR/$rel" --check \
      <<<"$(printf '%b' "${entry#*|}")" || failed=1
  done
  # bin/ holds symlinks to most skill scripts; skip them to avoid duplicates.
  for f in "$SRCDIR"/bin/* "$SRCDIR"/skills/*/scripts/*; do
    [ -f "$f" ] && [ ! -L "$f" ] || continue
    first_line=""
    read -r first_line <"$f" 2>/dev/null || true
    case "$first_line" in
      '#!/usr/bin/env -S uv run'*)
        uv_item "$ok" "$bad" "${f#"$SRCDIR"/}" uv sync --script "$f" </dev/null || failed=1
        ;;
    esac
  done

  if [ "$failed" != 0 ]; then
    if [ "$offline" = 1 ]; then
      echo "warning: some uv items are not available offline; re-run '$(basename "$0") --only uv' with network access" >&2
    else
      echo "warning: some uv items failed to install or fetch" >&2
    fi
    return 1
  fi
}

if [ -n "$ONLY" ]; then
  "stanza_$ONLY"
  exit $?
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

for src in "${SRCDIRS[@]}"; do
  heading "git pull ($(basename "$src"))"
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

if [ ! -L "$XDG_CONFIG_HOME/fish" ] || [ "$(readlink "$XDG_CONFIG_HOME/fish")" != "$SRCDIR/fish" ]; then

  if [ -d "$XDG_CONFIG_HOME/fish" ] || [ -L "$XDG_CONFIG_HOME/fish" ]; then
    x rm -rf "$XDG_CONFIG_HOME/fish"
  fi
  xmkdir "$XDG_CONFIG_HOME"
  x ln -s "$SRCDIR/fish" "$XDG_CONFIG_HOME/fish"

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

XDG_COMPLETIONS_DIR="$XDG_DATA_HOME/fish/completions"
xmkdir "$XDG_COMPLETIONS_DIR"

if exists hcloud; then
  x hcloud completion fish >"$XDG_COMPLETIONS_DIR/hcloud.fish"
fi

if exists gog; then
  x gog completion fish >"$XDG_COMPLETIONS_DIR/gog.fish"
fi

bat_cmd=""
if exists bat; then
  bat_cmd="bat"
elif exists batcat; then
  bat_cmd="batcat"
fi

if [ -n "$bat_cmd" ]; then
  # bat / batcat --completion was added in 0.25.0; attempt completion generation without halting install.sh on error
  tmp_comp=$(mktemp)
  if "$bat_cmd" --completion fish >"$tmp_comp" 2>/dev/null; then
    x cp "$tmp_comp" "$XDG_COMPLETIONS_DIR/bat.fish"
  fi
  rm -f "$tmp_comp"
fi

# shpool

if exists shpool; then

  heading "shpool"

  xmkdir "$XDG_CONFIG_HOME/shpool"
  link_overlay_path "etc/shpool/config.toml" "$XDG_CONFIG_HOME/shpool/config.toml"

fi

# starship

if exists starship; then

  heading "starship"

  link_overlay_path "etc/starship/starship.toml" "$XDG_CONFIG_HOME/starship.toml"

fi

# ghostty

if exists ghostty; then

  heading "ghostty"

  xmkdir "$XDG_CONFIG_HOME/ghostty"
  link_overlay_path "etc/ghostty/config" "$XDG_CONFIG_HOME/ghostty/config"

fi

# bat

if exists bat || exists batcat; then

  heading "bat"

  xmkdir "$XDG_CONFIG_HOME/bat"
  link_overlay_path "etc/bat/config" "$XDG_CONFIG_HOME/bat/config"

  if ! exists bat && exists batcat; then
    x ln -sf "$(which batcat)" "$BINDIR/bat"
  fi

fi

# Package Management Invariants (Homebrew and apt-get):
# Both Homebrew (macOS) and apt-get (Linux) package management paths enforce four invariants:
# 1. 24-Hour Freshness TTL: Index lists are updated and installed packages are
#    upgraded non-interactively at most once every 24 hours (bypassed with --force).
#    Target package sets are always diffed and missing packages are installed
#    immediately on every run.
# 2. Accurate State Diffing: Target package sets (core/optional/full) are diffed
#    against installed states (via `brew list` or `dpkg-query` filtered by
#    'install ok installed') to prevent redundant installation steps.
# 3. Cache Purging: Downloaded package archives and build caches are purged from
#    disk periodically and after upgrades (brew cleanup, apt-get clean).
# 4. Unmanaged Package Pruning:
#    - Homebrew: As a userland manager, packages outside tier allowlists are
#      reported and pruned when requested (`--prune`).
#    - apt-get: Allowlist-based pruning is unsafe because `apt` manages OS base and
#      system infrastructure; orphaned dependencies are purged via `autoremove --purge`.

if exists brew; then

  heading "brew"

  export HOMEBREW_NO_OUTDATED_FORMULAE_NOTIFIER=1
  export HOMEBREW_NO_ENV_HINTS=1
  export HOMEBREW_NO_ANALYTICS=1

  installed_formulae=$(brew list --formula 2>/dev/null | sort)
  installed_casks=$(brew list --cask 2>/dev/null | sort)

  if ! is_fresh "$PACKAGE_STAMP"; then
    echo "Updating brew (this may prompt for Xcode license agreement)..."
    if ! brew update; then
      echo "$(basename "$0"): brew update failed" >&2
      echo "hint: sudo xcodebuild -license accept" >&2
      exit 1
    fi
  fi

  # The non-HEAD version is years old...
  if ! echo "$installed_formulae" | grep -qx "jed"; then
    x brew install jed --HEAD
  fi

  # Core packages: always installed, on every run.
  core="fish coreutils wget direnv jq mtr htop sevenzip ripgrep chafa node bat"
  # These packages have non-standard installation mechanisms (see above)
  custom="jed"
  # Optional packages: installed only with --install-optional or --install-all.
  # Known packages, so they are kept (not flagged) when present on a core run.
  # ruby-build compiles Ruby for ruby-install/direnv; brew pulls its build deps
  # (openssl, libyaml, readline) automatically.
  optional="imagemagick-full yt-dlp ffmpeg apktool git bundletool scrcpy git-lfs firebase-cli mosquitto gh openclaw/tap/gogcli hcloud entr pv exiftool pidcat yazi fzf pwgen ruby-build rust rustup wasm-bindgen"
  # Full packages: installed only with --install-all. Heaviest or least-used
  # extras; add to this list as needed.
  full=""

  # The allowlist is every package the script knows about. Any `brew leaves`
  # entry outside it is unmanaged: reported, and removed only with --prune.
  allowlist="$core $custom $optional $full"

  install_set=$(install_set_for_tier "$core" "$optional" "$full")

  to_install=$(comm -13 <(echo "$installed_formulae") <(echo "$install_set" | tr ' ' '\n' | sort))
  if [ -n "$to_install" ]; then
    echo "$to_install" | xargs brew install
  fi

  # Special handling for imagemagick-full (needs manual linking due to conflicts)
  if echo "$installed_formulae $to_install" | grep -qw "imagemagick-full"; then
    if ! brew link --dry-run imagemagick-full 2>&1 | grep -q "Already linked"; then
      x brew link --overwrite imagemagick-full
    fi
  fi

  # JDK: Temurin casks are installed below. They land in:
  #   /Library/Java/JavaVirtualMachines/temurin-*.jdk/Contents/Home
  # JAVA_HOME is set in fish/config.fish; consult that for the current value,
  # how to override it for a single command, etc.
  for jdk in temurin@17 temurin@21; do
    if ! echo "$installed_casks" | grep -qx "$jdk"; then
      x brew install --cask "$jdk"
    fi
  done

  if ! is_fresh "$PACKAGE_STAMP"; then
    # Upgrade all installed packages non-interactively
    brew upgrade --no-ask

    prune_brew_extras "$allowlist"

    # Final cleanup of unused dependencies and installer caches from disk
    brew autoremove
    brew cleanup
  elif [ "$PRUNE" = 1 ]; then
    prune_brew_extras "$allowlist"
  fi

fi

if [ "$PLATFORM" = "linux" ]; then

  heading "apt-get"

  if exists apt-get && $HAS_SUDO; then

    if ! is_fresh "$PACKAGE_STAMP"; then
      x sudo apt-get update # refresh package lists
    fi

    # Core packages: always installed, on every run.
    core="apt-file direnv command-not-found dnsutils htop iftop iotop lsof traceroute mtr-tiny whois locate wget curl gnupg zip unzip libxml2-utils jed sqlite3 jq ripgrep chafa bat"
    # Optional packages: installed only with --install-optional or --install-all.
    # The lib*-dev set is Ruby's build toolchain for ruby-build/ruby-install (the
    # ruby-build binary itself is bootstrapped from git below, as the apt package
    # is too old to build current Ruby). rustc (YJIT) is omitted to stay lean.
    optional="pv entr fzf pwgen build-essential autoconf libssl-dev libyaml-dev libreadline-dev zlib1g-dev libffi-dev libgmp-dev libncurses-dev libgdbm-dev gh"
    # Full packages: installed only with --install-all.
    full=""

    # TODO: JDK installation on Linux (not yet documented; see fish/config.fish
    # for context on how JAVA_HOME is set and what the macOS approach looks like)

    install_set=$(install_set_for_tier "$core" "$optional" "$full")

    comm -13 <(dpkg-query -W -f='${binary:Package}\t${Status}\n' | awk '$2=="install" && $4=="installed" {print $1}' | sort) <(echo "$install_set" | tr ' ' '\n' | sort) | xargs -r sudo apt-get -y install || echo "warning: some package installations failed"
    # Full unmanaged package removal is unsafe on Debian/apt because apt manages
    # base system and infrastructure packages beyond dotfiles. Orphaned dependency
    # packages are purged via apt-get autoremove --purge below.

    # Retired packages: ones this script used to install and no longer does.
    # Reported on every run and removed with --prune (see prune_apt_retired).
    #   sysstat, pcp: sysstat recommends pcp, which installs 6 heavyweight
    #     daemon services.
    #   shfmt, shellcheck: now run by the formatter scripts via pinned uvx
    #     (see stanza_uv).
    retired="sysstat pcp shellcheck shfmt"
    prune_apt_retired "$retired"

    # ruby-build: the engine behind ruby-install. Installed alongside the Ruby
    # build deps above whenever the optional/all tier is selected, so the two
    # always arrive together. apt's ruby-build is too old to build current Ruby,
    # so bootstrap a current copy from git into ~/.local (binary at
    # ~/.local/bin/ruby-build, where ruby-install looks for it).
    if [ "$INSTALL_TIER" != core ] && exists git; then
      RUBY_BUILD_SRC="$HOME/.local/share/ruby-build"
      if [ -d "$RUBY_BUILD_SRC/.git" ]; then
        if ! is_fresh "$PACKAGE_STAMP"; then
          x git -C "$RUBY_BUILD_SRC" pull --ff-only || echo "warning: ruby-build update failed"
        fi
      else
        x git clone https://github.com/rbenv/ruby-build.git "$RUBY_BUILD_SRC" || echo "warning: ruby-build clone failed"
      fi
      if [ -x "$RUBY_BUILD_SRC/install.sh" ]; then
        x env PREFIX="$HOME/.local" "$RUBY_BUILD_SRC/install.sh" || echo "warning: ruby-build install failed"
      fi
    fi

    if ! is_fresh "$PACKAGE_STAMP"; then
      # Upgrade installed packages non-interactively
      x sudo apt-get -y upgrade || echo "warning: apt-get upgrade failed, skipping"
      x sudo apt-get -y full-upgrade || echo "warning: apt-get full-upgrade failed, skipping"

      # Try autoremove with --purge, fallback to standard autoremove if restricted, and ignore failure
      x sudo apt-get -y autoremove --purge || x sudo apt-get -y autoremove || echo "warning: apt-get autoremove failed, skipping"

      # Autoclean and clean package archives
      x sudo apt-get -y autoclean || echo "warning: apt-get autoclean failed, skipping"
      x sudo apt-get -y clean || echo "warning: apt-get clean failed, skipping"
    fi

    if [ -f /var/run/reboot-required ]; then
      REBOOT_REQUIRED=1
    fi

  else
    echo "$(basename "$0"): no supported package manager (apt-get) found, skipping" >&2
  fi

fi

# fish: Debian packages an out-of-date fish (trixie ships 4.0.2, but our config
# targets 4.2+), so when fish is missing on Debian 13 we install fish 4 from the
# OpenSUSE Build Service instead of the distro package. Other systems install
# fish themselves (Homebrew on macOS, manually otherwise). If fish is already
# present we leave it untouched and only warn when it predates 4.2.
heading "fish"

FISH_MIN_VERSION="4.2"

if exists fish; then

  # Warn about (but do not replace) an installed fish older than the version our
  # config relies on. `fish --version` prints e.g. "fish, version 4.0.2".
  fish_version=$(fish --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)+' | head -1) || fish_version=""
  if [ -n "$fish_version" ]; then
    fish_major=${fish_version%%.*}
    fish_rest=${fish_version#*.}
    fish_minor=${fish_rest%%.*}
    min_major=${FISH_MIN_VERSION%%.*}
    min_minor=${FISH_MIN_VERSION#*.}
    if [ "$fish_major" -lt "$min_major" ] ||
      { [ "$fish_major" -eq "$min_major" ] && [ "$fish_minor" -lt "$min_minor" ]; }; then
      echo "warning: fish $fish_version is older than $FISH_MIN_VERSION; some config may not work" >&2
      echo "hint: Debian's packaged fish is out of date; see README for fish $FISH_MIN_VERSION+ install instructions" >&2
    fi
  fi

elif [ "$PLATFORM" = "linux" ]; then

  # shellcheck disable=SC1091 # /etc/os-release is provided by the host, not the repo
  read -r os_id os_ver < <(
    . /etc/os-release 2>/dev/null
    printf '%s %s\n' "${ID:-}" "${VERSION_ID:-}"
  )

  if ! { exists apt-get && $HAS_SUDO; }; then
    echo "warning: cannot install fish without apt-get and sudo; install manually (see README)" >&2
  elif [ "$os_id" = debian ] && [ "$os_ver" = 13 ]; then
    echo "Installing fish $FISH_MIN_VERSION+ from the OpenSUSE Build Service (Debian 13)..."
    # https://software.opensuse.org/download.html?project=shells%3Afish%3Arelease%3A4&package=fish
    if echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_13/ /' |
      x sudo tee /etc/apt/sources.list.d/shells:fish:release:4.list >/dev/null &&
      curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:4/Debian_13/Release.key |
      gpg --dearmor |
        x sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg >/dev/null &&
      x sudo apt-get update &&
      x sudo apt-get -y install fish; then
      echo "Installed fish."
    else
      echo "warning: fish installation failed; install manually (see README)" >&2
    fi
  elif [ "$os_id" = ubuntu ]; then
    echo "Installing fish $FISH_MIN_VERSION+ from the official Launchpad PPA (ppa:fish-shell/release-4)..."
    if ! exists add-apt-repository; then
      x sudo apt-get update && x sudo apt-get -y install software-properties-common
    fi
    if x sudo add-apt-repository -y ppa:fish-shell/release-4 &&
      x sudo apt-get update &&
      x sudo apt-get -y install fish; then
      echo "Installed fish."
    else
      echo "warning: fish installation failed; install manually (see README)" >&2
    fi
  else
    echo "warning: fish not available for '${os_id:-unknown} ${os_ver:-?}'; install manually (see README)" >&2
  fi

else
  echo "warning: fish not installed; install it (e.g. 'brew install fish', see README)" >&2
fi

# Defined above, next to --only; failures are reported there and do not stop
# the rest of the run.
stanza_uv || true

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

if exists android || exists compose-preview || [ "$INSTALL_TIER" = "optional" ] || [ "$INSTALL_TIER" = "all" ]; then
  if ! is_fresh "$PACKAGE_STAMP"; then
    heading "android"
    if exists android; then
      x android update || echo "warning: android update failed" >&2
      x android skills update --all || echo "warning: android skills update failed" >&2
    fi
    if exists compose-preview; then
      # MODIFY_PATH=0 suppresses silent PATH modification of shell configs
      # (https://github.com/yschimke/skills/issues/108). Revert once fixed upstream.
      x env CLI_ONLY=1 MODIFY_PATH=0 SKILL_DIR="$XDG_DATA_HOME/compose-preview" \
        compose-preview update || echo "warning: compose-preview update failed" >&2
    fi
  fi
  if ! exists compose-preview && { [ "$INSTALL_TIER" = "optional" ] || [ "$INSTALL_TIER" = "all" ]; }; then
    heading "android"
    # MODIFY_PATH=0 and --no-modify-path work around upstream issue #108.
    x env MODIFY_PATH=0 SKILL_DIR="$XDG_DATA_HOME/compose-preview" \
      bash <(curl -fsSL https://raw.githubusercontent.com/yschimke/skills/main/scripts/install.sh) \
      --cli-only --no-modify-path || echo "warning: compose-preview install failed" >&2
  fi
fi

heading "skill plugins"

# Clean up legacy skill-select configuration and cache
x rm -rf "$XDG_CONFIG_HOME/skill-select"
x rm -rf "$XDG_CACHE_HOME/skill-select"

# Plugins for 'skill' and 'permission'
# (overlay repos provide these under config/<tool>/plugins).
xmkdir "$XDG_CONFIG_HOME/skill/plugins"
link_overlay_files "config/skill/plugins" "$XDG_CONFIG_HOME/skill/plugins"
xmkdir "$XDG_CONFIG_HOME/permission/plugins"
link_overlay_files "config/permission/plugins" "$XDG_CONFIG_HOME/permission/plugins"

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
# by `skill apply` (or `skill add ...`) using ~/.dotfiles/skills (plus .private
# and .corp overlays) as the source. Keeping ~/.agents/skills and
# ~/.claude/skills empty prevents every project from seeing every skill.

if ! is_fresh "$PACKAGE_STAMP"; then

  if exists agy || exists claude || is_codex_agent; then

    heading "agent CLIs"

    if exists agy; then
      x agy update || echo "warning: agy update failed" >&2
    fi
    if exists claude; then
      x claude update || echo "warning: claude update failed" >&2
    fi
    if is_codex_agent; then
      x codex update || echo "warning: codex update failed" >&2
    fi

  fi

  touch_stamp "$PACKAGE_STAMP"

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
