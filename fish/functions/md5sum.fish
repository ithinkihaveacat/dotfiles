function md5sum --wraps md5sum
  if type -q gmd5sum
    command gmd5sum $argv
  else
    command md5sum $argv
  end
end
