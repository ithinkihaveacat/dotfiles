# https://b612-font.com/

function font-b612

    set DIR (fontdir)/b612
    set URL 'https://api.github.com/repos/polarsys/b612/zipball'

    rm -rf $DIR
    mkdir -p $DIR
    unzip -j (curl -sL $URL | psub) '**/fonts/ttf/*.ttf' -d $DIR

end
