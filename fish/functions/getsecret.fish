function getsecret --description 'Print a secret from ~/.private/fish/secrets.env[.age] to stdout'
    if contains -- --help $argv
        echo "Usage: getsecret NAME

Print the value of a secret to stdout, without setting it in the current shell.
Intended for use in command substitution or scripts.

Secrets are read from ~/.private/fish/secrets.env.age (decrypted with age and
the identity in ~/.config/age/secrets-identity.txt) if it exists, otherwise
from ~/.private/fish/secrets.env. Edit either with editsecrets.

Arguments:
  NAME          Name of the secret to read

Options:
  --help        Display this help message and exit

Examples:
  getsecret GITHUB_TOKEN
  curl -H \"Authorization: Bearer (getsecret PINBOARD_API_TOKEN)\" ..."
        return 0
    end

    if test (count $argv) -ne 1
        echo "getsecret: missing NAME operand" >&2
        echo "Try 'getsecret --help' for more information." >&2
        return 1
    end
    set -l name $argv[1]
    if not string match -qr '^[A-Za-z_][A-Za-z0-9_]*$' -- $name
        echo "getsecret: invalid name: $name" >&2
        return 1
    end
    set -l entries (__secrets_parse getsecret); or return
    set -l value (string replace -rf "^$name=" '' -- $entries)[-1]
    if test -z "$value"
        echo "getsecret: $name is unset or empty" >&2
        return 1
    end
    printf '%s\n' $value
end
