# https://github.com/adobe-fonts/source-code-pro/releases

function font-source-code-pro

  set DIR (fontdir)/source-code-pro
  set URL 'https://codeload.github.com/adobe-fonts/source-code-pro/zip/2.030R-ro/1.050R-it'

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  unzip -j (curl -s $URL | psub) '*.otf' -d $DIR

end