function amp-cloudflare-validator -d "Query Cloudflare for URL validity"
  if test ( count $argv ) -eq 0
    echo "usage: $_ url"
    return 1
  end
  if string match -q -r "^https://" $argv[1]
    set URL (string replace -r "^https://" "s/" $argv[1])
  else
    set URL (string replace -r "^http://" "" $argv[1])
  end
  curl -s (printf "https://amp.cloudflare.com/q/%s" $URL)
end
