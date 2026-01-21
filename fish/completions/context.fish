# Fish completion script for context

# Helper function: check if we need a topic
function __fish_context_needs_topic
    set -l cmd (commandline -opc)
    if test (count $cmd) -eq 1
        return 0
    end
    return 1
end

# Helper function: get list of available topics
function __fish_context_list_topics
    context --list 2>/dev/null
end

# Complete topics (when no topic given)
complete -c context -f -n __fish_context_needs_topic -a '(__fish_context_list_topics)' -d Topic

# Complete individual topics with descriptions
complete -c context -f -n __fish_context_needs_topic -a gemini-api -d 'Gemini API documentation and examples'
complete -c context -f -n __fish_context_needs_topic -a mcp-server -d 'MCP server documentation and specification'
complete -c context -f -n __fish_context_needs_topic -a gemini-cli -d 'Gemini CLI documentation (all)'
complete -c context -f -n __fish_context_needs_topic -a gemini-cli-extensions -d 'Gemini CLI extensions documentation'
complete -c context -f -n __fish_context_needs_topic -a gemini-cli-hooks -d 'Gemini CLI hooks documentation'
complete -c context -f -n __fish_context_needs_topic -a gemini-cli-changelog -d 'Gemini CLI changelog (index, latest, preview, releases)'
complete -c context -f -n __fish_context_needs_topic -a inkyframe -d 'Pimoroni Inky Frame documentation'
complete -c context -f -n __fish_context_needs_topic -a rpi -d 'Raspberry Pi documentation'
complete -c context -f -n __fish_context_needs_topic -a skills -d 'Agent skills documentation (Claude, Gemini CLI, OpenAI Codex)'

# Complete flags
complete -c context -f -s h -l help -d 'Display help message and exit'
complete -c context -f -l list -d 'List available topics (names only)'
