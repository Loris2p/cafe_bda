# Boutique BDA - Application de Gestion

Application Flutter pour la gestion de la boutique du BDA (Ventes, Rechargements, Étudiants).

## 🚀 Architecture Hybride

Cette application est conçue pour fonctionner sur **Windows, Linux, Android, iOS et Web** avec une base de données Firebase unique.

### Mode Desktop Native (Windows / Linux)
Utilise le package **Firedart** pour communiquer directement avec Firebase sans passer par les services Google Play (qui ne sont pas disponibles nativement sur PC).
- Authentification persistante via `SharedPreferences`.
- Accès Firestore direct.

### Mode Mobile & Web
Utilise les SDK officiels **FlutterFire**.

## 🛠 Scripts Utiles

### Mise à jour de la version
Un script Dart est disponible à la racine pour synchroniser la version du fichier `pubspec.yaml` avec celle stockée sur Firestore (utilisée pour le contrôle de version forcé).

```bash
dart update_version.dart <version>
# Exemple
dart update_version.dart 10.1.0
```

## 🔒 Sécurité & Administration

### Mode Administrateur
Le mode administrateur permet d'accéder aux statistiques, à la gestion des produits et à l'inscription de nouveaux Étudiants.
- L'activation est restreinte par email (voir `lib/main.dart`, classe `AdminProvider`).
- Les administrateurs peuvent inscrire des utilisateurs via le menu **Paramètres > Administration**.

### Inscription des utilisateurs
1. L'admin saisit le nom et l'email.
2. Un mot de passe aléatoire est généré.
3. Un lien `mailto:` pré-rempli est proposé pour envoyer les identifiants au nouveau étudiant.
4. L'utilisateur est **forcé** de changer son mot de passe lors de sa première connexion.

## 📦 Dépendances Principales
- `provider` : Gestion d'état.
- `firedart` : Firebase pour Desktop.
- `firebase_auth` & `cloud_firestore` : Firebase pour Mobile/Web.
- `fl_chart` : Graphiques statistiques.
- `package_info_plus` : Contrôle de version.
- `url_launcher` : Ouverture des mails et liens GitHub.
