# Wrapper for agy that verifies skill health before launching.
function agy --description 'Run agy after verifying skill health'
    _agent_preflight agy; or return
    command agy $argv
end
