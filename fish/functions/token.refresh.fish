# https://developers.google.com/accounts/docs/OAuth2WebServer#refresh

function token.refresh -d "Get access token from a refresh token"

  # set -xU CLIENT_ID "212696220856-2mrcaejro9o098rpdod53kpld0athcuf.apps.googleusercontent.com"
  # set -xU CLIENT_SECRET "xK0v4Ldw_8BUWnrTQJn3YbEG"

  if test -z "$CLIENT_ID"
    echo "error: CLIENT_ID not set; create 'Other' client via https://console.developers.google.com/project"
    return
  end

  if test -z "$CLIENT_SECRET"
    echo "error: CLIENT_SECRET not set; create 'Other' client via https://console.developers.google.com/project"
    return
  end

  if test ( count $argv ) -ne 1
    echo "usage: $_ refresh_token"
    return
  end

  set URI "https://www.googleapis.com/oauth2/v4/token"

  curl -sS $URI -d client_id=$CLIENT_ID -d client_secret=$CLIENT_SECRET -d refresh_token=$argv[1] -d grant_type=refresh_token

end
