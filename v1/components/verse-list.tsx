"use client"

interface VerseListProps {
  bookName: string
  chapter: number
  verses: number
}

export function VerseList({ bookName, chapter, verses }: VerseListProps) {
  const verseArray = Array.from({ length: verses }, (_, i) => i + 1)

  return (
    <div className="space-y-4">
      {verseArray.map((verse) => (
        <div key={verse} className="bg-card border border-border rounded-lg p-4 hover:bg-muted transition-colors">
          <div className="flex gap-3">
            <span className="text-primary font-semibold text-sm min-w-fit pt-1">
              {chapter}:{verse}
            </span>
            <p className="text-foreground leading-relaxed">[Texte du verset {verse} - À ajouter ultérieurement]</p>
          </div>
          <div className="mt-3 flex gap-2 text-xs text-muted-foreground flex-wrap">
            <button className="hover:text-foreground transition-colors">Références</button>
            <span>•</span>
            <button className="hover:text-foreground transition-colors">Notes</button>
          </div>
        </div>
      ))}
    </div>
  )
}
