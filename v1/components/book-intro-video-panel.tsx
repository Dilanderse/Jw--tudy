"use client"

import { useEffect, useMemo, useState, type FormEvent } from "react"
import { ExternalLink, Link2, Pencil, PlayCircle, Trash2 } from "lucide-react"

interface BookIntroVideoPanelProps {
  bookName: string
  videoUrl: string
  isSaving?: boolean
  saveError?: string | null
  onVideoUrlChange: (videoUrl: string) => void
}

type ParsedVideo =
  | {
      provider: "jw"
      mode: "external"
      sourceUrl: string
    }
  | {
      provider: "jw"
      mode: "native-video"
      sourceUrl: string
      videoUrl: string
    }

function parseJwVideo(rawUrl: string): ParsedVideo | null {
  const trimmed = rawUrl.trim()
  if (!trimmed) {
    return null
  }

  try {
    const parsed = new URL(trimmed)
    const host = parsed.hostname.replace(/^www\./, "").toLowerCase()

    if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
      return null
    }

    if (host !== "jw.org" && !host.endsWith(".jw.org")) {
      return null
    }

    // Accept common JW video/document links and the shared finder format.
    const isFinderLink = parsed.pathname === "/finder" && !!parsed.searchParams.get("docid")
    const isMediaLikePath =
      parsed.pathname.includes("/library/") ||
      parsed.pathname.includes("/multimedia/") ||
      parsed.pathname.includes("/video")

    if (!isFinderLink && !isMediaLikePath) {
      return null
    }

    const sourceUrl = parsed.toString()
    const lowerPath = parsed.pathname.toLowerCase()
    const isDirectVideoFile =
      lowerPath.endsWith(".mp4") ||
      lowerPath.endsWith(".m4v") ||
      lowerPath.endsWith(".webm") ||
      lowerPath.endsWith(".ogg")

    if (isDirectVideoFile) {
      return {
        provider: "jw",
        mode: "native-video",
        sourceUrl,
        videoUrl: sourceUrl,
      }
    }

    // Most JW pages block iframe embedding (X-Frame-Options / CSP),
    // so default to external opening for reliable playback.
    return {
      provider: "jw",
      mode: "external",
      sourceUrl,
    }
  } catch {
    return null
  }
}

function parseVideoUrl(rawUrl: string): ParsedVideo | null {
  return parseJwVideo(rawUrl)
}

export function BookIntroVideoPanel({
  bookName,
  videoUrl,
  isSaving = false,
  saveError = null,
  onVideoUrlChange,
}: BookIntroVideoPanelProps) {
  const [isEditing, setIsEditing] = useState(false)
  const [draftUrl, setDraftUrl] = useState(videoUrl)
  const [error, setError] = useState<string | null>(null)

  const parsedVideo = useMemo(() => parseVideoUrl(videoUrl), [videoUrl])

  useEffect(() => {
    setDraftUrl(videoUrl)
    setError(null)
  }, [videoUrl])

  const startEditing = () => {
    setDraftUrl(videoUrl)
    setError(null)
    setIsEditing(true)
  }

  const cancelEditing = () => {
    setDraftUrl(videoUrl)
    setError(null)
    setIsEditing(false)
  }

  const clearVideo = () => {
    onVideoUrlChange("")
    setDraftUrl("")
    setError(null)
    setIsEditing(false)
  }

  const saveVideo = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (isSaving) {
      return
    }

    const trimmed = draftUrl.trim()
    if (!trimmed) {
      setError("Colle un lien JW.ORG valide pour enregistrer la vidéo.")
      return
    }

    const parsedDraft = parseVideoUrl(trimmed)
    if (!parsedDraft) {
      setError("Lien non reconnu. Utilise uniquement un lien JW.ORG (finder/docid).")
      return
    }

    onVideoUrlChange(trimmed)
    setError(null)
    setIsEditing(false)
  }

  return (
    <aside className="lg:sticky lg:top-24">
      <div className="overflow-hidden rounded-2xl border border-border bg-card shadow-sm">
        <div className="border-b border-border px-4 py-3">
          <p className="text-xs uppercase tracking-[0.18em] text-muted-foreground">Vidéo d'introduction</p>
          <h3 className="mt-1 text-base font-semibold text-foreground">{bookName}</h3>
        </div>

        <div className="space-y-4 p-4">
          {parsedVideo ? (
            <div className="overflow-hidden rounded-xl border border-border bg-black">
              <div className="aspect-video">
                {parsedVideo.mode === "native-video" && (
                  <video
                    controls
                    preload="metadata"
                    className="h-full w-full bg-black object-contain"
                    src={parsedVideo.videoUrl}
                  />
                )}
                {parsedVideo.mode === "external" && (
                  <a
                    href={parsedVideo.sourceUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex h-full w-full flex-col items-center justify-center gap-2 px-4 text-center text-foreground"
                  >
                    <ExternalLink className="h-8 w-8 text-primary" />
                    <p className="text-sm font-semibold">Lecture externe requise</p>
                    <p className="text-xs text-muted-foreground">
                      JW.ORG bloque la lecture intégrée dans la page. Clique pour ouvrir la vidéo.
                    </p>
                  </a>
                )}
              </div>
            </div>
          ) : (
            <button type="button" onClick={startEditing} className="group block w-full text-left">
              <div className="relative overflow-hidden rounded-xl border-2 border-dashed border-border bg-gradient-to-br from-secondary/70 via-card to-secondary/30 p-4 transition-colors group-hover:border-primary/60">
                <div className="absolute inset-0 bg-gradient-to-br from-primary/10 via-transparent to-transparent" />
                <div className="relative">
                  <div className="aspect-video rounded-lg border border-border/60 bg-black/80">
                    <div className="flex h-full items-center justify-center">
                      <PlayCircle className="h-12 w-12 text-primary/80" />
                    </div>
                  </div>

                  <p className="mt-3 text-sm font-semibold text-foreground">Aucune vidéo d'introduction ajoutée</p>
                  <p className="mt-1 text-xs text-muted-foreground">
                    Clique ici pour coller un lien et activer la vidéo d'introduction du livre.
                  </p>
                </div>
              </div>
            </button>
          )}

          {isEditing && (
            <form onSubmit={saveVideo} className="space-y-3 rounded-xl border border-border bg-background/60 p-3">
              <label htmlFor="book-intro-video-link" className="block text-sm font-medium text-foreground">
                Lien vidéo
              </label>
              <div className="flex items-center gap-2 rounded-lg border border-input bg-background px-3">
                <Link2 className="h-4 w-4 text-muted-foreground" />
                <input
                  id="book-intro-video-link"
                  type="url"
                  value={draftUrl}
                  onChange={(event) => setDraftUrl(event.target.value)}
                  placeholder="https://www.jw.org/finder?wtlocale=F&docid=..."
                  className="h-10 w-full bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground"
                  autoFocus
                  disabled={isSaving}
                />
              </div>

              {error && <p className="text-xs text-destructive">{error}</p>}

              <div className="flex items-center gap-2">
                <button
                  type="submit"
                  disabled={isSaving}
                  className="rounded-lg bg-primary px-3 py-2 text-sm font-medium text-primary-foreground hover:opacity-90"
                >
                  {isSaving ? "Enregistrement..." : "Enregistrer"}
                </button>
                <button
                  type="button"
                  onClick={cancelEditing}
                  disabled={isSaving}
                  className="rounded-lg border border-border px-3 py-2 text-sm font-medium text-foreground hover:bg-secondary"
                >
                  Annuler
                </button>
              </div>
            </form>
          )}

          {!isEditing && parsedVideo && (
            <div className="flex flex-wrap items-center gap-2">
              <button
                type="button"
                onClick={startEditing}
                disabled={isSaving}
                className="inline-flex items-center gap-2 rounded-lg border border-border px-3 py-2 text-sm text-foreground hover:bg-secondary"
              >
                <Pencil className="h-4 w-4" />
                Modifier le lien
              </button>
              <button
                type="button"
                onClick={clearVideo}
                disabled={isSaving}
                className="inline-flex items-center gap-2 rounded-lg border border-destructive/40 px-3 py-2 text-sm text-destructive hover:bg-destructive/10"
              >
                <Trash2 className="h-4 w-4" />
                Retirer
              </button>
              <a
                href={parsedVideo.sourceUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 rounded-lg border border-primary/40 px-3 py-2 text-sm text-primary hover:bg-primary/10"
              >
                <ExternalLink className="h-4 w-4" />
                Ouvrir la source
              </a>
            </div>
          )}

          {!isEditing && !parsedVideo && (
            <button
              type="button"
              onClick={startEditing}
              disabled={isSaving}
              className="w-full rounded-lg border border-primary/40 bg-primary/10 px-3 py-2 text-sm font-medium text-primary hover:bg-primary/15"
            >
              Ajouter une vidéo d'introduction
            </button>
          )}

          {saveError && <p className="text-xs text-destructive">{saveError}</p>}

          <p className="text-[11px] text-muted-foreground">
            Format pris en charge: JW.ORG (`/finder?...docid=...`).
            Les liens JW.ORG s'ouvrent souvent en lecture externe pour des raisons de sécurité du site.
          </p>
        </div>
      </div>
    </aside>
  )
}
