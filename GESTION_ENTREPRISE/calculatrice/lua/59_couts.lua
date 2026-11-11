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
  -- formulaire simple : valeurs par défaut puis valeurs saisies
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
    T("Coûts complets en cascade")
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

  ------------------------------------------------------------------ menu
  local function saisir(msg, defaut, nom)
    return function() demander(msg, function(t) SOLVEURS[nom](t) end, defaut) end
  end
  table.insert(MENUS_COMPTA, {ordre = 59, titre = "Coûts (59)", items = {
    {"Compte de stock au CMP", saisir("Stock : si date=q@cu ; e date=q@cu ; s date=q ; dec ; arr ; mode=g (période) ou p", DEF_STOCK, "coutsStock")},
    {"Répartition des charges indirectes", saisir("sec=… ; aux=nb ; c Nom=montants ou total@clé ; k Section=clé ; uo=… ; nuo=… ; dec", DEF_REP, "coutsRepart")},
    {"Coûts complets en cascade", saisir("mode 1 (CI appro en stock) / 2 (59.15) ; SI MP, achats, uoa ; ateliers h,t,n,c,q, stock sq,scu,so ; distribution nd,cd ; ventes vq,pv", DEF_CASC, "coutsCascade")},
    {"Prix de revient d'une commande", saisir("Matières, CI appro (% ou /kg), MOD, CI ateliers u×c, distribution, prix et remise", DEF_CMD, "coutsCommande")},
    {"Charges incorporables", saisir("cg = charges d'exploitation de la période ; montants annuels ; per = périodes par an", DEF_INC, "coutsIncorp")},
    {"Résultat analytique → CG", saisir("ra = résultat analytique ; corrections", DEF_RCG, "coutsResCG")},
    {"Résultat par département", saisir("Quantités, prix, charges directes ; fg réparti selon les articles", DEF_DEP, "coutsDept")},
    {"Coût de l'unité d'œuvre", saisir("tot = charges ; p Nom=heures,classes", DEF_UO, "coutsUO")},
  }})
end
