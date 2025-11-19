# https://github.com/adobe-fonts/emojione-color

function font-emojione

    set DIR (fontdir)/emojione
    set URL 'https://api.github.com/repos/adobe-fonts/emojione-color/zipball'

    if test -d $DIR
        echo "error: $DIR already exists"
        return 1
    end

    mkdir -p $DIR
    unzip -j (curl -sL --output - $URL | psub) '*.otf' -d $DIR

end
