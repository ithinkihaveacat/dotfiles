# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [hook](#hook)
- [envrc](#envrc)
- [node-install](#node-install)
- [ruby-install](#ruby-install)
- [python-install](#python-install)

## hook

The block below is `../scripts/hook --help`, kept in sync by
`command-index-format`.

<!-- generated: ../scripts/hook --help -->

```text
Usage: hook <command> [arguments]

Manage this repository's git hooks. Hooks are grouped into profiles; each
profile installs one or more sub-hooks through a multiplexer at
.git/hooks/<hook-name>, so profiles coexist with each other and with hooks
from other tools.

A sub-hook is installed as a trampoline: a generated stub whose body execs
the hook source where it lives in this dotfiles tree. Editing that source
changes the behaviour of every repository the profile is installed into,
with no re-install step, and a source that has gone away fails the hook
loudly rather than being silently skipped.

A pre-existing hook not managed by this tool is preserved as
.git/hooks/<hook-name>.d/00-legacy and continues to run first. Removing the
last managed sub-hook restores it as the plain hook.

A hook source kept outside this tree (in another repository, say) can join
the same multiplexer as an external sub-hook: 'add --external' installs a
trampoline to it under a key you choose. External sub-hooks are shown by
'list', checked by 'doctor', and left alone by 'apply' and 'clean'.

Commands:
  apply             Synchronize this repository's hooks to match
                    AGENT_REQUIRED_HOOKS (idempotent)
  add PROFILE...    Add a hook profile
  add --external HOOK-NAME:KEY SOURCE
                    Add SOURCE as sub-hook KEY of HOOK-NAME (e.g.
                    pre-push:90-check); KEY is two digits, a dash and a name,
                    and sets the run order
  remove PROFILE... Remove a hook profile, leaving other hooks in place
                    (alias: rm)
  remove --external HOOK-NAME:KEY
                    Remove an external sub-hook
  list              List the hooks installed in this repository (alias: ls)
  catalog           List the hook profiles available to add
  doctor            Report missing, drifted or unmanaged hooks (read-only)
  clean             Remove every profile this tool manages, leaving
                    third-party hooks, external sub-hooks and 00-legacy in
                    place

Options:
  -C DIR, --directory DIR
                    Run as if started in DIR instead of the current working
                    directory
  --source-dir DIR, -S DIR
                    Source directory containing hook profiles
                    (default: bundled resources/hooks, or $HOOK_SOURCE_DIR)
  --copy            add/apply: copy the hook source instead of installing a
                    trampoline to it, for a machine with no dotfiles tree
  --external        add/remove: operate on an external sub-hook rather than
                    a profile
  --quiet, -q       add/apply/remove/clean: suppress informational messages;
                    errors are still printed
  --all             clean: delete the entire hooks directory, including
                    third-party hooks; requires --force
  --force           clean --all: confirm the deletion
  --help, -h        Display this help message and exit

Environment:
  HOOK_SOURCE_DIR       Directory containing hook profile sources
                        (alias: AGENT_HOOKS_DIR)
  AGENT_REQUIRED_HOOKS  Whitespace-separated profiles 'apply' installs
                        (default: agent). Profiles it does not name are
                        removed.
  AGENT_OFFLINE         Set to 1 to fail rather than fetch a profile whose
                        hook is downloaded (gerrit).

Examples:
  hook apply
  hook add node
  hook list
  hook doctor
  hook remove gerrit
  hook add --external pre-push:90-check ~/src/checks/pre-push
  env AGENT_REQUIRED_HOOKS='agent node' hook apply

'add'/'apply' abort immediately, installing nothing for that profile, if a
required profile names a dependency that is missing or not actually usable
(no 'uv' for agent or markdown, no 'curl' for gerrit, no prettier reachable via
'npx' or on PATH for node) — deliberately, so a broken promise fails loudly at
install/checkout time rather than silently at the next commit. 'apply' does
not partially recover: a dependency failure on any named profile stops the
whole sync, leaving profiles processed so far installed. Run 'doctor' to see
which profile is at fault.
```

<!-- /generated -->

## envrc

The block below is `scripts/envrc --help`, kept in sync by
`command-index-format`.

<!-- generated: ../scripts/envrc --help -->

```text
Usage: envrc [options] <command> [args...]

Manage configuration blocks within a .envrc file. Blocks are delimited by
managed marker comments so multiple configurations can co-exist safely. The
'env' block holds environment variables managed with set/unset/get.

Options:
  --output FILE  Path to the output file (default: .envrc)
  --help         Display this help message and exit

Commands:
  create <type> [args...]  Create a configuration block
  delete <type>            Delete an entire configuration block
  show <type>              Print a block's content
  list                     List active blocks
  set VAR VALUE            Set an environment variable in the env block
                           (creates the block if needed)
  unset VAR                Remove an environment variable from the env block
  get VAR                  Print a variable's value from any managed block
  catalog                  List available configuration types
  migrate skills [--dry-run] [--force]
                           Replace a legacy 'skills' block (from before
                           'skill' defaults): link its skills into the
                           workspace with 'skill add', then delete the block

Types:
  node [VERSION]           Adds Node.js direnv layout (default version: 24)
  ruby [VERSION]           Adds Ruby direnv layout (default version: 3.4)
  uv                       Adds Python uv direnv layout
  firebase <PROJECT_ID>    Adds Firebase project variables
  appengine <APP_ID> [URL] Adds Google App Engine variables
  block <NAME>             Adds a raw block named NAME; content is read from
                           stdin

Examples:
  envrc create node 22
  envrc create uv
  envrc list
  envrc set API_ORIGIN https://api.example.com
  envrc get API_ORIGIN
  envrc create block corp <corp-fragment.sh
  envrc delete node
  envrc migrate skills --dry-run

'set' writes single-quoted values, so values are always literal data: shell
syntax like $(...) is never evaluated when direnv loads the file. 'get' reads
the file statically (no shell is executed) and unquotes simple single- or
double-quoted values.

'migrate skills' runs 'skill -C DIR' in the .envrc's directory. Names already
linked there or already defaults are skipped. Negated names ('-NAME', '!NAME')
have no equivalent yet and are dropped with a warning. The block is kept, and
the exit status is 1, if 'skill add' fails or, without --force, if a name does
not resolve or a line is not understood, so nothing is lost silently.
--dry-run (-n) prints the actions without changing anything. With no 'skills'
block it does nothing and exits 0.
```

<!-- /generated -->

## node-install

The block below is `../scripts/node-install --help`, kept in sync by
`command-index-format`.

<!-- generated: ../scripts/node-install --help -->

```text
Usage: node-install [OPTIONS] VERSION [PREFIX]
       node-install --list
       node-install --installed
       node-install --default [VERSION]

Downloads and installs a specific version of Node.js.

Arguments:
  VERSION     Node.js version to install. Supports partial versions:
              - "22.13.1" installs exactly v22.13.1
              - "22.13" installs the latest v22.13.x
              - "22" installs the latest v22.x.x
  PREFIX      Directory where Node.js will be installed (optional).
              A subdirectory named node-vVERSION will be created.
              Default: $XDG_DATA_HOME/node/versions or ~/.local/share/node/versions

Options:
  -l, --list       List all available remote Node.js versions
  -i, --installed  List all installed Node.js versions
  --default [VERSION]
                   Install VERSION if it is missing (succeeding if it is
                   already installed) and make it the per-user default,
                   $XDG_DATA_HOME/node/default; print its path. Without
                   VERSION, print the current default's path
  --help           Display this help message and exit

Examples:
  # Install latest Node.js 22.x
  node-install 22

  # List available versions
  node-install --list

  # List installed versions
  node-install --installed

  # Make the latest Node.js 24.x the default outside direnv workspaces
  node-install --default 24

The default is for machines whose package manager has no recent enough
Node.js: put $XDG_DATA_HOME/node/default/bin on PATH to use it. Global npm
packages are unaffected by switching it, provided npm's prefix (~/.npmrc) is
outside the version directories.
```

<!-- /generated -->

## ruby-install

The block below is `../scripts/ruby-install --help`, kept in sync by
`command-index-format`.

<!-- generated: ../scripts/ruby-install --help -->

```text
Usage: ruby-install [OPTIONS] VERSION [PREFIX]
       ruby-install --list
       ruby-install --installed

Compiles and installs a specific version of Ruby from source.

Arguments:
  VERSION     Ruby version to install. Supports partial versions:
              - "3.4.1" installs exactly 3.4.1
              - "3.4" installs the latest 3.4.x
              - "3" installs the latest 3.x.x
  PREFIX      Directory where Ruby will be installed (optional).
              A subdirectory named ruby-vVERSION will be created.
              Default: $XDG_DATA_HOME/ruby/versions or ~/.local/share/ruby/versions

Options:
  -l, --list       List all installable stable Ruby versions
  -i, --installed  List all installed Ruby versions
  --help           Display this help message and exit

Examples:
  # Install latest Ruby 3.4.x
  ruby-install 3.4

  # List installable versions
  ruby-install --list

  # List installed versions
  ruby-install --installed

Versions are compiled from source, so the first install of a version takes a few
minutes. The build is performed by ruby-build; if a system library is missing it
will report which one at configure time.
```

<!-- /generated -->

## python-install

The block below is `../scripts/python-install --help`, kept in sync by
`command-index-format`.

<!-- generated: ../scripts/python-install --help -->

```text
Usage: python-install

Install Python using uv.

This script checks for the presence of 'uv' and provides information on how
to use it for Python environment management in this repository.

Options:
  --help      Display this help message and exit

Examples:
  python-install
```

<!-- /generated -->

<!-- markdownlint-restore MD013 -->
