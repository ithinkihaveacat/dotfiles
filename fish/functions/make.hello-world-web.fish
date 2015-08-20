function make.hello-world-web
  if test ( count $argv ) -ne 1
    echo "usage: $_ directory"
    return
  end
  svn export https://github.com/ithinkihaveacat/hello-world-web/branches/master $argv[1]
end
