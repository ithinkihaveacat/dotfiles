# https://github.com/golang/image

function font-go

  set DIR (fontdir)/go
  set URL 'https://api.github.com/repos/golang/image/zipball'

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  unzip -j (curl -sL $URL | psub) '*/Go-*.ttf' -d $DIR

end
