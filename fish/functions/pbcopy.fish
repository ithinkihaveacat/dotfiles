# pbcopy - Copy text to the system clipboard
#
# Usage:
#   pbcopy              # Copy from command line (interactive)
#   echo "text" | pbcopy # Copy from piped input
#
# Input Behavior:
#   - Interactive (stdin is TTY): Copies the current command line selection,
#     or the entire command line if nothing is selected. Useful as a keybinding.
#   - Piped input: Copies the piped text. Trailing newlines are stripped for
#     single-line input but preserved for multi-line input.
#
# Output Method:
#   - Local macOS (not remote, native pbcopy available): Uses the native
#     macOS pbcopy command for direct clipboard access.
#   - Remote/SSH or no native pbcopy: Uses OSC 52 escape sequence to copy
#     via the terminal emulator. Requires terminal support (most modern
#     terminals like iTerm2, kitty, alacritty support this).
#   - Falls back with an error if base64 is unavailable or TERM is "dumb".
#
# See also: pbclean (paste, clean, and re-copy), pbpaste

function pbcopy
    set -l cmdline
    set -l exit_status 0

    # Branch A: Execute arguments as a command and capture command + output
    if set -q argv[1]
        # Prevent intercepting basic helper flags intended for pbcopy itself
        if contains -- $argv[1] -h --help
            echo "Usage: pbcopy [command...]"
            return 0
        end

        set -l command_str
        if test (count $argv) -eq 1
            set command_str $argv[1]
        else
            set command_str "$argv[1] "(string join ' ' (string escape -- $argv[2..-1]))
        end

        set -l output
        # Execute silently and capture stdout and stderr mixed
        fish -c $argv 2>&1 | read -z output
        set exit_status $pipestatus[1]

        # Format clipboard content, preventing an extraneous newline if output is empty
        set cmdline "\$ $command_str"
        if test -n "$output"
            set cmdline "\$ $command_str
$output"
        end

        # Branch B: Standard pbcopy input (interactive selection or piped input)
    else
        set -l is_tty_stdin 0
        if isatty stdin
            set is_tty_stdin 1
        end

        if test $is_tty_stdin -eq 1
            set cmdline (commandline --current-selection | fish_indent --only-indent | string collect)
            test -n "$cmdline"; or set cmdline (commandline | fish_indent --only-indent | string collect)
        else
            # Slurp the entire input (-0777).
            # Strips trailing newline for single-line strings.
            perl -0777 -pe 's/\n$// if !/\n./' | read -z cmdline
        end
    end

    # -----------------------------------------------------------------
    # Clipboard Backend Logic (Common to both branches)
    # -----------------------------------------------------------------
    if not is_remote; and type -q pbcopy
        printf '%s' "$cmdline" | command pbcopy
        return $exit_status
    end

    if not type -q base64; or test "$TERM" = dumb
        echo "pbcopy: cannot copy (no base64 or dumb terminal)" >&2
        return 1
    end

    set -l encoded (printf '%s' "$cmdline" | base64 | string join '')
    printf '\e]52;c;%s\a' "$encoded" >/dev/tty

    return $exit_status
end
