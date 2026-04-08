#!/usr/bin/env node

import { spawnSync } from "node:child_process"
import { readFileSync, existsSync, mkdirSync, mkdtempSync, rmSync } from "node:fs"
import { tmpdir } from "node:os"
import { dirname, join, resolve } from "node:path"
import { DatabaseSync } from "node:sqlite"
import { fileURLToPath } from "node:url"

const CANONICAL_BOOK_IDS = [
  "genesis",
  "exodus",
  "leviticus",
  "numbers",
  "deuteronomy",
  "joshua",
  "judges",
  "ruth",
  "1samuel",
  "2samuel",
  "1kings",
  "2kings",
  "1chronicles",
  "2chronicles",
  "ezra",
  "nehemiah",
  "esther",
  "job",
  "psalms",
  "proverbs",
  "ecclesiastes",
  "songs",
  "isaiah",
  "jeremiah",
  "lamentations",
  "ezekiel",
  "daniel",
  "hosea",
  "joel",
  "amos",
  "obadiah",
  "jonah",
  "micah",
  "nahum",
  "habakkuk",
  "zephaniah",
  "haggai",
  "zechariah",
  "malachi",
  "matthew",
  "mark",
  "luke",
  "john",
  "acts",
  "romans",
  "1corinthians",
  "2corinthians",
  "galatians",
  "ephesians",
  "philippians",
  "colossians",
  "1thessalonians",
  "2thessalonians",
  "1timothy",
  "2timothy",
  "titus",
  "philemon",
  "hebrews",
  "james",
  "1peter",
  "2peter",
  "1john",
  "2john",
  "3john",
  "jude",
  "revelation",
]

const NAMED_ENTITIES = {
  amp: "&",
  lt: "<",
  gt: ">",
  quot: '"',
  apos: "'",
  nbsp: " ",
  thinsp: " ",
  ensp: " ",
  emsp: " ",
  laquo: "«",
  raquo: "»",
  lsquo: "‘",
  rsquo: "’",
  ldquo: "“",
  rdquo: "”",
  ndash: "–",
  mdash: "—",
  hellip: "…",
}

function decodeHtmlEntities(input) {
  return input
    .replace(/&#x([0-9a-fA-F]+);/g, (_, hex) => String.fromCodePoint(Number.parseInt(hex, 16)))
    .replace(/&#(\d+);/g, (_, dec) => String.fromCodePoint(Number.parseInt(dec, 10)))
    .replace(/&([a-zA-Z]+);/g, (match, name) => NAMED_ENTITIES[name] ?? match)
}

function stripTags(input) {
  return input
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<br\s*\/?\s*>/gi, " ")
    .replace(/<\/p>/gi, " ")
    .replace(/<[^>]+>/g, " ")
}

function normalizeText(input) {
  return decodeHtmlEntities(stripTags(input)).replace(/[\u00a0\u202f]/g, " ").replace(/\s+/g, " ").trim()
}

function parseTitle(xhtml) {
  const titleMatch = xhtml.match(/<title>([\s\S]*?)<\/title>/i)
  if (!titleMatch) {
    return ""
  }

  return normalizeText(titleMatch[1])
}

function parseBookLinks(bookNavContent) {
  const links = []
  const linkPattern = /<a\s+href="([^"]+)">([^<]+)<\/a>/g

  for (const match of bookNavContent.matchAll(linkPattern)) {
    const href = match[1].trim()

    if (/^biblechapternav\d+\.xhtml$/i.test(href) || /^\d+(?:-split\d+)?\.xhtml$/i.test(href)) {
      links.push({
        href,
        abbreviation: normalizeText(match[2]).replace(/\.$/, ""),
      })
    }
  }

  return links
}

function parseChapterLinks(chapterNavContent) {
  const chapterLinks = []
  const chapterLinkPattern = /<a\s+href="([^"]+)">(\d+)<\/a>/g

  for (const match of chapterNavContent.matchAll(chapterLinkPattern)) {
    chapterLinks.push({
      href: match[1].trim(),
      chapterNumber: Number.parseInt(match[2], 10),
    })
  }

  chapterLinks.sort((left, right) => left.chapterNumber - right.chapterNumber)
  return chapterLinks
}

function parseFootnotes(chapterContent) {
  const byNoteId = new Map()

  const footnotePattern = /<div epub:type="footnote" id="(footnote\d+)">([\s\S]*?)<\/div>/g

  for (const match of chapterContent.matchAll(footnotePattern)) {
    const noteId = match[1]
    const noteContent = match[2].replace(/<a\b[^>]*>[\s\S]*?<\/a>\s*/gi, " ")
    const noteText = normalizeText(noteContent)

    if (noteText) {
      byNoteId.set(noteId, noteText)
    }
  }

  return byNoteId
}

function parseVerses(chapterContent) {
  const markers = []
  const markerPattern = /<span id="chapter(\d+)_verse(\d+)"><\/span>/g

  for (const match of chapterContent.matchAll(markerPattern)) {
    markers.push({
      chapterNumber: Number.parseInt(match[1], 10),
      verseNumber: Number.parseInt(match[2], 10),
      index: match.index,
      markerText: match[0],
    })
  }

  if (markers.length === 0) {
    return []
  }

  const footnotesStart = chapterContent.indexOf('<div class="groupFootnote">')
  const boundaryIndex = footnotesStart === -1 ? chapterContent.length : footnotesStart
  const footnotesById = parseFootnotes(chapterContent)

  const verses = []

  for (let index = 0; index < markers.length; index += 1) {
    const current = markers[index]
    const next = markers[index + 1]
    const start = current.index + current.markerText.length
    const end = next ? Math.min(next.index, boundaryIndex) : boundaryIndex

    if (end <= start) {
      continue
    }

    const fragment = chapterContent.slice(start, end)
    const noteRefs = []
    const seenNotes = new Set()

    for (const noteMatch of fragment.matchAll(/href="#(footnote\d+)"/g)) {
      const noteId = noteMatch[1]
      if (!seenNotes.has(noteId)) {
        seenNotes.add(noteId)
        noteRefs.push(noteId)
      }
    }

    const cleanedFragment = fragment
      .replace(/<span id="footnotesource\d+"><\/span>\s*/gi, " ")
      .replace(/<a\b[^>]*epub:type="noteref"[^>]*>[\s\S]*?<\/a>/gi, " ")
      .replace(/<span\b[^>]*class="pageNum"[^>]*>[\s\S]*?<\/span>/gi, " ")
      .replace(/<span\b[^>]*id="pos\d+"[^>]*><\/span>/gi, " ")
      .replace(/<span\b[^>]*class="w_ch"[^>]*>[\s\S]*?<\/span>/gi, " ")
      .replace(/<strong>\s*<sup>\d+<\/sup>\s*<\/strong>/gi, " ")
      .replace(/<sup>\d+<\/sup>/gi, " ")

    const text = normalizeText(cleanedFragment)

    if (!text) {
      continue
    }

    const notes = noteRefs
      .map((noteId) => ({ noteId, noteText: footnotesById.get(noteId) ?? "" }))
      .filter((note) => Boolean(note.noteText))

    verses.push({
      chapterNumber: current.chapterNumber,
      verseNumber: current.verseNumber,
      text,
      notes,
    })
  }

  return verses
}

function loadChapterLinksForBook(oebpsDir, href) {
  if (/^biblechapternav\d+\.xhtml$/i.test(href)) {
    const navPath = join(oebpsDir, href)
    const navContent = readFileSync(navPath, "utf8")
    const chapterLinks = parseChapterLinks(navContent)
    const name = parseTitle(navContent)

    if (chapterLinks.length === 0) {
      throw new Error(`Aucun chapitre trouvé dans ${href}`)
    }

    return {
      name,
      chapterLinks,
    }
  }

  if (!/^\d+(?:-split\d+)?\.xhtml$/i.test(href)) {
    throw new Error(`Format de lien de livre non supporté: ${href}`)
  }

  const chapterPath = join(oebpsDir, href)
  const chapterContent = readFileSync(chapterPath, "utf8")
  const chapterTitle = parseTitle(chapterContent)
  const name = chapterTitle.replace(/\s+\d+\s*$/, "").trim()

  return {
    name,
    chapterLinks: [{ href, chapterNumber: 1 }],
  }
}

function ensureSequentialChapters(bookId, chapterLinks) {
  for (let index = 0; index < chapterLinks.length; index += 1) {
    const expected = index + 1
    if (chapterLinks[index].chapterNumber !== expected) {
      throw new Error(`Chapitres non séquentiels pour ${bookId}: attendu ${expected}, reçu ${chapterLinks[index].chapterNumber}`)
    }
  }
}

function main() {
  const epubPath = resolve(process.cwd(), process.argv[2] ?? "nwt_F.epub")
  const outputDbPath = resolve(process.cwd(), process.argv[3] ?? "data/bible.sqlite")

  if (!existsSync(epubPath)) {
    throw new Error(`EPUB introuvable: ${epubPath}`)
  }

  const tempDir = mkdtempSync(join(tmpdir(), "nwt-import-"))
  const schemaPath = fileURLToPath(new URL("../data/bible-schema.sql", import.meta.url))
  const schemaSql = readFileSync(schemaPath, "utf8")

  let db = null

  try {
    const unzip = spawnSync("unzip", ["-q", "-o", epubPath, "-d", tempDir], { encoding: "utf8" })

    if (unzip.error) {
      throw unzip.error
    }

    if (unzip.status !== 0) {
      throw new Error(`Échec unzip (${unzip.status}): ${unzip.stderr || unzip.stdout}`)
    }

    const oebpsDir = join(tempDir, "OEBPS")
    const bookNavPath = join(oebpsDir, "biblebooknav.xhtml")
    const bookNavContent = readFileSync(bookNavPath, "utf8")
    const bookLinks = parseBookLinks(bookNavContent)

    if (bookLinks.length !== CANONICAL_BOOK_IDS.length) {
      throw new Error(
        `Nombre de livres invalide dans biblebooknav.xhtml: attendu ${CANONICAL_BOOK_IDS.length}, reçu ${bookLinks.length}`,
      )
    }

    if (existsSync(outputDbPath)) {
      rmSync(outputDbPath)
    }

    mkdirSync(dirname(outputDbPath), { recursive: true })

    db = new DatabaseSync(outputDbPath)
    db.exec("PRAGMA journal_mode = OFF;")
    db.exec("PRAGMA synchronous = OFF;")
    db.exec("PRAGMA temp_store = MEMORY;")
    db.exec(schemaSql)

    const insertBook = db.prepare(
      `INSERT INTO books (id, sort_order, name, abbreviation, testament, chapters_count)
       VALUES (?, ?, ?, ?, ?, ?)`,
    )
    const insertChapter = db.prepare(
      `INSERT INTO chapters (book_id, chapter_number, source_href, verses_count)
       VALUES (?, ?, ?, ?)`,
    )
    const insertVerse = db.prepare(
      `INSERT INTO verses (chapter_id, verse_number, text)
       VALUES (?, ?, ?)`,
    )
    const insertVerseNote = db.prepare(
      `INSERT INTO verse_notes (verse_id, note_order, note_id, note_text)
       VALUES (?, ?, ?, ?)`,
    )

    let totalBooks = 0
    let totalChapters = 0
    let totalVerses = 0
    let totalNotes = 0

    db.exec("BEGIN")

    try {
      for (let order = 0; order < CANONICAL_BOOK_IDS.length; order += 1) {
        const bookId = CANONICAL_BOOK_IDS[order]
        const bookLink = bookLinks[order]
        const testament = order < 39 ? "old" : "new"

        const loaded = loadChapterLinksForBook(oebpsDir, bookLink.href)
        const chapterLinks = loaded.chapterLinks
        ensureSequentialChapters(bookId, chapterLinks)

        const bookName = loaded.name || bookId
        const abbreviation = bookLink.abbreviation || bookName

        insertBook.run(bookId, order + 1, bookName, abbreviation, testament, chapterLinks.length)
        totalBooks += 1

        for (const chapterLink of chapterLinks) {
          const chapterPath = join(oebpsDir, chapterLink.href)
          const chapterContent = readFileSync(chapterPath, "utf8")
          const parsedVerses = parseVerses(chapterContent)

          const chapterInsert = insertChapter.run(bookId, chapterLink.chapterNumber, chapterLink.href, parsedVerses.length)
          const chapterId = Number(chapterInsert.lastInsertRowid)

          totalChapters += 1

          for (const verse of parsedVerses) {
            const verseInsert = insertVerse.run(chapterId, verse.verseNumber, verse.text)
            const verseId = Number(verseInsert.lastInsertRowid)
            totalVerses += 1

            for (let noteIndex = 0; noteIndex < verse.notes.length; noteIndex += 1) {
              const note = verse.notes[noteIndex]
              insertVerseNote.run(verseId, noteIndex + 1, note.noteId, note.noteText)
              totalNotes += 1
            }
          }
        }
      }

      db.exec("COMMIT")

      const result = {
        outputDbPath,
        totals: {
          books: totalBooks,
          chapters: totalChapters,
          verses: totalVerses,
          notes: totalNotes,
        },
      }

      console.log(JSON.stringify(result, null, 2))
    } catch (error) {
      db.exec("ROLLBACK")
      throw error
    }
  } finally {
    if (db) {
      db.close()
    }

    rmSync(tempDir, { recursive: true, force: true })
  }
}

try {
  main()
} catch (error) {
  const message = error instanceof Error ? error.message : String(error)
  console.error(`Import EPUB -> SQLite échoué: ${message}`)
  process.exitCode = 1
}
