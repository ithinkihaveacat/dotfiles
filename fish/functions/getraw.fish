function getraw -w curl -d "Retrieve single URL (including headers), output to stdout"
  if test -n "$ACCESS_TOKEN"
    curl -sS -i --max-redirs 0 -H "Authorization: Bearer $ACCESS_TOKEN" $argv
  else
    curl -sS -i --max-redirs 0 $argv
  end
end
