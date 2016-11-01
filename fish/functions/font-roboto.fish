# https://github.com/google/roboto/releases

function font-roboto

  set DIR (fontdir)/roboto
  set URL 'https://codeload.github.com/google/roboto/zip/v2.134'

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  unzip -j (curl -s $URL | psub) '*.ttf' -d $DIR

end