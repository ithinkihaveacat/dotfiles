function getcat -d "Retrieve single URL, output to stdout"
  if test -n "$ACCESS_TOKEN"
    curl -sS -H "Authorization: Bearer $ACCESS_TOKEN" $argv
    if test "$status" -eq 23
      echo "error: $_ "
    end
  else
    curl -sS $argv
  end
end
