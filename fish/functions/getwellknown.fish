function getwellknown -d "Retrieve .well-known (and similar) URLs, output to stdout"
    if contains -- --help $argv
        echo "Usage: getwellknown URL"
        echo ""
        echo "Retrieve .well-known (and similar) URLs, output to stdout."
        echo ""
        echo "Arguments:"
        echo "  URL         The base URL to query (e.g., https://example.com)"
        echo ""
        echo "Options:"
        echo "  --help      Display this help message and exit"
        echo ""
        echo "Examples:"
        echo "  getwellknown https://example.com"
        return 0
    end

    if test (count $argv) -eq 0
        echo "getwellknown: missing URL operand" >&2
        echo "Try 'getwellknown --help' for more information." >&2
        return 1
    end

    set -l url $argv[1]
    # Remove trailing slash if present
    set url (string replace -r '/$' '' -- $url)

    # https://developers.google.com/identity/smartlock-passwords/android/associate-apps-and-sites
    echo "# $url/.well-known/assetlinks.json"
    curl -sSi "$url/.well-known/assetlinks.json" | head -1

    # https://developer.apple.com/reference/security/1654440-shared_web_credentials
    # https://developer.apple.com/library/content/documentation/General/Conceptual/AppSearch/UniversalLinks.html
    # https://branch.io/resources/aasa-validator/
    # https://search.developer.apple.com/appsearch-validation-tool
    echo "# $url/apple-app-site-association"
    curl -sSi "$url/apple-app-site-association" | head -1

    echo "# $url/.well-known/apple-app-site-association"
    curl -sSi "$url/.well-known/apple-app-site-association" | head -1

    echo "# $url/.well-known/change-password"
    curl -sSi "$url/.well-known/change-password" | head -1
end
