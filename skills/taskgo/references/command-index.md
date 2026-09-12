# Command Index

<!-- markdownlint-disable MD013 -->

## Contents

- [Help](#help)
- [create](#create)
- [update](#update)
- [list](#list)
- [status](#status)
- [dispatch](#dispatch)
- [sync](#sync)
- [doctor](#doctor)
- [fix](#fix)
- [history](#history)
- [checkpoint](#checkpoint)
- [commit](#commit)
- [harbor](#harbor)
  - [harbor prepare](#harbor-prepare)
  - [harbor run](#harbor-run)
  - [harbor verify](#harbor-verify)

## Help

The block below is `taskgo --help`, kept in sync by `command-index-format`.

<!-- generated: ../scripts/taskgo --help -->

```text
Usage: taskgo COMMAND [OPTIONS]

Maintain a private Git-backed personal project/task control repo.

Commands:
  id                               Allocate a unique task ID
  root                             Print the active control repository root
  create PROJECT TITLE [OPTIONS]   Create a new task (--slug, --problem, etc.)
  update TASK_ID [OPTIONS]         Update task fields, status, or headings
  list [PROJECT] [OPTIONS]         List tasks (--state ready for the frontier)
  status [PROJECT] [--json]        Show project status
  dispatch TASK_ID                 Print agent instructions for a selected task
  sync [PROJECT]                   Update STATUS.md snapshot
  doctor [PROJECT]                 Run mechanical checks (read-only)
  fix [PROJECT] [OPTIONS]          Auto-heal IDs, statuses, and snapshots
  history PATH_OR_TASK_ID [FIELD]  Show frontmatter history
  checkpoint TASK_ID SUBJECT [...] Commit an authorized tracker checkpoint (--all)
  commit SUBJECT [OPTIONS]         Commit a logical transition
  harbor COMMAND [OPTIONS]         Prepare, execute, and verify unattended trials

Options:
  -R, --root DIR  Operate on the control repository at DIR instead of the
                  default (~/.projects); overrides TASKGO_ROOT. Must appear
                  before COMMAND.
  --help, -h      Display this help message and exit

Environment:
  Root: ~/.projects
  Source: default

Examples:
  taskgo id
  taskgo create my-project "Diagnose intermittent disconnects" --slug disconnects
  taskgo create my-project "Add cache layer" --slug cache-layer --problem "High latency"
  taskgo update TASK-3A91F --status in-progress --sketch "Use in-memory dict"
  taskgo dispatch TASK-3A91F
  taskgo sync my-project
  taskgo fix my-project
  taskgo checkpoint TASK-3A91F "project: start diagnosis" --all
```

<!-- /generated -->

## create

<!-- generated: ../scripts/taskgo create --help -->

```text
usage: taskgo create [-h] [--slug SLUG] [--status STATUS] [--problem PROBLEM]
                     [--goal GOAL] [--criteria CRITERIA] [--sketch SKETCH]
                     [--constraints CONSTRAINTS] [--outcome OUTCOME]
                     [--findings FINDINGS] [--next NEXT_STEPS] [--conv CONV]
                     [--no-commit] [--dry-run]
                     PROJECT TITLE

Create a new task in PROJECT.

positional arguments:
  PROJECT               Project identifier
  TITLE                 Task title

options:
  -h, --help            show this help message and exit
  --slug SLUG           Filename mnemonic, max 32 chars (default: derived from
                        TITLE)
  --status, -s STATUS   Initial task state (default: todo)
  --problem, -p PROBLEM
                        Problem description
  --goal, -g GOAL       Goal description
  --criteria, -c CRITERIA
                        Observable end condition
  --sketch SKETCH       Implementation sketch
  --constraints CONSTRAINTS
                        Constraints
  --outcome OUTCOME     Outcome description
  --findings FINDINGS   Findings
  --next NEXT_STEPS     Next steps
  --conv, -C, --conversation CONV
                        Active conversation or session ID
  --no-commit           Do not commit created task
  --dry-run             Preview allocation without modifying files

Examples:
  taskgo create my-project "Diagnose intermittent disconnects" --slug disconnects
  taskgo create my-project "Add a read-through cache layer in front of the resolver" \
    --slug cache-layer --problem "High latency" --goal "Sub-10ms"
  taskgo create --status in-progress my-project "Initial implementation" --slug initial-impl

TITLE is prose for humans (it becomes the H1 and appears in STATUS.md); SLUG is
the filename mnemonic. A slug derived from a long TITLE keeps the leading words,
which are rarely the distinguishing ones, so pass --slug whenever TITLE is longer
than a few words.
```

<!-- /generated -->

## update

<!-- generated: ../scripts/taskgo update --help -->

```text
usage: taskgo update [-h] [--status STATUS] [--title TITLE] [--slug SLUG]
                     [--problem PROBLEM] [--goal GOAL] [--criteria CRITERIA]
                     [--sketch SKETCH] [--constraints CONSTRAINTS]
                     [--outcome OUTCOME] [--findings FINDINGS]
                     [--next NEXT_STEPS] [--conv CONV]
                     TASK_ID

Update task fields, status, or headings.

positional arguments:
  TASK_ID               Task ID or relative path

options:
  -h, --help            show this help message and exit
  --status, -s STATUS   New task state
  --title, -t TITLE     New task title
  --slug SLUG           Rename the task file's slug, max 32 chars
  --problem, -p PROBLEM
                        Problem description
  --goal, -g GOAL       Goal description
  --criteria, -c CRITERIA
                        Observable end condition
  --sketch SKETCH       Implementation sketch
  --constraints CONSTRAINTS
                        Constraints
  --outcome OUTCOME     Outcome description
  --findings FINDINGS   Findings
  --next NEXT_STEPS     Next steps
  --conv, -C, --conversation CONV
                        Active conversation or session ID

Examples:
  taskgo update TASK-3A91F --status in-progress
  taskgo update TASK-3A91F --sketch "Use in-memory dict" --findings "Latency reduced by 40%"
```

<!-- /generated -->

## list

<!-- generated: ../scripts/taskgo list --help -->

```text
usage: taskgo list [-h] [--state STATE] [--json] [PROJECT]

List tasks in the repository or a specific project.

positional arguments:
  PROJECT               Optional project name filter

options:
  -h, --help            show this help message and exit
  --state, --status, -s STATE
                        Filter tasks by state (e.g. in-progress, done, or
                        ready)
  --json, -j            Output machine-readable JSON
```

<!-- /generated -->

## status

<!-- generated: ../scripts/taskgo status --help -->

```text
usage: taskgo status [-h] [--json] [PROJECT]

Show project status or whole-workspace summary.

positional arguments:
  PROJECT     Optional target project

options:
  -h, --help  show this help message and exit
  --json, -j  Output machine-readable JSON
```

<!-- /generated -->

## dispatch

<!-- generated: ../scripts/taskgo dispatch --help -->

```text
Usage: taskgo dispatch [--help] TASK_ID

Print instructions dispatching an agent to a selected task.

Arguments:
  TASK_ID     Task to assign to the agent

Options:
  --help, -h  Display this help message and exit

Examples:
  taskgo dispatch TASK-3A91F
  taskgo --root ~/projects dispatch TASK-3A91F

The note is generated from the task record committed at HEAD. Findings about
working-tree or tracker readiness are written to stderr.
```

<!-- /generated -->

## sync

<!-- generated: ../scripts/taskgo sync --help -->

```text
usage: taskgo sync [-h] [PROJECT]

Update STATUS.md snapshot for a project or the workspace.

positional arguments:
  PROJECT     Optional target project

options:
  -h, --help  show this help message and exit
```

<!-- /generated -->

## doctor

<!-- generated: ../scripts/taskgo doctor --help -->

```text
usage: taskgo doctor [-h] [PROJECT]

Run mechanical health checks across the workspace or a project.

positional arguments:
  PROJECT     Optional target project

options:
  -h, --help  show this help message and exit
```

<!-- /generated -->

## fix

<!-- generated: ../scripts/taskgo fix --help -->

```text
usage: taskgo fix [-h] [--dry-run] [--no-commit] [PROJECT]

Auto-heal IDs, statuses, and snapshot drift.

positional arguments:
  PROJECT      Optional target project

options:
  -h, --help   show this help message and exit
  --dry-run    Preview repairs without modifying files
  --no-commit  Apply repairs on disk without committing
```

<!-- /generated -->

## history

<!-- generated: ../scripts/taskgo history --help -->

```text
usage: taskgo history [-h] PATH_OR_TASK_ID [FIELD]

Show frontmatter field history across git revisions.

positional arguments:
  PATH_OR_TASK_ID  Task ID or relative path
  FIELD            Frontmatter field to track (default: status)

options:
  -h, --help       show this help message and exit
```

<!-- /generated -->

## checkpoint

<!-- generated: ../scripts/taskgo checkpoint --help -->

```text
usage: taskgo checkpoint [-h] [--all] [--path PATHS] [--body BODY]
                         [--ref REFS] [--conv CONV]
                         TASK_ID SUBJECT

Commit an authorized tracker checkpoint for TASK_ID. Nonconforming subjects are rewritten as 'chore(<project>): <subject>' (truncated to 50 characters).

positional arguments:
  TASK_ID               Target task ID
  SUBJECT               Conventional Commits subject line (rewritten when
                        nonconforming)

options:
  -h, --help            show this help message and exit
  --all, -a             Stage all modified/untracked project files
  --path, -p PATHS      Explicit project files to stage
  --body, -b BODY       Plain-text commit body (hard-wrapped to 72 columns)
  --ref, -r REFS        External references (e.g. artifact@sha)
  --conv, -C, --conversation CONV
                        Active conversation or session ID

Examples:
  taskgo checkpoint TASK-3A91F "chore(proj): start diagnosis" --all
  taskgo checkpoint TASK-3A91F "docs(proj): update task" --path proj/tasks/TASK-3A91F-slug.md
```

<!-- /generated -->

## commit

<!-- generated: ../scripts/taskgo commit --help -->

```text
usage: taskgo commit [-h] [--body BODY] [--ref REFS] [--conv CONV] SUBJECT

Commit a logical transition with automatic project status synchronization.

positional arguments:
  SUBJECT               Conventional Commits subject line (rewritten when
                        nonconforming)

options:
  -h, --help            show this help message and exit
  --body, -b BODY       Plain-text commit body (hard-wrapped to 72 columns)
  --ref, -r REFS        External references (e.g. artifact@sha)
  --conv, -C, --conversation CONV
                        Active conversation or session ID
```

<!-- /generated -->

## harbor

<!-- generated: ../scripts/taskgo harbor --help -->

```text
usage: taskgo harbor [-h] COMMAND ...

Prepare, execute, and verify unattended trials with Harbor.

positional arguments:
  COMMAND
    prepare   Package an unattended trial directory for Harbor execution
    run       Execute a prepared trial with Harbor
    verify    Evaluate candidate artifacts and build Candidate Acceptance
              Packet

options:
  -h, --help  show this help message and exit

Commands:
  prepare [TASK_ID] [OPTIONS]   Package an unattended trial directory
  run [TARGET] [OPTIONS]        Execute a prepared trial with Harbor
  verify [OPTIONS]              Evaluate candidate artifacts and build acceptance packet

Examples:
  taskgo harbor prepare TASK-12345 -o ./trial
  taskgo harbor run ./trial --print-config
  taskgo harbor verify --base-file orig.json --candidate-file cand.json -o ./packet
```

<!-- /generated -->

### harbor prepare

<!-- generated: ../scripts/taskgo harbor prepare --help -->

```text
usage: taskgo harbor prepare [-h] -o OUTPUT_DIR [--task-id TASK_ID]
                             [--task-title TASK_TITLE]
                             [--instruction INSTRUCTION]
                             [--instruction-file INSTRUCTION_FILE]
                             [--workspace WORKSPACE] [--dockerfile DOCKERFILE]
                             [--artifacts ARTIFACTS] [--skills SKILLS]
                             [--model MODEL] [--agent AGENT]
                             [--agent-version AGENT_VERSION]
                             [--timeout TIMEOUT]
                             [--setup-timeout SETUP_TIMEOUT]
                             [--allowed-hosts ALLOWED_HOSTS] [--dry-run]
                             [task]

Package an unattended trial directory for Harbor execution.

positional arguments:
  task                  Task ID or slug from control repository

options:
  -h, --help            show this help message and exit
  -o, --output OUTPUT_DIR
                        Directory to create trial package in
  --task-id TASK_ID     Explicit task identifier
  --task-title TASK_TITLE
                        Explicit task title
  --instruction INSTRUCTION
                        Instruction text for agent
  --instruction-file INSTRUCTION_FILE
                        Read instruction from file
  --workspace WORKSPACE
                        Host workspace directory with initial files
  --dockerfile DOCKERFILE
                        Custom Dockerfile to use
  --artifacts ARTIFACTS
                        Declared container artifacts to collect
  --skills SKILLS       Skills to bundle and inject (e.g. coding-standards)
  --model MODEL         Model name (default: google/gemini-3.6-flash-low)
  --agent AGENT         Agent name (default: antigravity-cli)
  --agent-version AGENT_VERSION
                        Agent version (default: 1.1.25)
  --timeout TIMEOUT     Agent timeout in seconds (default: 60.0)
  --setup-timeout SETUP_TIMEOUT
                        Setup/build timeout in seconds (default: 180.0)
  --allowed-hosts ALLOWED_HOSTS
                        Allowed network egress hosts during agent phase
  --dry-run             Preview generated trial files without writing to disk
```

<!-- /generated -->

### harbor run

<!-- generated: ../scripts/taskgo harbor run --help -->

```text
usage: taskgo harbor run [-h] [--harbor-bin HARBOR_BIN] [--print-config]
                         [--dry-run] [-o OUTPUT_DIR]
                         [target]

Execute a prepared trial with Harbor.

positional arguments:
  target                Trial package directory or job.json (default: .)

options:
  -h, --help            show this help message and exit
  --harbor-bin HARBOR_BIN
                        Path to harbor executable
  --print-config        Print resolved Harbor configuration and exit without
                        running
  --dry-run             Verify preflights and configuration without executing
                        containers
  -o, --output-dir OUTPUT_DIR
                        Collect results and artifacts into directory upon
                        completion
```

<!-- /generated -->

### harbor verify

<!-- generated: ../scripts/taskgo harbor verify --help -->

```text
usage: taskgo harbor verify [-h] --base-file BASE_FILE
                            --candidate-file CANDIDATE_FILE -o OUTPUT_DIR
                            [--patch-file PATCH_FILE] [--task-id TASK_ID]
                            [--task-title TASK_TITLE]
                            [--completion-json COMPLETION_JSON]
                            [--result-json RESULT_JSON] [--tool-cmd TOOL_CMD]
                            [--json]

Evaluate candidate artifacts and build Candidate Acceptance Packet.

options:
  -h, --help            show this help message and exit
  --base-file BASE_FILE
                        Path to original base file before changes
  --candidate-file CANDIDATE_FILE
                        Path to candidate output file produced by worker
  -o, --output, --output-dir OUTPUT_DIR
                        Directory to write acceptance packet files
  --patch-file PATCH_FILE
                        Unified diff patch file (auto-generated if omitted)
  --task-id TASK_ID     Task identifier
  --task-title TASK_TITLE
                        Task title
  --completion-json COMPLETION_JSON
                        Path to worker completion.json
  --result-json RESULT_JSON
                        Path to Harbor trial result.json
  --tool-cmd TOOL_CMD   Host command to rerun deterministic transformation
  --json                Emit acceptance packet JSON to stdout
```

<!-- /generated -->
