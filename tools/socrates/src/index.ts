#!/usr/bin/env node

import { parseArgs } from "node:util";
import { run as runGenerate } from "./commands/generate.js";
import { run as runAnswer } from "./commands/answer.js";
import { run as runScore } from "./commands/score.js";
import { run as runStatus } from "./commands/status.js";
import { run as runReport } from "./commands/report.js";
import { run as runQuestion } from "./commands/question.js";
import pkg from "../package.json" with { type: "json" };

const SCRIPT_NAME = "socrates";

function usage(): void {
  console.log(`Usage: ${SCRIPT_NAME} <command> [options]

Commands:
  generate [topic]      Generate questions from stdin.
  answer <db> --mode <mode>
                        Answer questions in the database.
                        Modes:
                          model:<model_name> (e.g. model:gemini-2.5-flash)
                          shell:<script_path> (e.g. shell:./myscript.sh)
                          interactive:<label> (e.g. interactive:manual)
  score <db>            Evaluate answers in the database.
  status <db>           Show progress status.
  question <db>         List questions in the database.
  report <db>           Generate Markdown report.

Options:
  --questions <n>       Number of questions to generate (default: 7).
  -h, --help            Display this help message.
  -v, --version         Display version number.

Examples:
  cat context.md | ${SCRIPT_NAME} generate "Topic Name" > my-session.db
  ${SCRIPT_NAME} answer my-session.db --mode model:gemini-2.5-flash
  ${SCRIPT_NAME} score my-session.db
  ${SCRIPT_NAME} report my-session.db > report.md
`);
}

function error(message: string): never {
  console.error(`${SCRIPT_NAME}: ${message}`);
  process.exit(1);
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length === 0) {
    usage();
    process.exit(0);
  }

  const command = args[0];

  if (["-h", "--help"].includes(command)) {
    usage();
    process.exit(0);
  }

  if (["-v", "--version"].includes(command)) {
    console.log(`${SCRIPT_NAME} ${pkg.version}`);
    process.exit(0);
  }

  try {
    switch (command) {
      case "generate": {
        const options = parseArgs({
          args: args.slice(1),
          options: {
            questions: { type: "string" },
          },
          allowPositionals: true,
        });
        
        const topic = options.positionals[0];
        // Topic is optional. If undefined, generate.ts will use a default.
        
        const count = options.values.questions ? parseInt(options.values.questions, 10) : 7;
        await runGenerate(topic, count);
        break;
      }

      case "answer": {
        const options = parseArgs({
          args: args.slice(1),
          options: {
            mode: { type: "string" },
          },
          allowPositionals: true,
        });

        const dbPath = options.positionals[0];
        if (!dbPath) {
          error("answer requires a database path argument");
        }
        if (!options.values.mode) {
          error("answer requires --mode <mode>");
        }

        await runAnswer(dbPath, options.values.mode);
        break;
      }

      case "score": {
         const dbPath = args[1];
         if (!dbPath) error("score requires a database path argument");
         await runScore(dbPath);
         break;
      }

      case "status": {
         const dbPath = args[1];
         if (!dbPath) error("status requires a database path argument");
         await runStatus(dbPath);
         break;
      }

      case "question": {
         const dbPath = args[1];
         if (!dbPath) error("question requires a database path argument");
         await runQuestion(dbPath);
         break;
      }

      case "report": {
         const dbPath = args[1];
         if (!dbPath) error("report requires a database path argument");
         await runReport(dbPath);
         break;
      }

      default:
        error(`unknown command: ${command}`);
    }
  } catch (err: any) {
    error(err.message || String(err));
  }
}

main();
