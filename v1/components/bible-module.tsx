"use client"

import { useEffect, useMemo, useState } from "react"
import { Header } from "@/components/header"
import { BookGrid } from "@/components/book-grid"
import { ChapterGrid } from "@/components/chapter-grid"
import { VerseView } from "@/components/verse-view"
import { BookIntroVideoPanel } from "@/components/book-intro-video-panel"
import type { Book } from "@/lib/types"
import { ChevronLeft } from "lucide-react"

interface BooksApiResponse {
  books: Book[]
  error?: string
}

interface IntroVideoApiResponse {
  sourceUrl: string | null
  error?: string
}

export function BibleModule() {
  const [selectedBook, setSelectedBook] = useState<string | null>(null)
  const [selectedChapter, setSelectedChapter] = useState<number | null>(null)
  const [books, setBooks] = useState<Book[]>([])
  const [booksLoading, setBooksLoading] = useState(true)
  const [booksError, setBooksError] = useState<string | null>(null)

  const [bookIntroVideos, setBookIntroVideos] = useState<Record<string, string>>({})
  const [bookIntroLoaded, setBookIntroLoaded] = useState<Record<string, boolean>>({})
  const [bookIntroSaving, setBookIntroSaving] = useState(false)
  const [bookIntroError, setBookIntroError] = useState<string | null>(null)

  useEffect(() => {
    const abortController = new AbortController()

    const loadBooks = async () => {
      setBooksLoading(true)
      setBooksError(null)

      try {
        const response = await fetch("/api/bible/books", { signal: abortController.signal })
        const payload = (await response.json()) as BooksApiResponse

        if (!response.ok) {
          throw new Error(payload.error || "Impossible de charger les livres.")
        }

        setBooks(payload.books ?? [])
      } catch (caught) {
        if (abortController.signal.aborted) {
          return
        }

        const message = caught instanceof Error ? caught.message : "Erreur inconnue"
        setBooksError(message)
        setBooks([])
      } finally {
        if (!abortController.signal.aborted) {
          setBooksLoading(false)
        }
      }
    }

    void loadBooks()
    return () => abortController.abort()
  }, [])

  useEffect(() => {
    if (!selectedBook) {
      return
    }

    const bookStillExists = books.some((book) => book.id === selectedBook)
    if (!bookStillExists && !booksLoading) {
      setSelectedBook(null)
      setSelectedChapter(null)
    }
  }, [books, booksLoading, selectedBook])

  useEffect(() => {
    if (!selectedBook || bookIntroLoaded[selectedBook]) {
      return
    }

    const abortController = new AbortController()

    const loadBookIntroVideo = async () => {
      try {
        const response = await fetch(`/api/bible/books/${selectedBook}/intro-video`, {
          signal: abortController.signal,
        })

        const payload = (await response.json()) as IntroVideoApiResponse
        if (!response.ok) {
          throw new Error(payload.error || "Impossible de charger la vidéo d'introduction.")
        }

        setBookIntroVideos((previous) => ({
          ...previous,
          [selectedBook]: payload.sourceUrl ?? "",
        }))
        setBookIntroLoaded((previous) => ({
          ...previous,
          [selectedBook]: true,
        }))
      } catch (caught) {
        if (abortController.signal.aborted) {
          return
        }

        const message = caught instanceof Error ? caught.message : "Erreur inconnue"
        setBookIntroError(message)
      }
    }

    void loadBookIntroVideo()
    return () => abortController.abort()
  }, [bookIntroLoaded, selectedBook])

  useEffect(() => {
    setBookIntroError(null)
  }, [selectedBook])

  const selectedBookData = selectedBook ? books.find((book) => book.id === selectedBook) ?? null : null

  const oldTestament = useMemo(() => books.filter((book) => book.testament === "old"), [books])
  const newTestament = useMemo(() => books.filter((book) => book.testament === "new"), [books])

  const saveBookIntroVideo = async (videoUrl: string) => {
    if (!selectedBook) {
      return
    }

    const bookId = selectedBook
    const previousUrl = bookIntroVideos[bookId] ?? ""

    setBookIntroError(null)
    setBookIntroSaving(true)
    setBookIntroVideos((previous) => ({
      ...previous,
      [bookId]: videoUrl,
    }))
    setBookIntroLoaded((previous) => ({
      ...previous,
      [bookId]: true,
    }))

    try {
      const response = await fetch(`/api/bible/books/${bookId}/intro-video`, {
        method: videoUrl ? "PUT" : "DELETE",
        headers: videoUrl ? { "Content-Type": "application/json" } : undefined,
        body: videoUrl ? JSON.stringify({ sourceUrl: videoUrl }) : undefined,
      })

      const payload = (await response.json()) as { error?: string }
      if (!response.ok) {
        throw new Error(payload.error || "Impossible d'enregistrer la vidéo d'introduction.")
      }
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : "Erreur inconnue"
      setBookIntroError(message)
      setBookIntroVideos((previous) => ({
        ...previous,
        [bookId]: previousUrl,
      }))
    } finally {
      setBookIntroSaving(false)
    }
  }

  if (booksLoading) {
    return (
      <div className="min-h-screen pb-20 md:pb-0">
        <Header title="Ma bible d'étude" titleClassName="text-3xl sm:text-4xl font-bold" />
        <div className="max-w-6xl mx-auto px-4 sm:px-6 py-16 space-y-6">
          {Array.from({ length: 10 }).map((_, index) => (
            <div key={index} className="h-12 animate-pulse rounded-lg border border-border bg-card/60" />
          ))}
        </div>
      </div>
    )
  }

  if (booksError) {
    return (
      <div className="min-h-screen pb-20 md:pb-0">
        <Header title="Ma bible d'étude" titleClassName="text-3xl sm:text-4xl font-bold" />
        <div className="max-w-3xl mx-auto px-4 sm:px-6 py-12">
          <div className="rounded-xl border border-destructive/40 bg-destructive/10 p-5 text-destructive">
            <p className="font-semibold">Chargement impossible</p>
            <p className="mt-2 text-sm">{booksError}</p>
            <p className="mt-2 text-xs">Assure-toi d'avoir importé l'EPUB avec: `npm run import:bible`</p>
          </div>
        </div>
      </div>
    )
  }

  if (selectedBook && selectedChapter) {
    if (!selectedBookData) {
      return null
    }

    return (
      <div className="min-h-screen pb-20 md:pb-0">
        <Header title={`${selectedBookData.name} - Chapitre ${selectedChapter}`} />

        <div className="max-w-4xl mx-auto px-4 sm:px-6 py-8">
          <button
            onClick={() => setSelectedChapter(null)}
            className="flex items-center gap-2 text-primary hover:text-accent mb-8 transition-colors"
          >
            <ChevronLeft className="w-5 h-5" />
            Retour aux chapitres
          </button>

          <VerseView bookId={selectedBook} chapter={selectedChapter} />
        </div>
      </div>
    )
  }

  if (selectedBook) {
    if (!selectedBookData) {
      return null
    }

    return (
      <div className="min-h-screen pb-20 md:pb-0">
        <Header title={`${selectedBookData.name}`} />

        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-8">
          <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_360px] lg:items-start">
            <div>
              <button
                onClick={() => setSelectedBook(null)}
                className="flex items-center gap-2 text-primary hover:text-accent mb-8 transition-colors"
              >
                <ChevronLeft className="w-5 h-5" />
                Retour aux livres
              </button>

              <h2 className="text-2xl font-light mb-8 text-foreground">Chapitres ({selectedBookData.chapters})</h2>
              <ChapterGrid
                bookId={selectedBook}
                totalChapters={selectedBookData.chapters}
                bookName={selectedBookData.name}
                onChapterSelect={setSelectedChapter}
              />
            </div>

            <BookIntroVideoPanel
              bookName={selectedBookData.name}
              videoUrl={bookIntroVideos[selectedBook] ?? ""}
              isSaving={bookIntroSaving}
              saveError={bookIntroError}
              onVideoUrlChange={(videoUrl) => {
                void saveBookIntroVideo(videoUrl)
              }}
            />
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen pb-20 md:pb-0">
      <Header title="Ma bible d'étude" titleClassName="text-3xl sm:text-4xl font-bold" />

      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-16 space-y-16">
        <section className="animate-in fade-in slide-in-from-bottom-4 duration-500">
          <div className="mb-8">
            <h2 className="text-3xl font-light tracking-tight text-primary mb-2">Écritures Hébraïques et Araméennes</h2>
            <p className="text-muted-foreground text-sm">39 livres • Ancien Testament</p>
          </div>
          <BookGrid books={oldTestament} onBookSelect={setSelectedBook} />
        </section>

        <div className="h-px bg-gradient-to-r from-transparent via-border to-transparent" />

        <section className="animate-in fade-in slide-in-from-bottom-4 duration-500 delay-100">
          <div className="mb-8">
            <h2 className="text-3xl font-light tracking-tight text-primary mb-2">Écritures Grecques Chrétiennes</h2>
            <p className="text-muted-foreground text-sm">27 livres • Nouveau Testament</p>
          </div>
          <BookGrid books={newTestament} onBookSelect={setSelectedBook} />
        </section>
      </div>
    </div>
  )
}
