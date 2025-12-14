# Changelog - Optimisation des Performances et Refactoring

## [1.1.0] - 2025-12-14

### Architecture (SOLID)
- **Refactoring Service/Repository** : Séparation stricte des responsabilités.
  - `GoogleSheetsService` : Ne gère plus que l'authentification et les appels API bruts. Suppression de toute logique métier (formules, structure des tables).
  - `CafeRepository` : Centralise désormais toute la logique métier (calcul des lignes, formules Excel, structure des données Crédit/Commande).
- **SheetProvider** :
  - Suppression de l'utilisation directe du Service pour la lecture des données. Tout passe par le Repository.
  - Implémentation du principe DRY via la méthode `_executeTransaction` pour uniformiser la gestion des erreurs et du chargement.

### Performance
- **Mise en cache (Caching)** :
  - Ajout d'un cache mémoire dans `CafeRepository` pour la table 'Étudiants' (durée de validité : 5 minutes).
  - Réduction drastique des appels API lors de la navigation entre les onglets et lors des recherches.
- **Optimisation UI (Flutter)** :
  - Remplacement de `context.watch<SheetProvider>()` à la racine de `GoogleSheetsScreen` (qui provoquait un rebuild total à chaque notification) par des widgets ciblés `Consumer` et `Selector`.
  - Découpage de l'écran principal en sous-widgets const (`_TableSelector`, `_ActionButtons`, etc.) pour minimiser le coût de rendu.
- **Benchmarking** :
  - Ajout de logs de performance (`stopwatch`) pour mesurer le temps de build de l'écran principal.

### Corrections Diverses
- Correction de la logique de double récupération des données (Tableau global + Liste étudiants) dans le Provider.
- Amélioration de la gestion des erreurs lors des transactions asynchrones.
