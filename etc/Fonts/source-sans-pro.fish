# https://github.com/adobe-fonts/source-sans-pro/releases

set DIR source-sans-pro
set URL 'https://codeload.github.com/adobe-fonts/source-sans-pro/zip/2.020R-ro/1.075R-it'
#set URL 'https://github.com/adobe-fonts/source-sans-pro/archive/2.020R-ro/1.075R-it.zip'

if test -d $DIR
  echo "$DIR already installed"
  exit 0
end

unzip -j (curl -s $URL | psub) '*.otf' -d $DIR
