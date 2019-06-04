# https://public-sans.digital.gov/

function font-public-sans

  set DIR (fontdir)/public-sans
  set URL (github-download-url uswds/public-sans)

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  unzip -j (curl -sL $URL | psub) 'fonts/otf/*.otf' -d $DIR

end
