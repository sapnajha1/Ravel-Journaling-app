-- Add AI analysis columns to journal_entries.
-- title already exists; moods, insight, topics are new nullable text columns.
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS moods    TEXT;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS insight  TEXT;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS topics   TEXT;
