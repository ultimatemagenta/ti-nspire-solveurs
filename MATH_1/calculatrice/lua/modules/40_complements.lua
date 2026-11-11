-- 40_complements.lua : complements series 1 a 7 : intervalles, domaine, bijection, parite, composition, calcul litteral, bilinearite, systemes
-- (lignes 1473-1859 de lua/solveur.lua, decoupees le 11.11.2026 ; code inchange)
do   -- bloc : limite de 200 variables locales du script principal
local norm, racines, deg, facteurs, tableauSignes, depuisX, cotes, ensemble, intervalles, vec = M1.norm, M1.racines, M1.deg, M1.facteurs, M1.tableauSignes, M1.depuisX, M1.cotes, M1.ensemble, M1.intervalles, M1.vec
------------------------------------------------------------------ complements (couverture series 1 a 7)

-- resultat logique du CAS -> intervalles  ("x≥4 or -2<x and x≤0" -> "]-2 ; 0] ∪ [4 ; +∞[")
local function substX(e, par) return (e:gsub("%f[%a]x%f[%A]", "(" .. par .. ")")) end
local OPSL = {"≤", "≥", "≠", "<=", ">=", "<", ">", "="}
local function atome(a, v)
  a = a:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^%((.*)%)$", "%1")
  local best, bo
  for _, o in ipairs(OPSL) do
    local i = a:find(o, 1, true)
    if i and (not best or i < best or (i == best and #o > #bo)) then best, bo = i, o end
  end
  if not best then return nil end
  local g, d = a:sub(1, best - 1), a:sub(best + #bo)
  local o = bo
  if o == "<=" then o = "≤" elseif o == ">=" then o = "≥" end
  return g, o, d
end

local function enIntervalles(sol, v)
  v = v or "x"
  if sol == "true" then return "ℝ" end
  if sol == "false" then return "∅" end
  local parts = {}
  for _, terme in ipairs(decouper((sol:gsub(" or ", "|")), "|")) do
    local lo, hi, flo, fhi, egal, diff = "−∞", "+∞", false, false, nil, nil
    terme = terme:gsub("^%s+", "")
    local atomes = {}
    for _, at in ipairs(decouper((terme:gsub(" and ", "&")), "&")) do
      local a1, o1, rest = atome(at, v)
      if a1 then
        local a2, o2, b2 = atome(rest, v)
        if a2 then table.insert(atomes, a1 .. o1 .. a2); table.insert(atomes, a2 .. o2 .. b2)
        else table.insert(atomes, at) end
      else table.insert(atomes, at) end
    end
    for _, at in ipairs(atomes) do
      local g, o, d = atome(at, v)
      if not g then return sol end
      local gs, ds = (g:gsub("%s", "")), (d:gsub("%s", ""))
      if gs == v then
        if o == "=" then egal = ds elseif o == "≠" then diff = ds
        elseif o == "≥" or o == ">" then lo = ds; flo = (o == "≥")
        else hi = ds; fhi = (o == "≤") end
      elseif ds == v then
        if o == "=" then egal = gs elseif o == "≠" then diff = gs
        elseif o == "≤" or o == "<" then lo = gs; flo = (o == "≤")
        else hi = gs; fhi = (o == "≥") end
      else return sol end
    end
    if lo == "-∞" then lo = "−∞" end
    if hi == "∞" then hi = "+∞" end
    if egal then table.insert(parts, "{" .. egal .. "}")
    elseif diff then table.insert(parts, "ℝ \\ {" .. diff .. "}")
    else table.insert(parts, ((flo and lo ~= "−∞") and "[" or "]") .. lo .. " ; " .. hi .. ((fhi and hi ~= "+∞") and "]" or "[")) end
  end
  return table.concat(parts, " ∪ ")
end

-- inequation rationnelle g op d : tableau de signes, renvoie la solution (texte)
local function ineqRat(g, d, op, v)
  local strict = (op == ">" or op == "<")
  local E = cas1("comDenom((" .. g .. ")-(" .. d .. "),x)")
  local N, D = cas1("getNum(" .. E .. ")"), cas1("getDenom(" .. E .. ")")
  M("⇔ ", "(" .. cas1("factor(" .. N .. ")") .. ")/(" .. cas1("factor(" .. D .. ")") .. ")" .. op .. "0")
  local interdits = deg(D) >= 1 and racines(D) or {}
  local lignes = {}
  for _, fc in ipairs((facteurs(N))) do
    local e = fc.s .. (fc.e > 1 and ("^" .. fc.e) or "")
    table.insert(lignes, {nom = depuisX(e, v), expr = e, zeros = fc.cst and {} or racines(fc.s)})
  end
  if deg(D) >= 1 then
    for _, fc in ipairs((facteurs(D))) do
      local e = fc.s .. (fc.e > 1 and ("^" .. fc.e) or "")
      table.insert(lignes, {nom = depuisX(e, v), expr = e, zeros = fc.cst and {} or racines(fc.s)})
    end
  end
  local zN = deg(N) >= 1 and racines(N) or {}
  table.insert(lignes, {nom = "total", expr = E, zeros = zN})
  local pts, sg = tableauSignes(v, lignes, interdits)
  local garder = (op == ">" or op == ">=") and {"+"} or {"−"}
  local function fermes(x) if strict then return false end; for _, z in ipairs(zN) do if math.abs(z.v - x) < 1e-9 then return true end end; return false end
  local function interdit(x) for _, z in ipairs(interdits) do if math.abs(z.v - x) < 1e-9 then return true end end; return false end
  return intervalles(pts, sg, garder, fermes, interdit)
end

-- valeur absolue par cas (test 2025 P1 c, S2 ex.6)
local function ineqAbs(g, d, op, v)
  local tout = g .. op .. d
  local inn = tout:match("abs(%b())")
  inn = inn:sub(2, -2)
  G("Méthode : si A ≥ 0, |A| = A ; si A < 0, |A| = −A. Dans chaque cas : tableau de signes, puis on garde seulement les x qui respectent la condition du cas (intersection). S = réunion des deux cas.")
  local cas_ = {{"Cas 1 : " .. depuisX(inn, v) .. " ≥ 0, donc |" .. depuisX(inn, v) .. "| = " .. depuisX(inn, v), "(" .. inn .. ")", inn .. ">=0"},
                {"Cas 2 : " .. depuisX(inn, v) .. " < 0, donc |" .. depuisX(inn, v) .. "| = −(" .. depuisX(inn, v) .. ")", "(-(" .. inn .. "))", inn .. "<0"}}
  local morceaux = {}
  for k, c in ipairs(cas_) do
    T(c[1])
    local gk = g:gsub("abs%b()", c[2], 1); local dk = d:gsub("abs%b()", c[2], 1)
    M("", depuisX(gk, v) .. op .. depuisX(dk, v))
    local sk = ineqRat(gk, dk, op, v)
    X("Solutions de l'inéquation du cas : " .. sk)
    local cond = enIntervalles(cas1("solve(" .. c[3] .. ",x)"), v)
    X("Condition du cas : " .. cond)
    local inter = cas1("solve((" .. gk .. op .. dk .. ") and " .. c[3] .. ",x)")
    R("S" .. k .. " = (" .. sk .. ") ∩ (" .. cond .. ") = ", "", enIntervalles(inter, v))
    table.insert(morceaux, inter)
  end
  T("Conclusion")
  R("S = S1 ∪ S2 = ", "", enIntervalles(cas1("solve(" .. tout .. ",x)"), v))
end

------------------------------------------------------------------ domaine avec racines (S7 ex.1, ex.3)
local function radicandes(e)
  local out = {}
  for a in e:gmatch("sqrt(%b())") do table.insert(out, a:sub(2, -2)) end
  for a in e:gmatch("√(%b())") do table.insert(out, a:sub(2, -2)) end
  return out
end

local function denominateurs(e)
  local out = {}
  for d in e:gmatch("/%s*(%b())") do table.insert(out, d:sub(2, -2)) end
  for d in e:gmatch("/%s*([%w%^%.]+)") do if d:find("x") and not d:find("^sqrt") then table.insert(out, d) end end
  return out
end

local function domaineGeneral(f)
  vider(); T("Domaine de définition")
  M("f(x) = ", f)
  G("Méthode du prof : « f existe ⇔ … ET … » : une condition numérotée par racine (expression sous √ ≥ 0, ou > 0 si la racine est au dénominateur) et par dénominateur (≠ 0) ; on résout chacune par un tableau de signes, puis on croise les conditions.")
  local conds, k = {}, 0
  local rad = radicandes(f)
  local dens = denominateurs(f)
  for _, r in ipairs(rad) do
    k = k + 1
    local sousDen = false
    for _, dd in ipairs(dens) do if dd:find(r, 1, true) then sousDen = true end end
    local op = sousDen and ">" or ">="
    T("[" .. k .. "] " .. r .. (sousDen and " > 0" or " ≥ 0"))
    local s = ineqRat(r, "0", op, "x")
    R("[" .. k .. "] ⇔ x ∈ ", "", s)
    table.insert(conds, "(" .. r .. ")" .. op .. "0")
  end
  for _, dd in ipairs(dens) do
    if not dd:find("sqrt") then
      k = k + 1
      T("[" .. k .. "] " .. dd .. " ≠ 0")
      local z = racines(cas1("expand(" .. dd .. ")"))
      local l = {}
      for _, r in ipairs(z) do table.insert(l, r.s) end
      R("[" .. k .. "] ⇔ x ∉ ", "{" .. table.concat(l, ",") .. "}")
      table.insert(conds, "(" .. dd .. ")≠0")
    end
  end
  T("Intersection des conditions")
  local sol = #conds > 0 and cas1("solve(" .. table.concat(conds, " and ") .. ",x)") or "true"
  R("D_f = ", "", enIntervalles(sol, "x"))
  G("Contrôle CAS : domain = " .. cas1("domain(" .. f .. ",x)"))
  montrer("Domaine")
end

------------------------------------------------------------------ equation irrationnelle / logarithmique (S2 ex.3, S3 ex.5)
local function eqIrrationnelle(eq)
  local g, d = cotes(eq)
  vider(); T("Équation avec racine")
  M("", eq)
  local rad = radicandes(eq)[1]
  G("Méthode : 1) condition d'existence (sous la racine ≥ 0) ; 2) isoler la racine ; 3) l'autre membre doit être ≥ 0 (une racine est positive) ; 4) élever au carré ; 5) vérifier chaque solution (solutions parasites).")
  X("1) Condition : " .. rad .. " ≥ 0")
  local iso = cas1("solve((" .. g .. ")=(" .. d .. "),s)|sqrt(" .. rad .. ")=s")
  local B = cas1("solve(((" .. g:gsub("sqrt%b()", "s", 1):gsub("√%b()", "s", 1) .. ")=(" .. d:gsub("sqrt%b()", "s", 1):gsub("√%b()", "s", 1) .. ")),s)")
  B = B:match("^s=(.*)$")
  if not B then
    A("Racine non isolable automatiquement.")
    R("Solution (CAS) : ", cas1("solve(" .. eq .. ",x)"))
    montrer("Équation"); return
  end
  M("2) ", "sqrt(" .. rad .. ")=" .. B)
  X("3) Condition : " .. B .. " ≥ 0")
  local carre = cas1("expand((" .. B .. ")^2)")
  M("4) ", rad .. "=" .. carre)
  local cand = racines(cas1("expand((" .. rad .. ")-(" .. carre .. "))"))
  local sol = {}
  X("5) Vérification :")
  for _, c in ipairs(cand) do
    local ok1 = (nombre("(" .. rad .. ")|x=" .. c.s) or -1) >= -1e-9
    local ok2 = (nombre("(" .. B .. ")|x=" .. c.s) or -1) >= -1e-9
    if ok1 and ok2 then table.insert(sol, c.s); M("x = " .. c.s .. " : ", B .. "|x=" .. c.s .. "=" .. cas1("(" .. B .. ")|x=" .. c.s), " ≥ 0  ✓")
    else A("x = " .. c.s .. " rejetée (" .. (ok1 and "membre de droite négatif" or "racine non définie") .. ")") end
  end
  R("S = ", "", ensemble(sol))
  G("Contrôle CAS : " .. cas1("solve(" .. eq .. ",x)"))
  montrer("Équation")
end

local function eqLog(eq)
  vider(); T("Équation avec logarithmes")
  M("", eq)
  G("Méthode : conditions d'existence (argument de chaque ln > 0), puis propriétés du ln (ln a + ln b = ln(ab), ln a = ln b ⇔ a = b), résolution et rejet des solutions hors domaine.")
  local conds = {}
  for a in eq:gmatch("ln(%b())") do if a:find("%a") then table.insert(conds, a:sub(2, -2) .. ">0") end end
  for a in eq:gmatch("log(%b())") do if a:find("%a") then table.insert(conds, a:sub(2, -2) .. ">0") end end
  for _, c in ipairs(conds) do X("Condition : " .. c) end
  local dom = #conds > 0 and cas1("solve(" .. table.concat(conds, " and ") .. ",x)") or "true"
  R("Domaine : ", "", enIntervalles(dom, "x"))
  local g, d = cotes(eq)
  X("On regroupe les logarithmes :")
  M("", cas1("lnCollect(" .. g .. ")") .. "=" .. cas1("lnCollect(" .. d .. ")"))
  R("S = ", cas1("solve(" .. eq .. ",x)"))
  montrer("Équation")
end

------------------------------------------------------------------ bijection sur I, f^-1, verification, courbes (S7 ex.7 g-h, blanc C f-g)
local function echantillons(f, a, b)
  local h = (b - a) / 120
  local s = cas1("seq(approx(" .. f .. "),x," .. a .. "," .. b .. "," .. h .. ")")
  local pts = {}
  local i = 0
  for _, t in ipairs(liste(s)) do
    local y = tonumber((t:gsub("ᴇ", "e"):gsub("E", "e")))
    table.insert(pts, {a + i * h, y})
    i = i + 1
  end
  return pts
end

local function borne(sv)
  sv = sv:gsub("%s", ""):gsub("inf", "∞")
  if sv == "+∞" or sv == "∞" then return "∞", 1e9 end
  if sv == "-∞" or sv == "−∞" then return "-∞", -1e9 end
  return sv, nombre(sv) or 0
end

local function bijectionI(f, I)
  f = norm(f)
  I = I:gsub("%s", "")
  local og, gs, ds, od = I:match("^([%[%]])(.-);(.-)([%[%]])$")
  if not og then vider(); A("Intervalle : tape par ex. ]2;+inf[ ou [0;2["); montrer("Bijection"); return end
  local gx, gv = borne(gs); local dx, dv = borne(ds)
  vider(); T("Bijection et réciproque sur I")
  M("f(x) = ", f)
  X("I = " .. I)
  G("Pourquoi : sur I, f est strictement monotone (voir l'analyse), donc bijective de I sur J = f(I). J se lit aux bornes de I (valeurs ou limites).")
  local function lim(x, cote) if x == "∞" or x == "-∞" then return cas1("limit(" .. f .. ",x," .. x .. ")") end; return cas1("limit(" .. f .. ",x," .. x .. "," .. cote .. ")") end
  local fg, fd = lim(gx, 1), lim(dx, -1)
  local function inf(s) if s == "∞" then return "+∞" end; return s end
  X("Bord gauche de I : f(x) tend vers " .. inf(fg)); X("Bord droit de I : f(x) tend vers " .. inf(fd))
  local croiss = (nombre(fd) or 1e9) > (nombre(fg) or -1e9)
  if fd == "∞" then croiss = true elseif fd == "-∞" then croiss = false end
  if fg == "-∞" then croiss = true elseif fg == "∞" then croiss = false end
  local Jg, Jd, oJg, oJd
  if croiss then Jg, Jd, oJg, oJd = inf(fg), inf(fd), og, od else Jg, Jd, oJg, oJd = inf(fd), inf(fg), (od == "]" and "[" or "]"), (og == "[" and "]" or "[") end
  R("J = f(I) = ", "", oJg .. Jg .. " ; " .. Jd .. oJd)
  T("Réciproque : 3 étapes")
  X("1) y = f(x) ; 2) on isole x ; 3) on garde la solution qui est dans I, puis on renomme y en x.")
  local sols = liste("{" .. cas1("solve(y=" .. f .. ",x)"):gsub(" or ", ","):gsub("x=", "") .. "}")
  local mid = (gv > -1e8 and dv < 1e8) and (gv + dv) / 2 or (gv > -1e8 and gv + 1 or (dv < 1e8 and dv - 1 or 0))
  local ymid = nombre("(" .. f .. ")|x=" .. string.format("%.6f", mid))
  local bonne
  for _, s0 in ipairs(sols) do
    local s1 = s0:gsub(" and .*$", "")
    M("x = ", s1)
    local xt = ymid and nombre("(" .. s1 .. ")|y=" .. string.format("%.6f", ymid))
    if xt and math.abs(xt - mid) < 1e-4 and not bonne then bonne = s1 end
  end
  if not bonne then A("Branche non identifiée automatiquement."); montrer("Bijection"); return end
  X("On garde la branche dont les valeurs sont dans I :")
  local finv = bonne:gsub("y", "x")
  R("f⁻¹ : J → I,  f⁻¹(x) = ", finv)
  T("Vérification")
  local function subst(e, par) return (e:gsub("%f[%a]x%f[%A]", "(" .. par .. ")")) end
  M("f(f⁻¹(x)) = ", cas1("(" .. subst(f, finv) .. ")"), "  (x ∈ J)")
  M("f⁻¹(f(x)) = ", cas1("(" .. subst(finv, f) .. ")"), "  (x ∈ I)")
  G("Si le CAS n'obtient pas exactement x, c'est souvent une valeur absolue due au carré : elle vaut x sur I.")
  T("Courbes de f (sur I) et de f⁻¹")
  G("Celle de f⁻¹ est la symétrique de celle de f par rapport à y = x ; les asymptotes sont échangées.")
  local a = gv > -1e8 and gv or (dv < 1e8 and dv - 8 or -8)
  local b = dv < 1e8 and dv or a + 8
  if gv <= -1e8 then a = b - 8 end
  local e = 1e-3 * math.max(1, b - a)
  local c1 = echantillons(f, a + e, b - e)
  local c2 = {}
  for _, p in ipairs(c1) do if p[2] then table.insert(c2, {p[2], p[1]}) end end
  local fins = {0}
  for _, v0 in ipairs({gv, dv, nombre(Jg) or 1e9, nombre(Jd) or 1e9}) do if math.abs(v0) < 1e8 then table.insert(fins, v0) end end
  local wlo, whi = math.min(unpack(fins)) - 1, math.max(unpack(fins)) + 4
  table.insert(DOC, {k = "courbes", lo = wlo, hi = whi, courbes = {{pts = c1, coul = {0, 0, 200}}, {pts = c2, coul = {0, 150, 0}}}, diag = true,
    legende = "bleu : f sur I   vert : f⁻¹   pointillé : y = x"})
  memoriser(finv)
  montrer("Bijection")
end

------------------------------------------------------------------ parite, composition, sommet (S7 ex.3, 4, 6)
local function parite(f)
  f = norm(f)
  vider(); T("Parité")
  M("f(x) = ", f)
  G("Méthode : D_f doit être symétrique par rapport à 0 ; on calcule f(−x) et on compare à f(x) (paire) et à −f(x) (impaire).")
  local fm = cas1(substX(f, "-x"))
  M("f(−x) = ", fm)
  local p = cas1("((" .. fm .. ")-(" .. f .. "))")
  local i = cas1("((" .. fm .. ")+(" .. f .. "))")
  if p == "0" then R("", "", "f(−x) = f(x) : f est paire (symétrie par rapport à l'axe Oy)")
  elseif i == "0" then R("", "", "f(−x) = −f(x) : f est impaire (symétrie par rapport à O)")
  else R("", "", "ni paire ni impaire")
    G("Contre-exemple : f(1) = " .. cas1("(" .. f .. ")|x=1") .. " et f(−1) = " .. cas1("(" .. f .. ")|x=-1"))
  end
  G("Domaine : " .. cas1("domain(" .. f .. ",x)"))
  montrer("Parité")
end

local function composition(f, g)
  f, g = norm(f), norm(g)
  vider(); T("Composition")
  M("f(x) = ", f); M("g(x) = ", g)
  G("f∘g(x) = f(g(x)) : on remplace x par g(x) dans f. Domaine : x ∈ D_g ET g(x) ∈ D_f.")
  M("(f∘g)(x) = ", substX(f, g))
  R("= ", cas1(substX(f, g)))
  G("D_f∘g = " .. cas1("domain(" .. substX(f, g) .. ",x)"))
  M("(g∘f)(x) = ", substX(g, f))
  R("= ", cas1(substX(g, f)))
  G("D_g∘f = " .. cas1("domain(" .. substX(g, f) .. ",x)"))
  montrer("Composition")
end

------------------------------------------------------------------ factorisation litterale, isoler une lettre (S1, S3 ex.6)
local function factoLitterale(e)
  vider(); T("Factorisation")
  M("", e)
  G("Méthode : 1) mise en évidence du facteur commun ; 2) identités remarquables a²−b² = (a−b)(a+b), a²±2ab+b² = (a±b)² ; 3) groupement de termes ; 4) trinôme : Δ.")
  R("= ", cas1("factor(" .. e .. ")"))
  G("Contrôle : en développant on retrouve " .. cas1("expand(" .. e .. ")"))
  montrer("Factorisation")
end

local function isoler(eq, l)
  vider(); T("Isoler " .. l)
  M("", eq)
  G("Méthode : conditions d'existence (dénominateurs ≠ 0, racines ≥ 0), puis opérations inverses des deux côtés.")
  R("", cas1("solve(" .. eq .. "," .. l .. ")"))
  montrer("Isoler")
end

------------------------------------------------------------------ bilinearite (S5 ex.4, ex.7)
local function bilin(eq, na, nb)
  vider(); T("Produit scalaire par bilinéarité")
  M("", eq .. "  avec ||a|| = " .. na .. ", ||b|| = " .. nb)
  G("Méthode : développer comme un produit (distributivité), avec a·a = ||a||², b·b = ||b||², a·b = b·a ; puis isoler a·b ; enfin cos θ = a·b / (||a||·||b||).")
  local g, d = cotes(eq)
  local E = cas1("expand((" .. g .. ")-(" .. d .. "))")
  local k = cas1("(" .. E .. ")|a=0 and b=0")
  local caa = cas1("((" .. E .. ")|a=1 and b=0)-(" .. k .. ")")
  local cbb = cas1("((" .. E .. ")|a=0 and b=1)-(" .. k .. ")")
  local cab = cas1("((" .. E .. ")|a=1 and b=1)-(" .. caa .. ")-(" .. cbb .. ")-(" .. k .. ")")
  M("Développé : ", "(" .. caa .. ")*||a||^2+(" .. cab .. ")*(a·b)+(" .. cbb .. ")*||b||^2+(" .. k .. ")=0")
  local ps = cas1("solve((" .. caa .. ")*(" .. na .. ")^2+(" .. cab .. ")*p+(" .. cbb .. ")*(" .. nb .. ")^2+(" .. k .. ")=0,p)"):gsub("^p=", "")
  R("a·b = ", ps)
  local c = cas1("(" .. ps .. ")/((" .. na .. ")*(" .. nb .. "))")
  R("cos θ = ", c)
  local dg = nombre("arccos(" .. c .. ")*180/π")
  R("θ = ", cas1("arccos(" .. c .. ")"), dg and string.format("  ≈ %.4g°", dg) or "")
  montrer("Bilinéarité")
end

------------------------------------------------------------------ systeme vectoriel (S5 ex.2, S6 ex.5-6)
local function systemeVect(defs, conds)
  vider(); T("Système de conditions vectorielles")
  local noms = {}
  for _, d in ipairs(decouper(defs, ";")) do
    local n, v = d:match("^%s*(%a)%s*=%s*(.-)%s*$")
    if n then noms[n] = vec(v); M("", n .. "=" .. vec(v)) end
  end
  G("Méthode : chaque condition (u·v = 0 pour l'orthogonalité, u×v = 0 pour la colinéarité, une norme ou une aire donnée) donne une équation ; on résout le système.")
  local c = conds:gsub("·", "."):gsub("(%a)%.(%a)", "dotP(%1,%2)"):gsub("(%a)x(%a)", "crossP(%1,%2)"):gsub("|(%a)|", "norm(%1)")
  for n, v in pairs(noms) do c = c:gsub("%f[%a]" .. n .. "%f[%A]", v) end
  local inc = {}
  local tout = c
  for _, l in ipairs({"a", "b", "c", "x", "y", "z", "t", "m", "k", "λ"}) do
    local present = false
    for _, v in pairs(noms) do if v:find("%f[%a]" .. l .. "%f[%A]") then present = true end end
    if present then table.insert(inc, l) end
  end
  for _, e in ipairs(decouper((c:gsub(" and ", ";")), ";")) do M("", cas1("expand(" .. e:gsub("=.*", "") .. ")") .. "=" .. (e:match("=(.*)$") or "0")) end
  R("", cas1("solve(" .. c:gsub(";", " and ") .. ",{" .. table.concat(inc, ",") .. "})"))
  montrer("Système")
end

M1.substX = substX; M1.OPSL = OPSL; M1.atome = atome; M1.enIntervalles = enIntervalles; M1.ineqRat = ineqRat; M1.ineqAbs = ineqAbs
M1.radicandes = radicandes; M1.denominateurs = denominateurs; M1.domaineGeneral = domaineGeneral; M1.eqIrrationnelle = eqIrrationnelle; M1.eqLog = eqLog; M1.echantillons = echantillons
M1.borne = borne; M1.bijectionI = bijectionI; M1.parite = parite; M1.composition = composition; M1.factoLitterale = factoLitterale; M1.isoler = isoler
M1.bilin = bilin; M1.systemeVect = systemeVect
end
