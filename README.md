# Gestion Café BDA

Une application Flutter pour la gestion des stocks et des ventes de la cafétéria d'une association.

## Fonctionnalités

- **Authentification Google :** Connexion sécurisée avec un compte Google pour accéder aux données.
- **Gestion des données :** Visualisez et gérez les données des feuilles de calcul Google Sheets.
- **Opérations CRUD :**
  - Enregistrer de nouveaux étudiants.
  - Ajouter des crédits café aux comptes des étudiants.
  - Enregistrer les nouvelles commandes.
- **Recherche :** Recherchez facilement des étudiants par nom, prénom ou numéro d'étudiant.
- **Interface réactive :** L'interface utilisateur est mise à jour en temps réel en fonction des données de la feuille de calcul.

## Pour commencer

### Prérequis

- [Flutter](https://flutter.dev/docs/get-started/install)
- Un compte Google avec l'API Google Sheets activée.
- Un projet Google Cloud avec des identifiants OAuth 2.0 (ID client et secret client).

### Installation

1. **Clonez le dépôt :**
   ```sh
   git clone https://github.com/loris2p/cafe_bda.git
   cd cafe_bda
   ```

2. **Installez les dépendances :**
   ```sh
   flutter pub get
   ```

### Configuration

1. **Créez un fichier `.env`** à la racine du projet et ajoutez les variables d'environnement suivantes :

   ```
   GOOGLE_CLIENT_ID=<VOTRE_ID_CLIENT_GOOGLE>
   GOOGLE_CLIENT_SECRET=<VOTRE_SECRET_CLIENT_GOOGLE>
   GOOGLE_SPREADSHEET_ID=<VOTRE_ID_DE_FEUILLE_DE_CALCUL>
   ```

   - `GOOGLE_CLIENT_ID` et `GOOGLE_CLIENT_SECRET` : Vos identifiants OAuth 2.0 provenant de la console Google Cloud.
   - `GOOGLE_SPREADSHEET_ID` : L'ID de votre feuille de calcul Google Sheets.

2. **Configurez les feuilles de calcul :** Assurez-vous que votre feuille de calcul Google Sheets contient les onglets suivants :
   - `Étudiants`
   - `Crédits`
   - `Paiements`
   - `Stocks`

## Utilisation

Pour lancer l'application, exécutez la commande suivante :

```sh
flutter run
```

## Structure du projet

Le projet est structuré pour séparer les préoccupations, ce qui le rend plus facile à maintenir et à faire évoluer.

- **`lib/`** : Contient tout le code Dart de l'application.
  - **`main.dart`** : Le point d'entrée de l'application.
  - **`screens/`** : Contient les widgets de l'interface utilisateur qui représentent les écrans de l'application.
    - `google_sheets_screen.dart` : L'écran principal de l'application.
  - **`widgets/`** : Contient des widgets réutilisables utilisés dans l'ensemble de l'application.
    - `data_table_widget.dart` : Affiche les données sous forme de tableau.
    - `registration_form.dart`, `credit_form.dart`, `order_form.dart` : Formulaires pour ajouter de nouvelles données.
  - **`providers/`** : Contient les fournisseurs de gestion d'état (`ChangeNotifier`).
    - `auth_provider.dart` : Gère l'authentification.
- `cafe_data_provider.dart` : Gère les données métier (Étudiants, Crédits...).
  - **`services/`** : Contient les services qui interagissent avec des API externes.
    - `google_sheets_service.dart` : Un service générique pour interagir avec l'API Google Sheets.
  - **`repositories/`** : Contient les dépôts qui encapsulent la logique métier.
    - `cafe_repository.dart` : Gère la logique métier liée à la cafétéria.
  - **`utils/`** : Contient des classes et des fonctions utilitaires.
    - `constants.dart` : Contient les constantes de l'application.
- **`assets/`** : Contient les ressources statiques, comme les icônes et les images.
- **`.env`** : Fichier de configuration pour les variables d'environnement (doit être créé).
- **`pubspec.yaml`** : Définit les métadonnées et les dépendances du projet.