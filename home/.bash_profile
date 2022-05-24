# -*- sh -*-

# Don't run fish if Android Studio is attempting to retrieve environment variables
# https://youtrack.jetbrains.com/articles/IDEA-A-19/Shell-Environment-Loading

if [ -z "$INTELLIJ_ENVIRONMENT_READER" ]; then

    # Attempt to run fish as login shell, even if bash is technically the
    # login shell.

    FISH=$(env PATH="$HOME/local/bin:$HOME/local/homebrew/bin:$PATH" which fish)

    if [[ -x "$FISH" ]]; then
      exec env SHELL="$FISH" "$FISH" -i
    fi

fi
