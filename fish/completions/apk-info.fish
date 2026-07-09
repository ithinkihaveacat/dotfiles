# completions for apk-info

# Disable default file completions
complete -c apk-info -f

# Subcommands list
set -l subcommands package manifest version libraries tiles complications launcher file

# Complete subcommands
complete -c apk-info -n "not __fish_seen_subcommand_from $subcommands" -a package -d "Print package name (application ID)"
complete -c apk-info -n "not __fish_seen_subcommand_from $subcommands" -a manifest -d "Display formatted AndroidManifest.xml"
complete -c apk-info -n "not __fish_seen_subcommand_from $subcommands" -a version -d "Print package version name/code details"
complete -c apk-info -n "not __fish_seen_subcommand_from $subcommands" -a libraries -d "List/query embedded library versions"
complete -c apk-info -n "not __fish_seen_subcommand_from $subcommands" -a tiles -d "List Wear OS tiles services"
complete -c apk-info -n "not __fish_seen_subcommand_from $subcommands" -a complications -d "List Wear OS complications providers"
complete -c apk-info -n "not __fish_seen_subcommand_from $subcommands" -a launcher -d "Print launcher icon resource path"
complete -c apk-info -n "not __fish_seen_subcommand_from $subcommands" -a file -d "Extract and print a specific file"

# Complete APK/ZIP files once a subcommand is present
complete -c apk-info -n "__fish_seen_subcommand_from $subcommands" -F -a '(__fish_complete_suffix .apk .zip)'

# Subcommand-specific: version
complete -c apk-info -n "__fish_seen_subcommand_from version" -l code -d "Print only the version code string"
complete -c apk-info -n "__fish_seen_subcommand_from version" -l name -d "Print only the version name string"
complete -c apk-info -n "__fish_seen_subcommand_from version" -s h -l help -d "Display help"

# Subcommand-specific: libraries
complete -c apk-info -n "__fish_seen_subcommand_from libraries" -l json -d "Output all libraries as a JSON map"
complete -c apk-info -n "__fish_seen_subcommand_from libraries" -s h -l help -d "Display help"

# Common libraries for autocompleting the argument of --only / --library
set -l common_libs \
    androidx.wear.compose_compose-foundation \
    androidx.health_health-services-client \
    androidx.core_core \
    androidx.compose.ui_ui \
    androidx.lifecycle_lifecycle-runtime

complete -c apk-info -n "__fish_seen_subcommand_from libraries" -l only -r -a "$common_libs" -d "Print only the version of a specific library"
complete -c apk-info -n "__fish_seen_subcommand_from libraries" -l library -r -a "$common_libs" -d "Print only the version of a specific library"
