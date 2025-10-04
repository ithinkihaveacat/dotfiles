# -*- sh -*-

# Might also need to avoid fish if INTELLIJ_ENVIRONMENT_READER is present; see
# https://youtrack.jetbrains.com/articles/SUPPORT-A-1727/Shell-Environment-Loading

is_interactive() { [[ $- == *i* ]]; }

if is_interactive; then

    # If we're running in interactive mode, look for fish, and exec if it exists.

    FISH=$(env PATH="$HOME/local/bin:/opt/homebrew/bin:$PATH" which fish)

    if [[ -x "$FISH" ]]; then
      exec env SHELL="$FISH" "$FISH" -i
    fi

fi
