# Solveurs TI-Nspire CX II (Lua) — compta et maths

Classeurs TI-Nspire écrits pendant mes révisions à la HEIG-VD : ils déroulent la résolution complète d'exercices types,
avec les formules écrites avant l'application numérique, les étapes intermédiaires et des commentaires rédigés.

| Classeur | Dossier | Contenu |
|---|---|---|
| `compta.tns` | `GESTION_ENTREPRISE/calculatrice/` | Comptabilité de gestion (manuel CREME-CIIP, profil M) : aide-mémoire, réserves latentes et évaluation au bilan, compte de résultat à degrés et seuil de rentabilité, analyse de bilan (26 ratios, comparaison d'entreprises), flux de trésorerie, comptabilité analytique, finance (hors cours). Sans CAS. |
| `solveur.tns` | `MATH_1/calculatrice/lua/` | Mathématiques 1 : analyse de fonctions rationnelles (domaine, zéros, pôles, asymptotes, bijection, graphe), factorisation détaillée, vecteurs (problèmes complets), calcul littéral. Utilise le CAS via `math.evalStr`. |
| `maths1.tns` | `MATH_1/calculatrice/` | Première version en Python TI (modules `*.py`). |

Socle commun (interface, menus, saisie guidée, rendu des tableaux et graphes) : `tools/nspire/socle_debut.lua` et `socle_fin.lua`.

## Construire
- Compta : `python GESTION_ENTREPRISE/calculatrice/construire.py` → `compta.tns` (modules `lua/NN_*.lua` assemblés entre les deux moitiés du socle).
- Maths : `python MATH_1/calculatrice/construire.py` (Python) ; le solveur Lua se construit avec `construire_lua` de `MATH_1/calculatrice/construire_tns.py`.
- `construire_tns.py` est un portage Python de la partie classeur de [Luna](https://github.com/ndless-nspire/Luna) (MPL 1.1) ; dépend de `cryptography`.

Envoi : ouvrir le `.tns` dans *TI-Nspire CX CAS Student Software*, puis **Fichier → Enregistrer sur l'unité…**

## Tester sans calculatrice
`PYTHONIOENCODING=utf-8 python tools/nspire/test_pc.py GESTION_ENTREPRISE/calculatrice/compta.lua NOM_SOLVEUR args…`
ou `… --menu 4,1` pour parcourir un menu et répondre aux questions (dépend de `lupa`). Le banc simule l'API Lua TI-Nspire,
imprime le document produit et signale ce qui déborde de l'écran.

Conventions pour écrire un module : `GESTION_ENTREPRISE/calculatrice/CONVENTIONS-MODULES.md`.

Ce dépôt est un miroir des dossiers « calculatrice » de mon dépôt de cours (privé), mis à jour par `tools/nspire/publier_github.py`.
