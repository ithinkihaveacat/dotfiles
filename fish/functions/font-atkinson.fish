# https://www.brailleinstitute.org/freefont

function font-atkinson

    set DIR (fontdir)/atkinson
    set URL https://braileinstitute.box.com/shared/static/waaf5z9gfss6w6tf5118im5hhlwolacc.zip

    rm -rf $DIR
    mkdir -p $DIR
    unzip -j (curl -sL $URL | psub) '**/*.otf' -d $DIR

end
