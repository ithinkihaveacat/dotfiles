# https://github.com/vercel/geist-font/tree/main/fonts/GeistPixel/otf

function font-geist-pixel

    set DIR (fontdir)/geist-pixel
    set URL 'https://api.github.com/repos/vercel/geist-font/zipball/main'

    if test -d $DIR
        echo "error: $DIR already exists"
        return 1
    end

    mkdir -p $DIR
    unzip -j (curl -sL $URL | psub) '*/fonts/GeistPixel/otf/*.otf' -d $DIR

end
