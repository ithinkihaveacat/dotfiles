function fontdir

    if test -x /bin/uname
        set UNAME /bin/uname
    else if test -x /usr/bin/uname
        set UNAME /usr/bin/uname
    end

    switch (eval $UNAME)

        case Darwin
            # $DSTDIR/Library/Fonts is special, and can't be removed, so make sure fonts
            # are copied into here (and not symlinked)
            echo "$HOME/Library/Fonts"

        case Linux
            # See /etc/fonts/fonts.conf for where Ubuntu looks for fonts
            # (/usr/local/share/fonts will also work)
            echo "$HOME/.fonts"

        case '*'
            exit 1

    end

end
