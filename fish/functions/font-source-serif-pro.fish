# https://github.com/adobe-fonts/source-serif-pro/releases

function font-source-serif-pro

  set DIR (fontdir)/source-serif-pro
  set URL 'https://codeload.github.com/adobe-fonts/source-serif-pro/zip/2.007R-ro/1.007R-it'

  if test -d $DIR
    echo "error: $DIR already installed"
    return 1
  end

  mkdir -p $DIR
  unzip -j (curl -s $URL | psub) '*.otf' -d $DIR

end
