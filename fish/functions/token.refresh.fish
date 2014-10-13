# https://developers.google.com/accounts/docs/OAuth2WebServer#refresh

function token.refresh -d "Get access token from a refresh token"
  if test ( count $argv ) -ne 3
    echo "usage: $_ client_id client_secret refresh_token"
    return
  end
  set url "https://accounts.google.com/o/oauth2/token"
  curl -s $url -d client_id=$argv[1] -d client_secret=$argv[2] -d refresh_token=$argv[3] -d grant_type=refresh_token
end
