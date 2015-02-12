function make.gam-icons -d "Generate icons in different sizes"
  if test ( count $argv ) -ne 1
    echo "usage: $_ color"
    return
  end
  convert -size 16x16 xc:$argv[1] 16x16.png
  convert -size 32x32 xc:$argv[1] 32x32.png
  convert -size 48x48 xc:$argv[1] 48x48.png
  convert -size 96x96 xc:$argv[1] 96x96.png
  convert -size 128x128 xc:$argv[1] 128x128.png
  convert -size 440x280 xc:$argv[1] 440x280.png
  convert -size 1280x800 xc:$argv[1] 1280x800.png
end
