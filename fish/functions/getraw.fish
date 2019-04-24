function getraw -w curl -d "Retrieve single URL (including headers), output to stdout"
  if test -n "$ACCESS_TOKEN"
    curl -sS -i --raw --max-redirs 0 --output - -H "Authorization: Bearer $ACCESS_TOKEN" $argv
  else
    curl -sS -i --raw --max-redirs 0 --output - $argv
  end
end
