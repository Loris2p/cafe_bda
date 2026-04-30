# Note de Version - v10.2.5 (Avril 2026)

Cette version apporte des améliorations à l'expérience de vente et stabilise la version Desktop avec un support complet du temps réel.

## 🚀 Nouveautés
- **Ventes Multiples :** Il est désormais possible de vendre plusieurs articles (ex: 3 cafés) en une seule transaction. Un sélecteur de quantité a été ajouté à l'écran de vente, mettant à jour automatiquement le total et les points de fidélité.
- **Fluidité des Actions :** Après une vente ou un rechargement réussi, une nouvelle option "Nouvelle Vente" (ou "Nouveau Rechargement") permet de rester sur le formulaire pour enchaîner les opérations plus rapidement.
- **Support Desktop Complet (Linux/Windows) :** 
    - Activation du **temps réel** sur Desktop : le solde des étudiants, le catalogue et l'historique se mettent désormais à jour instantanément sans redémarrage.
    - Résolution du bug de la barre de recherche qui pouvait rester bloquée au démarrage sur Desktop.

## 🛠️ Optimisations UI & UX
- **Gestion des Étudiants :** Le bouton d'ajout d'un nouvel étudiant a été déplacé du bouton flottant vers la barre d'outils (App Bar) pour une meilleure visibilité.
- **Confirmation de Solde Négatif :** Ajout d'une boîte de dialogue de confirmation si une vente par "Crédit" doit rendre le solde d'un étudiant négatif.
- **Stabilité Globale :** Correction de nombreux avertissements techniques (Async Gaps) pour garantir que l'application ne plante pas lors de transitions rapides entre les écrans.

## 🔧 Corrections Techniques
- **Migration Firedart :** Optimisation des flux de données pour la bibliothèque Firedart (Desktop) utilisant `Rx.concat` pour garantir l'affichage immédiat des données au chargement.
- **Maintenance :** Nettoyage des variables dupliquées et mise à jour des dépendances de sécurité Firebase.
