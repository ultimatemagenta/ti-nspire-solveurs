-- 10_analyse.lua : identification de reels, outils d'analyse, tableau de signes, factorisation detaillee, analyse de fonction
-- (lignes 338-427, 453-550, 552-879 de lua/solveur.lua, decoupees le 11.11.2026 ; code inchange)
do   -- bloc : limite de 200 variables locales du script principal
------------------------------------------------------------------ module : identification (S7 ex.5)
local function sans_espace(s) return (s:gsub("%s", "")) end

local function norm(e)
  e = e:gsub("%f[%a]([abcdmkp])x", "%1*x"):gsub("%f[%a]([abcdmkp])%(", "%1*("):gsub("λx", "λ*x"):gsub("λ%(", "λ*(")
  return e
end

local function identifier(f, forme, inclus)
  f = norm(f); forme = norm(forme)
  if not inclus then vider(); T("Identification des réels") end
  local lettres = {}
  for _, l in ipairs({"a", "b", "c", "d"}) do
    if forme:find("%f[%a]" .. l .. "%f[%A]") or forme:find(l .. "x") or forme:find(l .. "%*") then table.insert(lettres, l) end
  end
  local inc = "{" .. table.concat(lettres, ",") .. "}"
  X("D'une part :")
  M("f(x) = ", f)
  X("D'autre part :")
  M("f(x) = ", forme)
  -- forme au meme denominateur
  local cd = cas1("comDenom(" .. forme .. ",x)")
  local nT, dT = cas1("getNum(" .. cd .. ")"), cas1("getDenom(" .. cd .. ")")
  local nF, dF = cas1("getNum(" .. f .. ")"), cas1("getDenom(" .. f .. ")")
  X("On met la forme au même dénominateur :")
  M("f(x) = ", "(" .. nT .. ")/(" .. dT .. ")")
  -- comparaison des numerateurs
  local k = cas1("(" .. dT .. ")/(" .. dF .. ")")
  local g, d
  if cas1("getDenom(" .. k .. ")") == "1" and not k:find("x") then
    g = cas1("expand((" .. nF .. ")*(" .. k .. "))"); d = cas1("expand(" .. nT .. ")")
    X("Même dénominateur des deux côtés, donc")
    X("on compare les numérateurs :")
  else
    g = cas1("expand((" .. nF .. ")*(" .. dT .. "))"); d = cas1("expand((" .. nT .. ")*(" .. dF .. "))")
    X("Produit en croix :")
  end
  M("", g .. "=" .. d)
  X("Par identification des coefficients")
  X("de chaque puissance de x :")
  local dg = tonumber(cas1("polyDegree(" .. g .. ",x)")) or 0
  local dd = tonumber(cas1("polyDegree(" .. d .. ",x)")) or 0
  local function coef(poly, deg, p)
    if p > deg then return "0" end
    return cas1("expand(polyCoeffs(" .. poly .. ",x)[" .. (deg - p + 1) .. "])")
  end
  local eqs = {}
  for p = math.max(dg, dd), 0, -1 do
    local cg, cdd = coef(g, dg, p), coef(d, dd, p)
    if not (cg == "0" and cdd == "0") then
      local nomp = p == 3 and "x³" or (p == 2 and "x²" or (p == 1 and "x" or (p == 0 and "1" or ("x^" .. p))))
      M(nomp .. " :  ", cdd .. "=" .. cg)
      table.insert(eqs, cdd .. "=" .. cg)
    end
  end
  local sol = cas1("solve(" .. table.concat(eqs, " and ") .. "," .. inc .. ")")
  if sol == "false" or sol:find("%?") then A("Système impossible : la forme ne convient pas."); if not inclus then montrer("Identification") end; return nil end
  R("Donc ", (sol:gsub(" and ", " ; ")))
  for _, l in ipairs(lettres) do
    local v = cas(l .. "|" .. sol)
    if v then memoriser(v) end
  end
  local fin = cas1("(" .. forme .. ")|" .. sol)
  local vals = {}
  for _, l in ipairs(lettres) do vals[l] = cas1(l .. "|" .. sol) end
  local joli = forme:gsub("%f[%a]([abcd])%f[%A]", function(l)
    local v = vals[l] or l
    if v:sub(1, 1) == "-" then return "(" .. v .. ")" end
    return v
  end)
  joli = joli:gsub("%(%((%-[^%)]*)%)", "(%1"):gsub("%+%((%-[^%)]*)%)", "%1"):gsub("%f[%d]1%*x", "x"):gsub("^%((%-[^%)]*)%)", "%1")
  R("f(x) = ", joli)
  local ok = cas1("comDenom((" .. f .. ")-(" .. fin .. "),x)")
  G("Contrôle : f(x) − forme = " .. ok .. (ok == "0" and "  ✓" or "  ✗"))
  if inclus then return joli end
  local qp = cas1("polyQuotient(getNum(" .. f .. "),getDenom(" .. f .. "),x)")
  local rp = cas1("polyRemainder(getNum(" .. f .. "),getDenom(" .. f .. "),x)")
  if rp ~= "0" and not qp:find("%?") then
    local dq = tonumber(cas1("polyDegree(" .. qp .. ",x)")) or 9
    if dq <= 1 then
      X("Le terme restant tend vers 0 en ±∞ :")
      M("", "(" .. rp .. ")/(" .. dF .. ")")
      R(dq == 0 and "Asymptote horizontale : y = " or "Asymptote oblique : y = ", qp, "  en ±∞")
    end
  end
  memoriser(fin)
  montrer("Identification")
end

------------------------------------------------------------------ outils d'analyse
local function racines(p)  -- racines reelles triees {s=exact, v=valeur}
  local z = cas1("zeros(" .. p .. ",x)")
  local out = {}
  for _, r in ipairs(liste(z)) do
    local v = nombre(r)
    if v then table.insert(out, {s = r, v = v}) end
  end
  table.sort(out, function(a, b) return a.v < b.v end)
  return out
end

local function ordre(p, r)  -- multiplicite de la racine r dans p
  local k = 1
  while k < 8 do
    if cas1("polyRemainder(" .. p .. ",(x-(" .. r .. "))^" .. (k + 1) .. ",x)") ~= "0" then return k end
    k = k + 1
  end
  return k
end

local function deg(p) return tonumber(cas1("polyDegree(" .. p .. ",x)")) or 0 end

local function facteurs(p)  -- factor(p) decoupe en {s=facteur, e=exposant} (+ constante)
  local f = cas1("factor(" .. p .. ")")
  local out = {}
  local function somme_niveau0(s)  -- + ou - au niveau 0 (hors signe initial) ?
    local prof = 0
    for i = 2, #s do
      local c = s:sub(i, i)
      if c == "(" then prof = prof + 1 elseif c == ")" then prof = prof - 1
      elseif (c == "+" or c == "-") and prof == 0 and s:sub(i - 1, i - 1) ~= "^" and s:sub(i - 1, i - 1) ~= "*" then return true end
    end
    return false
  end
  local morceaux = somme_niveau0(f) and {f} or decouper(f, "*")
  for _, morceau in ipairs(morceaux) do
    local base, ex = morceau, 1
    local pw = decouper(morceau, "^")
    if #pw == 2 then base = pw[1]; ex = tonumber(pw[2]) or 1 end
    base = base:gsub("^%((.*)%)$", "%1")
    if base:find("x") then table.insert(out, {s = base, e = ex}) else table.insert(out, {s = base, e = 1, cst = true}) end
  end
  return out, f
end

------------------------------------------------------------------ tableau de signes (element dessine)
-- tab = {var="x", pts={{s=,v=}}, lignes={{nom=, cells={...}}}} ; cells alternent intervalle/point
local function signe(v) if math.abs(v) < 1e-9 then return "0" end; return v > 0 and "+" or "−" end

local function tableauSignes(var, lignes, interdits, extra)
  -- lignes : {{nom=, expr=, zeros={{s,v}}}} ; la derniere est le resultat
  local pts = {}
  local function ajoute(r)
    for _, q in ipairs(pts) do if math.abs(q.v - r.v) < 1e-9 then return end end
    table.insert(pts, {s = r.s, v = r.v})
  end
  for _, l in ipairs(lignes) do for _, z in ipairs(l.zeros or {}) do ajoute(z) end end
  for _, z in ipairs(interdits or {}) do ajoute(z) end
  for _, z in ipairs(extra or {}) do ajoute(z) end
  table.sort(pts, function(a, b) return a.v < b.v end)
  local tests = {}
  if #pts == 0 then tests = {0} else
    table.insert(tests, pts[1].v - 1)
    for i = 1, #pts - 1 do table.insert(tests, (pts[i].v + pts[i + 1].v) / 2) end
    table.insert(tests, pts[#pts].v + 1)
  end
  local tab = {var = var, pts = pts, lignes = {}}
  local resultat = {}
  for li, l in ipairs(lignes) do
    local cells = {}
    for i, t in ipairs(tests) do
      local v = nombre("(" .. l.expr .. ")|x=" .. string.format("%.6f", t))
      table.insert(cells, v and signe(v) or "?")
      if li == #lignes then resultat[i] = cells[#cells] end
      if i <= #pts then
        local p = pts[i]
        local c = ""
        for _, z in ipairs(l.zeros or {}) do if math.abs(z.v - p.v) < 1e-9 then c = "0" end end
        if li == #lignes then
          for _, z in ipairs(interdits or {}) do if math.abs(z.v - p.v) < 1e-9 then c = "||" end end
        end
        table.insert(cells, c)
      end
    end
    table.insert(tab.lignes, {nom = l.nom, cells = cells})
  end
  table.insert(DOC, {k = "tab", tab = tab})
  return pts, resultat
end

------------------------------------------------------------------ graphe (element dessine)
local function coeffs(p)
  local l = liste(cas1("approx(polyCoeffs(" .. p .. ",x))"))
  local c = {}
  for _, s in ipairs(l) do table.insert(c, tonumber((s:gsub("ᴇ", "e"))) or 0) end
  return c
end


------------------------------------------------------------------ factorisation detaillee
local CANDIDATS = {"1", "-1", "2", "-2", "3", "-3", "1/2", "-1/2", "3/2", "-3/2", "4", "-4", "6", "-6", "1/3", "-1/3"}

local function factoriserDetail(p, nom)
  nom = nom or "P"
  local d = deg(p)
  if d <= 1 then
    if d == 1 then M("", nom .. "(x)=" .. p); end
    return
  end
  -- mise en evidence de x^k
  local k = 0
  while k < d and cas1("polyRemainder(" .. p .. ",x^" .. (k + 1) .. ",x)") == "0" do k = k + 1 end
  if k > 0 then
    local q = cas1("polyQuotient(" .. p .. ",x^" .. k .. ",x)")
    X("Mise en évidence de x" .. (k > 1 and ("^" .. k) or "") .. " :")
    M("", nom .. "(x)=x^" .. k .. "*(" .. q .. ")")
    factoriserDetail(q, "Q")
    return
  end
  if d == 2 then
    local c = liste(cas1("polyCoeffs(" .. p .. ",x)"))
    local a, b, cc = c[1], c[2], c[3]
    local D = cas1("(" .. b .. ")^2-4*(" .. a .. ")*(" .. cc .. ")")
    X("Trinôme du 2nd degré : Δ = b² − 4ac")
    M("Δ = ", "(" .. b .. ")^2-4*(" .. a .. ")*(" .. cc .. ")=" .. D)
    local vD = nombre(D) or 0
    if vD > 1e-12 then
      local r = racines(p)
      local x1, x2 = r[1] and r[1].s or "?", r[2] and r[2].s or "?"
      X("Δ > 0 : deux racines x = (−b ± √Δ)/(2a)")
      M("", "x_1=" .. x1); M("", "x_2=" .. x2)
    elseif math.abs(vD) <= 1e-12 then
      X("Δ = 0 : racine double x = −b/(2a)")
      M("", "x_0=" .. cas1("-(" .. b .. ")/(2*(" .. a .. "))"))
    else
      X("Δ < 0 : aucune racine réelle,")
      X("le trinôme garde le signe de a.")
    end
    return
  end
  -- racine evidente
  X("Racine évidente (essais " .. nom .. "(r)) :")
  local trouve = nil
  for _, r in ipairs(CANDIDATS) do
    local v = cas1("(" .. p .. ")|x=" .. r)
    M("", nom .. "(" .. r .. ")=" .. v)
    if v == "0" then trouve = r; break end
  end
  if not trouve then
    A("Pas de racine évidente : factorisation à la main non attendue.")
    return
  end
  local q = cas1("polyQuotient(" .. p .. ",x-(" .. trouve .. "),x)")
  X("Donc (" .. cas1("x-(" .. trouve .. ")") .. ") divise " .. nom .. " (car " .. nom .. "(" .. trouve .. ") = 0) :")
  X("division en potence ou identification")
  M("", nom .. "(x)=(" .. cas1("x-(" .. trouve .. ")") .. ")*(" .. q .. ")")
  factoriserDetail(q, "Q")
end

local function bilanFacto(p, nom)
  factoriserDetail(p, nom)
  local _, f = facteurs(p)
  R(nom .. "(x) = ", f)
  local rs = racines(p)
  for _, r in ipairs(rs) do G("racine " .. r.s .. "  : ordre " .. ordre(p, r.s)) end
  memoriser(f)
end

------------------------------------------------------------------ module : analyse de fonction (S7 ex.7-8)
local function analyse(f0)
  f0 = norm(f0)
  vider()
  local N = cas1("getNum(" .. f0 .. ")")   -- forme saisie (avant simplification ?) :
  local D = cas1("getDenom(" .. f0 .. ")")
  -- le CAS simplifie d'office : on reconstruit num/den tels que tapes
  local brut = decouper(f0, "/")
  if #brut == 2 then N = cas1("expand(" .. brut[1] .. ")"); D = cas1("expand(" .. brut[2] .. ")") end
  local fs = cas1("(" .. N .. ")/(" .. D .. ")")
  local Ns, Ds = cas1("getNum(" .. fs .. ")"), cas1("getDenom(" .. fs .. ")")
  T("a) Domaine de définition")
  G("Pourquoi : on ne peut pas diviser par 0. On interdit donc les zéros du dénominateur, sur la forme tapée (avant toute simplification).")
  M("f(x) = ", "(" .. N .. ")/(" .. D .. ")")
  X("On ne divise pas par 0 :")
  M("f existe ⇔ ", D .. "≠0")
  if deg(D) >= 2 then bilanFacto(D, "D") end
  local interdits = racines(D)
  local noms = {}
  for _, r in ipairs(interdits) do table.insert(noms, r.s); M("", "x≠" .. r.s, r.s:find("[^%d%-/]") and ("  ≈ " .. string.format("%.4g", r.v)) or "") end
  if #noms == 0 then R("D_f = ", "ℝ") else R("D_f = ℝ \\ ", "{" .. table.concat(noms, ",") .. "}") end
  memoriser(fs)

  T("b) Factorisation et simplification")
  G("Pourquoi : factoriser numérateur et dénominateur fait apparaître les facteurs communs. On les simplifie, mais les valeurs interdites restent interdites.")
  if deg(N) >= 2 then bilanFacto(N, "N") end
  local _, fN = facteurs(N); local _, fD = facteurs(D)
  M("f(x) = ", "(" .. fN .. ")/(" .. fD .. ")")
  if cas1("polyDegree(" .. Ds .. ",x)") ~= cas1("polyDegree(" .. D .. ",x)") then
    X("Facteur commun simplifié (x ∈ D_f) :")
    R("f(x) = ", "(" .. cas1("factor(" .. Ns .. ")") .. ")/(" .. cas1("factor(" .. Ds .. ")") .. ")")
    A("Les valeurs interdites restent interdites !")
  else G("Aucun facteur commun.") end

  T("c) Zéros et pôles (ordre)")
  G("Zéro : le numérateur s'annule. Pôle : le dénominateur s'annule. Ordre pair : f garde son signe en traversant ; ordre impair : f change de signe.")
  X("Sur la forme simplifiée : l'exposant")
  X("du facteur donne l'ordre.")
  local zs = racines(Ns)
  if #zs == 0 then X("Aucun zéro.") end
  for _, z in ipairs(zs) do R("zéro ", z.s, "  d'ordre " .. ordre(Ns, z.s)) end
  local ps = racines(Ds)
  for _, z in ipairs(ps) do R("pôle ", z.s, "  d'ordre " .. ordre(Ds, z.s)) end
  for _, r in ipairs(interdits) do
    local pole = false
    for _, q in ipairs(ps) do if math.abs(q.v - r.v) < 1e-9 then pole = true end end
    if not pole then A("x = " .. r.s .. " : interdite mais pas un pôle (trou)") end
  end

  T("d) Signe de f")
  G("Méthode : une ligne par facteur, puis la règle des signes. Double barre sous une valeur interdite, 0 sous un zéro.")
  local lignes = {}
  local fac = facteurs(Ns)
  local facd = facteurs(Ds)
  for _, fc in ipairs(fac) do
    local e = fc.s .. (fc.e > 1 and ("^" .. fc.e) or "")
    table.insert(lignes, {nom = e, expr = e, zeros = fc.cst and {} or racines(fc.s)})
  end
  for _, fc in ipairs(facd) do
    local e = fc.s .. (fc.e > 1 and ("^" .. fc.e) or "")
    table.insert(lignes, {nom = e, expr = e, zeros = fc.cst and {} or racines(fc.s)})
  end
  table.insert(lignes, {nom = "f(x)", expr = fs, zeros = zs})
  tableauSignes("x", lignes, interdits)

  T("e) Forme a + b/…  (identification)")
  G("Pourquoi : on sépare la partie qui reste (a) de la partie qui tend vers 0 quand x → ±∞. C'est elle qui donne l'asymptote et aide pour les variations.")
  local dN, dD = deg(Ns), deg(Ds)
  local forme
  if dD >= 1 and dN >= dD and dN <= dD + 1 then
    local q = dN == dD and "a" or "a*x+b"
    local lettres = dN == dD and {"b", "c", "d"} or {"c", "d"}
    local r
    if dD == 1 or cas1("polyRemainder(" .. Ns .. "," .. Ds .. ",x)"):find("x") == nil then r = lettres[1]
    else r = lettres[1] .. "*x+" .. lettres[2] end
    forme = q .. "+(" .. r .. ")/(" .. Ds .. ")"
    if not r:find("x") then forme = q .. "+" .. r .. "/(" .. Ds .. ")" end
    identifier(fs, forme, true)
  else
    G("deg num < deg dén : f est déjà « 0 + reste/dén ».")
  end

  T("f) Asymptotes")
  G("AV : droite x = pôle, là où f part vers ±∞. AH ou AO : ce qui reste de f quand x → ±∞ (le terme reste/dén. tend vers 0).")
  for _, p in ipairs(ps) do
    local function inf(v) if v == "∞" then return "+∞" end; return v end
    local g = inf(cas1("limit(" .. fs .. ",x," .. p.s .. ",-1)"))
    local d = inf(cas1("limit(" .. fs .. ",x," .. p.s .. ",1)"))
    R("AV : x = ", p.s, "")
    G("   à gauche : " .. g .. "   à droite : " .. d)
  end
  local qp = cas1("polyQuotient(" .. Ns .. "," .. Ds .. ",x)")
  local rp = cas1("polyRemainder(" .. Ns .. "," .. Ds .. ",x)")
  local dq = deg(qp)
  if dD >= 1 and dN <= dD + 1 then
    X("f = quotient + reste/dén, le reste/dén → 0 en ±∞")
    R(dq <= 0 and "AH : y = " or "AO : y = ", qp, "  en ±∞")
    if rp ~= "0" then
      local s1 = nombre("(" .. rp .. ")/(" .. Ds .. ")|x=1000")
      local s2 = nombre("(" .. rp .. ")/(" .. Ds .. ")|x=-1000")
      G("+∞ : courbe " .. ((s1 or 0) > 0 and "au-dessus" or "en dessous") .. " ; −∞ : courbe " .. ((s2 or 0) > 0 and "au-dessus" or "en dessous"))
    end
  elseif dN > dD + 1 then G("Ni AH ni AO (deg num ≥ deg dén + 2).") end

  T("g) Réciproque et image I_f")
  G("Méthode du prof en 3 étapes : 1) poser y = f(x) ; 2) isoler x ; 3) renommer la variable. Puis I_f = D_f⁻¹ : les y pour lesquels x existe.")
  X("1) On pose y = f(x) et 2) on isole x :")
  local eq = cas1("expand(y*(" .. Ds .. ")-(" .. Ns .. "))")
  M("", "y*(" .. Ds .. ")=" .. Ns)
  local degx = deg(eq:gsub("y", "(7/3)"))
  local A2 = cas1("polyCoeffs(" .. eq .. ",x)")
  local cs = liste(A2)
  if degx == 1 then
    local sol = cas1("solve(" .. eq .. "=0,x)")
    R("", sol)
    X("3) On renomme y en x :")
    local rhs = sol:match("^x=(.*)$")
    if rhs then R("f⁻¹(x) = ", (rhs:gsub("y", "x"))) end
    local cond = cs[1]
    X("x existe si le coefficient de x ≠ 0 :")
    M("", cond .. "≠0")
    local zy = racines(cond:gsub("y", "x"))
    local ny = {}
    for _, z in ipairs(zy) do table.insert(ny, z.s) end
    R("I_f = ℝ \\ ", "{" .. table.concat(ny, ",") .. "}")
  elseif degx == 2 then
    local a2, b2, c2 = cs[1], cs[2], cs[3]
    if cas1(b2) == "0" then
      local x2 = cas1("factor(-(" .. c2 .. ")/(" .. a2 .. "))")
      M("⇔ ", "x^2=" .. x2)
      M("⇔ x = ± ", "sqrt(" .. x2 .. ")")
      X("3) On renomme y en x :")
      R("f⁻¹(x) = ± ", "sqrt(" .. (x2:gsub("y", "x")) .. ")")
      G("Le ± : f⁻¹ n'est une fonction qu'après restriction à un intervalle I (voir i) : on garde + si I ⊂ [0 ; +∞[, − si I ⊂ ]−∞ ; 0].")
      X("I_f = D_f⁻¹ : l'expression sous la racine doit être ≥ 0 (et son dénominateur ≠ 0) :")
      local nn, dd = cas1("getNum(" .. x2 .. ")"), cas1("getDenom(" .. x2 .. ")")
      local nx, dx = nn:gsub("y", "x"), dd:gsub("y", "x")
      local l2 = {
        {nom = nn, expr = nx, zeros = racines(nx)},
        {nom = dd, expr = dx, zeros = deg(dx) >= 1 and racines(dx) or {}},
        {nom = "sous √", expr = "(" .. nx .. ")/(" .. dx .. ")", zeros = racines(nx)}}
      local pts, sg = tableauSignes("y", l2, deg(dx) >= 1 and racines(dx) or {})
      -- union des intervalles >= 0
      local parts = {}
      local zd = deg(dx) >= 1 and racines(dx) or {}
      local function interdit(v) for _, z in ipairs(zd) do if math.abs(z.v - v) < 1e-9 then return true end end return false end
      for i = 1, #sg do
        if sg[i] == "+" then
          local g = i == 1 and "]-∞" or ((interdit(pts[i - 1].v) and "]" or "[") .. pts[i - 1].s)
          local d = i == #sg and "+∞[" or (pts[i].s .. (interdit(pts[i].v) and "[" or "]"))
          table.insert(parts, g .. " ; " .. d)
        end
      end
      R("I_f = ", "", table.concat(parts, " ∪ "))
    else
      local Dl = cas1("factor((" .. b2 .. ")^2-4*(" .. a2 .. ")*(" .. c2 .. "))")
      X("Équation du 2nd degré en x : Δ(y) ≥ 0")
      M("Δ(y) = ", Dl)
      local dxs = Dl:gsub("y", "x")
      local pts, sg = tableauSignes("y", {{nom = "Δ(y)", expr = dxs, zeros = racines(dxs)}}, {})
      local parts = {}
      for i = 1, #sg do
        if sg[i] == "+" then
          local g = i == 1 and "]-∞" or ("[" .. pts[i - 1].s)
          local d = i == #sg and "+∞[" or (pts[i].s .. "]")
          table.insert(parts, g .. " ; " .. d)
        end
      end
      R("I_f = ", "", table.concat(parts, " ∪ "))
      G("(vérifier à part le cas coefficient de x² nul : " .. a2 .. " = 0)")
    end
  else
    G("Degré " .. degx .. " en x : pas de réciproque algébrique attendue.")
  end

  T("h) Variations (contrôle par f')")
  G("Au test (avant le chapitre des dérivées) : justifie les variations par le graphe ou la forme a+b/… ; ici f' sert de contrôle.")
  do
    local qd = cas1("polyQuotient(" .. Ns .. "," .. Ds .. ",x)")
    local rd = cas1("polyRemainder(" .. Ns .. "," .. Ds .. ",x)")
    local c = liste(cas1("polyCoeffs(" .. Ds .. ",x)"))
    if deg(Ds) == 2 and c[2] == "0" and not rd:find("x") and rd ~= "0" then
      local al, bb = nombre(c[1]) or 1, nombre(rd) or 1
      X("Raisonnement du prof (forme a + b/(αx² + β)) :")
      X("sur [0 ; +∞[, x² est croissante, donc αx² + β est " .. (al > 0 and "croissante" or "décroissante") .. " (α = " .. c[1] .. ") ;")
      X("l'inverse 1/(αx² + β) varie en sens contraire sur chaque intervalle où il est défini : il est " .. (al > 0 and "décroissant" or "croissant") .. " ;")
      X("b = " .. rd .. (bb > 0 and " > 0 conserve" or " < 0 inverse") .. " ce sens : f est " .. (((al > 0) == (bb > 0)) and "décroissante" or "croissante") .. " sur chaque intervalle de [0 ; +∞[ ∩ D_f.")
      X("f est paire : sur ]−∞ ; 0], le sens est inversé (symétrie par rapport à Oy).")
    end
  end
  local fp = cas1("factor(comDenom(derivative(" .. fs .. ",x)))")
  M("f'(x) = ", fp)
  local fpn = cas1("getNum(" .. fp .. ")")
  local crit = deg(fpn) >= 1 and racines(fpn) or {}
  local extra = {}
  for _, c in ipairs(crit) do
    local bon = true
    for _, r in ipairs(interdits) do if math.abs(r.v - c.v) < 1e-9 then bon = false end end
    if bon then table.insert(extra, c) end
  end
  local pts, sg = tableauSignes("x", {{nom = "f'(x)", expr = fp, zeros = extra}}, interdits)
  for i, c in ipairs(pts) do
    local isint = false
    for _, r in ipairs(interdits) do if math.abs(r.v - c.v) < 1e-9 then isint = true end end
    if not isint then
      local val = cas1("(" .. fs .. ")|x=" .. c.s)
      if sg[i] == "+" and sg[i + 1] == "−" then R("max local en x = " .. c.s .. " : ", "f=" .. val)
      elseif sg[i] == "−" and sg[i + 1] == "+" then R("min local en x = " .. c.s .. " : ", "f=" .. val) end
    end
  end
  G("lim −∞ : " .. cas1("limit(" .. fs .. ",x,-∞)") .. "   lim +∞ : " .. cas1("limit(" .. fs .. ",x,∞)"))

  T("i) Bijection f : I → J")
  local boites = {}
  local function val(sv) if sv == "+∞" then return 1e9 elseif sv == "-∞" or sv == "−∞" then return -1e9 end; return nombre(sv) or 0 end
  X("f est bijective sur un intervalle où elle est")
  X("strictement monotone ; J = f(I) se lit aux bornes.")
  local function inf(v) if v == "∞" then return "+∞" end; return v end
  for i = 1, #sg do
    if sg[i] == "+" or sg[i] == "−" then
      local ga, dr = pts[i - 1], pts[i]
      local gx = ga and ga.s or "-∞"
      local dx = dr and dr.s or "+∞"
      local function estInterdit(p)
        if not p then return true end
        for _, r in ipairs(interdits) do if math.abs(r.v - p.v) < 1e-9 then return true end end
        return false
      end
      local gf = ga and inf(cas1("limit(" .. fs .. ",x," .. ga.s .. ",1)")) or inf(cas1("limit(" .. fs .. ",x,-∞)"))
      local df = dr and inf(cas1("limit(" .. fs .. ",x," .. dr.s .. ",-1)")) or inf(cas1("limit(" .. fs .. ",x,∞)"))
      local gc_, dc_ = not estInterdit(ga), not estInterdit(dr)
      local I = (gc_ and "[" or "]") .. gx .. " ; " .. dx .. (dc_ and "]" or "[")
      local J
      if sg[i] == "+" then J = (gc_ and "[" or "]") .. gf .. " ; " .. df .. (dc_ and "]" or "[")
      else J = (dc_ and "[" or "]") .. df .. " ; " .. gf .. (gc_ and "]" or "[") end
      R("I = " .. I .. "  →  J = " .. J, "", sg[i] == "+" and "  (croissante)" or "  (décroissante)")
      local ya, yb = val(gf), val(df)
      table.insert(boites, {x1 = ga and ga.v or -1e9, x2 = dr and dr.v or 1e9, y1 = math.min(ya, yb), y2 = math.max(ya, yb), n = #boites + 1})
    end
  end

  local G0 = {k = "graphe", num = coeffs(Ns), den = coeffs(Ds),
    poles = ps, interdits = interdits, zeros = zs, crit = extra,
    asym = (dD >= 1 and dN <= dD + 1) and coeffs(qp) or nil, f = fs}
  if #boites > 0 then
    X("Chaque cadre de couleur = un couple I × J possible :")
    local Gb = {}
    for k2, v2 in pairs(G0) do Gb[k2] = v2 end
    Gb.boites = boites
    table.insert(DOC, Gb)
  end
  T("j) Graphe")
  G("Graphe en 3 étapes : asymptotes (pointillés), quelques points, lissage.")
  table.insert(DOC, G0)
  memoriser(fs)
  montrer("Analyse de f")
end

M1.sans_espace = sans_espace; M1.norm = norm; M1.identifier = identifier; M1.racines = racines; M1.ordre = ordre; M1.deg = deg
M1.facteurs = facteurs; M1.signe = signe; M1.tableauSignes = tableauSignes; M1.coeffs = coeffs; M1.CANDIDATS = CANDIDATS; M1.factoriserDetail = factoriserDetail
M1.bilanFacto = bilanFacto; M1.analyse = analyse
end
