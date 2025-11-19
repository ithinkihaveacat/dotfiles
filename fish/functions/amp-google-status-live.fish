function amp-google-status-live -d "Query Google AMP CDN for URL validity (FETCH_LIVE_DOC strategy)"
    if test -z "$AMP_API_KEY"
        # https://developers.google.com/amp/cache/reference/authorizing
        echo "error: AMP_API_KEY must be set"
    end
    if test ( count $argv ) -eq 0
        printf "usage: %s canonical_url\n" (status current-command)
        return 1
    end
    # https://developers.google.com/amp/cache/reference/acceleratedmobilepageurl/rest/v1/ampUrls/batchGet#lookupstrategy
    # set STRATEGY IN_INDEX_DOC
    set -l STRATEGY FETCH_LIVE_DOC
    # https://developers.google.com/amp/cache/reference/acceleratedmobilepageurl/rest/v1/ampUrls/batchGet
    curl -s -X POST -d "{urls:['"$argv[1]"'],lookupStrategy:'"$STRATEGY"'}" -H "x-goog-api-key: $AMP_API_KEY" -H 'content-type: application/json' https://acceleratedmobilepageurl.googleapis.com/v1/ampUrls:batchGet
end
