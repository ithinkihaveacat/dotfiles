# https://github.com/microsoft/cascadia-code/releases

function font-cascadia-code

  set DIR (fontdir)/cascadia-code
  set URL (github-download-url microsoft/cascadia-code)

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  unzip -j (curl -sL $URL | psub) 'otf/static/*.otf' -d $DIR

end
