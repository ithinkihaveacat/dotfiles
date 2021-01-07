# https://black-foundry.com/blog/inria-serif-and-inria/

function font-inria

  set DIR (fontdir)/inria
  set URL (github-zipball-url BlackFoundryCom/InriaFonts)
  
  rm -rf $DIR
  mkdir -p $DIR
  unzip -j (curl -sL $URL | psub) '**/*.otf' -d $DIR

end
