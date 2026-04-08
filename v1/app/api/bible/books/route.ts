import { NextResponse } from "next/server"
import { getBibleBooks, getBibleDatabasePath, isBibleDatabaseReady } from "@/lib/bible-db"

export const runtime = "nodejs"

export async function GET() {
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
    const books = getBibleBooks()
    return NextResponse.json({ books })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error"
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
