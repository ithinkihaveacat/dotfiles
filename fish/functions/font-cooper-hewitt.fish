# https://www.cooperhewitt.org/open-source-at-cooper-hewitt/cooper-hewitt-the-typeface-by-chester-jenkins/

function font-cooper-hewitt

  set DIR (fontdir)/cooper-hewitt
  set URL 'https://uh8yh30l48rpize52xh0q1o6i-wpengine.netdna-ssl.com/wp-content/uploads/fonts/CooperHewitt-OTF-public.zip'

  if test -d $DIR
    echo "error: $DIR already exists"
    return 1
  end

  mkdir -p $DIR
  unzip -j (curl -sL $URL | psub) '*.otf' -d $DIR

end
