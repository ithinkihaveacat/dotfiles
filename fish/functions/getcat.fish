function getcat -w curl -d "Retrieve single URL, output to stdout"
    if test -n "$ACCESS_TOKEN"
        set -gx CURL_CMD "curl -sSL --output - -H \"Authorization: Bearer $ACCESS_TOKEN\"" (string escape -- $argv)
    else
        set -gx CURL_CMD "curl -sSL --output -" (string escape -- $argv)
    end
    echo $CURL_CMD | source
    if test "$status" -eq 23
        printf "error: %s\n" (status current-command)
    end
end
