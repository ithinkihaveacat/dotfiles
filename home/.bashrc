# -*- sh -*-

# Only run if FNM_DIR isn't already set (indicates fnm env already evaluated)
# if [[ -z "${FNM_DIR-}" ]]; then
#   # Prefer explicit path; fall back to PATH lookup
#   _FNM_BIN="$HOME/.local/share/fnm/fnm"
#   if [[ -x "$_FNM_BIN" ]]; then
#     eval "$("$_FNM_BIN" env --use-on-cd --shell bash)"
#   elif command -v fnm >/dev/null 2>&1; then
#     eval "$(fnm env --use-on-cd --shell bash)"
#   fi
#   unset _FNM_BIN
# fi

# Set PATH for some non-interactive use cases, like "ssh server ...". Use
# selectively; don't try to replicated fish's full PATH manipulation logic
# here!

path_prepend() { case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH";; esac; }

path_prepend "$HOME/.local/bin"
# npm's global prefix (~/.npmrc), then the per-user default Node.js, which
# install.sh creates only where the distribution's is too old; as in fish, it
# comes first so a global package can never shadow node or npm.
for d in "${XDG_DATA_HOME:-$HOME/.local/share}/npm/bin" \
  "${XDG_DATA_HOME:-$HOME/.local/share}/node/default/bin"; do
  if [ -d "$d" ]; then path_prepend "$d"; fi
done
unset d
path_prepend "$HOME/.dotfiles/bin"

export PATH
