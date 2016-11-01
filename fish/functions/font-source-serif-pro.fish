# https://github.com/adobe-fonts/source-serif-pro/releases

set DIR (fontdir)/source-serif-pro
set URL 'https://codeload.github.com/adobe-fonts/source-serif-pro/zip/1.017R'

if test -d $DIR
  echo "$DIR already installed"
  exit 0
end

mkdir -p $DIR
unzip -j (curl -s $URL | psub) '*.otf' -d $DIR
