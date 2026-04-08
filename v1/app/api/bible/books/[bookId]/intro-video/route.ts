import { NextResponse } from "next/server"
import {
  deleteBookIntroVideo,
  getBibleBook,
  getBibleDatabasePath,
  getBookIntroVideo,
  isBibleDatabaseReady,
  upsertBookIntroVideo,
} from "@/lib/bible-db"

export const runtime = "nodejs"

interface RouteContext {
  params: Promise<{
    bookId: string
  }>
}

function isValidJwUrl(value: string) {
  try {
    const parsed = new URL(value)
    const hostname = parsed.hostname.replace(/^www\./i, "").toLowerCase()

    if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
      return false
    }

    if (hostname !== "jw.org" && !hostname.endsWith(".jw.org")) {
      return false
    }

    return true
  } catch {
    return false
  }
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

  try {
    const { bookId } = await context.params
    const book = getBibleBook(bookId)

    if (!book) {
      return NextResponse.json({ error: "Book not found" }, { status: 404 })
    }

    const sourceUrl = getBookIntroVideo(bookId)
    return NextResponse.json({ bookId, sourceUrl })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error"
    return NextResponse.json({ error: message }, { status: 500 })
  }
}

export async function PUT(request: Request, context: RouteContext) {
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

  try {
    const { bookId } = await context.params
    const book = getBibleBook(bookId)

    if (!book) {
      return NextResponse.json({ error: "Book not found" }, { status: 404 })
    }

    const payload = (await request.json()) as { sourceUrl?: string }
    const sourceUrl = payload.sourceUrl?.trim() ?? ""

    if (!sourceUrl) {
      return NextResponse.json({ error: "sourceUrl is required" }, { status: 400 })
    }

    if (!isValidJwUrl(sourceUrl)) {
      return NextResponse.json({ error: "Only JW.ORG links are accepted" }, { status: 400 })
    }

    upsertBookIntroVideo(bookId, sourceUrl)
    return NextResponse.json({ bookId, sourceUrl })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error"
    return NextResponse.json({ error: message }, { status: 500 })
  }
}

export async function DELETE(_: Request, context: RouteContext) {
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

  try {
    const { bookId } = await context.params
    const book = getBibleBook(bookId)

    if (!book) {
      return NextResponse.json({ error: "Book not found" }, { status: 404 })
    }

    deleteBookIntroVideo(bookId)
    return NextResponse.json({ ok: true })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error"
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
