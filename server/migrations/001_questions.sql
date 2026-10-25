-- Optional D1-compatible schema. Not applied; no database provisioned.
CREATE TABLE questions (
  id TEXT PRIMARY KEY,
  fact_key TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL,
  difficulty INTEGER NOT NULL CHECK (difficulty BETWEEN 0 AND 2),
  expires_at TEXT NOT NULL DEFAULT '',
  payload TEXT NOT NULL CHECK (json_valid(payload))
);
CREATE INDEX questions_selection ON questions(category, difficulty, expires_at);
CREATE TABLE refresh_batches (
  id TEXT PRIMARY KEY,
  created_at TEXT NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('candidate', 'approved', 'rejected')),
  content_sha256 TEXT NOT NULL,
  review_json TEXT NOT NULL CHECK (json_valid(review_json))
);
