import assert from "node:assert/strict";
import { test } from "node:test";
import { buildRule, INPUT_SCHEMA, TOOL } from "../src/rule.ts";
import {
  buildRule as CLAUDE_BUILD_RULE,
  INPUT_SCHEMA as CLAUDE_INPUT_SCHEMA,
  TOOL as CLAUDE_TOOL
} from "../../claude/hooks/rule.ts";
import { createSensor, shellFailed } from "../src/sensor.ts";

test("pull payload stays compatible with the Claude adapter and omits level", () => {
  assert.deepEqual(INPUT_SCHEMA.required, CLAUDE_INPUT_SCHEMA.required);
  assert.deepEqual(
    Object.keys(INPUT_SCHEMA.properties),
    Object.keys(CLAUDE_INPUT_SCHEMA.properties)
  );
  assert.equal("level" in INPUT_SCHEMA.properties, false);
  assert.deepEqual(
    INPUT_SCHEMA.properties.kind.enum,
    CLAUDE_INPUT_SCHEMA.properties.kind.enum
  );
  assert.deepEqual(
    INPUT_SCHEMA.properties.color.enum,
    CLAUDE_INPUT_SCHEMA.properties.color.enum
  );
  assert.equal(
    INPUT_SCHEMA.properties.summary.maxLength,
    CLAUDE_INPUT_SCHEMA.properties.summary.maxLength
  );
  for (const key of [
    "color",
    "summary",
    "details",
    "sources",
    "resolution",
    "proposed_fix"
  ] as const) {
    assert.equal(
      INPUT_SCHEMA.properties[key].description,
      CLAUDE_INPUT_SCHEMA.properties[key].description
    );
  }
});

test("OpenCode and Claude render the same rule apart from the tool name", () => {
  for (const level of [1, 2, 3, 4, 5] as const) {
    assert.equal(
      buildRule(level),
      CLAUDE_BUILD_RULE(level).replaceAll(CLAUDE_TOOL, TOOL)
    );
  }
});

test("buildRule includes the full 1-5 rubric and keeps static text across levels", () => {
  const rule3 = buildRule(3);
  assert.match(rule3, /Active trigger level: 3 \(standard\)\./);
  assert.match(rule3, /## Not a Harness Defect \(Do Not Pull\)/);
  assert.match(rule3, /At Levels 1–4, a transient failure/);
  assert.match(rule3, /- \*\*Level 1 \(red only\):\*\*/);
  assert.match(rule3, /- \*\*Level 2 \(conservative\):\*\*/);
  assert.match(rule3, /- \*\*Level 3 \(standard\):\*\*/);
  assert.match(rule3, /- \*\*Level 4 \(proactive audit\):\*\*/);
  assert.match(rule3, /- \*\*Level 5 \(maximum coverage\):\*\*/);
  const rule5 = buildRule(5);
  assert.match(rule5, /At Levels 1–4, a transient failure/);
  assert.doesNotMatch(
    rule5,
    /Active trigger level: 5 \(maximum coverage\)\. Do not self-filter/
  );
  assert.equal(
    rule3.replace(
      "Active trigger level: 3 (standard).",
      "Active trigger level: 5 (maximum coverage)."
    ),
    rule5
  );
});

test("shell exits use metadata or a trailing status, not guessed error words", () => {
  assert.equal(shellFailed({ metadata: { exitCode: 1 } }), true);
  assert.equal(shellFailed({ metadata: { exit: 1 } }), true);
  assert.equal(shellFailed({ metadata: { exit: 0 } }), false);
  assert.equal(
    shellFailed({ metadata: { exit_code: 0 }, content: "Exited with code 1" }),
    false
  );
  assert.equal(
    shellFailed({ content: "actual output\nExited with code 2\n" }),
    true
  );
  assert.equal(
    shellFailed({ content: "\x1b[31mExited with code 2\x1b[0m" }),
    true
  );
  assert.equal(
    shellFailed({
      content: "coloured output\n\x1b[31mExited with code 1\x1b[0m"
    }),
    true
  );
  assert.equal(
    shellFailed({ content: [{ type: "text", text: "Exited with code 3" }] }),
    true
  );
  assert.equal(shellFailed({ content: "ordinary error explanation" }), false);
  assert.equal(
    shellFailed({
      content: "Exited with code 1\nquoted documentation follows"
    }),
    false
  );
});

test("skill tool loads and direct SKILL.md reads both inform the sensor", () => {
  for (const observation of [
    { tool: "skill", input: { id: "deploy" } },
    { tool: "read", input: { path: "/skills/deploy/SKILL.md" } }
  ]) {
    const sensor = createSensor();
    sensor.observe({ ...observation, failed: false, level: 3 });
    assert.match(
      sensor.observe({
        tool: "shell",
        input: { command: "skills/deploy/scripts/run --old" },
        failed: true,
        level: 3
      })!,
      /read the skill/
    );
  }
});

test("level 1 stays quiet and a pull clears the help-after-failure pattern", () => {
  const sensor = createSensor();
  const failure = {
    tool: "shell",
    input: { command: "deploy" },
    failed: true,
    level: 1
  };
  sensor.observe(failure);
  assert.equal(sensor.observe(failure), null);
  sensor.observe({ ...failure, level: 3 });
  sensor.observe({ tool: "andon_pull", input: {}, failed: false, level: 3 });
  assert.equal(
    sensor.observe({
      tool: "shell",
      input: { command: "deploy --help" },
      failed: false,
      level: 3
    }),
    null
  );
});

test("sensor nudges each pattern once and caps reminders at five", () => {
  const sensor = createSensor();
  for (let n = 0; n < 8; n++) {
    const failure = {
      tool: "shell",
      input: { command: `tool-${n}` },
      failed: true,
      level: 3
    };
    assert.equal(sensor.observe(failure), null);
    assert.equal(sensor.observe(failure) !== null, n < 5);
    assert.equal(sensor.observe(failure), null);
  }
});
