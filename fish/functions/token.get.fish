function token.get -d "Gets OpenID Connect tokens and assertions"

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

  if test ( count $argv ) -eq 0
    printf "usage: %s scope # e.g. %s email profile\n" (status current-command) (status current-command)
    return
  end

  # https://accounts.google.com/.well-known/openid-configuration
  set -l AUTH_URI "https://accounts.google.com/o/oauth2/v2/auth"
  set -l TOKEN_URI "https://www.googleapis.com/oauth2/v4/token"

  set -l REDIRECT_URI "urn:ietf:wg:oauth:2.0:oob"
  set -l SCOPE (echo "openid $argv" | perl -MURI::Escape -ne 'chomp; print uri_escape($_);')
  set -l NONCE "qqqqqqqq" # embedded into the returned id_token

  # https://developers.google.com/identity/protocols/OpenIDConnect?hl=en#authenticationuriparameters
  echo "$AUTH_URI?client_id=$CLIENT_ID&response_type=code&scope=$SCOPE&redirect_uri=$REDIRECT_URI&nonce=$NONCE" | pbcopy

  echo "OpenID Connect URL copied to your clipboard; load it, and paste the returned code below"
  read -l CODE

  curl $TOKEN_URI -d client_id=$CLIENT_ID -d client_secret=$CLIENT_SECRET -d redirect_uri=$REDIRECT_URI -d grant_type=authorization_code -d code=$CODE

end
