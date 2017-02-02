function getmd -d "Retrieve single URL, convert to markdown"
  if test -z $MERCURY_API_KEY
    echo "error: MERCURY_API_KEY not set"
    return 1
  end
  if test -z $argv[1]
    echo "usage: $_ url"
    return 1
  end
  curl -s -G --data-urlencode (printf "url=%s" $argv[1]) -H "x-api-key: $MERCURY_API_KEY" https://mercury.postlight.com/parser | jq -r .content | pandoc -f html -t markdown
end
