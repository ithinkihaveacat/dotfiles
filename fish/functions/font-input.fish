# http://input.fontbureau.com/

function font-input

  set DIR (fontdir)/input
  set URL 'http://input.fontbureau.com/build/?fontSelection=whole&a=ss&g=ss&i=0&l=0&zero=slash&asterisk=height&braces=straight&preset=default&line-height=1.2&accept=I+do&email='

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  unzip -j (curl -s $URL | psub) '*.ttf' -d $DIR

end