# https://ia.net/topics/a-typographic-christmas

function font-iA

    set DIR (fontdir)/iA
    set URL 'https://api.github.com/repos/iaolo/iA-Fonts/zipball'

    rm -rf $DIR
    mkdir -p $DIR
    unzip -j (curl -sL $URL | psub) '**/Static/*.ttf' -d $DIR

end
