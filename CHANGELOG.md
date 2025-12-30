## [6.9.2] - 2025-12-30

### Fixed
- **Gestion des Erreurs d'Accès** : 
  - Correction d'un bug où la page "Accès non autorisé" n'apparaissait plus lors d'une erreur 403.
  - Ajout du bouton "Se déconnecter / Changer de compte" sur la page d'accès refusé pour permettre de basculer facilement vers un compte autorisé.
  - Amélioration de l'affichage de l'email bloqué sur la page d'erreur.
## [6.9.2] - 2025-12-30

### Added
- **Gestion Avancée du Compte** :
  - Ajout d'une option "Révoquer l'accès Google (Changer de compte)" en bas de l'onglet Paramètres. Cela permet de forcer le changement d'utilisateur en cas de besoin.
  - Distinction entre la déconnexion "rapide" (via le bouton de la barre d'outils) qui permet une reconnexion facile, et la révocation (via les paramètres ou la page d'erreur) qui nettoie complètement l'accès.

## [6.9.1] - 2025-12-30

### Fixed
- **Déconnexion et Changement de Compte** :
  - Utilisation de `disconnect()` lors de la déconnexion pour révoquer l'accès Google. Cela force l'affichage du sélecteur de compte lors de la prochaine tentative, résolvant le problème des utilisateurs bloqués sur un mauvais compte.
  - Sécurisation de la méthode de déconnexion pour garantir le retour à l'écran d'accueil même en cas d'erreur réseau avec Google.

## [6.9.0] - 2025-12-30


## [6.8.5] - 2025-12-30

### Changed
- **Dépendances** : Mise à jour de plusieurs bibliothèques vers leurs dernières versions stables :
  - `http` (^1.6.0)
  - `shared_preferences` (^2.5.4)
  - `url_launcher` (^6.3.2)

## [6.8.3] - 2025-12-30

### Changed
- **Authentification** : Migration majeure de `google_sign_in` vers la version 7.0.0.
  - Séparation explicite de l'authentification et de l'autorisation des permissions Google Sheets.
  - Utilisation de la nouvelle infrastructure de gestion des jetons d'accès.
  - Amélioration de la stabilité de la connexion sur Android et iOS.

## [6.8.2] - 2025-12-30

### Changed
- **Dépendances** : Mise à jour de `googleapis` vers la version 15.0.0 pour bénéficier des dernières améliorations et assurer la compatibilité avec le SDK Dart 3.7+.

## [6.8.1] - 2025-12-30

### Changed
- **Dépendances** : Mise à jour de `connectivity_plus` vers la version 7.0.0 pour une meilleure gestion de la connectivité réseau (support multi-réseaux, Android 14+).

## [6.07] - 2025-12-30

### Added
- **Page d'Informations de Paiement** :
  - Ajout d'un nouvel onglet "Paiements" dans le menu principal, affichant les informations de paiement (Lydia, etc.).
  - L'interface utilise un système d'onglets pour naviguer entre plusieurs moyens de paiement.
  - Génération automatique d'un QR Code pour les liens de paiement, cliquable pour ouvrir l'application correspondante.
  - Ajout d'un bouton pour copier le numéro de téléphone/IBAN.
  - La configuration se fait via une nouvelle feuille Google Sheets `InfosPaiement`.
  - Ajout de la dépendance `qr_flutter` pour la génération des QR codes.

### Fixed
- **Pagination des Tableaux** : 
  - Correction du sélecteur du nombre de lignes par page qui ne fonctionnait pas.
- **Localisation** : 
  - Ajout du support pour la langue française (`flutter_localizations`), traduisant les textes par défaut de l'interface (ex: "Rows per page" en "Lignes par page").

### Improved
- **Expérience Utilisateur (UX)** :
  - Ajout d'une transition visuelle (flou et indicateur de chargement) lors du changement du nombre de lignes dans les tableaux pour une expérience plus fluide.
  - L'interface de la page de paiement a été conçue pour être claire et similaire au style des formulaires existants.
- **Robustesse du Code** :
  - Amélioration de l'analyse des booléens (`TRUE`/`FALSE`) depuis Google Sheets pour mieux gérer les cases à cocher.

## [6.06] - 2025-12-25

### Added
- **Système de Mise à Jour Automatique** :
  - L'application vérifie désormais automatiquement au démarrage si une nouvelle version est disponible.
  - Affichage d'une fenêtre de dialogue proposant le téléchargement de la nouvelle version.
  - Gestion des mises à jour obligatoires (si la version actuelle est trop ancienne) et facultatives.
  - Redirection automatique vers la page de "Release" GitHub pour télécharger les fichiers (APK, Windows, Linux).
  - Ajout d'une configuration distante via la feuille "Application" du Google Sheet (Version, URL, Version minimale).

## [6.05.2] - 2025-12-22

### Added
- **Documentation Technique** :
  - Ajout de la documentation du schéma de données Google Sheets (`docs/SHEETS_SCHEMA.md`).
  - Ajout du guide d'architecture de l'application (`docs/ARCHITECTURE.md`).
  - Amélioration des commentaires de code pour l'entrée de l'application et l'authentification.


## [6.05] - 2025-12-22

### Changed
- **Refonte de la Recherche Étudiant** :
  - Amélioration esthétique majeure de la boîte de dialogue de recherche (`StudentSearchDialog`).
  - Interface moderne avec coins arrondis et meilleures icônes.
  - Affichage des résultats avec avatars (initiales) et meilleure lisibilité (Nom/Prénom en gras, ID en sous-titre).
  - Ajout d'un état "Aucun résultat" visuel.
  - Champ de recherche plus clair et mieux intégré.
- **Amélioration des Résultats de Recherche (Accueil)** :
  - Mise à jour esthétique des dialogues de résultats (`SearchDialog`).
  - Les détails d'un résultat respectent désormais la visibilité des colonnes configurée dans les paramètres.
- **Navigation Améliorée** :
  - Cliquer sur l'onglet "Accueil" alors qu'il est déjà actif permet de revenir au tableau de bord (choix des tableaux) si vous étiez en train de consulter un tableau spécifique.
- **Paramètres des colonnes améliorés** :
  - Refonte de l'interface des paramètres avec un système d'accordéon coloré pour chaque tableau.
  - Possibilité de configurer la visibilité des colonnes pour **tous** les tableaux depuis un seul écran, même sans les avoir ouverts au préalable.
  - Ajout d'icônes et de couleurs thématiques pour une meilleure lisibilité.
  - Affichage de la version de l'application en bas des paramètres.

### Fixed
- **Alignement des colonnes** : Correction d'un désalignement entre l'en-tête et les valeurs pour les colonnes numériques (ex: dernière colonne). Les en-têtes sont désormais correctement alignés à droite comme les données.

## [6.04] - 2025-12-22

### Added
- **Nouveau Tableau de Bord (Dashboard)** : 
  - Refonte complète de l'accueil de l'application pour un accès plus visuel et rapide.
  - Cartes d'accès rapide colorées pour les principales sections (Étudiants, Stocks, Paiements, Crédits).
  - Barre de recherche intégrée directement sur l'accueil pour trouver rapidement un étudiant.
  - Bouton "Retour" pour revenir facilement au tableau de bord depuis un tableau de données.
- **Suite de Tests Complète** :
  - Mise en place d'une infrastructure de tests unitaires et widgets robuste avec `flutter_test` et `mockito`.
  - Couverture des repositories (`CafeRepository`) et providers (`CafeDataProvider`) pour sécuriser la logique métier.
  - Tests d'intégration UI pour le nouveau Dashboard.

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