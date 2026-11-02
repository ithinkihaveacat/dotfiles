function envsecret --description 'Run a command with secret env var(s) set, without leaking into the calling shell'
    # Only a leading -h or --help asks for help; later ones belong to COMMAND.
    if contains -- "$argv[1]" -h --help
        echo "Usage: envsecret NAME [NAME...] [--] COMMAND [ARGS...]

Run COMMAND with one or more secrets injected into its environment. The
secrets are not set in the calling shell.

Arguments:
  NAME          Name of the secret variable to inject; uppercase identifiers at
                the start of the arguments are names
  COMMAND       Command to run with the secrets set, starting at the first
                argument that is not a name, or after --

Options:
  --            Separator between secret names and the command
  -h, --help    Display this help message and exit

Examples:
  envsecret GITHUB_TOKEN gh api user
  envsecret CLOUDFLARE_API_TOKEN -- wrangler whoami
  envsecret HASS_TOKEN HASS_SERVER ha state list

Secrets are read from the secrets files in ~/.private and ~/.corp; see
getsecret --help for the files and their order."
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
        echo "Usage: envsecret NAME [NAME...] [--] COMMAND [ARGS...]

Run a command with secrets injected into its environment.

Examples:
  envsecret GITHUB_TOKEN gh api user

Try 'envsecret --help' for more information." >&2
        return 1
    end

    if test (count $cmd) -eq 0
        echo "Usage: envsecret NAME [NAME...] [--] COMMAND [ARGS...]

Run a command with secrets injected into its environment.

Examples:
  envsecret GITHUB_TOKEN gh api user

Try 'envsecret --help' for more information." >&2
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
