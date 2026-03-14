# Note de Version - v10.0.0 (Mars 2026)

Cette version "Grand Cru" marque la fin de la migration vers Firebase et apporte des améliorations majeures en termes de performance, de sécurité et d'expérience utilisateur.

## 🚀 Nouveautés Majeures
- **Backend Firebase (Migration Terminée) :** L'application utilise désormais Google Firestore en remplacement de Google Sheets. Les données sont accessibles en temps réel et de manière sécurisée.
- **Rétrocompatibilité Totale :** Toutes les anciennes transactions issues de l'ancien système ont été intégrées et sont comptabilisées dans les nouvelles statistiques.
- **Statistiques Avancées :** Un nouveau tableau de bord complet avec :
    - KPIs globaux (Ventes totales, Rechargements, Panier moyen).
    - Graphique d'évolution du chiffre d'affaires.
    - Répartition des moyens de paiement (Camembert).
    - Top 10 des produits les plus vendus.
- **Sécurité Renforcée :** 
    - Déploiement de règles Firestore strictes (accès réservé aux membres connectés).
    - Suppression de la liste blanche d'emails : tout membre autorisé peut désormais gérer le catalogue et les prix.

## 🛠️ Optimisations UI & UX
- **Support Desktop/Linux :** Ajout de boutons "Rafraîchir" manuels sur tous les écrans critiques pour compenser les limitations des flux temps réel sur certaines versions Linux.
- **Design Moderne :** Refonte des boîtes de dialogue (bords arrondis 28px, police Poppins, icônes harmonisées).
- **Robustesse Réseau :** L'application détecte désormais la perte de connexion Internet et bloque les transactions risquées pour éviter toute désynchronisation.

## 🔧 Corrections Techniques
- Résolution des conflits de fusion Git lors de la migration.
- Optimisation des requêtes via les agrégations natives Firestore (plus rapide, moins de consommation de données).
- Nettoyage complet du code (suppression des scripts de migration temporaires).
