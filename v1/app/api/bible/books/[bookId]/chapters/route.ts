import { NextResponse } from "next/server"
import {
  getBibleBook,
  getBibleChapters,
  getBibleDatabasePath,
  isBibleDatabaseReady,
} from "@/lib/bible-db"

export const runtime = "nodejs"

interface RouteContext {
  params: Promise<{
    bookId: string
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

  try {
    const { bookId } = await context.params
    const book = getBibleBook(bookId)
    if (!book) {
      return NextResponse.json({ error: "Book not found" }, { status: 404 })
    }

    const chapters = getBibleChapters(bookId)
    return NextResponse.json({ book, chapters })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error"
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
