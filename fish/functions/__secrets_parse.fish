function __secrets_parse --description 'Print each secret in the secrets files as NAME=value'
    # $argv[1] names the calling command, for error messages. Reads the
    # plaintext file $argv[2] if given; otherwise reads, in order, for each
    # overlay in ~/.private and ~/.corp:
    #
    #   fish/secrets.shared.env   committed, values every machine may hold
    #   fish/secrets.env.age      this machine only, decrypted with age, or
    #   fish/secrets.env          this machine only, if there is no .age file
    #
    # Missing files are skipped, but at least one must exist. Each file holds
    # NAME=value lines; blank lines and lines starting with # are ignored,
    # nothing is expanded, and one pair of matching quotes around a value is
    # removed. A later line for the same NAME wins, within a file and across
    # files. Never echo a line back: it may hold a secret.
    set -l prog $argv[1]
    set -l files
    if set -q argv[2]
        set files $argv[2]
    else
        for dir in $HOME/.private/fish $HOME/.corp/fish
            test -e $dir/secrets.shared.env; and set -a files $dir/secrets.shared.env
            if test -e $dir/secrets.env.age
                set -a files $dir/secrets.env.age
            else if test -e $dir/secrets.env
                set -a files $dir/secrets.env
            end
        end
        if test (count $files) -eq 0
            echo "$prog: no secrets file found; see 'getsecret --help'" >&2
            return 1
        end
    end

    set -l names
    set -l values
    for file in $files
        set -l lines
        if string match -q -- '*.age' $file
            set -l identity $HOME/.config/age/secrets-identity.txt
            if not command -q age
                echo "$prog: age not found" >&2
                return 127
            end
            if not test -r $identity
                echo "$prog: $identity not readable" >&2
                return 1
            end
            set lines (age --decrypt --identity $identity $file)
            or begin
                echo "$prog: cannot decrypt $file" >&2
                return 1
            end
        else
            set lines (cat $file); or return
        end

        set -l n 0
        for line in $lines
            set n (math $n + 1)
            string match -qr '^\s*(#|$)' -- $line; and continue
            set -l m (string match -r '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$' -- $line)
            if test (count $m) -ne 3
                echo "$prog: $file line $n is not NAME=value; ignored" >&2
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
    end

    test (count $names) -gt 0; or return 0
    for i in (seq (count $names))
        printf '%s=%s\n' $names[$i] $values[$i]
    end
end
