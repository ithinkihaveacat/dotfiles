function editsecrets --description 'Edit a secrets file in $EDITOR'
    if contains -- "$argv[1]" -h --help
        echo "Usage: editsecrets [FILE]

Open a secrets file in \$VISUAL or \$EDITOR, then check that every line is
NAME=value (blank lines and # comments are allowed).

Arguments:
  FILE          Secrets file to edit (default: this machine's personal file,
                ~/.private/fish/secrets.env.age, else secrets.env beside it)

Options:
  -h, --help    Display this help message and exit

Examples:
  editsecrets
  editsecrets ~/.private/fish/secrets.shared.env
  EDITOR=nano editsecrets ~/.corp/fish/secrets.env

A file ending in .age is decrypted into a private temporary directory with the
identity in ~/.config/age/secrets-identity.txt, and re-encrypted on save to
every recipient in ~/.config/age/secrets-recipients.txt; the previous encrypted
file is kept as FILE~. Any other file is edited in place, and created (mode
600) if it does not exist. See getsecret --help for every file that is read
and what belongs in each.

To encrypt an existing plaintext file:
  age --encrypt --recipients-file ~/.config/age/secrets-recipients.txt \\
    --output ~/.private/fish/secrets.env.age ~/.private/fish/secrets.env"
        return 0
    end

    if test (count $argv) -gt 1
        echo "editsecrets: unexpected argument: $argv[2]" >&2
        echo "Try 'editsecrets --help' for more information." >&2
        return 1
    end

    set -l target $argv[1]
    if string match -q -- '-*' $target
        echo "editsecrets: unknown option: $target" >&2
        echo "Try 'editsecrets --help' for more information." >&2
        return 1
    end
    if test -z "$target"
        set -l dir $HOME/.private/fish
        if test -e $dir/secrets.env.age
            set target $dir/secrets.env.age
        else if test -e $dir/secrets.env
            set target $dir/secrets.env
        else
            echo "editsecrets: neither $dir/secrets.env.age nor $dir/secrets.env exists" >&2
            echo "Try 'editsecrets FILE' to create one." >&2
            return 1
        end
    end

    set -l editor $VISUAL
    test -n "$editor"; or set editor $EDITOR
    test -n "$editor"; or set editor vi

    if not string match -q -- '*.age' $target
        if not test -e $target
            if not test -d (dirname -- $target)
                echo "editsecrets: no such directory: "(dirname -- $target) >&2
                return 1
            end
            touch $target; and chmod 600 $target; or return
        end
        eval $editor (string escape -- $target); or return
        __secrets_parse editsecrets $target >/dev/null
        return 0
    end

    if not test -e $target
        echo "editsecrets: $target does not exist" >&2
        return 1
    end
    set -l identity $HOME/.config/age/secrets-identity.txt
    set -l recipients $HOME/.config/age/secrets-recipients.txt
    if not command -q age
        echo "editsecrets: age not found" >&2
        return 127
    end
    for f in $identity $recipients
        if not test -r $f
            echo "editsecrets: $f not readable" >&2
            return 1
        end
    end

    set -l tmp (mktemp -d); or return
    chmod 700 $tmp
    set -l plain $tmp/secrets.env
    if not age --decrypt --identity $identity --output $plain $target
        echo "editsecrets: cannot decrypt $target" >&2
        rm -rf $tmp
        return 1
    end
    set -l before (shasum $plain | string split -f1 ' ')

    while true
        if not eval $editor (string escape -- $plain)
            echo "editsecrets: editor failed; nothing saved" >&2
            rm -rf $tmp
            return 1
        end
        set -l errors (__secrets_parse editsecrets $plain 2>&1 >/dev/null)
        test (count $errors) -eq 0; and break
        printf '%s\n' $errors >&2
        read -l -P 'Edit again? [Y/n] ' answer
        if string match -qir '^n' -- $answer
            echo "editsecrets: nothing saved" >&2
            rm -rf $tmp
            return 1
        end
    end

    if test (shasum $plain | string split -f1 ' ') = "$before"
        echo "editsecrets: no changes" >&2
        rm -rf $tmp
        return 0
    end

    if not age --encrypt --recipients-file $recipients --output $tmp/secrets.env.age $plain
        echo "editsecrets: cannot encrypt; nothing saved" >&2
        rm -rf $tmp
        return 1
    end
    chmod 600 $tmp/secrets.env.age
    cp -p $target $target~
    and mv $tmp/secrets.env.age $target
    set -l rc $status
    rm -rf $tmp
    test $rc -eq 0; and echo "editsecrets: saved $target" >&2
    return $rc
end
