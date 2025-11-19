# https://fonts.googleblog.com/2024/06/playwrite-is-new-font-superfamily-for.html

function font-playwrite

    set DIR (fontdir)/playwrite

    if test -d $DIR
        echo "error: $DIR already exists"
        return 1
    end

    mkdir -p $DIR

    set files PlaywriteGBS-Italic%5Bwght%5D.ttf PlaywriteGBS%5Bwght%5D.ttf PlaywriteGBJ-Italic%5Bwght%5D.ttf PlaywriteGBJ%5Bwght%5D.ttf

    for f in $files
        set url (printf	"https://github.com/google/fonts/raw/main/ofl/playwritegbj/%s" $f)
        curl -sSL -o $DIR/(string unescape --style=url (basename $url)) $url
    end

end
