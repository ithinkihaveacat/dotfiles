function getraw -w curl -d "Retrieve single URL (including headers), output to stdout"
    if test -n "$ACCESS_TOKEN"
        set -gx CURL_CMD "curl -sS -i --raw --max-redirs 0 --output - -H \"Authorization: Bearer $ACCESS_TOKEN\"" (string escape -- $argv)
    else
        set -gx CURL_CMD "curl -sS -i --raw --max-redirs 0 --output -" (string escape -- $argv)
    end
    echo $CURL_CMD | source
end
