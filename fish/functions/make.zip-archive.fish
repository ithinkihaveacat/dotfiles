function make.zip-archive -d "Creates zip file from current git repo's HEAD"
  if test ( count $argv ) -ne 1
    echo "usage: $_ zipfile"
    return
  end
  git archive --format=zip --prefix= -o $argv[1] HEAD
end
