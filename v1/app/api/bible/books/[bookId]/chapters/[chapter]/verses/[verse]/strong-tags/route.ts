import { NextResponse } from "next/server"
import { addVerseStrongTag, getBibleBook, getBibleDatabasePath, isBibleDatabaseReady } from "@/lib/bible-db"

export const runtime = "nodejs"

interface RouteContext {
  params: Promise<{
    bookId: string
    chapter: string
    verse: string
  }>
}

function isValidStrongNumber(value: string) {
  return /^[HG]\d+$/i.test(value)
}

export async function POST(request: Request, context: RouteContext) {
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

  const { bookId, chapter, verse } = await context.params
  const chapterNumber = Number.parseInt(chapter, 10)
  const verseNumber = Number.parseInt(verse, 10)

  if (!Number.isInteger(chapterNumber) || chapterNumber < 1) {
    return NextResponse.json({ error: "Invalid chapter number" }, { status: 400 })
  }

  if (!Number.isInteger(verseNumber) || verseNumber < 1) {
    return NextResponse.json({ error: "Invalid verse number" }, { status: 400 })
  }

  try {
    const book = getBibleBook(bookId)
    if (!book) {
      return NextResponse.json({ error: "Book not found" }, { status: 404 })
    }

    const payload = (await request.json()) as {
      tokenText?: string
      strongNumber?: string
      lemma?: string
      tokenIndex?: number
    }

    const tokenText = payload.tokenText?.trim() ?? ""
    const strongNumber = payload.strongNumber?.trim().toUpperCase() ?? ""
    const lemma = payload.lemma?.trim() || null
    const tokenIndex = Number.isInteger(payload.tokenIndex) && Number(payload.tokenIndex) > 0 ? Number(payload.tokenIndex) : null

    if (!tokenText) {
      return NextResponse.json({ error: "tokenText is required" }, { status: 400 })
    }

    if (!strongNumber) {
      return NextResponse.json({ error: "strongNumber is required" }, { status: 400 })
    }

    if (!isValidStrongNumber(strongNumber)) {
      return NextResponse.json({ error: "strongNumber must match H#### or G####" }, { status: 400 })
    }

    const inserted = addVerseStrongTag({
      bookId,
      chapterNumber,
      verseNumber,
      tokenText,
      strongNumber,
      lemma,
      tokenIndex,
    })

    if (!inserted) {
      return NextResponse.json({ error: "Verse not found" }, { status: 404 })
    }

    return NextResponse.json({ tag: inserted }, { status: 201 })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error"
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
