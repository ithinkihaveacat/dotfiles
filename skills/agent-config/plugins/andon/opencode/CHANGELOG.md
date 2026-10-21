# Changelog

## Unreleased

- Add an OpenCode V2 adapter with a direct pull tool, per-request rule with the
  full 1–5 trigger rubric, session-fixed trigger level, passive reminders,
  terminal board and status footer.
- Share the CLI, store format and saved default-level config with the Claude
  adapter. Alerts from both harnesses participate in the same recurrence groups
  and triage operations.

## Compatibility notes for a later Claude session

- This adapter does not import Claude's hook modules. Its rule, schema and
  sensor vocabulary are currently maintained locally, so Claude can be changed
  independently. A later extraction into shared modules should preserve tool
  naming and each harness's attribution semantics rather than importing from one
  adapter into the other.
- The OpenCode rule explicitly limits live `--help` precedence to CLI syntax; it
  cannot override safety policy. Its failure guidance avoids automatic retries
  when the write outcome is uncertain.
- `harness` is `opencode`. A child session's ID is its `agent_id`. OpenCode does
  not record a transcript path or synthetic turn index. The CLI's
  Claude-specific follow-up command remains unchanged; OpenCode reports have no
  generated session-resume command yet.
- Each session locks in the shared saved default level (subject to
  `ANDON_LEVEL`) on its first request; `/andon level` updates the shared
  default.

## Future MCP boundary

MCP is intentionally deferred. Keep alert validation, fingerprints, locking and
storage canonical in the CLI/core. A future MCP adapter can expose those
operations without owning the always-on rule, approval policy, passive sensor or
native UI. Preserve the distinction between model-reported alert content and
harness-stamped context. Retry idempotency and attribution are explicit design
work for that change, not assumptions introduced by this plugin.
