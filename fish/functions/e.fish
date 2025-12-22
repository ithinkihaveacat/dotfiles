function e -d 'Edit file, searching in a few different places'

    if test ( count $argv ) -ne 1
        printf "usage: %s filename" (status current-command)
        return
    end

    if test -f $argv[1]
        eval $EDITOR $argv[1]
        return
    end

    # Strip .fish extension if present (e.g., "foo.fish" -> "foo")
    set -l name (string replace -r '\.fish$' '' $argv[1])

    if not type -q $name
        printf "%s: '%s' not found, or not a file\n" (status current-command) $argv[1]
        return
    end

    switch ( type -t $name )

        case file

            if file ( type -p $name ) | grep text >/dev/null
                eval $EDITOR ( type -p $name )
            else
                echo "error: '$name' is not a text file"
            end

        case function

            set -l type_output (type $name)
            set -l def_line (string match -r '# Defined in .*' $type_output)

            if test -n "$def_line"
                set -l func_file (string replace '# Defined in ' '' $def_line | string trim)
                # Further clean the path to remove potential line number and column info
                set func_file (echo $func_file | string match -r '^[^ @]+')
                if test -f "$func_file"
                    eval $EDITOR "$func_file"
                else
                    echo "error: file '$func_file' for function '$name' not found"
                end
            else
                echo "error: could not determine file for function '$name'"
            end

        case '*'

            echo "error: '$name' not found"

    end

end
