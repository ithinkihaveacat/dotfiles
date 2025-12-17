function e -d 'Edit file, searching in a few different places'
    # Parse options
    argparse h/help c/completion f/function -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: e [OPTIONS] FILE..."
        echo
        echo "Edit files, searching in a few different places"
        echo
        echo "Options:"
        echo "  -h, --help        Show this help message"
        echo "  -c, --completion  Edit fish completion file for command"
        echo "  -f, --function    Edit fish function file for command"
        echo
        echo "Without flags, e will:"
        echo "  1. Open the file directly if it exists"
        echo "  2. If argument is an executable script in PATH, open it"
        echo "  3. If argument is a fish function, open its definition file"
        return 0
    end

    if test (count $argv) -eq 0
        printf "%s: missing file argument\n" (status current-command) >&2
        printf "Try '%s --help' for more information.\n" (status current-command) >&2
        return 1
    end

    set -l files_to_edit
    set -l errors 0

    for arg in $argv
        if set -q _flag_completion
            # Edit completion file
            set -l comp_file $__fish_config_dir/completions/$arg.fish
            if test -f $comp_file
                set -a files_to_edit $comp_file
            else
                printf "%s: completion file for '%s' not found at %s\n" (status current-command) $arg $comp_file >&2
                set errors (math $errors + 1)
            end
        else if set -q _flag_function
            # Edit function file explicitly
            if functions -q $arg
                set -l func_file (functions -D $arg)
                if test -f "$func_file"
                    set -a files_to_edit $func_file
                else
                    printf "%s: function '%s' is defined but source file not found\n" (status current-command) $arg >&2
                    set errors (math $errors + 1)
                end
            else
                printf "%s: function '%s' not found\n" (status current-command) $arg >&2
                set errors (math $errors + 1)
            end
        else
            # Default behavior: try file, then executable, then function
            if test -f $arg
                set -a files_to_edit $arg
            else if type -q $arg
                switch (type -t $arg)
                    case file
                        set -l cmd_path (type -p $arg)
                        if file $cmd_path | string match -q '*text*'
                            set -a files_to_edit $cmd_path
                        else
                            printf "%s: '%s' is not a text file\n" (status current-command) $arg >&2
                            set errors (math $errors + 1)
                        end
                    case function
                        set -l func_file (functions -D $arg)
                        if test -f "$func_file"
                            set -a files_to_edit $func_file
                        else
                            printf "%s: function '%s' source file not found (may be built-in or defined interactively)\n" (status current-command) $arg >&2
                            set errors (math $errors + 1)
                        end
                    case builtin
                        printf "%s: '%s' is a builtin command\n" (status current-command) $arg >&2
                        set errors (math $errors + 1)
                    case '*'
                        printf "%s: '%s' is a %s, cannot edit\n" (status current-command) $arg (type -t $arg) >&2
                        set errors (math $errors + 1)
                end
            else
                printf "%s: '%s' not found\n" (status current-command) $arg >&2
                set errors (math $errors + 1)
            end
        end
    end

    # Open all files in editor
    if test (count $files_to_edit) -gt 0
        $EDITOR $files_to_edit
    end

    # Return error if any files failed
    if test $errors -gt 0
        return 1
    end
end
