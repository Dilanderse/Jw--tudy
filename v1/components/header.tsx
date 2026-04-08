import Link from "next/link"
import { ChevronLeft, BookOpen } from "lucide-react"

interface HeaderProps {
  title: string
  backHref?: string
  backLabel?: string
  titleClassName?: string
}

export function Header({ title, backHref, backLabel, titleClassName }: HeaderProps) {
  return (
    <header className="border-b border-border bg-gradient-to-b from-card to-background">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-8 sm:py-12">
        {backHref && (
          <Link
            href={backHref}
            className="inline-flex items-center gap-2 text-sm mb-4 text-primary hover:text-accent transition-colors"
          >
            <ChevronLeft className="w-4 h-4" />
            <span>{backLabel || "Retour"}</span>
          </Link>
        )}
        <div className="flex items-center gap-3">
          <BookOpen className="w-8 h-8 text-primary" />
          <h1
            className={`text-4xl sm:text-5xl font-light tracking-tight text-balance text-foreground ${titleClassName ?? ""}`}
          >
            {title}
          </h1>
        </div>
      </div>
    </header>
  )
}
