function geturl -d "Save URL to file"
  if test -n "$ACCESS_TOKEN"
    curl -s -H "Authorization: Bearer $ACCESS_TOKEN" --remote-name-all $argv
    if test "$status" -eq 23
      echo "error: $_ "
    end
  else
    curl -s --remote-name-all $argv
  end
end
