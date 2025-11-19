function as --description 'Open project in Android Studio'
    set -q argv[1]; or set argv[1] "."
    set -l build build.gradle.kts build.gradle
    for f in $build
        set -l path "$argv[1]/$f"
        if test -f $path
            open -a "Android Studio Preview" $path
            return 0
        end
    end
    echo "error: couldn't find $build in $argv[1]"
end
