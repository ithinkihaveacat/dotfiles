# copy(Array.from(document.querySelectorAll("div.obs-media-gallery-main img")).map(e => e.src).join("\n"))

function getjpg -d "Save URLs to JPG files"
  set -l i 0
  while read -la line
    set i (math $i + 1)
    printf "curl -sSL --output 'photo-%03d.jpg' '%s'" $i $line | sh
  end
  # overwrite dupes
  for file in *
    mv $file (printf "%s.jpg\n" (md5sum $file | cut -c 1-10))
  end
end
