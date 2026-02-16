import Database from "better-sqlite3";
import { Question, Answer, Evaluation, Stats } from "./types.js";

export function initDB(path: string): Database.Database {
  const db = new Database(path);
  db.pragma("journal_mode = WAL");

  db.exec(`
    CREATE TABLE IF NOT EXISTS metadata (
      key TEXT PRIMARY KEY,
      value TEXT
    );

    CREATE TABLE IF NOT EXISTS questions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      text TEXT NOT NULL,
      ground_truth TEXT NOT NULL,
      rationale TEXT NOT NULL,
      topic TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS answers (
      question_id INTEGER,
      responder TEXT,
      text TEXT NOT NULL,
      meta TEXT,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (question_id, responder),
      FOREIGN KEY(question_id) REFERENCES questions(id)
    );

    CREATE TABLE IF NOT EXISTS evaluations (
      question_id INTEGER,
      responder TEXT,
      is_correct BOOLEAN NOT NULL,
      summary TEXT,
      critique TEXT,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (question_id, responder),
      FOREIGN KEY(question_id) REFERENCES questions(id)
    );
  `);

  return db;
}

export function addQuestions(db: Database.Database, questions: Omit<Question, "id" | "created_at">[]) {
  const insert = db.prepare("INSERT INTO questions (text, ground_truth, rationale, topic) VALUES (?, ?, ?, ?)");
  const insertMany = db.transaction((qs) => {
    for (const q of qs) insert.run(q.text, q.ground_truth, q.rationale, q.topic || null);
  });
  insertMany(questions);
}

export function getNextQuestion(db: Database.Database, responder: string): Question | null {
  const row = db.prepare(`
    SELECT * FROM questions
    WHERE id NOT IN (
      SELECT question_id FROM answers WHERE responder = ?
    )
    ORDER BY id ASC
    LIMIT 1
  `).get(responder) as Question | undefined;
  return row || null;
}

export function getUnansweredQuestions(db: Database.Database, responder: string): Question[] {
  return db.prepare(`
    SELECT * FROM questions
    WHERE id NOT IN (
      SELECT question_id FROM answers WHERE responder = ?
    )
    ORDER BY id ASC
  `).all(responder) as Question[];
}

export function getAllQuestions(db: Database.Database): Question[] {
  return db.prepare("SELECT * FROM questions ORDER BY id ASC").all() as Question[];
}

export function addAnswer(db: Database.Database, answer: Omit<Answer, "timestamp">) {
  const insert = db.prepare(`
    INSERT INTO answers (question_id, responder, text, meta)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(question_id, responder) DO UPDATE SET
      text=excluded.text,
      meta=excluded.meta,
      timestamp=CURRENT_TIMESTAMP
  `);
  insert.run(
    answer.question_id,
    answer.responder,
    answer.text,
    answer.meta ? JSON.stringify(answer.meta) : null
  );
}

export function getAnswers(db: Database.Database, questionId: number): Answer[] {
  const rows = db.prepare("SELECT * FROM answers WHERE question_id = ?").all() as any[];
  return rows.map((r) => ({
    question_id: r.question_id,
    responder: r.responder,
    text: r.text,
    timestamp: r.timestamp,
    meta: r.meta ? JSON.parse(r.meta) : undefined,
  }));
}

export function getAnswer(db: Database.Database, questionId: number, responder: string): Answer | null {
  const row = db.prepare(
    "SELECT * FROM answers WHERE question_id = ? AND responder = ?"
  ).get(questionId, responder) as any;
  if (!row) return null;
  return {
    question_id: row.question_id,
    responder: row.responder,
    text: row.text,
    timestamp: row.timestamp,
    meta: row.meta ? JSON.parse(row.meta) : undefined,
  };
}

export function getAllAnswers(db: Database.Database): Answer[] {
  const rows = db.prepare("SELECT * FROM answers").all() as any[];
  return rows.map((r) => ({
    question_id: r.question_id,
    responder: r.responder,
    text: r.text,
    timestamp: r.timestamp,
    meta: r.meta ? JSON.parse(r.meta) : undefined,
  }));
}

export function addEvaluation(db: Database.Database, evaluation: Omit<Evaluation, "timestamp">) {
  const insert = db.prepare(`
    INSERT INTO evaluations (question_id, responder, is_correct, summary, critique)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(question_id, responder) DO UPDATE SET
      is_correct=excluded.is_correct,
      summary=excluded.summary,
      critique=excluded.critique,
      timestamp=CURRENT_TIMESTAMP
  `);
  insert.run(
    evaluation.question_id,
    evaluation.responder,
    evaluation.is_correct ? 1 : 0,
    evaluation.summary,
    evaluation.critique
  );
}

export function getEvaluation(db: Database.Database, questionId: number, responder: string): Evaluation | null {
  const row = db.prepare(
    "SELECT * FROM evaluations WHERE question_id = ? AND responder = ?"
  ).get(questionId, responder) as any;
  if (!row) return null;
  return {
    question_id: row.question_id,
    responder: row.responder,
    is_correct: !!row.is_correct,
    summary: row.summary,
    critique: row.critique,
    timestamp: row.timestamp,
  };
}

export function getUnevaluatedAnswers(db: Database.Database): Answer[] {
  const rows = db.prepare(`
    SELECT a.* FROM answers a
    LEFT JOIN evaluations e ON a.question_id = e.question_id AND a.responder = e.responder
    WHERE e.question_id IS NULL
  `).all() as any[];
  return rows.map((r) => ({
    question_id: r.question_id,
    responder: r.responder,
    text: r.text,
    timestamp: r.timestamp,
    meta: r.meta ? JSON.parse(r.meta) : undefined,
  }));
}

export function getStats(db: Database.Database): Stats {
  const totalQuestions = (db.prepare("SELECT COUNT(*) as count FROM questions").get() as any).count;

  const responders: Record<string, { answers: number; evaluations: number; correct: number }> = {};

  const answerCounts = db.prepare("SELECT responder, COUNT(*) as count FROM answers GROUP BY responder").all() as any[];
  for (const row of answerCounts) {
    responders[row.responder] = { answers: row.count, evaluations: 0, correct: 0 };
  }

  const evalCounts = db.prepare(
    "SELECT responder, COUNT(*) as count, SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct FROM evaluations GROUP BY responder"
  ).all() as any[];

  for (const row of evalCounts) {
    if (!responders[row.responder]) {
      responders[row.responder] = { answers: 0, evaluations: 0, correct: 0 };
    }
    responders[row.responder].evaluations = row.count;
    responders[row.responder].correct = row.correct;
  }

  return { totalQuestions, responders };
}
