"use client"

import { useFavorites } from "@/lib/favorites-context"
import { Heart } from "lucide-react"
import { getStrongEntry } from "@/data/strong-concordance"
import { useState } from "react"
import { StrongPopup } from "./strong-popup"
import type { StrongEntry } from "@/data/strong-concordance"

export function FavoritesModule() {
  const { favorites, removeFavorite } = useFavorites()
  const [selectedEntry, setSelectedEntry] = useState<StrongEntry | null>(null)
  const [isPopupOpen, setIsPopupOpen] = useState(false)

  const favoriteEntries = Array.from(favorites)
    .map((strongNumber) => getStrongEntry(strongNumber))
    .filter((entry): entry is StrongEntry => entry !== undefined)

  const handleWordClick = (strongNumber: string) => {
    const entry = getStrongEntry(strongNumber)
    if (entry) {
      setSelectedEntry(entry)
      setIsPopupOpen(true)
    }
  }

  return (
    <div className="p-6 space-y-6 pb-24 md:pb-6">
      <div>
        <h1 className="text-3xl font-light text-foreground mb-2">Mots Favoris</h1>
        <p className="text-muted-foreground">
          {favoriteEntries.length === 0
            ? "Aucun mot favorable pour le moment. Cliquez sur le cœur dans la Concordance de Strong pour en ajouter."
            : `${favoriteEntries.length} mot${favoriteEntries.length > 1 ? "s" : ""} sauvegardé${favoriteEntries.length > 1 ? "s" : ""}`}
        </p>
      </div>

      {favoriteEntries.length > 0 && (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {favoriteEntries.map((entry) => (
            <button
              key={entry.number}
              onClick={() => handleWordClick(entry.number)}
              className="p-4 bg-card rounded-lg border border-border hover:border-primary hover:shadow-lg transition-all duration-300 text-left group"
            >
              <div className="flex items-start justify-between mb-2">
                <div>
                  <p className="text-sm text-muted-foreground mb-1">{entry.number}</p>
                  <p className="text-xl font-light text-primary group-hover:text-primary/80">{entry.word}</p>
                </div>
                <Heart className="w-4 h-4 text-accent fill-accent flex-shrink-0" />
              </div>
              <p className="text-sm text-muted-foreground mb-2">{entry.transliteration}</p>
              <p className="text-xs text-muted-foreground bg-secondary/50 px-2 py-1 rounded w-fit">
                {entry.partOfSpeech}
              </p>
              <p className="text-sm text-foreground leading-relaxed mt-3 line-clamp-2">{entry.definition}</p>
            </button>
          ))}
        </div>
      )}

      {selectedEntry && (
        <StrongPopup entry={selectedEntry} isOpen={isPopupOpen} onClose={() => setIsPopupOpen(false)} />
      )}
    </div>
  )
}
