function getsecret --description 'Print secret value(s) from ~/.private/fish/secrets.fish to stdout'
    if contains -- --help $argv
        echo "Usage: getsecret NAME

Print the value of a secret from ~/.private/fish/secrets.fish to stdout,
without setting it in the current shell. Array values are printed one per line.
Intended for use in command substitution or scripts.

Arguments:
  NAME          Name of the secret variable to read

Options:
  --help        Display this help message and exit

Examples:
  getsecret GITHUB_API_KEY
  set keys (getsecret GEMINI_API_KEYS)
  curl -H \"Authorization: Bearer (getsecret OPENAI_API_KEY)\" ..."
        return 0
    end

    set -l file $HOME/.private/fish/secrets.fish
    if test (count $argv) -ne 1
        echo "getsecret: missing NAME operand" >&2
        echo "Try 'getsecret --help' for more information." >&2
        return 1
    end
    if not test -r $file
        echo "getsecret: $file not readable" >&2
        return 1
    end
    set -l name $argv[1]
    set -l values (fish --no-config -c '
        source $argv[1] 2>/dev/null
        set -q $argv[2]; or exit 1
        for v in $$argv[2]
            echo $v
        end
    ' $file $name)
    if test $status -ne 0
        echo "getsecret: $name is unset or empty in $file" >&2
        return 1
    end
    for v in $values
        echo $v
    end
end
