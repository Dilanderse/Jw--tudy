import { existsSync } from "node:fs"
import { join, resolve } from "node:path"
import { DatabaseSync } from "node:sqlite"

export interface BibleBookSummary {
  id: string
  name: string
  abbreviation: string
  testament: "old" | "new"
  chapters: number
}

export interface BibleChapterSummary {
  number: number
  verses: number
}

export interface BibleVerseNote {
  id: string
  text: string
}

export interface BibleVerseMedia {
  id: number
  mediaType: string
  provider: string | null
  sourceUrl: string
  title: string | null
  startSeconds: number | null
  endSeconds: number | null
  createdAt: string
}

export interface BibleVerseStrongTag {
  id: number
  tokenIndex: number
  tokenText: string
  strongNumber: string
  lemma: string | null
}

export interface BibleVerse {
  number: number
  text: string
  notes: BibleVerseNote[]
  media: BibleVerseMedia[]
  strongTags: BibleVerseStrongTag[]
}

export interface AddVerseMediaInput {
  bookId: string
  chapterNumber: number
  verseNumber: number
  mediaType: string
  provider: string | null
  sourceUrl: string
  title: string | null
  startSeconds: number | null
  endSeconds: number | null
}

export interface UpdateVerseMediaInput {
  mediaId: number
  mediaType: string
  provider: string | null
  sourceUrl: string
  title: string | null
  startSeconds: number | null
  endSeconds: number | null
}

export interface AddVerseStrongTagInput {
  bookId: string
  chapterNumber: number
  verseNumber: number
  tokenText: string
  strongNumber: string
  lemma: string | null
  tokenIndex: number | null
}

export interface UpdateVerseStrongTagInput {
  tagId: number
  tokenText: string
  strongNumber: string
  lemma: string | null
  tokenIndex: number | null
}

const DEFAULT_DB_PATH = join(process.cwd(), "data", "bible.sqlite")

function resolveDbPath() {
  const configuredPath = process.env.BIBLE_DB_PATH
  return configuredPath ? resolve(configuredPath) : DEFAULT_DB_PATH
}

let db: DatabaseSync | null = null

function getDatabase() {
  const dbPath = resolveDbPath()

  if (!existsSync(dbPath)) {
    throw new Error(`Bible DB introuvable: ${dbPath}`)
  }

  if (!db) {
    db = new DatabaseSync(dbPath)
    db.exec("PRAGMA foreign_keys = ON;")
  }

  return db
}

function getVerseId(bookId: string, chapterNumber: number, verseNumber: number) {
  const statement = getDatabase().prepare(
    `SELECT v.id AS verseId
     FROM verses v
     JOIN chapters c ON c.id = v.chapter_id
     WHERE c.book_id = ? AND c.chapter_number = ? AND v.verse_number = ?`,
  )

  const row = statement.get(bookId, chapterNumber, verseNumber) as unknown as { verseId: number } | undefined
  return row?.verseId ?? null
}

interface VerseMediaJoinRow {
  mediaId: number
  verseId: number
  mediaType: string
  provider: string | null
  sourceUrl: string
  title: string | null
  startSeconds: number | null
  endSeconds: number | null
  createdAt: string
}

interface VerseStrongTagJoinRow {
  tagId: number
  verseId: number
  tokenIndex: number
  tokenText: string
  strongNumber: string
  lemma: string | null
}

function mapMediaRow(row: VerseMediaJoinRow): BibleVerseMedia {
  return {
    id: row.mediaId,
    mediaType: row.mediaType,
    provider: row.provider,
    sourceUrl: row.sourceUrl,
    title: row.title,
    startSeconds: row.startSeconds,
    endSeconds: row.endSeconds,
    createdAt: row.createdAt,
  }
}

function mapStrongTagRow(row: VerseStrongTagJoinRow): BibleVerseStrongTag {
  return {
    id: row.tagId,
    tokenIndex: row.tokenIndex,
    tokenText: row.tokenText,
    strongNumber: row.strongNumber,
    lemma: row.lemma,
  }
}

function getNextStrongTokenIndex(verseId: number) {
  const statement = getDatabase().prepare(
    `SELECT COALESCE(MAX(token_index), 0) + 1 AS nextTokenIndex
     FROM verse_strong_tags
     WHERE verse_id = ?`,
  )

  const row = statement.get(verseId) as unknown as { nextTokenIndex: number } | undefined
  return row?.nextTokenIndex ?? 1
}

export function isBibleDatabaseReady() {
  return existsSync(resolveDbPath())
}

export function getBibleDatabasePath() {
  return resolveDbPath()
}

export function getBibleBooks() {
  const statement = getDatabase().prepare(
    `SELECT id, name, abbreviation, testament, chapters_count AS chapters
     FROM books
     ORDER BY sort_order ASC`,
  )

  return statement.all() as unknown as BibleBookSummary[]
}

export function getBibleBook(bookId: string) {
  const statement = getDatabase().prepare(
    `SELECT id, name, abbreviation, testament, chapters_count AS chapters
     FROM books
     WHERE id = ?`,
  )

  return (statement.get(bookId) as unknown as BibleBookSummary | undefined) ?? null
}

export function getBibleChapters(bookId: string) {
  const statement = getDatabase().prepare(
    `SELECT chapter_number AS number, verses_count AS verses
     FROM chapters
     WHERE book_id = ?
     ORDER BY chapter_number ASC`,
  )

  return statement.all(bookId) as unknown as BibleChapterSummary[]
}

interface VerseNoteJoinRow {
  verseId: number
  verseNumber: number
  verseText: string
  noteOrder: number | null
  noteId: string | null
  noteText: string | null
}

export function getBibleVerses(bookId: string, chapterNumber: number) {
  const notesStatement = getDatabase().prepare(
    `SELECT
       v.id AS verseId,
       v.verse_number AS verseNumber,
       v.text AS verseText,
       vn.note_order AS noteOrder,
       vn.note_id AS noteId,
       vn.note_text AS noteText
     FROM verses v
     JOIN chapters c ON c.id = v.chapter_id
     LEFT JOIN verse_notes vn ON vn.verse_id = v.id
     WHERE c.book_id = ? AND c.chapter_number = ?
     ORDER BY v.verse_number ASC, vn.note_order ASC`,
  )

  const noteRows = notesStatement.all(bookId, chapterNumber) as unknown as VerseNoteJoinRow[]
  const grouped = new Map<number, BibleVerse>()

  for (const row of noteRows) {
    const existing = grouped.get(row.verseId)
    if (!existing) {
      grouped.set(row.verseId, {
        number: row.verseNumber,
        text: row.verseText,
        notes: row.noteId && row.noteText ? [{ id: row.noteId, text: row.noteText }] : [],
        media: [],
        strongTags: [],
      })
      continue
    }

    if (row.noteId && row.noteText) {
      existing.notes.push({ id: row.noteId, text: row.noteText })
    }
  }

  if (grouped.size === 0) {
    return []
  }

  const mediaStatement = getDatabase().prepare(
    `SELECT
       vm.id AS mediaId,
       vm.verse_id AS verseId,
       vm.media_type AS mediaType,
       vm.provider AS provider,
       vm.source_url AS sourceUrl,
       vm.title AS title,
       vm.start_seconds AS startSeconds,
       vm.end_seconds AS endSeconds,
       vm.created_at AS createdAt
     FROM verse_media vm
     JOIN verses v ON v.id = vm.verse_id
     JOIN chapters c ON c.id = v.chapter_id
     WHERE c.book_id = ? AND c.chapter_number = ?
     ORDER BY v.verse_number ASC, vm.created_at ASC, vm.id ASC`,
  )

  const mediaRows = mediaStatement.all(bookId, chapterNumber) as unknown as VerseMediaJoinRow[]
  for (const row of mediaRows) {
    const verse = grouped.get(row.verseId)
    if (verse) {
      verse.media.push(mapMediaRow(row))
    }
  }

  const strongTagsStatement = getDatabase().prepare(
    `SELECT
       vst.id AS tagId,
       vst.verse_id AS verseId,
       vst.token_index AS tokenIndex,
       vst.token_text AS tokenText,
       vst.strong_number AS strongNumber,
       vst.lemma AS lemma
     FROM verse_strong_tags vst
     JOIN verses v ON v.id = vst.verse_id
     JOIN chapters c ON c.id = v.chapter_id
     WHERE c.book_id = ? AND c.chapter_number = ?
     ORDER BY v.verse_number ASC, vst.token_index ASC, vst.id ASC`,
  )

  const strongTagRows = strongTagsStatement.all(bookId, chapterNumber) as unknown as VerseStrongTagJoinRow[]
  for (const row of strongTagRows) {
    const verse = grouped.get(row.verseId)
    if (verse) {
      verse.strongTags.push(mapStrongTagRow(row))
    }
  }

  return [...grouped.values()].sort((left, right) => left.number - right.number)
}

export function getBookIntroVideo(bookId: string) {
  const statement = getDatabase().prepare(
    `SELECT source_url AS sourceUrl
     FROM book_intro_videos
     WHERE book_id = ?`,
  )

  const row = statement.get(bookId) as unknown as { sourceUrl: string } | undefined
  return row?.sourceUrl ?? null
}

export function upsertBookIntroVideo(bookId: string, sourceUrl: string) {
  const statement = getDatabase().prepare(
    `INSERT INTO book_intro_videos (book_id, source_url, updated_at)
     VALUES (?, ?, CURRENT_TIMESTAMP)
     ON CONFLICT(book_id) DO UPDATE SET
       source_url = excluded.source_url,
       updated_at = CURRENT_TIMESTAMP`,
  )

  statement.run(bookId, sourceUrl)
}

export function deleteBookIntroVideo(bookId: string) {
  const statement = getDatabase().prepare(`DELETE FROM book_intro_videos WHERE book_id = ?`)
  statement.run(bookId)
}

export function addVerseMedia(input: AddVerseMediaInput) {
  const verseId = getVerseId(input.bookId, input.chapterNumber, input.verseNumber)
  if (!verseId) {
    return null
  }

  const insertStatement = getDatabase().prepare(
    `INSERT INTO verse_media (
       verse_id,
       media_type,
       provider,
       source_url,
       title,
       start_seconds,
       end_seconds
     )
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
  )

  const inserted = insertStatement.run(
    verseId,
    input.mediaType,
    input.provider,
    input.sourceUrl,
    input.title,
    input.startSeconds,
    input.endSeconds,
  )

  const selectStatement = getDatabase().prepare(
    `SELECT
       id AS mediaId,
       verse_id AS verseId,
       media_type AS mediaType,
       provider AS provider,
       source_url AS sourceUrl,
       title AS title,
       start_seconds AS startSeconds,
       end_seconds AS endSeconds,
       created_at AS createdAt
     FROM verse_media
     WHERE id = ?`,
  )

  const row = selectStatement.get(Number(inserted.lastInsertRowid)) as unknown as VerseMediaJoinRow | undefined
  return row ? mapMediaRow(row) : null
}

export function updateVerseMedia(input: UpdateVerseMediaInput) {
  const updateStatement = getDatabase().prepare(
    `UPDATE verse_media
     SET media_type = ?,
         provider = ?,
         source_url = ?,
         title = ?,
         start_seconds = ?,
         end_seconds = ?
     WHERE id = ?`,
  )

  const updateResult = updateStatement.run(
    input.mediaType,
    input.provider,
    input.sourceUrl,
    input.title,
    input.startSeconds,
    input.endSeconds,
    input.mediaId,
  )

  if (updateResult.changes < 1) {
    return null
  }

  const selectStatement = getDatabase().prepare(
    `SELECT
       id AS mediaId,
       verse_id AS verseId,
       media_type AS mediaType,
       provider AS provider,
       source_url AS sourceUrl,
       title AS title,
       start_seconds AS startSeconds,
       end_seconds AS endSeconds,
       created_at AS createdAt
     FROM verse_media
     WHERE id = ?`,
  )

  const row = selectStatement.get(input.mediaId) as unknown as VerseMediaJoinRow | undefined
  return row ? mapMediaRow(row) : null
}

export function deleteVerseMedia(mediaId: number) {
  const statement = getDatabase().prepare(`DELETE FROM verse_media WHERE id = ?`)
  const result = statement.run(mediaId)
  return result.changes > 0
}

export function addVerseStrongTag(input: AddVerseStrongTagInput) {
  const verseId = getVerseId(input.bookId, input.chapterNumber, input.verseNumber)
  if (!verseId) {
    return null
  }

  const tokenIndex = input.tokenIndex ?? getNextStrongTokenIndex(verseId)

  const insertStatement = getDatabase().prepare(
    `INSERT INTO verse_strong_tags (
       verse_id,
       token_index,
       token_text,
       strong_number,
       lemma
     )
     VALUES (?, ?, ?, ?, ?)`,
  )

  const inserted = insertStatement.run(verseId, tokenIndex, input.tokenText, input.strongNumber, input.lemma)

  const selectStatement = getDatabase().prepare(
    `SELECT
       id AS tagId,
       verse_id AS verseId,
       token_index AS tokenIndex,
       token_text AS tokenText,
       strong_number AS strongNumber,
       lemma AS lemma
     FROM verse_strong_tags
     WHERE id = ?`,
  )

  const row = selectStatement.get(Number(inserted.lastInsertRowid)) as unknown as VerseStrongTagJoinRow | undefined
  return row ? mapStrongTagRow(row) : null
}

export function updateVerseStrongTag(input: UpdateVerseStrongTagInput) {
  const getCurrentStatement = getDatabase().prepare(
    `SELECT
       id AS tagId,
       verse_id AS verseId,
       token_index AS tokenIndex,
       token_text AS tokenText,
       strong_number AS strongNumber,
       lemma AS lemma
     FROM verse_strong_tags
     WHERE id = ?`,
  )

  const current = getCurrentStatement.get(input.tagId) as unknown as VerseStrongTagJoinRow | undefined
  if (!current) {
    return null
  }

  const updateStatement = getDatabase().prepare(
    `UPDATE verse_strong_tags
     SET token_index = ?,
         token_text = ?,
         strong_number = ?,
         lemma = ?
     WHERE id = ?`,
  )

  updateStatement.run(
    input.tokenIndex ?? current.tokenIndex,
    input.tokenText,
    input.strongNumber,
    input.lemma,
    input.tagId,
  )

  const updated = getCurrentStatement.get(input.tagId) as unknown as VerseStrongTagJoinRow | undefined
  return updated ? mapStrongTagRow(updated) : null
}

export function deleteVerseStrongTag(tagId: number) {
  const statement = getDatabase().prepare(`DELETE FROM verse_strong_tags WHERE id = ?`)
  const result = statement.run(tagId)
  return result.changes > 0
}
