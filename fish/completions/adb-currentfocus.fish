# completions for adb-currentfocus
complete -c adb-currentfocus -f
complete -c adb-currentfocus -s s -l serial -r -d 'Target device serial'

complete -c adb-currentfocus -s p -l packagename -d "Display the package name of the focused application (default)"
complete -c adb-currentfocus -s a -l activity -d "Display the package and activity name"
complete -c adb-currentfocus -s t -l toolkit -d "Display the detected UI toolkit"
complete -c adb-currentfocus -s d -l details -d "Display a detailed breakdown of the focused application and UI layout"
complete -c adb-currentfocus -s j -l json -d "Output all information as a JSON object"
complete -c adb-currentfocus -s h -l help -d "Display help"
