# https://github.com/google/roboto/releases

set DIR roboto
set URL 'https://codeload.github.com/google/roboto/zip/v2.134'

if test -d $DIR
  echo "$DIR already installed"
  exit 0
end

unzip -j (curl -s $URL | psub) '*.ttf' -d $DIR