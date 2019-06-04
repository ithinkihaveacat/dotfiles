function geturl -w curl -d "Save URL to file"
  if test -n "$ACCESS_TOKEN"
    curl -sSL -H "Authorization: Bearer $ACCESS_TOKEN" --remote-name-all $argv
    if test "$status" -eq 23
      printf "error: %s\n" (status current-command)
    end
  else
    curl -sSL --remote-name-all $argv
  end
end
