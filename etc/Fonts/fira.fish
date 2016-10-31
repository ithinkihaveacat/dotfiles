# https://carrois.com/projects/Fira/

set DIR fira

if test -d $DIR
  echo "error: $DIR already exists"
  exit 1
end

unzip -j (curl -s https://carrois.com/downloads/Fira/Fira_Sans_4_2.zip | psub) '*.otf' -x '__MACOSX/*' -d $DIR
unzip -j (curl -s https://carrois.com/downloads/Fira/Fira_Code_3_2.zip | psub) '*.otf' -d $DIR
unzip -j (curl -s https://carrois.com/downloads/Fira/Fira_Mono_3_2.zip | psub) '*.otf' -d $DIR
