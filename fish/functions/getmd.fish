function getmd -d "Retrieve single URL, convert to markdown"
  if test -z $MERCURY_API_KEY
    echo "error: MERCURY_API_KEY not set"
    return 1
  end
  if test -z $argv[1]
    printf "usage: %s URL\n" (status current-command)
    return 1
  end
  curl -sS -G --data-urlencode (printf "url=%s" $argv[1]) -H "x-api-key: $MERCURY_API_KEY" https://mercury.postlight.com/parser | jq -r .content | pandoc -f html -t markdown
end
