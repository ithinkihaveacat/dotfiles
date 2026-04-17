# Source: https://github.com/junegunn/fzf/blob/master/bin/fzf-preview.sh
# Simplified for Ghostty and Chafa.

function fzfinder
    function usage
        echo "Usage: fzfinder [PATH]
       fzfinder FILENAME[:LINENO]

Fuzzy finder with image and text preview. Requires Ghostty terminal.

Arguments:
  PATH        Path to search in interactive mode (defaults to current directory)
  FILENAME    File to preview in preview mode

Options:
  --help      Display this help message and exit

Examples:
  fzfinder
  fzfinder ~/Pictures"
    end

    if contains -- --help $argv
        usage
        return 0
    end

    if not string match -q -r ghostty "$TERM"
        echo "fzfinder: requires Ghostty terminal" >&2
        return 1
    end

    if test (count $argv) -gt 0
        # Preview mode
        set file (string replace -r '^~/' "$HOME/" $argv[1])

        set center 0
        if not test -r $file
            if set match (string match -r '^(.+):([0-9]+)\ *$' $file)
                set file $match[2]
                set center $match[3]
            else if set match (string match -r '^(.+):([0-9]+):[0-9]+\ *$' $file)
                set file $match[2]
                set center $match[3]
            end
        end

        set type (file --brief --dereference --mime -- "$file")

        if not string match -q -r image/ "$type"
            if string match -q -r '=binary' "$type"
                file "$argv[1]"
                return
            end

            set batname ""
            if command -v batcat >/dev/null
                set batname batcat
            else if command -v bat >/dev/null
                set batname bat
            else
                cat "$argv[1]"
                return
            end

            $batname --style="numbers" --color=always --pager=never --highlight-line="$center" -- "$file"
            return
        end

        if command -v chafa >/dev/null
            chafa --clear --format=kitty --size="$FZF_PREVIEW_COLUMNS"x"$FZF_PREVIEW_LINES" "$file"
        else
            file "$file"
        end
    else
        # Interactive mode
        fzf --exact --preview 'fzfinder {}' --preview-window=right:60%
    end
end
