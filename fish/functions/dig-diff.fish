function dig-diff -d "Compares cached and uncached DNS records"

  # For an another way to compare results from different servers, see
  # https://www.whatsmydns.net/

  if test ( count $argv ) -eq 0
    printf "usage: %s host\n" (status current-command)
    return
  end

  set -l NS (dig +short $argv[1] NS | sort | head -1 | rev | cut -c 2- | rev)

  # DNS queries for the "ANY" type behave unpredictably, partly
  # because of caches, and partly because authoritative servers don't
  # like it. Simulate an "ANY" query by asking for all "likely" types.
  # http://serverfault.com/q/754422/14573
  
  set -l QUERY
  for type in A AAAA NS SOA MX TXT NAPTR CNAME DNSKEY RP SRV CAA
    set QUERY $QUERY $argv[1] $type
  end
  
  set -l ARGS --minimal --new-line-format='+%L' --old-line-format='-%L' --unchanged-line-format='%L'
  set -l DIG1 dig +noall +nottl +answer $QUERY
  set -l DIG2 dig +noall +nottl +answer $QUERY @$NS
  
  echo "# $DIG1"
  echo "# $DIG2"

  diff $ARGS (eval $DIG1 | sort | uniq | psub) (eval $DIG2 | sort | uniq | psub)

end
