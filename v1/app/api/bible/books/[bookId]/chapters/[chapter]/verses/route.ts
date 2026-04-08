import { NextResponse } from "next/server"
import {
  getBibleBook,
  getBibleChapters,
  getBibleDatabasePath,
  getBibleVerses,
  isBibleDatabaseReady,
} from "@/lib/bible-db"

export const runtime = "nodejs"

interface RouteContext {
  params: Promise<{
    bookId: string
    chapter: string
  }>
}

export async function GET(_: Request, context: RouteContext) {
  if (!isBibleDatabaseReady()) {
    return NextResponse.json(
      {
        error: "Bible database not found",
        dbPath: getBibleDatabasePath(),
        hint: "Run: npm run import:bible",
      },
      { status: 503 },
    )
  }

  const { bookId, chapter } = await context.params
  const chapterNumber = Number.parseInt(chapter, 10)
  if (!Number.isInteger(chapterNumber) || chapterNumber < 1) {
    return NextResponse.json({ error: "Invalid chapter number" }, { status: 400 })
  }

  try {
    const book = getBibleBook(bookId)
    if (!book) {
      return NextResponse.json({ error: "Book not found" }, { status: 404 })
    }

    const chapters = getBibleChapters(bookId)
    const chapterExists = chapters.some((chapter) => chapter.number === chapterNumber)
    if (!chapterExists) {
      return NextResponse.json({ error: "Chapter not found" }, { status: 404 })
    }

    const verses = getBibleVerses(bookId, chapterNumber)
    return NextResponse.json({
      book,
      chapter: chapterNumber,
      verses,
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error"
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
