function geturl -w curl -d "Save URL to file"
  if test -n "$ACCESS_TOKEN"
    set -gx CURL_CMD "curl -sSL -H \"Authorization: Bearer $ACCESS_TOKEN\" --remote-name-all '$argv'"
  else
    set -gx CURL_CMD "curl -sSL --remote-name-all '$argv'"
  end
  eval $CURL_CMD
  if test "$status" -eq 23
    printf "error: %s\n" (status current-command)
  end
end
