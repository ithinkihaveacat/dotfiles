# http://levien.com/type/myfonts/inconsolata.html

function font-inconsolata

    set DIR (fontdir)/inconsolata
    set URL 'https://raw.githubusercontent.com/google/fonts/master/ofl/inconsolata/Inconsolata-%s.ttf'

    if test -d $DIR
        echo "error: $DIR already exists"
        return 1
    end

    mkdir -p $DIR
    curl -sS (printf $URL Bold) >$DIR/Inconsolata-Bold.ttf
    curl -sS (printf $URL Regular) >$DIR/Inconsolata-Regular.ttf

end
