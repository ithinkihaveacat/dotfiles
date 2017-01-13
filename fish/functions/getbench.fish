function getbench -d "How long does it take to retrieve a URL?"
  curl -kso /dev/null -w "dns:%{time_namelookup} tcp:%{time_connect} ssl:%{time_appconnect} ttfb:%{time_starttransfer} total:%{time_total} (%{size_download} bytes)\n" $argv
end
