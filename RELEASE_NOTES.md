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