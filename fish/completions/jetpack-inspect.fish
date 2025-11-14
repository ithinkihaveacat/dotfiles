# completions for jetpack-inspect
complete -c jetpack-inspect -s h -l help -d 'Display help'
complete -c jetpack-inspect -l output -r -d 'Specify output directory'
complete -c jetpack-inspect -f -a 'ALPHA BETA RC STABLE LATEST' -d 'Version type'
