function getcat -w curl -d "Retrieve single URL, output to stdout"
  if test -n "$ACCESS_TOKEN"
    set -gx CURL_CMD "curl -sSL --output - -H \"Authorization: Bearer $ACCESS_TOKEN\" '$argv'"
  else
    set -gx CURL_CMD "curl -sSL --output - '$argv'"
  end
  eval $CURL_CMD
  if test "$status" -eq 23
    printf "error: %s\n" (status current-command)
  end
end
