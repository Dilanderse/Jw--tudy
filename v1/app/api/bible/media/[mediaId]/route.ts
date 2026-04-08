import { NextResponse } from "next/server"
import { deleteVerseMedia, getBibleDatabasePath, isBibleDatabaseReady, updateVerseMedia } from "@/lib/bible-db"

export const runtime = "nodejs"

interface RouteContext {
  params: Promise<{
    mediaId: string
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

  const { mediaId } = await context.params
  const parsedMediaId = Number.parseInt(mediaId, 10)

  if (!Number.isInteger(parsedMediaId) || parsedMediaId < 1) {
    return NextResponse.json({ error: "Invalid media id" }, { status: 400 })
  }

  try {
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

    const updated = updateVerseMedia({
      mediaId: parsedMediaId,
      mediaType,
      provider,
      sourceUrl,
      title,
      startSeconds,
      endSeconds,
    })

    if (!updated) {
      return NextResponse.json({ error: "Media not found" }, { status: 404 })
    }

    return NextResponse.json({ media: updated })
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

  const { mediaId } = await context.params
  const parsedMediaId = Number.parseInt(mediaId, 10)

  if (!Number.isInteger(parsedMediaId) || parsedMediaId < 1) {
    return NextResponse.json({ error: "Invalid media id" }, { status: 400 })
  }

  try {
    const removed = deleteVerseMedia(parsedMediaId)
    if (!removed) {
      return NextResponse.json({ error: "Media not found" }, { status: 404 })
    }

    return NextResponse.json({ ok: true })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error"
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
