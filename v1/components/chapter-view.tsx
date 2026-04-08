"use client"

import { useState } from "react"
import { ChevronLeft, ChevronRight } from "lucide-react"
import { StrongPopup } from "./strong-popup"
import { HighlightedVerse } from "./highlighted-verse"
import { getStrongEntry } from "@/data/strong-concordance"

interface Verse {
  number: number
  text: string
  highlightedWords?: {
    word: string
    strongNumber: string
  }[]
}

interface ChapterViewProps {
  bookName: string
  chapter: number
  totalChapters: number
  verses: Verse[]
  onChapterChange: (chapter: number) => void
}

export function ChapterView({ bookName, chapter, totalChapters, verses, onChapterChange }: ChapterViewProps) {
  const [selectedStrongNumber, setSelectedStrongNumber] = useState<string | null>(null)

  const selectedEntry = selectedStrongNumber ? getStrongEntry(selectedStrongNumber) : undefined

  return (
    <div className="min-h-screen pb-20 md:pb-0 animate-in fade-in duration-300">
      {/* Header */}
      <div className="sticky top-20 md:top-0 bg-background/95 backdrop-blur z-30 border-b border-border px-4 py-4">
        <div className="max-w-4xl mx-auto">
          <h1 className="text-2xl font-light text-primary mb-4">
            {bookName} {chapter}
          </h1>

          {/* Navigation */}
          <div className="flex items-center justify-between gap-4">
            <button
              onClick={() => onChapterChange(chapter - 1)}
              disabled={chapter === 1}
              className="flex items-center gap-2 px-4 py-2 rounded-lg bg-secondary hover:bg-border disabled:opacity-50 disabled:cursor-not-allowed transition-colors text-sm"
            >
              <ChevronLeft className="w-4 h-4" />
              <span className="hidden sm:inline">Précédent</span>
            </button>

            <span className="text-sm text-muted-foreground whitespace-nowrap">
              {chapter} / {totalChapters}
            </span>

            <button
              onClick={() => onChapterChange(chapter + 1)}
              disabled={chapter === totalChapters}
              className="flex items-center gap-2 px-4 py-2 rounded-lg bg-secondary hover:bg-border disabled:opacity-50 disabled:cursor-not-allowed transition-colors text-sm"
            >
              <span className="hidden sm:inline">Suivant</span>
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Verses */}
      <div className="max-w-4xl mx-auto px-4 py-8 space-y-6">
        {verses.map((verse) => (
          <div key={verse.number} className="group hover:bg-card/50 p-4 rounded-lg transition-colors">
            <div className="flex gap-4">
              <span className="flex-shrink-0 text-primary font-light text-lg w-8 text-center">{verse.number}</span>
              <p className="text-foreground leading-relaxed flex-1">
                <HighlightedVerse
                  text={verse.text}
                  strongNumbers={verse.highlightedWords ?? []}
                  onWordClick={setSelectedStrongNumber}
                />
              </p>
            </div>
          </div>
        ))}
      </div>

      {/* Strong Popup */}
      {selectedEntry && (
        <StrongPopup
          entry={selectedEntry}
          isOpen={!!selectedStrongNumber}
          onClose={() => setSelectedStrongNumber(null)}
        />
      )}
    </div>
  )
}
