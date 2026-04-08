"use client"

import { useState } from "react"
import { Search, X } from "lucide-react"

export function SearchBar() {
  const [query, setQuery] = useState("")
  const [isOpen, setIsOpen] = useState(false)

  return (
    <div className="relative w-full group">
      <div className="relative flex items-center">
        <Search className="absolute left-3 w-4 h-4 text-muted-foreground group-focus-within:text-primary transition-colors duration-300" />
        <input
          type="text"
          placeholder="Chercher un livre, un verset, un personnage..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onFocus={() => setIsOpen(true)}
          onBlur={() => setTimeout(() => setIsOpen(false), 200)}
          className="w-full pl-10 pr-10 py-2.5 bg-card border border-border rounded-lg text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all duration-300 hover:border-primary/50"
        />
        {query && (
          <button
            onClick={() => setQuery("")}
            className="absolute right-3 text-muted-foreground hover:text-foreground transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        )}
      </div>

      {isOpen && query && (
        <div className="absolute top-full left-0 right-0 mt-2 bg-card border border-border rounded-lg shadow-lg z-50 overflow-hidden animate-in fade-in slide-in-from-top-2 duration-300">
          <div className="max-h-96 overflow-y-auto">
            <div className="p-3 space-y-2">
              <div className="text-xs font-semibold text-muted-foreground uppercase tracking-wider px-2">Livres</div>
              <button className="w-full text-left px-3 py-2 rounded-md hover:bg-secondary transition-colors text-sm text-foreground">
                Genèse
              </button>
              <button className="w-full text-left px-3 py-2 rounded-md hover:bg-secondary transition-colors text-sm text-foreground">
                Matthieu
              </button>
              <div className="my-2 h-px bg-border" />
              <div className="text-xs font-semibold text-muted-foreground uppercase tracking-wider px-2">
                Concordance
              </div>
              <button className="w-full text-left px-3 py-2 rounded-md hover:bg-secondary transition-colors text-sm text-foreground">
                Grâce (G5485)
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
