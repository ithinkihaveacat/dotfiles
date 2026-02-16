import * as fs from "fs";
import { initDB, getAllQuestions, getAllAnswers, getEvaluation } from "../db.js";
import { Question, Answer, Evaluation } from "../types.js";
import { truncate } from "../utils.js";
import { resolveDBPath } from "../resolve.js";

interface ReportData {
  questions: Question[];
  answers: Answer[];
  evaluations: Evaluation[];
  responders: string[];
}

function generateReport(data: ReportData): string {
  const { questions, answers, evaluations, responders } = data;
  
  let report = `# Model Knowledge Gap Analysis\n\n`;
  report += `Date: ${new Date().toISOString().slice(0, 16).replace("T", " ")} \\\n`;

  if (responders.length === 1) {
    report += `Responder: \`${responders[0]}\`\n\n`;
  } else {
    report += `Responders: ${responders.map((m) => `\`${m}\``).join(", ")}\n\n`;
  }

  // Summary Table
  report += "## Summary\n\n";
  report += "| Question | " + responders.map((m) => m).join(" | ") + " |\n";
  report += "| :--- | " + responders.map(() => ":---:").join(" | ") + " |\n";

  for (const q of questions) {
    const row = [truncate(q.text, 60)];
    for (const r of responders) {
      const evalRes = evaluations.find(e => e.question_id === q.id && e.responder === r);
      if (evalRes) {
        row.push(evalRes.is_correct ? "✅" : "❌");
      } else {
        const ans = answers.find(a => a.question_id === q.id && a.responder === r);
        row.push(ans ? "⏳" : "-");
      }
    }
    report += "| " + row.join(" | ") + " |\n";
  }
  report += "\n---\n\n";

  // Detailed Breakdown
  report += "## Detailed Analysis\n\n";

  for (let i = 0; i < questions.length; i++) {
    const q = questions[i];
    report += `### Q${i + 1}: ${q.text}\n\n`;
    report += `**Rationale:** ${q.rationale}\n\n`;
    report += `**Ground Truth:** ${q.ground_truth}\n\n`;

    for (const r of responders) {
      const ans = answers.find(a => a.question_id === q.id && a.responder === r);
      if (!ans) continue;

      const evalRes = evaluations.find(e => e.question_id === q.id && e.responder === r);
      
      if (!evalRes) {
         report += `#### ⏳ ${r}\n\n`;
         report += `**Status:** Answered but not yet evaluated.\n\n`;
         report += `<details><summary>Raw Response</summary>\n\n${ans.text}\n\n</details>\n\n`;
         continue;
      }

      const icon = evalRes.is_correct ? "✅" : "❌";
      report += `#### ${icon} ${r}\n\n`;
      report += `**Analysis:** ${evalRes.summary} ${evalRes.critique}\n\n`;
      report += `<details><summary>Raw Response</summary>\n\n${ans.text}\n\n</details>\n\n`;
    }
    report += "---\n\n";
  }

  return report;
}

export async function run(dbPathOrId: string, options: { force?: boolean } = {}) {
  const dbPath = resolveDBPath(dbPathOrId);
  const db = initDB(dbPath);
  
  const questions = getAllQuestions(db);
  const answers = getAllAnswers(db);
  
  // Get unique responders
  const responders = Array.from(new Set(answers.map(a => a.responder))).sort();

  if (responders.length === 0) {
    console.error("No answers found in database.");
    return;
  }

  // Get evaluations for all answers
  const evaluations: Evaluation[] = [];
  for (const ans of answers) {
    const evaluation = getEvaluation(db, ans.question_id, ans.responder);
    if (evaluation) {
      evaluations.push(evaluation);
    }
  }

  // Completeness Check
  if (!options.force) {
    const questionCount = questions.length;
    const errors: string[] = [];
    
    for (const r of responders) {
      // Check 1: Did this responder answer all questions?
      const responderAnswers = answers.filter(a => a.responder === r);
      if (responderAnswers.length < questionCount) {
        errors.push(`Responder '${r}' has answered only ${responderAnswers.length}/${questionCount} questions.`);
      }

      // Check 2: Are all answers scored?
      const responderEvaluations = evaluations.filter(e => e.responder === r);
      if (responderEvaluations.length < responderAnswers.length) {
         errors.push(`Responder '${r}' has only ${responderEvaluations.length}/${responderAnswers.length} answers evaluated.`);
      }
    }

    if (errors.length > 0) {
      console.error("Report generation aborted due to incomplete data:");
      errors.forEach(e => console.error(`- ${e}`));
      console.error("\nUse --force to generate the report anyway.");
      process.exit(1);
    }
  }

  const report = generateReport({ questions, answers, evaluations, responders });
  console.log(report);
}
