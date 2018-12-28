function token.info.id -d "Get information about a Google id token"
  if test ( count $argv ) -eq 0
    printf "usage: %s id_token" (status current-command)
    return
  end
  set url "https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=$argv[1]"
  echo "# $url"
  curl -sS $url
end
