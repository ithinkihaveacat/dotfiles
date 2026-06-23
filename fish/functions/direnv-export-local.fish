function direnv-export-local --description 'Generate set -lx commands from a directory\'s direnv configuration' --argument-names target_dir
    # Related: 'direnv export fish' produces global set -x commands for the current
    # directory and handles variable unsetting; this function targets any directory
    # and uses set -lx so variables remain scoped to the caller and do not leak.
    if contains -- --help $argv
        echo "Usage: direnv-export-local [DIRECTORY]

Generate set -lx commands from a directory's direnv configuration.

Reads the direnv environment for DIRECTORY (or the current directory if
omitted) and outputs Fish set -lx statements suitable for eval. Variables
are exported but function-scoped, so they do not pollute the parent shell.

Arguments:
  DIRECTORY   Directory whose .envrc to evaluate (default: current directory)

Options:
  --help      Display this help message and exit

Examples:
  # Load env vars from the current directory into a function scope
  eval (direnv-export-local)

  # Load env vars from another project without cd-ing there
  eval (direnv-export-local ~/projects/myapp)

  # Inspect what direnv would set for a project without applying it
  direnv-export-local ~/projects/myapp"
        return 0
    end

    set -l target $target_dir
    if test -z "$target"
        set target $PWD
    end

    set -l real_dir (realpath $target)
    if not test -d "$real_dir"
        echo "direnv-export-local: Target directory '$target' does not exist." >&2
        return 1
    end

    if not type -q direnv; or not type -q jq
        echo "direnv-export-local: direnv and jq are required." >&2
        return 127
    end

    set -l json (env -C $real_dir direnv export json 2>/dev/null)
    if test -n "$json" -a "$json" != "{}"
        echo $json \
            | jq -r 'to_entries[] | select(.key | startswith("DIRENV_") | not) | "set -lx \(.key) \((if .value == null then "" else .value end) | @sh)"' \
            | string collect
    end
end
