# Plan et Bilan de Sécurité GitHub (café_bda)

## Résumé de l'état de sécurité (13 octobre 2026)

- **Alertes Dependabot** : **0 ouverte** (173 sur 173 résolues)
- **Alertes Secret Scanning** : **0 ouverte** (20 sur 20 résolues)
- **Code Scanning** : 0 alerte
- **Analyse Flutter (`flutter analyze`)** : 0 erreur / avertissement
- **Tests unitaires (`flutter test`)** : 10/10 tests réussis

---

## Détail des actions réalisées

### Étape 1 – Hygiène du dépôt Git ✅
- Ajout de `.env`, `.env.*`, `scripts/Jeton.sh`, `node_modules/` dans `.gitignore`.
- Sortie de l'index Git des ~43 000 fichiers `node_modules`.
- Création du gabarit `.env.example`.
- Suppression des workflows GitHub Actions Gemini inutilisés.

### Étape 2 – Traitement des alertes Secret Scanning (20/20) ✅
| Alertes | Type | Emplacement | Statut / Résolution |
|---|---|---|---|
| **#1, #2, #3** | Google OAuth Client ID | Ancien `.env` (V1 Sheets) | `revoked` (projet migré vers Firebase) |
| **#4, #6** | Google OAuth Client Secret | Ancien `.env` (V1 Sheets) | `revoked` (projet migré vers Firebase) |
| **#5** | Azure AD Application Secret | Ancien `.env` | `revoked` |
| **#7, #8, #9** | Google API Key (Firebase) | Ancien projet `cafe-bda` | `revoked` (remplacé par `boutique-bda`) |
| **#12** | Google API Key (iOS) | Ancien commit `boutique-bda` | `revoked` (remplacée par la clé active #20) |
| **#10, #11, #20** | Google API Key (Web, Android, iOS) | `lib/firebase_options.dart` | `false_positive` (clés publiques clientes `boutique-bda`, protégées par restrictions API et règles Firestore) |
| **#13 à #19** | Clés API / tokens de démo | `node_modules/` (gemini-cli) | `false_positive` (faux positifs de dépendances de test) |

### Étape 3 – Traitement des alertes Dependabot (173/173) ✅
- Suppression des manifests `package.json` et `package-lock.json` qui appartenaient à l'outil `gemini-cli` non utilisé dans le projet Flutter.
- Résolution automatique et immédiate de la totalité des 173 vulnérabilités Dependabot.

---

## Prochaines étapes envisageables (optionnelles)

1. **Suppression des résidus de configuration Gemini** :
   - Retirer les fichiers `.github/commands/gemini-*.toml` devenus obsolètes.
2. **Durcissement des règles Firestore** :
   - Affiner `firestore.rules` par collection si un contrôle d'accès granulaire est souhaité.
3. **Purge définitive de l'historique Git (`git filter-repo`)** *(optionnel)* :
   - Pour retirer complètement les traces historiques des anciens `.env` et `node_modules` des vieux commits (nécessite une réécriture d'historique et `git push --force`).
4. **Intégration** :
   - Fusionner la branche `patch_Security_quality` vers `release`.
