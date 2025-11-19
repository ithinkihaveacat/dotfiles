function getbench -w curl -d "How long does it take to retrieve a URL?"
    set -gx CURL_CMD "curl -ksSo /dev/null --compressed -w \"dns:%{time_namelookup} tcp:%{time_connect} ssl:%{time_appconnect} ttfb:%{time_starttransfer} total:%{time_total} (%{size_download} bytes)\n\"" (string escape -- $argv)
    echo $CURL_CMD | source
end
