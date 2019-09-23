# https://github.com/ThomasJockin/lexend

function font-lexend

  set DIR (fontdir)/lexend
  set URL 'https://api.github.com/repos/ThomasJockin/lexend/zipball'

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  unzip -j (curl -sL $URL | psub) '*/fonts/ttf/*' -d $DIR

end
