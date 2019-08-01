function getsxg -w curl -d "Attempt to retrieve SXG for URL"
  curl -sS --output - -H 'accept: application/signed-exchange;v=b3' -H 'amp-cache-transform: google;v="1"' $argv
end
