complete -c popper -f

# Helper function: get list of installed packages
function __fish_popper_list_packages
    adb shell pm list packages 2>/dev/null | string replace 'package:' ''
end

complete -c popper -l app -x -a '(__fish_popper_list_packages)' -d "Launch the specified app before starting"
complete -c popper -l timeout -x -d "Maximum execution time in seconds"
complete -c popper -l output-format -x -a "text stream-json" -d "Output format"
complete -c popper -l screenshots -d "Enable screenshot capture and transmission to the model"
complete -c popper -l no-screenshots -d "Disable screenshot capture and transmission to the model"
complete -c popper -l help -d "Display help message and exit"
