-- 37_reserves.lua : chap. 37, principes d'evaluation et reserves latentes (RL)
-- Sources : exercices/chap-37/txt/corrige-37-*.md, examens/2025-11-intermediaire/txt/corrige-prof.md
do
  ---------------------------------------------------------------- evaluateur maison (sans load : Lua 5.1 de la machine)
  -- accepte 12'500, 2/3, 400*5%, -(15), min(1070000,1083000), max(a,b) ; "?" ou vide -> nil
  local function evaluer(s)
    if type(s) == "number" then return s end
    if s == nil then return nil end
    s = tostring(s):gsub("'", ""):gsub("’", ""):gsub("%s", ""):gsub("−", "-"):gsub("×", "*"):gsub("÷", "/")
    if s == "" or s:find("?", 1, true) then return nil end
    if not s:find("(", 1, true) then s = s:gsub(",", ".") end
    local pos, n = 1, #s
    local expr
    local function car() return s:sub(pos, pos) end
    local function primaire()
      local c = car()
      if c == "(" then
        pos = pos + 1
        local v = expr(); if car() ~= ")" then error("parenthèse") end
        pos = pos + 1; return v
      end
      local nom = s:match("^%a+", pos)
      if nom then
        pos = pos + #nom
        if car() ~= "(" then error("nom inconnu : " .. nom) end
        pos = pos + 1
        local args = {expr()}
        while car() == "," do pos = pos + 1; table.insert(args, expr()) end
        if car() ~= ")" then error("parenthèse") end
        pos = pos + 1
        local r = args[1]
        for i = 2, #args do
          if nom == "min" then r = math.min(r, args[i]) elseif nom == "max" then r = math.max(r, args[i]) else error("fonction " .. nom) end
        end
        return r
      end
      local num = s:match("^%d*%.?%d+", pos) or s:match("^%d+%.?", pos)
      if not num then error("nombre attendu") end
      pos = pos + #num
      return tonumber(num)
    end
    local function postfixe()
      local v = primaire()
      while car() == "%" do v = v / 100; pos = pos + 1 end
      return v
    end
    local function unaire()
      local c = car()
      if c == "-" then pos = pos + 1; return -unaire() end
      if c == "+" then pos = pos + 1; return unaire() end
      return postfixe()
    end
    local function terme()
      local v = unaire()
      while true do
        local c = car()
        if c == "*" then pos = pos + 1; v = v * unaire()
        elseif c == "/" then pos = pos + 1; v = v / unaire()
        else return v end
      end
    end
    expr = function()
      local v = terme()
      while true do
        local c = car()
        if c == "+" then pos = pos + 1; v = v + terme()
        elseif c == "-" then pos = pos + 1; v = v - terme()
        else return v end
      end
    end
    local ok, v = pcall(expr)
    if ok and pos > n and type(v) == "number" then return v end
    return nil
  end

  ---------------------------------------------------------------- outils
  local function arr(x) if not x then return nil end; return math.floor(x * 1e6 + 0.5) / 1e6 end
  local function f(x)  -- montant : entier si possible, sinon 2 decimales
    if x == nil then return "?" end
    x = arr(x)
    if math.abs(x - math.floor(x + 0.5)) < 1e-6 then return fmt(math.floor(x + 0.5)) end
    return fmt(x, 2)
  end
  local function fs(x) if x == nil then return "?" end; return (arr(x) > 0 and "+" or "") .. f(x) end   -- signe explicite
  local function fp(x) if x ~= nil and arr(x) < 0 then return "(" .. f(x) .. ")" end; return f(x) end    -- negatif entre parentheses
  local function pc(x) if not x then return "?" end; return string.format("%g %%", arr(x * 100)) end
  local function sens(v) if arr(v) > 0 then return "augmentation = constitution" elseif arr(v) < 0 then return "diminution = dissolution" end; return "aucune variation" end

  -- formulaire « cle=valeur;… » evalue par l'evaluateur maison ; « ? » = inconnue (nil)
  local function lireParams(txt, champs)
    local v = {}
    for _, c in ipairs(champs) do v[c.cle] = evaluer(c.defaut) end
    for paire in tostring(txt or ""):gmatch("[^;]+") do
      local k, val = paire:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
      if k then v[k] = evaluer(val) end
    end
    return v
  end
  local function formu(titre, champs, suite)
    local pre = {}
    for _, c in ipairs(champs) do table.insert(pre, c.cle .. "=" .. (c.defaut or "")) end
    demander(titre .. " (" .. COMMUN.aideChamps(champs) .. ")", function(txt) suite(txt) end, table.concat(pre, ";"))
  end

  -- coupe au niveau 0 des parentheses
  local function couperA(s, sep)
    local out, prof, cur = {}, 0, ""
    for i = 1, #s do
      local c = s:sub(i, i)
      if c == "(" then prof = prof + 1 elseif c == ")" then prof = prof - 1 end
      if c == sep and prof == 0 then table.insert(out, cur); cur = "" else cur = cur .. c end
    end
    table.insert(out, cur)
    return out
  end
  local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

  -- saisie eclair « Nom:v1/v2/…;Nom2:… » ; valeurs separees par « / » ou, si la partie valeurs contient des espaces, par des espaces
  local function lireLignes(txt)
    local out = {}
    for _, morceau in ipairs(couperA(tostring(txt or ""), ";")) do
      local nom, vals = morceau:match("^%s*(.-)%s*:%s*(.-)%s*$")
      if nom and nom ~= "" then
        local brut = {}
        if vals:find("%s") then for t in vals:gmatch("%S+") do table.insert(brut, t) end
        else for _, t in ipairs(couperA(vals, "/")) do table.insert(brut, trim(t)) end end
        local nums = {}
        for i, t in ipairs(brut) do nums[i] = evaluer(t) end
        table.insert(out, {nom = nom, brut = brut, v = nums})
      end
    end
    return out
  end

  ---------------------------------------------------------------- propagation d'une ligne du tableau des RL
  -- champs : vci, vri, rli (bilan initial) ; vcf, vrf, rlf (bilan final) ; var ; frac = VC / VR (stock « aux 2/3 »)
  local LIB = {vci = "VC 01.01", vri = "VR 01.01", rli = "RL 01.01", vcf = "VC 31.12", vrf = "VR 31.12", rlf = "RL 31.12", var = "Variation"}
  local EQS = {{"rli", "vri", "vci"}, {"rlf", "vrf", "vcf"}, {"var", "rlf", "rli"}}   -- a = b - c
  local function etapeLigne(L, notes)
    local change = false
    for _, e in ipairs(EQS) do
      local a, b, c = e[1], e[2], e[3]
      if L[a] == nil and L[b] ~= nil and L[c] ~= nil then
        L[a] = L[b] - L[c]; change = true
        table.insert(notes, L.nom .. " : " .. LIB[a] .. " = " .. LIB[b] .. " − " .. LIB[c] .. " = " .. f(L[b]) .. " − " .. fp(L[c]) .. " = " .. f(L[a]))
      elseif L[b] == nil and L[a] ~= nil and L[c] ~= nil then
        L[b] = L[a] + L[c]; change = true
        table.insert(notes, L.nom .. " : " .. LIB[b] .. " = " .. LIB[c] .. " + " .. LIB[a] .. " = " .. f(L[c]) .. " + " .. fp(L[a]) .. " = " .. f(L[b]))
      elseif L[c] == nil and L[a] ~= nil and L[b] ~= nil then
        L[c] = L[b] - L[a]; change = true
        table.insert(notes, L.nom .. " : " .. LIB[c] .. " = " .. LIB[b] .. " − " .. LIB[a] .. " = " .. f(L[b]) .. " − " .. fp(L[a]) .. " = " .. f(L[c]))
      end
    end
    if L.frac then
      for _, p in ipairs({{"vci", "vri"}, {"vcf", "vrf"}}) do
        local vc, vr = p[1], p[2]
        if L[vc] == nil and L[vr] ~= nil then
          L[vc] = L.frac * L[vr]; change = true
          table.insert(notes, L.nom .. " : " .. LIB[vc] .. " = " .. L.fracTxt .. " × " .. LIB[vr] .. " = " .. L.fracTxt .. " × " .. f(L[vr]) .. " = " .. f(L[vc]))
        elseif L[vr] == nil and L[vc] ~= nil then
          L[vr] = L[vc] / L.frac; change = true
          table.insert(notes, L.nom .. " : " .. LIB[vr] .. " = " .. LIB[vc] .. " ÷ " .. L.fracTxt .. " = " .. f(L[vc]) .. " ÷ " .. L.fracTxt .. " = " .. f(L[vr]))
        end
      end
    end
    return change
  end
  -- chainage d'annees : bilan final de la ligne k = bilan initial de la ligne k+1
  local function etapeChaine(rows, notes)
    local change = false
    for k = 1, #rows - 1 do
      local a, b = rows[k], rows[k + 1]
      for _, p in ipairs({{"vcf", "vci"}, {"vrf", "vri"}, {"rlf", "rli"}}) do
        if a[p[1]] == nil and b[p[2]] ~= nil then
          a[p[1]] = b[p[2]]; change = true
          table.insert(notes, a.nom .. " : " .. LIB[p[1]] .. " = " .. LIB[p[2]] .. " de " .. b.nom .. " = " .. f(a[p[1]]))
        elseif b[p[2]] == nil and a[p[1]] ~= nil then
          b[p[2]] = a[p[1]]; change = true
          table.insert(notes, b.nom .. " : " .. LIB[p[2]] .. " = " .. LIB[p[1]] .. " de " .. a.nom .. " = " .. f(b[p[2]]))
        end
      end
    end
    return change
  end
  local function propager(rows, chainer)
    local notes = {}
    local tours = 0
    while tours < 50 do
      tours = tours + 1
      local ch = false
      for _, L in ipairs(rows) do if etapeLigne(L, notes) then ch = true end end
      if chainer and etapeChaine(rows, notes) then ch = true end
      if not ch then break end
    end
    return notes
  end

  local function estPassif(nom)
    local n = nom:lower()
    return n:find("ducroire") or n:find("provision") or n:find("^%./%.") or n:find("^%-")
  end

  -- lignes du tableau des RL : « Nom[@fraction]:VCi/VRi/VCf/VRf » ou « Nom:VCi/VRi/RLi/VCf/VRf/RLf/Var » (« ? » = inconnue)
  local function lignesRL(txt)
    local rows = {}
    for _, l in ipairs(lireLignes(txt)) do
      local nom, fr = l.nom:match("^(.-)%s*@%s*(.+)$")
      nom = nom or l.nom
      local L = {nom = nom}
      if fr then L.frac = evaluer(fr); L.fracTxt = fr end
      local v = l.v
      if #l.brut == 4 then L.vci, L.vri, L.vcf, L.vrf = v[1], v[2], v[3], v[4]
      else L.vci, L.vri, L.rli, L.vcf, L.vrf, L.rlf, L.var = v[1], v[2], v[3], v[4], v[5], v[6], v[7] end
      if estPassif(nom) then
        L.passif = true
        if not nom:find("^%./%.") then L.nom = "./. " .. nom:gsub("^%-", "") end
        for _, k in ipairs({"vci", "vri", "vcf", "vrf"}) do if L[k] then L[k] = -math.abs(L[k]) end end
      end
      table.insert(rows, L)
    end
    return rows
  end

  local function grillesRL(rows, avecTot)
    local ini, fin, var = {}, {}, {}
    local ti, tf, tv = 0, 0, 0
    for _, L in ipairs(rows) do
      local function b(x) if x == nil then return "" end; return f(x) end   -- case non demandee : vide, comme le prof
      table.insert(ini, {L.nom, b(L.vci), b(L.vri), f(L.rli)})
      table.insert(fin, {L.nom, b(L.vcf), b(L.vrf), f(L.rlf)})
      table.insert(var, {L.nom, f(L.rli), f(L.rlf), fs(L.var)})
      ti = ti + (L.rli or 0); tf = tf + (L.rlf or 0); tv = tv + (L.var or 0)
    end
    if avecTot ~= false then
      table.insert(ini, {"Totaux", "", "", f(ti), gras = true, trait = true})
      table.insert(fin, {"Totaux", "", "", f(tf), gras = true, trait = true})
      table.insert(var, {"Totaux", f(ti), f(tf), fs(tv), gras = true, trait = true, fond = true})
    end
    GRILLE("Bilan initial", ini, {entetes = {"Comptes", "VC", "VR", "RL"}})
    GRILLE("Bilan final", fin, {entetes = {"Comptes", "VC", "VR", "RL"}})
    GRILLE("Variation des RL", var, {entetes = {"Comptes", "RL ini.", "RL fin.", "Var."}})
    return ti, tf, tv
  end

  local function manque(rows)
    for _, L in ipairs(rows) do
      for _, k in ipairs({"rli", "rlf", "var"}) do
        if L[k] == nil then A(L.nom .. " : " .. LIB[k] .. " inconnue (données insuffisantes).") end
      end
    end
  end

  ---------------------------------------------------------------- A2 tableau des RL -> benefice reel, FP reels
  local DEF_TAB = "Ducroire:15/10/?/400*5%/12/?/?;Titres:100/130/105/120;Stock@2/3:?/210/?/150/?/?/?;Installations:175/?/35/155/?/?/10"
  local CH_TAB = {{cle = "bn", lib = "bénéfice publié", defaut = "500"}, {cle = "fp", lib = "fonds propres publiés", defaut = "1500"}}
  local function rlTableau(lignes, params)
    local rows = lignesRL(lignes or DEF_TAB)
    local p = lireParams(params, CH_TAB)
    vider()
    T("Tableau des réserves latentes")
    G("Méthode : par compte, RL = valeur réelle − valeur comptable aux deux bilans, puis variation = RL finale − RL initiale. " ..
      "Les passifs (ducroire, provisions) s'écrivent en négatif : un passif surévalué crée une RL. " ..
      "Bénéfice réel = bénéfice publié + variation des RL ; fonds propres réels = fonds propres publiés + RL du bilan final. " ..
      "Modèle : test 2025 ex. 7 (8 pts), 37.11 ; 37.7-37.9, 37.12, 37.13.")
    X("Saisie : Nom:VCi/VRi/VCf/VRf ou Nom:VCi/VRi/RLi/VCf/VRf/RLf/Var (« ? » = inconnue) ; « Stock@2/3 » = comptable aux 2/3 du réel.")
    T("Calculs ligne par ligne")
    for _, s in ipairs(propager(rows)) do X(s) end
    manque(rows)
    T("a) Tableau des RL")
    local ti, tf, tv = grillesRL(rows)
    if p.bn then
      T("b) Bénéfice réel")
      COMMUN.calc("Bénéfice réel", "bénéfice publié + variation des RL", f(p.bn) .. " + " .. fp(tv), f(p.bn + tv))
      G("Variation nette " .. fs(tv) .. " : " .. sens(tv) .. (tv > 0 and " → bénéfice dissimulé, le réel est plus grand que le publié."
        or (tv < 0 and " → la dissolution a gonflé le bénéfice publié." or ".")))
    end
    local rlfOk = true
    for _, L in ipairs(rows) do if L.rlf == nil then rlfOk = false end end
    if p.fp and not rlfOk then A("Fonds propres réels : il manque une RL finale, on ne peut pas les calculer (seule la variation est connue).") end
    if p.fp and rlfOk then
      T("c) Fonds propres réels")
      COMMUN.calc("FP réels", "FP publiés + RL du bilan final", f(p.fp) .. " + " .. f(tf), f(p.fp + tf))
    end
    A("Pièges : ducroire en négatif ; stock « aux 2/3 » → réel = comptable × 3/2 ; FP réels avec la RL FINALE, pas la variation.")
    montrer("Tableau des RL")
  end
  SOLVEURS.rlTableau = rlTableau

  ---------------------------------------------------------------- A11 tableau des fonds propres sur plusieurs exercices
  local DEF_FP = "2012:120/120/?/?/130/?/5;2013:125/?/?/?/?/20/?;2014:132/?/?/140/?/?/-5"
  local function fondsPropres(lignes)
    local rows = {}
    for _, l in ipairs(lireLignes(lignes or DEF_FP)) do
      local v = l.v
      table.insert(rows, {nom = l.nom, vci = v[1], vri = v[2], rli = v[3], vcf = v[4], vrf = v[5], rlf = v[6], var = v[7]})
    end
    vider()
    T("Tableau des fonds propres")
    G("Méthode : chaque ligne est un exercice ; RL = FP réels − FP comptables ; variation = RL finale − RL initiale. " ..
      "Le bilan final d'un exercice est le bilan initial du suivant (on recopie VC, VR et RL d'une ligne à l'autre). Modèle : 37.22.")
    X("Saisie : Année:VCi/VRi/RLi/VCf/VRf/RLf/Var, « ? » = case à compléter.")
    T("Calculs")
    for _, s in ipairs(propager(rows, true)) do X(s) end
    manque(rows)
    T("Tableau complété")
    grillesRL(rows, false)
    T("Bénéfices (pas d'augmentation de capital)")
    local lig = {}
    for _, L in ipairs(rows) do
      if L.vcf and L.vci and L.var then
        table.insert(lig, {L.nom, f(L.vcf - L.vci), fs(L.var), f(L.vcf - L.vci + L.var)})
      end
    end
    GRILLE("Bénéfice comptable et réel", lig, {entetes = {"Exercice", "BN compt.", "Var. RL", "BN réel"}})
    G("BN comptable = FP comptables finaux − initiaux (bénéfice entièrement viré aux réserves) ; BN réel = BN comptable + variation des RL.")
    montrer("Fonds propres (37.22)")
  end
  SOLVEURS.fondsPropres = fondsPropres

  ---------------------------------------------------------------- A1 resultat reel depuis un seul poste
  local CH_UN = {{cle = "reel", lib = "valeur réelle 31.12", defaut = "420"}, {cle = "bilan", lib = "valeur au bilan 31.12", defaut = "300"},
    {cle = "rli", lib = "RL au 01.01", defaut = "160"}, {cle = "res", lib = "résultat publié (perte < 0)", defaut = "-40"},
    {cle = "vise", lib = "résultat à publier (b, c)", defaut = "?"}}
  local function rlUnPoste(params)
    local p = lireParams(params, CH_UN)
    local rlf = p.reel - p.bilan
    local var = rlf - p.rli
    local reel = p.res + var
    vider()
    T("Résultat réel depuis un seul poste")
    G("Méthode : le résultat publié est corrigé de la VARIATION de la RL, pas de la RL. Une diminution (dissolution) a gonflé le résultat publié : " ..
      "on la retranche ; une augmentation (constitution) l'a diminué : on l'ajoute. Modèle : test 2025 ex. 1 (3 pts), 37.28.")
    COMMUN.calc("RL au 31.12", "valeur réelle − valeur au bilan", f(p.reel) .. " − " .. f(p.bilan), f(rlf))
    COMMUN.calc("Variation", "RL 31.12 − RL 01.01", f(rlf) .. " − " .. f(p.rli), fs(var) .. " (" .. sens(var) .. ")")
    local nomVar = var < 0 and "Diminution de la RL" or "Augmentation de la RL"
    GRILLE("Réserve latente", {{"RL au 01.01", f(p.rli)}, {"RL au 31.12", f(rlf)}, {nomVar, fs(var), gras = true, trait = true}})
    local lp = p.res < 0 and "Perte nette comptable" or "Bénéfice net comptable"
    local lr = reel < 0 and "Perte nette réelle" or "Bénéfice net réel"
    GRILLE("Résultat", {{lp, f(p.res)}, {(var < 0 and "./. " or "+ ") .. nomVar, f(var)}, {lr, f(reel), gras = true, trait = true, fond = true}})
    R(lr .. " = " .. f(p.res) .. " " .. (var < 0 and "− " or "+ ") .. f(math.abs(var)) .. " = " .. f(reel), "", "")
    if p.vise then
      T("b) Publier un résultat de " .. f(p.vise))
      local dv = reel - p.vise
      local rl2 = p.rli + dv
      COMMUN.calc("Variation nécessaire", "résultat réel − résultat visé", f(reel) .. " − " .. fp(p.vise), fs(dv))
      X(dv < 0 and ("Il faut dissoudre " .. f(-dv) .. " de RL au lieu de " .. f(math.max(-var, 0)) .. ".")
        or ("Il faut constituer " .. f(dv) .. " de RL."))
      COMMUN.calc("RL au 31.12", "RL 01.01 + variation", f(p.rli) .. " + " .. fp(dv), f(rl2))
      T("c) Valeur du stock au bilan")
      COMMUN.calc("Stock au bilan", "valeur réelle − RL 31.12", f(p.reel) .. " − " .. f(rl2), f(p.reel - rl2))
      if rl2 < 0 then A("RL négative : il faudrait surévaluer le stock, interdit (valeur plafond, CO 960c).") end
    end
    montrer("Résultat réel (1 poste)")
  end
  SOLVEURS.rlUnPoste = rlUnPoste

  ---------------------------------------------------------------- A3 ducroire
  local CH_DUC = {{cle = "cli", lib = "créances clients 01.01", defaut = "140000"}, {cle = "clf", lib = "créances clients 31.12", defaut = "160000"},
    {cle = "afci", lib = "créances AFC 01.01", defaut = "4000"}, {cle = "afcf", lib = "créances AFC 31.12", defaut = "6000"},
    {cle = "taux", lib = "taux du ducroire", defaut = "5%"}, {cle = "rri", lib = "risque réel 01.01 (montant ou %)", defaut = "5000"},
    {cle = "rrf", lib = "risque réel 31.12", defaut = "3000"}, {cle = "res", lib = "résultat publié", defaut = "-2000"},
    {cle = "vci", lib = "ducroire comptable 01.01 si donné", defaut = "?"}, {cle = "vcf", lib = "ducroire comptable 31.12 si donné", defaut = "?"}}
  local function ducroire(params)
    local p = lireParams(params, CH_DUC)
    vider()
    T("Ducroire : RL et résultat réel")
    G("Méthode : provision comptable = taux × créances COMMERCIALES (créances clients, sans les créances AFC). " ..
      "Le ducroire est un passif : RL = provision comptable − risque réel (provision surévaluée). Variation, puis résultat réel. Modèle : 37.21.")
    local vci, vcf = p.vci, p.vcf
    if not vci then vci = p.taux * p.cli; COMMUN.calc("Provision 01.01", "taux × créances clients", pc(p.taux) .. " × " .. f(p.cli), f(vci)) end
    if not vcf then vcf = p.taux * p.clf; COMMUN.calc("Provision 31.12", "taux × créances clients", pc(p.taux) .. " × " .. f(p.clf), f(vcf)) end
    local rri, rrf = p.rri, p.rrf
    if rri and rri < 1 then local t = rri; rri = t * p.cli; X("Risque réel 01.01 = " .. pc(t) .. " × " .. f(p.cli) .. " = " .. f(rri)) end
    if rrf and rrf < 1 then local t = rrf; rrf = t * p.clf; X("Risque réel 31.12 = " .. pc(t) .. " × " .. f(p.clf) .. " = " .. f(rrf)) end
    local rli, rlf = vci - rri, vcf - rrf
    local var = rlf - rli
    COMMUN.calc("RL 01.01", "provision comptable − risque réel", f(vci) .. " − " .. f(rri), f(rli))
    COMMUN.calc("RL 31.12", "provision comptable − risque réel", f(vcf) .. " − " .. f(rrf), f(rlf))
    GRILLE("Ducroire", {{"Provisions au 01.01", f(vci), f(rri), f(rli)}, {"Provisions au 31.12", f(vcf), f(rrf), f(rlf)},
      {"Variation", "", "", fs(var), gras = true, trait = true}}, {entetes = {"", "Compt.", "Risque", "RL"}})
    local reel = p.res + var
    COMMUN.calc("Résultat réel", "résultat publié + variation des RL", f(p.res) .. " + " .. fp(var), f(reel))
    local q = reel >= 0 and "un bénéfice" or "une perte"
    X("Le résultat réel de l'exercice est " .. q .. " de " .. f(math.abs(reel)) .. ". En faisant " .. (var >= 0 and "augmenter" or "diminuer") ..
      " les réserves latentes de " .. f(math.abs(var)) .. ", on a " .. (var >= 0 and "dissimulé " or "ajouté au résultat publié ") .. f(math.abs(var)) ..
      " de bénéfice" .. (p.res < 0 and (" et provoqué une perte comptable de " .. f(-p.res)) or "") .. ".")
    if (p.afci or 0) ~= 0 or (p.afcf or 0) ~= 0 then A("Piège : les créances AFC (" .. f(p.afci) .. " ; " .. f(p.afcf) .. ") n'entrent pas dans le calcul du ducroire.") end
    G("Usage : 5 % pour les créances suisses, 10 % pour les étrangères (37 p.41).")
    montrer("Ducroire")
  end
  SOLVEURS.ducroire = ducroire

  ---------------------------------------------------------------- A4 stock a une fraction, PRAMV reel et comptable
  local CH_SF = {{cle = "vci", lib = "stock comptable 01.01", defaut = "400000"}, {cle = "vri", lib = "stock réel 01.01", defaut = "?"},
    {cle = "vcf", lib = "stock comptable 31.12", defaut = "?"}, {cle = "vrf", lib = "stock réel 31.12", defaut = "750000"},
    {cle = "fr", lib = "comptable / réel", defaut = "2/3"}, {cle = "ca", lib = "chiffre d'affaires", defaut = "2000000"},
    {cle = "achats", lib = "achats", defaut = "1600000"}, {cle = "autres", lib = "autres charges", defaut = "380000"}}
  local function stockFraction(params)
    local p = lireParams(params, CH_SF)
    local L = {nom = "Stock", vci = p.vci, vri = p.vri, vcf = p.vcf, vrf = p.vrf, frac = p.fr, fracTxt = string.format("%.4g", p.fr)}
    if math.abs(p.fr - 2 / 3) < 1e-6 then L.fracTxt = "2/3" end
    vider()
    T("Stock à une fraction de sa valeur réelle")
    G("Méthode : comptable = " .. L.fracTxt .. " du réel ⇒ RL = réel − comptable" .. (L.fracTxt == "2/3" and " = comptable ÷ 2 = réel ÷ 3" or "") ..
      ". Puis variations de stock réelle et comptable, PRAMV = achats − augmentation (+ diminution) du stock, bénéfice brut et net. Modèle : 37.14.")
    for _, s in ipairs(propager({L})) do X(s) end
    T("a) Réserves latentes")
    GRILLE("RL", {{"RL au 01.01", f(L.rli)}, {"RL au 31.12", f(L.rlf)}, {L.var >= 0 and "Augmentation des RL" or "Diminution des RL", fs(L.var), gras = true, trait = true}})
    T("b) PRAMV réel et comptable")
    local dr, dc = L.vrf - L.vri, L.vcf - L.vci
    COMMUN.calc("Variation de stock réelle", "stock réel 31.12 − stock réel 01.01", f(L.vrf) .. " − " .. f(L.vri), fs(dr))
    COMMUN.calc("Variation de stock comptable", "stock compt. 31.12 − stock compt. 01.01", f(L.vcf) .. " − " .. f(L.vci), fs(dc))
    local pr, pc = p.achats - dr, p.achats - dc
    COMMUN.calc("PRAMV réel", "achats − augmentation de stock", f(p.achats) .. " − " .. fp(dr), f(pr))
    COMMUN.calc("PRAMV comptable", "achats − augmentation de stock", f(p.achats) .. " − " .. fp(dc), f(pc))
    T("c) Bénéfice réel et comptable")
    local br, bc = p.ca - pr, p.ca - pc
    local nr, nc = br - p.autres, bc - p.autres
    GRILLE("Résultats", {{"Stock 01.01", f(L.vri), f(L.vci)}, {"Stock 31.12", f(L.vrf), f(L.vcf)}, {"Variation de stock", fs(dr), fs(dc)},
      {"PRAMV", f(pr), f(pc), trait = true}, {"Bénéfice brut", f(br), f(bc)}, {"./. Autres charges", f(-p.autres), f(-p.autres)},
      {"Bénéfice net", f(nr), f(nc), gras = true, trait = true, fond = true}}, {entetes = {"", "Réel", "Comptable"}})
    R("BN réel = " .. f(nr) .. " ; BN comptable = " .. f(nc), "", "")
    G("Contrôle : BN réel − BN comptable = " .. f(nr - nc) .. " = variation des RL (" .. fs(L.var) .. ").")
    montrer("Stock à une fraction")
  end
  SOLVEURS.stockFraction = stockFraction

  ---------------------------------------------------------------- A5 stock externe / interne -> PRAMV et MB
  local CH_EI = {{cle = "sie", lib = "stock initial externe", defaut = "60000"}, {cle = "sii", lib = "stock initial interne", defaut = "90000"},
    {cle = "sfe", lib = "stock final externe", defaut = "40000"}, {cle = "sfi", lib = "stock final interne", defaut = "60000"},
    {cle = "prama", lib = "PRAMA", defaut = "400000"}, {cle = "can", lib = "CAN", defaut = "600000"}}
  local function stockExtInt(params)
    local p = lireParams(params, CH_EI)
    vider()
    T("Stock : valeurs externes et internes")
    G("Méthode : PRAMV = PRAMA ± variation de stock (+ diminution, − augmentation), une fois avec les valeurs externes, une fois avec les internes. " ..
      "RL = valeur interne − valeur externe. MB = CAN − PRAMV. Modèle : 37.10.")
    local ve = p.sfe - p.sie
    T("a) PRAMV externe")
    COMMUN.calc("Variation de stock externe", "SF − SI", f(p.sfe) .. " − " .. f(p.sie), fs(ve) .. (ve < 0 and " (diminution)" or " (augmentation)"))
    local pe = p.prama - ve
    COMMUN.calc("PRAMV externe", "PRAMA ± variation de stock", f(p.prama) .. (ve < 0 and " + " or " − ") .. f(math.abs(ve)), f(pe))
    T("b) RL constituées ou dissoutes")
    local rli, rlf = p.sii - p.sie, p.sfi - p.sfe
    COMMUN.calc("RL au 1.1", "interne − externe", f(p.sii) .. " − " .. f(p.sie), f(rli))
    COMMUN.calc("RL au 31.12", "interne − externe", f(p.sfi) .. " − " .. f(p.sfe), f(rlf))
    COMMUN.calc((rlf - rli) < 0 and "Diminution de la RL" or "Augmentation de la RL", "RL 31.12 − RL 1.1", f(rlf) .. " − " .. f(rli), fs(rlf - rli))
    T("c) PRAMV interne")
    local vi = p.sfi - p.sii
    COMMUN.calc("Variation de stock réelle", "SF − SI", f(p.sfi) .. " − " .. f(p.sii), fs(vi))
    local pi = p.prama - vi
    COMMUN.calc("PRAMV interne", "PRAMA ± variation de stock", f(p.prama) .. (vi < 0 and " + " or " − ") .. f(math.abs(vi)), f(pi))
    T("d) e) Marges brutes")
    COMMUN.calc("MB externe", "CAN − PRAMV externe", f(p.can) .. " − " .. f(pe), f(p.can - pe))
    COMMUN.calc("MB interne", "CAN − PRAMV interne", f(p.can) .. " − " .. f(pi), f(p.can - pi))
    GRILLE("Synthèse", {{"Stock initial", f(p.sie), f(p.sii)}, {"Stock final", f(p.sfe), f(p.sfi)}, {"PRAMV", f(pe), f(pi)},
      {"Marge brute", f(p.can - pe), f(p.can - pi), gras = true, trait = true}}, {entetes = {"", "Externe", "Interne"}})
    local d = rlf - rli
    if d < 0 then X("La marge brute interne est moins importante que la marge brute comptable. Cette dernière a été améliorée par une diminution de la réserve latente sur stock.")
    elseif d > 0 then X("La marge brute interne est plus importante que la marge brute comptable : l'augmentation de la réserve latente sur stock a diminué la marge publiée.")
    else X("Pas de variation de RL : les deux marges sont égales.") end
    montrer("Stock externe / interne")
  end
  SOLVEURS.stockExtInt = stockExtInt

  ---------------------------------------------------------------- A6 valeur maximale du stock (CO 960c)
  local DEF_SM = "Ours en peluche:10/12/11;Marmotte en béton:5/24/32"
  local function stockMax(lignes)
    local ls = lireLignes(lignes or DEF_SM)
    vider()
    T("Valeur maximale du stock (CO 960c)")
    G("Méthode : ARTICLE PAR ARTICLE, évaluation = min(PRA unitaire ; valeur vénale nette), puis total = quantité × évaluation, puis somme. " ..
      "Modèle : test 2025 ex. 4, 37.20 ; 37 p.37.")
    X("Saisie : Article:quantité/PRA unitaire/valeur vénale nette.")
    local lig, tot = {}, 0
    for _, l in ipairs(ls) do
      local q, pra, vvn = l.v[1], l.v[2], l.v[3]
      local ev = math.min(pra, vvn)
      local t = q * ev
      tot = tot + t
      X(l.nom .. " : min(" .. f(pra) .. " ; " .. f(vvn) .. ") = " .. f(ev) .. (vvn < pra and " (VVN plus basse)" or " (PRA)") .. " ; " .. f(q) .. " × " .. f(ev) .. " = " .. f(t))
      table.insert(lig, {l.nom, f(q), f(ev), f(t)})
    end
    table.insert(lig, {"Total", "", "", f(tot), gras = true, trait = true, fond = true})
    GRILLE("Évaluation du stock", lig, {entetes = {"Marchandises", "Qté", "Éval.", "Total"}})
    R("Valeur maximale au bilan = " .. f(tot), "", "")
    A("Piège : jamais min(total PRA ; total VVN) ; article par article (CO 960c al. 1).")
    montrer("Stock CO 960c")
  end
  SOLVEURS.stockMax = stockMax

  ---------------------------------------------------------------- A7 titres cotes / non cotes
  local DEF_TI = "Taupe S.A.:10/50/70/c;Renard S.A.:20/30/25/c;Corbeau S.A.:15/200/250/n;Elephant S.A.:5/100/80/n"
  local function titres(lignes)
    local ls = lireLignes(lignes or DEF_TI)
    vider()
    T("Titres cotés et non cotés")
    G("Méthode : cotés (marché actif) → cours du 31.12, même au-dessus du prix d'achat (CO 960b) ; " ..
      "non cotés → min(prix d'achat ; valeur au 31.12) : jamais au-dessus du coût d'acquisition (CO 960a), baisse obligatoire (CO 960 al. 3). " ..
      "Modèle : test 2025 ex. 9 (3 pts), 37.19 ; 37 p.35.")
    X("Saisie : Titre:nombre/prix d'achat/cours ou valeur 31.12/c (coté) ou n (non coté).")
    local gc, gn, tc, tn = {}, {}, 0, 0
    for _, l in ipairs(ls) do
      local nb, ach, c31 = l.v[1], l.v[2], l.v[3]
      local cote = (l.brut[4] or "c"):lower():sub(1, 1) ~= "n"
      local pu, art
      if cote then pu = c31; art = c31 > ach and "CO 960b" or "CO 960 al. 3"
      else pu = math.min(ach, c31); art = c31 >= ach and "CO 960a" or "CO 960 al. 3" end
      local v = nb * pu
      X(l.nom .. (cote and " (coté)" or " (non coté)") .. " : prix retenu " .. f(pu) .. " (" .. art .. ") ; " .. f(nb) .. " × " .. f(pu) .. " = " .. f(v))
      if cote then table.insert(gc, {l.nom, f(nb), f(pu), f(v)}); tc = tc + v
      else table.insert(gn, {l.nom, f(nb), f(pu), f(v)}); tn = tn + v end
    end
    if #gc > 0 then table.insert(gc, {"Total", "", "", f(tc), gras = true, trait = true}); GRILLE("Cotés", gc, {entetes = {"Titres", "Nombre", "Prix u.", "Valeur"}}) end
    if #gn > 0 then table.insert(gn, {"Total", "", "", f(tn), gras = true, trait = true}); GRILLE("Non cotés", gn, {entetes = {"Titres", "Nombre", "Prix u.", "Valeur"}}) end
    R("Valeur maximale au bilan = " .. f(tc) .. " + " .. f(tn) .. " = " .. f(tc + tn), "", "")
    G("Corrigé 37.19 : le prof cite « CO 960 al. 3 et CO 960b » pour les deux tableaux.")
    A("Pièges : coté en baisse → le cours s'impose ; non coté en hausse → on reste au prix d'achat.")
    montrer("Titres")
  end
  SOLVEURS.titres = titres

  ---------------------------------------------------------------- A8 cout d'acquisition, amortissement prudent
  local CH_CA = {{cle = "prix", lib = "prix d'achat", defaut = "800000"}, {cle = "transport", lib = "frais de transport", defaut = "10000"},
    {cle = "install", lib = "frais d'installation", defaut = "40000"}, {cle = "remise", lib = "remise (% du prix ou montant)", defaut = "10%"},
    {cle = "autres", lib = "autres frais", defaut = "0"}, {cle = "duree", lib = "durée de vie la plus courte (ans)", defaut = "4"}}
  local function coutAcq(params)
    local p = lireParams(params, CH_CA)
    local rem = p.remise
    local remTxt = f(rem)
    if rem and rem < 1 then remTxt = pc(rem) .. " × " .. f(p.prix); rem = rem * p.prix end
    local total = p.prix + p.transport + p.install + (p.autres or 0) - rem
    vider()
    T("Coût d'acquisition (1re inscription)")
    G("Méthode : prix d'achat + frais d'acquisition (transport, installation) − remise = prix de revient d'achat, valeur maximale lors de la première inscription (CO 960a al. 1). Modèle : 37.18.")
    COMMUN.calc("Remise", "taux × prix d'achat", remTxt, f(rem))
    local lig = {{"Prix d'achat", f(p.prix)}, {"Frais de transport", f(p.transport)}, {"Frais d'installation", f(p.install)}}
    if (p.autres or 0) ~= 0 then table.insert(lig, {"Autres frais", f(p.autres)}) end
    table.insert(lig, {"./. Remise", f(-rem)})
    table.insert(lig, {"Prix de revient d'achat", f(total), gras = true, trait = true, fond = true})
    GRILLE("Prix maximum", lig)
    R("Valeur maximale = " .. f(total) .. " (CO 960a al. 1)", "", "")
    if p.duree and p.duree > 0 then
      T("Amortissement prudent (37.17)")
      local tc = 1 / p.duree
      COMMUN.calc("Taux constant", "100 % ÷ durée la plus courte", "100 % ÷ " .. f(p.duree), pc(tc))
      COMMUN.calc("Taux dégressif", "2 × taux constant", "2 × " .. pc(tc), pc(2 * tc))
      X("1re année : constant " .. f(total * tc) .. " ; dégressif " .. f(total * 2 * tc) .. ".")
      G("Base légale : CO 960 al. 2 (prudence) et CO 960a al. 3.")
      A("Le manuel (37 p.41) et le corrigé 37.17 divergent sur le dégressif : suivre le corrigé (25 % constant ou 50 % dégressif pour 4-5 ans).")
    end
    G("Terrain : jamais au-dessus du coût d'acquisition (37.16).")
    montrer("Coût d'acquisition")
  end
  SOLVEURS.coutAcq = coutAcq

  ---------------------------------------------------------------- A9 reprise fiscale sur stock
  local CH_RF = {{cle = "rli", lib = "RL au 01.01", defaut = "45200"}, {cle = "vc", lib = "stock au bilan 31.12", defaut = "77800"},
    {cle = "vr", lib = "stock au PRA (réel) 31.12", defaut = "136500"}, {cle = "part", lib = "part admise par le fisc", defaut = "1/3"},
    {cle = "bn", lib = "bénéfice comptable", defaut = "57900"}}
  local function repriseStock(params)
    local p = lireParams(params, CH_RF)
    local rlf = p.vr - p.vc
    local var = rlf - p.rli
    vider()
    T("RL fiscale, reprise, bénéfice fiscal")
    G("Méthode : a) tableau des RL à une ligne et bénéfice réel ; b) RL admise = part fiscale × valeur RÉELLE ; reprise = RL comptabilisée − RL admise ; " ..
      "bénéfice fiscal = comptable + reprise ; c) valeur réelle pour que tout soit admis = RL ÷ part. Modèle : 37.24 ; 37 p.41.")
    T("a) Bénéfice réel")
    COMMUN.calc("RL 31.12", "valeur réelle − valeur comptable", f(p.vr) .. " − " .. f(p.vc), f(rlf))
    COMMUN.calc("Variation", "RL 31.12 − RL 01.01", f(rlf) .. " − " .. f(p.rli), fs(var))
    GRILLE("Stock", {{"RL", f(p.rli), f(rlf), fs(var)}}, {entetes = {"", "RL ini.", "RL fin.", "Var."}})
    GRILLE("Bénéfice réel", {{"Bénéfice comptable", f(p.bn)}, {"+ Variation RL", fs(var)}, {"Bénéfice réel", f(p.bn + var), gras = true, trait = true}})
    T("b) Bénéfice fiscal")
    local adm = p.part * p.vr
    COMMUN.calc("RL fiscale autorisée", "part × valeur réelle", string.format("%.4g", p.part) .. " × " .. f(p.vr), f(adm))
    local rep = rlf - adm
    if rep > 0 then
      COMMUN.calc("Reprise fiscale", "RL comptabilisée − RL autorisée", f(rlf) .. " − " .. f(adm), f(rep))
      GRILLE("Bénéfice fiscal", {{"Bénéfice comptable", f(p.bn)}, {"+ Reprise sur stock", f(rep)}, {"Bénéfice fiscal", f(p.bn + rep), gras = true, trait = true}})
    else
      X("RL comptabilisée " .. f(rlf) .. " ≤ RL autorisée " .. f(adm) .. " : pas de reprise, bénéfice fiscal = " .. f(p.bn) .. ".")
    end
    T("c) Valeur réelle admissible")
    COMMUN.calc("Stock réel admissible", "RL comptabilisée ÷ part", f(rlf) .. " ÷ " .. string.format("%.4g", p.part), f(rlf / p.part))
    A("Piège : 33 1/3 % de la valeur RÉELLE (PRA), pas de la valeur au bilan.")
    montrer("Reprise fiscale")
  end
  SOLVEURS.repriseStock = repriseStock

  ---------------------------------------------------------------- reprises fiscales sur plusieurs postes (37.26, 37.25 a, 37.27 b)
  local DEF_RP = "Provisions:7000/5600;Amortissements:120000/90000;RL stock:58500/58500"
  local CH_RP = {{cle = "bn", lib = "bénéfice comptable", defaut = "60000"}, {cle = "min", lib = "1 = bénéfice fiscal minimal", defaut = "0"}}
  local function reprises(lignes, params)
    local ls = lireLignes(lignes or DEF_RP)
    local p = lireParams(params, CH_RP)
    vider()
    T("Reprises fiscales, bénéfice fiscal")
    G("Méthode : par poste, montant comptabilisé (provision, amortissement, RL) − montant admis par le fisc. Excédent → reprise ajoutée au bénéfice ; " ..
      "en dessous → pas de reprise (37.27 b). Avec min=1 (« bénéfice fiscal minimal », 37.25 a), la marge encore admise se déduit. Modèle : 37.26.")
    X("Saisie : Poste:comptabilisé/admis.")
    local lig = {{"Bénéfice comptable", f(p.bn)}}
    local tot = p.bn
    for _, l in ipairs(ls) do
      local c, a = l.v[1], l.v[2]
      local d = c - a
      if d > 0 then
        X(l.nom .. " : reprise = " .. f(c) .. " − " .. f(a) .. " = " .. f(d))
        table.insert(lig, {"+ Rep. " .. l.nom, fs(d)}); tot = tot + d
      elseif d < 0 and (p.min or 0) ~= 0 then
        X(l.nom .. " : encore admis = " .. f(a) .. " − " .. f(c) .. " = " .. f(-d) .. " (déduit pour le minimum)")
        table.insert(lig, {"./. " .. l.nom, f(d)}); tot = tot + d
      else
        X(l.nom .. " : " .. f(c) .. " ≤ " .. f(a) .. " → pas de reprise")
        table.insert(lig, {"+ Rep. " .. l.nom, "0"})
      end
    end
    table.insert(lig, {(p.min or 0) ~= 0 and "Bénéfice fiscal min." or "Bénéfice fiscal", f(tot), gras = true, trait = true, fond = true})
    GRILLE("Bénéfice fiscal", lig)
    R("Bénéfice fiscal = " .. f(tot), "", "")
    montrer("Reprises fiscales")
  end
  SOLVEURS.reprises = reprises

  ---------------------------------------------------------------- A10 bilans sur plusieurs annees
  local DEF_PA = "Stock:749000/1070000/861000/1230000/1024000/1536000;Immobilisations:900000/900000/750000/800000/600000/700000;" ..
    "Ducroire:21000/18000/21000/20700/23500/23280;BN:598000/687000"
  local CH_PA = {{cle = "an", lib = "année de la 1re date", defaut = "2011"}}
  local function plusieursAnnees(lignes, params)
    local ls = lireLignes(lignes or DEF_PA)
    local p = lireParams(params, CH_PA)
    local postes, bn = {}, nil
    local nd = 0
    for _, l in ipairs(ls) do
      if l.nom:upper() == "BN" then bn = l.v
      else
        local P = {nom = l.nom, vc = {}, vr = {}, rl = {}}
        local pas_ = estPassif(l.nom)
        if pas_ and not l.nom:find("^%./%.") then P.nom = "./. " .. l.nom end
        for k = 1, math.floor(#l.v / 2) do
          local vc, vr = l.v[2 * k - 1], l.v[2 * k]
          if pas_ then vc, vr = -math.abs(vc), -math.abs(vr) end
          P.vc[k], P.vr[k], P.rl[k] = vc, vr, vr - vc
        end
        nd = math.max(nd, #P.rl)
        table.insert(postes, P)
      end
    end
    local an = p.an or 1
    vider()
    T("RL et bénéfice réel sur plusieurs années")
    G("Méthode : à chaque date et par poste, RL = valeur réelle − valeur comptable (stock : réel = min(PRA ; prix du jour) ; ducroire en négatif). " ..
      "Variation d'une année = RL 31.12 − RL de l'année précédente ; BN réel = BN comptable + variation totale. Modèle : 37.25 ; 37.27.")
    X("Saisie : Poste:VC/VR date 1/VC/VR date 2/… ; ligne BN:bénéfices comptables à partir de la 2e date.")
    for _, P in ipairs(postes) do
      for k = 1, #P.rl do X(P.nom .. " " .. (an + k - 1) .. " : RL = " .. f(P.vr[k]) .. " − " .. fp(P.vc[k]) .. " = " .. f(P.rl[k])) end
    end
    local recap = {}
    for k = 2, nd do
      local lig, ti, tf = {}, 0, 0
      for _, P in ipairs(postes) do
        if P.rl[k] and P.rl[k - 1] then
          table.insert(lig, {P.nom, f(P.rl[k - 1]), f(P.rl[k]), fs(P.rl[k] - P.rl[k - 1])})
          ti = ti + P.rl[k - 1]; tf = tf + P.rl[k]
        end
      end
      table.insert(lig, {"Totaux", f(ti), f(tf), fs(tf - ti), gras = true, trait = true})
      T("Exercice " .. (an + k - 1))
      GRILLE("RL " .. (an + k - 2) .. " → " .. (an + k - 1), lig, {entetes = {"Comptes", "RL ini.", "RL fin.", "Var."}})
      local b = bn and bn[k - 1]
      if b then
        COMMUN.calc("BN réel " .. (an + k - 1), "BN comptable + variation des RL", f(b) .. " + " .. fp(tf - ti), f(b + tf - ti))
        table.insert(recap, {tostring(an + k - 1), f(b), fs(tf - ti), f(b + tf - ti)})
      end
    end
    if #recap > 0 then GRILLE("Récapitulatif", recap, {entetes = {"Année", "BN compt.", "Var. RL", "BN réel"}}) end
    montrer("Plusieurs années")
  end
  SOLVEURS.plusieursAnnees = plusieursAnnees

  ---------------------------------------------------------------- A12 dissolution des RL : ecritures, CR externe / interne
  local CH_DI = {{cle = "rld", lib = "RL ducroire", defaut = "12"}, {cle = "rls", lib = "RL stock", defaut = "20"},
    {cle = "rli", lib = "RL immobilisation", defaut = "20"}, {cle = "ventes", lib = "produit des ventes", defaut = "1400"},
    {cle = "pertes", lib = "pertes sur créances", defaut = "16"}, {cle = "march", lib = "charges de marchandises", defaut = "840"},
    {cle = "pers", lib = "charges de personnel", defaut = "320"}, {cle = "amort", lib = "amortissements", defaut = "120"},
    {cle = "autres", lib = "autres charges", defaut = "0"}}
  local function dissolution(params)
    local p = lireParams(params, CH_DI)
    local d, s, i = p.rld or 0, p.rls or 0, p.rli or 0
    vider()
    T("Dissolution des RL : écritures, CR interne")
    G("Méthode : chaque RL dissoute ramène le poste à sa valeur réelle et corrige la charge qui l'avait créée : Ducroire / Pertes sur créances, " ..
      "Stock / Charges de marchandises, Immobilisation / Amortissements. Le bénéfice interne = bénéfice externe + somme des RL. Modèle : 37.5 ; 37.4-37.6.")
    T("a) Journal")
    local function ecr(deb, cre, lib, m)
      if m == 0 then return end
      if m > 0 then X(deb .. " à " .. cre .. " : " .. f(m) .. " (" .. lib .. ")")
      else X(cre .. " à " .. deb .. " : " .. f(-m) .. " (constitution, écriture inverse)") end
    end
    ecr("Ducroire", "Pertes sur créances", "diminution du Ducroire", d)
    ecr("Stock de marchandises", "Charges de marchandises", "augmentation du stock", s)
    ecr("Immobilisation (équipement)", "Amortissements", "augmentation de l'immobilisation", i)
    T("b) Compte de résultat externe / interne")
    local cane, cani = p.ventes - p.pertes, p.ventes - (p.pertes - d)
    local ext = cane - p.march - p.pers - p.amort - (p.autres or 0)
    local int = cani - (p.march - s) - p.pers - (p.amort - i) - (p.autres or 0)
    local lig = {{"Produit des ventes", f(p.ventes), f(p.ventes)}, {"./. Pertes s/créances", f(-p.pertes), f(-(p.pertes - d))},
      {"Produit net des ventes", f(cane), f(cani), trait = true}, {"./. Ch. marchandises", f(-p.march), f(-(p.march - s))},
      {"./. Ch. de personnel", f(-p.pers), f(-p.pers)}, {"./. Amortissements", f(-p.amort), f(-(p.amort - i))}}
    if (p.autres or 0) ~= 0 then table.insert(lig, {"./. Autres charges", f(-p.autres), f(-p.autres)}) end
    table.insert(lig, {"Bénéfice d'exploitation", f(ext), f(int), gras = true, trait = true, fond = true})
    GRILLE("CR", lig, {entetes = {"", "Externe", "Interne"}})
    COMMUN.calc("Bénéfice interne", "bénéfice externe + RL dissoutes", f(ext) .. " + " .. f(d + s + i), f(int))
    G("Bilan interne : ducroire − " .. f(d) .. ", stock + " .. f(s) .. ", immobilisation + " .. f(i) .. " ; total + " .. f(d + s + i) .. " = bénéfice + " .. f(d + s + i) .. ".")
    montrer("Dissolution des RL")
  end
  SOLVEURS.dissolution = dissolution

  ---------------------------------------------------------------- A13 theorie
  local function theorie()
    vider()
    T("Théorie des RL (37.1-37.3)")
    X("RL = valeur réelle − valeur comptable : actif sous-évalué ou passif surévalué. Créée AVANT la détermination du bénéfice : c'est une dissimulation de fonds propres.")
    X("Valeurs « plafonds » pour les actifs, « planchers » pour les passifs (37 p.3). Titres cotés : plafond = cours du jour du bilan (CO 960b).")
    X("Sous-évaluables : actifs estimés (créances via le ducroire, stocks, titres, immobilisations). Surévaluables : provisions, ducroire. " ..
      "Liquidités, dettes, capital et réserves : valeur nominale, pas de RL.")
    T("Vrai / faux (corrigé 37.3)")
    GRILLE("Affirmations", {{"Sous-évaluer un passif crée une RL", "F"}, {"Sous-évaluer un actif crée une RL", "V"},
      {"Réserve apparente : après le bénéfice", "V"}, {"RL : avant le bénéfice", "V"}, {"Dissolution = réévaluation d'actif", "V"},
      {"RL créée avec les FP", "F"}, {"RL = dissimulation de FP", "V"}}, {entetes = {"", "V/F"}})
    T("Catégories (37 p.40)")
    X("Forcées : découlent du CO 960a-e (pas de valeur de marché au bilan, sauf titres).")
    X("D'appréciation : prudence (CO 960) sans empêcher une appréciation fiable.")
    X("Arbitraires : injustifiées ; refusées par IFRS, US GAAP, Swiss GAAP RPC ; le CO laisse la porte ouverte (960a al. 4, 960e al. 4).")
    T("Effet sur le résultat")
    X("Constitution (augmentation) de RL : bénéfice publié < réel. Dissolution (diminution) : bénéfice publié > réel.")
    montrer("Théorie des RL")
  end
  SOLVEURS.theorieRL = theorie

  ---------------------------------------------------------------- menu
  local function viaLignes(titre, defaut, suite)
    return function() demander(titre, function(t) suite(t) end, defaut) end
  end
  table.insert(MENUS_COMPTA, {ordre = 37, titre = "Réserves latentes, évaluation (37)", items = {
    {"Tableau des RL → BN, FP réels", function()
      demander("Comptes (Nom:VCi/VRi/VCf/VRf ou 7 valeurs, ? = inconnue, Stock@2/3)", function(l)
        formu("Bénéfice et FP publiés", CH_TAB, function(t) rlTableau(l, t) end)
      end, DEF_TAB)
    end},
    {"Résultat réel (un poste)", function() formu("Un poste", CH_UN, rlUnPoste) end},
    {"Ducroire", function() formu("Ducroire", CH_DUC, ducroire) end},
    {"Stock à une fraction (PRAMV)", function() formu("Stock à une fraction", CH_SF, stockFraction) end},
    {"Stock externe / interne", function() formu("Stock ext./int.", CH_EI, stockExtInt) end},
    {"Valeur max. du stock (960c)", viaLignes("Articles (Nom:qté/PRA/VVN)", DEF_SM, stockMax)},
    {"Titres cotés / non cotés", viaLignes("Titres (Nom:nombre/achat/cours 31.12/c ou n)", DEF_TI, titres)},
    {"Coût d'acquisition, amort.", function() formu("Coût d'acquisition", CH_CA, coutAcq) end},
    {"Reprise fiscale (stock)", function() formu("Reprise fiscale", CH_RF, repriseStock) end},
    {"Reprises fiscales (postes)", function()
      demander("Postes (Nom:comptabilisé/admis)", function(l) formu("Bénéfice", CH_RP, function(t) reprises(l, t) end) end, DEF_RP)
    end},
    {"Plusieurs années", function()
      demander("Postes (Nom:VC/VR/VC/VR… ; BN:bénéfices)", function(l) formu("Années", CH_PA, function(t) plusieursAnnees(l, t) end) end, DEF_PA)
    end},
    {"Fonds propres sur 3 ans", viaLignes("Années (An:VCi/VRi/RLi/VCf/VRf/RLf/Var)", DEF_FP, fondsPropres)},
    {"Dissolution : écritures, CR", function() formu("Dissolution", CH_DI, dissolution) end},
    {"Théorie, V/F, catégories", theorie},
  }})
end
