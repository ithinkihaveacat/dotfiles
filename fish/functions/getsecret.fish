function getsecret --description 'Print a secret from the secrets files to stdout'
    if contains -- "$argv[1]" -h --help
        echo "Usage: getsecret NAME

Print the value of a secret to stdout, without setting it in the current shell.
Intended for use in command substitution or scripts.

Arguments:
  NAME          Name of the secret to read

Options:
  -h, --help    Display this help message and exit

Examples:
  getsecret GITHUB_TOKEN
  curl -H \"Authorization: Bearer (getsecret PINBOARD_API_TOKEN)\" ...
  getsecret GEMINI_API_KEY | pbcopy

Secrets are read from these files in order, skipping any that are missing; a
later value for the same NAME wins:

  ~/.private/fish/secrets.shared.env  personal, committed, on every machine
  ~/.private/fish/secrets.env.age     personal, this machine only (or
  ~/.private/fish/secrets.env           this one if there is no .age file)
  ~/.corp/fish/secrets.shared.env     work, committed, on every work machine
  ~/.corp/fish/secrets.env.age        work, this machine only (or
  ~/.corp/fish/secrets.env              this one if there is no .age file)

A shared file is committed with its overlay, so it holds only values that are
acceptable to leak (scoped, spend-capped, cheap to rotate); the others are
ignored by Git. .age files are decrypted with the identity in
~/.config/age/secrets-identity.txt. Edit any of them with editsecrets."
        return 0
    end

    if test (count $argv) -ne 1
        echo "Usage: getsecret NAME

Print the value of a secret to stdout.

Examples:
  getsecret GITHUB_TOKEN

Try 'getsecret --help' for more information." >&2
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
