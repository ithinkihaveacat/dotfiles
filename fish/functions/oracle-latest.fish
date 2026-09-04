function oracle-latest --description 'Echo filename of newest file in ~/.local/state/oracle'
    if contains -- -h $argv; or contains -- --help $argv
        echo "Usage: oracle-latest [OPTIONS]

Echo the path of the newest file in the Oracle state directory.

Options:
  -h, --help    Display this help message and exit

Environment:
  ORACLE_STATE_DIR  Directory containing Oracle session files
                    (default: \$XDG_STATE_HOME/oracle or ~/.local/state/oracle)

Examples:
  oracle-latest
  cat (oracle-latest)"
        return 0
    end

    for arg in $argv
        switch $arg
            case '-*'
                echo "oracle-latest: unrecognized option '$arg'" >&2
                echo "Try 'oracle-latest --help' for more information." >&2
                return 1
            case '*'
                echo "oracle-latest: unexpected argument '$arg'" >&2
                echo "Try 'oracle-latest --help' for more information." >&2
                return 1
        end
    end

    set -l state_dir
    if set -q ORACLE_STATE_DIR; and test -n "$ORACLE_STATE_DIR"
        set state_dir $ORACLE_STATE_DIR
    else if set -q XDG_STATE_HOME; and test -n "$XDG_STATE_HOME"
        set state_dir $XDG_STATE_HOME/oracle
    else
        set state_dir $HOME/.local/state/oracle
    end

    set state_dir (string replace -r '^~' "$HOME" -- "$state_dir")

    if not test -d "$state_dir"
        echo "oracle-latest: directory not found: $state_dir" >&2
        return 1
    end

    set -l latest
    if stat -f "%m" /dev/null >/dev/null 2>&1
        set latest (find "$state_dir" -type f -exec stat -f "%m %N" {} + 2>/dev/null | sort -n -r | head -n 1 | cut -d" " -f2-)
    else
        set latest (find "$state_dir" -type f -exec stat -c "%Y %n" {} + 2>/dev/null | sort -n -r | head -n 1 | cut -d" " -f2-)
    end

    if test -z "$latest"
        echo "oracle-latest: no files found in $state_dir" >&2
        return 1
    end

    echo $latest
    return 0
end
