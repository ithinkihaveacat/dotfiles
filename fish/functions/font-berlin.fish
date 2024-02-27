# https://wir.berlin/en/be-a-part/the-new-berlin-font
# https://www.hvdfonts.com/custom-cases/berlin-type

function font-berlin

  set DIR (fontdir)/berlin
  set URL 'https://wir.berlin/fileadmin/downloads/Wir.Berlin_Schrift.zip'
  
  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  unzip -j (curl -sL --output - $URL | psub) '*/BerlinType*.otf' -d $DIR

end
