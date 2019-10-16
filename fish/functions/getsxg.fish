function getsxg -w curl -d "Get URL as SXG"
  curl -sS --output - -H 'accept: application/signed-exchange;v=b3' -H 'amp-cache-transform: google;v="1..100"' $argv
end
