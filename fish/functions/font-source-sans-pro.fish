# https://github.com/adobe-fonts/source-sans-pro/releases

function font-source-sans-pro

  set DIR (fontdir)/source-sans-pro
  set URL 'https://codeload.github.com/adobe-fonts/source-sans-pro/zip/2.040R-ro/1.090R-it'

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  unzip -j (curl -s $URL | psub) '*.otf' -d $DIR

end
