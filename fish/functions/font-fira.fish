# https://carrois.com/projects/Fira/

function font-fira

  set DIR (fontdir)/fira
  set URL 'https://api.github.com/repos/carrois/Fira/zipball'

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  unzip -j (curl -sL $URL | psub) '*.otf' -d $DIR

end
