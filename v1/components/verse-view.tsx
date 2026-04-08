"use client"

import { useEffect, useState } from "react"
import { ExternalLink, Link2, Pencil, Plus, Trash2 } from "lucide-react"
import { StrongPopup } from "@/components/strong-popup"
import { getStrongEntry } from "@/data/strong-concordance"
import { HighlightedVerse } from "@/components/highlighted-verse"

interface VerseViewProps {
  bookId: string
  chapter: number
}

interface VerseNote {
  id: string
  text: string
}

interface VerseMedia {
  id: number
  mediaType: string
  provider: string | null
  sourceUrl: string
  title: string | null
  startSeconds: number | null
  endSeconds: number | null
  createdAt: string
}

interface VerseStrongTag {
  id: number
  tokenIndex: number
  tokenText: string
  strongNumber: string
  lemma: string | null
}

interface VerseItem {
  number: number
  text: string
  notes: VerseNote[]
  media: VerseMedia[]
  strongTags: VerseStrongTag[]
}

interface VersesApiResponse {
  verses: VerseItem[]
}

function providerLabel(provider: string | null) {
  switch (provider) {
    case "jw":
      return "JW.ORG"
    case "youtube":
      return "YouTube"
    case "web":
      return "Web"
    default:
      return "Lien"
  }
}

function normalizeStrongNumber(value: string) {
  return value.trim().toUpperCase()
}

function isValidStrongNumber(value: string) {
  return /^[HG]\d+$/i.test(value)
}

export function VerseView({ bookId, chapter }: VerseViewProps) {
  const [selectedStrong, setSelectedStrong] = useState<string | null>(null)
  const [verses, setVerses] = useState<VerseItem[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [reloadToken, setReloadToken] = useState(0)

  const [mediaSaving, setMediaSaving] = useState(false)
  const [mediaError, setMediaError] = useState<string | null>(null)
  const [addingMediaVerse, setAddingMediaVerse] = useState<number | null>(null)
  const [mediaUrlDraft, setMediaUrlDraft] = useState("")
  const [mediaTitleDraft, setMediaTitleDraft] = useState("")
  const [editingMediaId, setEditingMediaId] = useState<number | null>(null)
  const [editingMediaUrlDraft, setEditingMediaUrlDraft] = useState("")
  const [editingMediaTitleDraft, setEditingMediaTitleDraft] = useState("")

  const [strongSaving, setStrongSaving] = useState(false)
  const [strongError, setStrongError] = useState<string | null>(null)
  const [addingStrongVerse, setAddingStrongVerse] = useState<number | null>(null)
  const [strongTokenDraft, setStrongTokenDraft] = useState("")
  const [strongNumberDraft, setStrongNumberDraft] = useState("")
  const [strongLemmaDraft, setStrongLemmaDraft] = useState("")
  const [editingStrongTagId, setEditingStrongTagId] = useState<number | null>(null)
  const [editingStrongTokenDraft, setEditingStrongTokenDraft] = useState("")
  const [editingStrongNumberDraft, setEditingStrongNumberDraft] = useState("")
  const [editingStrongLemmaDraft, setEditingStrongLemmaDraft] = useState("")

  const handleWordClick = (strongNumber: string) => {
    setSelectedStrong(strongNumber)
  }

  useEffect(() => {
    setAddingMediaVerse(null)
    setMediaUrlDraft("")
    setMediaTitleDraft("")
    setEditingMediaId(null)
    setEditingMediaUrlDraft("")
    setEditingMediaTitleDraft("")
    setMediaError(null)

    setAddingStrongVerse(null)
    setStrongTokenDraft("")
    setStrongNumberDraft("")
    setStrongLemmaDraft("")
    setEditingStrongTagId(null)
    setEditingStrongTokenDraft("")
    setEditingStrongNumberDraft("")
    setEditingStrongLemmaDraft("")
    setStrongError(null)
  }, [bookId, chapter])

  useEffect(() => {
    const abortController = new AbortController()

    const loadVerses = async () => {
      setIsLoading(true)
      setError(null)
      setSelectedStrong(null)

      try {
        const response = await fetch(`/api/bible/books/${bookId}/chapters/${chapter}/verses`, {
          signal: abortController.signal,
        })

        const payload = (await response.json()) as VersesApiResponse & { error?: string }
        if (!response.ok) {
          throw new Error(payload.error || "Impossible de charger les versets.")
        }

        setVerses(payload.verses ?? [])
      } catch (caught) {
        if (abortController.signal.aborted) {
          return
        }

        const message = caught instanceof Error ? caught.message : "Erreur inconnue"
        setError(message)
        setVerses([])
      } finally {
        if (!abortController.signal.aborted) {
          setIsLoading(false)
        }
      }
    }

    void loadVerses()
    return () => abortController.abort()
  }, [bookId, chapter, reloadToken])

  const selectedEntry = selectedStrong ? getStrongEntry(selectedStrong) : null

  const resetMediaAdd = () => {
    setAddingMediaVerse(null)
    setMediaUrlDraft("")
    setMediaTitleDraft("")
    setMediaError(null)
  }

  const resetMediaEdit = () => {
    setEditingMediaId(null)
    setEditingMediaUrlDraft("")
    setEditingMediaTitleDraft("")
    setMediaError(null)
  }

  const openMediaAdd = (verseNumber: number) => {
    setAddingMediaVerse(verseNumber)
    setMediaUrlDraft("")
    setMediaTitleDraft("")
    setMediaError(null)
    setEditingMediaId(null)
  }

  const openMediaEdit = (media: VerseMedia) => {
    setEditingMediaId(media.id)
    setEditingMediaUrlDraft(media.sourceUrl)
    setEditingMediaTitleDraft(media.title ?? "")
    setMediaError(null)
    setAddingMediaVerse(null)
  }

  const submitAddMedia = async (verseNumber: number) => {
    const sourceUrl = mediaUrlDraft.trim()

    if (!sourceUrl) {
      setMediaError("Colle un lien pour ce média.")
      return
    }

    try {
      const parsed = new URL(sourceUrl)
      if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
        setMediaError("Le lien doit commencer par http:// ou https://")
        return
      }
    } catch {
      setMediaError("Lien invalide.")
      return
    }

    setMediaSaving(true)
    setMediaError(null)

    try {
      const response = await fetch(`/api/bible/books/${bookId}/chapters/${chapter}/verses/${verseNumber}/media`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          sourceUrl,
          title: mediaTitleDraft.trim() || undefined,
          mediaType: "video",
        }),
      })

      const payload = (await response.json()) as { error?: string }
      if (!response.ok) {
        throw new Error(payload.error || "Impossible d'ajouter le média.")
      }

      resetMediaAdd()
      setReloadToken((previous) => previous + 1)
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : "Erreur inconnue"
      setMediaError(message)
    } finally {
      setMediaSaving(false)
    }
  }

  const submitEditMedia = async (mediaId: number) => {
    const sourceUrl = editingMediaUrlDraft.trim()

    if (!sourceUrl) {
      setMediaError("Le lien du média est requis.")
      return
    }

    try {
      const parsed = new URL(sourceUrl)
      if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
        setMediaError("Le lien doit commencer par http:// ou https://")
        return
      }
    } catch {
      setMediaError("Lien invalide.")
      return
    }

    setMediaSaving(true)
    setMediaError(null)

    try {
      const response = await fetch(`/api/bible/media/${mediaId}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          sourceUrl,
          title: editingMediaTitleDraft.trim() || undefined,
          mediaType: "video",
        }),
      })

      const payload = (await response.json()) as { error?: string }
      if (!response.ok) {
        throw new Error(payload.error || "Impossible de modifier le média.")
      }

      resetMediaEdit()
      setReloadToken((previous) => previous + 1)
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : "Erreur inconnue"
      setMediaError(message)
    } finally {
      setMediaSaving(false)
    }
  }

  const removeVerseMedia = async (mediaId: number) => {
    setMediaSaving(true)
    setMediaError(null)

    try {
      const response = await fetch(`/api/bible/media/${mediaId}`, {
        method: "DELETE",
      })

      const payload = (await response.json()) as { error?: string }
      if (!response.ok) {
        throw new Error(payload.error || "Impossible de supprimer le média.")
      }

      if (editingMediaId === mediaId) {
        resetMediaEdit()
      }

      setReloadToken((previous) => previous + 1)
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : "Erreur inconnue"
      setMediaError(message)
    } finally {
      setMediaSaving(false)
    }
  }

  const resetStrongAdd = () => {
    setAddingStrongVerse(null)
    setStrongTokenDraft("")
    setStrongNumberDraft("")
    setStrongLemmaDraft("")
    setStrongError(null)
  }

  const resetStrongEdit = () => {
    setEditingStrongTagId(null)
    setEditingStrongTokenDraft("")
    setEditingStrongNumberDraft("")
    setEditingStrongLemmaDraft("")
    setStrongError(null)
  }

  const openStrongAdd = (verseNumber: number) => {
    setAddingStrongVerse(verseNumber)
    setStrongTokenDraft("")
    setStrongNumberDraft("")
    setStrongLemmaDraft("")
    setStrongError(null)
    setEditingStrongTagId(null)
  }

  const openStrongEdit = (tag: VerseStrongTag) => {
    setEditingStrongTagId(tag.id)
    setEditingStrongTokenDraft(tag.tokenText)
    setEditingStrongNumberDraft(tag.strongNumber)
    setEditingStrongLemmaDraft(tag.lemma ?? "")
    setStrongError(null)
    setAddingStrongVerse(null)
  }

  const submitAddStrongTag = async (verseNumber: number) => {
    const tokenText = strongTokenDraft.trim()
    const strongNumber = normalizeStrongNumber(strongNumberDraft)
    const lemma = strongLemmaDraft.trim() || undefined

    if (!tokenText) {
      setStrongError("Le mot (token) est requis.")
      return
    }

    if (!strongNumber) {
      setStrongError("Le numéro Strong est requis.")
      return
    }

    if (!isValidStrongNumber(strongNumber)) {
      setStrongError("Format attendu: H#### ou G####")
      return
    }

    setStrongSaving(true)
    setStrongError(null)

    try {
      const response = await fetch(`/api/bible/books/${bookId}/chapters/${chapter}/verses/${verseNumber}/strong-tags`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          tokenText,
          strongNumber,
          lemma,
        }),
      })

      const payload = (await response.json()) as { error?: string }
      if (!response.ok) {
        throw new Error(payload.error || "Impossible d'ajouter le tag Strong.")
      }

      resetStrongAdd()
      setReloadToken((previous) => previous + 1)
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : "Erreur inconnue"
      setStrongError(message)
    } finally {
      setStrongSaving(false)
    }
  }

  const submitEditStrongTag = async (tagId: number) => {
    const tokenText = editingStrongTokenDraft.trim()
    const strongNumber = normalizeStrongNumber(editingStrongNumberDraft)
    const lemma = editingStrongLemmaDraft.trim() || undefined

    if (!tokenText) {
      setStrongError("Le mot (token) est requis.")
      return
    }

    if (!strongNumber) {
      setStrongError("Le numéro Strong est requis.")
      return
    }

    if (!isValidStrongNumber(strongNumber)) {
      setStrongError("Format attendu: H#### ou G####")
      return
    }

    setStrongSaving(true)
    setStrongError(null)

    try {
      const response = await fetch(`/api/bible/strong-tags/${tagId}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          tokenText,
          strongNumber,
          lemma,
        }),
      })

      const payload = (await response.json()) as { error?: string }
      if (!response.ok) {
        throw new Error(payload.error || "Impossible de modifier le tag Strong.")
      }

      resetStrongEdit()
      setReloadToken((previous) => previous + 1)
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : "Erreur inconnue"
      setStrongError(message)
    } finally {
      setStrongSaving(false)
    }
  }

  const removeStrongTag = async (tagId: number) => {
    setStrongSaving(true)
    setStrongError(null)

    try {
      const response = await fetch(`/api/bible/strong-tags/${tagId}`, {
        method: "DELETE",
      })

      const payload = (await response.json()) as { error?: string }
      if (!response.ok) {
        throw new Error(payload.error || "Impossible de supprimer le tag Strong.")
      }

      if (editingStrongTagId === tagId) {
        resetStrongEdit()
      }

      setReloadToken((previous) => previous + 1)
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : "Erreur inconnue"
      setStrongError(message)
    } finally {
      setStrongSaving(false)
    }
  }

  if (isLoading) {
    return (
      <div className="space-y-3">
        {Array.from({ length: 6 }).map((_, index) => (
          <div key={index} className="h-16 animate-pulse rounded-lg border border-border bg-card/60" />
        ))}
      </div>
    )
  }

  if (error) {
    return (
      <div className="rounded-xl border border-destructive/40 bg-destructive/10 p-4 text-sm text-destructive">
        <p className="font-medium">Chargement impossible</p>
        <p className="mt-1">{error}</p>
        <p className="mt-2 text-xs">Vérifie que la base existe puis lance: `npm run import:bible`</p>
      </div>
    )
  }

  if (verses.length === 0) {
    return (
      <div className="rounded-xl border border-border bg-card p-4 text-sm text-muted-foreground">
        Aucun verset trouvé pour ce chapitre.
      </div>
    )
  }

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      {verses.map((verse) => {
        const highlightedWords = verse.strongTags.map((tag) => ({
          word: tag.tokenText,
          strongNumber: tag.strongNumber,
        }))

        return (
          <div key={`${verse.number}`} className="border-l-2 border-primary/30 pl-6 py-4">
            <div className="flex gap-4 mb-3">
              <span className="font-semibold text-primary text-sm min-w-12">{verse.number}</span>
              <div className="text-foreground leading-relaxed">
                <HighlightedVerse text={verse.text} strongNumbers={highlightedWords} onWordClick={handleWordClick} />
              </div>
            </div>

            {verse.notes.length > 0 && (
              <div className="mt-2 space-y-1 pl-16 text-xs text-muted-foreground">
                {verse.notes.map((note, index) => (
                  <p key={`${note.id}-${index}`}>
                    <span className="mr-1 font-semibold text-primary">*</span>
                    {note.text}
                  </p>
                ))}
              </div>
            )}

            <div className="mt-4 rounded-lg border border-border/70 bg-card/40 p-3 pl-16">
              <div className="flex items-center justify-between gap-2">
                <p className="text-[11px] uppercase tracking-[0.14em] text-muted-foreground">Médias sur ce verset</p>
                {addingMediaVerse !== verse.number && (
                  <button
                    type="button"
                    onClick={() => openMediaAdd(verse.number)}
                    className="inline-flex items-center gap-1 rounded-md border border-border px-2 py-1 text-xs text-foreground hover:bg-secondary"
                  >
                    <Plus className="h-3.5 w-3.5" />
                    Ajouter
                  </button>
                )}
              </div>

              {verse.media.length > 0 ? (
                <div className="mt-2 space-y-2">
                  {verse.media.map((media) => (
                    <div key={media.id} className="rounded-md border border-border/70 bg-background/60 p-2">
                      {editingMediaId === media.id ? (
                        <div className="space-y-2">
                          <div className="flex items-center gap-2 rounded-md border border-input bg-background px-2">
                            <Link2 className="h-3.5 w-3.5 text-muted-foreground" />
                            <input
                              type="url"
                              value={editingMediaUrlDraft}
                              onChange={(event) => setEditingMediaUrlDraft(event.target.value)}
                              placeholder="https://..."
                              className="h-8 w-full bg-transparent text-xs text-foreground outline-none placeholder:text-muted-foreground"
                              disabled={mediaSaving}
                            />
                          </div>
                          <input
                            type="text"
                            value={editingMediaTitleDraft}
                            onChange={(event) => setEditingMediaTitleDraft(event.target.value)}
                            placeholder="Titre (facultatif)"
                            className="h-8 w-full rounded-md border border-input bg-background px-2 text-xs text-foreground outline-none placeholder:text-muted-foreground"
                            disabled={mediaSaving}
                          />

                          {mediaError && <p className="text-xs text-destructive">{mediaError}</p>}

                          <div className="flex items-center gap-2">
                            <button
                              type="button"
                              onClick={() => {
                                void submitEditMedia(media.id)
                              }}
                              disabled={mediaSaving}
                              className="rounded-md bg-primary px-2.5 py-1.5 text-xs font-medium text-primary-foreground hover:opacity-90 disabled:opacity-60"
                            >
                              {mediaSaving ? "Maj..." : "Enregistrer"}
                            </button>
                            <button
                              type="button"
                              onClick={resetMediaEdit}
                              disabled={mediaSaving}
                              className="rounded-md border border-border px-2.5 py-1.5 text-xs text-foreground hover:bg-secondary disabled:opacity-60"
                            >
                              Annuler
                            </button>
                          </div>
                        </div>
                      ) : (
                        <div className="flex items-start justify-between gap-2">
                          <a
                            href={media.sourceUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="min-w-0 flex-1"
                          >
                            <p className="truncate text-xs font-medium text-foreground hover:text-primary">
                              {media.title || media.sourceUrl}
                            </p>
                            <p className="mt-1 text-[11px] text-muted-foreground">
                              {providerLabel(media.provider)} • {media.mediaType}
                            </p>
                          </a>

                          <div className="flex items-center gap-1">
                            <a
                              href={media.sourceUrl}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="inline-flex h-7 w-7 items-center justify-center rounded-md border border-border text-muted-foreground hover:text-primary"
                              aria-label="Ouvrir le média"
                            >
                              <ExternalLink className="h-3.5 w-3.5" />
                            </a>
                            <button
                              type="button"
                              onClick={() => openMediaEdit(media)}
                              disabled={mediaSaving}
                              className="inline-flex h-7 w-7 items-center justify-center rounded-md border border-border text-muted-foreground hover:text-primary disabled:opacity-50"
                              aria-label="Modifier le média"
                            >
                              <Pencil className="h-3.5 w-3.5" />
                            </button>
                            <button
                              type="button"
                              onClick={() => {
                                void removeVerseMedia(media.id)
                              }}
                              disabled={mediaSaving}
                              className="inline-flex h-7 w-7 items-center justify-center rounded-md border border-destructive/40 text-destructive hover:bg-destructive/10 disabled:opacity-50"
                              aria-label="Supprimer le média"
                            >
                              <Trash2 className="h-3.5 w-3.5" />
                            </button>
                          </div>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              ) : (
                <p className="mt-2 text-xs text-muted-foreground">Aucun média ajouté pour ce verset.</p>
              )}

              {addingMediaVerse === verse.number && (
                <div className="mt-3 space-y-2 rounded-md border border-border bg-background/70 p-2">
                  <div className="flex items-center gap-2 rounded-md border border-input bg-background px-2">
                    <Link2 className="h-3.5 w-3.5 text-muted-foreground" />
                    <input
                      type="url"
                      value={mediaUrlDraft}
                      onChange={(event) => setMediaUrlDraft(event.target.value)}
                      placeholder="https://..."
                      className="h-8 w-full bg-transparent text-xs text-foreground outline-none placeholder:text-muted-foreground"
                      disabled={mediaSaving}
                    />
                  </div>

                  <input
                    type="text"
                    value={mediaTitleDraft}
                    onChange={(event) => setMediaTitleDraft(event.target.value)}
                    placeholder="Titre (facultatif)"
                    className="h-8 w-full rounded-md border border-input bg-background px-2 text-xs text-foreground outline-none placeholder:text-muted-foreground"
                    disabled={mediaSaving}
                  />

                  {mediaError && <p className="text-xs text-destructive">{mediaError}</p>}

                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => {
                        void submitAddMedia(verse.number)
                      }}
                      disabled={mediaSaving}
                      className="rounded-md bg-primary px-2.5 py-1.5 text-xs font-medium text-primary-foreground hover:opacity-90 disabled:opacity-60"
                    >
                      {mediaSaving ? "Ajout..." : "Enregistrer"}
                    </button>
                    <button
                      type="button"
                      onClick={resetMediaAdd}
                      disabled={mediaSaving}
                      className="rounded-md border border-border px-2.5 py-1.5 text-xs text-foreground hover:bg-secondary disabled:opacity-60"
                    >
                      Annuler
                    </button>
                  </div>
                </div>
              )}
            </div>

            <div className="mt-4 rounded-lg border border-border/70 bg-card/40 p-3 pl-16">
              <div className="flex items-center justify-between gap-2">
                <p className="text-[11px] uppercase tracking-[0.14em] text-muted-foreground">Tags Strong</p>
                {addingStrongVerse !== verse.number && (
                  <button
                    type="button"
                    onClick={() => openStrongAdd(verse.number)}
                    className="inline-flex items-center gap-1 rounded-md border border-border px-2 py-1 text-xs text-foreground hover:bg-secondary"
                  >
                    <Plus className="h-3.5 w-3.5" />
                    Ajouter
                  </button>
                )}
              </div>

              {verse.strongTags.length > 0 ? (
                <div className="mt-2 space-y-2">
                  {verse.strongTags.map((tag) => (
                    <div key={tag.id} className="rounded-md border border-border/70 bg-background/60 p-2">
                      {editingStrongTagId === tag.id ? (
                        <div className="space-y-2">
                          <input
                            type="text"
                            value={editingStrongTokenDraft}
                            onChange={(event) => setEditingStrongTokenDraft(event.target.value)}
                            placeholder="Mot dans le verset"
                            className="h-8 w-full rounded-md border border-input bg-background px-2 text-xs text-foreground outline-none placeholder:text-muted-foreground"
                            disabled={strongSaving}
                          />
                          <input
                            type="text"
                            value={editingStrongNumberDraft}
                            onChange={(event) => setEditingStrongNumberDraft(event.target.value)}
                            placeholder="H430 ou G2316"
                            className="h-8 w-full rounded-md border border-input bg-background px-2 text-xs text-foreground outline-none placeholder:text-muted-foreground"
                            disabled={strongSaving}
                          />
                          <input
                            type="text"
                            value={editingStrongLemmaDraft}
                            onChange={(event) => setEditingStrongLemmaDraft(event.target.value)}
                            placeholder="Lemme (facultatif)"
                            className="h-8 w-full rounded-md border border-input bg-background px-2 text-xs text-foreground outline-none placeholder:text-muted-foreground"
                            disabled={strongSaving}
                          />

                          {strongError && <p className="text-xs text-destructive">{strongError}</p>}

                          <div className="flex items-center gap-2">
                            <button
                              type="button"
                              onClick={() => {
                                void submitEditStrongTag(tag.id)
                              }}
                              disabled={strongSaving}
                              className="rounded-md bg-primary px-2.5 py-1.5 text-xs font-medium text-primary-foreground hover:opacity-90 disabled:opacity-60"
                            >
                              {strongSaving ? "Maj..." : "Enregistrer"}
                            </button>
                            <button
                              type="button"
                              onClick={resetStrongEdit}
                              disabled={strongSaving}
                              className="rounded-md border border-border px-2.5 py-1.5 text-xs text-foreground hover:bg-secondary disabled:opacity-60"
                            >
                              Annuler
                            </button>
                          </div>
                        </div>
                      ) : (
                        <div className="flex items-start justify-between gap-2">
                          <button
                            type="button"
                            onClick={() => setSelectedStrong(tag.strongNumber)}
                            className="min-w-0 flex-1 text-left"
                          >
                            <p className="text-xs font-medium text-foreground hover:text-primary">
                              {tag.tokenText} <span className="text-primary">({tag.strongNumber})</span>
                            </p>
                            <p className="mt-1 text-[11px] text-muted-foreground">
                              {tag.lemma ? `Lemme: ${tag.lemma}` : "Sans lemme"} • Position {tag.tokenIndex}
                            </p>
                          </button>

                          <div className="flex items-center gap-1">
                            <button
                              type="button"
                              onClick={() => openStrongEdit(tag)}
                              disabled={strongSaving}
                              className="inline-flex h-7 w-7 items-center justify-center rounded-md border border-border text-muted-foreground hover:text-primary disabled:opacity-50"
                              aria-label="Modifier le tag Strong"
                            >
                              <Pencil className="h-3.5 w-3.5" />
                            </button>
                            <button
                              type="button"
                              onClick={() => {
                                void removeStrongTag(tag.id)
                              }}
                              disabled={strongSaving}
                              className="inline-flex h-7 w-7 items-center justify-center rounded-md border border-destructive/40 text-destructive hover:bg-destructive/10 disabled:opacity-50"
                              aria-label="Supprimer le tag Strong"
                            >
                              <Trash2 className="h-3.5 w-3.5" />
                            </button>
                          </div>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              ) : (
                <p className="mt-2 text-xs text-muted-foreground">Aucun tag Strong sur ce verset.</p>
              )}

              {addingStrongVerse === verse.number && (
                <div className="mt-3 space-y-2 rounded-md border border-border bg-background/70 p-2">
                  <input
                    type="text"
                    value={strongTokenDraft}
                    onChange={(event) => setStrongTokenDraft(event.target.value)}
                    placeholder="Mot dans le verset"
                    className="h-8 w-full rounded-md border border-input bg-background px-2 text-xs text-foreground outline-none placeholder:text-muted-foreground"
                    disabled={strongSaving}
                  />
                  <input
                    type="text"
                    value={strongNumberDraft}
                    onChange={(event) => setStrongNumberDraft(event.target.value)}
                    placeholder="H430 ou G2316"
                    className="h-8 w-full rounded-md border border-input bg-background px-2 text-xs text-foreground outline-none placeholder:text-muted-foreground"
                    disabled={strongSaving}
                  />
                  <input
                    type="text"
                    value={strongLemmaDraft}
                    onChange={(event) => setStrongLemmaDraft(event.target.value)}
                    placeholder="Lemme (facultatif)"
                    className="h-8 w-full rounded-md border border-input bg-background px-2 text-xs text-foreground outline-none placeholder:text-muted-foreground"
                    disabled={strongSaving}
                  />

                  {strongError && <p className="text-xs text-destructive">{strongError}</p>}

                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => {
                        void submitAddStrongTag(verse.number)
                      }}
                      disabled={strongSaving}
                      className="rounded-md bg-primary px-2.5 py-1.5 text-xs font-medium text-primary-foreground hover:opacity-90 disabled:opacity-60"
                    >
                      {strongSaving ? "Ajout..." : "Enregistrer"}
                    </button>
                    <button
                      type="button"
                      onClick={resetStrongAdd}
                      disabled={strongSaving}
                      className="rounded-md border border-border px-2.5 py-1.5 text-xs text-foreground hover:bg-secondary disabled:opacity-60"
                    >
                      Annuler
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        )
      })}

      {selectedEntry && <StrongPopup entry={selectedEntry} isOpen={!!selectedStrong} onClose={() => setSelectedStrong(null)} />}
    </div>
  )
}
