function dig-diff -d "Compares cached and uncached DNS records"

  if test ( count $argv ) -eq 0
    echo "usage: $_ host"
    return
  end

  set -l NS (dig +short $argv[1] ns | head -1 | rev | cut -c 2- | rev)

  set -l ARGS --minimal --new-line-format='+%L' --old-line-format='-%L' --unchanged-line-format='%L'
  set -l DIG1 dig -t ANY +noall +answer $argv[1] @$NS
  set -l DIG2 dig -t ANY +noall +answer $argv[1]
  
  echo "# $DIG1"
  echo "# $DIG2"

  diff $ARGS (eval $DIG1 | sort | psub) (eval $DIG2 | sort | psub)

end
