function setsecret --description 'Load secret(s) from the secrets files into env'
    if contains -- "$argv[1]" -h --help
        echo "Usage: setsecret [--if-unset] NAME [NAME...]

Load one or more secrets into the current shell as exported variables. Errors
if a named variable is already set, unless --if-unset is given.

Arguments:
  NAME          Name of the secret variable to load

Options:
  --if-unset    Skip variables that are already set instead of erroring
  -h, --help    Display this help message and exit

Examples:
  setsecret GITHUB_TOKEN
  setsecret HASS_SERVER HASS_TOKEN
  setsecret --if-unset GEMINI_API_KEY GITHUB_TOKEN

Secrets are read from the secrets files in ~/.private and ~/.corp; see
getsecret --help for the files and their order."
        return 0
    end
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
                if not string match -qr '^[A-Za-z_][A-Za-z0-9_]*$' -- $arg
                    echo "setsecret: invalid name: $arg" >&2
                    return 1
                end
                set -a names $arg
        end
    end

    if test (count $names) -eq 0
        echo "Usage: setsecret [--if-unset] NAME [NAME...]

Load secrets into the current shell as exported variables.

Examples:
  setsecret HASS_SERVER HASS_TOKEN

Try 'setsecret --help' for more information." >&2
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

    set -l entries (__secrets_parse setsecret); or return

    set -l rc 0
    for name in $to_load
        set -l value (string replace -rf "^$name=" '' -- $entries)[-1]
        if test -z "$value"
            echo "setsecret: $name is unset or empty" >&2
            set rc 1
            continue
        end
        set -gx $name $value
    end

    return $rc
end
