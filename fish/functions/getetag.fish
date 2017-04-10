function getetag -d "Retrieve single URL, then conditionally retrieve same URL with ETags"

  set -l httpcode (curl -s -o /dev/null -w "%{http_code}" $argv)
  if test $httpcode -ne 200
    if test ($httpcode -eq 302) -o ($httpcode -eq 301)
      set -l urleffective (curl -s -o /dev/null -w "%{url_effective}" $argv)
      echo "error: redirected to $urleffective"
      return 1
    else
      curl -s -D - -o /dev/null $argv
      return 1
    end
  end

  set -l etag (curl -s -D - -o /dev/null $argv | grep -Ei '^etag' | awk '{ printf "%s", $2 }')
  if test -z $etag
    echo "error: no ETag support"
    return 1
  end

  set -l header (printf "if-none-match: %s" (string trim $etag))
  curl -s -D - -o /dev/null -H $header $argv
end
