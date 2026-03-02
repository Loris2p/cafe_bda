# Plan de Migration : Google Sheets vers Firebase (Firestore & Auth)

Ce document détaille la stratégie de migration du backend de l'application Café BDA vers Firebase, en garantissant la gratuité totale (Plan Spark) et la fiabilité des données.

## 🎯 Objectifs
1.  **Fiabilité :** Remplacer Google Sheets par Cloud Firestore.
2.  **Sécurité :** Migrer l'authentification vers Firebase Auth.
3.  **Zéro Coût :** Utilisation exclusive du plan gratuit Firebase Spark (pas de CB requise).
4.  **Performance :** Réduire la charge de travail des appareils via des requêtes indexées.
5.  **Intégrité :** Interdire les modifications hors-ligne pour garantir la cohérence en temps réel.

---

## 🏗️ Architecture Cible

### 1. Authentification (Firebase Auth)
*   Migration des comptes administrateurs/utilisateurs.
*   Gestion des sessions sécurisée et native à Flutter.

### 2. Base de données (Cloud Firestore)
Structure proposée (Collections/Documents) :
*   `config/app` : Paramètres globaux, versions, seuils.
*   `students/` : Collection des étudiants (remplace l'onglet Students).
    *   `id` : Document ID (ex: email ou matricule).
    *   `nom`, `prenom`, `solde`, `historique_achats[]`.
*   `transactions/` : Journal global des ventes et rechargements.
*   `products/` : Liste des articles et tarifs.

---

## 📋 Étapes de Réalisation

### Phase 1 : Infrastructure & Configuration
- [ ] Création du projet sur la Console Firebase.
- [ ] Configuration de FlutterFire (`firebase_core`, `cloud_firestore`, `firebase_auth`).
- [ ] Désactivation de la persistence locale Firestore (pour forcer le mode en ligne).
- [ ] Définition des `Security Rules` Firestore pour protéger l'accès aux données.

### Phase 2 : Migration des Données
- [ ] Développement d'un script de migration (`lib/utils/migration_script.dart`).
- [ ] Lecture des données actuelles depuis Google Sheets.
- [ ] Injection structurée dans Cloud Firestore.
- [ ] Validation de l'intégrité (totaux, soldes, historiques).

### Phase 3 : Refonte du Backend
- [ ] Création de `lib/services/firebase_service.dart`.
- [ ] Adaptation de `lib/repositories/cafe_repository.dart` pour utiliser Firestore au lieu de Sheets.
- [ ] Mise à jour de `lib/providers/auth_provider.dart` avec Firebase Auth.
- [ ] Suppression progressive des dépendances Google Sheets.

### Phase 4 : Interface & Expérience Utilisateur
- [ ] Ajout d'un vérificateur de connexion avant chaque transaction.
- [ ] Mise à jour des formulaires (`OrderForm`, `CreditForm`, `RegistrationForm`).
- [ ] Gestion des erreurs Firebase (ex: "Permission denied", "Network error").
- [ ] Adaptation de `StatsTab` pour utiliser les agrégations Firestore (plus rapide).

### Phase 5 : Tests & Livraison
- [ ] Tests unitaires des nouveaux services.
- [ ] Tests d'intégration (flux complet Achat -> Mise à jour solde -> Historique).
- [ ] Mise à jour de `README.md` et des instructions de déploiement.

---

## ⚡ Contraintes Techniques & Performance
*   **Mode "Strict Online" :** Utilisation de `Transaction` Firestore pour les achats afin d'éviter les conflits si deux personnes modifient le même solde simultanément.
*   **Lazy Loading :** On ne télécharge plus toute la base au démarrage. On récupère uniquement les données nécessaires à l'écran affiché.
*   **Payload réduit :** Firestore ne renvoie que les champs modifiés, économisant de la data pour les utilisateurs.

---

## 🛠️ Outils à utiliser
*   `firebase_cli` : Pour le déploiement des règles.
*   `flutterfire_cli` : Pour la configuration automatique du projet.
*   `connectivity_plus` : Pour détecter l'absence de réseau avant une action.
