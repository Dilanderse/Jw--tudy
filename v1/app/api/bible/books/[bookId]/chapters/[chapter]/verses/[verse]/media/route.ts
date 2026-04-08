import { NextResponse } from "next/server"
import { addVerseMedia, getBibleBook, getBibleDatabasePath, isBibleDatabaseReady } from "@/lib/bible-db"

export const runtime = "nodejs"

interface RouteContext {
  params: Promise<{
    bookId: string
    chapter: string
    verse: string
  }>
}

function detectProvider(sourceUrl: string) {
  try {
    const parsed = new URL(sourceUrl)
    const hostname = parsed.hostname.replace(/^www\./i, "").toLowerCase()

    if (hostname === "jw.org" || hostname.endsWith(".jw.org")) {
      return "jw"
    }

    if (hostname === "youtube.com" || hostname === "youtu.be" || hostname.endsWith(".youtube.com")) {
      return "youtube"
    }

    return "web"
  } catch {
    return null
  }
}

function isValidWebUrl(value: string) {
  try {
    const parsed = new URL(value)
    return parsed.protocol === "https:" || parsed.protocol === "http:"
  } catch {
    return false
  }
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
      sourceUrl?: string
      title?: string
      mediaType?: string
      startSeconds?: number
      endSeconds?: number
    }

    const sourceUrl = payload.sourceUrl?.trim() ?? ""
    const title = payload.title?.trim() || null
    const mediaType = payload.mediaType?.trim() || "video"

    if (!sourceUrl) {
      return NextResponse.json({ error: "sourceUrl is required" }, { status: 400 })
    }

    if (!isValidWebUrl(sourceUrl)) {
      return NextResponse.json({ error: "sourceUrl must be a valid http(s) URL" }, { status: 400 })
    }

    const provider = detectProvider(sourceUrl)
    const startSeconds = Number.isFinite(payload.startSeconds) ? Number(payload.startSeconds) : null
    const endSeconds = Number.isFinite(payload.endSeconds) ? Number(payload.endSeconds) : null

    const inserted = addVerseMedia({
      bookId,
      chapterNumber,
      verseNumber,
      mediaType,
      provider,
      sourceUrl,
      title,
      startSeconds,
      endSeconds,
    })

    if (!inserted) {
      return NextResponse.json({ error: "Verse not found" }, { status: 404 })
    }

    return NextResponse.json({ media: inserted }, { status: 201 })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error"
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
