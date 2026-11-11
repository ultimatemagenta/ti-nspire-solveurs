# Installer les classeurs sur une TI-Nspire

Ce guide sert à mettre les solveurs sur ta calculatrice **à la main**, avec le logiciel de Texas Instruments. Aucune ligne de commande n'est nécessaire.

## 1. Ce qu'il te faut

| Élément | Détail |
|---|---|
| Calculatrice | TI-Nspire **CX II** ou **CX II CAS**. Les classeurs ont été testés sur une **TI-Nspire CX II CAS**. Le solveur de maths (`solveur.tns`) a besoin du **CAS**. Le classeur de compta (`compta.tns`) n'utilise pas le CAS. |
| Système de la calculatrice | Un OS récent (5.x ou plus). Le classeur `maths1.tns` en Python demande un OS avec Python, soit 5.2 ou plus. Pour connaître ta version : `on` → **5 Paramètres** → **4 À propos**. |
| Câble | Le câble USB fourni avec la calculatrice (USB-A ou USB-C vers mini-USB). |
| Logiciel sur l'ordinateur | Au choix (Windows ou macOS) : **TI-Nspire CX Student Software** (payant, avec une période d'essai), **TI-Nspire CX Premium Teacher Software**, ou **TI-Nspire Computer Link Software** (gratuit, qui suffit pour transférer). Tous se téléchargent sur le site éducation de Texas Instruments (education.ti.com). |

## 2. Télécharger les classeurs

Les fichiers prêts à installer sont dans le dossier [`classeurs/`](classeurs/) du dépôt :

| Fichier | Contenu |
|---|---|
| `compta.tns` | Comptabilité : aide-mémoire, réserves latentes (37), compte de résultat et seuil de rentabilité (44), analyse de bilan et ratios (51), trésorerie (57), coûts (59), finance (hors cours) |
| `solveur.tns` | Maths 1 : résolution automatique, analyse de fonction, factorisation, vecteurs, problèmes A et B, calcul littéral |
| `maths1.tns` | Maths 1, première version en Python (facultatif) |

Pour chaque fichier :
1. Clique sur son nom dans le dossier `classeurs/` sur GitHub.
2. Clique sur le bouton **Download raw file** (icône de flèche vers le bas, en haut à droite de la page).
3. Enregistre-le, par exemple dans `Téléchargements`. Garde bien l'extension **`.tns`** : n'ouvre pas le fichier et ne le renomme pas.

Pour tout prendre d'un coup : sur la page d'accueil du dépôt, clique **Code** → **Download ZIP**, puis décompresse l'archive. Les classeurs sont dans `classeurs/`.

## 3. Transférer sur la calculatrice

Allume la calculatrice et branche-la à l'ordinateur avec le câble. Ferme les classeurs ouverts sur la calculatrice : un classeur ouvert ne peut pas être remplacé.

### Méthode A — Glisser-déposer (tous les logiciels TI)
1. Ouvre le logiciel TI.
2. Ouvre l'explorateur des unités :
   - **Student / Teacher Software** : dans la colonne de gauche (« Boîte d'outils Classeurs »), clique sur l'icône **Explorateur de contenu** (le dossier jaune, la dernière icône). Le panneau du bas, « Unités TI-Nspire CX connectées », affiche ta calculatrice.
   - **Computer Link** : la fenêtre principale affiche directement ta calculatrice.
3. Si la calculatrice n'apparaît pas, voir la section 6.
4. Double-clique sur ta calculatrice pour voir ses dossiers.
5. Depuis l'Explorateur Windows (ou le Finder), fais **glisser** `compta.tns` (puis les autres) dans la liste des fichiers de la calculatrice. Pose-le à la racine ou dans le dossier de ton choix.
6. Si le logiciel signale que le fichier existe déjà, réponds **Oui** pour le remplacer (mise à jour).

### Méthode B — Ouvrir puis enregistrer sur l'unité (Student / Teacher Software)
1. **Fichier → Ouvrir un classeur…** et choisis `compta.tns`. Le menu « Compta – solveur » s'affiche dans la fenêtre : le classeur fonctionne aussi sur l'ordinateur, ce qui permet de l'essayer.
2. **Fichier → Enregistrer sur l'unité…**
3. Dans la fenêtre, **double-clique** sur ta calculatrice (par ex. « TI-Nspire CX II CAS »), puis choisis le dossier.
4. Laisse le nom `compta.tns` et clique **Enregistrer**. Réponds **Oui** si le fichier existe déjà.

Répète la méthode choisie pour `solveur.tns` et `maths1.tns`.

## 4. Lancer un solveur sur la calculatrice
1. Touche **`home`** (maison, ou `on`) → **2 Mes classeurs**.
2. Ouvre `compta` (ou `solveur`) avec **`enter`**. Le menu s'affiche directement, il n'y a pas de programme à lancer.
3. Pour `maths1` (Python) : ouvre le classeur, puis appuie sur **`ctrl`** + **`R`** pour exécuter le script et afficher le menu.

### Touches
| Écran | Touches |
|---|---|
| Menu | **▲▼** choisir, **`enter`** ouvrir, chiffre **1-9** accès direct, **`esc`** menu précédent |
| Saisie guidée | La question rappelle la composition du poste (« Liquidités = caisse + poste + banque … »). La valeur proposée vient d'un exercice corrigé. **`enter`** garde la valeur, on peut taper une somme (`35+30`), **`<`** revient à la question précédente, **`!`** valide tout le reste par défaut, **`esc`** annule. |
| Saisie libre (maths) | **◄►** déplacer le curseur, **▲▼** rappeler les saisies précédentes, **`enter`** valider |
| Résultat | **▲▼** défiler, **◄►** page par page, **`enter`** ou **`esc`** retour au menu |

Chaque solveur s'ouvre avec les données d'un exercice corrigé : **`enter`** jusqu'au bout montre directement un exemple complet. L'entrée « Historique des résultats » rouvre les derniers résultats.

## 5. Mettre à jour
Télécharge la nouvelle version du `.tns` (section 2) et transfère-la (section 3) en acceptant de **remplacer** l'ancienne. Ferme d'abord le classeur sur la calculatrice.

## 6. Problèmes fréquents
| Problème | Solution |
|---|---|
| La calculatrice n'apparaît pas dans le logiciel | Allume-la et quitte le classeur ouvert. Change de câble ou de port USB (certains câbles ne font que charger). Redémarre le logiciel. Sous Windows, le pilote est installé avec le logiciel TI : réinstalle-le si besoin. |
| « Le fichier est ouvert sur l'unité » / remplacement refusé | Sur la calculatrice, ferme le classeur (`ctrl` + `home` → Fermer, ou ouvre un autre classeur), puis recommence. |
| Le classeur s'ouvre sur une page blanche ou un message d'erreur Lua | L'OS de la calculatrice est trop ancien : mets-le à jour avec le logiciel TI (**Outils → Installer l'OS** ou l'assistant de mise à jour). Le solveur de maths exige une version **CAS**. |
| `maths1` n'affiche rien | Il faut lancer le script : **`ctrl`** + **`R`** dans la page Python. |
| Les classeurs ont disparu ou sont grisés | Le **mode examen** (Press-to-Test) bloque temporairement les classeurs existants. Ils réapparaissent quand tu quittes le mode examen. |
| Le texte déborde ou semble coupé | Les écrans sont prévus pour l'écran de la calculatrice (318 × 212). Dans le logiciel, passe en vue unité (**Afficher → Aperçu du classeur → Calculatrice**) pour voir le rendu réel. |

## 7. Pour aller plus loin (facultatif)
Pour modifier les solveurs, les sources Lua sont dans `GESTION_ENTREPRISE/calculatrice/lua/` et `MATH_1/calculatrice/lua/`. La reconstruction des `.tns` et les tests sur PC sont expliqués dans le [README](README.md). Cette étape demande Python, mais l'installation décrite ci-dessus n'en a pas besoin.

Rappel : vérifie le règlement de ton examen avant d'utiliser ces classeurs pendant une épreuve. Certains tests n'autorisent qu'une calculatrice simple, sans CAS ni programme.
