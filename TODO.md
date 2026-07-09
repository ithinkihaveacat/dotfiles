# TODO

## Standardize concise help on missing required arguments (2026-07-09)

**Problem:** `cli-tools.md` already states the rule (adopted from clig.dev):
a tool invoked without required arguments should print a brief description,
one or two examples, and a pointer to `--help` — not full help text, and not
only "Try --help". No script was changed to implement it when `-h` support
was added (PR #134), because it's a per-script judgment call, not a
mechanical find/replace. A grep audit of `bin/` and `skills/*/scripts/`
(2026-07-09) found at least three different existing behaviors for missing
required arguments, all still live:

1. **Full help text, exit 1** — e.g. `usage 1 >&2` in `bin/csv-query:28` and
   `bin/image-mask-circular:38`. Dumps everything (all examples, every flag)
   to stderr for a simple "you forgot an argument" error.
2. **Bare error, no pointer to `--help`** — e.g.
   `echo "$(basename "$0"): missing operand" >&2; exit 1` in
   `bin/macos-bootout:40`. Correct exit code, but no example and no "Try
   '--help'" pointer, which even the outgoing standard's GNU-style error
   convention wanted.
3. **No args treated as an implicit help request, exit 0** — e.g.
   `if [[ "$1" == "--help" || "$1" == "-h" || -z "$1" ]]; then usage; fi` in
   `skills/adb/scripts/adb-demo:40` and `skills/adb/scripts/adb-fontscale`.
   This is clig.dev's "bare complex command shows help" allowance, but these
   are simple single-action tools (Appendix A patterns), not `git`-style
   subcommand tools — treating missing-args as a request for help (exit 0)
   instead of a usage error (exit >0) breaks scripting (`tool; echo $?`
   can't distinguish "ran fine" from "forgot an argument").

**Goal:** One consistent behavior for simple (non-subcommand) tools invoked
without a required positional argument: print a short usage line, one
example, and a pointer to `--help`/`-h` to stderr, then exit `1` — never the
full help text, never a bare error with no example, never exit `0`. Complex
subcommand tools (the `kubectl`-style and Manager-pattern tools covered by
`cli-tools.md`'s Appendix A) are explicitly out of scope here: clig.dev's
bare-command-shows-help allowance is for them, and `git-hooks-multiplexer`,
`skill`, `jetpack`, etc. already implement it deliberately.

**Criteria:** `shell.md` documents a short concise-usage pattern (e.g. a
`usage_short()` helper or an inline `die_usage`-style one-liner, whichever
reads more like the rest of the file) developers can drop into the
`if [[ $# -lt N ]]` preamble. Every simple-pattern script in `bin/` and
`skills/*/scripts/` that currently does pattern 1, 2, or 3 above for a
*required* positional argument is converted to the new behavior and exits
`1`. `shellcheck`/`shfmt` clean; existing test suites still pass (a few
tests likely assert today's exit-0-on-no-args or full-help-dump behavior and
will need updating alongside the scripts they cover).

**Sketch:** Grep for `usage 1 >&2`, `missing operand`, and
`-z "\$1"[^]]*--help\|--help[^]]*-z "\$1"` across `bin/` and
`skills/*/scripts/` to enumerate the full set (the three examples above are
a starting sample, not the complete list). Decide per script whether the
first positional argument is actually required — some of the `-z "$1"`
tools may have a legitimate zero-arg default behavior rather than a missing
required argument, in which case they're out of scope and should be left
alone rather than forced into a usage error.

**Constraints:** No behavior change for scripts whose missing-argument case
is genuinely a valid default (not an error). Keep bash 3.2 compatibility.
Don't touch the complex subcommand tools' bare-invocation-shows-help
behavior.
