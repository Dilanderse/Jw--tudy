"use client"
import { Button } from "@/components/ui/button"
import { BookOpen, Info } from "lucide-react"

interface ActionButtonsProps {
  bookName: string
  onIntroduction?: () => void
  onOverview?: () => void
}

export function ActionButtons({ bookName, onIntroduction, onOverview }: ActionButtonsProps) {
  return (
    <div className="flex flex-col gap-3 w-full max-w-sm">
      <Button onClick={onIntroduction} variant="outline" className="w-full justify-start gap-2 bg-transparent">
        <Info className="w-4 h-4" />
        <span>Introduction à {bookName}</span>
      </Button>
      <Button onClick={onOverview} variant="outline" className="w-full justify-start gap-2 bg-transparent">
        <BookOpen className="w-4 h-4" />
        <span>{bookName} – Aperçu</span>
      </Button>
    </div>
  )
}
