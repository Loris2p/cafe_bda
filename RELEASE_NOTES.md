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