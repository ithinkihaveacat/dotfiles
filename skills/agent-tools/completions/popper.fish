complete -c popper -f

# Helper function: get list of installed packages
function __fish_popper_list_packages
    adb shell pm list packages 2>/dev/null | string replace 'package:' ''
end

complete -c popper -l launch -x -a '(__fish_popper_list_packages)' -d "Launch the specified app before starting"
complete -c popper -l stay-in-app -d "Restrict the run to a single application package"
complete -c popper -l timeout -x -d "Maximum execution time in seconds"
complete -c popper -l output-format -x -a "text stream-json" -d "Output format"
complete -c popper -l agent-screenshots -d "Enable transmitting screenshots to the Gemini API"
complete -c popper -l no-agent-screenshots -d "Disable transmitting screenshots to the Gemini API"
complete -c popper -l local-screenshots -d "Enable saving debug screenshots to local disk"
complete -c popper -l no-local-screenshots -d "Disable saving debug screenshots to local disk"
complete -c popper -l local-screenshot-dir -r -d "Directory for step-by-step debug screenshots"
complete -c popper -l output-dir -r -d "Directory for screenshots requested by the agent"
complete -c popper -l model -x -d "Gemini model to use"
complete -c popper -l dump-layout -d "Print the current simplified UI layout as JSON and exit"
complete -c popper -s h -l help -d "Display help message and exit"
