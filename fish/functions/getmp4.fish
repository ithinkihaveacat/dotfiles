# copy(Array.from(document.querySelectorAll("div.obs-media-gallery-main video source")).map(e => e.src).join("\n"))

function getmp4 -d "Save URLs to MP4 files"
  set -l i 0
  while read -la line
    set i (math $i + 1)
    printf "curl -sSL --output 'photo-%03d.mp4' '%s'" $i $line | sh
  end
  # overwrite dupes
  for file in *.mp4
    mv $file (printf "%s.mp4\n" (md5sum $file | cut -c 1-10))
  end
end
