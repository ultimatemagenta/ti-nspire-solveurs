-- 20_algebre.lua : outils des series 1 a 3 : division, simplification, inequations, parametre, changement de variable, equations, signe
-- (lignes 880-1236 de lua/solveur.lua, decoupees le 11.11.2026 ; code inchange)
do   -- bloc : limite de 200 variables locales du script principal
local racines, deg, facteurs, tableauSignes, factoriserDetail = M1.racines, M1.deg, M1.facteurs, M1.tableauSignes, M1.factoriserDetail
local EXT = {}
------------------------------------------------------------------ outils des series 1 a 3
local function versX(e, v) if v == "x" then return e end; return (e:gsub("%f[%a]" .. v .. "%f[%A]", "x")) end
local function depuisX(e, v) if v == "x" then return e end; return (e:gsub("%f[%a]x%f[%A]", v)) end

local function variable(e)
  for _, v in ipairs({"x", "u", "t", "y", "z", "h", "s", "a"}) do if e:find("%f[%a]" .. v .. "%f[%A]") then return v end end
  return "x"
end

local function parametreDe(e, v)
  for _, p in ipairs({"m", "λ", "k", "a", "p", "b"}) do
    if p ~= v and e:find(p, 1, true) and (p == "λ" or e:find("%f[%a]" .. p .. "%f[%A]")) then return p end
  end
  return nil
end

local function cotes(eq)  -- "g=d" -> g, d
  local g, d = eq:match("^(.-)=(.*)$")
  if not g then return eq, "0" end
  return g, d
end

local function ensemble(l)  -- liste de chaines -> "{a ; b}"
  if #l == 0 then return "∅" end
  return "{" .. table.concat(l, " ; ") .. "}"
end

local function intervalles(pts, sg, garder, fermes, interdits)
  -- garder : {"+"} ou {"−"} ; fermes : fonction(v) bornes incluses ; interdits : fonction(v)
  local parts = {}
  local n = #pts
  local function ok(sgn) for _, g in ipairs(garder) do if g == sgn then return true end end return false end
  local i = 1
  while i <= n + 1 do
    if ok(sg[i]) then
      local j = i
      while j <= n and ok(sg[j + 1]) and fermes(pts[j].v) and not interdits(pts[j].v) do j = j + 1 end
      local g = i == 1 and "]−∞" or ((fermes(pts[i - 1].v) and not interdits(pts[i - 1].v)) and "[" or "]") .. pts[i - 1].s
      local d = j == n + 1 and "+∞[" or (pts[j].s .. ((fermes(pts[j].v) and not interdits(pts[j].v)) and "]" or "["))
      table.insert(parts, g .. " ; " .. d)
      i = j + 1
    else i = i + 1 end
  end
  for k = 1, n do  -- zero isole garde par ≤ / ≥
    if fermes(pts[k].v) and not interdits(pts[k].v) and not ok(sg[k]) and not ok(sg[k + 1]) then
      table.insert(parts, "{" .. pts[k].s .. "}")
    end
  end
  if #parts == 0 then return "∅" end
  return table.concat(parts, " ∪ ")
end

------------------------------------------------------------------ division en potence
local function division(A, B, v)
  v = v or variable(A .. B)
  A, B = versX(cas1("expand(" .. A .. ")"), v), versX(cas1("expand(" .. B .. ")"), v)
  A, B = cas1("expand(" .. A .. ")"), cas1("expand(" .. B .. ")")
  vider(); T("Division en potence")
  G("Méthode : on divise le terme de plus haut degré du reste par celui du diviseur, on multiplie, on soustrait, et on recommence tant que deg(reste) ≥ deg(diviseur).")
  M("A(x) = ", A); M("B(x) = ", B)
  local reste, Q = A, "0"
  local dB = deg(B)
  local lB = liste(cas1("polyCoeffs(" .. B .. ",x)"))[1]
  local n = 0
  while reste ~= "0" and deg(reste) >= dB and n < 10 do
    n = n + 1
    local lr = liste(cas1("polyCoeffs(" .. reste .. ",x)"))[1]
    local t = cas1("(" .. lr .. ")/(" .. lB .. ")*x^" .. (deg(reste) - dB))
    local prod = cas1("expand((" .. t .. ")*(" .. B .. "))")
    local nouv = cas1("expand((" .. reste .. ")-(" .. prod .. "))")
    X("Étape " .. n .. " :")
    M("", "(" .. cas1("(" .. lr .. ")*x^" .. deg(reste)) .. ")/(" .. cas1("(" .. lB .. ")*x^" .. dB) .. ")=" .. t)
    M("", "(" .. t .. ")*(" .. B .. ")=" .. prod)
    M("reste : ", "(" .. reste .. ")-(" .. prod .. ")=" .. nouv)
    Q = cas1("expand(" .. Q .. "+" .. t .. ")")
    reste = nouv
  end
  R("Quotient Q(x) = ", depuisX(Q, v))
  R("Reste R(x) = ", depuisX(reste, v))
  X("Donc A = B·Q + R :")
  M("", depuisX(A, v) .. "=(" .. depuisX(B, v) .. ")*(" .. depuisX(Q, v) .. ")+" .. depuisX(reste, v))
  if reste == "0" then G("Reste nul : B divise A.") end
  memoriser(depuisX(Q, v))
  montrer("Division")
end

------------------------------------------------------------------ simplification de fractions (S1 ex.2-3)
local function simplifier(e)
  vider(); T("Simplification")
  G("Méthode : factoriser numérateur et dénominateur, poser les conditions (chaque facteur du dénominateur ≠ 0) AVANT de simplifier, puis simplifier les facteurs communs.")
  M("", e)
  -- denominateurs tels que tapes (pour les conditions)
  local dens = {}
  for d in e:gmatch("/%s*(%b())") do table.insert(dens, d:sub(2, -2)) end
  for d in e:gmatch("/%s*([%w%^]+)") do if d:find("%a") then table.insert(dens, d) end end
  local morceaux = decouper(e, "/")
  local N, D
  if #morceaux == 2 and not decouper(morceaux[1], "+")[2] then
    N, D = morceaux[1]:gsub("^%((.*)%)$", "%1"), morceaux[2]:gsub("^%((.*)%)$", "%1")
    X("On factorise numérateur et dénominateur :")
    M("", "(" .. cas1("factor(" .. N .. ")") .. ")/(" .. cas1("factor(" .. D .. ")") .. ")")
  else
    X("On met au même dénominateur puis on factorise :")
    local c = cas1("comDenom(" .. e .. ")")
    M("", "(" .. cas1("factor(getNum(" .. c .. "))") .. ")/(" .. cas1("factor(getDenom(" .. c .. "))") .. ")")
  end
  X("Conditions d'existence (dénominateurs ≠ 0) :")
  local vus = {}
  for _, d in ipairs(dens) do
    local fd = cas1("factor(" .. d .. ")")
    for _, m in ipairs(decouper(fd, "*")) do
      local b = m:gsub("%^%d+$", ""):gsub("^%((.*)%)$", "%1")
      if b:find("%a") and not vus[b] then vus[b] = true; M("", b .. "≠0") end
    end
  end
  local r = cas1("factor(" .. e .. ")")
  X("On simplifie les facteurs communs :")
  R("= ", r)
  G("(valable sous les conditions ci-dessus)")
  memoriser(r)
  montrer("Simplification")
end

------------------------------------------------------------------ inequations et valeur absolue (S2 ex.5)
local OPS = {">=", "<=", "≥", "≤", ">", "<"}

local function inequation(s)
  s = s:gsub("≥", ">="):gsub("≤", "<=")
  -- |...| -> abs(...)
  local n = 0
  s = s:gsub("|", function() n = n + 1; return n % 2 == 1 and "abs(" or ")" end)
  local op, g, d
  for _, o in ipairs({">=", "<=", ">", "<"}) do
    local i = s:find(o, 1, true)
    if i then op = o; g = s:sub(1, i - 1); d = s:sub(i + #o); break end
  end
  if not op then vider(); A("Il faut un signe <, ≤, > ou ≥."); montrer("Inéquation"); return end
  local v = variable(s)
  g, d = versX(g, v), versX(d, v)
  vider(); T("Inéquation")
  M("", depuisX(g, v) .. op .. depuisX(d, v))
  local strict = (op == ">" or op == "<")
  -- valeur absolue |x - a| op r : methode de la distance
  local inner = g:match("^%s*abs%((.*)%)%s*$")
  if inner and deg(inner) == 1 and not d:find("x") then
    local coef = liste(cas1("polyCoeffs(" .. inner .. ",x)"))
    local a = cas1("-(" .. coef[2] .. ")/(" .. coef[1] .. ")")
    local r = cas1("(" .. d .. ")/abs(" .. coef[1] .. ")")
    G("Méthode du prof : |x − a| est la distance entre x et a sur la droite réelle.")
    if coef[1] ~= "1" then M("⇔ ", "abs(x-(" .. a .. "))" .. op .. r) end
    local rv = nombre(r) or 0
    X("a = " .. a .. ", distance r = " .. r)
    local res
    if rv < 0 or (rv == 0 and op == "<") then
      res = (op == "<" or op == "<=") and "∅" or "ℝ"
      if rv < 0 then G("Une distance n'est jamais négative.") end
      if rv == 0 and op == ">=" then res = "ℝ" end
    else
      local m1, m2 = cas1(a .. "-(" .. r .. ")"), cas1(a .. "+(" .. r .. ")")
      if op == "<" then res = "]" .. m1 .. " ; " .. m2 .. "["
      elseif op == "<=" then res = "[" .. m1 .. " ; " .. m2 .. "]"
      elseif op == ">" then res = "]−∞ ; " .. m1 .. "[ ∪ ]" .. m2 .. " ; +∞["
      else res = "]−∞ ; " .. m1 .. "] ∪ [" .. m2 .. " ; +∞[" end
      X((op:sub(1, 1) == "<") and "x est à une distance de a inférieure à r :" or "x est à une distance de a supérieure à r :")
    end
    R("S = ", "", res)
    G("Contrôle CAS : " .. cas1("solve(" .. g .. op .. d .. ",x)"))
    montrer("Inéquation"); return
  end
  if g:find("abs") or d:find("abs") then
    EXT.abs(g, d, op, v)
    montrer("Inéquation"); return
  end
  G("Méthode : tout passer à gauche, même dénominateur, factoriser, tableau de signes. On ne multiplie jamais par une expression de signe inconnu.")
  R("S = ", "", EXT.rat(g, d, op, v))
  G("Crochets : fermés aux zéros si ≤ ou ≥ ; toujours ouverts aux valeurs interdites.")
  montrer("Inéquation")
end

------------------------------------------------------------------ equation a parametre (S2 ex.1 k-n)
local function parametre(eq, v, p)
  local g, d = cotes(eq)
  local E = cas1("expand((" .. versX(g, v) .. ")-(" .. versX(d, v) .. "))")
  -- coefficients en x
  local c = liste(cas1("polyCoeffs(" .. E .. ",x)"))
  local A, B, C
  if #c == 3 then A, B, C = c[1], c[2], c[3]
  elseif #c == 2 then A, B, C = "0", c[1], c[2] else A, B, C = "0", "0", c[1] or "0" end
  vider(); T("Équation à paramètre " .. p)
  M("", depuisX(E, v) .. "=0")
  G("Méthode : identifier a, b, c (fonctions de " .. p .. "), traiter d'abord a = 0 (l'équation n'est plus du 2nd degré : oubli pénalisé), puis Δ selon " .. p .. ".")
  M("a = ", A); M("b = ", B); M("c = ", C)
  local Pp = function(e) return versX(e, p) end  -- parametre -> x pour les outils
  T("1) Cas a = 0")
  if A == "0" then X("a = 0 pour tout " .. p .. " : équation du 1er degré.")
  else
    local za = racines(Pp(A))
    if #za == 0 then X("a ne s'annule jamais.") end
    for _, z in ipairs(za) do
      local eqz = cas1("(" .. E .. ")|" .. p .. "=" .. z.s)
      M(p .. " = " .. z.s .. " :  ", depuisX(eqz, v) .. "=0")
      local sol = cas1("solve(" .. eqz .. "=0,x)")
      if sol == "false" then R("", "", "impossible : aucune solution")
      elseif sol == "true" then R("", "", "tout " .. v .. " est solution")
      else R("", depuisX(sol, v)) end
    end
  end
  T("2) Cas a ≠ 0 : discriminant")
  local Dl = cas1("factor((" .. B .. ")^2-4*(" .. A .. ")*(" .. C .. "))")
  M("Δ = b² − 4ac = ", Dl)
  if Dl:find(p, 1, true) then
    local zd = racines(Pp(Dl))
    local za = A ~= "0" and racines(Pp(A)) or {}
    tableauSignes(p, {{nom = "Δ", expr = Pp(Dl), zeros = zd}}, za)
    X("Δ > 0 : deux solutions ; Δ = 0 : une solution double ; Δ < 0 : aucune solution (pour les " .. p .. " où a ≠ 0).")
    for _, z in ipairs(zd) do
      local x0 = cas1("(-(" .. B .. ")/(2*(" .. A .. ")))|" .. p .. "=" .. z.s)
      R(p .. " = " .. z.s .. " : Δ = 0,  ", v .. "=" .. depuisX(x0, v))
    end
  else
    local dv = nombre(Dl) or 0
    X("Δ = " .. Dl .. (dv > 0 and " > 0 : toujours deux solutions." or (dv == 0 and " : solution double." or " < 0 : aucune solution.")))
  end
  T("3) Solutions (a ≠ 0, Δ ≥ 0)")
  M(v .. " = ", "(-(" .. depuisX(B, v) .. ")±sqrt(" .. Dl .. "))/(2*(" .. depuisX(A, v) .. "))")
  local s1 = cas1("factor((-(" .. B .. ")+sqrt(" .. Dl .. "))/(2*(" .. A .. ")))")
  local s2 = cas1("factor((-(" .. B .. ")-sqrt(" .. Dl .. "))/(2*(" .. A .. ")))")
  R(v .. "₁ = ", s1); R(v .. "₂ = ", s2)
  G("Contrôle CAS : " .. depuisX(cas1("solve(" .. E .. "=0,x)"), v))
  montrer("Paramètre")
end

------------------------------------------------------------------ changement de variable (S2 ex.3, S3 ex.2 h-l)
local function changement(eq, sub, v)
  local g, d = cotes(eq)
  local E = cas1("expand((" .. versX(g, v) .. ")-(" .. versX(d, v) .. "))")
  sub = versX(sub:gsub("^%s*[XT]%s*=%s*", ""), v)
  vider(); T("Changement de variable")
  M("", depuisX(E, v) .. "=0")
  G("Pourquoi : l'équation devient du 2nd degré en X. On résout en X, puis on revient à " .. v .. " (étape souvent oubliée), en respectant les conditions sur X.")
  M("On pose X = ", depuisX(sub, v))
  local cond = nil
  if sub:find("x%^2") or sub:find("x%^4") or sub:find("sqrt") or sub:find("√") then cond = "X ≥ 0" end
  if sub:find("^1/") then cond = "X ≠ 0" end
  if sub:find("e%^") then cond = "X > 0" end
  if cond then G("Condition : " .. cond .. " (car X = " .. depuisX(sub, v) .. ").") end
  local brut = cas1("solve(z=" .. sub .. ",x)"):gsub(" or ", ","):gsub("x=", "")
  local xs = liste("{" .. brut .. "}")
  local xX = xs[#xs] or "z"
  local EX = cas1("expand((" .. E .. ")|x=" .. xX .. ")")
  if EX:find("x") or EX:find("√") or EX:find("sqrt") then
    A("La substitution ne transforme pas l'équation en polynôme en X.")
    montrer("Changement"); return
  end
  M("⇔ ", (EX:gsub("z", "X")) .. "=0")
  G("Équation du 2nd degré en X : on la résout (Δ ou factorisation).")
  local zX = racines((EX:gsub("z", "x")))
  local sol = {}
  for _, z in ipairs(zX) do
    local bon = true
    if cond == "X ≥ 0" and z.v < 0 then bon = false end
    if cond == "X ≠ 0" and math.abs(z.v) < 1e-12 then bon = false end
    if cond == "X > 0" and z.v <= 0 then bon = false end
    if not bon then A("X = " .. z.s .. " rejetée (" .. cond .. ")")
    else
      local r = cas1("solve(" .. sub .. "=" .. z.s .. ",x)")
      M("X = " .. z.s .. " :  ", depuisX(sub, v) .. "=" .. z.s)
      R("⇔ ", depuisX(r, v))
      for _, t in ipairs(liste("{" .. r:gsub(" or ", ","):gsub("x=", "") .. "}")) do
        if t ~= "false" and t ~= "" then table.insert(sol, t) end
      end
    end
  end
  R("S = ", "", ensemble(sol))
  G("Contrôle CAS : " .. depuisX(cas1("solve(" .. E .. "=0,x)"), v))
  montrer("Changement")
end

------------------------------------------------------------------ equation generale (S2 ex.1-2, S3 ex.2)
local function equation(eq)
  if eq:find("sqrt") or eq:find("√") then EXT.irr(eq); return end
  if eq:find("ln%(") or eq:find("log%(") then EXT.log(eq); return end
  local v = variable(eq)
  local p = parametreDe(eq, v)
  if p then parametre(eq, v, p); return end
  local g, d = cotes(eq)
  local E0 = cas1("(" .. versX(g, v) .. ")-(" .. versX(d, v) .. ")")
  local E = cas1("comDenom(" .. E0 .. ",x)")
  local N, D = cas1("getNum(" .. E .. ")"), cas1("getDenom(" .. E .. ")")
  vider(); T("Équation")
  M("", eq)
  local interdits = {}
  if deg(D) >= 1 then
    G("Équation avec fractions : conditions d'existence d'abord (dénominateurs ≠ 0), puis un quotient est nul ⇔ numérateur nul.")
    interdits = racines(D)
    for _, r in ipairs(interdits) do M("", v .. "≠" .. r.s) end
  end
  X("On ramène tout à gauche" .. (deg(D) >= 1 and " et au même dénominateur" or "") .. " :")
  M("", depuisX(cas1("expand(" .. N .. ")"), v) .. "=0")
  local Nx = cas1("expand(" .. N .. ")")
  local dn = deg(Nx)
  -- puissances multiples de k -> changement de variable
  local c = liste(cas1("polyCoeffs(" .. Nx .. ",x)"))
  local k = 0
  for i, ci in ipairs(c) do
    local e = dn - (i - 1)
    if ci ~= "0" and e > 0 then
      local function pgcd(a, b) while b ~= 0 do a, b = b, a % b end; return a end
      k = pgcd(k, e)
    end
  end
  if dn >= 4 and k >= 2 and dn / k == 2 then
    G("Les puissances de " .. v .. " sont " .. dn .. " et " .. k .. " : on pose X = " .. v .. "^" .. k .. " (équation bicarrée).")
    changement(depuisX(Nx, v) .. "=0", v .. "^" .. k, v)
    return
  end
  if dn == 1 then
    R("", depuisX(cas1("solve(" .. Nx .. "=0,x)"), v))
  else
    factoriserDetail(Nx, "P")
    R("Factorisé : ", depuisX(cas1("factor(" .. Nx .. ")"), v), "=0")
    G("Un produit est nul ⇔ un des facteurs est nul.")
  end
  local zs = dn >= 1 and racines(Nx) or {}
  local sol = {}
  for _, z in ipairs(zs) do
    local rej = false
    for _, r in ipairs(interdits) do if math.abs(r.v - z.v) < 1e-9 then rej = true end end
    if rej then A(v .. " = " .. z.s .. " rejetée (valeur interdite)") else table.insert(sol, z.s) end
  end
  R("S = ", "", ensemble(sol))
  G("Contrôle CAS : " .. depuisX(cas1("solve(" .. E0 .. "=0,x)"), v))
  memoriser(ensemble(sol))
  montrer("Équation")
end

------------------------------------------------------------------ signe d'un polynome (S3 ex.3)
local function signePoly(pz)
  local v = variable(pz)
  local P0 = cas1("expand(" .. versX(pz, v) .. ")")
  vider(); T("Factorisation et signe")
  M("P = ", depuisX(P0, v))
  factoriserDetail(P0, "P")
  local fac, f = facteurs(P0)
  R("P = ", depuisX(f, v))
  local lignes = {}
  for _, fc in ipairs(fac) do
    local e = fc.s .. (fc.e > 1 and ("^" .. fc.e) or "")
    table.insert(lignes, {nom = depuisX(e, v), expr = e, zeros = fc.cst and {} or racines(fc.s)})
  end
  table.insert(lignes, {nom = "P", expr = P0, zeros = racines(P0)})
  tableauSignes(v, lignes, {})
  G("Un facteur au carré (ordre pair) ne change pas de signe ; un trinôme sans racine a le signe de son coefficient dominant.")
  montrer("Signe")
end

M1.EXT = EXT; M1.versX = versX; M1.depuisX = depuisX; M1.variable = variable; M1.parametreDe = parametreDe; M1.cotes = cotes
M1.ensemble = ensemble; M1.intervalles = intervalles; M1.division = division; M1.simplifier = simplifier; M1.OPS = OPS; M1.inequation = inequation
M1.parametre = parametre; M1.changement = changement; M1.equation = equation; M1.signePoly = signePoly
end
