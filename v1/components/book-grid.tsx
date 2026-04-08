"use client"

import type { Book } from "@/lib/types"
import { ChevronRight } from "lucide-react"

interface BookGridProps {
  books: Book[]
  onBookSelect: (bookId: string) => void
}

export function BookGrid({ books, onBookSelect }: BookGridProps) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
      {books.map((book) => (
        <button
          key={book.id}
          onClick={() => onBookSelect(book.id)}
          className="group relative overflow-hidden bg-card hover:bg-card border border-border hover:border-primary rounded-lg p-4 transition-all duration-300 hover:shadow-lg hover:shadow-primary/20 text-left"
        >
          <div className="flex items-center justify-between">
            <span className="font-medium text-foreground group-hover:text-primary transition-colors">{book.name}</span>
            <ChevronRight className="w-5 h-5 text-muted-foreground group-hover:text-primary transition-all transform group-hover:translate-x-1" />
          </div>
          <div className="absolute inset-0 bg-gradient-to-r from-primary/5 to-accent/5 opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none" />
        </button>
      ))}
    </div>
  )
}
