# Idées d'Améliorations pour l'Application Café BDA

Ce document liste des suggestions pour les futures évolutions et améliorations de l'application, couvrant différents aspects techniques et fonctionnels.

## Améliorations UX/UI

### Optimisation de la Navigation
*   **Barre de navigation inférieure (Bottom Navigation Bar)**: Pour une navigation plus intuitive sur mobile entre les principales sections (Accueil, Commandes, Crédits, Paramètres). (Fait)
*   **Historique de navigation**: Faciliter le retour en arrière ou l'accès rapide aux écrans fréquemment visités. (Fait)
*   **Tableau de Bord (Dashboard)**: Page d'accueil visuelle avec accès rapide et recherche. (Fait)
*   **Navigation Intuitive (Double Tap)** : Retour rapide au dashboard en cliquant sur l'onglet actif. (Fait)

### Améliorations de l'Interface (UI)
*   **Recherche Avancée** : Refonte esthétique des dialogues de recherche (Avatars, lisibilité, respect des colonnes masquées). (Fait)
*   **Paramètres Globaux** : Gestion centralisée de la visibilité des colonnes pour tous les tableaux (UI Accordéon). (Fait)
*   **Feedback Visuel** : Indicateurs de chargement et messages d'erreur plus clairs. (Fait)

### Améliorations des Formulaires
*   **Gestion des dates** : Modification de la façon dont les dates sont gérées sur le sheets pour qu'elles soient homogènes + entrée via sélecteur de dates. (Fait)
*   **Confirmation Envoi** : Notification de l'utilisateur à l'envoi d'un formulaire. (Fait)
*   **Validation en temps réel**: Fournir un feedback immédiat aux utilisateurs pendant la saisie. [3]
*   **Autocomplétion intelligente**: Améliorer l'autocomplétion des noms d'étudiants ou de cafés. [4]

## Performance
### Correction d'erreurs
*   **Changement de tableau** : Actuellement, changer de table sur la page d'accueil entraine un plantage de l'application quelque soit la plateforme. (Fait)
*   **Alignement Colonnes** : Correction du décalage visuel sur les colonnes numériques. (Fait)

### Optimisation Globale
*   **Chargement paresseux (Lazy Loading)**: Des données pour les grands tableaux ou les images (si applicable). (Fait - via PaginatedDataTable)
*   **Optimisation des requêtes API**: Regrouper les requêtes ou réduire la quantité de données transférées lorsque c'est possible (Pagination API). [2]
*   **Amélioration de la gestion du cache**: Affiner les stratégies de cache pour les données fréquemment accédées. [3]

## Qualité et Maintenabilité du Code

### Couverture de Tests
*   **Tests unitaires**: Accroître la couverture des tests unitaires pour la logique métier des providers, services et repositories. (Fait)
*   **Tests de widgets**: Ajouter des tests pour vérifier le comportement des composants UI. (Fait)
*   **Tests d'intégration**: Mettre en place des tests d'intégration pour les flux critiques de l'application. (Partiellement Fait - Dashboard)

### Documentation Technique
*   Mettre à jour la documentation existante et ajouter des commentaires de code là où c'est nécessaire. [5]
*   Créer une documentation pour l'API (si une API custom est développée). [6]

## Nouvelles Fonctionnalités Potentielles

*   **Notification Nouvelle Version** : Vérification automatique de la version et notification de l'utilisateur quand une mise à jour est disponible (GitHub Releases). [1]
*   **Rapports et Statistiques**: Afficher des graphiques ou des résumés sur les ventes, les crédits, la popularité des cafés, etc. [2]
*   **Mode Hors Ligne (Consultation)** : Permettre la consultation des données mises en cache (Dernière version connue) sans connexion internet. [3]
*   **Historique des transactions détaillé**: Pour chaque étudiant, voir un historique complet de ses achats et rechargements. [3]
*   **Gestion des Stocks Avancée** : Ajout de seuils d'alerte (stock bas) et gestion des quantités numériques si nécessaire. [4]
*   **Export Données** : Exporter les vues actuelles en CSV/PDF pour archivage. [4]
*   **Thème Sombre** : Implémenter un thème sombre complet pour l'application. [4]
*   **Notifications**: Envoyer des notifications pour des événements importants (stock faible, crédit étudiant bas, etc.). [5]
*   **Gestion des utilisateurs (au-delà de Google Auth)**: Permettre des rôles d'utilisateurs plus fins si nécessaire. [6]

## Accessibilité & Internationalisation

*   **Conformité WCAG**: Assurer le contraste des couleurs et la navigation au clavier. [6]
*   **Support Multilingue**: Traduire l'interface utilisateur. [7]

---

## Plan d'amélioration technique (Archives)

*Objectif : rendre le changement de tableau robuste et performant sur toutes les distributions.*

*   **Debounce / Tokens d'annulation**: (Fait - Partiellement implémenté via l'état isLoading et les sécurités UI).
*   **UI Légère**: (Fait - Remplacement de DataTable par PaginatedDataTable).