# https://toolbox.finland.fi/brand-identity-and-guidelines/finlandica-font/
# http://web.archive.org/web/20190323232539/https://toolbox.finland.fi/brand-identity-and-guidelines/finlandica-font/

function font-finlandica

  set DIR (fontdir)/finlandica
  set URL 'https://toolbox.finland.fi/wp-content/uploads/sites/2/2015/09/finlandica-2018.zip'

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  unzip -j (curl -s $URL | psub) '*/TTF/*.ttf' -x '__MACOSX/*' -d $DIR # web versions also available!

end
