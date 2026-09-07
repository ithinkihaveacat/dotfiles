# fish/functions/__fish_android_devices.fish
function __fish_android_devices -d "List connected Android device serials and descriptions"
    if not type -q adb
        return 1
    end

    for line in (adb devices -l 2>/dev/null)
        if string match -qr '^(\*|List of devices attached|\s*$)' -- $line
            continue
        end

        set -l tokens (string split -n ' ' -- $line)
        if test (count $tokens) -lt 2
            continue
        end

        set -l serial $tokens[1]
        set -l state $tokens[2]
        set -l product (string match -r 'product:(\S+)' -- $line)
        set -l model (string match -r 'model:(\S+)' -- $line)
        set -l desc ""

        if test -n "$product[2]"; and test -n "$model[2]"
            set desc "$product[2] $model[2]"
        else if test -n "$model[2]"
            set desc "$model[2]"
        else if test -n "$product[2]"
            set desc "$product[2]"
        else
            set desc "$state"
        end

        printf "%s\t%s\n" $serial $desc
    end
end
