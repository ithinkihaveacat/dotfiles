function postjson -d "POSTs JSON from stdin to URL"
  if test -n "$ACCESS_TOKEN"
    set -l AUTHORIZATION -H "authorization: Bearer $ACCESS_TOKEN"
  end
  curl -s --max-redirs 0 -X POST --data @- $AUTHORIZATION -H 'content-type: application/json' $argv
end
