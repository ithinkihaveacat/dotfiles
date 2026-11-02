function __secrets_parse --description 'Print each secret in the secrets file as NAME=value'
    # $argv[1] names the calling command, for error messages. Reads the
    # plaintext file $argv[2] if given, else ~/.private/fish/secrets.env.age
    # (decrypted with age) or, failing that, ~/.private/fish/secrets.env. The
    # file holds NAME=value lines; blank lines and lines starting with # are
    # ignored, nothing is expanded, and one pair of matching quotes around a
    # value is removed. A later line for the same NAME wins. Never echo a line
    # back: it may hold a secret.
    set -l prog $argv[1]
    set -l dir $HOME/.private/fish
    set -l lines
    if set -q argv[2]
        set lines (cat $argv[2]); or return
    else if test -e $dir/secrets.env.age
        set -l identity $HOME/.config/age/secrets-identity.txt
        if not command -q age
            echo "$prog: age not found" >&2
            return 127
        end
        if not test -r $identity
            echo "$prog: $identity not readable" >&2
            return 1
        end
        set lines (age --decrypt --identity $identity $dir/secrets.env.age)
        or begin
            echo "$prog: cannot decrypt $dir/secrets.env.age" >&2
            return 1
        end
    else if test -r $dir/secrets.env
        set lines (cat $dir/secrets.env)
    else
        echo "$prog: neither $dir/secrets.env.age nor $dir/secrets.env is readable" >&2
        return 1
    end

    set -l names
    set -l values
    set -l n 0
    for line in $lines
        set n (math $n + 1)
        string match -qr '^\s*(#|$)' -- $line; and continue
        set -l m (string match -r '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$' -- $line)
        if test (count $m) -ne 3
            echo "$prog: secrets file line $n is not NAME=value; ignored" >&2
            continue
        end
        set -l value $m[3]
        if string match -qr '^"(.*)"$|^\'(.*)\'$' -- $value
            set value (string sub --start 2 --end -1 -- $value)
        end
        set -l i (contains -i -- $m[2] $names)
        if test -n "$i"
            set values[$i] "$value"
        else
            set -a names $m[2]
            set -a values "$value"
        end
    end

    test (count $names) -gt 0; or return 0
    for i in (seq (count $names))
        printf '%s=%s\n' $names[$i] $values[$i]
    end
end
