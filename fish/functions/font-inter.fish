# https://rsms.me/inter/

function font-inter

  set DIR (fontdir)/inter
  set URL (github-download-url rsms/inter)
  
  rm -rf $DIR
  mkdir -p $DIR
  unzip -j (curl -sL $URL | psub) 'Inter/*.otf' -d $DIR

end
