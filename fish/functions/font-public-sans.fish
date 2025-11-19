# https://public-sans.digital.gov/

function font-public-sans

    set DIR (fontdir)/public-sans
    set URL (github-download-url uswds/public-sans)

    rm -rf $DIR
    mkdir -p $DIR
    unzip -j (curl -sL $URL | psub) 'fonts/variable/*' -d $DIR

end
