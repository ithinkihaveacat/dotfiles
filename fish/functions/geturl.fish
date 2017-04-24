function geturl -d "Save URL to file"
  if test -n "$ACCESS_TOKEN"
    curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -O $argv
  else
    curl -s -O $argv
  end
end
