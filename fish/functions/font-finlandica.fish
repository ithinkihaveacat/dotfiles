# http://toolbox.finland.fi/identity-of-finland/graphic-elements/other-graphic-elements/finlandica-font/
# https://github.com/ithinkihaveacat/misc/tree/master/fonts

function font-finlandica

  set DIR (fontdir)/finlandica
  set URL 'https://toolbox.finland.fi/wp-content/uploads/sites/16/Finlandica.zip'

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  # -4 Because toolbox.finland.fi's IPv6 SSL is broken...
  unzip -j (curl -4 -s $URL | psub) '*.otf' -d $DIR # ttf, woff, woff2 also available

end
