# https://github.com/google/roboto/releases

function font-roboto

    set DIR (fontdir)/roboto
    set URL (github-download-url google/roboto | grep unhinted)

    if test -d $DIR
        echo "error: $DIR already exists"
        return 1
    end

    mkdir -p $DIR
    unzip -j (curl -Ls $URL | psub) '*.ttf' -d $DIR

end
