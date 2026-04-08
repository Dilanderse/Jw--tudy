"use client"

interface ChapterGridProps {
  bookId: string
  totalChapters: number
  bookName: string
  onChapterSelect: (chapter: number) => void
}

export function ChapterGrid({ bookId, totalChapters, bookName, onChapterSelect }: ChapterGridProps) {
  const chapterArray = Array.from({ length: totalChapters }, (_, i) => i + 1)

  return (
    <div className="grid grid-cols-4 sm:grid-cols-6 lg:grid-cols-8 gap-2 animate-in fade-in duration-500">
      {chapterArray.map((chapter) => (
        <button
          key={chapter}
          onClick={() => onChapterSelect(chapter)}
          className="group aspect-square flex items-center justify-center bg-card border border-border hover:border-primary hover:bg-primary/10 text-foreground font-semibold rounded-lg transition-all duration-300 hover:shadow-md hover:shadow-primary/30 relative overflow-hidden"
        >
          <span className="relative z-10 group-hover:text-primary transition-colors">{chapter}</span>
          <div className="absolute inset-0 bg-gradient-to-br from-primary/10 to-accent/10 opacity-0 group-hover:opacity-100 transition-opacity" />
        </button>
      ))}
    </div>
  )
}
