"use client"

interface HighlightedVerseProps {
  text: string
  strongNumbers: { word: string; strongNumber: string }[]
  onWordClick: (strongNumber: string) => void
}

export function HighlightedVerse({ text, strongNumbers, onWordClick }: HighlightedVerseProps) {
  const strongMap = strongNumbers.reduce(
    (acc, item) => {
      acc[item.word] = item.strongNumber
      return acc
    },
    {} as Record<string, string>,
  )

  const words = text.split(/(\s+)/)

  return (
    <span>
      {words.map((word, idx) => {
        if (/^\s+$/.test(word)) {
          return <span key={idx}>{word}</span>
        }

        const strongNumber = strongMap[word]

        if (strongNumber) {
          return (
            <button
              key={idx}
              onClick={() => onWordClick(strongNumber)}
              className="bg-accent/40 hover:bg-accent/60 px-1.5 rounded transition-colors cursor-pointer font-medium hover:text-primary"
            >
              {word}
            </button>
          )
        }

        return <span key={idx}>{word}</span>
      })}
    </span>
  )
}
