# -*- sh -*-

is_interactive() { [[ $- == *i* ]]; }

if is_interactive; then

    # If we're running in interactive mode, look for fish, and exec if it exists.

    FISH=$(env PATH="$HOME/local/bin:/opt/homebrew/bin:$PATH" which fish)

    if [[ -x "$FISH" ]]; then
      # If bash was invoked with -c 'command' (e.g., Android Studio's printenv),
      # pass the command to fish so it runs in fish's environment after fish config.
      # See https://youtrack.jetbrains.com/articles/SUPPORT-A-1727/Shell-Environment-Loading
      if [[ -n "${BASH_EXECUTION_STRING-}" ]]; then
        exec env SHELL="$FISH" "$FISH" -i -c "$BASH_EXECUTION_STRING"
      else
        exec env SHELL="$FISH" "$FISH" -i
      fi
    fi

fi

# If we reach here, fish wasn't found. Source bashrc for PATH and environment setup.
[[ -r "$HOME/.bashrc" ]] && . "$HOME/.bashrc"
