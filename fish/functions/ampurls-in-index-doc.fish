function ampurls-in-index-doc -d "Map URL to corresponding AMP URL (IN_INDEX_DOC strategy)"
  if test -z "$AMP_API_KEY"
    # https://developers.google.com/amp/cache/reference/authorizing
    echo "error: AMP_API_KEY must be set"
  end
  if test ( count $argv ) -eq 0
    echo "usage: $_ url"
    return 1
  end
  # https://developers.google.com/amp/cache/reference/acceleratedmobilepageurl/rest/v1/ampUrls/batchGet#lookupstrategy
  set STRATEGY IN_INDEX_DOC
  # set STRATEGY FETCH_LIVE_DOC
  # https://developers.google.com/amp/cache/reference/acceleratedmobilepageurl/rest/v1/ampUrls/batchGet
  curl -s -X POST -d "{urls:['"$argv[1]"'],lookupStrategy:'"$STRATEGY"'}" -H "x-goog-api-key: $AMP_API_KEY" -H 'content-type: application/json' https://acceleratedmobilepageurl.googleapis.com/v1/ampUrls:batchGet
end
