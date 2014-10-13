# https://developers.google.com/+/api/latest/people/get
function people.get -d "Google+ People: get"
  if test ( count $argv ) -eq 0
    echo "usage: $_ user_id [access_token]"
    return
  end
  # example 112077979967606528699
  set userId "$argv[1]"
  if test ( count $argv ) -gt 1
    set qs "?access_token=$argv[2]"
  end
  set url "https://www.googleapis.com/plus/v1/people/$userId$qs"
  echo "# $url"
  curl -s $url
end
