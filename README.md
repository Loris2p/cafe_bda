# ☕ Boutique BDA - v12.0

Application officielle de gestion des ventes et des comptes étudiants du Bureau des Arts (BDA).

🌐 **Accès Production Web / PWA** : [https://boutique-bda.web.app](https://boutique-bda.web.app)

---

## 📌 Présentation & Architecture

La Boutique BDA est désormais exploitée **exclusivement en version Web (PWA)**, hébergée sur **Firebase Hosting** et déployée automatiquement via un pipeline d'intégration et déploiement continus (CI/CD) GitHub Actions.

- **Stack technique** : Flutter Web (SDK ^3.10.7) + Firebase SDK officiel (`firebase_core`, `cloud_firestore`, `firebase_auth`).
- **Synchronisation** : Données temps réel réactives avec Google Cloud Firestore.
- **Accès universel** : Compatible ordinateurs de bureau, tablettes et smartphones (installable en PWA sur écran d'accueil).
- **Déploiement continu** : Tout merge sur la branche `release` déclenche la compilation et le déploiement automatique sur le canal de production.

---

## 📖 Guide Utilisateur

### 🔑 Connexion & Sécurité
- Connectez-vous avec vos identifiants fournis par l'administrateur.
- **Gestionnaires de mots de passe** : Prise en charge native de l'autocomplétion (Bitwarden, 1Password, iCloud Trousseau, Google Password Manager, etc.).
- **Premier accès** : Lors de la création d'un compte, un mot de passe temporaire est généré et l'application impose le changement de mot de passe dès la première connexion.

### 🛒 Effectuer une Vente
1. Rendez-vous sur l'onglet **Vendre**.
2. **Client** : Sélectionnez l'étudiant dans la liste ou utilisez la recherche instantanée (nom / prénom).
3. **Mode de règlement** :
   - **Crédit** : Débite directement le solde du compte étudiant. Une confirmation explicite s'affiche si la vente entraîne un solde négatif.
   - **Lydia / Espèces / Autre** : Pour les paiements directs hors solde.
4. **Sélection du produit** :
   - ⚡ **Vente Express (Rush)** : En cas de forte affluence, une section dépliable permet de sélectionner en un clic un café Nespresso, un café Dolce Gusto ou un Thé au tarif standard (0.50 €) sans impact bloquant sur le stock dosette unitaire.
   - ☕ **Catalogue & Variétés** : Filtrez par catégorie (*Tous*, *Nespresso*, *Dolce Gusto*, *Thé*). Seuls les produits disponibles et en stock s'affichent, avec indicateur visuel de quantité restante et badge d'alerte en cas de réserve disponible.
5. **Quantité** : Ajustez la quantité souhaitée (+/-) ; le montant total et les points de fidélité sont calculés instantanément.
6. **Validation** : Validez la transaction. Une boîte de dialogue confirme le succès et propose :
   - **Nouvelle Vente** : Réinitialise le formulaire pour enchaîner immédiatement la prochaine commande.
   - **Retour à l'accueil** : Revient au tableau de bord.

### 💰 Recharger un Compte Étudiant
1. Allez sur l'onglet **Créditer**.
2. Sélectionnez l'étudiant concerné.
3. Renseignez le montant à créditer (suggestions rapides ou saisie personnalisée).
4. Indiquez le mode de règlement reçu (Lydia, Espèces, etc.).
5. Validez pour mettre à jour instantanément le solde en base.
6. Option **Nouveau Rechargement** disponible pour traiter plusieurs réapprovisionnements à la suite.

### 👥 Gestion des Étudiants
- Onglet **Étudiants** : consultation de l'annuaire complet, recherche en temps réel et solde actuel.
- Ajout d'un nouvel étudiant via le bouton **Ajouter (+)** dans la barre d'outils.
- Consultation de l'historique personnel et modification des informations d'un étudiant.

### 💳 Informations de Paiement & QR Codes
- Onglet **Paiements** : Affiche les informations de règlement pour les étudiants (QR codes scannables pour Lydia, liens et coordonnées de paiement).

---

## ⚙️ Administration & Gestion des Stocks

Le mode Administrateur est accessible aux utilisateurs autorisés via l'icône de profil / paramètres ou le bouton de bascule.

### 📦 Gestion du Catalogue & des Produits
- Activation / désactivation de la disponibilité des produits.
- Modification des tarifs, des dénominations, des catégories et sous-catégories.
- Définition des seuils d'alerte de stock bas.

### 📋 Module Inventaire & Stocks (Bureau & Réserve)
- **Double suivi du stock** :
  - **Stock Bureau (Présentoir)** : Dosettes immédiatement accessibles pour le service au comptoir.
  - **Stock Réserve** : Cartons et dosettes stockés en réserve.
- **Écran d'Inventaire dédié** :
  - Permet d'effectuer un comptage physique périodique rapide.
  - Transfert en un clic du stock Réserve vers le stock Bureau lors du réassort du meuble.
  - Sauvegarde en bloc des écarts constatés avec recalcul automatique du stock total.
  - Alertes automatiques visuelles : *Rupture totale*, *Réassort bureau requis*, *Stock global faible*.

### 📊 Statistiques & Pilotage
- Suivi du chiffre d'affaires, volume de ventes, panier moyen et total rechargé.
- Graphiques de répartition des ventes par produit et évolution chronologique.
- Journal d'audit complet de toutes les transactions avec recherche et filtres.

### 👤 Gestion des Utilisateurs
- Création de nouveaux comptes utilisateurs BDA avec génération automatique de mot de passe temporaire et envoi préparé par email.
- Réinitialisation de mot de passe sécurisée par email.

---

## 🚀 Pipeline de Déploiement & CI/CD

L'application ne nécessite aucune installation locale côté client : elle est hébergée sur **Firebase Hosting** avec déploiement continu via **GitHub Actions**.

### 🔄 Pipeline de Production
- **Fichier de workflow** : `.github/workflows/firebase-hosting-merge.yml`
- **Branche de déclenchement** : `release`
- **Déroulement** :
  1. Checkout du code source.
  2. Installation du SDK Flutter (canal stable).
  3. Résolution des dépendances (`flutter pub get`).
  4. Compilation Web optimisée (`flutter build web --release`).
  5. Déploiement automatique sur le canal `live` de Firebase Hosting ([https://boutique-bda.web.app](https://boutique-bda.web.app)).

### 🧪 Déploiement de Prévisualisation (Pull Requests)
- **Fichier de workflow** : `.github/workflows/firebase-hosting-pull-request.yml`
- Déploie automatiquement chaque PR sur une URL d'aperçu temporaire Firebase Hosting pour valider les modifications avant merge.

### 🛠️ Commandes Utiles (Développeur)

#### Lancement en local
```bash
flutter pub get
flutter run -d chrome
```

#### Tests unitaires & Analyse
```bash
flutter test
flutter analyze
```

#### Déploiement manuel Web (si nécessaire)
```bash
flutter build web --release
firebase deploy --only hosting
```

#### Déploiement des Règles Firestore
```bash
firebase deploy --only firestore:rules
```

---

## 🛡️ Sécurité & Données

- **Base de données** : Google Cloud Firestore (règles de sécurité `firestore.rules` avec accès restreint aux membres authentifiés).
- **Authentification** : Firebase Authentication (chiffrement et hachage sécurisé des identifiants).
- **Programme de Fidélité** : Calcul automatique d'un crédit offert de **0.50 € tous les 10 articles** achetés.
