# Atlas biblique

Le module `Atlas biblique` est conçu comme un système éditable par l'utilisateur, pas seulement comme un écran de consultation.

## Types d'éléments

- `place`
- `region`
- `route`
- `event`

## Stockage

Tables SQLite utilisées :

- `atlas_items`
- `atlas_item_verses`
- `atlas_collections`
- `atlas_collection_items`

`map_data` est stocké en JSON pour rester flexible :

- `point` pour un lieu
- `polygon` pour une région
- `polyline` pour un trajet
- `event` peut utiliser `point` ou `polygon`

## Relations

- Un élément atlas peut être lié à plusieurs versets.
- Un verset peut être lié à plusieurs éléments atlas.
- Un élément atlas peut appartenir à plusieurs collections.

## UX actuelle

- L'écran atlas contient :
  - une colonne filtres / recherche / création
  - une zone centrale carte + timeline
  - une fiche détaillée de l'élément sélectionné
- Depuis un verset biblique, l'utilisateur peut ouvrir directement un élément atlas lié.
- Depuis une fiche atlas, l'utilisateur peut revenir au livre / chapitre du verset associé.

## Règles d'édition

- `place` : 1 point minimum
- `region` : 3 points minimum
- `route` : 2 points minimum
- `event` : 1 point minimum si point, 3 points minimum si zone

Le bouton d'enregistrement reste bloqué tant que la géométrie minimale n'est pas valide.
