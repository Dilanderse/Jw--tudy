import { NextResponse } from "next/server"
import { deleteVerseStrongTag, getBibleDatabasePath, isBibleDatabaseReady, updateVerseStrongTag } from "@/lib/bible-db"

export const runtime = "nodejs"

interface RouteContext {
  params: Promise<{
    tagId: string
  }>
}

function isValidStrongNumber(value: string) {
  return /^[HG]\d+$/i.test(value)
}

export async function PATCH(request: Request, context: RouteContext) {
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

  const { tagId } = await context.params
  const parsedTagId = Number.parseInt(tagId, 10)

  if (!Number.isInteger(parsedTagId) || parsedTagId < 1) {
    return NextResponse.json({ error: "Invalid tag id" }, { status: 400 })
  }

  try {
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

    const updated = updateVerseStrongTag({
      tagId: parsedTagId,
      tokenText,
      strongNumber,
      lemma,
      tokenIndex,
    })

    if (!updated) {
      return NextResponse.json({ error: "Strong tag not found" }, { status: 404 })
    }

    return NextResponse.json({ tag: updated })
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

  const { tagId } = await context.params
  const parsedTagId = Number.parseInt(tagId, 10)

  if (!Number.isInteger(parsedTagId) || parsedTagId < 1) {
    return NextResponse.json({ error: "Invalid tag id" }, { status: 400 })
  }

  try {
    const removed = deleteVerseStrongTag(parsedTagId)
    if (!removed) {
      return NextResponse.json({ error: "Strong tag not found" }, { status: 404 })
    }

    return NextResponse.json({ ok: true })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error"
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
