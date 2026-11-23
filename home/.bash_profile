# -*- sh -*-

start_fish() {
  [[ $- == *i* ]] || return 0

  # SSH clients can use bash -ilc without a terminal to load the login
  # environment before running a command. Codex Desktop does this to locate
  # Codex on the remote host. Keep the command in Bash so assignments such
  # as CODEX_HOME from the probe are parsed using Bash syntax.
  if [[ -n ${SSH_CONNECTION-} && -z ${SSH_TTY-} && -n ${BASH_EXECUTION_STRING-} ]]; then
    return 0
  fi

  local fish
  fish=$(env PATH="$HOME/local/bin:/opt/homebrew/bin:$PATH" which fish)
  [[ -x $fish ]] || return 0

  # Local IDE probes such as Android Studio's printenv need fish's environment.
  # https://youtrack.jetbrains.com/articles/SUPPORT-A-1727/Shell-Environment-Loading
  if [[ -n ${BASH_EXECUTION_STRING-} ]]; then
    exec env SHELL="$fish" "$fish" -i -c "$BASH_EXECUTION_STRING"
  fi
  exec env SHELL="$fish" "$fish" -i
}

start_fish

# Set up PATH and other defaults when the login shell stays in Bash.
if [[ -r $HOME/.bashrc ]]; then
  # shellcheck source=/dev/null
  . "$HOME/.bashrc"
fi
