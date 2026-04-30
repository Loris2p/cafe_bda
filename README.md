# ☕ Boutique BDA - v10.2.5

L'application de gestion officielle du Bureau des Arts (BDA). Permet de gérer les ventes de café, les rechargements de comptes étudiants et de suivre les statistiques en temps réel.

---

## 📖 Guide Utilisateur

### 🔑 Connexion
- Connectez-vous avec votre email et mot de passe fournis par l'administrateur.
- Lors de votre première connexion, il vous sera demandé de **changer votre mot de passe**.

### 🛒 Effectuer une Vente
1. Allez sur l'onglet **Vente**.
2. Sélectionnez l'étudiant dans la liste (ou utilisez la barre de recherche).
3. Choisissez le produit.
4. **Quantité** : Ajustez le nombre d'articles si nécessaire (le total et la fidélité se mettent à jour automatiquement).
5. Sélectionnez le moyen de paiement (**Crédit** débitera le solde de l'étudiant).
6. Validez. Une popup de succès confirmera l'enregistrement.
7. **Action Rapide** : Choisissez "Nouvelle Vente" pour rester sur le formulaire ou "Retour à l'accueil".

### 💰 Recharger un Compte
1. Allez sur l'onglet **Rechargement**.
2. Sélectionnez l'étudiant.
3. Saisissez le montant et choisissez le mode de paiement (Lydia, Espèces, etc.).
4. Validez. Le solde est mis à jour instantanément.
5. **Action Rapide** : Choisissez "Nouveau Rechargement" pour rester sur le formulaire ou "Retour à l'accueil".

### 👥 Gestion des Étudiants
- Utilisez l'onglet **Étudiants** pour ajouter un nouvel arrivant ou modifier les informations d'un élève.
- Le bouton **Ajouter (+)** se trouve dans la barre d'outils en haut à droite.
- Les données sont synchronisées en temps réel sur tous les supports (incluant Linux/Windows).

### ⚙️ Mode Administrateur
- Accessible via les **Paramètres**.
- Permet de modifier les prix, ajouter des produits au catalogue et configurer les méthodes de paiement.

---

## 🚀 Guide de Déploiement (Développeur)

### 🏗️ Pré-requis
- Flutter SDK (dernière version stable).
- Firebase CLI installé (`npm install -g firebase-tools`).

### ⚙️ Configuration Firebase
L'application utilise une architecture hybride :
- **Firedart + RxDart** pour le support natif Linux/Windows (Desktop) avec flux temps réel.
- **Cloud Firestore SDK** pour Mobile et Web.

#### Déploiement des Règles de Sécurité
Pour mettre à jour les règles Firestore :
```bash
firebase use boutique-bda
firebase deploy --only firestore:rules
```

### 🔨 Compilation
#### Pour Linux :
```bash
flutter build linux --release
```
#### Pour Windows :
```bash
flutter build windows --release
```
#### Pour Android :
```bash
flutter build apk --release
```

---

## 🛡️ Sécurité & Données
- Les données sont stockées sur **Google Cloud Firestore**.
- Les accès sont restreints aux utilisateurs authentifiés.
- Le système applique automatiquement une règle de **fidélité** : 1 crédit offert (0.50€) tous les 10 articles achetés.
