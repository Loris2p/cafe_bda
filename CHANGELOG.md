## [6.04] - 2025-12-22

### Added
- **Nouveau Tableau de Bord (Dashboard)** : 
  - Refonte complète de l'accueil de l'application pour un accès plus visuel et rapide.
  - Cartes d'accès rapide colorées pour les principales sections (Étudiants, Stocks, Paiements, Crédits).
  - Barre de recherche intégrée directement sur l'accueil pour trouver rapidement un étudiant.
  - Bouton "Retour" pour revenir facilement au tableau de bord depuis un tableau de données.

### Optimized
- **Performance d'affichage des tableaux** : 
  - Remplacement du widget `DataTable` standard par un `PaginatedDataTable`.
  - Chargement instantané même avec des centaines de lignes (chargement partiel par pages de 20 lignes).
  - Navigation fluide entre les pages de données.

### Fixed
- **Tri des Dates** : 
  - Correction du tri des colonnes de dates qui se faisait auparavant par ordre alphabétique (texte). Le tri respecte maintenant l'ordre chronologique réel.
- **Menu déroulant "Tableau Actif"** :
  - Correction d'un bug visuel où le menu apparaissait grisé.
  - Ajout d'une sécurité pour empêcher le crash si le tableau sélectionné est introuvable.
  - Amélioration visuelle du menu pour mieux s'intégrer au thème de l'application.

## [6.03] - 2025-12-21
### Changed
- **Gestion des dates dans les forms** :
  - Les dates sont maintenant gérées de la même manière dans les deux tableaux et sont triable normalement. 
### Fixed
- **Crash au changement de tableau**: Correction d'un bug critique où l'application plantait lors du changement de tableau (ex: passer de "Étudiants" à "Stocks"). Le problème était dû à une persistance temporaire des données de l'ancien tableau avant le chargement du nouveau, créant une incompatibilité d'affichage.

## [6.01] - 2025-12-21

### Added
- **Historique de Navigation**: Ajout d'une gestion de l'historique de navigation au sein de l'application. Le bouton "Retour" permet désormais de revenir à l'onglet précédemment consulté (ex: basculer entre "Commandes" et "Crédit").

## [6.0] - 2025-12-21

### Changed
- **Refactorisation majeure des Providers**:
  - La classe `SheetProvider` a été divisée en deux providers spécialisés : `AuthProvider` (pour l'authentification) et `CafeDataProvider` (pour la gestion des données et de l'état UI lié aux tableaux).
  - Cela améliore la modularité, la testabilité et la maintenabilité du code.
  - L'injection de dépendances a été mise à jour dans `main.dart` et les écrans/widgets ont été adaptés en conséquence.
- **Sécurité et Révocation d'accès**:
  - **Vérification d'accès stricte**: Après chaque authentification (automatique ou manuelle), l'application vérifie explicitement les droits de lecture sur la feuille de calcul via un appel API minimal. Si l'accès est refusé (erreur 403), l'utilisateur est immédiatement déconnecté.
  - **Gestion des erreurs 403 en cours d'utilisation**: En cas de détection d'une erreur de permission (403 Forbidden) lors d'une opération sur les données, toutes les données locales sont effacées et l'utilisateur est déconnecté pour garantir que des informations non autorisées ne persistent pas.
- **Optimisation de la taille de l'application (Android)**:
  - Activation des options `isMinifyEnabled` et `isShrinkResources` dans le `build.gradle.kts` Android pour le build `release`. Cela réduit significativement la taille de l'APK en éliminant le code et les ressources inutilisées.

### Fixed
- **Stabilité de la disposition des boutons**:
  - Les `FilterChip`s utilisés pour la sélection des moyens de paiement et de crédit ne changent plus de taille lors de la sélection/désélection. La coche (`showCheckmark`) a été désactivée et la sélection est maintenant indiquée par le changement de style du texte (couleur et gras).
- **Valeur par défaut du "Nombre de cafés"**: Le champ "Nombre de cafés" dans le formulaire de commande est maintenant pré-rempli avec la valeur `1` par défaut.
- **Avertissement de compilation**: Correction de l'utilisation dépréciée de `withOpacity` par `withValues` pour les couleurs.

## [1.6.0] - 2025-12-14

### Added
- **Tri des colonnes**: Il est maintenant possible de trier les données des tableaux en cliquant sur les en-têtes de colonnes. Le tri gère les nombres, les textes et les booléens.
- **Panneau de Paramètres (Roue crantée)**:
  - Ajout d'un panneau de configuration accessible via une nouvelle icône de roue crantée dans la barre d'application.
  - **Visibilité des colonnes**: Permet de masquer ou d'afficher les colonnes de chaque tableau. Les préférences sont sauvegardées pour chaque utilisateur et chaque tableau.
  - **Nom du Responsable**: Permet de définir un nom par défaut pour le "Responsable", qui sera automatiquement pré-rempli dans le formulaire d'ajout de crédit. Ce paramètre est aussi sauvegardé par utilisateur.
- **Gestion des Erreurs d'Autorisation**:
  - Un écran spécifique est maintenant affiché si un utilisateur se connecte avec un compte Google n'ayant pas accès au Google Sheet.
  - Cet écran invite l'utilisateur à contacter le support et inclut un bouton pour envoyer un e-mail de demande d'accès pré-rempli.
- **Barres de Défilement Visibles**: Des barres de défilement verticale et horizontale sont maintenant toujours visibles sur les tableaux pour une meilleure clarté.

### Changed
- **Icône des Paramètres**: L'icône pour la configuration des colonnes a été remplacée par une icône de roue crantée (`Icons.settings`).
- **Logique du Stock de Café**: La liste des cafés disponibles dans le formulaire de commande se base maintenant sur une valeur booléenne (`TRUE`/`FALSE`) pour le stock, au lieu d'une quantité numérique.
- **Position de la Barre de Défilement**: La barre de défilement horizontale du tableau est maintenant affichée en haut du tableau plutôt qu'en bas.
- **Centrage des Éléments**:
  - Les tableaux plus étroits que la fenêtre sont maintenant centrés horizontalement.
  - Les boutons d'action ("Étudiant", "Crédit", etc.) sont maintenant centrés sur les écrans de petite taille.

### Fixed
- **Actualisation des Données**:
  - La soumission d'une commande ou d'un crédit actualise maintenant correctement la table des étudiants pour refléter les changements de solde.
  - Le bouton d'actualisation force maintenant un rechargement des données depuis la source, ignorant le cache.
- **Mise à Jour de l'UI**: Correction de plusieurs problèmes où l'interface utilisateur ne se mettait pas à jour instantanément après une action (ex: changement de visibilité d'une colonne, case à cocher du stock).
- **Erreurs de Layout**: Correction d'une erreur `RenderFlex overflow` survenant sur les écrans de petite taille.
- **Avertissements d'Analyse Statique**: Correction de plusieurs avertissements, incluant l'utilisation de membres dépréciés (`withOpacity`, `dataRowHeight`) et des importations inutilisées.

### Bugs
- **Barres de défilement**: les barres de défilement on un comportement étrange
