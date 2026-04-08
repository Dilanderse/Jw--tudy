export type Testament = "old" | "new"

export interface Book {
  id: string
  name: string
  testament: Testament
  chapters: number
  abbreviation: string
}

export interface Chapter {
  bookId: string
  number: number
  verses: Verse[]
}

export interface Verse {
  number: number
  text: string
  strongNumbers?: string[]
  references?: string[]
}
