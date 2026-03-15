# TODO - Boutique BDA

## ✅ 1. Fonctionnalités de Gestion (Terminé)
- [x] **Gestion des Produits :** Bouton disponibilité et modification prix/nom fonctionnels.
- [x] **Module de Statistiques :** Graphique camembert, évolution des ventes (LineChart) et KPIs (Revenu, Items, Panier Moyen, Rechargements).
- [x] **Logique de Fidélité :** Crédit de 0.50€ offert automatiquement tous les 10 cafés achetés.
- [x] **Gestion des Admins :** Liste blanche supprimée, accès admin pour tout utilisateur connecté.
- [x] **Gestion des Paiements :** Configuration dynamique des moyens de paiement (Lydia, Espèces, etc.).

## ✅ 2. Migration Back-End (Terminé)
- [x] **Migration Firebase :** Passage complet de Google Sheets à Firestore.
- [x] **Rétrocompatibilité :** Les anciennes transactions (importées) sont comptabilisées dans les stats.
- [x] **Sécurité :** Déploiement des `firestore.rules` (accès complet authentifié).
- [x] **Robustesse :** Détection de connexion Internet avant chaque transaction critique.

## 🛠️ 3. Interface & Expérience Utilisateur (En cours)
- [x] **Navigation TabBar :** Switch entre Vente, Rechargement, Étudiants et Admin unifié.
- [x] **Boutons "Rafraîchir" :** Ajoutés sur Historique, Produits, Paiements, Stats et Étudiants (optimisé Linux).
- [x] **Harmonisation UI :** Dialogues modernes arrondis (28px) généralisés.
- [x] **Uniformisation SnackBars :** S'assurer que tous les messages utilisent le style flottant arrondi.

## 🚀 4. Finalisation (À venir)
- [ ] **Tests de bout en bout :** Valider le cycle complet Achat -> Historique -> Solde.
- [ ] **Signature Android (Keystore) :** Créer une clé de signature réelle pour stabiliser les mises à jour et Play Protect.
- [x] **Nettoyage final :** Supprimer les fichiers de migration et logs temporaires.
- [ ] **Documentation :** Mettre à jour le README avec les nouvelles étapes de déploiement.
