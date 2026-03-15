# Note de Version - v10.0.0 "Google Sheets -> Firebase" (Mars 2026)

Cette version marque un tournant majeur pour l'application **Boutique BDA**. Après plusieurs semaines de travail, nous avons finalisé la migration complète vers une infrastructure moderne et robuste.

## 🚀 Nouveautés Majeures
- **Backend Firebase (Migration Terminée) :** L'application abandonne Google Sheets au profit de **Google Firestore**. Les données sont désormais accessibles en temps réel, de manière sécurisée et avec une bien meilleure réactivité.
- **Rétrocompatibilité Totale :** Toutes les transactions historiques de l'ancien système ont été migrées et sont pleinement intégrées dans les nouveaux modules de statistiques.
- **Statistiques Avancées :** Un nouveau tableau de bord complet pour le pilotage de l'activité :
    - **KPIs globaux :** Ventes totales, Rechargements, Panier moyen.
    - **Visualisations :** Graphique d'évolution du CA (LineChart) et répartition des paiements (PieChart).
    - **Top Ventes :** Classement dynamique des 10 produits les plus populaires.
- **Sécurité Renforcée :** 
    - Déploiement de règles Firestore strictes garantissant que seuls les membres authentifiés peuvent lire/écrire.
    - **Suppression de la "liste blanche" :** Tout utilisateur autorisé par l'admin peut désormais gérer le catalogue sans configuration manuelle fastidieuse.

## 🛠️ Optimisations UI & UX
- **Design Moderne & Harmonisé :**
    - Refonte des boîtes de dialogue avec des bords arrondis (**28px**), une typographie **Poppins** et des icônes rafraîchies.
    - **SnackBars Flottantes :** Toutes les notifications (erreurs, succès, infos) utilisent désormais un style flottant, arrondi et cohérent sur toute l'application.
- **Expérience Desktop/Linux :** Ajout de boutons "Rafraîchir" manuels sur tous les écrans critiques pour garantir la synchronisation, même sur les environnements Linux limitant les flux temps réel.
- **Fiabilité Réseau :** Détection automatique de la perte de connexion Internet pour prévenir toute transaction incomplète ou désynchronisée.

## 🔧 Maintenance & Restructuration
- **Nettoyage de Printemps :** Restructuration complète de la racine du projet pour plus de clarté et archivage définitif des scripts de la v1.
- **Optimisation Firestore :** Utilisation des agrégations natives pour des statistiques ultra-rapides et une consommation de données réduite.
- **Robustesse Git :** Nettoyage des fichiers sensibles accidentellement suivis et résolution des conflits de fusion historiques.
