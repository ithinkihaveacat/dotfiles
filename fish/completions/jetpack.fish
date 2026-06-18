# completions for jetpack

# Disable file completions by default
complete -c jetpack -f

# Main help
complete -c jetpack -s h -l help -d 'Display help'

# Subcommands
complete -c jetpack -n __fish_use_subcommand -a version -d 'Get version for a package'
complete -c jetpack -n __fish_use_subcommand -a list -d 'List versions or dependencies'
complete -c jetpack -n __fish_use_subcommand -a resolve -d 'Convert package name to Maven coordinate'
complete -c jetpack -n __fish_use_subcommand -a source -d 'Download and extract source JARs'
complete -c jetpack -n __fish_use_subcommand -a inspect -d 'Resolve class name and download source'
complete -c jetpack -n __fish_use_subcommand -a resolve-exceptions -d 'Find missing exceptions for resolve'
complete -c jetpack -n __fish_use_subcommand -a search -d 'Search for artifacts by package or class name'

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
complete -c jetpack -n '__fish_seen_subcommand_from resolve-exceptions' -a 'ALPHA BETA RC STABLE LATEST SNAPSHOT' -d 'Symbolic version'

# list subcommands
complete -c jetpack -n '__fish_seen_subcommand_from list; and not __fish_seen_subcommand_from versions dependencies' -a versions -d 'List all versions for a given Maven artifact'
complete -c jetpack -n '__fish_seen_subcommand_from list; and not __fish_seen_subcommand_from versions dependencies' -a dependencies -d 'List direct Maven dependencies for an artifact'

# list versions
complete -c jetpack -n '__fish_seen_subcommand_from list; and __fish_seen_subcommand_from versions' -s h -l help -d 'Display help'

# list dependencies
complete -c jetpack -n '__fish_seen_subcommand_from list; and __fish_seen_subcommand_from dependencies' -s h -l help -d 'Display help'
complete -c jetpack -n '__fish_seen_subcommand_from list; and __fish_seen_subcommand_from dependencies' -a 'ALPHA BETA RC STABLE LATEST SNAPSHOT' -d 'Symbolic version'

# search subcommand
complete -c jetpack -n '__fish_seen_subcommand_from search' -s h -l help -d 'Display help'
complete -c jetpack -n '__fish_seen_subcommand_from search' -l force -d 'Force cache rebuild'
