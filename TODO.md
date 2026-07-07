# TODO

## Surface plugin load failures in doctor (2026-06-11)

**Goal:** Make `skill doctor` (and other plugin-loading tools' doctor commands)
report plugins that failed to load, rather than silently omitting them from a
"healthy" catalog. A plugin that fails to load currently produces only a
one-line stderr warning that scrolls past; `doctor` then reports a healthy
catalog that is silently missing that plugin's skills.

**Criteria:** The loader records load failures and `doctor` lists them (e.g.,
"plugin 20_corp.py failed to load"), fitting the doctor-as-drift-detection
pattern.
