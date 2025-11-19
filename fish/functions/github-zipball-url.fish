function github-zipball-url -d 'Returns the zipball URL of the most recent release'

    # see also github-download-url

    if test ( count $argv ) -eq 0
        printf "usage: %s user/repo # e.g. %s IBM/plex\n" (status current-command) (status current-command)
        return
    end

    curl --fail -sSL https://api.github.com/repos/{$argv}/releases | jq -r '.[0].zipball_url'

end
