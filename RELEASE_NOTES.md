# Notes de Version - Boutique BDA

---

## 🚀 Version 12.0 (Octobre 2026) - Version Actuelle

Cette version marque l'officialisation de la **version 12.0** de la Boutique BDA, centralisée sur la plateforme **Web (PWA)** avec un pipeline de déploiement continu automatisé en production.

### 🌐 Architecture Web Exclusive & Pipeline de Production
- **Déploiement Web Unifié** : L'application est désormais servie exclusivement sur le Web à l'adresse officielle [https://boutique-bda.web.app](https://boutique-bda.web.app), garantissant une expérience identique et toujours à jour sur tous les postes, tablettes et téléphones.
- **Pipeline CI/CD GitHub Actions** :
  - Tout merge sur la branche `release` déclenche automatiquement le pipeline de compilation Flutter Web et le déploiement sur Firebase Hosting (canal `live`).
  - Déploiement de canaux de prévisualisation (preview channels) éphémères sur chaque Pull Request pour tester avant mise en ligne.
- **Suppression des dépendances Desktop hétérogènes** : Retrait définitif de Firedart et de la couche native Linux/Windows au profit du SDK officiel FlutterFire Web.

### 📦 Gestion Complète des Stocks & Module Inventaire
- **Double Répartition des Stocks** :
  - **Stock Bureau (Présentoir)** : Suivi en direct des dosettes disponibles immédiatement au comptoir de vente.
  - **Stock Réserve** : Suivi des boîtes et stocks entreposés en réserve.
- **Écran d'Inventaire dédié (`InventoryScreen`)** :
  - Interface rapide de pointage physique lors des inventaires réguliers.
  - Outil de transfert direct du stock Réserve vers le Bureau pour faciliter le réassort.
  - Détection automatique et sauvegarde groupée des écarts d'inventaire.
- **Filtrage Intelligent à la Vente** :
  - Affichage direct des produits en stock uniquement, avec pastilles de quantité restante.
  - Indicateur visuel lorsqu'un produit est épuisé au comptoir mais encore disponible en réserve.
- **Alertes de Rupture & Seuils Bas** :
  - Seuil d'alerte paramétrable par produit avec mise en évidence des variétés nécessitant une commande fournisseur.

### ⚡ Expérience de Vente & Mode Rush
- **Ventes Express (Rush)** : Section accordéon dédiée aux moments de forte affluence permettant d'enregistrer en un clic un café Nespresso, Dolce Gusto ou Thé au tarif standard (0.50 €) sans blocage d'inventaire unitaire.
- **Filtrage par Catégories** : Filtres rapides par chips (*Tous*, *Nespresso*, *Dolce Gusto*, *Thé*) pour sélectionner la variété souhaitée en quelques secondes.

### 🔐 Sécurité & Qualité de Vie
- **Support des Gestionnaires de Mots de Passe** : Intégration d'un groupe d'autofill adapté pour les gestionnaires de mots de passe modernes (Bitwarden, 1Password, Google Password Manager, Apple Keychain).
- **Audit de Sécurité & Nettoyage** :
  - Dépôt nettoyé de l'index Git des modules tiers et manifests obsolètes.
  - Sécurisation stricte des variables d'environnement et gabarit `.env.example`.
  - Résolution complète des alertes de sécurité Dependabot et Secret Scanning.
- **Contrôle de Version Automatique** : Redirection fluide vers l'application Web de production en cas de mise à jour requise.

---

## 📦 Version 11.0 (Septembre 2026)

- Configuration de Firebase Hosting pour Web / PWA.
- Introduction initiale du modèle de suivi des stocks (Bureau / Réserve).
- Refonte des écrans de gestion de produits et ajout de la suite de tests unitaires de stock (`test/product_stock_test.dart`).
- Optimisation des graphiques et du tableau de bord de statistiques.

---

## 📦 Version 10.2.5 (Avril 2026)

- **Ventes Multiples** : Vente de plusieurs articles simultanément avec sélecteur de quantité et calcul dynamique du total et des points de fidélité.
- **Fluidité des Actions** : Options "Nouvelle Vente" et "Nouveau Rechargement" pour rester sur les formulaires d'opérations.
- **Gestion des Étudiants** : Déplacement du bouton d'ajout vers l'AppBar pour une meilleure visibilité.
- **Confirmation de Solde Négatif** : Dialogue d'alerte lors d'une transaction par Crédit passant le compte en négatif.
