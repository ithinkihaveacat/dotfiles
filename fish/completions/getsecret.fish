complete -c getsecret -f -a '(__secrets_parse getsecret 2>/dev/null | string replace -r "=.*" "")'
complete -c getsecret -s h -l help -d 'Display help and exit'
