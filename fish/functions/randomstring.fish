function randomstring -d "Generate random string"
  dd if=/dev/urandom bs=1 count=128 ^/dev/null | gmd5sum -b | awk '{ print $1 }'
end
