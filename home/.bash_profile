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

# Last-resort PATH modifications. In most cases we either want a full interactive
# shell (in which case we'll follow the is_interactive branch above, and fish's
# config will run) *or* it's acceptable to have a very minimal PATH. However,
# for some use cases we need . (Don't try to replicate the full fish PATH-setting
# logic here!)

path_prepend() { case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH";; esac; }

path_prepend "$HOME/.local/bin"

export PATH
