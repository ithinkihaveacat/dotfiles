function getcond -d "Retrieve URL, then retrieve conditionally"

  if test (count $argv) -ne 1
    echo "error: $_ URL"
    return 1
  end
  
  set -l url (curl -sL -o /dev/null -w "%{url_effective}" $argv[1])
  if test $status -ne 0
    curl $argv[1]
    return 1
  end

  set -l etag (curl -s -D - -o /dev/null $url | grep -Ei '^etag' | awk '{ printf "%s", $2 }')

  if test -n (echo $etag)
    set -l header (printf "if-none-match: %s" (string trim $etag))
    echo "# etag"
    echo
    echo "GET $url"
    echo $header
    echo
    curl -s -D - -o /dev/null -H $header $url | head -1
    echo
  end

  set -l lastmodified (curl -s -D - -o /dev/null $url | grep -Ei '^last-modified' | awk '{ $1 = ""; printf "%s", $0 }')
  if test -n (echo $lastmodified)
    set -l header (printf "if-modified-since: %s" (string trim $lastmodified))
    echo "# last-modified"
    echo
    echo "GET $url"
    echo $header
    echo
    curl -s -D - -o /dev/null -H $header $url | head -1
  end

#  set -l httpcode (curl -s -o /dev/null -H $header -w "%{http_code}" $url)
#  echo $httpcode

end
