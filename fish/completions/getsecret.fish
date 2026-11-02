complete -c getsecret -f -a '(__secrets_parse getsecret 2>/dev/null | string replace -r "=.*" "")'
