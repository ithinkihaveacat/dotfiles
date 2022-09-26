function token-exchange -d "Exchanges an auth code for access, id and refresh tokens"

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
        printf "usage: %s auth_code\n" (status current-command)
        return
    end

    # https://accounts.google.com/.well-known/openid-configuration
    set -l TOKEN_URI "https://www.googleapis.com/oauth2/v4/token"

    set -l REDIRECT_URI "urn:ietf:wg:oauth:2.0:oob"

    curl $TOKEN_URI -d client_id=$CLIENT_ID -d client_secret=$CLIENT_SECRET -d redirect_uri=$REDIRECT_URI -d grant_type=authorization_code -d code=$argv

end
