function make.lately-post -d "Generate lately post template"
  if test ( count $argv ) -ne 1
    echo "usage: $_ slug"
    return
  end
  set -l PREFIX $HOME/workspace/beebo-site/app/lately
  set -l yyyymmdd (date -u +'%Y-%m-%d')
  set -l filename (printf "%s/%s_%s.markdown" $PREFIX $yyyymmdd $argv[1])
  if test -e $filename
    echo "error: $filename already exists"
    return
  end
  echo "---" >> $filename
  echo "title: " >> $filename
  echo "---" >> $filename
  echo >> $filename
  eval $VISUAL $filename
end
