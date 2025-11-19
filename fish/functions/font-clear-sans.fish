# https://01.org/clear-sans

function font-clear-sans

    set DIR (fontdir)/clear-sans
    set URL 'https://01.org/sites/default/files/downloads/clear-sans/clearsans-1.00.zip'

    if test -d $DIR
        echo "error: $DIR already exists"
        return 1
    end

    mkdir -p $DIR
    unzip -j (curl -sL $URL | psub) '*.ttf' -d $DIR

end
