function getraw -d "Retrieve single URL (including headers), output to stdout"
  if test -n "$ACCESS_TOKEN"
    curl -s -i --max-redirs 0 -H "Authorization: Bearer $ACCESS_TOKEN" $argv
  else
    curl -s -i --max-redirs 0 $argv
  end
end
