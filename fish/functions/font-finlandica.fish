# http://toolbox.finland.fi/identity-of-finland/graphic-elements/other-graphic-elements/finlandica-font/

set DIR (fontdir)/finlandica
set URL 'http://toolbox.finland.fi/wp-content/uploads/sites/16/Finlandica.zip'

if test -d $DIR
  echo "$DIR already installed"
  exit 0
end

mkdir -p $DIR
unzip -j (curl -s $URL | psub) '*.otf' -d $DIR # ttf, woff, woff2 also available
