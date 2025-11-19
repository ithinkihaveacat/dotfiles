# https://github.com/rektdeckard/departure-mono/releases

function font-departure-mono

    set DIR (fontdir)/departure-mono
    set URL (github-download-url rektdeckard/departure-mono)

    if test -d $DIR
        echo "error: $DIR already exists"
        return 1
    end

    mkdir -p $DIR
    unzip -j (curl -sL $URL | psub) '*.otf' -d $DIR

end
