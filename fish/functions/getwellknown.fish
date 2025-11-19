function getwellknown -d "Retrieve .well-known (and similar) URLs, output to stdout"

    # https://developers.google.com/identity/smartlock-passwords/android/associate-apps-and-sites
    echo "# $argv/.well-known/assetlinks.json"
    curl -sSi "{$argv}/.well-known/assetlinks.json" | head -1

    # https://developer.apple.com/reference/security/1654440-shared_web_credentials
    # https://developer.apple.com/library/content/documentation/General/Conceptual/AppSearch/UniversalLinks.html
    # https://branch.io/resources/aasa-validator/
    # https://search.developer.apple.com/appsearch-validation-tool
    echo "# $argv/apple-app-site-association"
    curl -sSi "{$argv}/apple-app-site-association" | head -1
    echo "# $argv/.well-known/apple-app-site-association"
    curl -sSi "{$argv}/.well-known/apple-app-site-association" | head -1
    echo "# $argv/.well-known/change-password"
    curl -sSi "{$argv}/.well-known/change-password" | head 1

end
