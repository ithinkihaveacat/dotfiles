# -*- sh -*-

# Attempt to run fish as login shell, even if bash is technically the
# login shell.

FISH=$(env PATH="$HOME/local/bin:$HOME/local/homebrew/bin:$PATH" which fish)

if [[ -x "$FISH" ]]; then
  exec env SHELL="$FISH" "$FISH" -i
fi
