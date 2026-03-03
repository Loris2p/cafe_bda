# Schéma du Google Sheets - Café BDA

Ce document décrit la structure attendue du tableur Google Sheets utilisé par l'application. Le spreadsheet doit contenir les cinq feuilles (onglets) suivantes avec les noms exacts.

## 1. Étudiants
Cette feuille contient la base de données des clients et leurs soldes calculés.

| Colonne | Nom | Type | Description |
|---|---|---|---|
| A | Nom | Texte | Nom de famille de l'étudiant |
| B | Prénom | Texte | Prénom de l'étudiant |
| C | Num etudiant | Texte | Identifiant unique (clé primaire) |
| D | Cycle + groupe | Texte | Classe de l'étudiant |
| E | Solde Restant | Formule | Somme totale disponible (Crédit - Dépense + Bonus) |
| F | Total Crédité | Formule | Somme de tous les rechargements effectués |
| G | Total Consommé sur Crédit | Formule | Somme des achats payés par crédit |
| H | Total Payé Cash | Texte | Somme des achats payés en espèce/lydia/etc. |
| I | Fidélité (Bonus) | Formule | Nombre de cafés offerts (1 tous les 10 consommés) |

### Formules utilisées (Ligne 2)
*   **Solde Restant** : `=F2-G2+I2`
*   **Total Crédité** : `=SIERREUR(SOMME.SI(Credit[Numéro étudiant];C2; Credit[Nb de Cafés]); 0)`
*   **Total Consommé sur Crédit** : `=SIERREUR(SOMME.SI.ENS(Paiements[Nb de Cafés]; Paiements[Numéro étudiant]; C2; Paiements[Moyen Paiement]; "Crédit");0)`
*   **Total Payé Cash** : `=SIERREUR(SOMME.SI.ENS(Paiements[Nb de Cafés]; Paiements[Numéro étudiant]; C2; Paiements[Moyen Paiement]; "<>Crédit"); 0)`
*   **Fidélité** : `=ENT((G2+H2)/10)`

---

## 2. Credits
Historique des rechargements de compte.

| Colonne | Nom | Type |
|---|---|---|
| A | Date | Date (YYYY-MM-DD HH:mm:ss) |
| B | Responsable | Texte |
| C | Numéro étudiant | Texte |
| D | Nom | Texte |
| E | Prenom | Texte |
| F | Classe + Groupe | Texte |
| G | Valeur (€) | Nombre |
| H | Nb de Cafés | Nombre |
| I | Moyen Paiement | Texte (Lydia, Espèce, etc.) |

---

## 3. Paiements
Historique des consommations (commandes).

| Colonne | Nom | Type |
|---|---|---|
| A | Date | Date (YYYY-MM-DD HH:mm:ss) |
| B | Moyen Paiement | Texte (Crédit, Lydia, Espèce, etc.) |
| C | Nom de famille | Texte |
| D | Prénom | Texte |
| E | Numéro étudiant | Texte |
| F | Nb de Cafés | Nombre |
| G | Café pris | Texte |

---

## 4. Stocks
Gestion de la disponibilité des produits.

| Colonne | Nom | Type | Description |
|---|---|---|---|
| A | Nom | Texte | Nom du café / produit |
| B | Disponible | Booléen | `TRUE` ou `FALSE` |

---

## 5. Application
Configuration technique de l'application pour le contrôle de version.
Cette feuille fonctionne sous forme de paire Clé / Valeur.

| Colonne | Nom | Description |
|---|---|---|
| A | Clé | Nom du paramètre |
| B | Valeur | Valeur du paramètre |

### Valeurs attendues
| Clé | Exemple de Valeur | Description |
|---|---|---|
| `latest_version` | `1.5.0` | La version la plus récente disponible. |
| `min_compatible_version` | `1.4.0` | La version minimale requise pour fonctionner. Si l'app est en dessous, la mise à jour est forcée. |
| `download_url` | `https://github.com/...` | Lien vers le fichier à télécharger. |