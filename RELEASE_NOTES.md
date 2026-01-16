# 📋 Journal des Modifications - Café BDA

## [6.11.4] - Gestion Stocks 📦
*   **Nouveau Produit** : Ajout de nouvelles références de cafés ou produits directement depuis l'onglet Stocks, sans passer par le mode administrateur.

## [6.11.3] - Plus de Stats 💰
*   **Revenu Total** : Suivi du chiffre d'affaires estimé (basé sur 0,50€ / café).
*   **Fidélité** : Visualisation du nombre total de cafés offerts aux étudiants.

## [6.11.2] - Détails Graphiques 📈
*   **Courbe des Ventes** : Affichage de la date précise dans l'infobulle au survol ou au clic sur le graphique "Évolution des Ventes".

## [6.11.1] - Correctif Stats 🔧
*   **Correction des Crédits** : Résolution du bug de calcul des crédits lorsque les valeurs contiennent des symboles (€) ou des espaces.

## [6.11.0] - Statistiques 📊
Introduction d'un nouvel onglet d'analyse pour les administrateurs :
*   **KPIs en direct** : Total cafés servis et montant total des crédits rechargés.
*   **Graphiques Interactifs** : Répartition des moyens de paiement, Top Cafés et courbe d'évolution temporelle.

## [6.10.6] - Historique Admin
*   **Historique des Actions** : Nouvel onglet de suivi chronologique (Inscriptions, Crédits, Commandes).
*   **Détails des opérations** : Suivi précis des modifications nécessitant un onglet `Logs` dans Google Sheets.

## [6.10.5] - Améliorations Admin
*   **Ajout de Ligne** : Insertion directe de nouvelles lignes dans la table active.
*   **Navigation** : Interface épurée masquant les onglets utilisateur en mode admin.
*   **Édition Paiements** : Édition directe de la configuration "Lydia".

## [6.10.4] - Nettoyage Administrateur 🧹
*   **Suppression de Ligne** : Possibilité de supprimer des entrées (étudiants, transactions, stocks) avec confirmation sécurisée.
*   **Accès Rapide** : Nouveau bouton pour quitter instantanément le mode administrateur.

## [6.10.3] - Intégrité & Précision 🎯
*   **Indexation Absolue** : Garantie que les modifications ciblent la bonne ligne, même si le tableau est trié ou filtré.
*   **Recherche Unifiée** : Synchronisation des barres de recherche avec bascule automatique vers le tableau concerné.

## [6.10.2] - Édition Intelligente 🧠
*   **Éditeurs Adaptés** : Calendrier pour les dates, listes déroulantes pour les moyens de paiement et clavier numérique pour les prix/quantités.

## [6.10.1] - Sécurité & Intégrité 🔐
*   **Code PIN Admin** : Accès protégé par PIN (modifiable via Google Sheets).
*   **Verrouillage des Formules** : Protection automatique des cellules contenant des calculs logiques.

## [6.10.0] - Mode Administrateur & Édition 🛠️
*   **Mode Édition** : Activation via paramètres avec changement de thème visuel (**Orange**).
*   **Édition Totale** : Modification directe de n'importe quelle cellule dans les tableaux.

## [6.9.0 - 6.9.3] - Gestion Avancée des Comptes 🔑
*   **Changement de Compte** : Option pour révoquer l'accès Google et changer d'utilisateur.
*   **Authentification Robuste** : Migration vers une infrastructure plus stable et sécurisée.

## [6.07] - Module Paiements
*   **Paiements** : Intégration des QR Codes Lydia.
*   **Interface** : Traduction intégrale de l'application en français.
