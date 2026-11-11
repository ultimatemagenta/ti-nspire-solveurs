-- 10_aide.lua : aide-mémoire du classeur compta (consultation : tableaux vides, schémas, 26 ratios, formules,
-- définitions, articles du CO, pièges et barème, phrases de commentaire). Menu ordre 10.
-- Abréviations des sources : voir l'écran « Sources (abréviations) » (SOLVEURS.aide_sources).
do
  local E = "…"   -- case à compléter

  local function S(s) G("Source : " .. s) end

  -- ligne de grille : libellé + n cases vides ; o = options (gras, trait, fond, retrait) ou cases imposées
  local function lv(lib, n, o)
    local t = {lib}
    for i = 1, n do t[i + 1] = E end
    if o then for k, v in pairs(o) do t[k] = v end end
    return t
  end
  -- ligne de section (fond bleuté, sans montants)
  local function sec(lib) return {lib, gras = true, fond = true} end
  -- compte de résultat en 2 colonnes : charge (case à gauche) ou produit (case à droite)
  local function ch(lib, v, o) local t = {lib, v or E, ""}; if o then for k, x in pairs(o) do t[k] = x end end; return t end
  local function pr(lib, v, o) local t = {lib, "", v or E}; if o then for k, x in pairs(o) do t[k] = x end end; return t end

  -- enregistre un écran : exposé aux tests (SOLVEURS.aide_<cle>) et renvoyé comme entrée de menu
  local function ecr(lib, cle, titre, corps)
    local f = function() vider(); corps(); montrer(titre) end
    SOLVEURS["aide_" .. cle] = f
    return {lib, f}
  end
  local function sousMenu(lib, titre, items)
    return COMMUN.sousMenu(lib, titre, items)
  end

  ------------------------------------------------------------------ révision du 12.11
  local revision = ecr("Révision du 12.11 (test 2025)", "revision", "Test 2025 : 10 exercices", function()
    T("Test intermédiaire 2025 : 51,5 pts")
    G("Chapitres 37, 44, 51 (≤ p.65 imprimée). Matériel : écriture + calculatrice simple, pas de CAS, pas de résumé.")
    GRILLE("Exercices et points", {
      {"1 Résultat réel (RL)", "3", "37"},
      {"2 CR à 2 degrés", "7", "44"},
      {"3 Liquidités, couvert.", "6.5", "51"},
      {"4 Stock CO 960c", "1", "37"},
      {"5 Ratios 3 bilans", "9", "51"},
      {"6 Point mort quantité", "2", "44"},
      {"7 Tableau des RL", "8", "37"},
      {"8 Graphique du seuil", "5", "44"},
      {"9 Titres cotés / non", "3", "37"},
      {"10 Licence (44.16)", "7", "44"},
      {"Total", "51.5", "", gras = true, trait = true},
    }, {entetes = {"Exercice", "Pts", "Chap."}})
    X("Où regarder dans l'aide-mémoire : ex. 1 et 7 → Tableaux vides › Tableau des RL ; ex. 2 → CR à 2 degrés ; "
      .. "ex. 3 et 5 → Ratios + Phrases de commentaire ; ex. 4 et 9 → Stock, Titres ; ex. 6, 8, 10 → Formules › chap. 44.")
    A("Commentaires : 2 pts chacun contre 0,5 pt par ratio calculé. 8 pts sur 15,5 du chap. 51 sont des commentaires.")
    X("Note = 1 + 5 × points ÷ 51,5 ; 4 = 30,9 pts (60 %).")
    S("[B] §1, §7 ; [T25] ; [C25]")
  end)

  ------------------------------------------------------------------ tableaux vides
  local tBilan = ecr("Bilan analytique", "bilan", "Bilan analytique (vide)", function()
    T("Bilan analytique : à compléter")
    GRILLE("Actif", {
      sec("Actifs circulants (AC)"),
      lv("Liquidités", 2, {retrait = 1}),
      lv("Créances", 2, {retrait = 1}),
      lv("./. Ducroire", 2, {retrait = 2}),
      lv("Stocks", 2, {retrait = 1}),
      lv("Total AC", 2, {gras = true, trait = true}),
      sec("Actifs immob. (AI)"),
      lv("Immobilisations", 2, {retrait = 1}),
      lv("./. FAC", 2, {retrait = 2}),
      lv("Participations", 2, {retrait = 1}),
      lv("Total AI", 2, {gras = true, trait = true}),
      lv("TOTAL ACTIF", 2, {gras = true, trait = true}),
    }, {entetes = {"Actif", "N-1", "N"}})
    GRILLE("Passif", {
      sec("CE à court terme"),
      lv("Dettes fournisseurs", 2, {retrait = 1}),
      lv("Passifs de régul.", 2, {retrait = 1}),
      lv("Dividende décidé", 2, {retrait = 1}),
      lv("Total CE ct", 2, {gras = true, trait = true}),
      sec("CE à long terme"),
      lv("Emprunts, hypothèques", 2, {retrait = 1}),
      lv("Provisions à lt", 2, {retrait = 1}),
      lv("Total CE lt", 2, {gras = true, trait = true}),
      sec("Capitaux propres (FP)"),
      lv("Capital social", 2, {retrait = 1}),
      lv("Capital de croissance", 2, {retrait = 1}),
      lv("Total FP", 2, {gras = true, trait = true}),
      lv("TOTAL PASSIF", 2, {gras = true, trait = true}),
    }, {entetes = {"Passif", "N-1", "N"}})
    T("Règles de classement")
    X("• Répartir le bénéfice AVANT de classer ; dividende décidé → CE ct.")
    X("• Actifs de régularisation → créances ; passifs de régularisation → CE ct.")
    X("• Ducroire et fonds d'amortissement (FAC) en déduction de l'actif concerné.")
    X("• Titres de placement → liquidités ; participations (≥ 20 % des voix) → AI.")
    X("• Provision à long terme → CE lt ; actionnaires (capital non libéré) et pertes reportées en déduction des FP.")
    X("• Capital de croissance = réserves issues du bénéfice + bénéfice reporté + réserves latentes.")
    A("Au test, garder le classement du bilan donné (2025 : dividendes en CE lt dans l'énoncé, suivi par le corrigé).")
    X("Contrôle : total actif = total passif.")
    S("[51 p.4, p.10] ; CLAUDE.md du cours (sous-totaux) ; [C25] ex. 3")
  end)

  local tCR2 = ecr("CR à 2 degrés", "cr2", "CR à 2 degrés (vide)", function()
    T("Compte de résultat à 2 degrés")
    GRILLE("1er degré (frais variables)", {
      ch("Déductions accordées"), ch("Achats de march."), ch("Frais d'achats"), ch("Diminution de stock"),
      pr("Ventes de march."), pr("Déductions obtenues"), pr("Augmentation de stock"),
      ch("Marge brute (MB)", E, {gras = true}),
      {"Total", E, E, gras = true, trait = true},
    }, {entetes = {"", "Charges", "Produits"}})
    GRILLE("2e degré (frais fixes)", {
      ch("ACE (FF)"), pr("Marge brute (MB)"),
      ch("Bénéfice net (BN)", E, {gras = true}), pr("ou Perte nette (PN)", E, {gras = true}),
      {"Total", E, E, gras = true, trait = true},
    }, {entetes = {"", "Charges", "Produits"}})
    G("Seul l'un des deux soldes existe : stock (diminution OU augmentation), résultat (BN OU PN). Totaux égaux dans chaque degré.")
    T("Formules à écrire avant le calcul")
    X("CAN = ventes − déductions accordées (− pertes s/créances − frais de vente)")
    X("PRAMA = achats + frais d'achats − déductions obtenues")
    X("PRAMV = PRAMA + diminution de stock (− augmentation)")
    X("MB = CAN − PRAMV = FF + BN")
    T("Exemple du prof : test 2025, ex. 2")
    GRILLE("1er degré", {
      ch("Déductions accordées", "30"), ch("Achats", "1'100"), ch("Frais d'achats", "70"),
      pr("Ventes", "2'000"), pr("Déductions obtenues", "20"), pr("Augmentation stock", "100"),
      ch("Marge brute", "920", {gras = true}),
      {"Total", "2'120", "2'120", gras = true, trait = true},
    }, {entetes = {"", "Charges", "Produits"}})
    GRILLE("2e degré", {
      ch("ACE", "400"), pr("Marge brute", "920"), ch("BN", "520", {gras = true}),
      {"Total", "920", "920", gras = true, trait = true},
    }, {entetes = {"", "Charges", "Produits"}})
    X("PRAMA = 1'100 + 70 − 20 = 1'150 ; PRAMV = 1'150 − 100 = 1'050 ; CAN = 2'000 − 30 = 1'970 ; MB = 1'970 − 1'050 = 920.")
    A("Barème : 1er degré 3 pts, 2e degré 1 pt, PRAMA, PRAMV, CAN 1 pt chacun.")
    S("[44 p.3-4] ; [C25] ex. 2 ; [B] R3")
  end)

  local tCR3 = ecr("CR à 3 degrés", "cr3", "CR à 3 degrés (vide)", function()
    T("Compte de résultat à 3 degrés")
    G("Modèle : 37.15 (compte de résultat interne à 3 degrés). 3e degré = éléments hors exploitation (immeubles, exceptionnels).")
    GRILLE("1er degré", {
      ch("Déductions accordées"), ch("Pertes s/créances"), ch("Achats de march."), ch("Frais d'achats"),
      ch("Variation de stock"), pr("Ventes de march."), pr("Déductions obtenues"),
      ch("Marge brute (MB)", E, {gras = true}),
      {"Total", E, E, gras = true, trait = true},
    }, {entetes = {"", "Charges", "Produits"}})
    GRILLE("2e degré (exploitation)", {
      ch("ACE"), ch("Charges financières"), ch("Amortissements"), pr("Marge brute"), pr("Produits financiers"),
      ch("BN d'exploitation", E, {gras = true}),
      {"Total", E, E, gras = true, trait = true},
    }, {entetes = {"", "Charges", "Produits"}})
    GRILLE("3e degré (hors exploit.)", {
      ch("Charges d'immeubles"), ch("Charges exception."), pr("BN d'exploitation"), pr("Produits d'immeubles"),
      ch("BN de l'exercice", E, {gras = true}),
      {"Total", E, E, gras = true, trait = true},
    }, {entetes = {"", "Charges", "Produits"}})
    G("Variation de stock : côté charges si diminution, côté produits si augmentation.")
    S("[c37 p.17, p.19] (37.15) ; 2e degré avec charges financières : [44 p.4]")
  end)

  local tCRliste = ecr("CR à degrés en liste (51)", "crliste", "CR à degrés (EBITDA, EBIT)", function()
    T("Compte de résultat en liste (chap. 51)")
    GRILLE("Calculs préliminaires", {
      {"CAB (ventes − retours)", E},
      {"CAN = CAB − déd. acc.", E},
      {"  − pertes s/créances", ""},
      {"  − frais directs vente", ""},
      {"PRAMA = achats − ret.", E},
      {"  − déd. obt. + frais ach.", ""},
      {"Variation de stock", E},
      {"PRAMV", E, gras = true},
    }, {entetes = {"", "CHF"}})
    GRILLE("Compte de résultat", {
      lv("CAN", 1),
      lv("./. PRAMV", 1),
      lv("= Marge brute", 1, {gras = true, trait = true}),
      lv("./. Charges de personnel", 1),
      lv("./. Autres ch. d'exploit.", 1),
      lv("= EBITDA", 1, {gras = true, trait = true}),
      lv("./. Amortissements", 1),
      lv("= EBIT", 1, {gras = true, trait = true}),
      lv("./. Charges financières", 1),
      lv("+ Produits financiers", 1),
      lv("= Bénéfice net (BN)", 1, {gras = true, trait = true}),
      lv("./. Impôts", 1),
      lv("= Bénéfice de l'exercice", 1, {gras = true, trait = true}),
    }, {entetes = {"", "CHF"}})
    G("Exemple du manuel : CAN 3'017 ; PRAMV 1'894 ; MB 1'123 ; EBITDA 203 ; EBIT 153 ; BN 152.")
    S("[51 p.31-32] ; modèle 51.19 [c51 p.23-24]")
  end)

  local tRL = ecr("Tableau des réserves latentes", "rl", "Tableau des RL (vide)", function()
    T("Tableau des réserves latentes (modèle du prof)")
    G("Le tableau du prof a 8 colonnes ; ici en 2 volets. RL = valeur réelle − valeur comptable.")
    GRILLE("Volet 1 : bilan initial", {
      lv("./. Ducroire", 3), lv("Titres", 3), lv("Stock de march.", 3), lv("Installations", 3),
      {"Totaux", "", "", E, gras = true, trait = true},
    }, {entetes = {"Comptes", "Compt.", "Réelle", "RL"}})
    GRILLE("Volet 2 : bilan final", {
      lv("./. Ducroire", 4), lv("Titres", 4), lv("Stock de march.", 4), lv("Installations", 4),
      {"Totaux", "", "", E, E, gras = true, trait = true},
    }, {entetes = {"Comptes", "Compt.", "Réelle", "RL", "Var."}})
    T("Puis, formule écrite avant le calcul")
    X("Variation des RL = RL finale − RL initiale")
    X("Bénéfice réel = bénéfice publié + variation des réserves latentes")
    X("Fonds propres réels = fonds propres publiés + réserve latente (au 31.12)")
    A("Ducroire en négatif : comptable −15, réelle −10 → RL = −10 − (−15) = 5 (passif surévalué).")
    A("Stock « aux 2/3 de sa valeur réelle » : réelle = comptable × 3/2.")
    T("Exemple du prof : test 2025, ex. 7")
    GRILLE("Bilan initial", {
      {"./. Ducroire", "−15", "−10", "5"}, {"Titres", "100", "130", "30"},
      {"Stock de march.", "140", "210", "70"}, {"Installations", "175", "210", "35"},
      {"Totaux", "", "", "140", gras = true, trait = true},
    }, {entetes = {"Comptes", "Compt.", "Réelle", "RL"}})
    GRILLE("Bilan final", {
      {"./. Ducroire", "−20", "−12", "8", "3"}, {"Titres", "105", "120", "15", "−15"},
      {"Stock de march.", "150", "225", "75", "5"}, {"Installations", "155", "200", "45", "10"},
      {"Totaux", "", "", "143", "3", gras = true, trait = true},
    }, {entetes = {"Comptes", "Compt.", "Réelle", "RL", "Var."}})
    R("Bénéfice réel = 500 + 3 = 503", "", "")
    R("FP réels = 1'500 + 143 = 1'643", "", "")
    G("Barème : ducroire 2 pts, titres 1, stock 2, installations 1 ; bénéfice réel 1 ; FP réels 1.")
    S("[37 p.18] ; [C25] ex. 7 ; [B] R2, R5")
  end)

  local tStock = ecr("Évaluation du stock (960c)", "stock", "Stock : valeur maximale", function()
    T("Valeur maximale du stock (CO 960c)")
    GRILLE("À compléter", {
      lv("Article 1", 5), lv("Article 2", 5),
      {"Total", "", "", "", "", E, gras = true, trait = true},
    }, {entetes = {"March.", "Qté", "PRA", "VVN", "Éval.", "Total"}})
    X("Évaluation = min(PRA unitaire ; valeur vénale nette) ; total = quantité × évaluation.")
    A("Article par article, jamais sur le total du stock.")
    T("Exemple du prof : test 2025, ex. 4")
    GRILLE("Corrigé", {
      {"Ours en peluche", "10", "12", "11", "11", "110"},
      {"Marmotte en béton", "5", "24", "32", "24", "120"},
      {"Total", "", "", "", "", "230", gras = true, trait = true},
    }, {entetes = {"March.", "Qté", "PRA", "VVN", "Éval.", "Total"}})
    S("[37 p.37] ; [C25] ex. 4 ; modèle 37.20 [c37 p.23-24]")
  end)

  local tTitres = ecr("Titres cotés / non cotés", "titres", "Titres au bilan", function()
    T("Titres au bilan")
    GRILLE("Titres cotés (CO 960b)", {lv("Titre A", 3), lv("Titre B", 3)},
      {entetes = {"Titres", "Nombre", "Prix", "Valeur"}})
    GRILLE("Titres non cotés (960a)", {lv("Titre C", 3), lv("Titre D", 3)},
      {entetes = {"Titres", "Nombre", "Prix", "Valeur"}})
    X("Cotés : cours du 31.12, même au-dessus du prix d'achat (CO 960b) ; si le cours est plus bas, il s'impose (CO 960 al. 3).")
    X("Non cotés : min(prix d'achat ; valeur au 31.12), jamais au-dessus du coût d'acquisition (CO 960a).")
    X("Valeur au bilan = nombre × prix retenu (prix retenu écrit explicitement).")
    T("Exemple du prof : test 2025, ex. 9")
    GRILLE("Cotés", {{"Taupe SA", "10", "70", "700"}, {"Renard SA", "20", "25", "500"}},
      {entetes = {"Titres", "Nombre", "Prix", "Valeur"}})
    GRILLE("Non cotés", {{"Corbeau SA", "15", "200", "3'000"}, {"Éléphant SA", "5", "80", "400"}},
      {entetes = {"Titres", "Nombre", "Prix", "Valeur"}})
    S("[37 p.3, p.35] ; [C25] ex. 9 ; modèle 37.19 [c37 p.22-23] ; [B] R8")
  end)

  local tSeuil = ecr("Seuil de rentabilité", "seuil", "Seuil (vide)", function()
    T("Seuil de rentabilité : tableau")
    GRILLE("Compte de résultat", {
      lv("Chiffre d'affaires", 4),
      lv("./. Charges variables", 4),
      {"Marge brute", "", E, E, E, gras = true, trait = true},
      {"./. Charges fixes", "", "", E, ""},
      {"Marge nette (BN)", "", "", E, "", gras = true, trait = true},
    }, {entetes = {"", "Qté", "Unit.", "CHF", "%"}})
    X("MB unitaire = PV unitaire − CV unitaire")
    X("Seuil (quantité) = charges fixes ÷ MB unitaire → arrondi à l'unité SUPÉRIEURE")
    X("CA au point mort = charges fixes × 100 ÷ taux de MB = CA × CF ÷ MB")
    X("Quantité pour un BN visé = (CF + BN) ÷ MB unitaire")
    T("Exemple du manuel (DVD)")
    GRILLE("Compte de résultat", {
      {"Chiffre d'affaires", "60", "20", "1'200", "100 %"},
      {"./. Charges variables", "60", "12", "720", "60 %"},
      {"Marge brute", "", "8", "480", "40 %", gras = true, trait = true},
      {"./. Charges fixes", "", "", "320", ""},
      {"Marge nette (BN)", "", "", "160", "", gras = true, trait = true},
    }, {entetes = {"", "Qté", "Unit.", "CHF", "%"}})
    R("CA au point mort = 320 × 100 ÷ 40 = 800", "", "")
    R("Seuil = 320 ÷ 8 = 40 DVD", "", "")
    S("[44 p.8-9] ; arrondi : [C25] ex. 6 b, [B] R9")
  end)

  local tRatios = ecr("Tableau des ratios", "tabratios", "Tableau des ratios (vide)", function()
    T("Ratios : présentation du prof")
    GRILLE("Une entreprise (test 2025 ex. 3)", {
      lv("Liquidités 1", 2), lv("Liquidités 2", 2), lv("Liquidités 3", 2), {"Commentaire", "→ 2 pts", ""},
      lv("Couverture 1", 2), lv("Couverture 2", 2), {"Commentaire", "→ 2 pts", ""},
    }, {entetes = {"Ratio", "Calcul", "Résultat"}})
    G("Calcul en fraction (numérateur / dénominateur), puis résultat : liquidités en % (14.44 %), couvertures en décimal (1.28).")
    GRILLE("Trois entreprises (ex. 5)", {
      lv("Liquidités 1", 3), lv("Liquidités 2", 3), lv("Liquidités 3", 3),
      lv("Intensité AI", 3), lv("Endettement", 3), lv("Couverture 2", 3),
    }, {entetes = {"Ratio", "A", "B", "C"}})
    G("Ex. 5 : résultats en décimal (0.82). 3 pts de calculs, 6 pts de commentaires (une à deux phrases par entreprise et par question).")
    S("[C25] ex. 3, ex. 5 ; [B] R6, R7, §3")
  end)

  local tLiq = ecr("Tableau des liquidités (57)", "liquidites", "Tableau des liquidités", function()
    T("Tableau des liquidités (fonds)")
    GRILLE("À compléter", {
      lv("Caisse", 3), lv("Poste", 3), lv("Banque (si fonds)", 3),
      lv("Total du fonds", 3, {gras = true, trait = true}),
    }, {entetes = {"Fonds", "N-1", "N", "Var."}})
    X("Définir d'abord le fonds (avec ou sans banque c/c, titres) : un compte courant débiteur se porte en diminution du fonds.")
    X("Variation du fonds = contrôle du tableau des flux (somme des 3 secteurs).")
    GRILLE("Exemple du manuel", {
      {"Caisse", "7", "4", "−3"}, {"Poste", "17", "9", "−8"},
      {"Total", "24", "13", "−11", gras = true, trait = true},
    }, {entetes = {"Fonds", "N-1", "N", "Var."}})
    S("[57 p.4, p.12] ; modèles 57.2, 57.3")
  end)

  local tTFT = ecr("Tableau des flux (57)", "tft", "Tableau des flux de trésorerie", function()
    T("Tableau des flux de trésorerie (CO 961b)")
    GRILLE("Exploitation (directe)", {
      lv("Encaiss. des clients", 1),
      lv("./. Paiem. fournisseurs", 1),
      lv("./. Paiem. salaires", 1),
      lv("./. Autres ch. payées", 1),
      lv("./. Charges financières", 1),
      lv("= Cash flow", 1, {gras = true, trait = true}),
    }, {entetes = {"", "CHF"}})
    GRILLE("Investissement", {
      lv("./. Investissements", 1),
      lv("+ Désinvestissements", 1),
      lv("= Flux investissement", 1, {gras = true, trait = true}),
    }, {entetes = {"", "CHF"}})
    GRILLE("Financement", {
      lv("+ Augm. capital (agio)", 1),
      lv("+ Nouvel emprunt", 1),
      lv("./. Remboursement", 1),
      lv("./. Dividende N-1 payé", 1),
      lv("= Flux financement", 1, {gras = true, trait = true}),
    }, {entetes = {"", "CHF"}})
    GRILLE("Contrôle", {
      lv("Variation du fonds", 1, {gras = true}),
      lv("Liquidités au 1.1", 1),
      lv("Liquidités au 31.12", 1),
    }, {entetes = {"", "CHF"}})
    GRILLE("Exploitation (indirecte)", {
      lv("Bénéfice net", 1),
      lv("+ Amortissements", 1),
      lv("+ Dotations provisions", 1),
      lv("./. Dissolutions prov.", 1),
      lv("./. Augm. créances", 1),
      lv("./. Augm. stocks", 1),
      lv("+ Augm. dettes fourn.", 1),
      lv("= Cash flow", 1, {gras = true, trait = true}),
    }, {entetes = {"", "CHF"}})
    G("Encaissements positifs, paiements négatifs. Une diminution de créances ou de stock, ou une diminution des dettes fournisseurs : signes inverses.")
    G("Exemple du manuel : CF 65 ; investissement −100 ; financement +24 ; variation du fonds −11 (24 → 13).")
    S("[57 p.9-13, p.21] ; test 2026-02 ex. 2 (corrigé Excel 002_57_06)")
  end)

  local tCMP = ecr("Compte de stock au CMP (59)", "cmp", "Compte de stock (CMP)", function()
    T("Compte de stock au coût moyen pondéré")
    GRILLE("Entrées", {lv("Stock initial", 3), lv("Entrée (date)", 3), lv("Entrée (date)", 3),
      lv("Total entrées", 3, {gras = true, trait = true})}, {entetes = {"Libellé", "Q", "Coût u.", "Total"}})
    GRILLE("Sorties", {lv("Sortie (date)", 3), lv("Sortie (date)", 3), lv("Stock final", 3),
      lv("Total sorties", 3, {gras = true, trait = true})}, {entetes = {"Libellé", "Q", "Coût u.", "Total"}})
    X("CMP = Σ (quantité × coût) ÷ Σ quantités ; sorties et stock final valorisés au CMP.")
    G("Exemple : (120 × 25 + 60 × 28 + 30 × 30) ÷ (120 + 60 + 30) = 26.5714. Test 2026-02 : CMP à 4 décimales.")
    S("[59 p.34] ; modèles 59.13, 59.14")
  end)

  local tableaux = sousMenu("Tableaux vides", "Tableaux vides", {
    tBilan, sousMenu("Comptes de résultat", "Comptes de résultat (vides)", {tCR2, tCR3, tCRliste}), tRL, tStock, tTitres, tSeuil, tRatios,
    sousMenu("Trésorerie (57)", "Trésorerie (vides)", {tLiq, tTFT}), tCMP,
  })

  ------------------------------------------------------------------ schémas
  local sCascade = ecr("PRAMA, PRAMV, CAN, MB", "cascade", "Schéma du 1er degré", function()
    T("Du chiffre d'affaires à la marge brute")
    GRILLE("Chiffre d'affaires", {
      {"Ventes (CAB)", E, "1'100"},
      {"+ Prestations propres", E, ""},
      {"./. Déd. accordées", E, "100"},
      {"./. Pertes s/créances", E, ""},
      {"./. Frais de vente", E, ""},
      {"= CAN", E, "1'000", gras = true, trait = true},
    }, {entetes = {"", "Vide", "44 p.4"}})
    GRILLE("Achats", {
      {"Achats", E, "560"},
      {"+ Frais d'achats", E, "20"},
      {"./. Déd. obtenues", E, "10"},
      {"= PRAMA", E, "570", gras = true, trait = true},
      {"+ Dimin. de stock", E, "30"},
      {"(./. Augm. de stock)", E, ""},
      {"= PRAMV (FV)", E, "600", gras = true, trait = true},
    }, {entetes = {"", "Vide", "44 p.4"}})
    GRILLE("Résultat", {
      {"CAN", E, "1'000"},
      {"./. PRAMV", E, "600"},
      {"= Marge brute", E, "400", gras = true, trait = true},
      {"./. Frais fixes (FF)", E, "350"},
      {"= BN", E, "50", gras = true, trait = true},
    }, {entetes = {"", "Vide", "44 p.4"}})
    X("MB = CAN − PRAMV = FF + BN ; taux de MB = MB × 100 ÷ CAN (ici 40 %).")
    G("Variation de stock = stock final − stock initial : augmentation → PRAMV diminue (côté produits dans le CR en T).")
    S("[44 p.3-4] ; [51 p.31] (CAB, retours)")
  end)

  local sBlocs = ecr("Bilan en blocs, FRN", "blocs", "Bilan en blocs", function()
    T("Bilan en blocs")
    GRILLE("Actif | Passif", {
      {"AC : liquidités", "CE ct", ""},
      {"  créances, stocks", "", ""},
      {"AI : immobilisations", "CE lt", ""},
      {"  participations", "FP", ""},
    }, {entetes = {"Actif", "Passif", ""}})
    X("Liquidités 1, 2, 3 : une partie de l'AC face aux CE ct.")
    X("Couverture 1 : FP face aux AI ; couverture 2 : (FP + CE lt) face aux AI.")
    X("FRN = AC − CE ct = (FP + CE lt) − AI : positif = favorable.")
    X("Règle d'or : les AI sont financés par les capitaux permanents (FP + CE lt) → couverture 2 > 1.")
    X("Capitaux permanents = FP + CE lt.")
    S("[51 p.4, p.11-13]")
  end)

  local sGraphe = ecr("Graphique du seuil", "graphe", "Graphique du seuil", function()
    T("Graphique du point mort : 4 droites")
    X("Abscisse : quantités (ou activité) ; ordonnée : CHF.")
    X("1. CAN = PV × quantité (part de 0)")
    X("2. FV (charges variables) = CV × quantité (part de 0) ; ou la marge brute BB = MB unitaire × quantité")
    X("3. FF (charges fixes) : droite horizontale")
    X("4. PR (prix de revient) = FV + FF (part du niveau des FF)")
    R("Point mort : CAN = PR (ou BB = FF)", "", "")
    X("À gauche : zone de perte (accolade PN entre PR et CAN) ; à droite : zone de bénéfice (accolade BN).")
    X("Lire et annoter les CA demandés (flèches « CAN = … », « PM BN = 0 ») ; nommer les droites dans une légende.")
    G("Test 2025 ex. 8 : point mort 375'000 ; BN 30'000 → 450'000 ; PN 60'000 → 225'000.")
    S("[44 p.10] ; [C25] ex. 8 ; corrigé 44.13 [c44 p.15] ; [B] R10")
  end)

  local sRL = ecr("Réserves latentes et résultat", "schemarl", "RL : résultat et FP", function()
    T("Effet des réserves latentes")
    G("Interne = réel ; externe = comptable, publié. RL = valeur réelle − valeur comptable.")
    GRILLE("Résultat", {
      {"Bénéfice publié", E},
      {"+ Augmentation des RL", E},
      {"(./. Diminution des RL)", E},
      {"= Bénéfice réel", E, gras = true, trait = true},
    }, {entetes = {"", "CHF"}})
    GRILLE("Fonds propres", {
      {"FP publiés", E},
      {"+ RL au 31.12", E},
      {"= FP réels (internes)", E, gras = true, trait = true},
    }, {entetes = {"", "CHF"}})
    X("Ce n'est pas l'existence d'une RL qui influence le résultat, mais sa variation : constituer des RL diminue le bénéfice publié, les dissoudre l'augmente.")
    G("Test 2025 ex. 1 : RL 160 → 120 (diminution 40) ; perte publiée −40 − 40 = perte réelle −80.")
    S("[37 p.18] ; [C25] ex. 1")
  end)

  local schemas = sousMenu("Schémas", "Schémas", {sCascade, sBlocs, sGraphe, sRL})

  ------------------------------------------------------------------ ratios (26 de la liste Profil M)
  local function ratio(nom, formule, unite, norme, lecture)
    X(nom .. " = " .. formule)
    G(unite .. " · " .. norme .. (lecture and (" · " .. lecture) or ""))
  end

  local rVue = ecr("Vue d'ensemble (26)", "ratios", "Les 26 ratios", function()
    T("Liste Profil M : 26 ratios")
    GRILLE("Bilan", {
      {"Liquidité I", "%", "20-30 %"}, {"Liquidité II", "%", "≥ 100 %"}, {"Liquidité III", "%", "> 150 %"},
      {"Intensité AC", "%", "secteur"}, {"Intensité AI", "%", "secteur"},
      {"Endettement", "%", "repères"}, {"Financement propre", "%", "élevé"}, {"Autofinancement", "%", "âge"},
      {"Couverture I", "% / déc.", "60-80 %"}, {"Couverture II", "% / déc.", "> 100 %"},
    }, {entetes = {"Ratio", "Unité", "Repère"}})
    GRILLE("Compte de résultat", {
      {"Taux de marge brute", "%", "temps"}, {"Taux marge économique", "%", "temps"}, {"Taux de marge nette", "%", "temps"},
    }, {entetes = {"Ratio", "Unité", "Repère"}})
    GRILLE("Cycle des liquidités", {
      {"Rotation créances", "fois", "—"}, {"Durée crédits accordés", "jours", "délai"},
      {"Rotation fournisseurs", "fois", "—"}, {"Durée crédits obtenus", "jours", "délai"},
      {"Rotation stocks", "fois", "—"}, {"Durée stockage", "jours", "courte"},
    }, {entetes = {"Ratio", "Unité", "Repère"}})
    GRILLE("Rentabilité", {
      {"ROI", "%", "temps"}, {"ROE", "%", "temps"},
      {"Rotation de l'actif", "fois", "D1"}, {"Effet de levier", "%", "D1"},
    }, {entetes = {"Ratio", "Unité", "Repère"}})
    GRILLE("Cash flow (57)", {
      {"Ratio d'investissement", "%", "—"}, {"Marge de cash flow", "%", "temps"}, {"Facteur endettement", "déc.", "1-3 ; > 5"},
    }, {entetes = {"Ratio", "Unité", "Repère"}})
    G("% : formule « × 100 » de la liste. Le prof écrit aussi le décimal (couvertures 1.28 et 1.75 en 2025 ex. 3 ; tout en décimal à l'ex. 5).")
    G("D1 : rotation de l'actif et effet de levier hors périmètre du 12.11. « temps » = comparer dans le temps ou au secteur.")
    S("[R] ; glossaire.md §1 ; normes [51 p.9-13], [57 p.62]")
  end)

  local rLiq = ecr("Liquidité (+ FRN)", "r_liquidite", "Ratios de liquidité", function()
    T("Liquidité (trésorerie)")
    ratio("Liquidité I", "Liquidités × 100 ÷ CE à c.t.", "%", "20 à 30 % (0.2 à 0.3)", "trop élevé : liquidités qui dorment ; trop bas : manque de trésorerie")
    ratio("Liquidité II", "(Liquidités + Créances) × 100 ÷ CE à c.t.", "%", "au moins 100 %", "le plus important : peut payer ses dettes à court terme")
    ratio("Liquidité III", "Actifs circulants × 100 ÷ CE à c.t.", "%", "> 150 %", "un léger écart n'est pas forcément grave (dépend de la vente du stock)")
    ratio("FRN (hors liste)", "AC − CE ct = (FP + CE lt) − AI", "CHF", "positif = favorable")
    G("Normes « communément admises par les banques », à prendre avec prudence.")
    G("Test 2025 ex. 3 : 65/450 = 14.44 % ; 535/450 = 118.89 % ; 975/450 = 216.67 %.")
    S("[R] ; [51 p.11-12] ; [C25] ex. 3")
  end)

  local rActif = ecr("Structure de l'actif", "r_actif", "Structure de l'actif", function()
    T("Structure de l'actif (investissement)")
    ratio("Intensité de l'actif circulant", "AC × 100 ÷ Actifs (total du bilan)", "%", "pas de norme", "dépend de l'activité ; comparer au secteur et dans le temps")
    ratio("Intensité de l'actif immobilisé", "AI × 100 ÷ Actifs (total du bilan)", "%", "pas de norme", "AI élevés = frais fixes importants")
    G("IAC + IAI = 100 %. Test 2025 ex. 5 : intensité AI 0.5 / 0.62 / 0.24.")
    S("[R] ; [51 p.9] ; [C25] ex. 5")
  end)

  local rFin = ecr("Structure du passif", "r_financement", "Structure du financement", function()
    T("Structure du passif (financement)")
    ratio("Degré d'endettement", "CE × 100 ÷ Passifs (total du bilan)", "%", "pas de norme chiffrée dans le manuel",
      "élevé = plus de charges financières et de risque, mais peut augmenter le ROE")
    G("Repères tirés des corrigés (pas des normes) : 40 % et 43.78 % « faible » ; 56-58 % « dans la norme » ; 82 % « surendettée ».")
    ratio("Degré de financement propre", "FP × 100 ÷ Passifs (total du bilan)", "%", "élevé = indépendance",
      "sécurité en cas de pertes, charges financières faibles")
    ratio("Degré d'autofinancement", "Capital de croissance × 100 ÷ FP", "%", "pas de norme",
      "dépend de l'âge de l'entreprise et des bénéfices antérieurs")
    G("Endettement + financement propre = 100 %. Capital de croissance = réserves issues du bénéfice + bénéfice reporté + RL.")
    S("[R] ; [51 p.10] ; 51.8 [c51 p.2], 51.10 [c51 p.4]")
  end)

  local rCouv = ecr("Couverture des immob.", "r_couverture", "Couverture des immobilisations", function()
    T("Couverture des immobilisations")
    ratio("Couverture I", "FP × 100 ÷ AI", "% (prof : décimal)", "60 à 80 %", "plus il est élevé, plus le risque est faible")
    ratio("Couverture II", "(FP + CE à l.t.) × 100 ÷ AI", "% (prof : décimal)", "toujours > 100 % (> 1)", "règle d'or : AI financés par des capitaux permanents")
    G("Test 2025 ex. 3 : 895/700 = 1.28 ; 1'225/700 = 1.75 → « La règle d'or est respectée… ».")
    A("Couverture II élevée peut venir d'AI faibles (Husky, ex. 5) : le dire dans le commentaire.")
    S("[R] ; [51 p.13] ; [C25] ex. 3 ; [B] §3")
  end)

  local rMarges = ecr("Marges (CR)", "r_marges", "Taux de marge", function()
    T("Compte de résultat")
    ratio("Taux de marge brute", "MB × 100 ÷ CAN", "%", "comparer dans le temps, au secteur")
    ratio("Taux de marge économique", "EBIT × 100 ÷ CAN", "%", "idem")
    ratio("Taux de marge nette", "BN × 100 ÷ CAN", "%", "idem", "aussi « rendement du chiffre d'affaires »")
    G("Chiffres clés hors liste : évolution du CA = (CA − CA précédent) × 100 ÷ CA précédent ; CA par employé ; CA au m².")
    S("[R] ; [51 p.35] ; 51.21 [c51 p.25]")
  end)

  local rRot = ecr("Rotations et durées", "r_rotations", "Rotations et durées", function()
    T("Cycle des liquidités")
    ratio("Rotation des créances", "CA à crédit ÷ moyenne des créances clients", "fois par an", "—", "CA total si le CA à crédit est inconnu")
    ratio("Durée des crédits accordés", "360 ÷ rotation des clients", "jours", "comparer au délai de paiement accordé", "trop long : relancer les clients")
    ratio("Rotation des fournisseurs", "PRAMA à crédit ÷ moyenne des dettes fournisseurs", "fois par an", "—", "PRAMA total si inconnu")
    ratio("Durée des crédits obtenus", "360 ÷ rotation des fournisseurs", "jours", "comparer aux délais fournisseurs", "trop longue : retards ; trop courte : utile seulement avec escompte")
    ratio("Rotation des stocks", "PRAMV ÷ moyenne des stocks", "fois par an", "—")
    ratio("Durée de stockage", "360 ÷ rotation des stocks", "jours", "aussi courte que possible", "sans rupture de stock")
    X("Moyenne = (valeur N−1 + valeur N) ÷ 2.")
    A("Fournisseurs : PRAMA ; stocks : PRAMV. Ne pas les confondre.")
    S("[R] ; [51 p.27-30] ; 51.24 [c51 p.27-29]")
  end)

  local rRent = ecr("Rentabilité (ROI, ROE)", "r_rentabilite", "Rentabilité", function()
    T("Rentabilité")
    ratio("ROI", "EBIT × 100 ÷ total moyen des bilans", "%", "comparer dans le temps", "indépendant du financement et des impôts")
    ratio("ROE", "BN × 100 ÷ total moyen des capitaux propres", "%", "comparer dans le temps", "intéresse les actionnaires")
    ratio("Rotation de l'actif", "CAN ÷ moyenne des actifs", "fois", "hors périmètre 12.11 (D1)")
    ratio("Effet de levier", "(ROI − t) × ⌀ FE ÷ ⌀ FP, t = charges fin. × 100 ÷ ⌀ FE", "%", "hors périmètre 12.11 (D1)", "si ROI > t, l'endettement augmente le ROE")
    X("EBIT = BN + charges financières − produits financiers (+ impôts). Total moyen = (N−1 + N) ÷ 2.")
    G("ROI = taux de marge économique × rotation de l'actif (D1). ⌀ = moyenne.")
    S("[R] ; [51 p.41-42, p.44] ; 51.25 [c51 p.29-30]")
  end)

  local rCF = ecr("Cash flow (57)", "r_cashflow", "Ratios de cash flow", function()
    T("Cash flow (chap. 57, test de janvier)")
    ratio("Ratio d'investissement", "Cash flow × 100 ÷ investissements nets", "%", "part des investissements financés par le cash flow")
    ratio("Marge de cash flow", "Cash flow × 100 ÷ CAN", "%", "comparer dans le temps")
    ratio("Facteur d'endettement", "Endettement effectif ÷ cash flow", "décimal (années)", "1 à 3 très bon ; > 5 insuffisant", "plus il est faible, plus le prêteur est en sécurité")
    X("Endettement effectif = CE − liquidités − créances.")
    X("Free cash flow (hors liste) = cash flow − investissements nets.")
    X("Investissements nets = investissements − désinvestissements = (AI N − AI N−1) + amortissements (si amort. direct) + pertes s/cession − bénéfices s/cession.")
    S("[R] ; [57 p.62] ; 57.22 [c57 p.45-46]")
  end)

  local ratiosMenu = sousMenu("Ratios (26, Profil M)", "Ratios", {rVue, rLiq, rActif, rFin, rCouv, rMarges, rRot, rRent, rCF})

  ------------------------------------------------------------------ formules par chapitre
  local f37 = ecr("Chap. 37 : évaluation, RL", "f37", "Formules du chap. 37", function()
    T("Réserves latentes")
    X("RL = valeur réelle − valeur comptable (= interne − externe)")
    X("Variation des RL = RL au 31.12 − RL au 01.01")
    X("Résultat réel = résultat publié + variation des RL (augmentation +, diminution −)")
    X("FP réels = FP publiés + RL au 31.12")
    G("Ex. 1 2025 : −40 − 40 = −80. Ex. 7 : 500 + 3 = 503 ; 1'500 + 143 = 1'643.")
    T("Ducroire")
    X("Provision = taux × créances commerciales (5 % suisses, 10 % étrangers)")
    X("RL ducroire = provision comptable − risque réel (passif surévalué)")
    G("37.21 : RL 2'000 → 5'000, +3'000.")
    T("Stock à une fraction")
    X("Comptable = 2/3 du réel ⇒ RL = comptable ÷ 2 ; réel = comptable × 3/2")
    X("RL = 1/3 de la valeur réelle ⇒ comptable = réel × 2/3 (abattement fiscal max. 1/3)")
    X("Stock au bilan (CO 960c) = Σ quantité × min(PRA ; valeur vénale nette), article par article")
    G("37.14 : RL 200'000 → 250'000.")
    T("Titres")
    X("Cotés : nombre × cours du 31.12 (CO 960b) ; non cotés : nombre × min(achat ; valeur) (CO 960a)")
    T("Immobilisation et fisc")
    X("Coût d'acquisition = prix d'achat − remise + transport + installation (max. à la 1re inscription, CO 960a al. 1)")
    G("37.18 : 800'000 + 10'000 + 40'000 − 80'000 = 770'000. Manuel : 50'000 − 5'000 + 1'000 + 200 = 46'200.")
    X("Reprise fiscale = RL comptabilisée − RL admise ; bénéfice fiscal = bénéfice comptable + reprise")
    G("37.24 : 58'700 − 45'500 = 13'200 ; 57'900 + 13'200 = 71'100.")
    S("[37 p.18, p.33, p.35, p.37, p.41] ; [c37 p.15-16, 21, 24-27]")
  end)

  local f44 = ecr("Chap. 44 : seuil", "f44", "Formules du chap. 44", function()
    T("Compte de résultat")
    X("CAN = CAB + prestations propres − déductions accordées − pertes s/créances − frais de vente")
    X("PRAMA = achats + frais d'achats − déductions obtenues")
    X("PRAMV = PRAMA + diminution de stock (− augmentation)")
    X("MB = CAN − PRAMV = FF + BN ; taux de MB = MB × 100 ÷ CAN")
    T("Seuil en valeur")
    X("CA au point mort = CA × CF ÷ MB = CF × 100 ÷ taux de MB")
    X("CA pour un BN visé = (CF + BN) × 100 ÷ taux de MB")
    X("Date du point mort (jours) = CA au PM × 360 ÷ CA annuel")
    X("BN à un autre CA = taux de MB × CA − CF")
    G("Manuel : 350 × 100 ÷ 40 = 875 ; (350 + 100) × 100 ÷ 40 = 1'125 ; 875 × 360 ÷ 1'000 = 315 → 15 novembre. Recueil : arrondi aux 5 centimes.")
    T("Seuil en quantité")
    X("MB unitaire = PV − CV unitaire")
    X("Seuil (qté) = CF ÷ MB unitaire ; qté visée = (CF + BN) ÷ MB unitaire → unité SUPÉRIEURE")
    X("CAN au PM = quantité au PM × PV ; BN = quantité × MB unitaire − CF")
    X("Taux de marge en % du PVN : MB u. = CV × t ÷ (100 − t) ; en % du coût : MB u. = CV × t")
    G("Ex. 6 2025 : 640 ÷ 8 = 80 ; 1'140 ÷ 8 = 142,5 → 143.")
    T("Licence, prix minimum, recettes annexes")
    X("À couvrir = CF + BN visé ; quantité = à couvrir ÷ marge sur coût variable")
    X("Prix minimum = CV unitaire + CF ÷ quantité (commande minimale)")
    X("Baisse de prix : nouveau PV → nouvelle MB u. → nouveau seuil ; augmentation = (nouveau − ancien) × 100 ÷ ancien")
    G("44.16 : 230'000 ÷ 40 = 5'750 ; 80 + 180'000 ÷ 5'000 = 116 ; 4'500 → 6'429 (+42.9 %).")
    X("Recettes annexes déduites des CF ; taux d'occupation = seuil × 100 ÷ capacité (44.15 : 80.125 %)")
    A("Ex. 10 2025 : référence = corrigé du prof (850 ; 6'750 ; +11,1 %), incohérent avec l'énoncé ; méthode du livre en regard : 200 ; 6'750 ; +114 %.")
    S("[44 p.3, p.8-10] ; [c44 p.4, 8-10, 17-19] ; [C25] ex. 6, 10")
  end)

  local f51 = ecr("Chap. 51 : analyse", "f51", "Formules du chap. 51", function()
    T("Bilan")
    X("AC = liquidités + créances + stocks ; FRN = AC − CE ct = (FP + CE lt) − AI")
    X("Capital de croissance = réserves issues du bénéfice + bénéfice reporté (− pertes reportées) + RL")
    T("Compte de résultat")
    X("CAB = ventes − retours des clients ; CAN = CAB − déd. accordées − pertes s/créances − frais directs de vente")
    X("PRAMA = achats − retours aux fournisseurs − déd. obtenues + frais d'achats")
    X("MB − personnel − autres charges d'exploitation = EBITDA ; EBITDA − amortissements = EBIT")
    X("EBIT − charges financières + produits financiers = BN ; BN − impôts = bénéfice de l'exercice")
    T("Rotations, rentabilité")
    X("Moyenne = (N−1 + N) ÷ 2 ; rotation = flux ÷ moyenne ; durée = 360 ÷ rotation")
    X("ROI = EBIT × 100 ÷ total moyen des bilans ; ROE = BN × 100 ÷ FP moyens")
    X("Évolution du CA = (CA − CA précédent) × 100 ÷ CA précédent")
    G("51.21 : 102'000 × 100 ÷ 2'356'000 ≈ 4 %.")
    A("Hors périmètre du 12.11 : décomposition du ROI, effet de levier (51.26-51.33), cycle des liquidités (51.16-51.18).")
    S("[51 p.4, p.10-13, p.27-35, p.41-42] ; CLAUDE.md du cours (hors scope)")
  end)

  local f57 = ecr("Chap. 57 : trésorerie", "f57", "Formules du chap. 57", function()
    T("Cash flow")
    X("Méthode directe : produits à effet monétaire − charges à effet monétaire")
    X("Méthode indirecte : BN + charges sans effet monétaire (amortissements, dotations aux provisions) − produits sans effet monétaire (dissolutions)")
    X("Avec ventes et achats à crédit : − augmentation des créances, − augmentation des stocks, + augmentation des dettes fournisseurs")
    G("Manuel : 260'000 − 120'000 − 15'000 − 80'000 − 26'000 − 4'000 = 15'000 = 5'000 + 10'000.")
    T("Secteurs")
    X("Investissement : − achats d'AI + ventes d'AI ; financement : + capital (agio inclus) + emprunts − remboursements − dividende N−1")
    X("Variation du fonds = cash flow + flux investissement + flux financement = liquidités 31.12 − liquidités 1.1")
    T("Analyse")
    X("Free cash flow = cash flow − investissements nets ; endettement effectif = CE − liquidités − créances")
    X("Investissements nets (amort. indirect) = (AI N − AI N−1) + pertes s/cession − bénéfices s/cession")
    G("Test 2026-02 ex. 2 : 290 − 140 − 155 = −5 (fonds 185 → 180).")
    S("[57 p.9-13, p.21, p.62] ; corrigé Excel 002_57_06")
  end)

  local f59 = ecr("Chap. 59 : coûts", "f59", "Formules du chap. 59", function()
    T("Comptabilité analytique (« 59 ? » au test de janvier)")
    X("Charges de la CAE = charges de la comptabilité générale + charges supplétives − charges non incorporables")
    G("Supplétives : rémunération des capitaux propres, de l'exploitant. Non incorporables : charges exceptionnelles, provisions sans risque réel.")
    X("Coûts en cascade : coût d'achat des matières → coût de production → prix de revient des produits vendus → résultat analytique")
    X("CMP = Σ (quantité × coût) ÷ Σ quantités (test 2026-02 : 4 décimales)")
    X("Coût de l'unité d'œuvre = total de la section après répartition secondaire ÷ nombre d'unités d'œuvre")
    S("[59 p.5, p.34] ; 59.9-59.15 ; test 2026-02 ex. 1, 3")
  end)

  local formules = sousMenu("Formules par chapitre", "Formules", {f37, f44, f51, f57, f59})

  ------------------------------------------------------------------ définitions
  local d37 = ecr("Chap. 37", "def37", "Définitions : chap. 37", function()
    T("Principes d'évaluation")
    X("Principe : pas d'actif surévalué ni de passif sous-évalué ; actifs = valeurs plafonds, passifs = valeurs planchers.")
    X("Valeur maximale d'un actif : prix de revient d'acquisition − moins-value subie.")
    X("Valeur vénale nette : valeur de marché − coûts résiduels prévisibles.")
    X("Valeur nominale : liquidités, créances, dettes (aucun problème d'évaluation).")
    X("Réserves apparentes : créées APRÈS le bénéfice (répartition, agio).")
    X("Réserve latente : fonds propres dissimulés, créés AVANT le bénéfice (sous-évaluation d'actifs, passifs fictifs ou surévalués).")
    X("Catégories : forcées (CO 960a-e), d'appréciation (CO 960, prudence), arbitraires (refusées par IFRS, US GAAP, RPC).")
    X("Reprise fiscale : montant au-delà des normes fiscales, ajouté au bénéfice comptable.")
    X("Participation : ≥ 20 % des droits de vote, détenue à long terme (CO 960d) → AI.")
    S("glossaire.md §2 ; [37 p.3-9, p.18, p.38, p.40-41]")
  end)

  local d44 = ecr("Chap. 44", "def44", "Définitions : chap. 44", function()
    T("Seuil de rentabilité")
    X("Seuil de rentabilité (CA au point mort) : CA pour lequel BN = 0.")
    X("Charges variables : rigoureusement proportionnelles à l'activité (commerce : PRAMV). Charges fixes : toutes les autres (ACE…).")
    X("Marge brute = marge sur coût variable = CAN − charges variables.")
    X("Marge contributive : CAN − charges directes (affectables sans ambiguïté) ; le manuel appelle aussi la MB « marge contributive ».")
    X("Hypothèses : valables à court terme (1 an) ; à long terme, les charges fixes varient par paliers.")
    X("1er degré : frais variables (PRAMV) → MB ; 2e degré : frais fixes → BN ou PN.")
    S("glossaire.md §2 ; [44 p.3-4, p.8-10]")
  end)

  local d51 = ecr("Chap. 51", "def51", "Définitions : chap. 51", function()
    T("Analyse de bilan et du résultat")
    X("Bilan analytique : bilan regroupé en AC (liquidités, créances, stocks), AI ; CE ct, CE lt, FP.")
    X("CE ct : dettes à moins d'un an + passifs de régularisation ; CE lt : plus d'un an (hypothèques).")
    X("Capitaux permanents = FP + CE lt. Règle d'or : AI financés par des capitaux permanents.")
    X("EBITDA : résultat avant intérêts, impôts, amortissements. EBIT : avant intérêts et impôts (« bénéfice économique »).")
    X("Cadence de rotation : nombre de renouvellements par an ; durée moyenne = 360 ÷ cadence.")
    X("Rentabilité = revenu × 100 ÷ capital investi.")
    X("Dividende à payer : CE ct dans le manuel ; garder le classement de l'énoncé.")
    S("glossaire.md §2 ; [51 p.4, p.13, p.27, p.31, p.40]")
  end)

  local d57 = ecr("Chap. 57 et 59", "def57", "Définitions : chap. 57, 59", function()
    T("Trésorerie (57)")
    X("Fonds : regroupement de comptes de liquidités (caisse, poste, banque…) à définir avant tout tableau.")
    X("Tableau des flux de trésorerie : explique la variation du fonds en 3 secteurs (exploitation, investissement, financement), CO 961b.")
    X("Cash flow : flux d'exploitation positif ; cash drain : négatif.")
    X("Charges sans effet monétaire : amortissements, dotations aux provisions ; produit sans effet monétaire : dissolution de provision.")
    X("Free cash flow : cash flow disponible après les investissements nets.")
    T("Coûts (59)")
    X("Charges supplétives : non comptabilisées en comptabilité générale mais incorporées aux coûts. Non incorporables : exclues des coûts.")
    S("[57 p.4, p.9, p.62] ; [59 p.5]")
  end)

  local definitions = sousMenu("Définitions", "Définitions", {d37, d44, d51, d57})

  ------------------------------------------------------------------ articles du CO
  local co = ecr("Articles du CO", "co", "Articles du CO", function()
    T("Code des obligations (droit comptable)")
    X("CO 960 : évaluation individuelle ; prudente sans fausser l'appréciation ; vérifier les actifs surévalués et provisions insuffisantes (al. 3).")
    X("CO 960a : 1re inscription au plus au coût d'acquisition (al. 1) ; ensuite jamais au-dessus (al. 2) ; amortissements et corrections de valeur (al. 3) ; amortissements supplémentaires admis (al. 4).")
    X("CO 960b : actifs cotés au cours du jour de clôture, même au-dessus du coût d'acquisition ; réserve de fluctuation possible.")
    X("CO 960c : stocks au plus au coût d'acquisition ou de revient ; à la valeur vénale nette si elle est inférieure.")
    X("CO 960d : AI = détention à plus de 12 mois ; participation ≥ 20 % des voix.")
    X("CO 960e : dettes à la valeur nominale ; provisions obligatoires (al. 2) ou facultatives (al. 3) ; pas d'obligation de dissoudre (al. 4).")
    X("CO 961b : tableau des flux de trésorerie en 3 secteurs (exploitation, investissement, financement).")
    G("CO 960a al. 4 et 960e al. 4 laissent la porte ouverte aux réserves latentes (en contradiction avec 960 al. 2).")
    S("[37 p.32-38, p.40] ; [57 p.9]")
  end)

  ------------------------------------------------------------------ pièges et barème
  local p37 = ecr("Pièges chap. 37", "pieges37", "Pièges : chap. 37", function()
    T("Réserves latentes, évaluation")
    A("C'est la VARIATION des RL qui change le résultat, pas la RL elle-même.")
    A("FP réels : + RL au 31.12 (pas la variation).")
    A("Ducroire en négatif : RL = comptable − réelle en valeur absolue.")
    A("Stock 2/3 : réelle = comptable × 3/2 ; « RL = 1/3 du réel » : comptable = réel × 2/3.")
    A("Stock (960c) : article par article, jamais sur le total.")
    A("Titres cotés : cours du 31.12 même plus haut ; non cotés : jamais au-dessus du prix d'achat.")
    A("Ducroire fiscal : 5 % des créances commerciales seulement (exclure AFC, etc.).")
    A("Résultat publié négatif : garder le signe (−40 − 40 = −80).")
    S("PLAN-CLASSEUR-COMPTA.md §2.1 ; [C25] ex. 1, 4, 7, 9")
  end)

  local p44 = ecr("Pièges chap. 44", "pieges44", "Pièges : chap. 44", function()
    T("Seuil, compte de résultat")
    A("Augmentation de stock côté PRODUITS (diminue le PRAMV) ; déductions accordées côté charges.")
    A("1er degré = 3 pts sur 4 : soigner PRAMV et variation de stock.")
    A("Quantités arrondies à l'unité SUPÉRIEURE (142,5 → 143).")
    A("Période des charges fixes (jour, mois, an) = période du seuil.")
    A("Base du taux de marge : 33 1/3 % du PVN ≠ 50 % du PRAMV.")
    A("Graphique : 4 droites nommées, CA lus et annotés ; perte visée ⇒ CA sous le seuil.")
    A("Recettes annexes : en déduction des charges fixes.")
    A("Ex. 10 2025 : chiffres du prof en référence (850 ; 6'750 ; +11,1 %), méthode du livre en regard.")
    S("PLAN-CLASSEUR-COMPTA.md §2.2 ; [B] R3, R9, R10")
  end)

  local p51 = ecr("Pièges chap. 51", "pieges51", "Pièges : chap. 51", function()
    T("Ratios")
    A("Prendre la bonne année (N ou N−1) et garder le classement du bilan donné.")
    A("Chaque ratio de liquidité ou de couverture : commentaire (valeur, norme, conséquence) = 2 pts.")
    A("% ou décimal comme le prof : liquidités 14.44 %, couvertures 1.28 ; ex. 5 tout en décimal.")
    A("Rotations : moyenne des 2 bilans ; PRAMA pour les fournisseurs, PRAMV pour les stocks.")
    A("EBIT = avant charges et produits financiers (et impôts).")
    A("Bilan analytique : répartir le bénéfice avant de classer ; titres de placement = liquidités, participations = AI.")
    A("Hors 12.11 : effet de levier, décomposition du ROI, cycle des liquidités.")
    S("PLAN-CLASSEUR-COMPTA.md §2.3 ; [B] R6, R7 ; CLAUDE.md du cours")
  end)

  local bareme = ecr("Barème : règles R1-R10", "bareme", "Barème du prof", function()
    T("Règles de notation (corrigé 2025)")
    X("R1 Points par étape : chaque montant intermédiaire compte.")
    X("R2 Tableau des RL : points par ligne (ducroire, stock 2 pts ; autres 1).")
    X("R3 CR : 1er degré 3 pts, 2e degré 1 pt.")
    X("R4 Un point par grandeur demandée (PRAMA, PRAMV, CAN, BR, FP réels).")
    X("R5 Formule écrite avant le calcul.")
    X("R6 Ratio 0,5 pt, commentaire 2 pts.")
    X("R7 Ratio en fraction puis résultat (% ou décimal).")
    X("R8 Évaluation au bilan en tableau, prix retenu explicite.")
    X("R9 Quantités à l'unité supérieure.")
    X("R10 Graphique : 4 droites, CA lus et annotés.")
    G("Présentation : nom, prénom, classe sur TOUTES les feuilles ; tableaux alignés ; ≈ 3,5 min par point.")
    S("[B] §2, §5, §6")
  end)

  local pieges = sousMenu("Pièges et barème", "Pièges et barème", {p37, p44, p51, bareme})

  ------------------------------------------------------------------ phrases de commentaire
  local phrases = ecr("Phrases de commentaire", "phrases", "Phrases de commentaire", function()
    T("Structure d'un commentaire")
    X("1. Valeur chiffrée  2. Comparaison à la valeur indicative du manuel  3. Conséquence pour l'entreprise (hypothèse, risque).")
    T("Le prof, test 2025 ex. 3")
    X("Liquidités (2 pts) : « L'entreprise a un ratio 1 de mauvaise façon, mais ses créances clients devraient lui permettre de s'en sortir aisément. »")
    X("Couverture (2 pts) : « La règle d'or est respectée et elle se paie ses actifs immobilisés avec ses fonds propres, donc tout va bien. »")
    G("Version complète (hypothèse du barème) : L1 14 % < 20-30 % ; L2 119 % ≥ 100 % → peut payer ses dettes à c.t. ; couverture 2 = 1.75 > 1 (règle d'or) ; couverture 1 = 1.28 : AI financés entièrement par les FP.")
    T("Le prof, 51.10 (ratio par ratio)")
    X("L1 49.50 % : « Ratio un peu trop élevé par rapport à la norme (entre 0.2 et 0.3). »")
    X("L2 89.62 % : « Ratio un peu faible par rapport à la norme (min. 100 %). »")
    X("Endettement 43.78 % : « Endettement faible. » ; financement propre 56.22 % : « Capitaux propres élevés. Sécurité en cas de pertes. »")
    X("Autofinancement 16.67 % : « Dépend de l'âge de l'entreprise et des bénéfices antérieurs. »")
    X("Couverture 1 73.58 % : « Dans la norme (entre 60 et 80 %). » ; couverture 2 96.42 % : « Ratio un peu faible par rapport à la règle d'or (min 100 %). »")
    T("Le prof, 51.8 (trois entreprises)")
    X("Liquidité : « nettement en excédent de liquidités. Peut-être est-ce volontaire pour acheter une autre entreprise ou réaliser prochainement des investissements importants » ; « assez dans la norme (entre 0.2 et 0.3) » ; « largement en manque de liquidités. De plus, ses dettes à court terme sont très importantes ».")
    X("Financement : « avant tout par des fonds propres : cela va compromettre la rentabilité des fonds propres, en revanche les risques sont moindres » ; « correspond assez à la norme » ; « surendettée et très vulnérable en cas de perte ».")
    T("Gabarits (à reformuler)")
    G("Rotation : « Les clients paient en moyenne en … jours pour un délai accordé de … jours : il faut les relancer. »")
    G("Stock : « Le stock reste en moyenne … jours : à réduire sans risquer la rupture. »")
    G("Couverture 2 élevée et AI faibles : « La règle d'or est respectée, mais surtout parce que les immobilisations sont faibles. »")
    S("[C25] ex. 3 ; [c51 p.1-2] (51.8), [c51 p.3-4] (51.10) ; [B] §3 ; [51 p.27-30]")
  end)

  ------------------------------------------------------------------ sources
  local sources = ecr("Sources (abréviations)", "sources", "Sources", function()
    T("Abréviations des sources")
    X("[37 p.N], [44 p.N], [51 p.N], [57 p.N], [59 p.N] : exercices/chap-NN/enonce.md, page PDF N (chap. 51 : page imprimée ≠ PDF, p.11 PDF = p.18 imprimée).")
    X("[c37 p.N]… : exercices/chap-NN/corrige-prof.pdf, page N.")
    X("[R] : sources/txt/Liste des ratios 2018 Profil M.md (26 ratios).")
    X("[T25] / [C25] : examens/2025-11-intermediaire/txt/enonce.md / corrige-prof.md.")
    X("[B] : examens/2026-11-intermediaire/BAREME.md.")
    X("glossaire.md : définitions et lectures des ratios.")
    G("Ce classeur ne va pas au test (calculatrice simple, sans résumé) : tout ici doit être su par cœur.")
  end)

  -- quelques écrans indexés pour la recherche (consignes « nommer les droites », « base légale », « expliquez ce que… »)
  sGraphe.forts, sGraphe.mots, sGraphe.si = "nommer accolade quatre", "droite graph mesurer seuil", "nommer les 4 droites, les accolades"
  co.forts, co.mots, co.si = "co article legal loi", "base choix evaluation 960", "base légale d'une évaluation"
  phrases.forts, phrases.mots, phrases.si = "phrase commentaire", "expliquer signifient commenter interpretation ratio", "rédiger le commentaire d'un ratio"
  table.insert(definitions.sous, co)   -- Articles du CO rangés sous Définitions (aide-mémoire : 9 entrées)
  table.insert(MENUS_COMPTA, {ordre = 10, titre = "Aide-mémoire", items = {
    revision, tableaux, schemas, ratiosMenu, formules, definitions, pieges, phrases, sources,
  }})
end
