# Completions for e (edit file, searching in a few different places)

# Helper: list fish functions that have editable source files
function __fish_e_list_functions
    for fn in (functions -n)
        set -l src (functions -D $fn 2>/dev/null)
        if test -f "$src"
            echo $fn
        end
    end
end

# Helper: list completion file base names (without .fish extension)
function __fish_e_list_completions
    for f in $__fish_config_dir/completions/*.fish
        basename $f .fish
    end
end

# Helper: check if -c/--completion flag is present
function __fish_e_has_completion_flag
    set -l tokens (commandline -opc)
    for tok in $tokens
        switch $tok
            case -c --completion
                return 0
        end
    end
    return 1
end

# Helper: check if -f/--function flag is present
function __fish_e_has_function_flag
    set -l tokens (commandline -opc)
    for tok in $tokens
        switch $tok
            case -f --function
                return 0
        end
    end
    return 1
end

# Options
complete -c e -s h -l help -d 'Show help message'
complete -c e -s c -l completion -d 'Edit fish completion file for command'
complete -c e -s f -l function -d 'Edit fish function file for command'

# Completions based on flags
# With -c flag: complete with completion names
complete -c e -f -n __fish_e_has_completion_flag -a '(__fish_e_list_completions)' -d 'Completion'

# With -f flag: complete with function names
complete -c e -f -n __fish_e_has_function_flag -a '(__fish_e_list_functions)' -d 'Function'

# Without flags: complete with files, commands, and functions
complete -c e -n 'not __fish_e_has_completion_flag; and not __fish_e_has_function_flag' -a '(__fish_complete_command)' -d 'Command'
complete -c e -n 'not __fish_e_has_completion_flag; and not __fish_e_has_function_flag' -a '(__fish_e_list_functions)' -d 'Function'
