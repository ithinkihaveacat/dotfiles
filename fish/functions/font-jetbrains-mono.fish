function font-jetbrains-mono

  set DIR (fontdir)/jetbrains-mono
  set URL https://download.jetbrains.com/fonts/JetBrainsMono-1.0.0.zip

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  else
    mkdir -p $DIR
  end

  unzip -j (curl -sL $URL | psub) '*.ttf' -d $DIR

end
