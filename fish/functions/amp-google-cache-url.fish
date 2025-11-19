function amp-google-cache-url -d "Get Google AMP Cache URL"
    # Alternative: https://www.npmjs.com/package/@ampproject/toolbox-cache-url

    if test ( count $argv ) -ne 1
        printf "usage: %s URL\n" (status current-command)
        return
    end

    amp-google-status $argv[1] | jq -r .ampUrls[0].cdnAmpUrl
end
