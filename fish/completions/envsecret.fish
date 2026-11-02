complete -c envsecret -f -a '(__secrets_parse envsecret 2>/dev/null | string replace -r "=.*" "")'
