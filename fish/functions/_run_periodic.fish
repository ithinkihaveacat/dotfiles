# Run a command periodically based on a universal state variable.
# Usage: _run_periodic <state_variable> <interval_seconds> <command...>
function _run_periodic -a state_var interval -d "Run a command periodically based on a universal state variable"
    if test (count $argv) -lt 3
        echo "Usage: _run_periodic <state_variable> <interval_seconds> <command...>" >&2
        return 1
    end

    set -l cmd $argv[3..-1]
    set -l current_time (date +%s)
    set -l last_run 0

    if set -q $state_var
        set last_run $$state_var
    end

    set -l time_elapsed (math "$current_time - $last_run")

    if test $time_elapsed -ge $interval
        $cmd
        set -U $state_var $current_time
    end
end
