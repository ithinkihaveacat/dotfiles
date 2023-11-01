# https://github.com/adobe-fonts/source-serif-pro/releases

function font-source-serif-pro

  set DIR (fontdir)/source-serif-pro
  set URL (github-download-url adobe-fonts/source-serif-pro | grep Desktop)

  rm -rf $DIR
  mkdir -p $DIR
  unzip -j (curl -sL $URL | psub) '**/OTF/*.otf' -d $DIR

end
