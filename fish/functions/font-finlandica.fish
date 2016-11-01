# http://toolbox.finland.fi/identity-of-finland/graphic-elements/other-graphic-elements/finlandica-font/

function font-finlandica

  set DIR (fontdir)/finlandica
  set URL 'http://toolbox.finland.fi/wp-content/uploads/sites/16/Finlandica.zip'

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  unzip -j (curl -s $URL | psub) '*.otf' -d $DIR # ttf, woff, woff2 also available

end
