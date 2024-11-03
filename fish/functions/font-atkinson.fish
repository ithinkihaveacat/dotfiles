# https://www.brailleinstitute.org/freefont

function font-atkinson

  set DIR (fontdir)/atkinson
  set URL https://www.brailleinstitute.org/atkinson-hyperlegible-font/Atkinson-Hyperlegible-Font-Print-and-Web-2020-0514.zip
  
  rm -rf $DIR
  mkdir -p $DIR
  unzip -j (curl -sL $URL | psub) '**/*.otf' -d $DIR

end
