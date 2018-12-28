function token.info.access -d "Get information about a Google access token"
  if test ( count $argv ) -eq 0
    printf "usage: %s access_token\n" (status current-command)
    return
  end
  set url "https://www.googleapis.com/oauth2/v3/tokeninfo?access_token=$argv[1]"
  echo "# $url"
  curl -sS $url
end
