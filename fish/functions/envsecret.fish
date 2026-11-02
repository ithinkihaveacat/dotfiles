function envsecret --description 'Run a command with secret env var(s) set, without leaking into the calling shell'
    if contains -- --help $argv
        echo "Usage: envsecret NAME [NAME...] [--] COMMAND [ARGS...]

Run COMMAND with one or more secrets injected into its environment. The
secrets are not set in the calling shell.

Uppercase identifiers at the start of the argument list are treated as secret
names. The first non-identifier argument (or an explicit --) begins the command.

Secrets are read from ~/.private/fish/secrets.env.age (decrypted with age) if
it exists, otherwise from ~/.private/fish/secrets.env; see getsecret --help.

Arguments:
  NAME          Name of the secret variable to inject
  COMMAND       Command to run with the secrets set

Options:
  --            Separator between secret names and the command
  --help        Display this help message and exit

Examples:
  envsecret GITHUB_TOKEN gh api user
  envsecret CLOUDFLARE_API_TOKEN -- wrangler whoami
  envsecret HASS_TOKEN HASS_SERVER ha state list"
        return 0
    end

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

    set -l entries (__secrets_parse envsecret); or return

    # Exported function-scoped variables reach COMMAND but not the calling
    # shell, and keep the values out of any process's arguments.
    for name in $names
        set -l value (string replace -rf "^$name=" '' -- $entries)[-1]
        if test -z "$value"
            echo "envsecret: $name is unset or empty" >&2
            return 1
        end
        set -fx $name $value
    end

    $cmd
end
