function people.get -d "Google+ people.get API call"
  if test ( count $argv ) -eq 0
    echo "usage: $_ userId [access_token]"
    return
  end
  # example 112077979967606528699
  set userId "$argv[1]"
  if test ( count $argv ) -gt 1
    set qs "?access_token=$argv[2]"
  end
  curl -s "https://www.googleapis.com/plus/v1/people/$userId$qs"
end
