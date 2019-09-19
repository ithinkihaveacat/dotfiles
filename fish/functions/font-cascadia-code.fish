function font-cascadia-code

  set DIR (fontdir)/cascadia-code
  set URL (github-zipball-url microsoft/cascadia-code)

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  else
    mkdir -p $DIR
  end

  unzip -j (curl -sL $URL | psub) '*.ttf' -d $DIR

end
