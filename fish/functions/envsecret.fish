function envsecret --description 'Run a command with secret env var(s) set, without leaking into the calling shell'
    if contains -- --help $argv
        echo "Usage: envsecret NAME [NAME...] [--] COMMAND [ARGS...]

Run COMMAND with one or more secrets from ~/.private/fish/secrets.fish injected
into its environment. The secrets are not set in the calling shell.

Uppercase identifiers at the start of the argument list are treated as secret
names. The first non-identifier argument (or an explicit --) begins the command.

Arguments:
  NAME          Name of the secret variable to inject
  COMMAND       Command to run with the secrets set

Options:
  --            Separator between secret names and the command
  --help        Display this help message and exit

Examples:
  envsecret GITHUB_API_KEY gh api user
  envsecret OPENAI_API_KEY -- python3 script.py
  envsecret HASS_TOKEN HASS_SERVER ha state list"
        return 0
    end

    set -l file $HOME/.private/fish/secrets.fish
    set -l names
    set -l cmd
    set -l mode names

    for arg in $argv
        switch $mode
            case names
                if test "$arg" = --
                    set mode cmd
                else if string match -qr '^[A-Z_][A-Z0-9_]*$' -- $arg
                    set -a names $arg
                else
                    set -a cmd $arg
                    set mode cmd
                end
            case cmd
                set -a cmd $arg
        end
    end

    if test (count $names) -eq 0
        echo "envsecret: missing NAME operand" >&2
        echo "Try 'envsecret --help' for more information." >&2
        return 1
    end

    if test (count $cmd) -eq 0
        echo "envsecret: no command given" >&2
        echo "Try 'envsecret --help' for more information." >&2
        return 1
    end

    if not test -r $file
        echo "envsecret: $file not readable" >&2
        return 1
    end

    set -l output (fish --no-config -c '
        set -l file $argv[1]
        set -l names $argv[2..-1]
        source $file 2>/dev/null
        for name in $names
            printf "%s\t%s\n" $name "$$name"
        end
    ' $file $names)

    set -l env_args
    for line in $output
        set -l parts (string split -m 1 \t -- $line)
        set -l name $parts[1]
        set -l value $parts[2]
        if test -z "$value"
            echo "envsecret: $name is unset or empty in $file" >&2
            return 1
        end
        set -a env_args "$name=$value"
    end

    env $env_args $cmd
end
