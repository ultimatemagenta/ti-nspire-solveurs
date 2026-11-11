-- 44_seuil.lua : chapitre 44, compte de résultat à 2 degrés, seuil de rentabilité, marge contributive
-- Types B1-B10 du plan (PLAN-CLASSEUR-COMPTA.md, § 2.2) + extensions (hors cours) : marge de sécurité,
-- levier opérationnel, seuil multiproduits. Données par défaut = corrigés du prof (indiqués dans chaque solveur).
do
  local num, calc = COMMUN.num, COMMUN.calc
  local EPS = 1e-9

  -- montants : entier sans décimales, sinon 2 décimales (format du prof : 420'000, 8'274'285.70)
  local function mt(x)
    if type(x) ~= "number" then return "?" end
    if math.abs(x - math.floor(x + 0.5)) < 1e-6 then return fmt(math.floor(x + 0.5)) end
    return fmt(x, 2)
  end
  local function m2(x) return fmt(x, 2) end
  -- arrondi aux 5 centimes (corrigés du recueil : 8'274'285.70, 13'988'571.45)
  local function r5(x) return math.floor(x * 20 + 0.5) / 20 end
  -- quantité arrondie à l'unité supérieure (corrigé 2025, ex. 6 b)
  local function sup(x) return math.ceil(x - EPS) end
  -- taux « à la manière du prof » : 35 %, 43.75 %, 80.125 %
  local function tx(t, d)
    if not t then return "?" end
    local s = string.format("%." .. (d or 3) .. "f", t * 100)
    s = s:gsub("0+$", ""); s = s:gsub("%.$", "")
    return s .. " %"
  end
  local function dec(x, d)
    local s = fmt(x, d or 2)
    if s:find("%.") then s = s:gsub("0+$", ""); s = s:gsub("%.$", "") end
    return s
  end
  local function nz(x) return x and math.abs(x) > EPS end
  local function lancer(champs, f) return function(txt) f(COMMUN.lireChamps(txt or "", champs)) end end
  local function menu(titre, champs, f) return function() COMMUN.formulaire(titre, champs, function(v) f(v) end) end end

  local MOIS = {"janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"}
  -- jour n d'une année commerciale de 360 jours (mois de 30 jours) -> « 18 mai »
  local function dateJour(n)
    local m = math.max(1, math.min(12, math.ceil(n / 30)))
    return (n - 30 * (m - 1)) .. " " .. MOIS[m]
  end

  -- graphique du seuil : 4 droites (CAN, marge brute, prix de revient, frais fixes), axes normalisés 0-100
  local function graphique(pv, cv, cf, qmax, reperes, nomCA)
    local ymax = pv * qmax
    local function P(q, v) return {q / qmax * 100, v / ymax * 100} end
    local c = {
      {pts = {P(0, 0), P(qmax, pv * qmax)}, coul = {200, 0, 0}},
      {pts = {P(0, 0), P(qmax, (pv - cv) * qmax)}, coul = {0, 140, 0}},
      {pts = {P(0, cf), P(qmax, cf + cv * qmax)}, coul = {0, 90, 200}},
      {pts = {P(0, cf), P(qmax, cf)}, coul = {210, 120, 0}},
    }
    for _, r in ipairs(reperes or {}) do
      table.insert(c, {pts = {P(r.q, 0), P(r.q, pv * r.q)}, coul = {150, 150, 150}})
    end
    table.insert(DOC, {k = "courbes", courbes = c, lo = 0, hi = 100,
      legende = "x : 100 = " .. fmt(qmax) .. " u ; y : 100 = " .. fmt(ymax) .. " CHF"})
    G("Rouge = " .. (nomCA or "CAN") .. " ; vert = marge brute ; bleu = prix de revient (FF + FV) ; orange = frais fixes ; gris = repères.")
    GRILLE("Points pour tracer les droites", {
      {nomCA or "CAN", "0", fmt(pv * qmax)},
      {"Marge brute", "0", fmt((pv - cv) * qmax)},
      {"Prix de revient", fmt(cf), fmt(cf + cv * qmax)},
      {"Frais fixes", fmt(cf), fmt(cf)},
    }, {entetes = {"Droite", "q = 0", "q = " .. fmt(qmax)}})
  end

  local function qmaxRond(q)
    local b = 10 ^ math.floor(math.log(q) / math.log(10))
    for _, k in ipairs({1, 1.2, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10}) do if k * b >= q then return k * b end end
    return 10 * b
  end

  ------------------------------------------------------------------ B1 compte de résultat à 2 degrés
  local CH_CR = {
    {cle = "vb", lib = "ventes brutes", defaut = "2000"},
    {cle = "da", lib = "déductions accordées", defaut = "30"},
    {cle = "pc", lib = "pertes sur créances", defaut = "0"},
    {cle = "fv", lib = "frais de vente", defaut = "0"},
    {cle = "ab", lib = "achats bruts", defaut = "1100"},
    {cle = "do", lib = "déductions obtenues", defaut = "20"},
    {cle = "fa", lib = "frais d'achats", defaut = "70"},
    {cle = "ace", lib = "autres charges d'exploitation", defaut = "400"},
    {cle = "si", lib = "inventaire initial au PRA", defaut = "150"},
    {cle = "sf", lib = "inventaire final au PRA", defaut = "250"},
  }
  local function cr2(v)
    vider()
    T("Compte de résultat à 2 degrés")
    G("Méthode (modèle : 44.1 ; test 2025 ex. 2) : 1er degré = opérations sur marchandises → marge brute ; 2e degré = ACE → résultat net. Formules du 1er degré écrites avant le calcul (44 p.3).")
    local vb, da, pc, fv, ab, dob, fa, ace = v.vb or 0, v.da or 0, v.pc or 0, v.fv or 0, v.ab or 0, v["do"] or 0, v.fa or 0, v.ace or 0
    local varS = (v.sf or 0) - (v.si or 0)   -- > 0 augmentation, < 0 diminution
    local can = vb - da - pc - fv
    local prama = ab + fa - dob
    local pramv = prama - varS
    local mb = can - pramv
    local bn = mb - ace
    -- 1er degré
    local L1, tch, tpr = {}, 0, 0
    local function ch(l, x) if nz(x) then table.insert(L1, {l, mt(x), ""}); tch = tch + x end end
    local function pr(l, x) if nz(x) then table.insert(L1, {l, "", mt(x)}); tpr = tpr + x end end
    ch("Déductions accordées", da); ch("Pertes sur créances", pc); ch("Frais de vente", fv)
    ch("Achats", ab); ch("Frais d'achats", fa)
    pr("Ventes", vb); pr("Déductions obtenues", dob)
    if varS > 0 then pr("Augmentation du stock", varS) elseif varS < 0 then ch("Diminution du stock", -varS) end
    if mb >= 0 then table.insert(L1, {"Marge brute", mt(mb), "", gras = true}); tch = tch + mb
    else table.insert(L1, {"Marge brute (négative)", "", mt(-mb), gras = true}); tpr = tpr - mb end
    table.insert(L1, {"Total", mt(tch), mt(tpr), gras = true, trait = true, fond = true})
    GRILLE("1er degré", L1, {entetes = {"", "Charges", "Produits"}})
    local L2 = {{"ACE", mt(ace), ""}, {"Marge brute", "", mt(mb)}}
    if bn >= 0 then table.insert(L2, {"BN", mt(bn), "", gras = true})
    else table.insert(L2, {"PN", "", mt(-bn), gras = true}) end
    local t2 = math.max(ace + math.max(bn, 0), mb + math.max(-bn, 0))
    table.insert(L2, {"Total", mt(t2), mt(t2), gras = true, trait = true, fond = true})
    GRILLE("2e degré", L2, {entetes = {"", "Charges", "Produits"}})
    G("Augmentation du stock côté produits (elle diminue le PRAMV) ; diminution côté charges. Déductions accordées côté charges, obtenues côté produits.")
    T("PRAMA, PRAMV, CAN, marge brute")
    calc("PRAMA", "achats + frais d'achats − déductions obtenues", mt(ab) .. " + " .. mt(fa) .. " − " .. mt(dob), m2(prama))
    local sv = varS >= 0 and (" − " .. mt(varS) .. " (augmentation)") or (" + " .. mt(-varS) .. " (diminution)")
    calc("PRAMV", "PRAMA ± variation de stock (+ diminution, − augmentation)", mt(prama) .. sv, m2(pramv))
    local app = mt(vb) .. " − " .. mt(da)
    if nz(pc) then app = app .. " − " .. mt(pc) end
    if nz(fv) then app = app .. " − " .. mt(fv) end
    calc("CAN", "ventes − déductions accordées" .. ((nz(pc) or nz(fv)) and " − pertes sur créances − frais de vente" or ""), app, m2(can))
    calc("MB", "CAN − PRAMV", mt(can) .. " − " .. mt(pramv), m2(mb))
    if nz(can) then calc("MB en % du CAN", "MB × 100 ÷ CAN", mt(mb) .. " × 100 ÷ " .. mt(can), tx(mb / can, 2)) end
    calc(bn >= 0 and "BN" or "PN", "MB − ACE", mt(mb) .. " − " .. mt(ace), m2(bn))
    GRILLE("Présentation en liste", {
      {"Chiffre d'affaires net", mt(can)}, {"./. PRAMV", mt(-pramv)},
      {"Marge brute", mt(mb), gras = true, trait = true}, {"./. ACE", mt(-ace)},
      {bn >= 0 and "Bénéfice net" or "Perte nette", mt(bn), gras = true, trait = true}})
    G("Contrôle : MB = FF + BN → " .. mt(mb) .. " = " .. mt(ace) .. " + " .. mt(bn) .. ". Défaut = test 2025 ex. 2 (prof : PRAMA 1'150, PRAMV 1'050, CAN 1'970, MB 920, BN 520) ; 44.1 : vb=1000000;da=40000;ab=600000;do=30000;fa=50000;ace=340000;si=120000;sf=200000.")
    montrer("CR à 2 degrés")
  end
  SOLVEURS.cr2 = lancer(CH_CR, cr2)

  ------------------------------------------------------------------ B3, B4 seuil en quantité, bénéfice visé, résultat à un volume
  local CH_Q = {
    {cle = "pv", lib = "prix de vente unitaire (0 si inconnu)", defaut = "10"},
    {cle = "cv", lib = "coût variable unitaire (0 si inconnu)", defaut = "2"},
    {cle = "t", lib = "taux de marge brute (si PV ou CV inconnu)", defaut = "0"},
    {cle = "base", lib = "base du taux : 0 = % du PVN, 1 = % du coût variable", defaut = "0"},
    {cle = "cf", lib = "charges fixes de la période", defaut = "640"},
    {cle = "bn", lib = "bénéfice visé (négatif = perte)", defaut = "500"},
    {cle = "q", lib = "quantité vendue (résultat, 0 = non)", defaut = "0"},
  }
  local function seuilQ(v)
    vider()
    T("Seuil en quantité, bénéfice visé")
    G("Méthode (modèles : 44.6, 44.7, 44.8 ; test 2025 ex. 6) : chaque unité vendue rapporte sa marge brute unitaire, qui couvre d'abord les charges fixes. Quantité = montant à couvrir ÷ MB unitaire, arrondie à l'unité supérieure.")
    local pv, cv, t, cf, bn, q = v.pv or 0, v.cv or 0, v.t or 0, v.cf or 0, v.bn or 0, v.q or 0
    local mbu
    if nz(pv) and nz(cv) then
      mbu = pv - cv
      calc("Marge brute unitaire", "PV − CV", m2(pv) .. " − " .. m2(cv), m2(mbu))
    elseif nz(cv) and nz(t) then
      if (v.base or 0) == 0 then
        mbu = cv * t / (1 - t)
        G("Taux en % du PVN : le coût variable vaut " .. tx(1 - t) .. " du PVN (44.7 b).")
        calc("Marge brute unitaire", "CV × taux ÷ (100 % − taux)", m2(cv) .. " × " .. tx(t) .. " ÷ " .. tx(1 - t), m2(mbu))
      else
        mbu = cv * t
        G("Taux en % du coût variable (44.8 c, piège de la base).")
        calc("Marge brute unitaire", "CV × taux", m2(cv) .. " × " .. tx(t), m2(mbu))
      end
      pv = cv + mbu
      calc("Prix de vente", "CV + MB unitaire", m2(cv) .. " + " .. m2(mbu), m2(pv))
    elseif nz(pv) and nz(t) then
      if (v.base or 0) == 0 then
        mbu = pv * t
        calc("Marge brute unitaire", "PV × taux", m2(pv) .. " × " .. tx(t), m2(mbu))
      else
        mbu = pv * t / (1 + t)
        G("Taux en % du coût variable : le PV vaut " .. tx(1 + t) .. " du coût (44.7 c).")
        calc("Marge brute unitaire", "PV × taux ÷ (100 % + taux)", m2(pv) .. " × " .. tx(t) .. " ÷ " .. tx(1 + t), m2(mbu))
      end
      cv = pv - mbu
      G("Coût variable = " .. m2(pv) .. " − " .. m2(mbu) .. " = " .. m2(cv))
    else
      A("Il faut PV et CV, ou l'un des deux et le taux de marge."); montrer("Seuil en quantité"); return
    end
    if mbu <= EPS then A("Marge brute unitaire nulle ou négative : pas de seuil."); montrer("Seuil en quantité"); return end
    T("Point mort")
    local qpm = cf / mbu
    calc("Quantité au point mort", "charges fixes ÷ MB unitaire", mt(cf) .. " ÷ " .. m2(mbu), dec(qpm) .. (math.abs(qpm - sup(qpm)) > 1e-6 and (" → " .. fmt(sup(qpm)) .. " unités (unité supérieure)") or " unités"))
    calc("CAN au point mort", "quantité × PV", dec(qpm) .. " × " .. m2(pv), m2(qpm * pv))
    if math.abs(qpm - sup(qpm)) > 1e-6 then
      G("Avec " .. math.floor(qpm) .. " unités on est encore en perte, avec " .. fmt(sup(qpm)) .. " déjà en bénéfice (44.15).")
    end
    if nz(bn) then
      T(bn > 0 and "Quantité pour le bénéfice visé" or "Quantité vendue avec cette perte")
      local acouv = cf + bn
      calc(bn > 0 and "Marge brute nécessaire" or "Marge brute totale", bn > 0 and "CF + BN visé" or "CF − perte", mt(cf) .. (bn > 0 and " + " or " − ") .. mt(math.abs(bn)), m2(acouv))
      local qb = acouv / mbu
      calc("Quantité", "marge nécessaire ÷ MB unitaire", mt(acouv) .. " ÷ " .. m2(mbu), dec(qb) .. (math.abs(qb - sup(qb)) > 1e-6 and (" → " .. fmt(sup(qb)) .. " unités") or " unités"))
      calc("CAN correspondant", "quantité × PV", mt(sup(qb)) .. " × " .. m2(pv), m2(sup(qb) * pv))
    end
    if nz(q) then
      T("Résultat pour " .. mt(q) .. " unités")
      local ca, fvar, mb = q * pv, q * cv, q * mbu
      GRILLE("CR en liste (44.2 d)", {
        {"CAN", mt(q) .. " × " .. dec(pv), m2(ca)},
        {"./. PRAMV", mt(q) .. " × " .. dec(cv), m2(-fvar)},
        {"MB", mt(q) .. " × " .. dec(mbu), m2(mb), trait = true},
        {"./. FF", "", m2(-cf)},
        {mb - cf >= 0 and "BN" or "PN", "", m2(mb - cf), gras = true, trait = true}})
    end
    G("Défaut = test 2025 ex. 6 (prof : 80 ; 1'140 ÷ 8 = 142.5 → 143 ; le corrigé écrit « 117.5 » par coquille). 44.6 : pv=18;cv=8;cf=750;bn=250 → 75, 100. 44.7 b : pv=0;cv=9;t=100/3%;base=0;cf=90000 → 4.50, 20'000, 270'000. 44.8 b : pv=0;cv=9;t=25%;base=0;cf=63000;bn=-6000 → 19'000.")
    montrer("Seuil en quantité")
  end
  SOLVEURS.seuilQ = lancer(CH_Q, seuilQ)

  ------------------------------------------------------------------ B2 seuil en valeur par le taux de marge brute
  local CH_V = {
    {cle = "ca", lib = "chiffre d'affaires net", defaut = "12568000"},
    {cle = "pramv", lib = "PRAMV (charges variables)", defaut = "8169200"},
    {cle = "cf", lib = "charges fixes", defaut = "2896000"},
    {cle = "bn", lib = "bénéfice net visé (0 = non)", defaut = "2000000"},
    {cle = "fp", lib = "fonds propres à rémunérer (0 = non)", defaut = "0"},
    {cle = "tfp", lib = "taux de rémunération des FP", defaut = "0"},
  }
  local function seuilV(v)
    vider()
    T("Seuil en valeur (taux de marge brute)")
    G("Méthode (modèles : 44.3, 44.10 ; 44 p.8, p.10) : le taux de marge brute dit quelle part de chaque franc de CA reste pour couvrir les charges fixes ; CA au point mort = CF ÷ taux.")
    local ca, pramv, cf, bn = v.ca or 0, v.pramv or 0, v.cf or 0, v.bn or 0
    if not nz(ca) then A("CA nul."); montrer("Seuil en valeur"); return end
    local mb = ca - pramv
    GRILLE("Compte de résultat", {{"Chiffre d'affaires", mt(ca)}, {"./. PRAMV", mt(-pramv)},
      {"Marge brute", mt(mb), gras = true, trait = true}, {"./. Charges fixes", mt(-cf)},
      {mb - cf >= 0 and "Marge nette" or "Perte nette", mt(mb - cf), gras = true, trait = true}})
    calc("Marge brute", "CA − PRAMV", mt(ca) .. " − " .. mt(pramv), m2(mb))
    local t = mb / ca
    calc("Taux de marge brute", "MB × 100 ÷ CA", mt(mb) .. " × 100 ÷ " .. mt(ca), tx(t))
    if t <= EPS then A("Taux de marge nul ou négatif : pas de point mort."); montrer("Seuil en valeur"); return end
    T("CA au point mort (deux formules)")
    calc("CA au PM", "CF × 100 ÷ taux de MB", mt(cf) .. " × 100 ÷ " .. dec(t * 100, 3), m2(r5(cf / t)))
    calc("CA au PM", "CA × CF ÷ MB", mt(ca) .. " × " .. mt(cf) .. " ÷ " .. mt(mb), m2(r5(ca * cf / mb)))
    G("Arrondi aux 5 centimes, comme les corrigés du recueil.")
    local fp, tfp = v.fp or 0, v.tfp or 0
    if nz(bn) or (nz(fp) and nz(tfp)) then
      T("CA pour le bénéfice visé")
      local L, ac = {{"Frais fixes", mt(cf)}}, cf
      if nz(fp) and nz(tfp) then
        local it = fp * tfp
        calc("Intérêt sur fonds propres", "taux × FP", tx(tfp) .. " × " .. mt(fp), m2(it))
        table.insert(L, {"Intérêt sur FP", mt(it)}); ac = ac + it
      end
      table.insert(L, {"Bénéfice prévisionnel", mt(bn)}); ac = ac + bn
      table.insert(L, {"À couvrir", mt(ac), gras = true, trait = true})
      GRILLE("Montant à couvrir (44.10 c)", L)
      calc("CA visé", "à couvrir × 100 ÷ taux de MB", mt(ac) .. " × 100 ÷ " .. dec(t * 100, 3), m2(r5(ac / t)))
    end
    G("Défaut = 44.3 (prof : 35 %, 8'274'285.70, 13'988'571.45). 44.10 : ca=2000000;pramv=1680000;cf=460000;bn=150000;fp=2400000;tfp=5% → 16 %, 2'875'000, 4'562'500.")
    montrer("Seuil en valeur")
  end
  SOLVEURS.seuilV = lancer(CH_V, seuilV)

  ------------------------------------------------------------------ B4 base du taux, CAN depuis la marge brute
  local CH_T = {
    {cle = "t", lib = "taux de marge brute", defaut = "50%"},
    {cle = "base", lib = "base : 0 = % du CAN, 1 = % du PRAMV", defaut = "1"},
    {cle = "mb", lib = "marge brute (bénéfice brut) connue", defaut = "15000"},
  }
  local function tauxBase(v)
    vider()
    T("Base du taux, CAN depuis la MB")
    G("Méthode (modèle : 44.8 c) : un taux « en % du PRAMV » se rapporte au coût ; le ramener au CAN avant de calculer. Si PRAMV = 100 %, MB = taux et CAN = 100 % + taux.")
    local t, mb = v.t or 0, v.mb or 0
    local tc, tv
    if (v.base or 0) == 1 then
      tc = t; tv = t / (1 + t)
      calc("Taux en % du CAN", "taux ÷ (100 % + taux)", tx(t) .. " ÷ " .. tx(1 + t), tx(tv))
    else
      tv = t; tc = t / (1 - t)
      calc("Taux en % du PRAMV", "taux ÷ (100 % − taux)", tx(t) .. " ÷ " .. tx(1 - t), tx(tc))
    end
    if nz(mb) and tv > EPS then
      local can = mb / tv
      calc("CAN", "MB × (100 % + taux du PRAMV) ÷ taux du PRAMV", mt(mb) .. " × " .. tx(1 + tc) .. " ÷ " .. tx(tc), m2(can))
      calc("PRAMV", "CAN − MB", mt(can) .. " − " .. mt(mb), m2(can - mb))
    end
    G("Défaut = 44.8 c (prof : CAN = 15'000 × 150 ÷ 50 = 45'000). Piège : 33 1/3 % du PVN = 50 % du coût.")
    montrer("Base du taux")
  end
  SOLVEURS.taux = lancer(CH_T, tauxBase)

  ------------------------------------------------------------------ B7 budget : PRAMV, taux, PM, résultat, prévisions, date
  local CH_B = {
    {cle = "ca", lib = "CAN", defaut = "800000"},
    {cle = "ach", lib = "achats (PRAMA)", defaut = "360000"},
    {cle = "aug", lib = "augmentation de stock (− = diminution)", defaut = "40000"},
    {cle = "cf", lib = "charges fixes", defaut = "120000"},
    {cle = "cab", lib = "CA du budget (0 = non)", defaut = "760000"},
    {cle = "dt", lib = "baisse du taux en points (− = hausse)", defaut = "2"},
    {cle = "dcf", lib = "hausse des charges fixes", defaut = "20000"},
  }
  local function budget(v)
    vider()
    T("Budget : PM, résultat, prévisions")
    G("Méthode (modèle : 44.9 ; date : 44.11) : PRAMV → MB et taux → CA au PM = CF ÷ taux ; à un autre CA, BN = taux × CA − CF.")
    local ca, ach, aug, cf = v.ca or 0, v.ach or 0, v.aug or 0, v.cf or 0
    local pramv = ach - aug
    calc("a) PRAMV", "achats − augmentation de stock", mt(ach) .. " − " .. mt(aug), m2(pramv))
    local mb = ca - pramv
    calc("b) Marge brute", "CAN − PRAMV", mt(ca) .. " − " .. mt(pramv), m2(mb))
    local t = mb / ca
    calc("Taux de marge brute", "MB × 100 ÷ CAN", mt(mb) .. " × 100 ÷ " .. mt(ca), tx(t))
    if t <= EPS then A("Taux nul ou négatif."); montrer("Budget"); return end
    local pm = r5(cf / t)
    calc("c) CA au point mort", "CF × 100 ÷ taux", mt(cf) .. " × 100 ÷ " .. dec(t * 100, 3), m2(pm))
    local j = sup(pm * 360 / ca)
    calc("Date du PM (ventes régulières)", "CA au PM × 360 ÷ CAN", m2(pm) .. " × 360 ÷ " .. mt(ca), j .. " jours, soit le " .. dateJour(j))
    local bn0 = mb - cf
    if nz(v.cab) then
      local bb = t * v.cab
      calc("d) Bénéfice brut", "taux × CA du budget", tx(t) .. " × " .. mt(v.cab), m2(bb))
      calc("Bénéfice net", "bénéfice brut − CF", mt(bb) .. " − " .. mt(cf), m2(bb - cf))
    end
    if nz(v.dt) or nz(v.dcf) then
      T("Prévisions")
      local t2, cf2 = t - (v.dt or 0) / 100, cf + (v.dcf or 0)
      calc("e) Taux de marge brute", "taux − baisse", tx(t) .. " − " .. dec(v.dt or 0) .. " %", tx(t2))
      calc("Frais fixes prévus", "CF + hausse", mt(cf) .. " + " .. mt(v.dcf or 0), m2(cf2))
      if t2 <= EPS then A("Nouveau taux nul ou négatif."); montrer("Budget"); return end
      calc("CAN au point mort", "CF prévus ÷ taux", mt(cf2) .. " ÷ " .. tx(t2), m2(r5(cf2 / t2)))
      GRILLE("f) À couvrir (même BN que l'exercice)", {
        {"Bénéfice prévu", mt(mb) .. " − " .. mt(cf), mt(bn0)},
        {"Charges fixes", "", mt(cf2)},
        {"À couvrir", "", mt(bn0 + cf2), gras = true, trait = true}})
      calc("CAN à réaliser", "à couvrir ÷ taux", mt(bn0 + cf2) .. " ÷ " .. tx(t2), m2(r5((bn0 + cf2) / t2)))
      local bb2 = t2 * ca
      GRILLE("g) Résultat si le CA reste à " .. mt(ca), {
        {"Bénéfice brut", tx(t2) .. " × " .. mt(ca), m2(bb2)},
        {"./. Charges fixes", "", m2(-cf2)},
        {bb2 - cf2 >= 0 and "Bénéfice net" or "Perte nette", "", m2(bb2 - cf2), gras = true, trait = true}})
    end
    G("Défaut = 44.9 (prof : 320'000 ; 60 % ; 200'000 ; 336'000 ; 58 %, 241'379.30 ; 862'068.95 ; 324'000). Année de 360 jours, mois de 30 jours.")
    montrer("Budget")
  end
  SOLVEURS.budget = lancer(CH_B, budget)

  ------------------------------------------------------------------ B7 CR prévisionnel à 2 degrés et date du point mort
  local CH_P = {
    {cle = "ca", lib = "CA budgété", defaut = "8200000"},
    {cle = "t", lib = "taux de marge brute (% du CA)", defaut = "60%"},
    {cle = "pers", lib = "charges de personnel", defaut = "1200000"},
    {cle = "autres", lib = "autres charges", defaut = "400000"},
    {cle = "amort", lib = "amortissements", defaut = "280000"},
  }
  local function crPrev(v)
    vider()
    T("CR prévisionnel, date du PM")
    G("Méthode (modèle : 44.11) : charges de marchandises = CA × (100 % − taux) ; MB = CA × taux ; 2e degré = charges fixes → marge nette. Date du PM : nombre de jours = 360 × CA au PM ÷ CA (activité régulière).")
    local ca, t = v.ca or 0, v.t or 0
    local mb = ca * t
    local cm = ca - mb
    local cf = (v.pers or 0) + (v.autres or 0) + (v.amort or 0)
    local mn = mb - cf
    calc("Charges marchandises", "CA × (100 % − taux)", mt(ca) .. " × " .. tx(1 - t), m2(cm))
    calc("Marge brute", "CA × taux", mt(ca) .. " × " .. tx(t), m2(mb))
    GRILLE("1er degré", {{"Charges marchandises", mt(cm), ""}, {"Chiffre d'affaires net", "", mt(ca)},
      {"Marge brute", mt(mb), "", gras = true}, {"Total", mt(ca), mt(ca), gras = true, trait = true, fond = true}},
      {entetes = {"", "Charges", "Produits"}})
    local L = {{"Marge brute", "", mt(mb)}}
    if nz(v.pers) then table.insert(L, {"Charges de personnel", mt(v.pers), ""}) end
    if nz(v.autres) then table.insert(L, {"Autres charges", mt(v.autres), ""}) end
    if nz(v.amort) then table.insert(L, {"Amortissements", mt(v.amort), ""}) end
    if mn >= 0 then table.insert(L, {"Marge nette", mt(mn), "", gras = true}) else table.insert(L, {"Perte nette", "", mt(-mn), gras = true}) end
    local tt = math.max(mb, cf)
    table.insert(L, {"Total", mt(tt), mt(tt), gras = true, trait = true, fond = true})
    GRILLE("2e degré", L, {entetes = {"", "Charges", "Produits"}})
    T("Date du point mort")
    calc("Charges fixes", "personnel + autres + amortissements", mt(v.pers or 0) .. " + " .. mt(v.autres or 0) .. " + " .. mt(v.amort or 0), m2(cf))
    if t <= EPS then A("Taux nul."); montrer("CR prévisionnel"); return end
    local pm = r5(cf / t)
    calc("CAN au point mort", "CF × 100 ÷ taux", mt(cf) .. " × 100 ÷ " .. dec(t * 100, 3), m2(pm))
    local jr = 360 * pm / ca
    calc("Nombre de jours", "360 × CA au PM ÷ CA", "360 × " .. m2(pm) .. " ÷ " .. mt(ca), dec(jr) .. " → " .. fmt(sup(jr)) .. " jours")
    R("Date du point mort : " .. fmt(sup(jr)) .. " jours après le début de l'année, soit le " .. dateJour(sup(jr)), "", "")
    G("Défaut = 44.11 (prof : 3'280'000 ; 4'920'000 ; marge nette 3'040'000 ; 3'133'333.35 ; 138 jours, 18 mai).")
    montrer("CR prévisionnel")
  end
  SOLVEURS.crprev = lancer(CH_P, crPrev)

  ------------------------------------------------------------------ B5 graphique du seuil
  local CH_G = {
    {cle = "pv", lib = "prix de vente unitaire", defaut = "15"},
    {cle = "cv", lib = "coût variable unitaire", defaut = "9"},
    {cle = "cf", lib = "coûts fixes", defaut = "150000"},
    {cle = "bn", lib = "bénéfice net visé (0 = non)", defaut = "30000"},
    {cle = "pn", lib = "perte nette visée (0 = non)", defaut = "60000"},
    {cle = "qmax", lib = "quantité max. de l'axe (0 = auto)", defaut = "30000"},
  }
  local function seuilGraphe(v)
    vider()
    T("Graphique du seuil")
    G("Méthode (modèles : 44.13, 44.14 ; test 2025 ex. 8 ; 44 p.10) : abscisse = quantités, ordonnée = CHF. Tracer 4 droites : CAN, marge brute, prix de revient (= FF + FV), frais fixes. Point mort à l'intersection CAN / prix de revient (et MB / FF).")
    local pv, cv, cf, bn, pn = v.pv or 0, v.cv or 0, v.cf or 0, v.bn or 0, v.pn or 0
    local mbu = pv - cv
    if mbu <= EPS then A("PV ≤ CV : pas de point mort."); montrer("Graphique du seuil"); return end
    calc("Marge brute unitaire", "PV − CV", m2(pv) .. " − " .. m2(cv), m2(mbu))
    local rep, L = {}, {}
    local function cas_(lib, montant)
      local q = (cf + montant) / mbu
      table.insert(rep, {q = q})
      table.insert(L, {lib, fmt(q, math.abs(q - math.floor(q + 0.5)) < 1e-6 and 0 or 2), mt(q * pv)})
      return q
    end
    if nz(pn) then cas_("PN = " .. mt(pn), -pn) end
    local qpm = cas_("PM (BN = 0)", 0)
    if nz(bn) then cas_("BN = " .. mt(bn), bn) end
    calc("Quantité au PM", "CF ÷ MB unitaire", mt(cf) .. " ÷ " .. m2(mbu), dec(qpm))
    if nz(bn) then calc("Quantité pour le BN", "(CF + BN) ÷ MB unitaire", "(" .. mt(cf) .. " + " .. mt(bn) .. ") ÷ " .. m2(mbu), dec((cf + bn) / mbu)) end
    if nz(pn) then calc("Quantité pour la PN", "(CF − PN) ÷ MB unitaire", "(" .. mt(cf) .. " − " .. mt(pn) .. ") ÷ " .. m2(mbu), dec((cf - pn) / mbu)) end
    GRILLE("CA à lire sur le graphique", L, {entetes = {"Cas", "Quantité", "CAN"}})
    local qm = v.qmax or 0
    if not nz(qm) then local mx = 0; for _, r in ipairs(rep) do mx = math.max(mx, r.q) end; qm = qmaxRond(mx * 1.15) end
    graphique(pv, cv, cf, qm, rep)
    G("Annoter : accolade BN entre CAN et prix de revient à droite du PM, PN à gauche ; nommer les 4 droites. Perte visée ⇒ CA sous le seuil.")
    G("Défaut = test 2025 ex. 8 et 44.13 (prof : 375'000 ; 450'000 ; 225'000).")
    montrer("Graphique du seuil")
  end
  SOLVEURS.graphe = lancer(CH_G, seuilGraphe)

  ------------------------------------------------------------------ B6 licence : quantité, prix minimum, baisse de prix
  local CH_L = {
    {cle = "pa", lib = "prix de revient d'achat unitaire", defaut = "80"},
    {cle = "cmin", lib = "commande minimale", defaut = "5000"},
    {cle = "pv", lib = "prix de vente", defaut = "120"},
    {cle = "cf", lib = "charges fixes annuelles", defaut = "180000"},
    {cle = "bn", lib = "bénéfice net visé", defaut = "50000"},
    {cle = "baisse", lib = "réduction du prix de vente", defaut = "10%"},
  }
  local function licenceCorps(v)
    local pa, cmin, pv, cf, bn, b = v.pa or 0, v.cmin or 0, v.pv or 0, v.cf or 0, v.bn or 0, v.baisse or 0
    local mcv = pv - pa
    T("a) Quantité pour le bénéfice")
    GRILLE("À couvrir", {{"Charges fixes", mt(cf)}, {"Bénéfice", mt(bn)}, {"À couvrir", mt(cf + bn), gras = true, trait = true}})
    calc("Marge sur coût variable unitaire", "PV − coût variable", m2(pv) .. " − " .. m2(pa), m2(mcv))
    if mcv <= EPS then A("PV ≤ coût : pas de solution."); return end
    local q = (cf + bn) / mcv
    calc("Nombre d'unités", "à couvrir ÷ marge unitaire", mt(cf + bn) .. " ÷ " .. m2(mcv), dec(q) .. (math.abs(q - sup(q)) > 1e-6 and (" → " .. fmt(sup(q))) or ""))
    T("b) Prix minimum (commande minimale)")
    if nz(cmin) then
      local mseuil = cf / cmin
      calc("Marge sur coût variable (seuil)", "CF ÷ commande minimale", mt(cf) .. " ÷ " .. mt(cmin), m2(mseuil))
      GRILLE("Prix minimum", {{"Prix d'achat unitaire", m2(pa)}, {"Marge s/ coût variable", m2(mseuil)},
        {"Prix de vente", m2(pa + mseuil), gras = true, trait = true}})
    end
    T("c) Baisse de prix et volume")
    local npv = pv * (1 - b)
    local nm = npv - pa
    GRILLE("Nouvelle marge", {{"Prix de vente initial", m2(pv)}, {"./. Réduction (" .. tx(b) .. ")", m2(-pv * b)},
      {"Nouveau prix de vente", m2(npv), trait = true}, {"./. Coût variable unit.", m2(-pa)},
      {"Marge s/ coût variable", m2(nm), gras = true, trait = true}})
    if nm <= EPS then A("La nouvelle marge est nulle ou négative : plus de seuil."); return end
    local s1, s2 = cf / mcv, cf / nm
    calc("Seuil avec PV à " .. m2(pv), "CF ÷ marge", mt(cf) .. " ÷ " .. m2(mcv), dec(s1) .. (math.abs(s1 - sup(s1)) > 1e-6 and (" → " .. fmt(sup(s1))) or ""))
    calc("Seuil avec PV à " .. m2(npv), "CF ÷ nouvelle marge", mt(cf) .. " ÷ " .. m2(nm), dec(s2) .. (math.abs(s2 - sup(s2)) > 1e-6 and (" → " .. fmt(sup(s2))) or ""))
    local d = sup(s2) - sup(s1)
    calc("Augmentation", "nouveau seuil − ancien seuil", fmt(sup(s2)) .. " − " .. fmt(sup(s1)), fmt(d) .. " unités")
    calc("Augmentation en %", "augmentation × 100 ÷ ancien seuil", fmt(d) .. " × 100 ÷ " .. fmt(sup(s1)), tx(d / sup(s1), 1))
  end
  local function licence(v)
    vider()
    T("Licence : quantité, prix min., baisse")
    G("Méthode (modèle : 44.16) : a) à couvrir = CF + BN, divisé par la marge sur coût variable unitaire ; b) marge minimale = CF ÷ commande minimale, prix = coût + marge ; c) nouvelle marge, seuils ancien et nouveau (unité supérieure), augmentation en %.")
    licenceCorps(v)
    G("Défaut = 44.16 (prof : 5'750 ; 116.00 ; 4'500 → 6'429, +1'929, 42.9 %).")
    montrer("Licence")
  end
  SOLVEURS.licence = lancer(CH_L, licence)

  local function licence2025()
    vider()
    T("Test 2025 ex. 10 : corrigé du prof")
    A("Référence = corrigé du prof, chiffres compris. Ses chiffres sont incohérents avec l'énoncé (CF 250'000) : méthode du livre en regard ci-dessous, à ne pas substituer.")
    GRILLE("Feuille du prof (7 pts)", {
      {"a) Charges fixes", "6'750'000"}, {"Bénéfice", "50'000"}, {"À couvrir (1 pt)", "6'800'000", trait = true},
      {"Marge s/ CV unitaire", "8'000"}, {"Nombre (1 pt)", "850", gras = true},
      {"b) Commande minimale", "1'000"}, {"Marge s/ CV (1 pt)", "250"}, {"Prix de vente (1 pt)", "6'750", gras = true},
      {"c) Nouveau PV", "7'200"}, {"Marge s/ CV (1 pt)", "700"},
      {"Seuil nouv. PV (1 pt)", "937.5"}, {"Seuil ancien PV", "843.75"}, {"Augmentation", "93.75"},
      {"Augmentation % (1 pt)", "11.1 %", gras = true}})
    G("Le prof divise par le PV (8'000, 7'200) au lieu de la marge et prend CF = 6'750'000 en a) et c).")
    licenceCorps({pa = 6500, cmin = 1000, pv = 8000, cf = 250000, bn = 50000, baisse = 0.1})
    G("Méthode du livre (44.16) : 200 ; 6'750 ; 167 → 358, +114.4 %.")
    montrer("Test 2025 ex. 10")
  end
  SOLVEURS.licence2025 = licence2025

  ------------------------------------------------------------------ B8 lot acheté, changement de prix en cours de vente
  local CH_LOT = {
    {cle = "qa", lib = "quantité achetée", defaut = "600"},
    {cle = "pa", lib = "prix d'achat unitaire", defaut = "6"},
    {cle = "pv", lib = "prix de vente initial", defaut = "11"},
    {cle = "cf", lib = "charges générales (fixes)", defaut = "1700"},
    {cle = "qv", lib = "quantité déjà vendue", defaut = "60"},
    {cle = "npv", lib = "nouveau prix de vente", defaut = "9"},
  }
  local function lot(v)
    vider()
    T("Lot : changement de prix")
    G("Méthode (modèle : 44.12) : les unités déjà vendues ont couvert une partie des frais fixes à l'ancienne marge ; le solde se couvre à la nouvelle marge. Nouveau seuil = déjà vendues + supplément.")
    local qa, pa, pv, cf, qv, npv = v.qa or 0, v.pa or 0, v.pv or 0, v.cf or 0, v.qv or 0, v.npv or 0
    local m1 = pv - pa
    if m1 <= EPS then A("PV ≤ prix d'achat."); montrer("Lot"); return end
    T("a) Seuil de rentabilité")
    calc("Marge brute unitaire", "PV − PA", m2(pv) .. " − " .. m2(pa), m2(m1))
    local s = cf / m1
    calc("Unités au point mort", "charges ÷ marge unitaire", mt(cf) .. " ÷ " .. m2(m1), dec(s) .. (math.abs(s - sup(s)) > 1e-6 and (" → " .. fmt(sup(s))) or ""))
    T("b) Bénéfice si tout est vendu")
    calc("Marge brute totale", "quantité × marge unitaire", mt(qa) .. " × " .. m2(m1), m2(qa * m1))
    calc("Bénéfice net", "MB totale − charges", mt(qa * m1) .. " − " .. mt(cf), m2(qa * m1 - cf))
    T("c) Nouveau seuil")
    local m2_ = npv - pa
    calc("Nouvelle marge brute", "nouveau PV − PA", m2(npv) .. " − " .. m2(pa), m2(m2_))
    local couv = qv * m1
    calc("Frais fixes déjà couverts", "déjà vendues × ancienne marge", mt(qv) .. " × " .. m2(m1), m2(couv))
    local reste = cf - couv
    if reste <= EPS then R("Les frais fixes sont déjà couverts : seuil atteint avec " .. mt(qv) .. " unités.", "", ""); montrer("Lot"); return end
    if m2_ <= EPS then A("Nouvelle marge nulle ou négative : le solde ne sera jamais couvert."); montrer("Lot"); return end
    local sp = reste / m2_
    calc("Unités supplémentaires", "(charges − déjà couverts) ÷ nouvelle marge", mt(reste) .. " ÷ " .. m2(m2_), dec(sp) .. (math.abs(sp - sup(sp)) > 1e-6 and (" → " .. fmt(sup(sp))) or ""))
    local ns = qv + sup(sp)
    calc("Nouveau seuil", "déjà vendues + supplément", mt(qv) .. " + " .. fmt(sup(sp)), fmt(ns) .. " unités")
    local bnf = couv + (qa - qv) * m2_ - cf
    if ns <= qa then
      G("Commentaire : le nouveau seuil (" .. fmt(ns) .. ") reste sous la quantité achetée (" .. fmt(qa) .. ") : un bénéfice reste possible, mais si tout est vendu il tombe de " .. mt(qa * m1 - cf) .. " à " .. mt(bnf) .. " ; il faut vendre " .. fmt(ns - sup(s)) .. " unités de plus pour atteindre le seuil.")
    else
      G("Commentaire : le nouveau seuil (" .. fmt(ns) .. ") dépasse la quantité achetée (" .. fmt(qa) .. ") : la perte est inévitable (" .. mt(bnf) .. " si tout est vendu).")
    end
    G("Défaut = 44.12 (prof : 5.00 ; 340 ; 3'000 − 1'700 = 1'300 ; 3.00 ; 300 ; 1'400 ÷ 3 → 467 ; 60 + 467 = 527).")
    montrer("Lot")
  end
  SOLVEURS.lot = lancer(CH_LOT, lot)

  ------------------------------------------------------------------ B9 taux de remplissage, recettes annexes
  local CH_R = {
    {cle = "cap", lib = "capacité (places)", defaut = "120"},
    {cle = "cf", lib = "coûts fixes par vol", defaut = "30000"},
    {cle = "cv", lib = "frais variables par passager", defaut = "40"},
    {cle = "pv", lib = "prix payé par passager", defaut = "300"},
    {cle = "ra", lib = "recettes annexes (fret) par vol", defaut = "5000"},
  }
  local function remplissage(v)
    vider()
    T("Taux de remplissage")
    G("Méthode (modèle : 44.15) : les recettes annexes se déduisent des coûts fixes ; passagers au PM = CF nets ÷ MB unitaire ; taux d'occupation = PM × 100 ÷ capacité.")
    local cap, cf, cv, pv, ra = v.cap or 0, v.cf or 0, v.cv or 0, v.pv or 0, v.ra or 0
    local cfn = cf - ra
    calc("Coûts fixes nets", "CF − recettes annexes", mt(cf) .. " − " .. mt(ra), m2(cfn))
    local mbu = pv - cv
    calc("Marge brute unitaire", "prix − frais variables", mt(pv) .. " − " .. mt(cv), m2(mbu))
    if mbu <= EPS then A("Marge nulle ou négative."); montrer("Remplissage"); return end
    local q = cfn / mbu
    calc("Passagers au PM", "CF nets ÷ MB unitaire", mt(cfn) .. " ÷ " .. m2(mbu), dec(q))
    if math.abs(q - sup(q)) > 1e-6 then
      R("Avec " .. math.floor(q) .. " passagers : encore en perte ; avec " .. fmt(sup(q)) .. " : déjà en bénéfice.", "", "")
    end
    if nz(cap) then
      calc("Taux d'occupation au PM", "PM × 100 ÷ capacité", dec(q) .. " × 100 ÷ " .. mt(cap), tx(math.floor(q * 100 + 0.5) / 100 / cap))
      if q > cap then A("Le point mort dépasse la capacité : vol toujours déficitaire.") end
    end
    G("Coûts fixes possibles (44.15 a) : carburant, salaires de l'équipage, amortissement de l'avion, intérêts, frais d'atterrissage.")
    graphique(pv, cv, cfn, nz(cap) and cap or qmaxRond(q * 1.2), {{q = q}}, "Recettes voyageurs")
    G("Défaut = 44.15 (prof : 25'000 ; 260 ; 96.15 ; 80.125 %). Le taux du prof part de 96.15 (arrondi à 2 décimales).")
    montrer("Remplissage")
  end
  SOLVEURS.remplissage = lancer(CH_R, remplissage)

  ------------------------------------------------------------------ B10 théorie : marge contributive
  local function theorie()
    vider()
    T("Marge contributive (théorie)")
    X("Charges variables (proportionnelles) : varient avec les quantités vendues (marchandises, emballage, commissions).")
    X("Charges fixes : indépendantes du volume à court terme (loyer, salaires fixes, amortissements, intérêts).")
    X("Marge sur coût variable (marge brute) = CAN − charges variables ; elle couvre les charges fixes puis forme le bénéfice.")
    X("Marge contributive = CAN − charges directes d'un produit ; elle contribue à couvrir les charges communes (indirectes).")
    G("Le manuel emploie aussi « marge contributive » pour la marge brute (44 p.4).")
    T("Formules du 1er degré (44 p.3)")
    X("CAN = ventes − déductions accordées (− pertes sur créances − frais de vente)")
    X("PRAMA = achats + frais d'achats − déductions obtenues")
    X("PRAMV = PRAMA ± variation de stock (+ diminution, − augmentation)")
    X("MB = CAN − PRAMV = FF + BN")
    T("Seuil (44 p.8-10)")
    X("Taux de MB = MB × 100 ÷ CAN")
    X("CA au PM = CF × 100 ÷ taux de MB = CA × CF ÷ MB")
    X("Quantité au PM = CF ÷ MB unitaire ; quantité visée = (CF + BN) ÷ MB unitaire")
    X("CA visé = (CF + BN) × 100 ÷ taux de MB")
    X("Date du PM = CA au PM × 360 ÷ CA annuel (ventes régulières)")
    G("Quantités arrondies à l'unité supérieure ; CA en CHF arrondis aux 5 centimes dans le recueil.")
    montrer("Marge contributive")
  end
  SOLVEURS.theorie = theorie

  ------------------------------------------------------------------ X1 marge de sécurité, levier opérationnel (hors cours)
  local CH_S = {
    {cle = "ca", lib = "CAN", defaut = "800000"},
    {cle = "cv", lib = "charges variables (PRAMV)", defaut = "320000"},
    {cle = "cf", lib = "charges fixes", defaut = "120000"},
  }
  local function securite(v)
    vider()
    T("Marge de sécurité, levier (hors cours)")
    A("Hors cours : notion absente du chap. 44 (aucune source du prof).")
    G("Méthode : la marge de sécurité mesure de combien le CA peut baisser avant la perte ; le levier opérationnel dit de combien de % varie le résultat quand le CA varie de 1 %.")
    local ca, cv, cf = v.ca or 0, v.cv or 0, v.cf or 0
    if not nz(ca) then A("CA nul."); montrer("Marge de sécurité"); return end
    local mb = ca - cv
    local t = mb / ca
    calc("Marge brute", "CAN − charges variables", mt(ca) .. " − " .. mt(cv), m2(mb))
    calc("Taux de marge brute", "MB × 100 ÷ CAN", mt(mb) .. " × 100 ÷ " .. mt(ca), tx(t))
    if t <= EPS then A("Taux nul ou négatif."); montrer("Marge de sécurité"); return end
    local pm = r5(cf / t)
    calc("CA au point mort", "CF × 100 ÷ taux", mt(cf) .. " × 100 ÷ " .. dec(t * 100, 3), m2(pm))
    local ms = ca - pm
    calc("Marge de sécurité", "CAN − CA au PM", mt(ca) .. " − " .. m2(pm), m2(ms))
    calc("Indice de sécurité", "marge de sécurité × 100 ÷ CAN", m2(ms) .. " × 100 ÷ " .. mt(ca), tx(ms / ca, 2))
    local bn = mb - cf
    calc("Résultat", "MB − CF", mt(mb) .. " − " .. mt(cf), m2(bn))
    if nz(bn) then
      local lo = mb / bn
      calc("Levier opérationnel", "MB ÷ résultat", mt(mb) .. " ÷ " .. mt(bn), dec(lo))
      G("Commentaire : si le CA varie de 10 %, le résultat varie d'environ " .. dec(lo * 10, 1) .. " %. Plus on est proche du point mort, plus le levier est fort et le risque élevé.")
    end
    G("Défaut = données de 44.9 (CA 800'000, PRAMV 320'000, CF 120'000).")
    montrer("Marge de sécurité")
  end
  SOLVEURS.securite = lancer(CH_S, securite)

  ------------------------------------------------------------------ X seuil multiproduits (hors cours)
  local CH_M = {
    {cle = "p1", lib = "PV produit 1", defaut = "20"}, {cle = "c1", lib = "CV produit 1", defaut = "12"}, {cle = "m1", lib = "part du mix 1", defaut = "3"},
    {cle = "p2", lib = "PV produit 2", defaut = "50"}, {cle = "c2", lib = "CV produit 2", defaut = "30"}, {cle = "m2", lib = "part du mix 2", defaut = "1"},
    {cle = "p3", lib = "PV produit 3 (0 = aucun)", defaut = "0"}, {cle = "c3", lib = "CV produit 3", defaut = "0"}, {cle = "m3", lib = "part du mix 3", defaut = "0"},
    {cle = "cf", lib = "charges fixes communes", defaut = "44000"},
  }
  local function multi(v)
    vider()
    T("Seuil multiproduits (hors cours)")
    A("Hors cours : le chap. 44 ne traite qu'un produit. Hypothèse : composition des ventes (mix en quantités) constante.")
    G("Méthode : MB unitaire moyenne pondérée par le mix → quantité totale au PM = CF ÷ MB moyenne → répartition selon le mix.")
    local P, sm, smb = {}, 0, 0
    for i = 1, 3 do
      local p, c, m = v["p" .. i] or 0, v["c" .. i] or 0, v["m" .. i] or 0
      if nz(p) and nz(m) then table.insert(P, {i = i, p = p, c = c, m = m, mb = p - c}); sm = sm + m; smb = smb + m * (p - c) end
    end
    if #P == 0 or sm <= EPS then A("Aucun produit."); montrer("Multiproduits"); return end
    local L = {}
    for _, x in ipairs(P) do table.insert(L, {"Produit " .. x.i .. " (mix " .. dec(x.m) .. ")", m2(x.mb), m2(x.m * x.mb)}) end
    table.insert(L, {"Total (" .. dec(sm) .. ")", "", m2(smb), gras = true, trait = true})
    GRILLE("Marges unitaires", L, {entetes = {"", "MB unit.", "× mix"}})
    local mmoy = smb / sm
    calc("MB moyenne", "Σ (mix × MB unit.) ÷ Σ mix", m2(smb) .. " ÷ " .. dec(sm), m2(mmoy))
    if mmoy <= EPS then A("Marge moyenne nulle ou négative."); montrer("Multiproduits"); return end
    local cf = v.cf or 0
    local q = cf / mmoy
    calc("Quantité totale au PM", "CF ÷ MB moyenne", mt(cf) .. " ÷ " .. m2(mmoy), dec(q))
    local L2, ca, mbt = {}, 0, 0
    for _, x in ipairs(P) do
      local qi = sup(q * x.m / sm)
      ca = ca + qi * x.p; mbt = mbt + qi * x.mb
      table.insert(L2, {"Produit " .. x.i, fmt(qi), mt(qi * x.p)})
    end
    table.insert(L2, {"Total", "", mt(ca), gras = true, trait = true})
    GRILLE("Répartition au PM", L2, {entetes = {"", "Quantité", "CAN"}})
    G("Contrôle : MB totale " .. mt(mbt) .. " ≥ CF " .. mt(cf) .. " (quantités arrondies à l'unité supérieure).")
    montrer("Multiproduits")
  end
  SOLVEURS.multi = lancer(CH_M, multi)

  ------------------------------------------------------------------ menu
  table.insert(MENUS_COMPTA, {ordre = 44, titre = "Compte de résultat, seuil (44)", items = {
    {"CR à 2 degrés, PRAMA, PRAMV, CAN", menu("CR à 2 degrés", CH_CR, cr2)},
    {"Seuil en quantité, bénéfice visé", menu("Seuil en quantité", CH_Q, seuilQ)},
    {"Seuil en valeur (taux de marge)", menu("Seuil en valeur", CH_V, seuilV)},
    {"Base du taux, CAN depuis la MB", menu("Base du taux", CH_T, tauxBase)},
    {"Budget : PM, résultat, prévisions", menu("Budget", CH_B, budget)},
    {"CR prévisionnel, date du PM", menu("CR prévisionnel", CH_P, crPrev)},
    {"Graphique du seuil", menu("Graphique du seuil", CH_G, seuilGraphe)},
    {"Licence : quantité, prix min., baisse", menu("Licence", CH_L, licence)},
    {"Test 2025 ex. 10 (prof + livre)", licence2025},
    {"Lot : changement de prix", menu("Lot", CH_LOT, lot)},
    {"Taux de remplissage", menu("Remplissage", CH_R, remplissage)},
    {"Marge contributive (théorie)", theorie},
    {"Marge de sécurité, levier (hors cours)", menu("Marge de sécurité", CH_S, securite)},
    {"Seuil multiproduits (hors cours)", menu("Multiproduits", CH_M, multi)},
  }})
end
