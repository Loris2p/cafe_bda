# Version 6.8.4 - Maintenance et Consolidation Technique 🛠️

Cette version cumule plusieurs mises à jour techniques importantes depuis la version 6.07, visant à moderniser le cœur de l'application et assurer sa stabilité à long terme.

### 🚀 Mises à jour Techniques (v6.8.1 - v6.8.4)

*   **Authentification Google (v6.8.3)** :
    *   Refonte complète du système de connexion (migration vers `google_sign_in` v7.0.0).
    *   Séparation de l'authentification et des autorisations pour une meilleure sécurité.
    *   Amélioration de la fiabilité de la connexion sur mobile.
*   **Mise à jour des Dépendances** :
    *   Intégration des dernières versions des bibliothèques principales (`googleapis`, `http`, `url_launcher`, `shared_preferences`).
    *   Support amélioré pour Android 14+ et les réseaux modernes via `connectivity_plus` v7.0.0.

### 🌍 Nouveautés de la v6.07

*   **Nouveau Module de Paiement** :
    *   Ajout d'un onglet **Paiements** dédié.
    *   Affichage des QR Codes (Lydia, etc.) générés automatiquement.
    *   Configuration simple via la feuille `InfosPaiement`.
*   **Améliorations de l'Interface** :
    *   **Traduction** : L'interface est désormais entièrement en français (y compris les éléments de pagination "Lignes par page").
    *   **Correctifs** : Réparation du sélecteur de lignes par page et meilleure gestion des cases à cocher.
