export const CONFIG = {
  MAX_RETRIES: 3,
  MAX_GLOBAL_ERRORS: 10,
  DEFAULT_QUESTION_COUNT: 7,
  EVALUATOR_MODEL: "gemini-3-pro-preview",
  DEFAULT_TARGET_MODEL: "gemini-2.5-flash",
  MAX_CONCURRENCY: 10,
};

export interface RetryOptions {
  maxRetries?: number;
  onRetry?: (attempt: number, error: unknown) => boolean;
}
