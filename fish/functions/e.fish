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

            set -l func_file (type -p $name)
            if test -n "$func_file" -a -f "$func_file"
                eval $EDITOR "$func_file"
            else
                echo "error: function '$name' is interactively defined or file not found"
            end

        case '*'

            echo "error: '$name' not found"

    end

end
