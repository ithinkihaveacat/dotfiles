function font-jetbrains-mono

    set DIR (fontdir)/jetbrains-mono
    set URL (github-download-url JetBrains/JetBrainsMono)

    if test -d $DIR
        echo "error: $DIR already exists"
        return 1
    else
        mkdir -p $DIR
    end

    unzip -j (curl -sL $URL | psub) 'fonts/variable/*.ttf' -d $DIR

end
