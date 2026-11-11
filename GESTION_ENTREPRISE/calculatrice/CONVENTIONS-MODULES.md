# Classeur compta TI-Nspire : conventions pour écrire un module

Plan général : `PLAN-CLASSEUR-COMPTA.md` (même dossier). Décisions de l'utilisateur (10.11.2026) :
**tous les solveurs**, un seul mode (tout afficher d'un coup), **toutes les extensions intégrées** (une seule version complète,
hors-cours marqué « (hors cours) » dans les titres), deux classeurs avec socle commun (`tools/nspire/`).

## Assemblage
- Fichiers : `GESTION_ENTREPRISE/calculatrice/lua/NN_nom.lua`, assemblés par ordre alphabétique entre `tools/nspire/socle_debut.lua`
  et `tools/nspire/socle_fin.lua` en un seul script Lua (API Lua TI-Nspire 2.4, Lua 5.1/5.2 : pas de `goto`, pas d'entiers `//`).
- Construire : `python GESTION_ENTREPRISE/calculatrice/construire.py` (écrit `compta.tns` + `compta.lua`).
- Tester sans calculatrice : `PYTHONIOENCODING=utf-8 python tools/nspire/test_pc.py GESTION_ENTREPRISE/calculatrice/compta.lua NOM_SOLVEUR arg1 arg2 …`
  imprime le document produit et simule le dessin. **Teste chaque solveur sur les données d'un corrigé du prof et compare les chiffres.**
- Parcours comme sur la calculatrice (menus + questions successives) : `… test_pc.py GESTION_ENTREPRISE/calculatrice/compta.lua --menu 4,1 [saisie1 saisie2 …]`
  (`=` = ENTER sans rien changer ; saisies épuisées = ENTER partout ; chaque invite est imprimée, « DEBORDE » si elle ne tient pas à l'écran).
- **Ne pilote jamais l'interface graphique du PC** (pas de logiciel TI, pas de clics) : l'utilisateur travaille dessus.

## Règles de code (impératives)
- Tout le module dans **un bloc `do … end`** (limite de 200 variables locales du script principal). Rien de local hors du bloc.
- Exposer les solveurs pour les tests : `SOLVEURS.nomCourt = fonction` (arguments = chaînes, comme une saisie).
- Ajouter le menu : `table.insert(MENUS_COMPTA, {ordre = N, titre = "…", items = {{"libellé", function() … end}, …}})`.
  Ordres : 10 aide-mémoire, 37 réserves latentes, 44 résultat/seuil, 51 analyse de bilan, 57 trésorerie, 59 coûts, 70 finance (hors cours).
- **9 entrées au plus par menu** (un écran, touches 1-9). Au-delà : sous-menu `COMMUN.sousMenu("libellé", "titre", {entrées…})`
  (jamais un `MENU = …` construit dans une fonction : l'index ne le verrait pas).
- **Libellés** : les mots des consignes du prof (« Point mort en quantité », « Prix minimum, baisse en % »), pas le nom de l'exercice modèle
  (« Licence », « Lot ») ni un numéro d'article ; 34 caractères au plus.

## Index de recherche (obligatoire pour tout nouveau solveur)
Dans n'importe quel menu, une lettre ouvre « Trouver un solveur » (moteur `CHERCHE` du socle, `tools/nspire/socle_debut.lua`) ; les
chiffres 1-9 restent au menu. Le moteur lit la table globale `INDEX_SOLVEURS`, au format commun aux classeurs compta et maths :
`{titre = "…", chemin = "2·3·1", forts = {"…"}, mots = {"…"}, si = "…", ouvrir = function() … end}`.
- Dans le classeur compta, on ne l'écrit pas à la main : chaque **entrée de menu** porte trois champs, et `99_menu.lua` en tire
  `INDEX_SOLVEURS` avec le chemin calculé (il suit donc les menus) :
  `{"Ducroire", function() … end, forts = "ducroire", mots = "creance client provision risque perte", si = "seul poste : le ducroire (x % des créances)"}`.
- `forts` (3 points par mot tapé qui y colle) : 1 à 5 mots qui ne désignent que ce solveur, ou le mot de sa famille (`seuil`).
  `mots` (1 point) : mots de la consigne partagés avec d'autres solveurs (`benefice`, `stock`, `tableau`), sigles (`pm`, `rl`, `fp`, `can`).
  Les mots du libellé comptent d'office comme `mots`.
- Écrire des **radicaux en minuscules, sans accents** : `maxim` couvre maximale et maximum, `graph` couvre graphiquement, `distribu`
  couvre distribués. Sigles de 2 lettres : égalité stricte. Verbes vides (calculer, déterminer, trouver, donner) ignorés ; les verbes qui
  orientent (dresser, établir, présenter, journaliser, montrer, comparer, apprécier) vont dans l'index.
- `si` : 45 caractères au plus, réponse à « je choisis celui-ci quand… » (« un seul poste », « plusieurs entreprises »).
- Prendre les mots dans les **consignes réelles** (`examens/*/txt/enonce.md`, `exercices/chap-*/txt/enonce-*.md`), puis ajouter la consigne
  à `consignes-test.txt` (même dossier) et vérifier :
  `PYTHONIOENCODING=utf-8 python tools/nspire/test_pc.py GESTION_ENTREPRISE/calculatrice/compta.lua --cherche-tout GESTION_ENTREPRISE/calculatrice/consignes-test.txt`
  (rang de chaque attendu, totaux « en tête » / « dans les 3 premiers », chemins de l'index rejoués dans les menus ; échoue si un attendu
  sort des 3 premiers). Une saisie isolée : `… test_pc.py …/compta.lua --cherche "max stock"` (top 5, frappe simulée, ENTER, esc).
- API du socle (fonctions locales déjà visibles) :
  - document : `vider()`, `T(titre)` ou `T(titre, repere)` (repère gris en petit à droite du titre, ou dessous), `X(texte)` (`
` = retour à la ligne dans le même paragraphe), `G(texte gris)`, `A(alerte rouge)`, `R(avant, expr, apres)` (résultat vert ; pour du texte pur : `R("texte", "", "")`), `montrer(titreEcran)` ;
  - **tableaux** : `GRILLE(titre, lignes, {entetes = {"", "N", "N-1"}})`, chaque ligne `{"libellé", "montant1", "montant2", gras = true, trait = true, fond = true, retrait = 1}` ;
  - montants : `fmt(x, dec)` → `12'500` (apostrophe suisse, signe −) ;
  - saisie : `demander(message, function(texte) … end, defaut, opts)` ; `opts` facultatif : `titre` (bandeau), `aide` (texte coupé en lignes
    sous la question ; police réduite puis « … » s'il ne tient pas), `erreur` (ligne rouge), `note` (ligne grise), `vide = true` (ENTER accepte un champ vide), `pied` ;
  - **questionnaire guidé (à préférer)** : `COMMUN.questionnaire(titre, champs, function(v, brut, rep) … end)` pose une question par champ, pré-remplie
    avec `defaut` ; `champs = {{cle = "liq", lib = "Liquidités", defaut = "35+30", aide = "Liquidités = caisse + poste + banque …", opt = true, texte = true, valider = f}, …}`.
    Touches affichées dans l'invite : ENTER garde, `<` (seul ou en fin de saisie) = question précédente, `!` = tout le reste par défaut, vide (ou `-`) = ignoré.
    Expressions acceptées (`15+10+30`) ; `v._txt[cle]` garde le texte saisi (pour réécrire la composition : `COMMUN.exprTexte("35+30")` → « 35 + 30 »).
    `brut` = « cle=texte;… », donc un solveur qui lit `COMMUN.lireChamps(brut, champs)` marche aussi avec des arguments directs dans les tests ;
  - **Règle (11.11.2026, exigence de l'utilisateur) : une donnée = un champ. Saisie sur une ligne interdite** dans tout menu : pas de
    « clé=valeur;… », pas de listes séparées par `;` / `,` / espaces, pas de « nom=montant » dans un seul champ, pas de tableau tapé en une ligne.
    Chaque question a un `lib` clair (mots du prof), une `aide` d'une ligne (d'où vient la donnée, comment elle se calcule), un `defaut` = valeur du
    corrigé du prof ; facultatif = `opt = true` (vide = ignoré). `COMMUN.formulaire` a été supprimé.
  - **Données en nombre variable** (comptes, titres, années, sections, mois, flux…) : `COMMUN.questionnaire(titre, COMMUN.repeter(segments), suite)`.
    `segments` = champs simples et groupes dans l'ordre ; groupe = `{groupe = "Compte", n = {cle = "n", lib = "Combien de comptes ?", defaut = "4",
    max = 12, min = 1, aide = "…"}, champs = function(j, val) return {{cle = "nom", …}, {cle = "vci", …}} end}` → « Combien de comptes ? », puis
    pour chaque élément ses champs un par un, posés « Compte 2/4 — valeur réelle au 1.1 » (clé `vci_2`). `nombre = function(val) … end` à la place
    de `n` : nombre tiré des réponses précédentes, sans question ; `brut = true` : libellés gardés tels quels. Une donnée à plusieurs colonnes
    (N-1 et N, début / fin) = une question par cellule. Tout est un seul questionnaire : `<` remonte jusqu'à « Combien », `!` garde les défauts
    pour tout le reste. Lecture : `COMMUN.elements(v, n, {"nom", "vci"})`, `COMMUN.entier(v.n, 0)`, `COMMUN.lu(val, cle, defaut)` dans les champs.
  - Les **solveurs** gardent leur format interne (« cle=valeur;… », « Nom:v1/v2 », …) pour les tests en arguments directs ; le questionnaire
    du menu le reconstruit (`COMMUN.bloc("2/3")` → « (2/3) » pour une valeur qui contient un séparateur). Contrôle après modification : ENTER
    partout dans `--menu` doit redonner exactement le document d'avant.
  - `COMMUN.num(s)`, `COMMUN.pct(x)` → « 14.44 % », `COMMUN.dec2(x)`, `COMMUN.calc(nom, formule, application, resultat)`,
    `COMMUN.commentaire(valeur, norme, ok, consequence)`.
  - Ne PAS utiliser `M(...)` avec des formules (pas de CAS en compta) : écrire les formules en texte (`X`, `calc`).
- Écran de 318 × 212 px : libellés courts dans les grilles (≤ 22 caractères), 1 à 3 colonnes de montants.

## Contenu attendu de chaque solveur
- Titre, puis « Méthode » en gris (pourquoi et comment, d'après le corrigé du prof, en citant l'exercice modèle « modèle : 44.16 »).
- Chaque calcul : formule écrite avant l'application numérique (règle du prof, `GESTION_ENTREPRISE/CLAUDE.md`), puis résultat.
- Tableaux comptables dans les grilles (CR à 2 degrés, bilans avec sous-totaux, tableau des RL du prof…).
- Commentaires rédigés pour les ratios (valeur, valeur indicative du manuel, conséquence).
- Arrondis comme le prof (quantités du seuil arrondies à l'unité supérieure, ratios en % ou en décimal comme dans la liste Profil M).
- Données par défaut = celles d'un exercice corrigé du prof (indiquer lequel), pour pouvoir vérifier tout de suite.
