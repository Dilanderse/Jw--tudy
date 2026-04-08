export interface MockVerse {
  verse: number
  text: string
  highlightedWords: {
    word: string
    strongNumber: string
  }[]
}

export function getMockVerses(bookId: string, chapter: number): MockVerse[] {
  // Mock data for Genesis Chapter 1
  if (bookId === "genesis" && chapter === 1) {
    return [
      {
        verse: 1,
        text: "Au commencement, Dieu créa les cieux et la terre.",
        highlightedWords: [
          { word: "Dieu", strongNumber: "H430" },
          { word: "créa", strongNumber: "H1254" },
        ],
      },
      {
        verse: 2,
        text: "La terre était informe et vide; il y avait des ténèbres à la surface de l'abîme, et l'esprit de Dieu se mouvait au-dessus des eaux.",
        highlightedWords: [
          { word: "terre", strongNumber: "H776" },
          { word: "ténèbres", strongNumber: "H2822" },
          { word: "Dieu", strongNumber: "H430" },
        ],
      },
      {
        verse: 3,
        text: "Dieu dit: Que la lumière soit! Et la lumière fut.",
        highlightedWords: [
          { word: "Dieu", strongNumber: "H430" },
          { word: "lumière", strongNumber: "H216" },
        ],
      },
      {
        verse: 4,
        text: "Dieu vit que la lumière était bonne; et Dieu sépara la lumière d'avec les ténèbres.",
        highlightedWords: [
          { word: "Dieu", strongNumber: "H430" },
          { word: "lumière", strongNumber: "H216" },
          { word: "sépara", strongNumber: "H914" },
        ],
      },
      {
        verse: 5,
        text: "Dieu appela la lumière jour, et il appela les ténèbres nuit. Ainsi, il y eut un soir, et il y eut un matin: ce fut le premier jour.",
        highlightedWords: [
          { word: "Dieu", strongNumber: "H430" },
          { word: "jour", strongNumber: "H3117" },
        ],
      },
    ]
  }

  // Default mock verses for other books/chapters
  return [
    {
      verse: 1,
      text: "Ceci est un verset fictif pour tester le système.",
      highlightedWords: [{ word: "verset", strongNumber: "H1697" }],
    },
  ]
}
