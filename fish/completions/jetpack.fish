# completions for jetpack

# Disable file completions by default
complete -c jetpack -f

# Main help
complete -c jetpack -s h -l help -d 'Display help'

# Subcommands
complete -c jetpack -n __fish_use_subcommand -a version -d 'Get version for a package'
complete -c jetpack -n __fish_use_subcommand -a resolve -d 'Convert package name to Maven coordinate'
complete -c jetpack -n __fish_use_subcommand -a source -d 'Download and extract source JARs'
complete -c jetpack -n __fish_use_subcommand -a inspect -d 'Resolve class name and download source'
complete -c jetpack -n __fish_use_subcommand -a resolve-exceptions -d 'Find missing exceptions for resolve'

# version subcommand
complete -c jetpack -n '__fish_seen_subcommand_from version' -s h -l help -d 'Display help'
complete -c jetpack -n '__fish_seen_subcommand_from version' -a 'ALPHA BETA RC STABLE LATEST SNAPSHOT' -d 'Symbolic version type'

# resolve subcommand
complete -c jetpack -n '__fish_seen_subcommand_from resolve' -s h -l help -d 'Display help'

# source subcommand
complete -c jetpack -n '__fish_seen_subcommand_from source' -s h -l help -d 'Display help'
complete -c jetpack -n '__fish_seen_subcommand_from source' -l output -r -d 'Specify output directory'
complete -c jetpack -n '__fish_seen_subcommand_from source' -a 'ALPHA BETA RC STABLE LATEST SNAPSHOT' -d 'Symbolic (floating) version'

# inspect subcommand
complete -c jetpack -n '__fish_seen_subcommand_from inspect' -s h -l help -d 'Display help'
complete -c jetpack -n '__fish_seen_subcommand_from inspect' -l output -r -d 'Specify output directory'
complete -c jetpack -n '__fish_seen_subcommand_from inspect' -a 'ALPHA BETA RC STABLE LATEST SNAPSHOT' -d 'Symbolic (floating) version'

# resolve-exceptions subcommand
complete -c jetpack -n '__fish_seen_subcommand_from resolve-exceptions' -s h -l help -d 'Display help'
