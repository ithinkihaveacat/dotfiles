function adb-settings-diff

    set -l SETTINGS adb exec-out dumpsys settings

    vimdiff ($SETTINGS | psub) (read -p "echo 'Make change and press enter (:qa to exit vimdiff!) > '" ; and $SETTINGS | psub)

end
