# https://rsms.me/inter/

function font-inter

  set DIR (fontdir)/plex
  set URL (curl -sSL https://api.github.com/repos/rsms/inter/releases | jq -r '.[0].assets | .[].browser_download_url')
  
  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  else
    mkdir -p $DIR
  end

  unzip -j (curl -sL $URL | psub) 'Inter (TTF)/*.ttf' -d $DIR

end
