# Decisions

## 2026-04-07 - Navigation responsive et ecrans compacts

- Le shell principal bascule en `BottomNavigation` sous `960px` et conserve la sidebar au-dela.
- La navigation mobile et desktop reutilisent le meme `navigationProvider` pour garder un seul flux d'etat.
- Les ecrans `Bible`, `Discours` et `Atlas` adaptent maintenant leurs espacements et leurs grilles aux petites largeurs.
- Le module `Atlas` passe d'une disposition en trois colonnes a une pile verticale sur largeur reduite, avec hauteurs bornees pour conserver l'edition utilisable.
