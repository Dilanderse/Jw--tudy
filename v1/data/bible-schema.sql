PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS books (
  id TEXT PRIMARY KEY,
  sort_order INTEGER NOT NULL UNIQUE,
  name TEXT NOT NULL,
  abbreviation TEXT NOT NULL,
  testament TEXT NOT NULL CHECK (testament IN ('old', 'new')),
  chapters_count INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS chapters (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id TEXT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  chapter_number INTEGER NOT NULL,
  source_href TEXT NOT NULL,
  verses_count INTEGER NOT NULL DEFAULT 0,
  UNIQUE(book_id, chapter_number)
);

CREATE TABLE IF NOT EXISTS verses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  chapter_id INTEGER NOT NULL REFERENCES chapters(id) ON DELETE CASCADE,
  verse_number INTEGER NOT NULL,
  text TEXT NOT NULL,
  UNIQUE(chapter_id, verse_number)
);

CREATE TABLE IF NOT EXISTS verse_notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  verse_id INTEGER NOT NULL REFERENCES verses(id) ON DELETE CASCADE,
  note_order INTEGER NOT NULL,
  note_id TEXT NOT NULL,
  note_text TEXT NOT NULL,
  UNIQUE(verse_id, note_order)
);

-- Future-ready tables for media/Strong overlays on verses.
CREATE TABLE IF NOT EXISTS verse_media (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  verse_id INTEGER NOT NULL REFERENCES verses(id) ON DELETE CASCADE,
  media_type TEXT NOT NULL,
  provider TEXT,
  source_url TEXT NOT NULL,
  title TEXT,
  start_seconds INTEGER,
  end_seconds INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS verse_strong_tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  verse_id INTEGER NOT NULL REFERENCES verses(id) ON DELETE CASCADE,
  token_index INTEGER NOT NULL,
  token_text TEXT NOT NULL,
  strong_number TEXT NOT NULL,
  lemma TEXT,
  UNIQUE(verse_id, token_index, strong_number)
);

CREATE TABLE IF NOT EXISTS book_intro_videos (
  book_id TEXT PRIMARY KEY REFERENCES books(id) ON DELETE CASCADE,
  source_url TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_chapters_book ON chapters(book_id, chapter_number);
CREATE INDEX IF NOT EXISTS idx_verses_chapter ON verses(chapter_id, verse_number);
CREATE INDEX IF NOT EXISTS idx_verse_notes_verse ON verse_notes(verse_id, note_order);
CREATE INDEX IF NOT EXISTS idx_verse_media_verse ON verse_media(verse_id);
CREATE INDEX IF NOT EXISTS idx_verse_strong_tags_verse ON verse_strong_tags(verse_id, token_index);
