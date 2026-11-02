complete -c setsecret -f -l if-unset -d 'Skip already-set names instead of erroring'
complete -c setsecret -f -a '(__secrets_parse setsecret 2>/dev/null | string replace -r "=.*" "")'
complete -c setsecret -s h -l help -d 'Display help and exit'
