function setsecret --description 'Load secret(s) from ~/.private/fish/secrets.fish into env'
    if contains -- --help $argv
        echo "Usage: setsecret [--if-unset] NAME [NAME...]

Load one or more secrets from ~/.private/fish/secrets.fish into the current
shell as exported variables. Errors if a named variable is already set, unless
--if-unset is given.

Arguments:
  NAME          Name of the secret variable to load

Options:
  --if-unset    Skip variables that are already set instead of erroring
  --help        Display this help message and exit

Examples:
  setsecret GITHUB_API_KEY
  setsecret OPENAI_API_KEY MISTRAL_API_KEY
  setsecret --if-unset GEMINI_API_KEY GITHUB_API_KEY"
        return 0
    end

    set -l file $HOME/.private/fish/secrets.fish
    set -l if_unset 0
    set -l names

    for arg in $argv
        switch $arg
            case --if-unset
                set if_unset 1
            case --
                # accepted but ignored
            case '--*'
                echo "setsecret: unknown option: $arg" >&2
                echo "Try 'setsecret --help' for more information." >&2
                return 1
            case '*'
                set -a names $arg
        end
    end

    if test (count $names) -eq 0
        echo "setsecret: missing NAME operand" >&2
        echo "Try 'setsecret --help' for more information." >&2
        return 1
    end

    if not test -r $file
        echo "setsecret: $file not readable" >&2
        return 1
    end

    set -l to_load
    for name in $names
        if set -q $name
            if test $if_unset -eq 1
                continue
            end
            echo "setsecret: $name is already set" >&2
            return 1
        end
        set -a to_load $name
    end

    if test (count $to_load) -eq 0
        return 0
    end

    set -l output (fish --no-config -c '
        set -l file $argv[1]
        set -l names $argv[2..-1]
        source $file 2>/dev/null
        for name in $names
            printf "%s\t%s\n" $name "$$name"
        end
    ' $file $to_load)

    set -l rc 0
    for line in $output
        set -l parts (string split -m 1 \t -- $line)
        set -l name $parts[1]
        set -l value $parts[2]
        if test -z "$value"
            echo "setsecret: $name is unset or empty in $file" >&2
            set rc 1
            continue
        end
        set -gx $name $value
    end

    return $rc
end
