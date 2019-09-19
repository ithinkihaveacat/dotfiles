function github-download-url -d 'Returns the URL of the most recent release'

  # see also github-zipball-url

  if test ( count $argv ) -eq 0
    printf "usage: %s user/repo # e.g. %s IBM/plex\n" (status current-command) (status current-command)
    return
  end

  # Note that multiple URLs can be returned
  curl --fail -sSL https://api.github.com/repos/{$argv}/releases | jq -r '.[0].assets | .[].browser_download_url'

end
