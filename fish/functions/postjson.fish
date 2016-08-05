function postjson -d "POSTs JSON from stdin to URL"
  # echo '{"bar": 2}' | postjson http://localhost:8080/api/whoami
  curl -s --max-redirs 0 -X POST --data @- -H 'content-type: application/json' $argv
end
