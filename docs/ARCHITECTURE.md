# Guide d'Architecture - Café BDA

L'application suit une architecture en couches pour séparer les responsabilités et faciliter les tests.

## Flux de Données

Le flux de données suit généralement ce chemin :
`Google Sheets API` <-> `Service` <-> `Repository` <-> `Provider` <-> `Widgets (UI)`

### 1. Service (`lib/services/`)
*   **Responsabilité** : Communication brute avec les APIs externes.
*   **Exemple** : `GoogleSheetsService` gère l'authentification OAuth2 et les appels HTTP vers l'API Sheets.
*   **État** : Ne contient aucune logique métier, uniquement du transport de données.

### 2. Repository (`lib/repositories/`)
*   **Responsabilité** : Orchestration de la logique métier et gestion du cache.
*   **Exemple** : `CafeRepository` transforme les données brutes (Listes de listes) en objets ou structures utilisables, gère l'invalidation du cache après écriture, et calcule les indices de lignes pour les formules.

### 3. Provider (`lib/providers/`)
*   **Responsabilité** : Gestion de l'état applicatif (UI State) via `ChangeNotifier`.
*   **Exemple** : `CafeDataProvider` expose les données au reste de l'application, gère les états de chargement (`isLoading`), les messages d'erreur, et les préférences de visibilité des colonnes.
*   **Pattern** : Utilisation de `Provider` pour l'injection de dépendances.

### 4. Widgets / Screens (`lib/widgets/`, `lib/screens/`)
*   **Responsabilité** : Affichage des données et interaction utilisateur.
*   **Pattern** : Utilisation de `Consumer` ou `Selector` pour ne reconstruire que les parties nécessaires de l'UI.

## Gestion d'État (State Management)

Nous utilisons le package `provider`.
*   `AuthProvider` : Gère l'état de connexion de l'utilisateur.
*   `CafeDataProvider` : Gère les données des tableaux et les résultats de recherche.

## Tests

*   **Unitaires** : Portent sur le Repository et le Provider (en utilisant des Mocks pour le Service).
*   **Widget** : Vérifient que l'interface réagit correctement aux changements d'état du Provider.
