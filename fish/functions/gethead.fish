function gethead -w curl -d "Retrieve single URL, displaying headers only"
  set -gx CURL_CMD "curl -sS -D - -o /dev/null $argv"
  eval $CURL_CMD
end
