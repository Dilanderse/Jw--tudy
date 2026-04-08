"use client"

import { useState, useEffect } from "react"
import { X, Volume2, Heart } from "lucide-react"
import type { StrongEntry } from "@/data/strong-concordance"
import { useFavorites } from "@/lib/favorites-context"

interface StrongPopupProps {
  entry: StrongEntry
  isOpen: boolean
  onClose: () => void
}

export function StrongPopup({ entry, isOpen, onClose }: StrongPopupProps) {
  const [activeTab, setActiveTab] = useState<"meaning" | "definition" | "verses" | "stats">("meaning")
  const { isFavorite, addFavorite, removeFavorite, addToHistory } = useFavorites()

  useEffect(() => {
    if (isOpen) {
      addToHistory(entry.number)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isOpen, entry.number])

  const handleFavoriteToggle = (strongNumber: string) => {
    if (isFavorite(strongNumber)) {
      removeFavorite(strongNumber)
    } else {
      addFavorite(strongNumber)
    }
  }

  // Handle keyboard
  useEffect(() => {
    if (!isOpen) return

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        onClose()
      }
    }

    document.addEventListener("keydown", handleKeyDown)
    return () => document.removeEventListener("keydown", handleKeyDown)
  }, [isOpen, onClose])

  if (!isOpen) return null

  const grammarDetails = [
    entry.grammaticalAnalysis.person && `Personne: ${entry.grammaticalAnalysis.person}`,
    entry.grammaticalAnalysis.number && `Nombre: ${entry.grammaticalAnalysis.number}`,
    entry.grammaticalAnalysis.gender && `Genre: ${entry.grammaticalAnalysis.gender}`,
    entry.grammaticalAnalysis.mood && `Mode: ${entry.grammaticalAnalysis.mood}`,
    entry.grammaticalAnalysis.voice && `Voix: ${entry.grammaticalAnalysis.voice}`,
    entry.grammaticalAnalysis.tense && `Temps: ${entry.grammaticalAnalysis.tense}`,
  ].filter(Boolean)

  return (
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/50 z-40 animate-in fade-in duration-200 md:backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Modal - Optimized for mobile and desktop */}
      <div className="fixed inset-x-4 bottom-0 md:inset-auto md:right-4 md:top-4 md:bottom-auto md:w-96 bg-popover rounded-t-lg md:rounded-lg shadow-2xl z-50 animate-in slide-in-from-bottom-4 duration-300 max-h-[85vh] overflow-y-auto flex flex-col">
        {/* Header */}
        <div className="sticky top-0 bg-gradient-to-b from-card to-popover border-b border-border p-4 flex items-center justify-between shrink-0">
          <div>
            <h2 className="text-lg font-semibold text-foreground">Concordance de Strong</h2>
            <p className="text-sm text-muted-foreground">{entry.number}</p>
          </div>
          <button
            onClick={onClose}
            className="p-1 hover:bg-secondary rounded-md transition-colors touch-feedback"
            aria-label="Fermer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Word Info */}
        <div className="p-4 bg-card/50 border-b border-border shrink-0">
          <div className="space-y-3">
            <div>
              <p className="text-xs text-muted-foreground uppercase tracking-wide mb-1">Mot Original</p>
              <div className="flex items-center justify-between">
                <p className="text-2xl font-light text-primary">{entry.word}</p>
                <button
                  className="p-2 hover:bg-secondary rounded-md transition-colors touch-feedback"
                  title="Pronunciation"
                  aria-label="Écouter la prononciation"
                >
                  <Volume2 className="w-5 h-5 text-muted-foreground hover:text-foreground" />
                </button>
              </div>
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Translittération</p>
              <p className="text-base font-medium text-foreground">{entry.transliteration}</p>
            </div>
            <div className="flex flex-wrap items-center gap-2 text-xs">
              <span className="px-2 py-1 bg-secondary rounded text-muted-foreground">{entry.partOfSpeech}</span>
              <span className="px-2 py-1 bg-secondary rounded text-muted-foreground">
                {entry.language === "hebrew" ? "Hébreu" : "Grec"}
              </span>
            </div>
          </div>
        </div>

        {/* Tabs */}
        <div className="flex border-b border-border bg-card shrink-0 overflow-x-auto">
          {["meaning", "definition", "verses", "stats"].map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab as typeof activeTab)}
              className={`flex-1 px-3 md:px-4 py-3 text-sm font-medium transition-colors border-b-2 whitespace-nowrap touch-feedback ${
                activeTab === tab
                  ? "text-primary border-primary"
                  : "text-muted-foreground border-transparent hover:text-foreground"
              }`}
            >
              {tab === "meaning" && "Sens"}
              {tab === "definition" && "Définition"}
              {tab === "verses" && `Versets (${entry.versets.length})`}
              {tab === "stats" && "Stats"}
            </button>
          ))}
        </div>

        {/* Content - Scrollable */}
        <div className="p-4 space-y-4 flex-1 overflow-y-auto">
          {activeTab === "meaning" && (
            <div className="space-y-4">
              <div className="p-4 bg-primary/10 rounded-lg border border-primary/20">
                <h3 className="text-sm font-semibold text-foreground mb-3">Sens dans le contexte</h3>
                <p className="text-sm text-foreground leading-relaxed mb-3">
                  Le mot "{entry.word}" (<span className="italic">{entry.transliteration}</span>) dans ce contexte
                  spécifique signifie :
                </p>
                <p className="text-base text-foreground leading-relaxed font-medium border-l-4 border-primary pl-3 italic">
                  {entry.definition}
                </p>
              </div>
              <div>
                <h3 className="text-sm font-semibold text-foreground mb-2">Message véhiculé</h3>
                <p className="text-sm text-muted-foreground leading-relaxed">{entry.usage}</p>
              </div>
            </div>
          )}

          {activeTab === "definition" && (
            <div className="space-y-4">
              <div>
                <h3 className="text-sm font-semibold text-foreground mb-2">Définition</h3>
                <p className="text-sm text-muted-foreground leading-relaxed">{entry.definition}</p>
              </div>
              <div>
                <h3 className="text-sm font-semibold text-foreground mb-2">Usages</h3>
                <p className="text-sm text-muted-foreground leading-relaxed">{entry.usage}</p>
              </div>
              {grammarDetails.length > 0 && (
                <div>
                  <h3 className="text-sm font-semibold text-foreground mb-2">Analyse Grammaticale</h3>
                  <div className="space-y-1">
                    {grammarDetails.map((detail) => (
                      <p key={detail} className="text-sm text-muted-foreground">
                        • {detail}
                      </p>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          {activeTab === "verses" && (
            <div className="space-y-3">
              {entry.versets.map((verset, idx) => (
                <button
                  key={idx}
                  className="w-full text-left p-3 rounded-lg bg-card hover:bg-secondary transition-colors border border-border hover:border-primary group touch-feedback"
                >
                  <p className="text-xs text-muted-foreground group-hover:text-primary mb-1">
                    {verset.book} {verset.chapter}:{verset.verse}
                  </p>
                  <p className="text-sm text-foreground leading-relaxed line-clamp-2 md:line-clamp-3">{verset.text}</p>
                </button>
              ))}
            </div>
          )}

          {activeTab === "stats" && (
            <div className="space-y-4">
              <div className="p-3 bg-card rounded-lg border border-border">
                <p className="text-xs text-muted-foreground mb-1">Total Occurrences</p>
                <p className="text-3xl font-light text-primary">{entry.occurrences}</p>
              </div>
              <div className="p-3 bg-card rounded-lg border border-border">
                <p className="text-xs text-muted-foreground mb-1">Langue</p>
                <p className="text-base font-medium text-foreground">
                  {entry.language === "hebrew" ? "Hébreu (AT)" : "Grec (NT)"}
                </p>
              </div>
            </div>
          )}
        </div>

        {/* Footer - Sticky */}
        <div className="bg-card border-t border-border p-4 flex gap-2 shrink-0">
          <button
            onClick={() => handleFavoriteToggle(entry.number)}
            className={`flex-1 px-4 py-2.5 rounded-lg font-medium transition-colors flex items-center justify-center gap-2 touch-feedback text-sm ${
              isFavorite(entry.number)
                ? "bg-accent text-accent-foreground hover:opacity-90"
                : "bg-secondary text-foreground hover:bg-border"
            }`}
          >
            <Heart className={`w-4 h-4 ${isFavorite(entry.number) ? "fill-current" : ""}`} />
            {isFavorite(entry.number) ? "Favori" : "Ajouter"}
          </button>
        </div>
      </div>
    </>
  )
}
