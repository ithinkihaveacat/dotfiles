function rotate-gemini-api-key -d "Cycles GEMINI_API_KEY through the GEMINI_API_KEYS array"
    if not set -q GEMINI_API_KEYS
        echo "Error: GEMINI_API_KEYS array is not set." >&2
        return 1
    end

    if test (count $GEMINI_API_KEYS) -eq 0
        echo "Error: GEMINI_API_KEYS array is empty." >&2
        return 1
    end

    set -l next_index 1
    if set -q GEMINI_API_KEY
        set -l idx (contains -i -- "$GEMINI_API_KEY" $GEMINI_API_KEYS)
        if test -n "$idx"
            set next_index (math $idx + 1)
            if test $next_index -gt (count $GEMINI_API_KEYS)
                set next_index 1
            end
        end
    end

    set -xU GEMINI_API_KEY $GEMINI_API_KEYS[$next_index]
    echo "Switched GEMINI_API_KEY to key $next_index of "(count $GEMINI_API_KEYS)
end
