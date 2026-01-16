function pbclean
    # Ensure clipboard contains text
    if not osascript -e 'clipboard info' | string match -q -r '«class utf8»|string|Unicode text'
        echo "pbclean: No text in clipboard" >&2
        return 1
    end

    # Capture clipboard content into a variable (binary safe-ish)
    set -l content_in (pbpaste | string collect --no-trim-newline)
    set -l size_in (string length --bytes -- "$content_in")

    if test $size_in -eq 0
        echo "pbclean: Clipboard empty" >&2
        return
    end

    # Process content using perl
    # We pipe the variable to perl and collect the result
    set -l content_out (printf '%s' "$content_in" | perl -CSD -pe '
        next if /^\x5Bimage\d+\]: <data:image\//;
        s/"data:[^"]*"/""/g;
        s/\x{00A0}/ /g;
        s/\x5Bcite[^]]*\]//g;
        s/---//g;
    ' | string collect --no-trim-newline)

    set -l size_out (string length --bytes -- "$content_out")

    # Copy the cleaned content back to clipboard
    printf '%s' "$content_out" | pbcopy

    # Calculate and report statistics
    set -l diff (math $size_in - $size_out)

    if test $size_in -gt 0
        set -l percent (math "$diff / $size_in * 100")
        printf "pbclean: Reduced by %d bytes (%.1f%%)\n" $diff $percent >&2
    end
end