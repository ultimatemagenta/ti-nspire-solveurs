-- 57_tresorerie.lua : flux de trésorerie (chap. 57) — tableau des liquidités, cash flow direct / indirect,
-- tableau des flux de trésorerie complet, effets des opérations, ratios de cash flow ;
-- hors cours : BFR et cycle de trésorerie, budget de trésorerie.
do
  local N = COMMUN.num

  local function r0(x, d)
    local m = 10 ^ (d or 0)
    if x >= 0 then return math.floor(x * m + 0.5) / m end
    return -math.floor(-x * m + 0.5) / m
  end
  local function F(x, d) return fmt(r0(x or 0, d or 0), d or 0) end
  -- montant signé à la manière du prof : +25 / −30
  local function S(x) if (x or 0) > 0 then return "+" .. F(x) end; return F(x) end
  local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
  local function paires(txt)
    local out = {}
    for m in tostring(txt or ""):gmatch("[^;]+") do
      local k, v = m:match("^(.-)=(.*)$")
      if k then table.insert(out, {trim(k), trim(v)}) end
    end
    return out
  end
  local function lst(s)
    local t = {}
    for x in (tostring(s or "") .. ","):gmatch("(.-),") do table.insert(t, trim(x)) end
    return t
  end
  local function source(txt, defaut) if txt and trim(txt) ~= "" then return txt end; return defaut end
  local function champs(defaut, txt)
    local v = {}
    for _, p in ipairs(paires(defaut)) do v[p[1]] = N(p[2]) end
    for _, p in ipairs(paires(txt)) do v[p[1]] = N(p[2]) end
    return v
  end
  -- « N-1/N » -> a, b
  local function deux(s)
    if s == nil then return 0, 0 end
    local a, b = tostring(s):match("^(.-)/(.*)$")
    if not a then local x = N(s) or 0; return x, x end
    return N(a) or 0, N(b) or 0
  end
  local function ligneCalc(nom, formule, app, res)
    X(nom .. " = " .. formule)
    if app then X("   = " .. app) end
    R("   = " .. res, "", "")
  end

  ------------------------------------------------------------------ lecture d'un dossier de trésorerie
  -- fonds : « L Caisse=55/80 » (« L -Banque cc=… » : compte du passif déduit) ; autres clés : montants ou paires N-1/N
  local function lireDossier(src)
    local d = {fonds = {}, v = {}, p = {}}
    for _, pr in ipairs(paires(src)) do
      local k, val = pr[1], pr[2]
      local nom = k:match("^L%s+(.+)$")
      if nom then
        local neg = nom:sub(1, 1) == "-"
        if neg then nom = trim(nom:sub(2)) end
        local a, b = deux(val)
        table.insert(d.fonds, {nom = nom, a = a, b = b, neg = neg})
      else
        d.v[k] = N(val)
        local a, b = deux(val)
        d.p[k] = {a, b}
      end
    end
    return d
  end
  local function val(d, k) return d.v[k] or 0 end
  local function delta(d, k) local p = d.p[k]; if not p then return 0 end; return p[2] - p[1] end

  local function tableauLiquidites(d)
    local l, ta, tb = {}, 0, 0
    for _, f in ipairs(d.fonds) do
      local s = f.neg and -1 or 1
      ta = ta + s * f.a; tb = tb + s * f.b
      table.insert(l, {(f.neg and "./. " or "") .. f.nom, F(s * f.a), F(s * f.b), S(s * (f.b - f.a))})
    end
    table.insert(l, {"Liquidités (total)", F(ta), F(tb), S(tb - ta), gras = true, trait = true})
    GRILLE("Tableau des liquidités", l, {entetes = {"Fonds", "N-1", "N", "Variation"}})
    return ta, tb
  end

  -- bénéfice net recalculé depuis le compte de résultat saisi
  local function beneficeNet(d)
    return val(d, "ven") + val(d, "pf") + val(d, "pvc") - val(d, "ach") - val(d, "sal") - val(d, "loy") - val(d, "ace") -
      val(d, "aut") - val(d, "cf") - val(d, "amo") - val(d, "nm") - val(d, "pc")
  end

  -- secteur exploitation, méthode directe : lignes {libellé, montant}
  local function exploitationDirecte(d)
    local l = {}
    local function aj(lib, x) if x and x ~= 0 then table.insert(l, {lib, x}) end end
    aj("Encaissements clients", val(d, "ven"))
    local dc = delta(d, "cre"); aj(dc > 0 and "./. Augm. créances" or "+ Dim. créances", -dc)
    local dr = delta(d, "ara"); aj(dr > 0 and "./. Augm. prod. à recevoir" or "+ Dim. prod. à recevoir", -dr)
    aj("./. Pertes s/créances", -val(d, "pc"))
    aj("+ Produits financiers", val(d, "pf"))
    aj("./. Fournisseurs (achats)", -val(d, "ach"))
    local ds = delta(d, "sto"); aj(ds > 0 and "./. Augm. stock" or "+ Dim. stock", -ds)
    local df = delta(d, "dfo"); aj(df > 0 and "+ Augm. dettes fourn." or "./. Dim. dettes fourn.", df)
    aj("./. Salaires", -val(d, "sal"))
    aj("./. Loyers", -val(d, "loy"))
    aj("./. ACE", -val(d, "ace"))
    aj("./. Autres charges", -val(d, "aut"))
    aj("./. Charges financières", -val(d, "cf"))
    local dp = delta(d, "pre"); aj(dp > 0 and "+ Augm. charges à payer" or "./. Dim. charges à payer", dp)
    local t = 0
    for _, x in ipairs(l) do t = t + x[2] end
    return l, t
  end

  local function exploitationIndirecte(d, bn)
    local l = {{"Bénéfice net", bn}}
    local function aj(lib, x) if x and x ~= 0 then table.insert(l, {lib, x}) end end
    aj("+ Amortissements", val(d, "amo"))
    aj("+ Provisions (sans effet)", val(d, "nm"))
    aj("./. Bén. s/cession d'AI", -val(d, "pvc"))
    local dc = delta(d, "cre"); aj(dc > 0 and "./. Augm. créances" or "+ Dim. créances", -dc)
    local dr = delta(d, "ara"); aj(dr > 0 and "./. Augm. prod. à recevoir" or "+ Dim. prod. à recevoir", -dr)
    local ds = delta(d, "sto"); aj(ds > 0 and "./. Augm. stock" or "+ Dim. stock", -ds)
    local df = delta(d, "dfo"); aj(df > 0 and "+ Augm. dettes fourn." or "./. Dim. dettes fourn.", df)
    local dp = delta(d, "pre"); aj(dp > 0 and "+ Augm. charges à payer" or "./. Dim. charges à payer", dp)
    local t = 0
    for _, x in ipairs(l) do t = t + x[2] end
    return l, t
  end

  local function grilleSecteur(titre, lignes, total, libTotal, out)
    table.insert(out, {titre, "", "", fond = true, gras = true})
    for _, x in ipairs(lignes) do table.insert(out, {x[1], F(x[2]), "", retrait = 1}) end
    table.insert(out, {libTotal, "", F(total), gras = true, trait = true})
  end

  local function controleBN(d, bn)
    if d.v.bn and math.abs(d.v.bn - bn) > 0.5 then
      A("Bénéfice recalculé " .. F(bn) .. " ≠ bénéfice saisi " .. F(d.v.bn) .. " : un poste du compte de résultat manque.")
    end
  end

  ------------------------------------------------------------------ 1. tableau des liquidités (D1)
  local DEF_LIQ = "Caisse=55/80;Poste=130/100"

  SOLVEURS.tresoLiq = function(txt)
    local src = source(txt, DEF_LIQ)
    local d = {fonds = {}}
    for _, pr in ipairs(paires(src)) do
      local nom = pr[1]:match("^L%s+(.+)$") or pr[1]
      local neg = nom:sub(1, 1) == "-"
      if neg then nom = trim(nom:sub(2)) end
      local a, b = deux(pr[2])
      table.insert(d.fonds, {nom = nom, a = a, b = b, neg = neg})
    end
    vider()
    T("Tableau des liquidités")
    G("Méthode : on liste les comptes du fonds (définition de l'énoncé) en N-1 et N ; variation = N − (N-1) ; un compte " ..
      "du passif inclus dans le fonds (banque c/c) se déduit. Les titres n'y entrent que s'ils sont des réserves de " ..
      "liquidités (57 p.4-8 ; modèle : test 2026-02 ex. 2 a, 3 pts ; 57.2, 57.3).")
    local ta, tb = tableauLiquidites(d)
    ligneCalc("Variation du fonds", "liquidités N − liquidités N-1", F(tb) .. " − " .. F(ta), S(tb - ta))
    G("Saisie : Nom=N-1/N ; préfixe « - » pour un compte du passif déduit (ex. -Banque cc=1600/1200).")
    montrer("Liquidités")
  end

  ------------------------------------------------------------------ 2. cash flow direct / indirect (D2)
  local DEF_CF = "ven=96100;sal=54000;ace=2600;aut=20200;amo=9000;pc=200;cre=0/3700;pre=0/8600;bn=10100"

  SOLVEURS.tresoCF = function(txt)
    local d = lireDossier(source(txt, DEF_CF))
    local bn = beneficeNet(d)
    vider()
    T("Cash flow : méthodes directe et indirecte")
    G("Méthode directe : encaissements − décaissements liés à l'exploitation (produits et charges corrigés des variations " ..
      "de créances, stocks, dettes). Méthode indirecte : bénéfice net + charges sans effet monétaire (amortissements, " ..
      "provisions) − produits sans effet monétaire ± variations du fonds de roulement. Les deux donnent le même cash flow " ..
      "(57 p.9-13 ; modèle : 57.4, 57.7, 57.12).")
    controleBN(d, bn)
    local ld, td = exploitationDirecte(d)
    local li, ti = exploitationIndirecte(d, bn)
    local g = {}
    grilleSecteur("Méthode directe", ld, td, "Cash flow", g)
    GRILLE("Exploitation (directe)", g, {entetes = {"", "Détail", "Total"}})
    g = {}
    grilleSecteur("Méthode indirecte", li, ti, "Cash flow", g)
    GRILLE("Exploitation (indirecte)", g, {entetes = {"", "Détail", "Total"}})
    if math.abs(td - ti) > 0.5 then A("Les deux méthodes divergent (" .. F(td) .. " / " .. F(ti) .. ") : vérifier les données.")
    else R("Cash flow = " .. F(td), "", "") end
    G("Clés : ven, ach (PRAMV), sal, loy, ace, aut, cf, pf, amo, nm (provisions), pvc (bén. s/cession), pc (pertes s/créances), bn (contrôle) ; " ..
      "paires N-1/N : cre, sto, ara (produits à recevoir), dfo (dettes fourn.), pre (charges à payer). Défaut : 57.7 (cash flow 24'000).")
    montrer("Cash flow")
  end

  ------------------------------------------------------------------ 3. tableau des flux de trésorerie complet (D3)
  local DEF_TFT = "L Caisse=55/80;L Poste=130/100;ven=1500;ach=700;sal=300;loy=150;ace=50;cf=10;amo=90;" ..
    "imo=800/850;dlt=400/260;cap=505/570;div=80;bn=200"

  SOLVEURS.tresoTFT = function(txt)
    local d = lireDossier(source(txt, DEF_TFT))
    local bn = beneficeNet(d)
    vider()
    T("Tableau des flux de trésorerie")
    G("Méthode : a) tableau des liquidités ; b) cash flow (indirecte) ; c) TFT en 3 secteurs : exploitation (directe) → cash flow ; " ..
      "investissement = variation des immobilisations nettes + amortissements + valeur comptable cédée ; financement = " ..
      "variation des dettes financières et du capital − dividende de N-1 payé. Contrôle : somme des flux = variation du fonds " ..
      "(57 p.9-22 ; modèle : test 2026-02 ex. 2, 16 pts ; 57.12, 57.17).")
    controleBN(d, bn)
    T("a) Tableau des liquidités")
    local ta, tb = tableauLiquidites(d)
    T("b) Cash flow (méthode indirecte)")
    local li, ti = exploitationIndirecte(d, bn)
    local g = {}
    for _, x in ipairs(li) do table.insert(g, {x[1], F(x[2])}) end
    table.insert(g, {"Cash flow", F(ti), gras = true, trait = true})
    GRILLE("Cash flow (indirecte)", g, {entetes = {"", "Montant"}})
    T("c) TFT (méthode directe)")
    local ld, td = exploitationDirecte(d)
    -- investissement
    local pi = d.p.imo or {0, 0}
    local i1, i2 = pi[1], pi[2]
    local ces, pvc = val(d, "ces"), val(d, "pvc")
    local vnc = ces - pvc
    local invest = (i2 - i1) + val(d, "amo") + vnc
    ligneCalc("Investissements", "AI nets N − AI nets N-1 + amortissements + valeur comptable cédée",
      F(i2) .. " − " .. F(i1) .. " + " .. F(val(d, "amo")) .. " + " .. F(vnc), F(invest))
    local linv = {}
    if invest ~= 0 then table.insert(linv, {"./. Investissements AI", -invest}) end
    if ces ~= 0 then table.insert(linv, {"+ Désinvestissements AI", ces}) end
    local dfi = delta(d, "ifi")
    if dfi ~= 0 then table.insert(linv, {dfi > 0 and "./. Invest. financiers" or "+ Désinvest. financiers", -dfi}) end
    local tinv = 0
    for _, x in ipairs(linv) do tinv = tinv + x[2] end
    -- financement
    local lfin = {}
    local dd = delta(d, "dlt")
    if dd ~= 0 then table.insert(lfin, {dd > 0 and "+ Augm. dettes fin." or "./. Remboursement dettes", dd}) end
    local dk = delta(d, "cap")
    if dk ~= 0 then table.insert(lfin, {dk > 0 and "+ Augmentation capital" or "./. Réduction capital", dk}) end
    if val(d, "div") ~= 0 then table.insert(lfin, {"./. Dividende N-1 payé", -val(d, "div")}) end
    local tfin = 0
    for _, x in ipairs(lfin) do tfin = tfin + x[2] end
    g = {}
    grilleSecteur("Exploitation (directe)", ld, td, "Cash flow", g)
    grilleSecteur("Investissement", linv, tinv, "Flux investissement", g)
    grilleSecteur("Financement", lfin, tfin, "Flux financement", g)
    local tot = td + tinv + tfin
    table.insert(g, {"Variation du fonds", "", S(tot), gras = true, trait = true})
    table.insert(g, {"Liquidités au 1.1", F(ta), ""})
    table.insert(g, {"Liquidités au 31.12", F(tb), ""})
    table.insert(g, {"Variation des liquidités", "", S(tb - ta), gras = true, trait = true})
    GRILLE("Tableau des flux de trésorerie", g, {entetes = {"", "Détail", "Total"}})
    X("Contrôle : " .. F(td) .. " + (" .. F(tinv) .. ") + (" .. F(tfin) .. ") = " .. S(tot) .. " ; variation du fonds = " .. S(tb - ta))
    if math.abs(tot - (tb - ta)) > 0.5 then
      A("Écart de " .. F(tot - (tb - ta)) .. " entre le TFT et le tableau des liquidités : il manque une donnée (cession, dividende, variation de créances…).")
    else R("TFT équilibré : " .. S(tot), "", "") end
    if math.abs(td - ti) > 0.5 then A("Cash flow direct " .. F(td) .. " ≠ indirect " .. F(ti) .. ".") end
    G("Pièges : dividende payé = celui de N-1 (au bilan N-1) ; investissement = variation nette + amortissements ; " ..
      "vente d'AI : désinvestissement au prix de vente, bénéfice de cession retiré du cash flow (57.6, 57.17).")
    G("Clés : L Nom=N-1/N (fonds, « L -Nom » au passif) ; CR : ven ach sal loy ace aut cf pf amo nm pvc pc bn ; BFR N-1/N : cre sto ara dfo pre ; " ..
      "imo=AI nets N-1/N ; ces = prix de cession ; ifi = immob. financières N-1/N ; dlt = dettes financières N-1/N ; cap = capital N-1/N ; div.")
    montrer("TFT")
  end

  ------------------------------------------------------------------ 4. effets des opérations (D4)
  SOLVEURS.tresoEffets = function()
    vider()
    T("Effets sur le résultat et les liquidités")
    G("Règle : une opération touche le résultat si elle passe par une charge ou un produit ; les liquidités si elle passe par " ..
      "caisse, poste ou banque (57.1, 57.9, 57.10 ; + augmente, − diminue, 0 sans effet).")
    GRILLE("Opération", {
      {"Vente au comptant", "+", "+"},
      {"Vente à crédit", "+", "0"},
      {"Encaissement client", "0", "+"},
      {"Achat march. comptant", "−", "−"},
      {"Achat march. à crédit", "−", "0"},
      {"Paiement fournisseur", "0", "−"},
      {"Salaires, loyer payés", "−", "−"},
      {"Intérêts payés", "−", "−"},
      {"Amortissement (AI)", "−", "0"},
      {"Diminution du stock", "−", "0"},
      {"Provision litige", "−", "0"},
      {"Ducroire, risque fictif", "−", "0"},
      {"Ducroire, risque avéré", "−", "−"},
      {"Remboursement dette", "0", "−"},
      {"Nouvel emprunt", "0", "+"},
      {"Achat AI au comptant", "0", "−"},
      {"Virement poste → banque", "0", "0"},
      {"Augm. capital libérée", "0", "+"},
      {"Dividende payé", "0", "−"}}, {entetes = {"", "Résultat", "Liquid."}})
    G("Ducroire pour risque avéré : « − / − » dans les corrigés du prof (57.9, 57.10).")
    T("Effets sur les ratios de cash flow (57.27)")
    GRILLE("Opération", {
      {"Liquidités / Ventes", "+", "+", "−"},
      {"Machines / Autres dettes", "0", "−", "+"},
      {"Loyers / Liquidités", "−", "−", "+"},
      {"Achats / Liquidités", "−", "−", "+"},
      {"Amort. / Véhicules", "0", "0", "0"}}, {entetes = {"", "Marge CF", "Ratio inv.", "Fact. end."}})
    montrer("Effets")
  end

  ------------------------------------------------------------------ 5. ratios de cash flow, free cash flow (D5)
  local DEF_RAT = "cf=65;can=1800;bn=0;inv=0;ai1=210;ai2=196;amo=35;pcess=0;bcess=0;ce=98;liq=54;cre=83"

  SOLVEURS.tresoRatios = function(txt)
    local v = champs(DEF_RAT, txt)
    vider()
    T("Ratios de cash flow")
    G("Formules du manuel (57 p.62) ; modèle : 57.22, 57.25, 57.26. Défaut : 57.25 (Mecanica).")
    local inv = v.inv
    if (inv or 0) == 0 then
      inv = (v.ai2 - v.ai1) + v.amo + (v.pcess or 0) - (v.bcess or 0)
      ligneCalc("Investissements nets", "(AI N − AI N-1) + amortissements + pertes s/cession − bénéfices s/cession",
        "(" .. F(v.ai2) .. " − " .. F(v.ai1) .. ") + " .. F(v.amo) .. " + " .. F(v.pcess or 0) .. " − " .. F(v.bcess or 0), F(inv))
    end
    ligneCalc("Marge de cash flow", "cash flow × 100 ÷ CA net", F(v.cf) .. " × 100 ÷ " .. F(v.can), COMMUN.pct(v.cf / v.can))
    G("À comparer dans le temps (évolution d'une année à l'autre).")
    if (v.bn or 0) ~= 0 then
      ligneCalc("Indice opérationnel", "cash flow ÷ bénéfice", F(v.cf) .. " ÷ " .. F(v.bn), COMMUN.dec2(v.cf / v.bn))
    end
    if inv ~= 0 then
      local ri = v.cf / inv
      ligneCalc("Ratio d'investissement", "cash flow × 100 ÷ investissements nets", F(v.cf) .. " × 100 ÷ " .. F(inv), COMMUN.pct(ri))
      if ri >= 1 then
        G("Commentaire : l'entreprise finance l'intégralité de ses investissements avec son cash flow (" .. COMMUN.pct(ri) .. " ≥ 100 %).")
      else
        G("Commentaire : l'entreprise ne finance que " .. COMMUN.pct(ri) .. " de ses investissements avec son cash flow ; le reste " ..
          "vient de fonds externes ou des liquidités. Prendre en compte la tendance à long terme.")
      end
    end
    local ee = v.ce - v.liq - v.cre
    ligneCalc("Endettement effectif", "capitaux étrangers − liquidités (sens large) − créances", F(v.ce) .. " − " .. F(v.liq) .. " − " .. F(v.cre), F(ee))
    if ee <= 0 then
      G("Commentaire : l'endettement effectif est négatif (ou nul) : il n'y a pas lieu de calculer le facteur d'endettement (57.25).")
    elseif v.cf <= 0 then
      A("Cash flow négatif : facteur d'endettement non calculable, l'entreprise ne peut pas rembourser ses dettes par l'exploitation.")
    else
      local fe = ee / v.cf
      ligneCalc("Facteur d'endettement", "endettement effectif ÷ cash flow", F(ee) .. " ÷ " .. F(v.cf), string.format("%.1f", fe))
      local app = fe <= 3 and "très bon (1 à 3)" or (fe <= 5 and "acceptable (entre 3 et 5)" or "insuffisant (> 5)")
      G("Commentaire : facteur de " .. string.format("%.1f", fe) .. " → " .. app .. ". Il faudrait " .. string.format("%.1f", fe) ..
        " exercices à l'entreprise pour rembourser son endettement effectif avec le cash flow qu'elle dégage. Plus il est faible, " ..
        "plus la sécurité des prêteurs est grande.")
    end
    local fcf = v.cf - inv
    ligneCalc("Free cash flow", "cash flow − investissements nets", F(v.cf) .. " − " .. F(inv), F(fcf))
    if fcf >= 0 then
      G("Commentaire : avec un free cash flow de " .. F(fcf) .. ", l'entreprise dispose de fonds pour rembourser des dettes, " ..
        "distribuer un dividende exceptionnel ou accumuler des fonds pour un investissement futur.")
    else
      G("Commentaire : avec un free cash flow de " .. F(fcf) .. ", l'entreprise ne dispose d'aucune marge de manœuvre pour " ..
        "rembourser des dettes ou verser un dividende exceptionnel.")
    end
    montrer("Ratios de cash flow")
  end

  ------------------------------------------------------------------ 6. BFR et cycle de trésorerie (hors cours)
  local DEF_BFR = "sto=40000;pramv=360000;cre=60000;ca=600000;dfo=30000;ach=360000;j=360"

  SOLVEURS.tresoBFR = function(txt)
    local v = champs(DEF_BFR, txt)
    vider()
    T("BFR, cycle de trésorerie (hors cours)")
    A("Hors cours : proche du « cycle des liquidités » du chap. 51 (section 3.4, retirée du programme).")
    G("Méthode : durées en jours (année de " .. fmt(v.j) .. " jours, comme la liste des ratios Profil M) ; cycle = stockage + crédit clients − crédit fournisseurs ; " ..
      "BFR d'exploitation = stocks + créances − dettes fournisseurs. Exemple simple vérifiable à la main.")
    local ds = v.sto * v.j / v.pramv
    local dc = v.cre * v.j / v.ca
    local df = v.dfo * v.j / v.ach
    ligneCalc("Durée de stockage", "stock moyen × " .. fmt(v.j) .. " ÷ PRAMV", F(v.sto) .. " × " .. fmt(v.j) .. " ÷ " .. F(v.pramv), F(ds, 1) .. " jours")
    ligneCalc("Crédit clients", "créances × " .. fmt(v.j) .. " ÷ CA", F(v.cre) .. " × " .. fmt(v.j) .. " ÷ " .. F(v.ca), F(dc, 1) .. " jours")
    ligneCalc("Crédit fournisseurs", "dettes fourn. × " .. fmt(v.j) .. " ÷ achats", F(v.dfo) .. " × " .. fmt(v.j) .. " ÷ " .. F(v.ach), F(df, 1) .. " jours")
    local cyc = ds + dc - df
    ligneCalc("Cycle de trésorerie", "stockage + clients − fournisseurs", F(ds, 1) .. " + " .. F(dc, 1) .. " − " .. F(df, 1), F(cyc, 1) .. " jours")
    local bfr = v.sto + v.cre - v.dfo
    ligneCalc("BFR d'exploitation", "stocks + créances − dettes fournisseurs", F(v.sto) .. " + " .. F(v.cre) .. " − " .. F(v.dfo), F(bfr))
    G("Lecture : pendant " .. F(cyc, 0) .. " jours, l'entreprise doit financer elle-même son exploitation ; un BFR positif se finance par le fonds de roulement net ou par du crédit à court terme.")
    montrer("BFR (hors cours)")
  end

  ------------------------------------------------------------------ 7. budget de trésorerie (hors cours)
  local DEF_BUD = "si=20000;mois=Jan,Fév,Mar,Avr;enc=50000,45000,60000,70000;dec=55000,60000,52000,58000;min=10000"

  SOLVEURS.tresoBudget = function(txt)
    local src = source(txt, DEF_BUD)
    local si, mn, mois, enc, dec = 0, 0, {}, {}, {}
    for _, p in ipairs(paires(src)) do
      if p[1] == "si" then si = N(p[2]) or 0
      elseif p[1] == "min" then mn = N(p[2]) or 0
      elseif p[1] == "mois" then mois = lst(p[2])
      elseif p[1] == "enc" then for _, x in ipairs(lst(p[2])) do table.insert(enc, N(x) or 0) end
      elseif p[1] == "dec" then for _, x in ipairs(lst(p[2])) do table.insert(dec, N(x) or 0) end end
    end
    vider()
    T("Budget de trésorerie (hors cours)")
    A("Hors cours : outil de gestion, absent des chap. 37-59.")
    G("Méthode : solde final du mois = solde initial + encaissements − décaissements ; le solde final devient le solde initial " ..
      "du mois suivant ; un solde sous le minimum (" .. F(mn) .. ") signale un besoin de financement. Exemple simple vérifiable à la main.")
    local l, s, besoin = {}, si, 0
    local n = math.max(#enc, #dec)
    for i = 1, n do
      local e, d = enc[i] or 0, dec[i] or 0
      local fin = s + e - d
      table.insert(l, {(mois[i] or ("Mois " .. i)) .. " (SI " .. F(s) .. ")", F(e), F(-d), F(fin), fond = fin < mn})
      if fin < mn then besoin = math.max(besoin, mn - fin) end
      s = fin
    end
    GRILLE("Budget", l, {entetes = {"", "Encaiss.", "Décaiss.", "Solde fin"}})
    X("Solde final = solde initial + encaissements − décaissements (lignes surlignées : sous le minimum).")
    if besoin > 0 then A("Besoin de financement maximal : " .. F(besoin) .. " (pour rester au minimum de " .. F(mn) .. ").")
    else R("Trésorerie toujours ≥ minimum", "", "") end
    montrer("Budget (hors cours)")
  end

  ------------------------------------------------------------------ menu
  local function saisir(msg, defaut, nom)
    return function() demander(msg, function(t) SOLVEURS[nom](t) end, defaut) end
  end
  table.insert(MENUS_COMPTA, {ordre = 57, titre = "Trésorerie (57)", items = {
    {"Tableau des liquidités", saisir("Compte=N-1/N ; « -Compte » au passif (banque c/c)", DEF_LIQ, "tresoLiq")},
    {"Cash flow direct / indirect", saisir("CR : ven ach sal loy ace aut cf pf amo nm pvc pc ; N-1/N : cre sto ara dfo pre ; bn", DEF_CF, "tresoCF")},
    {"Tableau des flux complet", saisir("L Compte=N-1/N ; CR ; BFR N-1/N ; imo ces ifi dlt cap div", DEF_TFT, "tresoTFT")},
    {"Effets des opérations", function() SOLVEURS.tresoEffets() end},
    {"Ratios de cash flow, free cash flow", saisir("cf ; can ; bn ; inv (ou ai1 ai2 amo pcess bcess) ; ce liq cre", DEF_RAT, "tresoRatios")},
    {"BFR, cycle de trésorerie (hors cours)", saisir("sto pramv cre ca dfo ach ; j = jours", DEF_BFR, "tresoBFR")},
    {"Budget de trésorerie (hors cours)", saisir("si ; mois=… ; enc=… ; dec=… ; min", DEF_BUD, "tresoBudget")},
  }})
end
