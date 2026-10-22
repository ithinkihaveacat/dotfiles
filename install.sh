#!/usr/bin/env bash
# bash 3.2+ compatible (macOS default). Do not use bash 4+ features
# (declare -A, readarray, ${var,,}, |&).

# Tests: tests/test-install-only (--only), tests/test-install-prune (--prune),
# tests/test-install-profiles (--profile, --with, --without, --dry-run),
# tests/test-install-node (the per-user default Node.js)

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
  echo "  curl -fsSL https://raw.githubusercontent.com/ithinkihaveacat/dotfiles/main/install.sh | bash" >&2
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
# the git-pull feature further down to fast-forward. The low-speed limit makes
# a stalled connection fail instead of hanging a setup script.
if [ ! -f "${BASH_SOURCE[0]:-}" ]; then
  DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
  if [ ! -d "$DOTFILES/.git" ]; then
    command -v git >/dev/null 2>&1 || {
      echo "install.sh: git not found; install git and re-run" >&2
      exit 127
    }
    echo "Cloning dotfiles into $DOTFILES..."
    git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 \
      clone https://github.com/ithinkihaveacat/dotfiles.git "$DOTFILES"
    git -C "$DOTFILES" remote set-url origin --push \
      git@github.com:ithinkihaveacat/dotfiles.git
  fi
  exec "$DOTFILES/install.sh" "$@"
fi

# Features: the parts of this script, in the order they run. Each entry is
# "name|profiles|description"; a profile runs the features that list it, and
# --with/--without/--only adjust that. A feature with no profile runs only when
# named. Most features are a function named feature_ plus the name (with - as
# _), run in a subshell, so a failure is reported and the remaining features
# still run. Package features (PACKAGE_FEATURES) contribute their packages
# (packages_of) to one shared install step, which runs before the first of
# them; some also have a function for setup beyond packages.
#
# When adding a feature, decide which profiles it belongs to: "workstation" is
# a long-lived machine for interactive use (a bare run); "cloud" is a
# disposable container's setup script, often with no sudo and an egress
# allowlist, so it takes only features that need no sudo, upgrade nothing, and
# reach no host beyond GitHub and uv's package index; "ci" is just what CI jobs
# need.
FEATURES=(
  'git-pull|workstation|Fast-forward ~/.dotfiles and its overlays'
  'links|workstation cloud|Symlink dotfiles into the home directory, fish and tool configs'
  'macos|workstation|Key bindings, system defaults, colors, git keychain (macOS)'
  'fish-completions|workstation|Regenerate fish completions'
  'base|workstation|Core command-line packages, and fish from its own repository'
  'cli-extras|workstation|gh, git-lfs, fzf, yazi, and other interactive tools'
  'services|-|Hetzner Cloud and gog CLIs'
  'media|-|ImageMagick, FFmpeg, yt-dlp, ExifTool'
  'android|-|Android SDK tools, Android CLI, compose-preview, JDKs, gradle settings'
  'ruby|-|ruby-build and the dependencies for building Ruby'
  'uv|workstation cloud ci|Install uv if missing; prefetch what scripts fetch on first use'
  'vscode|workstation|Link VS Code settings'
  'npm|workstation|Set the npm global prefix; a per-user Node.js where the distribution'"'"'s is too old'
  'cloudflare|-|Cloudflare'"'"'s cf CLI (beta) from npm, with its telemetry off'
  'skills|workstation cloud|Link skill and permission plugins; apply default skills'
  'agents|workstation|Link agent context and hooks, and synchronize permissions'
  'upgrades|workstation|Daily: upgrade packages, uv, ruby-build, Android and agent CLIs'
  'overlay-hooks|workstation|Run each overlay'"'"'s update hook'
)
PROFILES="workstation cloud ci"
PACKAGE_FEATURES="base cli-extras services media android ruby"

# Print each feature's name and description for --help, then each profile's
# features.
function features_help {
  local entry name rest profile list
  for entry in "${FEATURES[@]}"; do
    name=${entry%%|*}
    rest=${entry#*|}
    printf '  %-17s %s\n' "$name" "${rest#*|}"
  done
  echo
  echo "PROFILES:"
  for profile in $PROFILES; do
    list=""
    for entry in "${FEATURES[@]}"; do
      rest=${entry#*|}
      if [[ " ${rest%%|*} " == *" $profile "* ]]; then
        list="${list:+$list }${entry%%|*}"
      fi
    done
    printf '%s\n' "$list" | fold -s -w 60 | {
      read -r line
      printf '  %-17s %s\n' "$profile" "$line"
      while read -r line; do
        printf '  %-17s %s\n' "" "$line"
      done
    }
  done
}

# Show usage information
function usage {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Sets up and updates this machine from ~/.dotfiles: symlinks dotfiles into
place, installs packages, and wires up tool-specific config. Safe to run
repeatedly; an existing checkout is fast-forwarded first.

Can also be run directly from the network, which clones the repo to ~/.dotfiles
(if absent) before installing:

  curl -fsSL https://raw.githubusercontent.com/ithinkihaveacat/dotfiles/main/install.sh | bash

The work is split into features, and a profile picks which of them run. The
default, workstation, sets up a long-lived machine for interactive use; cloud
is for the setup script of a disposable cloud or agent container, and uses no
sudo, installs no packages, and upgrades nothing. Features in no profile run
only when named with --with or --only. A failing feature is reported and the
others still run; the exit status is non-zero if any failed.

OPTIONS:
  -h, --help    Show this help message and exit
  --profile NAME
                Run the features of profile NAME (default: workstation)
  --with FEATURE[,FEATURE...]
                Also run these features
  --without FEATURE[,FEATURE...]
                Do not run these features
  --only FEATURE[,FEATURE...]
                Run only these features, in their usual order. Cannot be
                combined with --profile or --with
  -n, --dry-run Print the features that would run, one per line, and exit
  --force       Replace existing real files with links, and run the daily
                upgrades even if they ran in the last 24 hours
  --prune       Remove brew packages that no feature installs, and apt packages
                this script has retired (keeping any that other installed
                packages depend on). Asks first when interactive; otherwise
                --prune is the consent. Default: warn only
  --no-input    Never prompt; use sudo only if it needs no password
  --verbose     Print each wrapped command to stderr before running it

FEATURES:
$(features_help)

ENVIRONMENT:
  AGENT_OFFLINE Set to 1 to make no network requests: features that need the
                network are skipped (and say so), and uv works from its cache
                as with UV_OFFLINE
  UV_OFFLINE    Set to 1 to have the uv feature check offline readiness
                without the network: nothing is downloaded or put on PATH, but
                each script's environment is (re)built inside uv's cache from
                packages already there, which is what proves it works.
                Fails, naming each item, if any package is missing

EXAMPLES:
  $(basename "$0")                    # Set up or update this machine
  $(basename "$0") --with android,ruby  # Also install Android and Ruby tooling
  $(basename "$0") --prune            # Also remove packages no feature installs
  $(basename "$0") --without upgrades # Skip the daily upgrades
  $(basename "$0") --profile cloud    # From a cloud environment's setup script
  $(basename "$0") --only uv          # Prepare a CI job for offline use
  UV_OFFLINE=1 $(basename "$0") --only uv  # Check it is ready, without the network
  $(basename "$0") --profile cloud --with android -n  # Preview a selection

  # Install/update over the network, passing flags after '-s --':
  curl -fsSL https://raw.githubusercontent.com/ithinkihaveacat/dotfiles/main/install.sh | bash -s -- --profile cloud

EOF
  exit "${1:-0}"
}

# Returns success if $1 is the name of a feature.
function is_feature {
  local entry
  for entry in "${FEATURES[@]}"; do
    if [ "${entry%%|*}" = "$1" ]; then
      return 0
    fi
  done
  return 1
}

# Validate a comma-separated feature list given to option $1, and print it
# space-separated.
function feature_list {
  local option=$1 names name
  names=$(printf '%s' "$2" | tr ',' ' ')
  if [ -z "${names// /}" ]; then
    echo "$(basename "$0"): $option requires a feature name" >&2
    return 1
  fi
  for name in $names; do
    if ! is_feature "$name"; then
      echo "$(basename "$0"): $option: unknown feature '$name'" >&2
      echo "hint: see '$(basename "$0") --help' for the list of features" >&2
      return 1
    fi
  done
  printf '%s' "$names"
}

VERBOSE=0
FORCE=0
HAS_SUDO=false
NON_INTERACTIVE=0
NO_INPUT=0
PRUNE=0
DRY_RUN=0
PROFILE=""
ONLY=""
WITH=""
WITHOUT=""

# XDG Base Directory specification defaults
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Options that take a value accept it as the next argument or after "=".
function option_value {
  if [ $# -lt 2 ] || [ -z "$2" ]; then
    echo "$(basename "$0"): $1 requires an argument" >&2
    usage 1 >&2
  fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --*=*)
      # Split --option=value into two arguments.
      opt=${1%%=*}
      val=${1#*=}
      shift
      set -- "$opt" "$val" "$@"
      continue
      ;;
  esac
  case $1 in
    -h | --help)
      usage 0
      ;;
    --verbose)
      VERBOSE=1
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --prune)
      PRUNE=1
      shift
      ;;
    --no-input)
      NON_INTERACTIVE=1
      NO_INPUT=1
      shift
      ;;
    -n | --dry-run)
      DRY_RUN=1
      shift
      ;;
    --profile)
      option_value "$@"
      case " $PROFILES " in
        *" $2 "*) ;;
        *)
          echo "$(basename "$0"): --profile: unknown profile '$2' (supported: $PROFILES)" >&2
          exit 1
          ;;
      esac
      PROFILE=$2
      shift 2
      ;;
    --with | --without | --only)
      option_value "$@"
      names=$(feature_list "$1" "$2")
      case $1 in
        --with) WITH="$WITH $names" ;;
        --without) WITHOUT="$WITHOUT $names" ;;
        --only) ONLY="$ONLY $names" ;;
      esac
      shift 2
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

if [ -n "$ONLY" ] && [ -n "$PROFILE$WITH" ]; then
  echo "$(basename "$0"): --only cannot be combined with --profile or --with" >&2
  exit 1
fi

# Resolve the selection to a space-separated list in FEATURES order.
SELECTED=""
for entry in "${FEATURES[@]}"; do
  name=${entry%%|*}
  rest=${entry#*|}
  if [ -n "$ONLY" ]; then
    [[ " $ONLY " == *" $name "* ]] || continue
  elif [[ " ${rest%%|*} " != *" ${PROFILE:-workstation} "* && " $WITH " != *" $name "* ]]; then
    continue
  fi
  [[ " $WITHOUT " != *" $name "* ]] || continue
  SELECTED="${SELECTED:+$SELECTED }$name"
done

if [ "$DRY_RUN" = 1 ]; then
  for name in $SELECTED; do
    printf '%s\n' "$name"
  done
  exit 0
fi

# Returns success if feature $1 is selected.
function selected {
  [[ " $SELECTED " == *" $1 "* ]]
}

# Returns success if any package feature is selected.
function packages_selected {
  local name
  for name in $PACKAGE_FEATURES; do
    if selected "$name"; then
      return 0
    fi
  done
  return 1
}

# A cloud container's setup script should say what it wants rather than get a
# workstation run; the variables only describe where we are, so warn rather
# than switch profile.
if [ -z "$PROFILE$ONLY" ] && [ -n "${CLAUDE_CODE_REMOTE:-}${CODESPACES:-}${CI:-}" ]; then
  echo "warning: this looks like a cloud or CI environment, but the workstation profile is running" >&2
  echo "hint: for a setup script, use '$(basename "$0") --profile cloud'" >&2
fi

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
if [ "$PLATFORM" = "linux" ]; then
  export DEBIAN_FRONTEND="noninteractive"
fi

# Returns success if AGENT_OFFLINE asks for no network requests.
function is_offline {
  case "$(echo "${AGENT_OFFLINE:-}" | tr '[:upper:]' '[:lower:]')" in
    1 | true | yes | on) return 0 ;;
  esac
  return 1
}

# Report that a step was skipped because it needs the network.
function skip_offline {
  echo "skipped: $1 (AGENT_OFFLINE is set)" >&2
}

# Offline, uv must also work from its cache alone: uv-based scripts (including
# `skill`) and the uv feature's readiness check both read UV_OFFLINE.
if is_offline; then
  export UV_OFFLINE=1
fi

# Bounded network requests: fail on a dropped connection instead of hanging a
# setup script until the platform kills it.
CURL_OPTS=(--connect-timeout 15 --max-time 300)
GIT_NET_OPTS=(-c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60)

# Runs the command, optionally logging it first when --verbose is set.
function x {
  if [ "$VERBOSE" = 1 ]; then
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

# Print the packages package feature $1 installs with manager $2: "brew"
# (formulae), "cask" (brew casks), or "apt". Only direct needs are listed;
# brew and apt pull in dependencies (such as rust) themselves.
function packages_of {
  case "$1:$2" in
    base:brew) echo "fish coreutils wget direnv jq mtr htop sevenzip ripgrep fd chafa node bat" ;;
    base:apt) echo "fish apt-file direnv command-not-found dnsutils htop btop iftop iotop lsof traceroute mtr-tiny whois locate wget curl gnupg zip unzip libxml2-utils jed sqlite3 jq ripgrep fd-find chafa bat ruby ruby-dev" ;;
    cli-extras:brew) echo "git git-lfs gh fzf pv entr pwgen yazi" ;;
    cli-extras:apt) echo "gh fzf pv entr pwgen" ;;
    services:brew) echo "hcloud openclaw/tap/gogcli" ;;
    media:brew) echo "imagemagick-full ffmpeg yt-dlp exiftool" ;;
    android:brew) echo "apktool bundletool scrcpy jadx pidcat" ;;
    android:apt) echo "apktool scrcpy pidcat" ;;
    # JAVA_HOME is set in fish/config.fish; consult that for the current
    # value, how to override it for a single command, etc.
    android:cask) echo "temurin@17 temurin@21" ;;
    # brew pulls ruby-build's build deps (openssl, libyaml, readline) itself;
    # on Linux, ruby-build itself is bootstrapped from git (feature_ruby).
    ruby:brew) echo "ruby-build" ;;
    ruby:apt) echo "build-essential autoconf libssl-dev libyaml-dev libreadline-dev zlib1g-dev libffi-dev libgmp-dev libncurses-dev libgdbm-dev" ;;
  esac
}

# Print the packages that the package features named in $2 (space-separated)
# install with manager $1.
function packages_for {
  local manager=$1 name list=""
  for name in $2; do
    list="$list $(packages_of "$name" "$manager")"
  done
  printf '%s' "$list"
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
    echo "warning: unmanaged brew packages present (installed by no feature):" >&2
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

# Point apt at fish's own release-4 repository, since distributions package an
# out-of-date fish (trixie ships 4.0.2; the transient prompt needs 4.1+): the
# OpenSUSE Build Service on Debian 13, the Launchpad PPA on Ubuntu. Elsewhere
# the distribution's fish is used. Returns success only if the repository was
# just configured, in which case the caller must refresh the package lists and
# reinstall fish.
function configure_fish_apt_repo {
  local os_id os_ver
  # shellcheck disable=SC1091 # /etc/os-release is provided by the host, not the repo
  read -r os_id os_ver < <(
    . /etc/os-release 2>/dev/null
    printf '%s %s\n' "${ID:-}" "${VERSION_ID:-}"
  )
  if [ "$os_id" = debian ] && [ "$os_ver" = 13 ]; then
    # https://software.opensuse.org/download.html?project=shells%3Afish%3Arelease%3A4&package=fish
    local url="https://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_13/"
    local key=/usr/share/keyrings/fish-shell.asc
    local list=/etc/apt/sources.list.d/fish-shell.list
    local line="deb [signed-by=$key] $url /"
    if [ -f "$key" ] && [ "$(cat "$list" 2>/dev/null)" = "$line" ]; then
      return 1
    fi
    echo "Configuring the fish apt repository (OpenSUSE Build Service)..."
    local tmp_key status=0
    tmp_key=$(mktemp)
    { curl "${CURL_OPTS[@]}" -fsSL -o "$tmp_key" "${url}Release.key" &&
      x sudo install -m 644 "$tmp_key" "$key" &&
      echo "$line" | x sudo tee "$list" >/dev/null; } || status=$?
    rm -f "$tmp_key"
    if [ "$status" -ne 0 ]; then
      echo "warning: failed to configure the fish apt repository from $url" >&2
      return 1
    fi
  elif [ "$os_id" = ubuntu ]; then
    if grep -rqs 'fish-shell/release-4' /etc/apt/sources.list.d; then
      return 1
    fi
    echo "Configuring the fish apt repository (ppa:fish-shell/release-4)..."
    if ! { exists add-apt-repository || x sudo apt-get -y install software-properties-common; } ||
      ! x sudo add-apt-repository -y ppa:fish-shell/release-4; then
      echo "warning: failed to add ppa:fish-shell/release-4" >&2
      return 1
    fi
  else
    return 1
  fi
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

# ~/.local/bin holds links made by several features, the standalone uv, and
# ruby-build; features that write to it create it first.
BINDIR="$HOME/.local/bin"
case ":$PATH:" in
  *":$BINDIR:"*) ;;
  *) export PATH="$BINDIR:$PATH" ;;
esac

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

# Pull each source repo to its upstream before applying. Mirrors the `git up`
# alias in ~/.gitconfig. Non-fast-forward or detached states are surfaced as
# errors via --ff-only so they can't be silently skipped.
git_up() {
  local dir=$1
  [ -d "$dir/.git" ] || return 0
  if ! git -C "$dir" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
    return 0
  fi
  x git "${GIT_NET_OPTS[@]}" -C "$dir" remote update -p
  x git -C "$dir" merge --ff-only '@{upstream}'
}

function feature_git_pull {
  local src
  if is_offline; then
    skip_offline "git pull"
    return 0
  fi
  for src in "${SRCDIRS[@]}"; do
    heading "git pull ($(basename "$src"))"
    git_up "$src"
  done
}

# "dotfiles" that will end up in $HOME

link_home_dotfiles() {
  local src=$1 f
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

function feature_links {
  local src f target

  heading "links"

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

  xmkdir "$BINDIR"

  heading "fish"

  # Fish configuration needs to be in ~/.config/fish
  if [ ! -L "$XDG_CONFIG_HOME/fish" ] || [ "$(readlink "$XDG_CONFIG_HOME/fish")" != "$SRCDIR/fish" ]; then
    if [ -d "$XDG_CONFIG_HOME/fish" ] || [ -L "$XDG_CONFIG_HOME/fish" ]; then
      x rm -rf "$XDG_CONFIG_HOME/fish"
    fi
    xmkdir "$XDG_CONFIG_HOME"
    x ln -s "$SRCDIR/fish" "$XDG_CONFIG_HOME/fish"
  fi

  if exists shpool; then
    heading "shpool"
    xmkdir "$XDG_CONFIG_HOME/shpool"
    link_overlay_path "etc/shpool/config.toml" "$XDG_CONFIG_HOME/shpool/config.toml"
  fi

  if exists starship; then
    heading "starship"
    link_overlay_path "etc/starship/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
  fi

  if exists ghostty; then
    heading "ghostty"
    xmkdir "$XDG_CONFIG_HOME/ghostty"
    link_overlay_path "etc/ghostty/config" "$XDG_CONFIG_HOME/ghostty/config"
  fi

  if exists bat || exists batcat; then
    heading "bat"
    xmkdir "$XDG_CONFIG_HOME/bat"
    link_overlay_path "etc/bat/config" "$XDG_CONFIG_HOME/bat/config"
    if ! exists bat && exists batcat; then
      x ln -sf "$(which batcat)" "$BINDIR/bat"
    fi
  fi

  if ! exists fd && exists fdfind; then
    heading "fd"
    x ln -sf "$(which fdfind)" "$BINDIR/fd"
  fi
}

# Apply macOS defaults (system preferences), grouped by application. Safe to
# re-run. Based on:
#   https://github.com/mathiasbynens/dotfiles/blob/master/.macos
#   https://github.com/hjuutilainen/dotfiles/blob/master/bin/osx-user-defaults.sh
#
# To find the bundle identifier of an app:
#   osascript -e 'id of app "Safari"'   # => com.apple.Safari
#
# To find what setting to change (fish shell):
#   vimdiff (defaults read -g | psub) (read -p "echo 'Make change, press enter' > "; and defaults read -g | psub)
#   vimdiff (defaults read pro.writer.mac | psub) (read -p "echo 'Make change, press enter' > "; and defaults read pro.writer.mac | psub)
function macos_defaults {
  # System

  # NSUserKeyEquivalent modifiers: @ Command, ^ Control, ~ Option, $ Shift
  defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
  defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
  defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
  defaults write -g WebAutomaticSpellingCorrectionEnabled -bool false
  defaults write -g NSAutomaticCapitalizationEnabled -bool false
  # Don't convert double space to period + double space
  defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
  # Don't show suggestions on the Touch Bar
  defaults write -g NSAutomaticTextCompletionEnabled -bool false
  defaults write -g NSDocumentSaveNewDocumentsToCloud -bool false
  # Speed up mouse (requires logout to take effect)
  defaults write -g com.apple.mouse.scaling -float 6
  defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string TwoButton
  defaults write -g AppleShowAllExtensions -int 1
  # Paste and Match Style on cmd-v http://apple.stackexchange.com/a/167649/890
  defaults write -g NSUserKeyEquivalents -dict-add "Paste and Match Style" -string "@v"

  # Finder

  defaults write com.apple.finder _FXSortFoldersFirst -int 1
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
  defaults write com.apple.finder NewWindowTarget -string PfHm

  # Terminal

  # Disable "marks" http://apple.stackexchange.com/a/209907/890
  defaults write com.apple.Terminal AutoMarkPromptLines -int 0

  # Photos

  # Don't open automatically when external media is connected
  defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

  # Messages

  defaults write com.apple.messageshelper.MessageController SOInputLineSettings \
    -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false
  defaults write com.apple.messageshelper.MessageController SOInputLineSettings \
    -dict-add "automaticQuoteSubstitutionEnabled" -bool false
  defaults write com.apple.messageshelper.MessageController SOInputLineSettings \
    -dict-add "automaticDashSubstitutionEnabled" -bool false
  defaults write com.apple.messageshelper.MessageController SOInputLineSettings \
    -dict-add "automaticSpellingCorrectionEnabled" -bool false

  # Spotlight
  #
  # To regenerate this array from current settings:
  #   defaults read com.apple.Spotlight orderedItems | sed -E -e 's/^[[:space:]]+//g' | tr -d '()\n' | tr ',' '\n'

  defaults write com.apple.Spotlight orderedItems -array \
    '{enabled = 1;name = APPLICATIONS;}' \
    '{enabled = 0;name = "MENU_SPOTLIGHT_SUGGESTIONS";}' \
    '{enabled = 1;name = "MENU_CONVERSION";}' \
    '{enabled = 1;name = "MENU_EXPRESSION";}' \
    '{enabled = 1;name = "MENU_DEFINITION";}' \
    '{enabled = 1;name = "SYSTEM_PREFS";}' \
    '{enabled = 0;name = DOCUMENTS;}' \
    '{enabled = 0;name = DIRECTORIES;}' \
    '{enabled = 0;name = PRESENTATIONS;}' \
    '{enabled = 0;name = SPREADSHEETS;}' \
    '{enabled = 0;name = PDF;}' \
    '{enabled = 0;name = MESSAGES;}' \
    '{enabled = 1;name = CONTACT;}' \
    '{enabled = 0;name = "EVENT_TODO";}' \
    '{enabled = 0;name = IMAGES;}' \
    '{enabled = 0;name = BOOKMARKS;}' \
    '{enabled = 0;name = MUSIC;}' \
    '{enabled = 0;name = MOVIES;}' \
    '{enabled = 0;name = FONTS;}' \
    '{enabled = 0;name = "MENU_OTHER";}' \
    '{enabled = 0;name = "MENU_WEBSEARCH";}' \
    '{enabled = 0;name = SOURCE;}'

  # iA Writer

  # Bind cmd-n to new file (instead of new file in library)
  defaults write pro.writer.mac NSUserKeyEquivalents -dict-add "New" -string "@n"
  defaults write pro.writer.mac "Document Path Extension" -string "md"
  defaults write pro.writer.mac nightMode -int 0
  defaults write pro.writer.mac "Editor Indent Using Spaces" -int 1
  # Use "Quattro" font
  defaults write pro.writer.mac "Editor Typeface" -int 2
  defaults write pro.writer.mac "Preview Center Headings" -int 0
  defaults write pro.writer.mac "Markdown Smart Punctuation Enabled" -int 1
  defaults write pro.writer.mac "Library Show Extension" -int 1
  defaults write pro.writer.mac "Library Shows Search Bar" -int 0
  defaults write pro.writer.mac "Organizer Shows Favorites" -int 0
  defaults write pro.writer.mac "Organizer Shows Hashtags" -int 1
  defaults write pro.writer.mac "Organizer Shows Smart Folders" -int 1
  defaults write pro.writer.mac "Template Identifier" -string "net.ia.writer.template.github"
  defaults write pro.writer.mac "Editor Line Length Limit" -int 72
  # Library sort order (folders first, by name) must be set manually via
  # Preferences > Library, as it is stored in a binary NSKeyedArchiver blob
  # that cannot be reproduced with a plain defaults write.

  # Firefox

  # Bind cmd-opt-j to Web Console, to match Chrome
  defaults write org.mozilla.firefox NSUserKeyEquivalents -dict-add "Web Console" -string "@~j"
}

function feature_macos {
  local keybindings_dir solarized_clr

  [ "$PLATFORM" = darwin ] || return 0

  heading "macos"
  xmkdir "$BINDIR"

  # For some reason *some* applications (like TextEdit) won't read
  # DefaultKeyBinding.dict if it's symlinked, or is in a symlinked directory,
  # so rsync instead of symlink... http://apple.stackexchange.com/a/53110/890
  # rdar://12429092
  keybindings_dir=$(overlay_path "etc/macos/KeyBindings") || keybindings_dir=""
  if [ -n "$keybindings_dir" ]; then
    x rsync -a --delete "$keybindings_dir/" "$DSTDIR/Library/KeyBindings/"
  fi

  macos_defaults

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

  heading "git"
  git config --file ~/.gitconfig.local credential.helper osxkeychain
}

function feature_fish_completions {
  local fish_completions_dir completions_dir bat_cmd="" tmp_comp

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

  completions_dir="$XDG_DATA_HOME/fish/completions"
  xmkdir "$completions_dir"

  if exists hcloud; then
    x hcloud completion fish >"$completions_dir/hcloud.fish"
  fi

  if exists gog; then
    x gog completion fish >"$completions_dir/gog.fish"
  fi

  if exists bat; then
    bat_cmd="bat"
  elif exists batcat; then
    bat_cmd="batcat"
  fi

  if [ -n "$bat_cmd" ]; then
    # bat / batcat --completion was added in 0.25.0; attempt completion generation without halting install.sh on error
    tmp_comp=$(mktemp)
    if "$bat_cmd" --completion fish >"$tmp_comp" 2>/dev/null; then
      x cp "$tmp_comp" "$completions_dir/bat.fish"
    fi
    rm -f "$tmp_comp"
  fi
}

# Packages (Homebrew and apt-get):
# 1. The selected package features' packages are diffed against what is
#    installed (`brew list`, or `dpkg-query` filtered by 'install ok
#    installed'), and only the missing ones are installed, on every run.
# 2. The package index is refreshed at most once every 24 hours (bypassed with
#    --force); upgrading what is installed is the upgrades feature's job.
# 3. Unmanaged packages:
#    - Homebrew: As a userland manager, leaves outside every package feature
#      (selected or not) are reported, and removed with --prune.
#    - apt-get: Allowlist-based pruning is unsafe because apt also manages the
#      OS itself, so only packages this script has retired are candidates;
#      orphaned dependencies are purged by `autoremove --purge` in upgrades.

# Install the packages of the package features in $1 (space-separated).
function packages_brew {
  local features=$1 installed_formulae installed_casks allowlist
  local to_install cask

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
  if [[ " $features " == *" base "* ]] && ! echo "$installed_formulae" | grep -qx "jed"; then
    x brew install jed --HEAD
  fi

  to_install=$(comm -13 <(echo "$installed_formulae") <(packages_for brew "$features" | tr ' ' '\n' | sed '/^$/d' | sort))
  if [ -n "$to_install" ]; then
    echo "$to_install" | xargs brew install
  fi

  # Special handling for imagemagick-full (needs manual linking due to conflicts)
  if echo "$installed_formulae $to_install" | grep -qw "imagemagick-full"; then
    if ! brew link --dry-run imagemagick-full 2>&1 | grep -q "Already linked"; then
      x brew link --overwrite imagemagick-full
    fi
  fi

  for cask in $(packages_for cask "$features"); do
    if ! echo "$installed_casks" | grep -qx "$cask"; then
      x brew install --cask "$cask"
    fi
  done

  # The allowlist is every package any feature installs (jed is installed
  # --HEAD above). Any `brew leaves` entry outside it is unmanaged.
  allowlist="jed $(packages_for brew "$PACKAGE_FEATURES")"
  prune_brew_extras "$allowlist"
}

# Install the packages of the package features in $1 (space-separated).
function packages_apt {
  local features=$1 install_set retired node_major

  heading "apt-get"

  if ! exists apt-get; then
    echo "$(basename "$0"): no supported package manager (apt-get) found, skipping" >&2
    return 0
  fi
  if ! $HAS_SUDO; then
    echo "$(basename "$0"): no usable sudo, skipping apt-get" >&2
    return 0
  fi

  if ! is_fresh "$PACKAGE_STAMP"; then
    x sudo apt-get update # refresh package lists
  fi

  # TODO: JDK installation on Linux (not yet documented; see fish/config.fish
  # for context on how JAVA_HOME is set and what the macOS approach looks like)

  install_set=$(packages_for apt "$features")

  # Node.js comes from the distribution only when it is recent enough;
  # otherwise the npm feature makes a per-user default (see sync_node_default)
  # and the distribution's npm is retired below, so that nothing writes to the
  # shared npm prefix with an old npm.
  node_major=$(deb_major nodejs candidate)
  if [ -n "$node_major" ] && [ "$node_major" -ge "$NODE_MIN_MAJOR" ]; then
    if [[ " $features " == *" base "* ]]; then
      install_set="$install_set nodejs npm"
    fi
  else
    node_major=""
  fi

  comm -13 <(dpkg-query -W -f='${binary:Package}\t${Status}\n' | awk '$2=="install" && $4=="installed" {print $1}' | sort) <(echo "$install_set" | tr ' ' '\n' | sed '/^$/d' | sort) | xargs -r sudo apt-get -y install || echo "warning: some package installations failed"

  # An installed nodejs that is too old is not in the list above (its name is
  # installed), so upgrade it when the candidate is new enough, e.g. part way
  # through a release upgrade; the npm feature then drops the per-user default
  # in the same run.
  if [ -n "$node_major" ] && [[ " $features " == *" base "* ]] && node_default_needed; then
    x sudo apt-get -y install nodejs || echo "warning: nodejs upgrade failed"
  fi

  if ! exists fd && exists fdfind; then
    xmkdir "$BINDIR"
    x ln -sf "$(which fdfind)" "$BINDIR/fd"
  fi

  # fish is in base, so on a fresh machine it first arrives from the
  # distribution; switching repositories then upgrades it in place.
  if [[ " $features " == *" base "* ]] && configure_fish_apt_repo; then
    { x sudo apt-get update && x sudo apt-get -y install fish; } ||
      echo "warning: fish installation from its apt repository failed" >&2
  fi

  # Retired packages: ones this script used to install and no longer does.
  # Reported on every run and removed with --prune (see prune_apt_retired).
  #   sysstat, pcp: sysstat recommends pcp, which installs 6 heavyweight
  #     daemon services.
  # shfmt, shellcheck: now run by the formatter scripts via uv (see feature_uv).
  #   npm: only where the distribution's nodejs is too old (see above); the
  #     nodejs package itself stays, since other packages depend on it.
  retired="sysstat pcp shellcheck shfmt"
  [ -n "$node_major" ] || retired="$retired npm"
  prune_apt_retired "$retired"
}

# The install step shared by the package features; runs once, before the
# first selected one.
function install_packages {
  local features="" name
  if is_offline; then
    skip_offline "packages"
    return 0
  fi
  for name in $PACKAGE_FEATURES; do
    if selected "$name"; then
      features="$features $name"
    fi
  done
  if exists brew; then
    packages_brew "$features"
  fi
  if [ "$PLATFORM" = "linux" ]; then
    packages_apt "$features"
  fi
}

# upgrades: everything that only needs doing now and then on a long-lived
# machine, at most once every 24 hours (bypassed with --force). It upgrades
# whatever is installed, whichever features installed it, so a tool added
# once with --with stays current on later bare runs. Each step only warns on
# failure, so one broken upgrade does not hold back the rest.
function feature_upgrades {
  local ruby_build_src="$HOME/.local/share/ruby-build"

  if is_fresh "$PACKAGE_STAMP"; then
    echo "upgrades: ran in the last 24 hours; skipping (--force to run now)"
    return 0
  fi
  if is_offline; then
    skip_offline "upgrades"
    return 0
  fi

  if exists brew; then
    heading "brew upgrade"
    # The package step refreshes the index itself when it runs.
    if ! packages_selected; then
      brew update || echo "warning: brew update failed" >&2
    fi
    brew upgrade --no-ask || echo "warning: brew upgrade failed" >&2
    # Remove unused dependencies and installer caches from disk
    brew autoremove || echo "warning: brew autoremove failed" >&2
    brew cleanup || echo "warning: brew cleanup failed" >&2
  fi

  if [ "$PLATFORM" = "linux" ] && exists apt-get; then
    heading "apt-get upgrade"
    if ! $HAS_SUDO; then
      echo "$(basename "$0"): no usable sudo, skipping apt-get upgrade" >&2
    else
      if ! packages_selected; then
        x sudo apt-get update || echo "warning: apt-get update failed" >&2
      fi
      x sudo apt-get -y upgrade || echo "warning: apt-get upgrade failed, skipping" >&2
      x sudo apt-get -y full-upgrade || echo "warning: apt-get full-upgrade failed, skipping" >&2
      # Try autoremove with --purge, fallback to standard autoremove if restricted, and ignore failure
      x sudo apt-get -y autoremove --purge || x sudo apt-get -y autoremove || echo "warning: apt-get autoremove failed, skipping" >&2
      # Autoclean and clean package archives
      x sudo apt-get -y autoclean || echo "warning: apt-get autoclean failed, skipping" >&2
      x sudo apt-get -y clean || echo "warning: apt-get clean failed, skipping" >&2
    fi
  fi

  # Only an existing default is upgraded (or removed, if a package upgrade made
  # it unnecessary); the npm feature is what creates one.
  if [ -L "$NODE_DEFAULT_LINK" ]; then
    heading "node upgrade"
    sync_node_default upgrade || echo "warning: node upgrade failed" >&2
  fi

  # Only packages a feature installed; the cloudflare feature installs cf.
  if exists npm && [ -x "$NPM_PREFIX/bin/cf" ]; then
    heading "npm upgrade"
    x npm install -g --prefix "$NPM_PREFIX" cf@latest || echo "warning: cf upgrade failed" >&2
  fi

  if exists uv; then
    heading "uv upgrade"
    # `uv self update` only works for the standalone installer; a uv provided
    # by a package manager (e.g. a leftover brew uv mid-migration) will refuse,
    # so warn rather than abort.
    uv self update || echo "warning: uv self update failed (uv may be package-managed)" >&2
    uv tool upgrade --all || echo "warning: uv tool upgrade failed" >&2
  fi

  if [ -d "$ruby_build_src/.git" ]; then
    heading "ruby-build upgrade"
    { x git "${GIT_NET_OPTS[@]}" -C "$ruby_build_src" pull --ff-only &&
      x env PREFIX="$HOME/.local" "$ruby_build_src/install.sh"; } ||
      echo "warning: ruby-build update failed" >&2
  fi

  if exists android || exists compose-preview; then
    heading "android upgrade"
  fi
  if exists android; then
    x android update || echo "warning: android update failed" >&2
    # Populate/refresh ~/.android/cli/skills without writing to agent skill directories.
    x android skills list --long=false >/dev/null || echo "warning: android skills update failed" >&2
  fi
  if exists compose-preview; then
    # MODIFY_PATH=0 suppresses silent PATH modification of shell configs
    # (https://github.com/yschimke/skills/issues/108). Revert once fixed upstream.
    x env CLI_ONLY=1 MODIFY_PATH=0 SKILL_DIR="$XDG_DATA_HOME/compose-preview" \
      compose-preview update || echo "warning: compose-preview update failed" >&2
  fi

  if exists agy || exists claude || is_codex_agent; then
    heading "agent CLIs upgrade"
  fi
  if exists agy; then
    x agy update || echo "warning: agy update failed" >&2
  fi
  if exists claude; then
    x claude update || echo "warning: claude update failed" >&2
  fi
  if is_codex_agent; then
    x codex update || echo "warning: codex update failed" >&2
  fi
}

# uv: installs uv itself, then fetches everything this repository's uv-based
# scripts download on first use, so they keep working once the network is gone
# (CI jobs, sandboxed cloud agents, planes).
#
# Architecture note: uv is the preferred way to get tools, because it works the
# same on macOS, Debian, CI runners, and cloud containers where brew and apt
# often do not. Skills stay self-contained: a skill's scripts need only uv, and
# fetch their own pinned tools through `uv run --script` metadata on first use,
# so each tool version is pinned in exactly one place. install.sh does not
# duplicate those installs; its uv feature only makes sure uv exists and warms
# uv's cache ahead of time.

# Run a uv command quietly, reporting one git-style status line and, on
# failure, the command's output (indented) so the cause is visible.
function uv_item {
  local ok=$1 bad=$2 label=$3 out
  shift 3
  if [ "$VERBOSE" = 1 ]; then
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

# Returns non-zero if anything failed (or, offline, is not cached).
function feature_uv {
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

  # uv is installed via the standalone astral installer on every platform (it
  # is not a brew/apt package here) because many scripts use `uv run` shebangs.
  # The installer puts it in ~/.local/bin, which is already on PATH.
  if ! exists uv; then
    if [ "$offline" = 1 ]; then
      echo "$(basename "$0"): uv not found" >&2
      return 1
    fi
    echo "Installing uv..."
    # The installer evaluates $XDG_DATA_HOME/../bin and checks it against PATH
    # literally without normalization, failing to recognize that ~/.local/bin is
    # already on PATH. Pin UV_INSTALL_DIR to ~/.local/bin and suppress shell
    # profile modifications (https://github.com/axodotdev/cargo-dist/issues/2529).
    if ! curl "${CURL_OPTS[@]}" -LsSf https://astral.sh/uv/install.sh |
      env UV_NO_MODIFY_PATH=1 UV_INSTALL_DIR="$BINDIR" sh ||
      ! exists uv; then
      echo "warning: uv installation failed" >&2
      return 1
    fi
  fi

  # Tools such as shellcheck, shfmt, and ruff are deliberately not installed on
  # PATH here: the scripts that need them declare their own pinned versions in
  # `uv run --script` metadata, so a skill needs nothing but uv, and each tool
  # version is pinned in exactly one place (the script). This feature only
  # warms uv's cache for those scripts.

  # Fetch what the repository's scripts need. With UV_OFFLINE, uv builds the
  # same environments from its cache alone, which checks offline readiness
  # (it writes to uv's cache, so it is not read-only).
  local f first_line
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

function feature_vscode {
  local dst

  heading "vscode"

  # Don't use system tools to update VS Code
  if [ -e /etc/apt/sources.list.d/vscode.list ] && $HAS_SUDO; then
    x sudo rm -f /etc/apt/sources.list.d/vscode.list || true
  fi

  if ! exists code; then
    if [ -d "/Applications/Visual Studio Code.app" ]; then
      xmkdir "$BINDIR"
      x ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" "$BINDIR/code"
    fi
  fi

  if exists code; then
    if [ "$PLATFORM" = "linux" ]; then
      dst="$DSTDIR/.config/Code/User"
    else
      dst="$DSTDIR/Library/Application Support/Code/User"
    fi

    xmkdir "$dst"

    link_overlay_files "etc/code" "$dst"

    # Let's try Settings Sync for now https://code.visualstudio.com/docs/editor/settings-sync
  fi
}

# Node.js: Homebrew and most apt distributions package a current Node.js. Where
# the distribution's is missing or older than NODE_MIN_MAJOR (Debian 13 ships
# 20), an official nodejs.org build is the per-user default instead:
# node-install keeps it in ~/.local/share/node/versions, and the link
# ~/.local/share/node/default selects one. fish/config.fish and home/.bashrc
# put the link's bin on PATH only when it exists. The decision rests on what
# dpkg reports as installed, so a release upgrade that brings a new enough
# nodejs removes the link on the next run, and nothing else is left behind:
# global npm packages live in NPM_PREFIX (~/.npmrc), outside every version.
#
# Such a machine is often a Raspberry Pi: on a Pi 4 (39-bit virtual address
# space) workerd, the local runtime behind Cloudflare's `cf dev` and `--local`,
# aborts at startup (cloudflare/workerd#5020); cf's API commands are fine.
NODE_MIN_MAJOR=22
NODE_DEFAULT_MAJOR=24
NODE_DEFAULT_LINK="$XDG_DATA_HOME/node/default"
NPM_PREFIX="$HOME/.local/share/npm"

# Print the major version of Debian package $1, as installed (when $2 is
# "installed") or as apt would install it ("candidate"); print nothing if
# there is none.
function deb_major {
  local version=""
  if [ "$2" = installed ] && exists dpkg-query; then
    version=$(dpkg-query -W -f='${Status} ${Version}\n' "$1" 2>/dev/null | awk '$3 == "installed" {print $4}') || true
  elif [ "$2" = candidate ] && exists apt-cache; then
    version=$(LC_ALL=C apt-cache policy "$1" 2>/dev/null | awk '$1 == "Candidate:" {print $2}') || true
  fi
  version=${version#*:} # drop an epoch
  case $version in
    [0-9]*) printf '%s\n' "${version%%.*}" ;;
  esac
}

# Returns success if this machine needs the per-user default Node.js: Linux
# whose installed nodejs package is missing or older than NODE_MIN_MAJOR.
function node_default_needed {
  local major
  [ "$PLATFORM" = linux ] || return 1
  major=$(deb_major nodejs installed)
  [ -z "$major" ] || [ "$major" -lt "$NODE_MIN_MAJOR" ]
}

# Print the major version the default link selects, or nothing if there is no
# link or it is dangling.
function node_default_major {
  local target
  [ -d "$NODE_DEFAULT_LINK/" ] || return 0
  target=$(readlink "$NODE_DEFAULT_LINK" 2>/dev/null) || return 0
  target=${target##*/node-v}
  case $target in
    [0-9]*) printf '%s\n' "${target%%.*}" ;;
  esac
}

# Make the per-user default Node.js exist exactly when node_default_needed, on
# NODE_DEFAULT_MAJOR. The network is used only to create it or change its major
# version, and, with "upgrade" ($1), to move it to the newest
# NODE_DEFAULT_MAJOR release. When the Node.js that
# global npm packages run under changes major version, they are rebuilt.
# Ends with one "node:" line saying which Node.js is in use and why.
function sync_node_default {
  local mode=${1:-} distro before after current
  distro=$(deb_major nodejs installed)
  before=$(node_default_major)

  if [ -e "$NODE_DEFAULT_LINK" ] && [ ! -L "$NODE_DEFAULT_LINK" ]; then
    echo "$(basename "$0"): $NODE_DEFAULT_LINK is not a link; leaving it alone" >&2
    return 1
  fi

  if ! node_default_needed; then
    if [ -L "$NODE_DEFAULT_LINK" ]; then
      x rm "$NODE_DEFAULT_LINK"
      echo "removed: $NODE_DEFAULT_LINK (no longer needed)" >&2
    fi
    if [ "$PLATFORM" = linux ]; then
      echo "node: distribution nodejs $distro"
    else
      echo "node: from the package manager (no per-user default on $PLATFORM)"
    fi
  else
    if [ "$mode" = upgrade ] || [ "$before" != "$NODE_DEFAULT_MAJOR" ]; then
      if is_offline; then
        skip_offline "per-user default Node.js $NODE_DEFAULT_MAJOR"
      elif ! x "$SRCDIR/bin/node-install" --default "$NODE_DEFAULT_MAJOR" >/dev/null; then
        echo "$(basename "$0"): node-install --default $NODE_DEFAULT_MAJOR failed" >&2
        return 1
      fi
    fi
    if [ -n "$(node_default_major)" ]; then
      current=$(basename "$(readlink "$NODE_DEFAULT_LINK")")
    else
      current="not installed"
    fi
    echo "node: per-user default $current (distribution nodejs ${distro:-not installed}; needs >= $NODE_MIN_MAJOR)"
  fi

  after=$(node_default_major)
  if [ -n "$after" ]; then
    export PATH="$NODE_DEFAULT_LINK/bin:$PATH"
  fi
  # Global packages run under the default when there is one, else the
  # system's Node.js (whose major version is unknown off Debian).
  distro=${distro:-system}
  if [ "${before:-$distro}" != "${after:-$distro}" ]; then
    rebuild_npm_globals "${before:-$distro}" "${after:-$distro}"
  fi
}

# Rebuild global npm packages for a new Node.js major version ($1 -> $2), since
# native addons are built for one, and drop npx's cache, which is not keyed by
# Node.js version.
function rebuild_npm_globals {
  local cache
  exists npm || return 0
  cache=$(npm config get cache 2>/dev/null) || cache=""
  [ -n "$cache" ] || cache="$HOME/.npm"
  [ ! -d "$cache/_npx" ] || x rm -rf "$cache/_npx"
  if [ -n "$(ls -A "$NPM_PREFIX/lib/node_modules" 2>/dev/null)" ]; then
    echo "Node.js major version changed ($1 -> $2): rebuilding global npm packages"
    x npm rebuild -g --prefix "$NPM_PREFIX" || echo "warning: npm rebuild -g failed" >&2
  fi
}

function feature_npm {
  heading "node"
  sync_node_default

  exists npm || return 0

  heading "npm"

  x npm config set prefix "$NPM_PREFIX"
  # Global commands land here; the shells put it on PATH only if it exists.
  xmkdir "$NPM_PREFIX/bin"
}

# cloudflare: Cloudflare's cf CLI, a global npm package in the shared prefix
# (kept current by the upgrades feature). Its guidance is the cf-cli skill,
# added per session or workspace with 'skill add cf-cli', not installed here.
# The workerd postinstall stays blocked: cf's local runtime (cf dev) is not
# used, and it cannot run on some hosts (a Raspberry Pi 4's 39-bit VA).
function feature_cloudflare {
  local major

  heading "cloudflare"

  if ! exists npm; then
    echo "$(basename "$0"): cloudflare: npm not found; run the npm feature first" >&2
    return 1
  fi
  # cf requires Node.js 22.18 or later.
  major=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null) || major=0
  if [ "${major:-0}" -lt 22 ]; then
    echo "$(basename "$0"): cloudflare: cf needs Node.js 22 or later (found $(node --version 2>/dev/null || echo none))" >&2
    return 1
  fi

  if ! exists cf; then
    if is_offline; then
      skip_offline "cloudflare"
      return 0
    fi
    x npm install -g --prefix "$NPM_PREFIX" cf || return 1
  fi

  # The shells also set CF_SEND_TELEMETRY=0; this covers processes that do not
  # start from them.
  x env CF_SEND_TELEMETRY=0 cf cli telemetry disable >/dev/null
}

# Download installer script $1 and run it with the remaining arguments. Unlike
# `bash <(curl ...)`, a failed download is an error rather than an empty script
# that "succeeds".
function run_installer {
  local url=$1 script status=0
  shift
  script=$(mktemp)
  if curl "${CURL_OPTS[@]}" -fsSL -o "$script" "$url"; then
    x bash "$script" "$@" || status=$?
  else
    echo "warning: failed to download $url" >&2
    status=1
  fi
  rm -f "$script"
  return "$status"
}

# Write ~/.gradle/gradle.properties with a heap sized to this machine's RAM
# (unless the file was not written by this script), and link the init scripts.
function gradle_settings {
  local mem_bytes mem_kb mem_gb heap gradle_dir gradle_props

  heading "gradle"

  if [ "$PLATFORM" = "darwin" ]; then
    # macOS: hw.memsize is usually the exact physical RAM in bytes
    mem_bytes=$(sysctl -n hw.memsize)
    mem_gb=$((mem_bytes / 1024 / 1024 / 1024))
  else
    # Linux: MemTotal is often less than physical RAM due to hardware reservations (GPU, etc.)
    # Round to the nearest GB to infer the physical capacity.
    mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    mem_gb=$(((mem_kb + 524288) / 1048576))
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

  if [ -f "$gradle_props" ] && ! grep -q "# Generated by dotfiles update" "$gradle_props"; then
    echo "Skipping $gradle_props as it was not generated by this script and already exists."
    return 0
  fi
  echo "Writing $gradle_props with heap=${heap}"
  cat >"$gradle_props" <<EOF
# Generated by dotfiles update
org.gradle.jvmargs=-Xmx${heap} -XX:+UseG1GC
org.gradle.parallel=true
org.gradle.caching=true
EOF
}

# android: the SDK tools and JDKs come from the package step; this adds the
# gradle settings and the Android CLI and compose-preview, which have their
# own installers (and are kept current by the upgrades feature).
function feature_android {
  gradle_settings

  if exists android && exists compose-preview; then
    return 0
  fi
  if is_offline; then
    skip_offline "Android CLI and compose-preview installs"
    return 0
  fi

  heading "android"
  if ! exists android; then
    if [ "$(uname -s -m)" = "Linux x86_64" ]; then
      run_installer https://dl.google.com/android/cli/latest/linux_x86_64/install.sh &&
        x android skills list --long=false >/dev/null ||
        echo "warning: android install failed" >&2
    else
      echo "warning: no Android CLI installer for $(uname -s -m); skipping" >&2
    fi
  fi
  if ! exists compose-preview; then
    # MODIFY_PATH=0 and --no-modify-path work around upstream issue #108.
    MODIFY_PATH=0 SKILL_DIR="$XDG_DATA_HOME/compose-preview" \
      run_installer https://raw.githubusercontent.com/yschimke/skills/main/scripts/install.sh \
      --cli-only --no-modify-path || echo "warning: compose-preview install failed" >&2
  fi
}

# ruby: the engine behind ruby-install. On macOS it is a brew package; on
# Linux apt's ruby-build is too old to build current Ruby, so bootstrap a
# current copy from git into ~/.local (binary at ~/.local/bin/ruby-build,
# where ruby-install looks for it). The upgrades feature keeps it current.
function feature_ruby {
  local ruby_build_src="$HOME/.local/share/ruby-build"

  [ "$PLATFORM" = "linux" ] || return 0
  [ ! -x "$BINDIR/ruby-build" ] || return 0

  heading "ruby-build"
  if [ ! -d "$ruby_build_src/.git" ]; then
    if is_offline; then
      skip_offline "ruby-build clone"
      return 0
    fi
    x git "${GIT_NET_OPTS[@]}" clone https://github.com/rbenv/ruby-build.git "$ruby_build_src"
  fi
  x env PREFIX="$HOME/.local" "$ruby_build_src/install.sh"
}

function feature_skills {
  local src

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

  heading "skill defaults"

  # Each repo's etc/skill/defaults.sh adds and removes default skills with
  # `skill --scope defaults`, so overlay skill names stay out of this repo. They
  # run here rather than at agent launch, which only links the defaults.
  for src in "${SRCDIRS[@]}"; do
    [ -f "$src/etc/skill/defaults.sh" ] || continue
    x env PATH="$SRCDIR/bin:$PATH" sh "$src/etc/skill/defaults.sh" ||
      echo "warning: $src/etc/skill/defaults.sh failed" >&2
  done

  # Skills are intentionally NOT installed globally. The defaults are linked
  # into each wrapped agent's workspace or session at launch
  # (`skill add --defaults`), and others with `skill add ...`, using
  # ~/.dotfiles/skills (plus .private and .corp overlays) as the source.
  # Keeping ~/.agents/skills and ~/.claude/skills empty prevents every project
  # from seeing every skill.
}

function feature_agents {
  local agents_context

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

  if exists agy; then
    xmkdir "$HOME/.gemini/config"
    link_overlay_path "etc/agents/agy/hooks.json" "$HOME/.gemini/config/hooks.json"
    link_overlay_path "etc/agents/agy/hooks" "$HOME/.gemini/config/hooks"
  fi

  heading "agent permissions"

  local permission_tool="$SRCDIR/bin/permission"
  if [ -x "$permission_tool" ]; then
    local paths_to_approve=()
    local src ws

    # Pre-approve base dotfiles and any active overlays
    for src in "${SRCDIRS[@]}"; do
      [ -d "$src" ] && paths_to_approve+=("$src")
    done

    # Include user projects repository if present
    if [ -d "$HOME/.projects" ]; then
      paths_to_approve+=("$HOME/.projects")
    fi

    # Allow agent sandboxes to write uv tool state and Andon alert logs
    # when ~/.local is otherwise mounted read-only.
    xmkdir "$XDG_DATA_HOME/uv"
    xmkdir "$XDG_STATE_HOME/andon"
    paths_to_approve+=("$XDG_DATA_HOME/uv" "$XDG_STATE_HOME/andon")

    if [[ ${#paths_to_approve[@]} -gt 0 ]]; then
      x "$permission_tool" path add "${paths_to_approve[@]}" ||
        echo "warning: failed to grant path permissions" >&2
    fi

    for ws in "${paths_to_approve[@]}"; do
      if [ -d "$ws/.git" ] || [ -d "$ws/.agents/skills" ]; then
        (cd "$ws" && x "$permission_tool" apply) ||
          echo "warning: failed to apply permissions in $ws" >&2
      fi
    done
  fi
}

function feature_overlay_hooks {
  if [ -x "$DSTDIR/.private/update" ]; then
    heading "private update"
    "$DSTDIR/.private/update"
  fi

  if [ -x "$DSTDIR/.corp/update" ]; then
    heading "corp update"
    "$DSTDIR/.corp/update"
  fi
}

# Ask for sudo upfront, but only if a selected feature will use it on Linux:
# the package step, or upgrades when due. When it would need a password, ask
# on the terminal if there is one; a non-interactive run (--no-input, or a
# setup script with no terminal at all) uses sudo only if it is passwordless,
# and skips apt otherwise.
if [ "$PLATFORM" = "linux" ] && ! is_offline &&
  { packages_selected || { selected upgrades && ! is_fresh "$PACKAGE_STAMP"; }; }; then
  if ! command -v sudo >/dev/null 2>&1; then
    echo "warning: sudo not found; skipping apt" >&2
  elif sudo -n true 2>/dev/null; then
    HAS_SUDO=true
  elif [ "$NO_INPUT" = 1 ] || ! (: </dev/tty) 2>/dev/null; then
    echo "warning: sudo needs a password and this run cannot prompt for it; skipping apt" >&2
  else
    echo "This script requires sudo access for package management."
    echo "You may be prompted for your password."
    # Good for 5 mins; for more see https://github.com/mathiasbynens/dotfiles/blob/master/.macos#L13
    # shellcheck disable=SC2024 # the redirect is for sudo's password prompt
    if ! sudo -v </dev/tty; then
      echo "$(basename "$0"): failed to obtain sudo access" >&2
      exit 1
    fi
    HAS_SUDO=true
  fi
fi

FAILED=""

# Run step $2 (a function) in a subshell with errexit, so a failure stops that
# step only, and record $1 as failed if it does. errexit is ignored inside any
# command that is part of an `||` or `if` test, hence the explicit status
# capture.
function run_step {
  local status
  set +e
  (
    set -e
    "$2"
  )
  status=$?
  set -e
  if [ "$status" -ne 0 ]; then
    FAILED="${FAILED:+$FAILED }$1"
  fi
}

PACKAGES_DONE=0
for name in $SELECTED; do
  if [ "$PACKAGES_DONE" = 0 ] && [[ " $PACKAGE_FEATURES " == *" $name "* ]]; then
    PACKAGES_DONE=1
    run_step packages install_packages
  fi
  if declare -F "feature_${name//-/_}" >/dev/null; then
    run_step "$name" "feature_${name//-/_}"
  fi
done

# Restart the upgrades' 24 hours only when they ran.
if selected upgrades && ! is_fresh "$PACKAGE_STAMP" && ! is_offline; then
  touch_stamp "$PACKAGE_STAMP"
fi

if { packages_selected || selected upgrades; } && [ -f /var/run/reboot-required ]; then
  echo "warning: a reboot is required to complete updates"
  if [ -f /var/run/reboot-required.pkgs ]; then
    sed 's/^/warning: /' /var/run/reboot-required.pkgs
  fi
  echo "hint: sudo reboot"
fi

if [ -n "$FAILED" ]; then
  for name in $FAILED; do
    echo "failed: $name" >&2
  done
  exit 1
fi
