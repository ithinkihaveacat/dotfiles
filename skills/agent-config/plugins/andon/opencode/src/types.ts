export type Alert = {
  id: string;
  created_at: string;
  status: "open" | "resolved" | "dismissed";
  color: "red" | "yellow";
  kind: string;
  level: number;
  summary: string;
  details: string;
  sources: string[];
  resolution?: string | null;
  proposed_fix?: string | null;
  fingerprint: string;
  recurrences: number;
  harness?: string;
  conversation_id?: string;
};

export type Stats = { open: number; open_red: number; level: number };
export type Snapshot = {
  alerts: Alert[];
  stats: Stats;
  level: number;
  sessionOverride: boolean;
};

export type TextResponse = { text: string };
