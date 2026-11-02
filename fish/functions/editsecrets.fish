function editsecrets --description 'Edit ~/.private/fish/secrets.env[.age] in $EDITOR'
    if contains -- --help $argv
        echo "Usage: editsecrets

Open the secrets file in \$VISUAL or \$EDITOR, then check that every line is
NAME=value (blank lines and # comments are allowed).

If ~/.private/fish/secrets.env.age exists, it is decrypted into a private
temporary directory with the identity in ~/.config/age/secrets-identity.txt,
and re-encrypted on save to every recipient in
~/.config/age/secrets-recipients.txt; the previous encrypted file is kept as
secrets.env.age~. Otherwise ~/.private/fish/secrets.env is edited in place.

Options:
  --help        Display this help message and exit

Examples:
  editsecrets
  EDITOR=nano editsecrets

To encrypt an existing plaintext file:
  age --encrypt --recipients-file ~/.config/age/secrets-recipients.txt \\
    --output ~/.private/fish/secrets.env.age ~/.private/fish/secrets.env"
        return 0
    end

    if test (count $argv) -ne 0
        echo "editsecrets: unexpected argument: $argv[1]" >&2
        echo "Try 'editsecrets --help' for more information." >&2
        return 1
    end

    set -l dir $HOME/.private/fish
    set -l editor $VISUAL
    test -n "$editor"; or set editor $EDITOR
    test -n "$editor"; or set editor vi

    if not test -e $dir/secrets.env.age
        if not test -e $dir/secrets.env
            echo "editsecrets: neither $dir/secrets.env.age nor $dir/secrets.env exists" >&2
            return 1
        end
        eval $editor (string escape -- $dir/secrets.env); or return
        __secrets_parse editsecrets $dir/secrets.env >/dev/null
        return 0
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
    if not age --decrypt --identity $identity --output $plain $dir/secrets.env.age
        echo "editsecrets: cannot decrypt $dir/secrets.env.age" >&2
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
    cp -p $dir/secrets.env.age $dir/secrets.env.age~
    and mv $tmp/secrets.env.age $dir/secrets.env.age
    set -l rc $status
    rm -rf $tmp
    test $rc -eq 0; and echo "editsecrets: saved $dir/secrets.env.age" >&2
    return $rc
end
