function token.info -d "Get information about a Google access token"
  if test ( count $argv ) -eq 0
    echo "usage: $_ access_token"
    return
  end
  set url "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=$argv[1]"
  echo "# $url"
  curl -s $url
end
