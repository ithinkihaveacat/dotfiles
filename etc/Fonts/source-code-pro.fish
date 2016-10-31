# https://github.com/adobe-fonts/source-code-pro/releases

set DIR source-code-pro
set URL 'https://codeload.github.com/adobe-fonts/source-code-pro/zip/2.030R-ro/1.050R-it'

if test -d $DIR
  echo "$DIR already installed"
  exit 0
end

unzip -j (curl -s $URL | psub) '*.otf' -d $DIR
