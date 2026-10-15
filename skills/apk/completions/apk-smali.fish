# completions for apk-smali

# Disable default file completions
complete -c apk-smali -f

set -l commands disassemble find show help
set -l show_commands class method annotations

# Commands
complete -c apk-smali -n "not __fish_seen_subcommand_from $commands" -a disassemble -d "Disassemble an APK or split-APK archive to one smali tree"
complete -c apk-smali -n "not __fish_seen_subcommand_from $commands" -a find -d "List classes matching predicates"
complete -c apk-smali -n "not __fish_seen_subcommand_from $commands" -a show -d "Print a class, method, or class annotations"
complete -c apk-smali -n "not __fish_seen_subcommand_from $commands" -a help -d "Display help for a command"

# Top-level options
complete -c apk-smali -s h -l help -d "Display help"

# disassemble
complete -c apk-smali -n "__fish_seen_subcommand_from disassemble" -F -a '(__fish_complete_suffix .apk .apks .xapk .aab .zip .dex)'
complete -c apk-smali -n "__fish_seen_subcommand_from disassemble" -s o -l output -r -F -d "Output directory"

# find
complete -c apk-smali -n "__fish_seen_subcommand_from find" -F -a '(__fish_complete_suffix .zip)'
complete -c apk-smali -n "__fish_seen_subcommand_from find" -l declares -r -d "Class declares METHOD"
complete -c apk-smali -n "__fish_seen_subcommand_from find" -l calls -r -d "Class invokes [CLASS]->METHOD"
complete -c apk-smali -n "__fish_seen_subcommand_from find" -l annotated-with -r -d "Class has a class-level annotation of type CLASS"
complete -c apk-smali -n "__fish_seen_subcommand_from find" -l extends -r -d "Direct superclass is CLASS"
complete -c apk-smali -n "__fish_seen_subcommand_from find" -l implements -r -d "Directly implements interface CLASS"
complete -c apk-smali -n "__fish_seen_subcommand_from find" -l methods -d "Print matching methods instead of classes"

# show
complete -c apk-smali -n "__fish_seen_subcommand_from show; and not __fish_seen_subcommand_from $show_commands" -a class -d "Print the whole class"
complete -c apk-smali -n "__fish_seen_subcommand_from show; and not __fish_seen_subcommand_from $show_commands" -a method -d "Print a method body"
complete -c apk-smali -n "__fish_seen_subcommand_from show; and not __fish_seen_subcommand_from $show_commands" -a annotations -d "Print class annotations"
complete -c apk-smali -n "__fish_seen_subcommand_from $show_commands" -F -a '(__fish_complete_suffix .zip)'
complete -c apk-smali -n "__fish_seen_subcommand_from method" -l depth -r -d "Follow same-class calls N levels deep"
complete -c apk-smali -n "__fish_seen_subcommand_from annotations" -l all -d "Include kotlin/Metadata and dalvik annotations"
complete -c apk-smali -n "__fish_seen_subcommand_from annotations" -l members -d "Also print field and method annotations"

# help COMMAND
complete -c apk-smali -n "__fish_seen_subcommand_from help" -a "disassemble find show"
