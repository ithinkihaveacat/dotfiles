# https://toolbox.finland.fi/brand-identity-and-guidelines/finlandica-font/
# http://web.archive.org/web/20190323232539/https://toolbox.finland.fi/brand-identity-and-guidelines/finlandica-font/
# https://github.com/HelsinkiTypeStudio/Finlandica

function font-finlandica

    set DIR (fontdir)/finlandica
    set URL 'https://api.github.com/repos/HelsinkiTypeStudio/Finlandica/zipball'

    if test -d $DIR
        echo "error: $DIR already exists"
        return 1
    end

    mkdir -p $DIR
    unzip -j (curl -sL --output - $URL | psub) '*/fonts/variable/*.ttf' -d $DIR

end
