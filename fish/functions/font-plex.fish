# https://ibm.github.io/type/

function font-plex

  set DIR (fontdir)/plex
  set URL (github-download-url IBM/plex | grep OpenType)

  rm -rf $DIR
  mkdir -p $DIR
  unzip -j (curl -sL $URL | psub) 'OpenType/IBM-Plex-Sans/*.otf' 'OpenType/IBM-Plex-Mono/*.otf' 'OpenType/IBM-Plex-Serif/*.otf' -d $DIR

end
