function getwellknown -d "Retrieve .well-known (and similar) URLs, output to stdout"

  # https://developers.google.com/identity/smartlock-passwords/android/associate-apps-and-sites
  echo "# $argv/.well-known/assetlinks.json"
  curl -si "{$argv}/.well-known/assetlinks.json" | head -1
  
  # https://developer.apple.com/reference/security/1654440-shared_web_credentials
  # https://branch.io/resources/aasa-validator/
  # https://search.developer.apple.com/appsearch-validation-tool
  echo "# $argv/apple-app-site-association"
  curl -si "{$argv}/apple-app-site-association" | head -1
  
end
