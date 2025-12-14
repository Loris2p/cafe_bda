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