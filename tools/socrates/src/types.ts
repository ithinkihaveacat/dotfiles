export interface Question {
  id: number;
  text: string;
  ground_truth: string;
  rationale: string;
  topic?: string;
  created_at: string;
}

export interface Answer {
  question_id: number;
  responder: string;
  text: string;
  timestamp: string;
  meta?: any;
}

export interface Evaluation {
  question_id: number;
  responder: string;
  is_correct: boolean;
  summary: string;
  critique: string;
  timestamp: string;
}

export interface ResponderStats {
  answers: number;
  evaluations: number;
  correct: number;
}

export interface Stats {
  totalQuestions: number;
  responders: Record<string, ResponderStats>;
}
