# https://ibm.github.io/type/

function font-plex

  set DIR (fontdir)/plex
  set URL 'https://github.com/IBM/type/archive/master.zip'

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  unzip -j (curl -sL $URL | psub) 'plex-master/*/fonts/complete/ttf/*.ttf' -d $DIR

end
