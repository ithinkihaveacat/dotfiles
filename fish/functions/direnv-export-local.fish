function direnv-export-local --description 'Generate set -lx commands from a directory\'s direnv configuration' --argument-names target_dir
    # Default to current working directory if not specified
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

    # Output eval-ready set -lx statements, ensuring zero parent shell pollution
    env -C $real_dir direnv export json 2>/dev/null \
        | jq -r 'to_entries[] | "set -lx \(.key) \((if .value == null then "" else .value end) | @sh)"' \
        | string collect
end
