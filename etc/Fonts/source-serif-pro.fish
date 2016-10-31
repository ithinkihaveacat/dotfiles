# https://github.com/adobe-fonts/source-serif-pro/releases

set DIR source-serif-pro
set URL 'https://codeload.github.com/adobe-fonts/source-serif-pro/zip/1.017R'

if test -d $DIR
  echo "$DIR already installed"
  exit 0
end

unzip -j (curl -s $URL | psub) '*.otf' -d $DIR
