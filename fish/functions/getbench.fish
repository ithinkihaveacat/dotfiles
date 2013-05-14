function gettime -d "How long does it take to retrieve a URL?"
  curl -kso /dev/null -w "dns: %{time_namelookup} tcp:%{time_connect} ssl:%{time_appconnect}\n" $argv
end
