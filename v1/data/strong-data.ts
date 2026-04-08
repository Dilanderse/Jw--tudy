export interface StrongEntry {
  number: string
  word: string
  transliteration: string
  language: "hebrew" | "greek"
  partOfSpeech: string
  definition: string
  usage: string
  occurrences: number
  grammaticalAnalysis: {
    person?: string
    number?: string
    gender?: string
    mood?: string
    voice?: string
    tense?: string
  }
  relatedWords?: string[]
  etymology?: string
  versets: Array<{
    book: string
    chapter: number
    verse: number
    text: string
  }>
}

export const STRONG_DATA: Record<string, StrongEntry> = {
  H430: {
    number: "H430",
    word: "אֱלֹהִים",
    transliteration: "Elohim",
    language: "hebrew",
    partOfSpeech: "Nom masculin pluriel",
    definition: "Dieu, la divinité suprême. Ce terme désigne le Créateur tout-puissant dans la religion biblique.",
    usage:
      "Utilisé pour référencer Dieu en tant que créateur, juge et pourvoyeur. Apparaît dans des contextes de création, jugement divin et relation covenantale.",
    occurrences: 2602,
    grammaticalAnalysis: {
      number: "Pluriel (pluriel de majesté)",
      gender: "Masculin",
    },
    etymology: "Racine אלה (alah) signifiant 'être fort' ou 'puissant'",
    relatedWords: ["H433 (El)", "H1211 (Ba'al)"],
    versets: [
      {
        book: "Genèse",
        chapter: 1,
        verse: 1,
        text: "Au commencement, Dieu créa les cieux et la terre.",
      },
      {
        book: "Genèse",
        chapter: 1,
        verse: 2,
        text: "La terre était informe et vide; il y avait des ténèbres à la surface de l'abîme, et l'esprit de Dieu se mouvait au-dessus des eaux.",
      },
      {
        book: "Exode",
        chapter: 3,
        verse: 14,
        text: "Et Dieu dit à Moïse: Je suis celui qui suis.",
      },
    ],
  },
  H1254: {
    number: "H1254",
    word: "בָּרָא",
    transliteration: "bara",
    language: "hebrew",
    partOfSpeech: "Verbe Qal parfait",
    definition:
      "Créer, former, produire quelque chose de nouveau. Ce verbe implique une création ex nihilo (à partir de rien).",
    usage:
      "Désigne l'acte créatif divin, notamment la création du monde et de l'humanité. Utilisation exclusive pour l'action créatrice divine dans l'AT.",
    occurrences: 48,
    grammaticalAnalysis: {
      person: "3ème personne",
      number: "Singulier",
      gender: "Masculin",
      tense: "Parfait",
      mood: "Indicatif",
      voice: "Actif",
    },
    etymology: "Racine apparentée à 'couper' ou 'séparer'",
    relatedWords: ["H6213 (asah - faire)", "H3559 (kun - établir)"],
    versets: [
      {
        book: "Genèse",
        chapter: 1,
        verse: 1,
        text: "Au commencement, Dieu créa les cieux et la terre.",
      },
      {
        book: "Genèse",
        chapter: 1,
        verse: 27,
        text: "Et Dieu créa l'homme à son image, à l'image de Dieu il le créa.",
      },
      {
        book: "Esaïe",
        chapter: 45,
        verse: 7,
        text: "Je forme la lumière et je crée les ténèbres.",
      },
    ],
  },
  H776: {
    number: "H776",
    word: "אֶרֶץ",
    transliteration: "erets",
    language: "hebrew",
    partOfSpeech: "Nom féminin",
    definition:
      "Terre, sol, pays, le monde. Peut désigner la surface terrestre, une région spécifique ou le monde entier.",
    usage:
      "Utilisé pour décrire la création physique, les royaumes terrestres, et les possessions foncières. Apparaît dans des contextes de géographie biblique et de promesses divines.",
    occurrences: 2505,
    grammaticalAnalysis: {
      gender: "Féminin",
      number: "Singulier",
    },
    etymology: "Racine ancienne, peut-être liée à 'être ferme' ou 'être stable'",
    relatedWords: ["H127 (adamah - sol)", "H1093 (gaia en grec)"],
    versets: [
      {
        book: "Genèse",
        chapter: 1,
        verse: 1,
        text: "Au commencement, Dieu créa les cieux et la terre.",
      },
      {
        book: "Psaume",
        chapter: 24,
        verse: 1,
        text: "La terre appartient à l'Éternel, et tout ce qu'elle contient.",
      },
    ],
  },
  H2822: {
    number: "H2822",
    word: "חֹשֶׁךְ",
    transliteration: "choshek",
    language: "hebrew",
    partOfSpeech: "Nom masculin",
    definition:
      "Ténèbres, obscurité. Littéralement l'absence de lumière; figurativement, le mal, l'ignorance ou le jugement divin.",
    usage:
      "Contraste avec la lumière dans les récits bibliques. Symbolise souvent le péché, l'ignorance ou l'absence de la présence divine.",
    occurrences: 82,
    grammaticalAnalysis: {
      gender: "Masculin",
      number: "Singulier",
    },
    etymology: "Racine ancienne signifiant 'couvrir' ou 'cacher'",
    relatedWords: ["H216 (or - lumière)", "H6822 (tsafah - regarder)"],
    versets: [
      {
        book: "Genèse",
        chapter: 1,
        verse: 2,
        text: "La terre était informe et vide; il y avait des ténèbres à la surface de l'abîme.",
      },
      {
        book: "Jean",
        chapter: 1,
        verse: 5,
        text: "La lumière brille dans les ténèbres, et les ténèbres ne l'ont point reçue.",
      },
    ],
  },
  H216: {
    number: "H216",
    word: "אוֹר",
    transliteration: "or",
    language: "hebrew",
    partOfSpeech: "Nom masculin",
    definition: "Lumière, clarté. Représente le jour, l'illumination physique et spirituelle, ou la présence divine.",
    usage:
      "Symbolise la connaissance de Dieu, la révélation divine et le bien. Contraste constant avec les ténèbres dans la Bible.",
    occurrences: 122,
    grammaticalAnalysis: {
      gender: "Masculin",
      number: "Singulier",
    },
    etymology: "Apparentée à 'brûler' ou 'être clair'",
    relatedWords: ["H215 (or verbe)", "H2822 (choshek - ténèbres)"],
    versets: [
      {
        book: "Genèse",
        chapter: 1,
        verse: 3,
        text: "Dieu dit: Que la lumière soit! Et la lumière fut.",
      },
      {
        book: "Psaume",
        chapter: 27,
        verse: 1,
        text: "L'Éternel est ma lumière et mon salut.",
      },
      {
        book: "Matthieu",
        chapter: 5,
        verse: 14,
        text: "Vous êtes la lumière du monde.",
      },
    ],
  },
  H914: {
    number: "H914",
    word: "בָּדַל",
    transliteration: "badal",
    language: "hebrew",
    partOfSpeech: "Verbe Qal parfait",
    definition: "Séparer, diviser, distinguer. Signifie mettre à part ou créer une distinction entre deux choses.",
    usage:
      "Utilisé pour décrire les actes de séparation divins dans la création, notamment en séparant les éléments de la création.",
    occurrences: 42,
    grammaticalAnalysis: {
      person: "3ème personne",
      number: "Singulier",
      gender: "Masculin",
      tense: "Parfait",
      mood: "Indicatif",
      voice: "Actif",
    },
    etymology: "Racine signifiant 'être éloigné' ou 'mettre à part'",
    relatedWords: ["H953 (bor - puits)", "H914 (badal)"],
    versets: [
      {
        book: "Genèse",
        chapter: 1,
        verse: 4,
        text: "Et Dieu sépara la lumière d'avec les ténèbres.",
      },
      {
        book: "Lévitique",
        chapter: 10,
        verse: 10,
        text: "Vous devez distinguer entre ce qui est sacré et ce qui est profane.",
      },
    ],
  },
  H3117: {
    number: "H3117",
    word: "יוֹם",
    transliteration: "yom",
    language: "hebrew",
    partOfSpeech: "Nom masculin",
    definition: "Jour, une période de 24 heures. Peut aussi désigner une période de temps plus longue ou une époque.",
    usage:
      "Utilisé pour les périodes de création, les jours spéciaux religieux et les périodes eschatologiques. Fondamental pour la chronologie biblique.",
    occurrences: 2291,
    grammaticalAnalysis: {
      gender: "Masculin",
      number: "Singulier",
    },
    etymology: "Racine ancienne, peut-être liée à 'brûler' (le jour solaire)",
    relatedWords: ["H915 (bidlaya - séparation)", "H3118 (yamam)"],
    versets: [
      {
        book: "Genèse",
        chapter: 1,
        verse: 5,
        text: "Ainsi, il y eut un soir, et il y eut un matin: ce fut le premier jour.",
      },
      {
        book: "Psaume",
        chapter: 118,
        verse: 24,
        text: "C'est ici le jour que l'Éternel a fait.",
      },
    ],
  },
  H1697: {
    number: "H1697",
    word: "דָּבָר",
    transliteration: "dabar",
    language: "hebrew",
    partOfSpeech: "Nom masculin",
    definition: "Parole, chose, affaire. Peut signifier une déclaration verbale ou une question/sujet quelconque.",
    usage:
      "Fondamental dans la théologie biblique, particulièrement la 'parole de Dieu' (dabar Elohim). Utilisé pour désigner la communication divine et les événements.",
    occurrences: 1454,
    grammaticalAnalysis: {
      gender: "Masculin",
      number: "Singulier",
    },
    etymology: "Racine signifiant 'parler' ou 'ordonner'",
    relatedWords: ["H1696 (dabar verbe)", "H1699 (dibrah - parole féminin)"],
    versets: [
      {
        book: "Genèse",
        chapter: 1,
        verse: 3,
        text: "Dieu dit (dabar): Que la lumière soit!",
      },
      {
        book: "Esaïe",
        chapter: 55,
        verse: 11,
        text: "Ma parole (dabar) qui sort de ma bouche ne retourne point à moi sans effet.",
      },
    ],
  },
}

export function getStrongEntry(strongNumber: string): StrongEntry | undefined {
  return STRONG_DATA[strongNumber]
}
