-- 70_finance.lua : calcul financier (hors cours) — intérêts simples et composés, escompte, emprunts (annuités constantes,
-- amortissement constant), VAN / TRI / délai de récupération, amortissements linéaire et dégressif, TVA, coefficients de prix.
-- Aucune source dans le cours (chap. 37, 44, 51, 57, 59) : exemples simples vérifiables à la main. Taux modifiables à la saisie.
do
  local N = COMMUN.num

  local function r0(x, d)
    local m = 10 ^ (d or 0)
    if x >= 0 then return math.floor(x * m + 0.5) / m end
    return -math.floor(-x * m + 0.5) / m
  end
  local function F(x, d) return fmt(r0(x or 0, d or 0), d or 0) end
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
    for x in (tostring(s or "") .. ","):gmatch("(.-),") do if trim(x) ~= "" then table.insert(t, N(trim(x)) or 0) end end
    return t
  end
  -- valeurs par défaut puis saisie ; les clés listées dans « listes » restent des listes de nombres
  local function champs(defaut, txt, listes)
    local brut = {}
    for _, p in ipairs(paires(defaut)) do brut[p[1]] = p[2] end
    for _, p in ipairs(paires(txt)) do brut[p[1]] = p[2] end
    local v = {}
    for k, s in pairs(brut) do
      if listes and listes[k] then v[k] = lst(s) else v[k] = N(s) end
    end
    return v
  end
  local function ligneCalc(nom, formule, app, res)
    X(nom .. " = " .. formule)
    if app then X("   = " .. app) end
    R("   = " .. res, "", "")
  end
  local P = COMMUN.pct
  local HC = "Hors cours : aucun chapitre de calcul financier dans le cours ; exemple simple vérifiable à la main."

  ------------------------------------------------------------------ 1. intérêts, escompte
  local DEF_INT = "c=10000;t=3%;j=90;n=5;m=12;esc=2%;de=10;dp=30"

  SOLVEURS.finInterets = function(txt)
    local v = champs(DEF_INT, txt)
    vider()
    T("Intérêts, escompte (hors cours)")
    A(HC)
    G("Usage suisse : année commerciale de 360 jours pour les intérêts simples.")
    T("Intérêts simples")
    local i = v.c * v.t * v.j / 360
    ligneCalc("Intérêt", "capital × taux × jours ÷ 360", F(v.c, 2) .. " × " .. P(v.t, 3) .. " × " .. fmt(v.j) .. " ÷ 360", F(i, 2))
    R("Capital final = " .. F(v.c + i, 2), "", "")
    T("Intérêts composés")
    local cn = v.c * (1 + v.t) ^ v.n
    ligneCalc("Capital après n ans", "C0 × (1 + t)^n", F(v.c, 2) .. " × (1 + " .. P(v.t, 3) .. ")^" .. fmt(v.n), F(cn, 2))
    X("Intérêts cumulés = " .. F(cn, 2) .. " − " .. F(v.c, 2) .. " = " .. F(cn - v.c, 2))
    local c0 = v.c / (1 + v.t) ^ v.n
    ligneCalc("Valeur actuelle de C", "C ÷ (1 + t)^n", F(v.c, 2) .. " ÷ (1 + " .. P(v.t, 3) .. ")^" .. fmt(v.n), F(c0, 2))
    T("Taux équivalent")
    local te = (1 + v.t) ^ (1 / v.m) - 1
    ligneCalc("Taux par période (m = " .. fmt(v.m) .. ")", "(1 + t)^(1/m) − 1", "(1 + " .. P(v.t, 3) .. ")^(1/" .. fmt(v.m) .. ") − 1", P(te, 4))
    G("Taux proportionnel (à ne pas confondre) : t ÷ m = " .. P(v.t / v.m, 4) .. ".")
    T("Coût d'un escompte non utilisé")
    local ce = v.esc / (1 - v.esc) * 360 / (v.dp - v.de)
    ligneCalc("Taux annuel", "esc ÷ (1 − esc) × 360 ÷ (délai de paiement − délai d'escompte)",
      P(v.esc) .. " ÷ " .. P(1 - v.esc) .. " × 360 ÷ (" .. fmt(v.dp) .. " − " .. fmt(v.de) .. ")", P(ce))
    G("Lecture : renoncer à l'escompte revient à emprunter à " .. P(ce) .. " par an ; s'il dépasse le taux d'un crédit bancaire, il vaut mieux payer dans le délai d'escompte.")
    montrer("Intérêts (hors cours)")
  end

  ------------------------------------------------------------------ 2. emprunt, plan de remboursement
  local DEF_EMP = "k=100000;t=5%;n=5;type=1"

  SOLVEURS.finEmprunt = function(txt)
    local v = champs(DEF_EMP, txt)
    local n = math.floor(v.n + 0.5)
    vider()
    T("Emprunt, plan de remboursement (hors cours)")
    A(HC)
    G("Méthode : chaque année, intérêt = solde dû en début d'année × taux ; annuité = intérêt + amortissement ; solde = solde − amortissement.")
    local a
    if v.type == 2 then
      a = v.k / n
      ligneCalc("Amortissement constant", "capital ÷ n", F(v.k, 2) .. " ÷ " .. fmt(n), F(a, 2))
    else
      a = v.k * v.t / (1 - (1 + v.t) ^ (-n))
      ligneCalc("Annuité constante", "K × t ÷ (1 − (1 + t)^−n)", F(v.k, 2) .. " × " .. P(v.t, 3) .. " ÷ (1 − (1 + " .. P(v.t, 3) .. ")^−" .. fmt(n) .. ")", F(a, 2))
    end
    local l, s, ti, ta, tn = {}, v.k, 0, 0, 0
    for an = 1, n do
      local int = s * v.t
      local am, ann
      if v.type == 2 then am = a; ann = am + int else ann = a; am = ann - int end
      if an == n then am = s; ann = am + int end
      s = s - am
      ti = ti + int; ta = ta + am; tn = tn + ann
      table.insert(l, {fmt(an) .. "  annuité " .. F(ann), F(int), F(am), F(s)})
    end
    table.insert(l, {"Total  " .. F(tn), F(ti), F(ta), "", gras = true, trait = true})
    GRILLE(v.type == 2 and "Amortissement constant" or "Annuités constantes", l, {entetes = {"Année", "Intérêt", "Amort.", "Solde"}})
    X("Coût total du crédit (somme des intérêts) = " .. F(ti, 2))
    G("type=1 : annuités constantes ; type=2 : amortissement constant (annuités décroissantes). Grille arrondie au franc.")
    montrer("Emprunt (hors cours)")
  end

  ------------------------------------------------------------------ 3. VAN, TRI, délai de récupération
  local DEF_INV = "i0=100000;cf=30000,35000,40000,30000,20000;t=8%"

  SOLVEURS.finInvest = function(txt)
    local v = champs(DEF_INV, txt, {cf = true})
    local cf = v.cf or {}
    vider()
    T("VAN, TRI, délai (hors cours)")
    A(HC)
    G("Méthode : flux actualisé = flux ÷ (1 + t)^année ; VAN = −investissement + somme des flux actualisés ; TRI = taux qui " ..
      "annule la VAN (recherche par dichotomie) ; délai = année où le cumul couvre l'investissement (interpolation linéaire). " ..
      "Valeur résiduelle : à ajouter au dernier flux.")
    local function van(t)
      local s = -v.i0
      for k, x in ipairs(cf) do s = s + x / (1 + t) ^ k end
      return s
    end
    local l, cum, cuma = {}, -v.i0, -v.i0
    local dS, dA
    table.insert(l, {"0", F(-v.i0), F(-v.i0), F(-v.i0)})
    for k, x in ipairs(cf) do
      local xa = x / (1 + v.t) ^ k
      local avant, avantA = cum, cuma
      cum = cum + x; cuma = cuma + xa
      if not dS and cum >= 0 then dS = (k - 1) + (-avant) / x end
      if not dA and cuma >= 0 then dA = (k - 1) + (-avantA) / xa end
      table.insert(l, {fmt(k), F(x), F(xa), F(cuma)})
    end
    GRILLE("Flux (taux " .. P(v.t) .. ")", l, {entetes = {"Année", "Flux", "Actualisé", "Cumul act."}})
    local vn = van(v.t)
    ligneCalc("VAN", "−I0 + Σ flux ÷ (1 + t)^k", "−" .. F(v.i0) .. " + " .. F(vn + v.i0), F(vn, 2))
    G(vn >= 0 and "VAN ≥ 0 : le projet rapporte plus que le taux exigé → acceptable." or "VAN < 0 : le projet ne couvre pas le taux exigé → à rejeter.")
    -- TRI par dichotomie
    local a, b = -0.99, 10
    local fa = van(a)
    if fa * van(b) > 0 then
      A("TRI introuvable entre −99 % et 1000 % (flux sans changement de signe).")
    else
      for _ = 1, 200 do
        local m = (a + b) / 2
        local fm = van(m)
        if fa * fm <= 0 then b = m else a = m; fa = fm end
      end
      local tri = (a + b) / 2
      X("TRI : on cherche t tel que VAN(t) = 0 ; par dichotomie (VAN décroît quand t augmente).")
      R("TRI = " .. P(tri, 2) .. " (VAN = " .. F(van(tri), 2) .. ")", "", "")
      G(tri >= v.t and ("TRI ≥ taux exigé (" .. P(v.t) .. ") → projet rentable.") or ("TRI < taux exigé (" .. P(v.t) .. ") → projet non rentable."))
    end
    if dS then X("Délai de récupération simple = " .. string.format("%.2f", dS) .. " ans (cumul des flux non actualisés)")
    else X("Délai de récupération simple : non atteint sur la durée.") end
    if dA then R("Délai actualisé = " .. string.format("%.2f", dA) .. " ans", "", "")
    else A("Délai actualisé : non atteint sur la durée (VAN négative).") end
    G("Saisie : cf = flux annuels séparés par des virgules (décimales avec un point).")
    montrer("Investissement (hors cours)")
  end

  ------------------------------------------------------------------ 4. amortissements linéaire et dégressif
  local DEF_AMO = "v=50000;n=5;vr=0;td=40%"

  SOLVEURS.finAmort = function(txt)
    local v = champs(DEF_AMO, txt)
    local n = math.floor(v.n + 0.5)
    vider()
    T("Plans d'amortissement (hors cours)")
    A(HC .. " Les taux fiscaux admis ne sont pas figés ici.")
    T("Linéaire (sur la valeur d'acquisition)")
    local al = (v.v - v.vr) / n
    ligneCalc("Amortissement annuel", "(valeur d'acquisition − valeur résiduelle) ÷ durée", "(" .. F(v.v) .. " − " .. F(v.vr) .. ") ÷ " .. fmt(n), F(al, 2))
    X("Taux linéaire = 1 ÷ durée = " .. P(1 / n))
    local l, vc = {}, v.v
    for an = 1, n do vc = vc - al; table.insert(l, {fmt(an), F(al), F(vc)}) end
    GRILLE("Linéaire", l, {entetes = {"Année", "Amort.", "VC fin"}})
    T("Dégressif (sur la valeur comptable)")
    X("Amortissement = valeur comptable en début d'année × " .. P(v.td) .. " (souvent le double du taux linéaire)")
    l, vc = {}, v.v
    local tot = 0
    for an = 1, n do
      local a = vc * v.td
      vc = vc - a; tot = tot + a
      table.insert(l, {fmt(an), F(a), F(vc)})
    end
    table.insert(l, {"Total", F(tot), "", gras = true, trait = true})
    GRILLE("Dégressif", l, {entetes = {"Année", "Amort.", "VC fin"}})
    G("Le dégressif n'atteint jamais zéro : la valeur comptable restante (" .. F(vc) .. ") s'amortit en dernière année ou reste au bilan.")
    montrer("Amortissements (hors cours)")
  end

  ------------------------------------------------------------------ 5. TVA
  local DEF_TVA = "t=8.1%;ht=1000;ttc=0;vht=200000;aht=120000;ti=8.1%"

  SOLVEURS.finTVA = function(txt)
    local v = champs(DEF_TVA, txt)
    vider()
    T("TVA (hors cours)")
    A(HC .. " Taux à saisir (défaut 8.1 %, taux normal suisse 2024 : à vérifier).")
    if (v.ttc or 0) ~= 0 then
      local ht = v.ttc / (1 + v.t)
      ligneCalc("Prix HT", "TTC ÷ (1 + taux)", F(v.ttc, 2) .. " ÷ " .. string.format("%.4f", 1 + v.t), F(ht, 2))
      ligneCalc("TVA", "TTC − HT  (= TTC × t ÷ (1 + t))", F(v.ttc, 2) .. " − " .. F(ht, 2), F(v.ttc - ht, 2))
    else
      local tva = v.ht * v.t
      ligneCalc("TVA", "HT × taux", F(v.ht, 2) .. " × " .. P(v.t), F(tva, 2))
      ligneCalc("Prix TTC", "HT + TVA = HT × (1 + taux)", F(v.ht, 2) .. " × " .. string.format("%.4f", 1 + v.t), F(v.ht + tva, 2))
    end
    T("Décompte de TVA")
    local due = v.vht * v.t
    local ip = v.aht * v.ti
    GRILLE("Décompte", {
      {"TVA due s/ventes", F(due, 2)},
      {"./. Impôt préalable", F(-ip, 2)},
      {due >= ip and "TVA à payer" or "Créance (à recevoir)", F(due - ip, 2), gras = true, trait = true}}, {entetes = {"", "CHF"}})
    X("TVA due = ventes HT × taux = " .. F(v.vht) .. " × " .. P(v.t) .. " ; impôt préalable = achats HT × taux = " .. F(v.aht) .. " × " .. P(v.ti))
    R("Solde = " .. F(due - ip, 2), "", "")
    G("Saisir ttc ≠ 0 pour partir d'un prix TTC (sinon ht).")
    montrer("TVA (hors cours)")
  end

  ------------------------------------------------------------------ 6. coefficients de prix, marge et marque
  local DEF_PRIX = "pa=80;pv=100;maj=0;mq=0;tva=8.1%"

  SOLVEURS.finPrix = function(txt)
    local v = champs(DEF_PRIX, txt)
    vider()
    T("Marge, marque, coefficients (hors cours)")
    A(HC)
    G("Majoration = marge en % du prix d'achat (coût) ; marque = marge en % du prix de vente (= « taux de marge brute en % du CAN » " ..
      "du chap. 44, p.3). Coefficient = prix de vente ÷ prix d'achat. Saisir pv, ou maj, ou mq (une seule des trois ≠ 0).")
    local pv = v.pv or 0
    if (v.maj or 0) ~= 0 then
      pv = v.pa * (1 + v.maj)
      ligneCalc("Prix de vente HT", "prix d'achat × (1 + majoration)", F(v.pa, 2) .. " × (1 + " .. P(v.maj) .. ")", F(pv, 2))
    elseif (v.mq or 0) ~= 0 then
      pv = v.pa / (1 - v.mq)
      ligneCalc("Prix de vente HT", "prix d'achat ÷ (1 − marque)", F(v.pa, 2) .. " ÷ (1 − " .. P(v.mq) .. ")", F(pv, 2))
    end
    local m = pv - v.pa
    ligneCalc("Marge", "prix de vente − prix d'achat", F(pv, 2) .. " − " .. F(v.pa, 2), F(m, 2))
    ligneCalc("Taux de majoration", "marge × 100 ÷ prix d'achat", F(m, 2) .. " × 100 ÷ " .. F(v.pa, 2), P(m / v.pa))
    ligneCalc("Taux de marque", "marge × 100 ÷ prix de vente", F(m, 2) .. " × 100 ÷ " .. F(pv, 2), P(m / pv))
    ligneCalc("Coefficient HT", "prix de vente ÷ prix d'achat", F(pv, 2) .. " ÷ " .. F(v.pa, 2), string.format("%.4f", pv / v.pa))
    local k = pv / v.pa * (1 + v.tva)
    ligneCalc("Coefficient TTC", "coefficient HT × (1 + TVA)", string.format("%.4f", pv / v.pa) .. " × " .. string.format("%.4f", 1 + v.tva), string.format("%.4f", r0(k, 4)))
    X("Prix TTC = " .. F(v.pa, 2) .. " × " .. string.format("%.4f", k) .. " = " .. F(v.pa * k, 2))
    G("Passages : marque = majoration ÷ (1 + majoration) ; majoration = marque ÷ (1 − marque).")
    montrer("Prix (hors cours)")
  end

  ------------------------------------------------------------------ menu : une question par donnée (COMMUN.questionnaire)
  -- les solveurs gardent leur format interne « clé=valeur;… » (tests) : le questionnaire le reconstruit.
  local function defs(def) local t = {}; for _, p in ipairs(paires(def)) do t[p[1]] = p[2] end; return t end
  local function qFixe(titre, def, liste, nom)
    local d = defs(def)
    local ch = {}
    for _, c in ipairs(liste) do table.insert(ch, {cle = c[1], lib = c[2], defaut = d[c[1]] or "", aide = c[3], opt = c[4]}) end
    return function() COMMUN.questionnaire(titre, ch, function(_, brut) SOLVEURS[nom](brut) end) end
  end
  local CH_INT = {
    {"c", "Capital", "Capital placé ou emprunté (C0)."},
    {"t", "Taux d'intérêt annuel", "Taux annuel (ex. 3%)."},
    {"j", "Durée en jours (intérêt simple)", "Nombre de jours ; année commerciale de 360 jours."},
    {"n", "Durée en années (intérêts composés)", "Nombre d'années de capitalisation."},
    {"m", "Périodes par an (taux équivalent)", "12 = mensuel, 4 = trimestriel, 2 = semestriel."},
    {"esc", "Taux d'escompte", "Escompte proposé par le fournisseur (ex. 2%)."},
    {"de", "Délai d'escompte (jours)", "Paiement dans ce délai = escompte déduit (ex. 10 jours)."},
    {"dp", "Délai de paiement (jours)", "Délai net de paiement de la facture (ex. 30 jours)."},
  }
  local CH_EMP = {
    {"k", "Capital emprunté", "Montant de l'emprunt."},
    {"t", "Taux d'intérêt annuel", "Taux annuel (ex. 5%)."},
    {"n", "Durée (années)", "Nombre d'annuités."},
    {"type", "Type : 1 annuités cst, 2 amort. cst", "1 = annuités constantes ; 2 = amortissement constant (annuités décroissantes)."},
  }
  local CH_AMO = {
    {"v", "Valeur d'acquisition", "Prix d'achat + frais d'acquisition de l'immobilisation."},
    {"n", "Durée d'utilisation (années)", "Durée de vie prévue."},
    {"vr", "Valeur résiduelle", "Valeur de revente prévue à la fin (0 si aucune)."},
    {"td", "Taux dégressif", "Taux appliqué à la valeur comptable (souvent le double du taux linéaire)."},
  }
  local CH_TVA = {
    {"t", "Taux de TVA", "Taux normal (8.1 % : à vérifier selon l'année)."},
    {"ht", "Prix hors taxe (HT)", "Prix HT dont on cherche la TVA et le TTC."},
    {"ttc", "ou prix TTC (0 = non)", "Prix TTC dont on cherche le HT ; 0 = partir du prix HT.", true},
    {"vht", "Ventes HT de la période", "Chiffre d'affaires HT : TVA due = ventes HT × taux."},
    {"aht", "Achats HT de la période", "Achats HT : impôt préalable = achats HT × taux."},
    {"ti", "Taux de l'impôt préalable", "Taux de TVA payé sur les achats."},
  }
  local CH_PRIX = {
    {"pa", "Prix d'achat (coût)", "Prix d'achat HT d'une unité."},
    {"pv", "Prix de vente HT", "Prix de vente HT ; ou donner la majoration ou la marque (une seule des trois).", true},
    {"maj", "ou majoration (% du coût)", "Marge en % du prix d'achat ; 0 = non.", true},
    {"mq", "ou marque (% du prix de vente)", "Marge en % du prix de vente ; 0 = non.", true},
    {"tva", "Taux de TVA", "Pour le coefficient TTC = coefficient HT × (1 + TVA)."},
  }
  local function qInvest()
    local d = defs(DEF_INV)
    local flux = {}
    for x in (d.cf .. ","):gmatch("(.-),") do flux[#flux + 1] = x end
    COMMUN.questionnaire("VAN, TRI (hors cours)", COMMUN.repeter({
      {cle = "i0", lib = "Investissement initial", defaut = d.i0, aide = "Montant investi en début de projet (année 0)."},
      {cle = "t", lib = "Taux d'actualisation", defaut = d.t, aide = "Taux exigé (coût du capital), ex. 8%."},
      {groupe = "Année", n = {cle = "na", lib = "Combien d'années de flux ?", defaut = tostring(#flux), max = 15,
        aide = "Durée du projet : un flux de trésorerie net par année."},
        champs = function(j) return {{cle = "cf", lib = "flux de trésorerie", defaut = flux[j] or "",
          aide = "Flux net de l'année (encaissements − décaissements) ; valeur résiduelle ajoutée au dernier."}} end},
    }), function(v)
      local t = {}
      for j, e in ipairs(COMMUN.elements(v, COMMUN.entier(v.na, 0), {"cf"})) do t[j] = (e.cf ~= "" and e.cf or "0"):gsub("%s", ""):gsub(",", ".") end
      SOLVEURS.finInvest("i0=" .. (v._txt.i0 or "") .. ";cf=" .. table.concat(t, ",") .. ";t=" .. (v._txt.t or ""))
    end)
  end
  -- forts / mots / si : index de la recherche (99_menu) ; radicaux sans accents (voir CONVENTIONS-MODULES.md)
  table.insert(MENUS_COMPTA, {ordre = 70, titre = "Finance (hors cours)", items = {
    {"Intérêts, escompte", qFixe("Intérêts (hors cours)", DEF_INT, CH_INT, "finInterets"),
      forts = "interet escompte", mots = "capital taux jours", si = "hors cours"},
    {"Emprunt, plan de remboursement", qFixe("Emprunt (hors cours)", DEF_EMP, CH_EMP, "finEmprunt"),
      forts = "emprunt annuite remboursement", mots = "plan", si = "hors cours"},
    {"VAN, TRI, délai de récupération", qInvest,
      forts = "van tri actualisation recuperation", mots = "investissement", si = "hors cours"},
    {"Amortissements linéaire, dégressif", qFixe("Amortissements (hors cours)", DEF_AMO, CH_AMO, "finAmort"),
      forts = "lineaire degressif", mots = "amortissement valeur residuelle", si = "hors cours"},
    {"TVA : HT/TTC, décompte", qFixe("TVA (hors cours)", DEF_TVA, CH_TVA, "finTVA"),
      forts = "tva ht ttc", mots = "decompte impot prealable", si = "hors cours"},
    {"Marge, marque, coefficients", qFixe("Prix (hors cours)", DEF_PRIX, CH_PRIX, "finPrix"),
      forts = "marque coefficient majoration", mots = "marge prix achat vente", si = "hors cours"},
  }})
end
