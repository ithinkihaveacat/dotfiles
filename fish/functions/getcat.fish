function getcat -w curl -d "Retrieve single URL, output to stdout"
  if test -n "$ACCESS_TOKEN"
    curl -sSL --output - -H "Authorization: Bearer $ACCESS_TOKEN" $argv
    if test "$status" -eq 23
      printf "error: %s\n" (status current-command)
    end
  else
    curl -sSL --output - $argv
  end
end
