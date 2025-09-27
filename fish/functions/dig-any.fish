function dig-any -d "DNS lookup (all records)"

  # DNS queries for the "ANY" type behave unpredictably, partly
  # because of caches, and partly because authoritative servers don't
  # like it. Simulate an "ANY" query by asking for all "likely" types.
  # http://serverfault.com/q/754422/14573
  
  set -l QUERY
  # https://en.wikipedia.org/wiki/List_of_DNS_record_types
  for type in HTTPS SVCB TLSA SMIMEA SSHFP DNAME LOC URI A AAAA NS SOA MX TXT NAPTR CNAME DNSKEY RP SRV CAA
    set QUERY $QUERY $argv[1] $type
  end

  set -gx DIG_CMD "dig +noall +nottl +answer $QUERY | sort | uniq"
  echo $DIG_CMD | source

end
