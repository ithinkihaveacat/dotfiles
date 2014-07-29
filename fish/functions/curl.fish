function curl -d "transfer a URL, with Authorization support"
  if test -n "$CURL_AUTHORIZATION"
    set header "-H \"Authorization: $CURL_AUTHORIZATION\""
  else
    set header ""
  end
  command curl $header $argv
end
