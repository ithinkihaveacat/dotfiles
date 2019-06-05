# https://rsms.me/inter/

function font-inter

  set DIR (fontdir)/inter
  set URL (github-download-url rsms/inter)
  
  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  else
    mkdir -p $DIR
  end

  unzip -j (curl -sL $URL | psub) 'Inter (OTF)/*.otf' -d $DIR

end
