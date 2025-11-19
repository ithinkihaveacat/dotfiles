# https://rsms.me/inter/

function font-inter

    set DIR (fontdir)/inter
    set URL (curl --fail -sSL https://api.github.com/repos/rsms/inter/releases | jq -r '.[].assets | .[].browser_download_url' | grep -v beta | head -1)

    rm -rf $DIR
    mkdir -p $DIR
    unzip -j (curl -sL $URL | psub) 'Inter Desktop/*.otf' -d $DIR

end
