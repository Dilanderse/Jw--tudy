export interface StrongEntry {
  number: string
  word: string
  transliteration: string
  language: "hebrew" | "greek"
  partOfSpeech: "noun" | "verb" | "adjective" | "adverb" | "preposition" | "conjunction" | "particle" | "pronoun"
  definition: string
  usage: string
  grammaticalAnalysis: {
    person?: "1st" | "2nd" | "3rd"
    number?: "singular" | "plural"
    gender?: "masculine" | "feminine" | "neuter"
    mood?: "indicative" | "subjunctive" | "imperative" | "optative"
    voice?: "active" | "passive" | "middle"
    tense?: "present" | "imperfect" | "aorist" | "future" | "perfect" | "pluperfect"
  }
  occurrences: number
  versets: Array<{
    book: string
    chapter: number
    verse: number
    text: string
  }>
}

export const strongConcordance: Record<string, StrongEntry> = {
  G2316: {
    number: "G2316",
    word: "Θεός",
    transliteration: "Theos",
    language: "greek",
    partOfSpeech: "noun",
    definition: "Dieu, l'être suprême, créateur de toutes choses",
    usage: "Utilisé pour désigner le Dieu unique du christianisme et de l'Ancien Testament",
    grammaticalAnalysis: {
      gender: "masculine",
      number: "singular",
    },
    occurrences: 1320,
    versets: [
      {
        book: "Jean",
        chapter: 1,
        verse: 1,
        text: "Au commencement était la Parole, et la Parole était avec Dieu, et la Parole était Dieu.",
      },
      {
        book: "Jean",
        chapter: 3,
        verse: 16,
        text: "Car Dieu a tant aimé le monde qu'il a donné son Fils unique...",
      },
    ],
  },
  G3056: {
    number: "G3056",
    word: "Λόγος",
    transliteration: "Logos",
    language: "greek",
    partOfSpeech: "noun",
    definition: "Parole, discours, raison, principe divin",
    usage: "En Jean 1:1, représente le principe divin ou la Parole de Dieu incarnée",
    grammaticalAnalysis: {
      gender: "masculine",
      number: "singular",
    },
    occurrences: 330,
    versets: [
      {
        book: "Jean",
        chapter: 1,
        verse: 1,
        text: "Au commencement était la Parole, et la Parole était avec Dieu...",
      },
      {
        book: "Matthieu",
        chapter: 26,
        verse: 75,
        text: "Et Pierre se souvint de la parole que Jésus avait dite...",
      },
    ],
  },
  H430: {
    number: "H430",
    word: "אלהים",
    transliteration: "Elohim",
    language: "hebrew",
    partOfSpeech: "noun",
    definition: "Dieu, dieux, puissance, force",
    usage: "Terme général pour désigner la divinité dans l'Ancien Testament",
    grammaticalAnalysis: {
      gender: "masculine",
      number: "plural",
    },
    occurrences: 2602,
    versets: [
      {
        book: "Genèse",
        chapter: 1,
        verse: 1,
        text: "Au commencement, Dieu créa les cieux et la terre.",
      },
    ],
  },
}

export function getStrongEntry(strongNumber: string): StrongEntry | undefined {
  return strongConcordance[strongNumber]
}

export function searchStrongByWord(word: string): StrongEntry[] {
  const query = word.toLowerCase()
  return Object.values(strongConcordance).filter(
    (entry) =>
      entry.word.toLowerCase().includes(query) ||
      entry.transliteration.toLowerCase().includes(query) ||
      entry.definition.toLowerCase().includes(query),
  )
}
