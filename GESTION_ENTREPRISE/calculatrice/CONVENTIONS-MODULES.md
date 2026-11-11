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
- API du socle (fonctions locales déjà visibles) :
  - document : `vider()`, `T(titre)`, `X(texte)`, `G(texte gris)`, `A(alerte rouge)`, `R(avant, expr, apres)` (résultat vert ; pour du texte pur : `R("texte", "", "")`), `montrer(titreEcran)` ;
  - **tableaux** : `GRILLE(titre, lignes, {entetes = {"", "N", "N-1"}})`, chaque ligne `{"libellé", "montant1", "montant2", gras = true, trait = true, fond = true, retrait = 1}` ;
  - montants : `fmt(x, dec)` → `12'500` (apostrophe suisse, signe −) ;
  - saisie : `demander(message, function(texte) … end, defaut, opts)` ; `opts` facultatif : `titre` (bandeau), `aide` (texte coupé en lignes
    sous la question ; police réduite puis « … » s'il ne tient pas), `erreur` (ligne rouge), `note` (ligne grise), `vide = true` (ENTER accepte un champ vide), `pied` ;
  - **questionnaire guidé (à préférer)** : `COMMUN.questionnaire(titre, champs, function(v, brut, rep) … end)` pose une question par champ, pré-remplie
    avec `defaut` ; `champs = {{cle = "liq", lib = "Liquidités", defaut = "35+30", aide = "Liquidités = caisse + poste + banque …", opt = true, texte = true, valider = f}, …}`.
    Touches affichées dans l'invite : ENTER garde, `<` (seul ou en fin de saisie) = question précédente, `!` = tout le reste par défaut, vide (ou `-`) = ignoré.
    Expressions acceptées (`15+10+30`) ; `v._txt[cle]` garde le texte saisi (pour réécrire la composition : `COMMUN.exprTexte("35+30")` → « 35 + 30 »).
    `brut` = « cle=texte;… », donc un solveur qui lit `COMMUN.lireChamps(brut, champs)` marche aussi avec des arguments directs dans les tests ;
  - formulaire une ligne (ancien) : `COMMUN.formulaire(titre, champs, function(v, brut) … end)` (saisie « ca=1000000;cv=600000 », `%` accepté, `12'500` accepté) ;
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
