#!/usr/bin/env node

import { parseArgs } from "node:util";
import { run as runGenerate } from "./commands/generate.js";
import { run as runAnswer } from "./commands/answer.js";
import { run as runScore } from "./commands/score.js";
import { run as runStatus } from "./commands/status.js";
import { run as runReport } from "./commands/report.js";
import { run as runDelete } from "./commands/delete.js";
import { run as runQuestion } from "./commands/question.js";

const SCRIPT_NAME = "socrates";
const VERSION = "1.0.3";

function usage(): void {
  console.log(`Usage: ${SCRIPT_NAME} <command> [options]

Commands:
  generate              Generate questions from stdin.
                        Outputs the absolute path to the created database.
  answer <db> --mode <mode>
                        Answer questions in the database.
                        Modes:
                          model:<model_name> (e.g. model:gemini-2.5-flash)
                            - Append '+grounded' for Google Search grounding.
                            - Append '[]' to auto-increment run ID (e.g. model:foo[]).
                            - Use explicit ID (e.g. model:foo[1]) to resume/overwrite.
                          shell:<script_path> (e.g. shell:./myscript.sh)
                          interactive:<label> (e.g. interactive:manual)
  score <db>            Evaluate answers in the database.
  status <db>           Show progress status.
  delete <db> [resp]    Delete a responder and its answers from the database.
                        Options: --cleanup (remove incomplete/zombie runs)
  questions <db>        List questions in the database.
  report <db>           Generate Markdown report.
                        Options: --force (ignore incomplete data)

Options:
  --questions <n>       Number of questions to generate (default: 7).
  -h, --help            Display this help message.
  -v, --version         Display version number.

Examples:
  # Generate questions and capture the database path
  DB_PATH=$(cat context.md | ${SCRIPT_NAME} generate)

  # Answer questions using the generated database
  ${SCRIPT_NAME} answer "$DB_PATH" --mode model:gemini-2.5-flash

  # Score the answers
  ${SCRIPT_NAME} score "$DB_PATH"

  # Generate a report
  ${SCRIPT_NAME} report "$DB_PATH" > report.md
`);
}

function error(message: string): void {
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
    console.log(`${SCRIPT_NAME} ${VERSION}`);
    process.exit(0);
  }

  try {
    switch (command) {
      case "generate": {
        const { values, positionals } = parseArgs({
          args: args.slice(1),
          options: {
            questions: { type: "string" },
          },
          allowPositionals: true,
        });
        
        const count = values.questions ? parseInt(values.questions, 10) : 7;
        await runGenerate(count);
        break;
      }

      case "answer": {
        const { values, positionals } = parseArgs({
          args: args.slice(1),
          options: {
            mode: { type: "string" },
          },
          allowPositionals: true,
        });

        const dbPath = positionals[0];
        if (!dbPath) {
          error("answer requires a database path argument");
        }
        if (!values.mode) {
          error("answer requires --mode <mode>");
        }

        await runAnswer(dbPath, values.mode as string);
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
      
      case "delete": {
         const { values, positionals } = parseArgs({
            args: args.slice(1),
            options: {
              cleanup: { type: "boolean" },
            },
            allowPositionals: true,
         });

         const dbPath = positionals[0];
         const responder = positionals[1];
         
         if (!dbPath) error("delete requires a database path argument");
         
         if (!values.cleanup && !responder) {
            error("delete requires a responder argument (e.g. 'model:gemini-flash') or --cleanup");
         }

         await runDelete(dbPath, responder, { cleanup: values.cleanup });
         break;
      }

      case "questions": {
         const dbPath = args[1];
         if (!dbPath) error("questions requires a database path argument");
         await runQuestion(dbPath);
         break;
      }

      case "report": {
         const { values, positionals } = parseArgs({
            args: args.slice(1),
            options: {
              force: { type: "boolean" },
            },
            allowPositionals: true,
         });

         const dbPath = positionals[0];
         if (!dbPath) error("report requires a database path argument");
         
         await runReport(dbPath, { force: values.force });
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
