# Change Sets

Read this when you write a change-set file for `taskgo apply`, need the exact
rules behind `taskgo edit`, or call the MCP write tools. Ordinary task work
needs only `create`, `update`, and `edit`.

A change set is the unit of a typed write: a list of operations applied in
order, all or none. `taskgo apply CHANGES.json` applies one to the working tree
without committing, so the MCP server's write semantics can be tried offline.
`taskgo edit` is a change set of one `edit_file`. The file is a JSON object with
one key, `changes`:

```json
{"changes": [
  {"op": "create", "kind": "task", "project": "my-project", "ref": "a",
   "fields": {"blocked_by": ["TASK-3A91F"]},
   "sections": {"title": "Add a cache", "Goal": "Sub-10ms reads."}},
  {"op": "set", "record": "TASK-3A91F", "field": "status", "value": "done",
   "expected": "in-progress"},
  {"op": "replace_section", "record": "TASK-3A91F", "section": "Outcome",
   "text": "Met.", "expected_hash": null}
]}
```

## Operations

| Operation         | Keys                                                                                                 | Precondition                          |
| ----------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------------- |
| `create`          | `kind` (`task`, `decision`, or `project`), `project`, `ref`, `slug`, `fields` (optional), `sections` | none; IDs and numbers are allocated   |
| `set`             | `record`, `field`, `value`, `expected` (optional)                                                    | `expected`, when given                |
| `add`, `remove`   | `record`, `field`, `values`                                                                          | none; repeats and absences are no-ops |
| `replace_section` | `record`, `section`, `text`, `expected_hash`                                                         | the section's hash                    |
| `write_file`      | `path`, `content`, `expected_blob` (optional), `executable` (optional)                               | absent, or the file's Git blob SHA    |
| `delete_file`     | `path`, `expected_blob`                                                                              | the file's Git blob SHA               |
| `edit_file`       | `path`, `old_string`, `new_string`, `replace_all` (optional), `expected_blob` (optional)             | `old_string` occurs; `expected_blob`  |

## Keys

- **Projects:** `create` with `kind` `project` names a new top-level directory
  in `project`. It takes `sections` `{"title": ...}` (the README heading),
  optionally `fields` `{"skills": [...]}`, and no `ref` or `slug`. It writes
  `README.md` and, unless one with content is there, `STATUS.md`. A directory
  without a README that holds `STATUS.md` or `tasks/`, which `doctor` warns
  about, becomes a project this way. An existing project, any other existing
  directory, and an invalid name are refused. Later changes in the set can
  create its tasks.
- **Records:** A task ID, a decision path, a project's `STATUS.md`, or `$name`
  for a record an earlier `create` named with `ref`. `$name` also works in
  `blocked_by` and `supersedes` values, so one set can create a task and the
  task it blocks.
- **Fields:** `set` takes a task's `status`, `due`, `stale_after`, or `title`,
  and a decision's `status`; null clears an optional one. `add` and `remove`
  take the set fields of the [schema](command-index.md#schema). Conversations
  need an explicit `<agent>://<id>`.
- **Sections:** `replace_section` takes a task section other than the title, or
  `STATUS.md` Summary or Next. `expected_hash` is the hash `get_task` or
  `get_project_status` reports, or null when the section is absent. A null
  `text` removes an optional section. A new section goes where the schema orders
  it. Supply the section body only: a leading own `## Heading` or `**Label:**`
  is dropped with a note. Text that duplicates a section or adds or removes any
  other section is refused. The result's `sections` list gives the current hash
  of every section of each modified task and `STATUS.md` (`record`, `section`,
  `hash`; null when absent), ready for the next `replace_section`.
- **Files:** `write_file` writes project assets: any file in an existing project
  outside `tasks/`, `decisions/`, and `STATUS.md`, and `INBOX.md`. It refuses
  `.git*` paths, `..`, symbolic links, more than 256 KiB, non-UTF-8 content, and
  a `README.md` whose frontmatter does not parse. Without `expected_blob` (or
  with null) the file must be new. A file that exists is refused with its blob,
  which `expected_blob` must name to overwrite it, so a write never loses a
  change made since the caller read the file. `content` must be a string.
  `delete_file` deletes a file whose blob is `expected_blob`, under the same
  path rules, except a project's `README.md`. A rewritten file keeps its mode
  and a new one is not executable, unless `executable` is `true` or `false`,
  which sets the mode (100755 or 100644). Markdown is formatted, so the result
  reports each written file's new blob SHA.
- **Edits:** `edit_file` replaces exact text in an existing file, as Caxton's
  `search_and_replace` does: `old_string` must occur exactly once, or
  `replace_all` must be true. It edits the assets `write_file` writes and the
  records too: tasks, decisions, and a project's `STATUS.md` outside its
  generated block. Bytes match verbatim. Only when nothing matches, the file has
  CRLF line endings, and `old_string` has bare `\n` ones, are both strings
  retried with CRLF. Assets are written exactly as replaced and keep their mode.
  A record must stay valid: its frontmatter parses, a task keeps its `id` and a
  known status, no section appears twice that did not before, and entries added
  to `blocked_by` or `supersedes` are checked as `add` checks them. Records are
  formatted once the whole set has applied, so several edits of one record each
  match the text the one before it left. Files and results are limited to 256
  KiB. A miss is a precondition failure, with a unified diff against the closest
  lines; several matches without `replace_all` are invalid.
- **Edit results:** The result's `edits` list gives each edit's
  `occurrences_replaced`, the `start_line` and `end_line` of its first
  replacement (lines end at `\n`), and the file's `total_lines` and `blob` after
  the set. Formatting can rewrap a record's edited lines, so the text there may
  differ from `new_string`: `reformatted` says whether it does, and then `text`
  holds those lines as they now stand, or, past 1 KiB, `text_omitted` is true
  and the caller reads them back. A later edit of the same lines quotes that
  text. With `replace_all`, the returned `text` and line numbers cover the first
  replacement only. `reformatted` is judged after the whole set, so a later edit
  of the same lines in the set also makes it true; `text` is still what to
  quote.

## Validation and Refusals

Each precondition is checked when its change applies, against the state the
changes before it left. Validation then runs on the state after the whole set:

- added blockers and superseded decisions exist;
- no `blocked_by` or `supersedes` cycle passes through a changed record;
- task IDs stay unique;
- a task that becomes done, or whose Outcome changes while done, has a non-empty
  Outcome.

Last, `STATUS.md` is regenerated for each project with a changed task, decision,
or `STATUS.md`, and for each project with a task that a changed task blocks. A
snapshot block shows only direct blockers, so no further project can change.
Other projects' date-driven refreshes stay with `taskgo sync`.

A refusal names the change and its kind: `invalid` (malformed or disallowed),
`precondition` (an expected value, hash, or blob that no longer holds), or
`validation` (the whole set's result breaks a rule). Nothing is written. To read
section hashes offline, use `taskgo status TASK_ID --json`,
`taskgo handoff PROJECT|TASK_ID --json`, or `taskgo mcp --stdio --no-fetch`.
