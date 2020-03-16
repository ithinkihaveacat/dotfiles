function getsxg -w curl -d "Get URL as SXG"
  set -gx CURL_CMD "curl -sS --output - -H 'accept: application/signed-exchange;v=b3' -H 'amp-cache-transform: google;v=\"1..100\"'" (string escape -- $argv)
  echo $CURL_CMD | source
end
