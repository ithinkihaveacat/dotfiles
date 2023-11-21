# https://monaspace.githubnext.com

function font-monaspace

  set DIR (fontdir)/monaspace
  set URL (github-download-url githubnext/monaspace)

  rm -rf $DIR
  mkdir -p $DIR
  unzip -j (curl -sL $URL | psub) 'monaspace*/fonts/variable/*.ttf' -d $DIR

end
