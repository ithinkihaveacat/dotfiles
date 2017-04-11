function getetag -d "Retrieve single URL, then conditionally retrieve same URL with ETags"

  if test (count $argv) -ne 1
    echo "error: $_ URL"
    return 1
  end
  
  set -l httpcode (curl -s -o /dev/null -w "%{http_code}" $argv[1])
  if test $httpcode -ne 200
    curl $argv[1]
    return 1
  end

  set -l urleffective (curl -sL -o /dev/null -w "%{url_effective}" $argv[1])
  echo "GET $urleffective"
  
  set -l etag (curl -s -D - -o /dev/null $argv | grep -Ei '^etag' | awk '{ printf "%s", $2 }')
  echo L (string length $etag)
  if test "(string trim $etag)" = ""
    echo "ETag: $etag"
    echo
  else
    echo "error: no ETag support"
    return 1
  end

  set -l header (printf "if-none-match: %s" (string trim $etag))
  curl -s -D - -o /dev/null -H $header $argv

#  set -l httpcode (curl -s -o /dev/null -H $header -w "%{http_code}" $argv)
#  echo $httpcode

end
