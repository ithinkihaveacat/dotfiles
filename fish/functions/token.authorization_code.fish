# https://developers.google.com/accounts/docs/OAuth2WebServer#handlingtheresponse

function token.authorization_code -d "Get refresh token and access token from authorization code"
  if test ( count $argv ) -ne 4
    echo "usage: $_ client_id client_secret redirect_uri code"
    return
  end
  set url "https://accounts.google.com/o/oauth2/token"
  set scope "https://www.googleapis.com/auth/googlenow.publish"
  curl -s $url -d client_id=$argv[1] -d client_secret=$argv[2] -d redirect_uri=$argv[3] -d code=$argv[4] -d grant_type=authorization_code
end
