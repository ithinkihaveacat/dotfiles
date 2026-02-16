import * as fs from "fs";
import { initDB, getAllQuestions, getAllAnswers, getEvaluation } from "../db.js";
import { Question, Answer, Evaluation } from "../types.js";
import { truncate } from "../utils.js";

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

export async function run(dbPath: string) {
  if (!fs.existsSync(dbPath)) {
    throw new Error(`Database not found: ${dbPath}`);
  }

  const db = initDB(dbPath);
  const questions = getAllQuestions(db);
  const answers = getAllAnswers(db);
  
  // Get evaluations for all answers
  const evaluations: Evaluation[] = [];
  for (const ans of answers) {
    const evaluation = getEvaluation(db, ans.question_id, ans.responder);
    if (evaluation) {
      evaluations.push(evaluation);
    }
  }

  // Get unique responders
  const responders = Array.from(new Set(answers.map(a => a.responder))).sort();

  const report = generateReport({ questions, answers, evaluations, responders });
  console.log(report);
}
