# https://github.com/googlefonts/noto-emoji

function font-notocoloremoji

    set DIR (fontdir)/notocoloremoji
    set URL 'https://github.com/googlefonts/noto-emoji/raw/main/fonts/NotoColorEmoji-noflags.ttf'

    if test -d $DIR
        echo "error: $DIR already exists"
        return 1
    end

    mkdir -p $DIR
    curl -sL --output - $URL >$DIR/NotoColorEmoji.ttf

end
