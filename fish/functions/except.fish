# Tests: tests/test-except

function except --description 'Filter out matching items from current directory (*) or stdin'
    if contains -- -h $argv; or contains -- --help $argv
        echo "Usage: except [OPTIONS] [PATTERNS...]
       ... | except -s [PATTERNS...]

Filter out items matching provided patterns (globs or exact strings).
Defaults to filtering all files ('*') in the current directory.
Items starting with a leading dash ('-*') are always excluded for safety.

Arguments:
  PATTERNS      Patterns or exact names to exclude (e.g. '*.tmp', 'node_modules')

Options:
  -s, --stdin   Read and filter items from standard input instead of '*'
  -h, --help    Display this help message and exit

Examples:
  rm (except important.txt *.bak)
  path filter -f * | except -s '.*' node_modules
  printf '%s\n' alpha beta gamma | except -s 'b*'"
        return 0
    end

    set -l use_stdin 0
    set -l patterns

    # Parse flags and patterns
    for arg in $argv
        if test "$arg" = -s; or test "$arg" = --stdin
            set use_stdin 1
        else
            set -a patterns "$arg"
        end
    end

    # Gather candidate items
    set -l targets
    if test $use_stdin -eq 1
        while read -l line
            set -a targets "$line"
        end
    else
        set targets *
    end

    # Filter items:
    # Always drop items starting with '-' for safety
    for item in $targets
        if string match -q -- '-*' "$item"
            continue
        end

        set -l matched 0
        for pattern in $patterns
            if string match -q -- "$pattern" "$item"
                set matched 1
                break
            end
        end
        if test $matched -eq 0
            printf "%s\n" "$item"
        end
    end
end
