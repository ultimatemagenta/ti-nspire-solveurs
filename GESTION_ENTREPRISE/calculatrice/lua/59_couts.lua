-- 59_couts.lua : comptabilité analytique (chap. 59) — stock au CMP, répartition des charges indirectes,
-- coûts complets en cascade, prix de revient d'une commande, charges incorporables, passage CAE → CG,
-- résultat par département, coût de l'unité d'œuvre.
do
  local N = COMMUN.num

  -- arrondi commercial (0.5 vers le haut, comme Excel), puis affichage suisse
  local function r0(x, d)
    local m = 10 ^ (d or 0)
    if x >= 0 then return math.floor(x * m + 0.5) / m end
    return -math.floor(-x * m + 0.5) / m
  end
  local function F(x, d) return fmt(r0(x or 0, d or 0), d or 0) end
  local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
  -- « clé=valeur ; clé=valeur » -> liste ordonnée {clé, valeur} (les clés peuvent contenir des espaces)
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
  -- valeurs par défaut puis texte interne « clé=valeur;… » (reconstruit par les questionnaires du menu)
  local function champs(defaut, txt)
    local v = {}
    for _, p in ipairs(paires(defaut)) do v[p[1]] = N(p[2]) end
    for _, p in ipairs(paires(txt)) do v[p[1]] = N(p[2]) end
    return v
  end
  local function ligneCalc(nom, formule, app, res)
    X(nom .. " = " .. formule)
    if app then X("   = " .. app) end
    R("   = " .. res, "", "")
  end

  ------------------------------------------------------------------ 1. compte de stock au CMP (E4)
  local DEF_STOCK = "si 1.03=1250@14;e 12.03=500@16;e 13.03=900@18;s 17.03=1000;e 25.03=300@17;s 27.03=1100;dec=4;arr=2;mode=g"

  SOLVEURS.coutsStock = function(txt)
    local src = source(txt, DEF_STOCK)
    local dec, arr, mode = 4, 2, "g"
    local mvts = {}
    for _, p in ipairs(paires(src)) do
      local k, v = p[1], p[2]
      if k == "dec" then dec = N(v) or 4
      elseif k == "arr" then arr = N(v) or 2
      elseif k == "mode" then mode = v:sub(1, 1)
      else
        local typ, date = k:match("^(%a+)%s*(.*)$")
        typ = (typ or ""):lower()
        local q, cu = v:match("^(.-)@(.*)$")
        if typ == "si" or typ == "e" then
          table.insert(mvts, {t = typ, date = date, q = N(q or v) or 0, cu = N(cu) or 0})
        elseif typ == "s" then
          table.insert(mvts, {t = "s", date = date, q = N(v) or 0})
        end
      end
    end
    vider()
    T("Compte de stock au CMP")
    G("Méthode : on valorise toutes les sorties au coût moyen pondéré = coût total (stock initial + entrées) ÷ quantité totale, " ..
      "arrondi à " .. dec .. " décimales (59 p.33-34 ; modèle : 59.13, 59.14, test 2026-02 ex. 1).")
    local ent, sor = {}, {}
    local qE, vE, qS, vS = 0, 0, 0, 0
    local nS = 0
    if mode == "p" then
      -- variante : CMP recalculé après chaque entrée (pas la méthode des corrigés du prof)
      A("Variante « CMP après chaque entrée » : les corrigés du prof utilisent le CMP de la période (mode=g).")
      local qs, vs = 0, 0
      for _, m in ipairs(mvts) do
        if m.t ~= "s" then
          local tot = m.q * m.cu
          qE = qE + m.q; vE = vE + tot; qs = qs + m.q; vs = vs + tot
          table.insert(ent, {(m.date ~= "" and (m.date .. " ") or "") .. (m.t == "si" and "Stock initial" or "Entrée"), fmt(m.q), F(m.cu, dec), F(tot, arr)})
        else
          nS = nS + 1
          local cmp = r0(vs / qs, dec)
          local tot = r0(m.q * cmp, arr)
          X("CMP au " .. m.date .. " = " .. F(vs, arr) .. " ÷ " .. fmt(qs) .. " = " .. F(cmp, dec))
          qS = qS + m.q; vS = vS + tot; qs = qs - m.q; vs = vs - tot
          table.insert(sor, {(m.date ~= "" and (m.date .. " ") or "") .. "Sortie n°" .. nS, fmt(m.q), F(cmp, dec), F(tot, arr)})
        end
      end
      local cmpf = qs > 0 and r0(vs / qs, dec) or 0
      table.insert(sor, {"Stock final", fmt(qs), F(cmpf, dec), F(vs, arr), trait = true})
      qS = qS + qs; vS = vS + vs
    else
      for _, m in ipairs(mvts) do
        if m.t ~= "s" then
          local tot = m.q * m.cu
          qE = qE + m.q; vE = vE + tot
          table.insert(ent, {(m.date ~= "" and (m.date .. " ") or "") .. (m.t == "si" and "Stock initial" or "Entrée"), fmt(m.q), F(m.cu, dec), F(tot, arr)})
        end
      end
      local cmp = r0(vE / qE, dec)
      ligneCalc("CMP", "coût total des entrées ÷ quantité totale", F(vE, arr) .. " ÷ " .. fmt(qE), F(cmp, dec))
      for _, m in ipairs(mvts) do
        if m.t == "s" then
          nS = nS + 1
          local tot = r0(m.q * cmp, arr)
          qS = qS + m.q; vS = vS + tot
          table.insert(sor, {(m.date ~= "" and (m.date .. " ") or "") .. "Bon de sortie n°" .. nS, fmt(m.q), F(cmp, dec), F(tot, arr)})
        end
      end
      local qf = qE - qS
      local vf = r0(qf * cmp, arr)
      X("Stock final = quantité totale − sorties = " .. fmt(qE) .. " − " .. fmt(qS) .. " = " .. fmt(qf))
      R("Stock final = " .. fmt(qf) .. " × " .. F(cmp, dec) .. " = " .. F(vf, arr), "", "")
      table.insert(sor, {"Stock final", fmt(qf), F(cmp, dec), F(vf, arr), trait = true})
      qS = qS + qf; vS = vS + vf
    end
    table.insert(ent, {"Total", fmt(qE), "", F(vE, arr), gras = true, trait = true})
    table.insert(sor, {"Total", fmt(qS), "", F(vS, arr), gras = true})
    GRILLE("Entrées (débit)", ent, {entetes = {"", "Qté", "CU", "Total"}})
    GRILLE("Sorties (crédit)", sor, {entetes = {"", "Qté", "CU", "Total"}})
    if math.abs(vS - vE) > 1e-9 then
      G("Écart d'arrondi débit − crédit : " .. F(vE - vS, arr) .. " (le CMP est arrondi ; le prof l'accepte : 46'800 / 46'799.98 au test 2026-02).")
    end
    montrer("Stock au CMP")
  end

  ------------------------------------------------------------------ 2. répartition des charges indirectes (E3)
  local DEF_REP = "sec=RH,Bât,Appro,Transfo,Empaq,Distr;aux=2;c Consomm.=680,545,16410,295,805,7162;" ..
    "c ACE=1150,1890,530,15140,1110,1850;c Formation=6000;k RH=0,15,20,30,20,15;k Bât=0,0,10,40,20,30;" ..
    "uo=6370,78,670,12000;nuo=kg,h mach,h hum,paquets;dec=0"

  SOLVEURS.coutsRepart = function(txt)
    local src = source(txt, DEF_REP)
    local sec, naux, ch, cles, uo, nuo, dec = {}, 0, {}, {}, {}, {}, 0
    for _, p in ipairs(paires(src)) do
      local k, v = p[1], p[2]
      if k == "sec" then sec = lst(v)
      elseif k == "aux" then naux = N(v) or 0
      elseif k == "uo" then for _, x in ipairs(lst(v)) do table.insert(uo, N(x) or 0) end
      elseif k == "nuo" then nuo = lst(v)
      elseif k == "dec" then dec = N(v) or 0
      else
        local typ, nom = k:match("^(%a)%s+(.+)$")
        if typ == "c" then
          local tot, poids = v:match("^(.-)@(.*)$")
          local c = {nom = nom, m = {}}
          if tot then
            -- total réparti selon une clé (poids ou %)
            local w, sw = {}, 0
            for _, x in ipairs(lst(poids)) do local y = N(x) or 0; table.insert(w, y); sw = sw + y end
            c.total = N(tot) or 0
            for i = 1, #sec do c.m[i] = sw > 0 and c.total * (w[i] or 0) / sw or 0 end
            c.cle = true
          else
            local l = lst(v)
            for i = 1, #sec do c.m[i] = N(l[i]) or 0 end
          end
          table.insert(ch, c)
        elseif typ == "k" then
          local w = {}
          for _, x in ipairs(lst(v)) do table.insert(w, N(x) or 0) end
          table.insert(cles, {nom = nom, w = w})
        end
      end
    end
    local ns = #sec
    vider()
    T("Répartition des charges indirectes")
    G("Méthode : 1) répartition primaire = somme des charges par section ; 2) répartition secondaire : chaque section " ..
      "auxiliaire est vidée, dans l'ordre, vers les sections suivantes selon sa clé ; 3) coût de l'UO = total secondaire ÷ " ..
      "nombre d'UO (59 p.18-24 ; modèle : test 2026-02 ex. 3 a, 59.9, 59.10, 59.15).")
    -- primaire
    local prim = {}
    for i = 1, ns do prim[i] = 0 end
    for _, c in ipairs(ch) do
      for i = 1, ns do prim[i] = prim[i] + c.m[i] end
      if c.cle then
        local l = {}
        for i = 1, ns do if c.m[i] ~= 0 then table.insert(l, {sec[i], F(c.m[i])}) end end
        GRILLE(c.nom .. " (" .. F(c.total) .. ") selon la clé", l, {entetes = {"", "Montant"}})
      end
    end
    -- grille primaire : charges par paquets de 3 colonnes
    local i0 = 1
    while i0 <= #ch do
      local paquet = {}
      for j = i0, math.min(i0 + 2, #ch) do table.insert(paquet, ch[j]) end
      local ent = {""}
      for _, c in ipairs(paquet) do table.insert(ent, c.nom) end
      local l = {}
      for i = 1, ns do
        local row = {sec[i] .. (i <= naux and " (aux)" or "")}
        for _, c in ipairs(paquet) do table.insert(row, F(c.m[i])) end
        table.insert(l, row)
      end
      local tot = {"Total", gras = true, trait = true}
      for _, c in ipairs(paquet) do local s = 0; for i = 1, ns do s = s + c.m[i] end; table.insert(tot, F(s)) end
      table.insert(l, tot)
      GRILLE("Charges par section", l, {entetes = ent})
      i0 = i0 + 3
    end
    -- secondaire (méthode en cascade)
    local cur, recu = {}, {}
    for i = 1, ns do cur[i] = prim[i]; recu[i] = 0 end
    for a = 1, naux do
      local cle
      for _, c in ipairs(cles) do if c.nom == sec[a] then cle = c end end
      if not cle then cle = cles[a] end
      if not cle then A("Clé manquante pour la section " .. sec[a] .. " : ajouter « k " .. sec[a] .. "=… »"); break end
      local w, sw = {}, 0
      for i = 1, ns do
        w[i] = (i > a) and (cle.w[i] or 0) or 0
        if i <= a and (cle.w[i] or 0) ~= 0 then A("Clé de " .. sec[a] .. " vers " .. sec[i] .. " ignorée (section déjà répartie).") end
        sw = sw + w[i]
      end
      local montant = cur[a]
      X("Section " .. sec[a] .. " : total à répartir = " .. F(montant) .. " ; montant reçu = total × clé ÷ somme des clés (" .. F(sw, 2) .. ")")
      local l = {}
      for i = 1, ns do
        if w[i] ~= 0 then
          local part = montant * w[i] / sw
          cur[i] = cur[i] + part; recu[i] = recu[i] + part
          table.insert(l, {sec[i], F(w[i], 2), F(part)})
        end
      end
      cur[a] = 0; recu[a] = recu[a] - montant
      table.insert(l, {"Total réparti", F(sw, 2), F(montant), gras = true, trait = true})
      GRILLE("Répartition " .. sec[a], l, {entetes = {"", "Clé", "Montant"}})
    end
    local l, sp, ss = {}, 0, 0
    for i = 1, ns do
      sp = sp + prim[i]; ss = ss + cur[i]
      table.insert(l, {sec[i] .. (i <= naux and " (aux)" or ""), F(prim[i]), F(recu[i]), F(cur[i]), fond = i <= naux})
    end
    table.insert(l, {"Total", F(sp), "", F(ss), gras = true, trait = true})
    GRILLE("Primaire → secondaire", l, {entetes = {"", "Primaire", "Reçu/cédé", "Second."}})
    -- unités d'œuvre
    local u = {}
    for i = naux + 1, ns do
      local k = i - naux
      local nb = uo[k]
      local nom = nuo[k] or ""
      if nb and nb ~= 0 then
        local cout = cur[i] / nb
        local enPct = nom:sub(1, 1) == "%"
        local aff = enPct and COMMUN.pct(cout) or F(cout, dec)
        X("Coût UO " .. sec[i] .. " = total secondaire ÷ nombre d'UO = " .. F(cur[i]) .. " ÷ " .. fmt(nb) .. " = " .. aff)
        table.insert(u, {sec[i] .. " (" .. nom .. ")", fmt(nb), aff})
      end
    end
    if #u > 0 then
      GRILLE("Unités d'œuvre", u, {entetes = {"", "Nb UO", "Coût UO"}})
      G("Arrondi du coût de l'UO : dec=" .. dec .. " (test 2026-02 : à l'unité ; 59.10, 59.15 : 4 décimales). Nom d'UO commençant par % : coût en % (base en CHF, ex. « %CAN »).")
    end
    montrer("Répartition des CI")
  end

  ------------------------------------------------------------------ 3. coûts complets en cascade (E5)
  local DEF_CASC = "mode=1;mpq=940;mpcu=7;achq=6370;achp=8;uoa=3;mpu=6350;h1=78;t1=160;n1=78;c1=247;q1=6350;sq1=905;scu1=14;so1=6055;" ..
    "h2=670;t2=45;n2=670;c2=6;q2=6055;sq2=30;scu2=22;so2=6000;dd=0;nd=12000;cd=1;vq=12000;pv=15;dec=4;arr=0"

  SOLVEURS.coutsCascade = function(txt)
    local v = champs(DEF_CASC, txt)
    local dec, arr = v.dec or 4, v.arr or 0
    local function rr(x) return r0(x, arr) end
    vider()
    T("Coûts : appro → prix de revient")
    G("Méthode : coût d'achat → stock de matières (CMP) → coût de production → stock de produits (CMP) → (2e atelier) → prix de " ..
      "revient → résultat. Chaque stock : CMP = (stock initial + entrées) ÷ quantités, " .. dec .. " décimales ; montants arrondis à " ..
      (arr == 0 and "l'unité" or (arr .. " déc.")) .. " (modèle : test 2026-02 ex. 3 b-i ; 59.15 avec mode=2).")
    -- a) approvisionnement
    T("1. Coût d'achat des matières achetées")
    local pan = rr(v.achq * v.achp)
    local cia = rr(v.achq * v.uoa)
    ligneCalc("Prix d'achat", "quantité achetée × prix", fmt(v.achq) .. " × " .. F(v.achp, 2), F(pan, arr))
    ligneCalc("CI d'approvisionnement", "nb d'UO × coût de l'UO", fmt(v.achq) .. " × " .. F(v.uoa, dec), F(cia, arr))
    local cach = pan + cia
    GRILLE("Coût d'achat", {
      {"Achat de matières", fmt(v.achq), F(v.achp, 2), F(pan, arr)},
      {"CI d'approvisionnement", fmt(v.achq), F(v.uoa, dec), F(cia, arr)},
      {"Coût d'achat", fmt(v.achq), F(cach / v.achq, dec), F(cach, arr), gras = true, trait = true}},
      {entetes = {"", "Qté", "CU", "Total"}})
    -- b) stock de matières
    T("2. Stock de matières premières")
    local vSI = rr(v.mpq * v.mpcu)
    local entree = (v.mode == 2) and pan or cach
    if v.mode == 2 then G("mode=2 (59.15) : le stock de matières est tenu au prix d'achat ; les CI d'approvisionnement s'ajoutent aux matières utilisées.") end
    local qT, vT = v.mpq + v.achq, vSI + entree
    local cmp1 = r0(vT / qT, dec)
    ligneCalc("CMP matières", "(stock initial + entrées) ÷ quantités", "(" .. F(vSI, arr) .. " + " .. F(entree, arr) .. ") ÷ " .. fmt(qT), F(cmp1, dec))
    local vU = rr(v.mpu * cmp1)
    local qF = qT - v.mpu
    local vF = rr(qF * cmp1)
    GRILLE("Stock MP : entrées", {
      {"Stock initial", fmt(v.mpq), F(v.mpcu, dec), F(vSI, arr)},
      {v.mode == 2 and "Achats (prix d'achat)" or "Coût d'achat", fmt(v.achq), F(entree / v.achq, dec), F(entree, arr)},
      {"Total", fmt(qT), "", F(vT, arr), gras = true, trait = true}}, {entetes = {"", "Qté", "CU", "Total"}})
    GRILLE("Stock MP : sorties", {
      {"Bon de sortie", fmt(v.mpu), F(cmp1, dec), F(vU, arr)},
      {"Stock final", fmt(qF), F(cmp1, dec), F(vF, arr)},
      {"Total", fmt(qT), "", F(vU + vF, arr), gras = true, trait = true}}, {entetes = {"", "Qté", "CU", "Total"}})
    local mpUt = vU
    if v.mode == 2 then
      local ciu = rr(v.mpu * v.uoa)
      X("CI d'approvisionnement des MP utilisées = " .. fmt(v.mpu) .. " × " .. F(v.uoa, dec) .. " = " .. F(ciu, arr))
      mpUt = vU + ciu
      R("Coût d'achat des MP utilisées = " .. F(vU, arr) .. " + " .. F(ciu, arr) .. " = " .. F(mpUt, arr), "", "")
    end
    -- c) ateliers de production
    local entreeAtelier, qEntree = mpUt, v.mpu
    local cuEntree = (v.mode == 2) and (mpUt / v.mpu) or cmp1
    local libEntree = "MP utilisées"
    local derniere = {cmp = cmp1, sortie = vU, q = v.mpu}
    for at = 1, 2 do
      local h, t, n, c, q = v["h" .. at] or 0, v["t" .. at] or 0, v["n" .. at] or 0, v["c" .. at] or 0, v["q" .. at] or 0
      if at == 2 and h == 0 and n == 0 then break end
      T((at + 2) .. ". Atelier " .. at .. " : coût de production")
      local cd = rr(h * t)
      local ci = rr(n * c)
      local cp = entreeAtelier + cd + ci
      X("Coût de production = " .. libEntree .. " + charges directes (h × taux) + charges indirectes (UO × coût UO)")
      X("   = " .. F(entreeAtelier, arr) .. " + " .. fmt(h) .. " × " .. F(t, 2) .. " + " .. fmt(n) .. " × " .. F(c, dec))
      R("   = " .. F(cp, arr) .. "  (unitaire " .. F(cp / q, dec) .. ")", "", "")
      GRILLE("Coût de production " .. at, {
        {libEntree, fmt(qEntree), F(cuEntree, dec), F(entreeAtelier, arr)},
        {"Charges directes", fmt(h), F(t, 2), F(cd, arr)},
        {"Charges indirectes", fmt(n), F(c, dec), F(ci, arr)},
        {"Coût de production", fmt(q), F(cp / q, dec), F(cp, arr), gras = true, trait = true}}, {entetes = {"", "Qté", "CU", "Total"}})
      -- stock de produits de l'atelier
      local sq, scu, so = v["sq" .. at] or 0, v["scu" .. at] or 0, v["so" .. at] or 0
      local vsi = rr(sq * scu)
      local qt, vt = sq + q, vsi + cp
      local cmp = r0(vt / qt, dec)
      ligneCalc("CMP stock " .. at, "(stock initial + production) ÷ quantités", "(" .. F(vsi, arr) .. " + " .. F(cp, arr) .. ") ÷ " .. fmt(qt), F(cmp, dec))
      local vso = rr(so * cmp)
      local qf2 = qt - so
      local vf2 = rr(qf2 * cmp)
      GRILLE("Stock " .. at .. " : entrées", {
        {"Stock initial", fmt(sq), F(scu, dec), F(vsi, arr)},
        {"Coût de production", fmt(q), F(cp / q, dec), F(cp, arr)},
        {"Total", fmt(qt), "", F(vt, arr), gras = true, trait = true}}, {entetes = {"", "Qté", "CU", "Total"}})
      GRILLE("Stock " .. at .. " : sorties", {
        {"Bon de sortie", fmt(so), F(cmp, dec), F(vso, arr)},
        {"Stock final", fmt(qf2), F(cmp, dec), F(vf2, arr)},
        {"Total", fmt(qt), "", F(vso + vf2, arr), gras = true, trait = true}}, {entetes = {"", "Qté", "CU", "Total"}})
      entreeAtelier, qEntree, cuEntree, libEntree = vso, so, cmp, "Produits atelier " .. at
      derniere = {cmp = cmp, sortie = vso, q = so}
    end
    -- d) prix de revient et résultat
    T("Prix de revient et résultat")
    local cid = rr(v.nd * v.cd)
    local pr = derniere.sortie + (v.dd or 0) + cid
    X("Prix de revient = coût de production des produits vendus + charges directes de distribution + CI de distribution")
    X("   = " .. F(derniere.sortie, arr) .. " + " .. F(v.dd or 0, arr) .. " + " .. fmt(v.nd) .. " × " .. F(v.cd, dec))
    R("   = " .. F(pr, arr), "", "")
    local ca = rr(v.vq * v.pv)
    local res = ca - pr
    GRILLE("Résultat", {
      {"Chiffre d'affaires", fmt(v.vq), F(v.pv, 2), F(ca, arr)},
      {"./. Prix de revient", fmt(v.vq), F(pr / v.vq, dec), F(-pr, arr)},
      {res >= 0 and "Bénéfice net" or "Perte nette", "", "", F(res, arr), gras = true, trait = true}}, {entetes = {"", "Qté", "CU", "Total"}})
    R("Résultat = CA − prix de revient = " .. F(res, arr), "", "")
    G("Données par défaut : test 2026-02 ex. 3. Le corrigé Excel du prof garde 92'640.29 non arrondi au 3e stock : CMP 20.9483, " ..
      "sortie 125'690, bénéfice 42'310 (ici 20.9482 et 42'311 en arrondissant chaque total). Écart de 1 CHF accepté.")
    montrer("Coûts en cascade")
  end

  ------------------------------------------------------------------ 4. prix de revient d'une commande (59.9 b, 59.10 b)
  local DEF_CMD = "mpq=150;mpp=3;ciap=0;ciak=0;modh=30;modt=25;u1=0.15;c1=316.48;u2=1;c2=29.8818;u3=1;c3=19.6445;dd=40;cid=6.73%;pc=2000;rem=10%;base=1"

  SOLVEURS.coutsCommande = function(txt)
    local v = champs(DEF_CMD, txt)
    vider()
    T("Prix de revient d'une commande")
    G("Méthode : coût d'approvisionnement (matières + CI d'appro.) → coût de production (+ MOD + CI des ateliers, UO × coût UO) → " ..
      "prix de revient (+ charges directes et CI de distribution) → résultat = prix net − PR (modèle : 59.10 b-c ; 59.9 b).")
    local mp = v.mpq * v.mpp
    local ciA = mp * (v.ciap or 0) + v.mpq * (v.ciak or 0)
    local appro = mp + ciA
    local l = {{"Matières premières", F(mp, 2)}}
    if ciA ~= 0 then table.insert(l, {"CI d'approvisionnement", F(ciA, 2)}) end
    table.insert(l, {"Coût d'appro.", F(appro, 2), gras = true, trait = true})
    X("Matières = " .. fmt(v.mpq) .. " × " .. F(v.mpp, 2) .. " = " .. F(mp, 2) ..
      ((v.ciap or 0) ~= 0 and ("; CI appro = " .. F(mp, 2) .. " × " .. COMMUN.pct(v.ciap) .. " = " .. F(mp * v.ciap, 2)) or "") ..
      ((v.ciak or 0) ~= 0 and ("; CI appro = " .. fmt(v.mpq) .. " × " .. F(v.ciak, 4) .. " = " .. F(v.mpq * v.ciak, 2)) or ""))
    local mod = v.modh * v.modt
    X("MOD = " .. fmt(v.modh) .. " h × " .. F(v.modt, 2) .. " = " .. F(mod, 2))
    table.insert(l, {"Main d'œuvre directe", F(mod, 2)})
    local prod = appro + mod
    for i = 1, 3 do
      local u, c = v["u" .. i] or 0, v["c" .. i] or 0
      if u ~= 0 and c ~= 0 then
        X("CI atelier " .. i .. " = " .. fmt(u, 3) .. " UO × " .. F(c, 4) .. " = " .. F(u * c, 2))
        table.insert(l, {"CI atelier " .. i, F(u * c, 2)})
        prod = prod + u * c
      end
    end
    table.insert(l, {"Coût de production", F(prod, 2), gras = true, trait = true})
    local net = v.pc * (1 - (v.rem or 0))
    local baseD = (v.base == 2) and net or v.pc
    local cid = baseD * (v.cid or 0)
    X("CI de distribution = " .. COMMUN.pct(v.cid or 0) .. " × " .. F(baseD, 2) .. (v.base == 2 and " (prix net)" or " (prix brut, CAB)") .. " = " .. F(cid, 2))
    if (v.dd or 0) ~= 0 then table.insert(l, {"Ch. directes distr.", F(v.dd, 2)}) end
    table.insert(l, {"CI de distribution", F(cid, 2)})
    local pr = prod + (v.dd or 0) + cid
    table.insert(l, {"Prix de revient", F(pr, 2), gras = true, trait = true})
    GRILLE("Prix de revient", l, {entetes = {"", "CHF"}})
    local res = net - pr
    GRILLE("Résultat de la commande", {
      {"Prix brut (catalogue)", F(v.pc, 2)},
      {"./. Remise " .. COMMUN.pct(v.rem or 0), F(-(v.pc - net), 2)},
      {"Prix de vente net", F(net, 2), trait = true},
      {"./. Prix de revient", F(-pr, 2)},
      {res >= 0 and "Bénéfice net" or "Perte nette", F(res, 2), gras = true, trait = true}}, {entetes = {"", "CHF"}})
    ligneCalc("Résultat en % du PR", "résultat × 100 ÷ prix de revient", F(res, 2) .. " × 100 ÷ " .. F(pr, 2), COMMUN.pct(res / pr))
    G("Défaut : 59.10 b-c (PR 1'471.60 ; bénéfice 328.40 = 22.32 % du PR). 59.9 b : mpq=400;mpp=4;ciap=14%;modh=80;modt=12;u1=80;c1=13.5;u2=0;u3=0;dd=0;cid=8%;pc=5000;rem=0.")
    montrer("Commande")
  end

  ------------------------------------------------------------------ 5. charges incorporables (E1, 59.1)
  local DEF_INC = "cg=260000;exc=12000;amo=80000;amon=16000;prov=190000;provn=17000;rem=120000;cp=600000;ti=5%;per=12"

  SOLVEURS.coutsIncorp = function(txt)
    local v = champs(DEF_INC, txt)
    local per = (v.per and v.per > 0) and v.per or 1
    vider()
    T("Charges incorporables (CAE)")
    G("Méthode : charges de la CAE = charges de la comptabilité générale − charges non incorporables + charges supplétives ; " ..
      "les montants annuels sont mensualisés (÷ " .. fmt(per) .. ") (59 p.5 ; modèle : 59.1).")
    local am = v.amo - v.amon
    local pv = v.prov - v.provn
    ligneCalc("Amortissements incorporables", "amortissements − amortissement exceptionnel", F(v.amo) .. " − " .. F(v.amon), F(am))
    ligneCalc("Provisions incorporables", "dotations − provisions non incorporables", F(v.prov) .. " − " .. F(v.provn), F(pv))
    local mens = (am + pv) / per
    ligneCalc("Charges mensualisées", "(amortissements + provisions) ÷ " .. fmt(per), F(am + pv) .. " ÷ " .. fmt(per), F(mens, 2))
    local rem = v.rem / per
    local int = v.cp * v.ti
    ligneCalc("Rémunération de l'exploitant", "montant annuel ÷ " .. fmt(per), F(v.rem) .. " ÷ " .. fmt(per), F(rem, 2))
    ligneCalc("Intérêt sur capital propre", "capital propre × taux ÷ " .. fmt(per), F(v.cp) .. " × " .. COMMUN.pct(v.ti) .. " ÷ " .. fmt(per), F(int / per, 2))
    local sup = rem + int / per
    local tot = v.cg + mens + sup
    GRILLE("Charges incorporables de la période", {
      {"Charges d'exploitation", F(v.cg)},
      {"Charges mensualisées", F(mens, 2)},
      {"Charges supplétives", F(sup, 2)},
      {"Charges incorporables", F(tot, 2), gras = true, trait = true}}, {entetes = {"", "CHF"}})
    if (v.exc or 0) ~= 0 then G("Les charges exceptionnelles (" .. F(v.exc) .. ") ne sont pas incorporables en CAE.") end
    montrer("Charges incorporables")
  end

  ------------------------------------------------------------------ 6. résultat analytique -> résultat de la CG (59.2)
  local DEF_RCG = "ra=140000+220000;exc=15600;amocg=62000;amocae=42000;chf=18000;prf=24000;cp=200000;ti=6%;rem=4000*12"

  SOLVEURS.coutsResCG = function(txt)
    local v = champs(DEF_RCG, txt)
    vider()
    T("Résultat analytique → résultat CG")
    G("Méthode : résultat CG = résultat analytique − charges non incorporées (exceptionnelles, financières, excédent d'amortissement " ..
      "comptable) + produits non incorporés + charges supplétives (intérêt calculé, rémunération fictive), qui ne sont pas des charges en CG (modèle : 59.2).")
    local da = v.amocg - v.amocae
    local int = v.cp * v.ti
    local l = {{"Bénéfice analytique", F(v.ra)}}
    if v.exc ~= 0 then table.insert(l, {"./. Charges except.", F(-v.exc)}) end
    if da ~= 0 then table.insert(l, {da > 0 and "./. Reprise s/amort." or "+ Amort. CAE > CG", F(-da)}) end
    if v.chf ~= 0 then table.insert(l, {"./. Charges financières", F(-v.chf)}) end
    if v.prf ~= 0 then table.insert(l, {"+ Produits financiers", F(v.prf)}) end
    if int ~= 0 then table.insert(l, {"+ Rémun. fonds propres", F(int)}) end
    if v.rem ~= 0 then table.insert(l, {"+ Rémun. exploitant", F(v.rem)}) end
    local rcg = v.ra - v.exc - da - v.chf + v.prf + int + v.rem
    table.insert(l, {"Bénéfice CG", F(rcg), gras = true, trait = true})
    X("Écart d'amortissement = amortissements CG − amortissements CAE = " .. F(v.amocg) .. " − " .. F(v.amocae) .. " = " .. F(da))
    X("Intérêt calculé = " .. F(v.cp) .. " × " .. COMMUN.pct(v.ti) .. " = " .. F(int))
    GRILLE("Passage au résultat CG", l, {entetes = {"", "CHF"}})
    R("Résultat CG = " .. F(rcg), "", "")
    montrer("Résultat CG")
  end

  ------------------------------------------------------------------ 7. résultat par département (E2, 59.6)
  local DEF_DEP = "qa=8000;pa=50;qb=12000;pb=60;pra=260000;prb=420000;fpa=90000;fpb=120000;fg=150000"

  SOLVEURS.coutsDept = function(txt)
    local v = champs(DEF_DEP, txt)
    vider()
    T("Résultat par département")
    G("Méthode : CA = quantité × prix ; charges directes affectées ; frais généraux répartis au prorata des articles vendus ; " ..
      "résultat unitaire = résultat ÷ quantité (modèle : 59.6).")
    local ca, cb = v.qa * v.pa, v.qb * v.pb
    local fga = v.fg * v.qa / (v.qa + v.qb)
    local fgb = v.fg - fga
    ligneCalc("Frais généraux A", "frais généraux × articles A ÷ total des articles", F(v.fg) .. " × " .. fmt(v.qa) .. " ÷ " .. fmt(v.qa + v.qb), F(fga))
    local ra = ca - v.pra - v.fpa - fga
    local rb = cb - v.prb - v.fpb - fgb
    GRILLE("Résultat global et par département", {
      {"Chiffre d'affaires", F(ca + cb), F(ca), F(cb)},
      {"./. PRAMV", F(-(v.pra + v.prb)), F(-v.pra), F(-v.prb)},
      {"./. Frais de personnel", F(-(v.fpa + v.fpb)), F(-v.fpa), F(-v.fpb)},
      {"./. Frais généraux", F(-v.fg), F(-fga), F(-fgb)},
      {"Résultat net", F(ra + rb), F(ra), F(rb), gras = true, trait = true}}, {entetes = {"", "Total", "Dép. A", "Dép. B"}})
    GRILLE("Par article", {
      {"Prix de vente", F(v.pa, 2), F(v.pb, 2)},
      {"./. PRAMV", F(-v.pra / v.qa, 2), F(-v.prb / v.qb, 2)},
      {"./. Frais de personnel", F(-v.fpa / v.qa, 2), F(-v.fpb / v.qb, 2)},
      {"./. Frais généraux", F(-fga / v.qa, 2), F(-fgb / v.qb, 2)},
      {"Résultat unitaire", F(ra / v.qa, 2), F(rb / v.qb, 2), gras = true, trait = true}}, {entetes = {"", "A", "B"}})
    montrer("Départements")
  end

  ------------------------------------------------------------------ 8. coût de l'unité d'œuvre (59.4, 59.7)
  local DEF_UO = "tot=2470000;p Profil B=35,5;p Profil E=40,12;p Profil M=45,6"

  SOLVEURS.coutsUO = function(txt)
    local src = source(txt, DEF_UO)
    local tot, pr = 0, {}
    for _, p in ipairs(paires(src)) do
      if p[1] == "tot" then tot = N(p[2]) or 0
      else
        local nom = p[1]:match("^p%s+(.+)$")
        if nom then local l = lst(p[2]); table.insert(pr, {nom = nom, h = N(l[1]) or 0, c = N(l[2]) or 1}) end
      end
    end
    vider()
    T("Coût de l'unité d'œuvre")
    G("Méthode : nombre d'UO = heures hebdomadaires × classes ; coût de l'UO = charges totales ÷ total des UO ; coût par profil = " ..
      "UO × coût de l'UO ; coût par classe = coût du profil ÷ classes (modèle : 59.7 ; 59.4 : une seule prestation).")
    local su = 0
    for _, q in ipairs(pr) do q.uo = q.h * q.c; su = su + q.uo end
    local cu = tot / su
    ligneCalc("Coût de l'UO", "charges ÷ nombre total d'UO", F(tot) .. " ÷ " .. fmt(su), F(cu, 4))
    local l = {}
    for _, q in ipairs(pr) do
      table.insert(l, {q.nom .. " (" .. fmt(q.h) .. "×" .. fmt(q.c) .. ")", fmt(q.uo), F(q.uo * cu), F(q.uo * cu / q.c)})
    end
    table.insert(l, {"Total", fmt(su), F(tot), "", gras = true, trait = true})
    GRILLE("Coût par profil et par classe", l, {entetes = {"", "UO", "Profil", "Classe"}})
    montrer("Unité d'œuvre")
  end

  ------------------------------------------------------------------ menu : une question par donnée (COMMUN.questionnaire)
  -- les solveurs gardent leur format interne « clé=valeur;… » (tests) : le questionnaire le reconstruit.
  local Q, lu, entier = COMMUN.questionnaire, COMMUN.lu, COMMUN.entier
  local function defs(def) local t = {}; for _, p in ipairs(paires(def)) do t[p[1]] = p[2] end; return t end
  local function ent(s) return (tostring(s or ""):gsub("%s", ""):gsub(",", ".")) end
  local function nom(s) return (tostring(s or ""):gsub("[,;=@]", " ")) end
  -- liste {cle, lib, aide[, opt]} -> champs avec défauts tirés de « clé=valeur;… »
  local function champsFixes(d, liste, segs)
    segs = segs or {}
    for _, c in ipairs(liste) do table.insert(segs, {cle = c[1], lib = c[2], defaut = d[c[1]] or "", aide = c[3], opt = c[4]}) end
    return segs
  end
  local function texteFixes(v, liste, t)
    for _, c in ipairs(liste) do t[#t + 1] = c[1] .. "=" .. (v._txt[c[1]] or "") end
    return t
  end
  local function qFixe(titre, def, liste, nomS)
    return function() Q(titre, champsFixes(defs(def), liste), function(v) SOLVEURS[nomS](table.concat(texteFixes(v, liste, {}), ";")) end) end
  end

  -- 1. compte de stock : mouvements un par un
  local function qStock()
    local mv, d = {}, {}
    for _, p in ipairs(paires(DEF_STOCK)) do
      local typ, date = p[1]:match("^(%a+)%s*(.*)$")
      if p[1] == "dec" or p[1] == "arr" or p[1] == "mode" then d[p[1]] = p[2]
      else local q, cu = p[2]:match("^(.-)@(.*)$"); mv[#mv + 1] = {typ, date, q or p[2], cu or ""} end
    end
    Q("Stock au CMP", COMMUN.repeter({
      {groupe = "Mouvement", n = {cle = "nm", lib = "Combien de mouvements (SI compris) ?", defaut = tostring(#mv), max = 15,
        aide = "Stock initial, chaque entrée et chaque bon de sortie, dans l'ordre des dates (59.13 : 6)."},
        champs = function(j) local m = mv[j] or {"", "", "", ""}; return {
          {cle = "ty", lib = "type (si, e ou s)", defaut = m[1], texte = true, aide = "si = stock initial, e = entrée (achat), s = sortie (bon de sortie).",
            valider = function(t) local x = t:lower(); if x ~= "si" and x ~= "e" and x ~= "s" then return "Taper si, e ou s." end end},
          {cle = "da", lib = "date", defaut = m[2], texte = true, opt = true, aide = "Date du mouvement (ex. 12.03) ; vide possible."},
          {cle = "qt", lib = "quantité", defaut = m[3], aide = "Quantité entrée ou sortie (unités, kg…)."},
          {cle = "cu", lib = "coût unitaire (si, e)", defaut = m[4], opt = true, aide = "Prix unitaire de l'entrée ou du stock initial ; vide pour une sortie (valorisée au CMP)."}} end},
      {cle = "dec", lib = "Décimales du CMP", defaut = d.dec or "4", aide = "Arrondi du coût moyen pondéré (prof : 4 décimales)."},
      {cle = "arr", lib = "Décimales des montants", defaut = d.arr or "2", aide = "Arrondi des totaux (2 = centimes)."},
      {cle = "mode", lib = "CMP : g (période) ou p (après chaque entrée)", defaut = d.mode or "g", texte = true,
        aide = "g = CMP de la période (méthode des corrigés du prof) ; p = variante recalculée après chaque entrée.",
        valider = function(t) if t ~= "g" and t ~= "p" then return "Taper g ou p." end end},
    }), function(v)
      local t = {}
      for _, e in ipairs(COMMUN.elements(v, entier(v.nm, 0), {"ty", "da", "qt", "cu"})) do
        local ty = e.ty:lower()
        local k = ty .. (e.da ~= "" and (" " .. nom(e.da)) or "")
        t[#t + 1] = k .. "=" .. ent(e.qt ~= "" and e.qt or "0") .. ((ty ~= "s" and e.cu ~= "") and ("@" .. ent(e.cu)) or "")
      end
      for _, k in ipairs({"dec", "arr", "mode"}) do t[#t + 1] = k .. "=" .. (v._txt[k] or "") end
      SOLVEURS.coutsStock(table.concat(t, ";"))
    end)
  end

  -- 2. répartition des charges indirectes : sections, charges par section, clés des auxiliaires, unités d'œuvre
  local function qRepart()
    local d, ch, cles = {}, {}, {}
    for _, p in ipairs(paires(DEF_REP)) do
      local typ, n = p[1]:match("^(%a)%s+(.+)$")
      if typ == "c" then local tot, w = p[2]:match("^(.-)@(.*)$"); ch[#ch + 1] = {n, tot or "", lst(w or p[2])}
      elseif typ == "k" then cles[n] = lst(p[2])
      else d[p[1]] = p[2] end
    end
    local sec, uo, nuo = lst(d.sec), lst(d.uo), lst(d.nuo)
    local function ns(val) return math.max(1, math.min(10, entier(lu(val, "ns", tostring(#sec)), #sec))) end
    local function na(val) return math.max(0, math.min(ns(val) - 1, entier(lu(val, "aux", d.aux), 0))) end
    local function nomSec(val, i) return lu(val, "sn_" .. i, sec[i] or ("S" .. i)) end
    Q("Répartition des CI", COMMUN.repeter({
      {groupe = "Section", n = {cle = "ns", lib = "Combien de sections (aux. comprises) ?", defaut = tostring(#sec), max = 10,
        aide = "Toutes les sections du tableau, auxiliaires d'abord, dans l'ordre de répartition (test 2026-02 : 6)."},
        champs = function(j) return {{cle = "sn", lib = "nom", defaut = sec[j] or "", texte = true,
          aide = "Nom court de la section (en-tête de colonne du tableau de répartition)."}} end},
      {cle = "aux", lib = "Combien de sections auxiliaires ?", defaut = d.aux or "0",
        aide = "Les premières sections de la liste : elles se vident vers les suivantes selon leur clé (59 p.20)."},
      {groupe = "Charge", n = {cle = "nc", lib = "Combien de charges indirectes ?", defaut = tostring(#ch), max = 10,
        aide = "Lignes du tableau de répartition primaire (consommables, ACE, formation…)."},
        champs = function(j, val)
          local c = ch[j] or {"", "", {}}
          local l = {
            {cle = "cn", lib = "nom", defaut = c[1], texte = true, aide = "Nom de la charge (ligne de la répartition primaire)."},
            {cle = "ct", lib = "total à répartir selon une clé", defaut = c[2], opt = true,
              aide = "Vide = montants donnés par section ; sinon total réparti selon les poids des questions suivantes."}}
          for i = 1, ns(val) do
            l[#l + 1] = {cle = "cm" .. i, lib = "montant (ou poids) " .. nomSec(val, i), defaut = c[3][i] or "", opt = true,
              aide = "Part de la charge pour la section " .. nomSec(val, i) .. " (vide = 0)."}
          end
          return l
        end},
      {groupe = "Clé", nombre = na, champs = function(a, val)
          local l, w = {}, cles[sec[a] or ""] or {}
          for i = a + 1, ns(val) do
            l[#l + 1] = {cle = "kw" .. i, lib = nomSec(val, a) .. " → " .. nomSec(val, i), defaut = w[i] or "", opt = true,
              aide = "Poids (ou %) de la clé de répartition de la section auxiliaire " .. nomSec(val, a) .. " (vide = 0)."}
          end
          return l
        end},
      {groupe = "UO", nombre = function(val) return ns(val) - na(val) end, champs = function(k, val)
          local i = k + na(val)
          return {
            {cle = "un", lib = nomSec(val, i) .. " : nombre d'UO", defaut = uo[k] or "", opt = true,
              aide = "Nombre d'unités d'œuvre de la section (heures, kg…). Coût UO = total secondaire ÷ nombre."},
            {cle = "ul", lib = nomSec(val, i) .. " : nature de l'UO", defaut = nuo[k] or "", texte = true, opt = true,
              aide = "Ex. kg, h mach, paquets ; commencer par % pour un coût en % (base en CHF, ex. %CAN)."}}
        end},
      {cle = "dec", lib = "Décimales du coût de l'UO", defaut = d.dec or "0", aide = "Test 2026-02 : à l'unité (0) ; 59.10, 59.15 : 4 décimales."},
    }), function(v)
      local val = v._txt
      local n, a = ns(val), na(val)
      local s, t = {}, {}
      for i = 1, n do s[i] = nom(nomSec(val, i)) end
      t[#t + 1] = "sec=" .. table.concat(s, ",")
      t[#t + 1] = "aux=" .. a
      for j = 1, entier(v.nc, 0) do
        local m = {}
        for i = 1, n do local x = val["cm" .. i .. "_" .. j] or ""; m[i] = ent(x ~= "" and x or "0") end
        local tot = val["ct_" .. j] or ""
        t[#t + 1] = "c " .. nom(val["cn_" .. j] ~= "" and val["cn_" .. j] or ("Charge " .. j)) .. "=" ..
          (tot ~= "" and (ent(tot) .. "@") or "") .. table.concat(m, ",")
      end
      for k = 1, a do
        local w = {}
        for i = 1, n do local x = i > k and (val["kw" .. i .. "_" .. k] or "") or ""; w[i] = ent(x ~= "" and x or "0") end
        t[#t + 1] = "k " .. s[k] .. "=" .. table.concat(w, ",")
      end
      local u, ul = {}, {}
      for k = 1, n - a do
        local x = val["un_" .. k] or ""; u[k] = ent(x ~= "" and x or "0"); ul[k] = nom(val["ul_" .. k] or "")
      end
      t[#t + 1] = "uo=" .. table.concat(u, ",")
      t[#t + 1] = "nuo=" .. table.concat(ul, ",")
      t[#t + 1] = "dec=" .. (val.dec or "")
      SOLVEURS.coutsRepart(table.concat(t, ";"))
    end)
  end

  -- 3. cascade : approvisionnement, 1 ou 2 ateliers, distribution, ventes
  local CASC_DEBUT = {
    {"mode", "Mode : 1 (CI appro en stock) ou 2", "1 = stock de MP au coût d'achat (test 2026-02) ; 2 = au prix d'achat, CI appro ajoutées aux MP utilisées (59.15)."},
    {"mpq", "Stock initial MP : quantité", "Stock de matières premières au début (quantité)."},
    {"mpcu", "Stock initial MP : coût unitaire", "Coût unitaire du stock initial de matières."},
    {"achq", "Matières achetées : quantité", "Quantité de matières achetée pendant la période."},
    {"achp", "Matières achetées : prix unitaire", "Prix d'achat unitaire des matières."},
    {"uoa", "Coût de l'UO d'approvisionnement", "Coût de l'unité d'œuvre de la section appro (tableau de répartition) ; UO = quantité achetée."},
    {"mpu", "Matières utilisées : quantité", "Bon de sortie des matières vers la production (quantité)."},
  }
  local CASC_ATELIER = {
    {"h", "heures de MOD", "Heures de main-d'œuvre directe de l'atelier."},
    {"t", "taux horaire de la MOD", "Coût d'une heure de main-d'œuvre directe."},
    {"n", "nombre d'UO", "Unités d'œuvre de l'atelier (tableau de répartition)."},
    {"c", "coût de l'UO", "Coût de l'unité d'œuvre de l'atelier (tableau de répartition)."},
    {"q", "quantité produite", "Produits sortis de l'atelier."},
    {"sq", "stock initial : quantité", "Stock initial de produits de l'atelier (quantité)."},
    {"scu", "stock initial : coût unitaire", "Coût unitaire du stock initial de produits."},
    {"so", "sorties du stock : quantité", "Produits sortis du stock (vers l'atelier suivant ou vendus)."},
  }
  local CASC_FIN = {
    {"dd", "Charges directes de distribution", "Charges de distribution affectées directement (0 si aucune)."},
    {"nd", "UO de distribution : nombre", "Unités d'œuvre de la section distribution (ex. paquets vendus)."},
    {"cd", "Coût de l'UO de distribution", "Coût de l'UO de distribution (tableau de répartition)."},
    {"vq", "Quantité vendue", "Produits vendus."},
    {"pv", "Prix de vente unitaire", "Prix de vente d'un produit."},
    {"dec", "Décimales des CMP", "Arrondi des coûts unitaires (prof : 4)."},
    {"arr", "Décimales des montants", "Arrondi des totaux (0 = au franc, test 2026-02)."},
  }
  local function qCascade()
    local d = defs(DEF_CASC)
    local segs = champsFixes(d, CASC_DEBUT)
    segs[#segs + 1] = {groupe = "Atelier", n = {cle = "nat", lib = "Combien d'ateliers ? (1 ou 2)", defaut = (d.h2 and d.h2 ~= "0") and "2" or "1", max = 2,
        aide = "Ateliers de production successifs (test 2026-02 : transformation puis empaquetage)."},
      champs = function(j) local l = {}
        for _, c in ipairs(CASC_ATELIER) do l[#l + 1] = {cle = c[1], lib = c[2], defaut = d[c[1] .. j] or "", aide = c[3]} end
        return l end}
    champsFixes(d, CASC_FIN, segs)
    Q("Coûts en cascade", COMMUN.repeter(segs), function(v)
      local t = texteFixes(v, CASC_DEBUT, {})
      local na = entier(v.nat, 1)
      for j = 1, 2 do
        for _, c in ipairs(CASC_ATELIER) do t[#t + 1] = c[1] .. j .. "=" .. (j <= na and (v._txt[c[1] .. "_" .. j] or "") or "0") end
      end
      SOLVEURS.coutsCascade(table.concat(texteFixes(v, CASC_FIN, t), ";"))
    end)
  end

  -- 4. commande : matières, MOD, ateliers (UO × coût), distribution, prix
  local CMD_DEBUT = {
    {"mpq", "Matières : quantité", "Quantité de matières premières pour la commande."},
    {"mpp", "Matières : prix unitaire", "Prix d'achat unitaire des matières."},
    {"ciap", "CI appro en % des matières", "Charges indirectes d'approvisionnement en % du coût des matières (59.9 b : 14%). 0 = non.", true},
    {"ciak", "CI appro par unité de matière", "CI d'approvisionnement par kg ou unité de matière. 0 = non.", true},
    {"modh", "MOD : heures", "Heures de main-d'œuvre directe pour la commande."},
    {"modt", "MOD : taux horaire", "Coût d'une heure de MOD."},
  }
  local CMD_FIN = {
    {"dd", "Charges directes de distribution", "Charges de distribution propres à la commande (0 si aucune).", true},
    {"cid", "CI de distribution (taux)", "Taux des charges indirectes de distribution (ex. 6.73%), appliqué au prix."},
    {"pc", "Prix brut (catalogue)", "Prix de vente catalogue de la commande."},
    {"rem", "Remise accordée", "Remise en % du prix brut (0 si aucune).", true},
    {"base", "Base des CI distr. : 1 brut, 2 net", "1 = prix brut (CAB) ; 2 = prix net après remise."},
  }
  local function qCommande()
    local d = defs(DEF_CMD)
    local nat = 0
    for j = 1, 3 do if (N(d["u" .. j]) or 0) ~= 0 then nat = j end end
    local segs = champsFixes(d, CMD_DEBUT)
    segs[#segs + 1] = {groupe = "Atelier", n = {cle = "nat", lib = "Combien d'ateliers ? (0 à 3)", defaut = tostring(nat), min = 0, max = 3,
        aide = "Sections de production traversées par la commande (59.10 b : 3)."},
      champs = function(j) return {
        {cle = "u", lib = "nombre d'UO", defaut = d["u" .. j] or "", aide = "Unités d'œuvre consommées par la commande dans l'atelier."},
        {cle = "c", lib = "coût de l'UO", defaut = d["c" .. j] or "", aide = "Coût de l'unité d'œuvre (tableau de répartition)."}} end}
    champsFixes(d, CMD_FIN, segs)
    Q("Commande", COMMUN.repeter(segs), function(v)
      local t = texteFixes(v, CMD_DEBUT, {})
      local na = entier(v.nat, 0)
      for j = 1, 3 do
        t[#t + 1] = "u" .. j .. "=" .. (j <= na and (v._txt["u_" .. j] or "") or "0")
        t[#t + 1] = "c" .. j .. "=" .. (j <= na and (v._txt["c_" .. j] or "") or "0")
      end
      SOLVEURS.coutsCommande(table.concat(texteFixes(v, CMD_FIN, t), ";"))
    end)
  end

  local CH_INC = {
    {"cg", "Charges d'exploitation (période)", "Charges de la comptabilité générale de la période, sans amortissements ni provisions."},
    {"exc", "Charges exceptionnelles", "Non incorporables en CAE (0 si aucune).", true},
    {"amo", "Amortissements (annuels)", "Amortissements comptables de l'année."},
    {"amon", "Amortissement exceptionnel", "Part non incorporable des amortissements (0 si aucune).", true},
    {"prov", "Provisions (annuelles)", "Dotations aux provisions de l'année."},
    {"provn", "Provisions non incorporables", "Part non incorporable des provisions (0 si aucune).", true},
    {"rem", "Rémunération de l'exploitant (an)", "Charge supplétive : salaire fictif de l'exploitant, par an."},
    {"cp", "Capital propre", "Base de l'intérêt calculé (charge supplétive)."},
    {"ti", "Taux de l'intérêt calculé", "Taux appliqué au capital propre (ex. 5%)."},
    {"per", "Périodes par an", "12 = mensuel : les montants annuels sont divisés par ce nombre."},
  }
  local CH_RCG = {
    {"ra", "Résultat analytique", "Résultat de la CAE (somme des résultats des produits, ex. 140000+220000)."},
    {"exc", "Charges exceptionnelles", "Non incorporées en CAE : à retrancher.", true},
    {"amocg", "Amortissements CG", "Amortissements comptables (comptabilité générale)."},
    {"amocae", "Amortissements CAE", "Amortissements calculés en CAE."},
    {"chf", "Charges financières", "Non incorporées en CAE : à retrancher.", true},
    {"prf", "Produits financiers", "Non incorporés en CAE : à ajouter.", true},
    {"cp", "Capital propre", "Base de l'intérêt calculé (charge supplétive, pas une charge en CG)."},
    {"ti", "Taux de l'intérêt calculé", "Taux de rémunération des fonds propres (ex. 6%)."},
    {"rem", "Rémunération de l'exploitant", "Charge supplétive de la période (ex. 4000*12)."},
  }
  local CH_DEP = {
    {"qa", "Dép. A : articles vendus", "Quantité vendue du département A (clé des frais généraux)."},
    {"pa", "Dép. A : prix de vente", "Prix de vente unitaire de A."},
    {"qb", "Dép. B : articles vendus", "Quantité vendue du département B."},
    {"pb", "Dép. B : prix de vente", "Prix de vente unitaire de B."},
    {"pra", "Dép. A : PRAMV", "Charges de marchandises de A (affectées directement)."},
    {"prb", "Dép. B : PRAMV", "Charges de marchandises de B."},
    {"fpa", "Dép. A : frais de personnel", "Frais de personnel affectés à A."},
    {"fpb", "Dép. B : frais de personnel", "Frais de personnel affectés à B."},
    {"fg", "Frais généraux communs", "Répartis au prorata des articles vendus (59.6)."},
  }
  local function qUO()
    local tot, pr = "", {}
    for _, p in ipairs(paires(DEF_UO)) do
      if p[1] == "tot" then tot = p[2] else local n = p[1]:match("^p%s+(.+)$"); if n then local l = lst(p[2]); pr[#pr + 1] = {n, l[1], l[2]} end end
    end
    Q("Unité d'œuvre", COMMUN.repeter({
      {cle = "tot", lib = "Charges totales", defaut = tot, aide = "Charges à répartir sur les unités d'œuvre (59.7 : 2'470'000)."},
      {groupe = "Profil", n = {cle = "np", lib = "Combien de profils (prestations) ?", defaut = tostring(#pr), max = 10,
        aide = "Profils ou prestations qui consomment des UO (59.7 : profils B, E, M ; 59.4 : 1)."},
        champs = function(j) local p = pr[j] or {"", "", ""}; return {
          {cle = "pn", lib = "nom", defaut = p[1], texte = true, aide = "Nom du profil."},
          {cle = "ph", lib = "heures hebdomadaires", defaut = p[2], aide = "Heures par semaine du profil ; UO = heures × classes."},
          {cle = "pc", lib = "nombre de classes", defaut = p[3], aide = "Nombre de classes du profil (1 si une seule)."}} end},
    }), function(v)
      local t = {"tot=" .. (v._txt.tot or "")}
      for j, e in ipairs(COMMUN.elements(v, entier(v.np, 0), {"pn", "ph", "pc"})) do
        t[#t + 1] = "p " .. nom(e.pn ~= "" and e.pn or ("Profil " .. j)) .. "=" .. ent(e.ph ~= "" and e.ph or "0") .. "," .. ent(e.pc ~= "" and e.pc or "1")
      end
      SOLVEURS.coutsUO(table.concat(t, ";"))
    end)
  end
  -- forts / mots / si : index de la recherche (99_menu) ; radicaux sans accents (voir CONVENTIONS-MODULES.md)
  table.insert(MENUS_COMPTA, {ordre = 59, titre = "Coûts (59)", items = {
    {"Compte de stock au CMP", qStock,
      forts = "cmp pondere entree sortie", mots = "compte stock etablir presenter cout moyen matiere premiere achetee",
      si = "entrées / sorties valorisées au CMP"},
    {"Répartition des charges indirectes", qRepart,
      forts = "repartition indirecte section", mots = "charge tableau auxiliaire principale unite oeuvre etablir primaire secondaire cle",
      si = "tableau de répartition (sections, clés)"},
    {"Coûts : appro → prix de revient", qCascade,
      forts = "approvisionnement transformation distribu complet cascade revient mois", mots = "cout prix production matiere premiere resultat atelier fabrication",
      si = "cascade : appro → production → prix de revient"},
    {"Prix de revient d'une commande", qCommande,
      forts = "commande devis revient", mots = "prix remise mod produit resultat",
      si = "une commande ou un produit : PR et résultat"},
    {"Charges incorporables", qFixe("Charges incorporables", DEF_INC, CH_INC, "coutsIncorp"),
      forts = "incorporable incorporee", mots = "charge cae periode mois montant",
      si = "charges de la CG → charges incorporables"},
    {"Résultat analytique → CG", qFixe("Résultat CG (59.2)", DEF_RCG, CH_RCG, "coutsResCG"),
      forts = "generale cg concordance", mots = "resultat analytique correction determination passage",
      si = "résultat analytique → résultat de la CG"},
    {"Résultat par département", qFixe("Départements (59.6)", DEF_DEP, CH_DEP, "coutsDept"),
      forts = "departement", mots = "resultat produit frais generaux",
      si = "résultat par produit / département"},
    {"Coût de l'unité d'œuvre", qUO,
      forts = "oeuvre uo profil classe", mots = "cout unite heure tableau completer",
      si = "coût par unité d'œuvre (profil, classe)"},
  }})
end
