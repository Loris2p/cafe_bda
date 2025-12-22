# Idées d'Améliorations pour l'Application Café BDA

Ce document liste des suggestions pour les futures évolutions et améliorations de l'application, couvrant différents aspects techniques et fonctionnels.

## Améliorations UX/UI


### Optimisation de la Navigation
*   **Barre de navigation inférieure (Bottom Navigation Bar)**: Pour une navigation plus intuitive sur mobile entre les principales sections (Accueil, Commandes, Crédits, Paramètres). (Fait)
*   **Historique de navigation**: Faciliter le retour en arrière ou l'accès rapide aux écrans fréquemment visités. (Fait)

### Améliorations des Formulaires
*   **Gestion des dates** : Modification de la façon dont les dates sont gérées sur le sheets pourqu'elles soient homogènes + entrée via sélecteur de dates.
*   **Validation en temps réel**: Fournir un feedback immédiat aux utilisateurs pendant la saisie.
*   **Autocomplétion intelligente**: Améliorer l'autocomplétion des noms d'étudiants ou de cafés.
*   **Confirmation Envoi** : Notification de l'utilisateur à l'envoi d'un formulaire

## Performance
### Correction d'erreurs
*   **Changement de tableau** : Actuellement, changer de table sur la page d'accueil entraine un plantage de l'application quelque soit la plateforme.
### Optimisation Globale
*   **Chargement paresseux (Lazy Loading)**: Des données pour les grands tableaux ou les images (si applicable).
*   **Optimisation des requêtes API**: Regrouper les requêtes ou réduire la quantité de données transférées lorsque c'est possible.
*   **Amélioration de la gestion du cache**: Affiner les stratégies de cache pour les données fréquemment accédées.

## Qualité et Maintenabilité du Code

### Couverture de Tests
*   **Tests unitaires**: Accroître la couverture des tests unitaires pour la logique métier des providers, services et repositories.
*   **Tests de widgets**: Ajouter des tests pour vérifier le comportement des composants UI.
*   **Tests d'intégration**: Mettre en place des tests d'intégration pour les flux critiques de l'application.

### Documentation Technique
*   Mettre à jour la documentation existante et ajouter des commentaires de code là où c'est nécessaire.
*   Créer une documentation pour l'API (si une API custom est développée).

## Accessibilité

### Conformité WCAG
Assurer que l'application respecte les directives d'accessibilité WCAG (Web Content Accessibility Guidelines) pour les utilisateurs ayant des handicaps (contraste des couleurs, labels sémantiques, navigation au clavier, etc.).

## Internationalisation

### Support Multilingue
Ajouter la possibilité de traduire l'interface utilisateur dans différentes langues pour s'adapter à un public plus large ou à des contextes spécifiques.

## Nouvelles Fonctionnalités Potentielles

*   **Rapports et Statistiques**: Afficher des graphiques ou des résumés sur les ventes, les crédits, la popularité des cafés, etc.
*   **Notifications**: Envoyer des notifications pour des événements importants (stock faible, crédit étudiant bas, etc.).
*   **Gestion des utilisateurs (au-delà de Google Auth)**: Permettre des rôles d'utilisateurs plus fins si nécessaire.
*   **Historique des transactions détaillé**: Pour chaque étudiant, voir un historique complet de ses achats et rechargements.
*   **Thème Sombre** :Implémenter un thème sombre complet pour l'application, offrant une expérience visuelle alternative et réduisant la fatigue oculaire, particulièrement utile dans des environnements peu éclairés.
*   **Notifiaction Nouvelle Version** : Notification de l'utilisateur quand une nouvelle version de l'app est disponible endroit pour les télécharger.

## Plan d'amélioration technique pour éviter les plantages lors du changement de tableau

Objectif : rendre le changement de tableau robuste et performant sur toutes les distributions.

Principes :
* Debounce des changements rapides pour éviter surcharge (ex. 200-300ms).
* Annulation/cohérence : chaque chargement possède un token ; si un nouveau chargement démarre, le résultat précédent est ignoré.
* Chargement en tâche de fond (compute) pour les parsings lourds.
* Cache local pour réouvrir rapidement un tableau déjà chargé.
* UI légère : pas de parsing dans le build, utiliser AnimatedBuilder/ChangeNotifier.
* Boundary d'erreurs côté UI pour éviter crash total.

Composants proposés (fichiers ajoutés) :
* lib/core/table_manager.dart — gestion centralisée du switching, cache, debounce, token d'annulation.
* lib/widgets/table_view.dart — rendu optimisé + indication loading/erreur + retry.
* lib/widgets/error_boundary.dart — enveloppe de sécurité qui montre une UI de secours en cas d'exception de build.

Intégration recommandée :
1. Sur la page d'accueil, injecter un singleton TableManager (Provider ou autre).
2. Lors du changement de tableau, appeler manager.switchTable(tableId).
3. Remplacer l'ancien widget de rendu par TableView(manager: manager).
4. Ajouter des tests unitaires pour TableManager (debounce, annulation, cache) et tests widget pour TableView (loading, error, content).

Tests et vérifications :
* test unitaire : vérifier que les résultats "anciens" sont ignorés si un nouveau switch a eu lieu.
* test widget : switch rapide 5x et vérifier qu'une seule requête effective est traitée et que l'UI reste réactive.