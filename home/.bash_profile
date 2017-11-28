# -*- sh -*-

# Attempt to run fish as login shell, even if bash is technically the
# login shell.

FISH=$(which fish)

if [[ -x "$FISH" ]]; then
  exec "$FISH" -i
fi
