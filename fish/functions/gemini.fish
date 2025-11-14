# Wrapper for gemini that automatically includes TMPDIR in context
function gemini --description 'Run gemini with TMPDIR automatically included in context'
    command gemini --include-directories $TMPDIR $argv
end
