import assert from "node:assert/strict";
import { test } from "node:test";
import { buildRule, INPUT_SCHEMA, parseLevelRequest } from "../src/rule.ts";
import { INPUT_SCHEMA as CLAUDE_INPUT_SCHEMA } from "../../claude/hooks/rule.ts";
import { createSensor, shellFailed } from "../src/sensor.ts";

test("pull payload stays compatible with the untouched Claude adapter", () => {
  assert.deepEqual(INPUT_SCHEMA.required, CLAUDE_INPUT_SCHEMA.required);
  assert.deepEqual(
    Object.keys(INPUT_SCHEMA.properties),
    Object.keys(CLAUDE_INPUT_SCHEMA.properties)
  );
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
});

test("levels and level requests keep the existing vocabulary", () => {
  assert.equal(parseLevelRequest("Set andon level to 2."), 2);
  assert.equal(parseLevelRequest("andon level reset"), "default");
  assert.equal(parseLevelRequest("What does andon level 5 do?"), null);
  assert.equal(parseLevelRequest("andon level 9"), null);
  assert.match(buildRule(3, false), /Do not pull for/);
  assert.doesNotMatch(buildRule(5, true), /Do not pull for/);
  assert.match(buildRule(5, true), /do not self-filter/);
});

test("shell exits use metadata or a trailing status, not guessed error words", () => {
  assert.equal(shellFailed({ metadata: { exitCode: 1 } }), true);
  assert.equal(
    shellFailed({ metadata: { exit_code: 0 }, content: "Exited with code 1" }),
    false
  );
  assert.equal(
    shellFailed({ content: "actual output\nExited with code 2\n" }),
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
