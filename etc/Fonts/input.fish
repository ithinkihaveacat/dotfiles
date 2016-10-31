# http://input.fontbureau.com/

set DIR input
set URL 'http://input.fontbureau.com/build/?fontSelection=whole&a=ss&g=ss&i=0&l=0&zero=slash&asterisk=height&braces=straight&preset=default&line-height=1.2&accept=I+do&email='

if test -d $DIR
  echo "error: $DIR already exists"
  exit 1
end

unzip -j (curl -s $URL | psub) '*.ttf' -d $DIR
