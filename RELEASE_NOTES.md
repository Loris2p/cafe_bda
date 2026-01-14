# Version 6.11.0 - Statistiques 📊

Cette version introduit un tout nouvel onglet dédié à l'analyse de l'activité du café, accessible aux administrateurs.

### 📊 Tableau de Bord Statistiques
*   **KPIs en direct** : Visualisez instantanément le nombre total de cafés servis et le montant total des crédits rechargés.
*   **Graphiques Interactifs** :
    *   🥧 **Moyens de Paiement** : Répartition des ventes par méthode (Crédit, Espèces, Lydia...).
    *   📊 **Top Cafés** : Classement des produits les plus populaires.
    *   📈 **Évolution des Ventes** : Courbe temporelle des consommations pour suivre les tendances.
*   L'onglet **Stats** est disponible dans la barre de navigation lorsque le mode administrateur est actif.

# Version 6.10.6

### Fonctionnalités Admin
*   **Historique des Actions** : Ajout d'un nouvel onglet **Historique** accessible uniquement en mode administrateur.
    *   Suivi chronologique des actions effectuées (Inscriptions, Crédits, Commandes).
    *   Affichage des détails de chaque opération (Qui a fait quoi, montants, etc.).
    *   Nécessite la création d'un onglet `Logs` dans le Google Sheet.

# Version 6.10.5

### Fonctionnalités Admin
*   **Ajout de Ligne** : Ajout d'un bouton pour insérer une nouvelle ligne dans la table active (ex: "InfosPaiement").
*   **Navigation** : Masquage des onglets "Commander" et "Créditer" en mode administrateur.
*   **Édition Paiements** : L'onglet "Lydia" permet l'édition directe de la table de configuration des paiements.

### Correctifs
*   Correction de l'affichage de l'onglet admin sur grand écran.
*   Correction du chargement des en-têtes pour l'ajout de ligne.

# Version 6.10.4 - Nettoyage Administrateur 🧹

Cette mise à jour ajoute une fonctionnalité clé pour la gestion des données en **Mode Administrateur**, permettant de maintenir la base de données propre directement depuis l'application.

### 🗑️ Suppression de Ligne
Les administrateurs peuvent désormais supprimer une entrée obsolète ou erronée (étudiant, transaction, ligne de stock) directement depuis l'interface.
*   **Action Sécurisée** : Un bouton "Supprimer" (Corbeille) apparaît dans la colonne "Actions" lorsque le mode Admin est actif.
*   **Confirmation** : Une fenêtre de dialogue demande une confirmation explicite avant toute suppression définitive pour éviter les accidents.

### ⚡ Accès Rapide
*   **Quitter le Mode Admin** : Un nouveau bouton dans la barre d'outils permet de désactiver le mode administrateur en un clic, sans repasser par les paramètres.

# Version 6.10.3 - Intégrité & Précision 🎯

Cette mise à jour corrective résout un problème important de correspondance des données lors de l'utilisation des fonctions de tri et de recherche.

### 🛡️ Indexation Absolue
Désormais, peu importe si votre tableau est trié (ex: par solde) ou filtré (via la recherche), l'application garantit que la modification effectuée cible la bonne ligne dans le Google Sheets. Cette correction renforce également la **protection des formules**, qui ne peuvent plus être contournées via une vue filtrée.

### 🔍 Recherche Unifiée
Les deux barres de recherche (Accueil et Contextuelle) offrent maintenant les mêmes capacités : recherche intelligente, édition directe (si Admin) et sélecteurs adaptés. Si vous recherchez un étudiant depuis l'accueil, l'application bascule automatiquement sur le tableau pour vous permettre d'agir.

# Version 6.10.2 - Édition Intelligente 🧠

Cette mise à jour améliore considérablement le confort d'utilisation du **Mode Administrateur** en rendant l'édition des cellules plus intelligente et moins propice aux erreurs.

### ✨ Éditeurs Adaptés
Fini la saisie manuelle de texte pour tout ! L'application reconnaît désormais le type de données que vous modifiez :

*   📅 **Dates** : Un calendrier s'ouvre pour choisir la date (plus de soucis de format `JJ/MM/AAAA`).
*   🔻 **Listes** : Pour les "Moyens de Paiement", choisissez directement parmi les options valides (Lydia, Espèces, Crédit) dans une liste déroulante.
*   🔢 **Chiffres** : Le clavier numérique s'ouvre automatiquement pour les prix et les quantités.

# Version 6.10.1 - Sécurité & Intégrité 🔐

Cette mise à jour mineure renforce le **Mode Administrateur** introduit en 6.10.0 en ajoutant des couches de sécurité et de protection des données.

### 🔐 Sécurisation de l'Accès Admin
*   **Code PIN Obligatoire** : L'activation du mode administrateur nécessite désormais la saisie d'un code PIN (par défaut `1234`). Ce code peut être personnalisé directement dans l'onglet `Application` de votre Google Sheets (`admin_pin`).

### 🛡️ Protection des Calculs
*   **Verrouillage des Formules** : L'application détecte maintenant les cellules contenant des formules (comme les calculs de solde ou de fidélité) et empêche leur modification manuelle pour éviter de casser la logique du tableur.
*   **Indication Visuelle** : Les cellules non modifiables apparaissent en gris dans les tableaux.

### 🐛 Correctifs
*   Correction de bugs internes liés à la gestion des données.

# Version 6.10.0 - Mode Administrateur & Édition 🛠️

Cette version majeure introduit un **Mode Administrateur** complet pour faciliter la gestion et la correction des données directement depuis l'application, sans avoir besoin d'accéder au fichier Google Sheets.

### 👑 Nouveau Mode Administrateur

*   **Activation Simple** : Accessible via un interrupteur dans le menu Paramètres.
*   **Thème Visuel Distinct** : L'interface passe du violet à l'**orange** pour indiquer clairement que le mode édition est actif.
*   **Édition Totale** : Cliquez sur n'importe quelle cellule de n'importe quel tableau pour modifier sa valeur instantanément. Idéal pour corriger une erreur de saisie ou ajuster un stock rapidement.
*   **Recherche Contextuelle & Édition** :
    *   La barre de recherche s'adapte au tableau affiché (recherche dans les Stocks, les Paiements, etc.).
    *   Les résultats permettent d'accéder aux détails d'une ligne et de la modifier directement (via l'icône crayon).

# Version 6.9.3 - Gestion Avancée des Comptes 🔑

Cette mise à jour (v6.9.x) se concentre sur l'amélioration de l'expérience utilisateur lors de la connexion et de la gestion des comptes Google, tout en consolidant les bases techniques posées en v6.8.

### 🆕 Gestion Avancée du Compte (v6.9.0 - v6.9.3)

*   **Changement de Compte Facilité** :
    *   Ajout d'une option explicite pour **révoquer l'accès** Google dans les paramètres (icône 👤 barrée en haut à droite). Cela force l'affichage du sélecteur de compte lors de la prochaine connexion, idéal si vous utilisez plusieurs comptes Google.
*   **Déconnexion Intelligente** :
    *   **Déconnexion Rapide** (bouton en haut) : Déconnecte la session tout en gardant votre compte en mémoire pour une reconnexion rapide.
    *   **Révocation** (Paramètres / Erreur) : Nettoie complètement les accès.
*   **Gestion des Erreurs d'Accès** :
    *   Si vous vous connectez avec un compte non autorisé, la page d'erreur vous propose désormais directement de **changer de compte** ou de contacter le support.

### 🚀 Rappel des Mises à jour Techniques (v6.8.x)

*   **Authentification Robuste** : Migration vers la nouvelle infrastructure d'authentification Google (v7.0.0), plus sécurisée et stable sur Android/iOS.
*   **Performance & Dépendances** : Mise à jour de l'ensemble des composants internes (`googleapis`, `http`, etc.) pour garantir la pérennité de l'application.

### 🌍 Rappel v6.07

*   **Module Paiements** : Onglet dédié avec QR Codes Lydia.
*   **Interface** : Traduction française intégrale et correctifs d'affichage.