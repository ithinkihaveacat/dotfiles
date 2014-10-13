# https://developers.google.com/now/api/v1/reference/users/cards/list
function now.cards.list -d "Google Now Users.cards: list"
  if test ( count $argv ) -eq 0
    echo "usage: $_ access_token"
    return
  end
  # example 112077979967606528699
  set userId "me"
  set accessToken $argv[1]
  set url "https://www.googleapis.com/now/v1/users/$userId/cards?access_token=$accessToken"
  echo "# $url"
  curl -s $url
end
