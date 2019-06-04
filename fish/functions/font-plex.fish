# https://ibm.github.io/type/

function font-plex

  set DIR (fontdir)/plex
  set URL (github-download-url IBM/plex | grep OpenType)

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  unzip -j (curl -sL $URL | psub) '*.otf' -d $DIR

end
