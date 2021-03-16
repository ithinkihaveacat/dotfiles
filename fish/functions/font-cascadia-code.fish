# https://github.com/microsoft/cascadia-code/releases

function font-cascadia-code

  set DIR (fontdir)/cascadia-code
  set URL (github-download-url microsoft/cascadia-code)

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  # Variable TTF version is recommended
  # https://github.com/microsoft/cascadia-code/wiki/Installing-Cascadia-Code
  unzip -j (curl -sL $URL | psub) 'ttf/C*.ttf' -d $DIR

end
