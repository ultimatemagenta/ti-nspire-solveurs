-- 50_figures.lua : Chasles sur une figure, problemes complets A et B, outils ponctuels (points, colinearite…)
-- (lignes 1860-2427 de lua/solveur.lua, decoupees le 11.11.2026 ; code inchange)
do   -- bloc : limite de 200 variables locales du script principal
local norm, ordre, signe, EXT, vec, comp, point, V, enIntervalles, ineqRat, ineqAbs, eqIrrationnelle = M1.norm, M1.ordre, M1.signe, M1.EXT, M1.vec, M1.comp, M1.point, M1.V, M1.enIntervalles, M1.ineqRat, M1.ineqAbs, M1.eqIrrationnelle
local eqLog = M1.eqLog
------------------------------------------------------------------ Chasles sur une figure (S4, blanc B, test 2025 P3)
local FIGURES = {
  {"Parallélogramme ABCD, centre O", "A=0;B=u;D=v;C=u+v;O=(u+v)/2"},
  {"Parallélépipède ABCDEFGH", "A=0;B=u;D=v;C=u+v;E=w;F=u+w;H=v+w;G=u+v+w"},
  {"Triangle ABC, milieux I(AB) J(BC) K(AC), G centre", "A=0;B=u;C=v;I=u/2;J=(u+v)/2;K=v/2;G=(u+v)/3"},
}

local function chasles(defs, somme)
  vider(); T("Chasles et combinaisons linéaires")
  G("Méthode : on exprime chaque point dans le repère (A ; u, v, w) de la figure, chaque vecteur XY = Y − X, on additionne, puis on reconnaît un vecteur de la figure. Sur la copie : remplacer les vecteurs égaux puis enchaîner Chasles (XY + YZ = XZ).")
  local P = {}
  local ordre = {}
  for _, d in ipairs(decouper(defs, ";")) do
    local n, e = d:match("^%s*(%u%d?)%s*=%s*(.-)%s*$")
    if n then
      e = e:gsub("%f[%a]u%f[%A]", "[1,0,0]"):gsub("%f[%a]v%f[%A]", "[0,1,0]"):gsub("%f[%a]w%f[%A]", "[0,0,1]")
      if e == "0" then e = "[0,0,0]" end
      for m, val in pairs(P) do e = e:gsub("%f[%u]" .. m .. "%f[^%w]", "(" .. val .. ")") end
      P[n] = cas1(e); table.insert(ordre, n)
    end
  end
  local function enUVW(vv)
    local c = comp(vv)
    local t = {}
    for i, nm in ipairs({"u", "v", "w"}) do
      local ci = c[i] or "0"
      if ci ~= "0" then table.insert(t, (ci == "1" and "" or (ci == "-1" and "-" or ("(" .. ci .. ")*"))) .. nm) end
    end
    if #t == 0 then return "0" end
    return (table.concat(t, "+"):gsub("%+%-", "-"))
  end
  -- somme : termes ±k*XY
  local s = somme:gsub("%s", ""):gsub("−", "-")
  if s:sub(1, 1) ~= "-" and s:sub(1, 1) ~= "+" then s = "+" .. s end
  local total = "[0,0,0]"
  for signe, coef, X1, Y1 in s:gmatch("([%+%-])([%d/%.]*)%*?(%u%d?)(%u%d?)") do
    if not P[X1] or not P[Y1] then A("Point inconnu : " .. (P[X1] and Y1 or X1)); montrer("Chasles"); return end
    local vv = cas1("(" .. P[Y1] .. ")-(" .. P[X1] .. ")")
    M(signe .. (coef ~= "" and coef or "") .. X1 .. Y1 .. " = ", enUVW(vv))
    total = cas1(total .. signe .. (coef ~= "" and coef or "1") .. "*(" .. vv .. ")")
  end
  R("Somme = ", enUVW(total))
  local trouves = {}
  for _, a in ipairs(ordre) do for _, b in ipairs(ordre) do
    if a ~= b and cas1("(" .. P[b] .. ")-(" .. P[a] .. ")-(" .. total .. ")") == "[[0,0,0]]" or (a ~= b and cas1("(" .. P[b] .. ")-(" .. P[a] .. ")-(" .. total .. ")") == "[0,0,0]") then
      table.insert(trouves, a .. b) end
  end end
  if total == "[0,0,0]" or total == "[[0,0,0]]" then R("", "", "= vecteur nul 0")
  elseif #trouves > 0 then R("= ", "", table.concat(trouves, " = ")) else G("Aucun vecteur de la figure n'est égal à cette somme : réponse en u, v, w ci-dessus.") end
  montrer("Chasles")
end

EXT.abs = ineqAbs; EXT.rat = ineqRat; EXT.irr = eqIrrationnelle; EXT.log = eqLog; EXT.intv = enIntervalles

------------------------------------------------------------------ problemes complets A (vecteurs) et B (figure)
local function nettoie(v) return (v:gsub("^%[%[", "["):gsub("%]%]$", "]")) end
local function C(e) return nettoie(cas1(e)) end

local function problemeA(Ps, Qs, Rs, Ss)
  local nP, P = point(Ps); local nQ, Q = point(Qs); local nR, Rp = point(Rs)
  local _, S0 = point(norm(Ss))
  local par
  for _, l in ipairs({"x", "t", "k", "m", "a", "λ", "y", "z"}) do if S0:find(l, 1, true) and (l == "λ" or S0:find("%f[%a]" .. l .. "%f[%A]")) then par = l; break end end
  vider(); T("Problème A : vecteurs dans l'espace")
  V(nP, P); V(nQ, Q); V(nR, Rp); V("S", S0)
  local QR = C(Rp .. "-" .. Q); local QP = C(P .. "-" .. Q)
  -- a) projection
  T("a) Projection orthogonale T de P sur (QR)")
  G("Méthode : T = Q + k·QR avec k = (QP·QR) / ||QR||² ; on vérifie que PT ⊥ QR. Schéma : P au-dessus de la droite (QR), T au pied de la perpendiculaire.")
  V("QR", QR); V("QP", QP)
  local ps, n2 = C("dotP(" .. QP .. "," .. QR .. ")"), C("dotP(" .. QR .. "," .. QR .. ")")
  M("QP·QR = ", ps); M("||QR||^2 = ", n2)
  local k = C("(" .. ps .. ")/(" .. n2 .. ")")
  M("k = ", "(" .. ps .. ")/(" .. n2 .. ")=" .. k)
  local Tt = C(Q .. "+(" .. k .. ")*" .. QR)
  R("T = Q + k·QR = ", Tt)
  local PT = C(Tt .. "-" .. P)
  G("Contrôle : PT·QR = " .. C("dotP(" .. PT .. "," .. QR .. ")") .. " (doit valoir 0)")
  M("Distance de P à (QR) : ||PT|| = ", C("norm(" .. PT .. ")"))
  -- b) point S
  T("b) Point S tel que QS ⊥ QR")
  G("Méthode : QS ⊥ QR ⇔ QS·QR = 0 : une équation du 1er degré en " .. (par or "?") .. ".")
  local QS0 = C(S0 .. "-" .. Q)
  V("QS", QS0)
  local eq = C("expand(dotP(" .. QS0 .. "," .. QR .. "))")
  M("QS·QR = ", eq .. "=0")
  local sol = par and C("solve(" .. eq .. "=0," .. par .. ")") or "?"
  R("", sol)
  local S = par and C("(" .. S0 .. ")|" .. sol) or S0
  R("S = ", S)
  local QS = C(S .. "-" .. Q)
  V("QS", QS)
  -- c) volume
  T("c) Volume du parallélépipède (QP, QR, QS)")
  G("Méthode : V = |[QP ; QR ; QS]| = |QP·(QR × QS)| (produit mixte).")
  local x = C("crossP(" .. QR .. "," .. QS .. ")")
  M("QR × QS = ", x)
  local m = C("dotP(" .. QP .. "," .. x .. ")")
  M("[QP;QR;QS] = QP·(QR×QS) = ", m)
  R("V = |[QP;QR;QS]| = ", C("abs(" .. m .. ")"), " (unités de volume)")
  -- d) BON
  T("d) Base orthonormée directe B0 = {u, v, w}")
  G("Méthode : u = QR / ||QR|| (même sens que QR). Observation : QS·QR = 0, donc QS ⊥ QR ; on prend v = QS / ||QS||. Enfin w = u × v (dans cet ordre : la base est directe).")
  local u = C("unitV(" .. QR .. ")")
  local vv = C("unitV(" .. QS .. ")")
  if C("dotP(" .. QS .. "," .. QR .. ")") ~= "0" then
    A("QS n'est pas ⊥ QR : on prend la composante de QS orthogonale à QR.")
    vv = C("unitV(" .. QS .. "-dotP(" .. QS .. "," .. u .. ")*" .. u .. ")")
  end
  M("||QR|| = ", C("norm(" .. QR .. ")")); R("u = ", u)
  M("||QS|| = ", C("norm(" .. QS .. ")")); R("v = ", vv)
  local w = C("crossP(" .. u .. "," .. vv .. ")")
  R("w = u × v = ", w)
  G("Contrôles : u·v = " .. C("dotP(" .. u .. "," .. vv .. ")") .. " ; ||w|| = " .. C("norm(" .. w .. ")") .. " ; [u;v;w] = " .. C("dotP(" .. u .. ",crossP(" .. vv .. "," .. w .. "))"))
  -- e) composantes
  T("e) Composantes de QP dans B0")
  G("Méthode : B0 est orthonormée, donc les composantes sont les produits scalaires : QP = (QP·u) u + (QP·v) v + (QP·w) w. (Sinon : résoudre un système 3×3.)")
  local a1, a2, a3 = C("dotP(" .. QP .. "," .. u .. ")"), C("dotP(" .. QP .. "," .. vv .. ")"), C("dotP(" .. QP .. "," .. w .. ")")
  M("QP·u = ", a1); M("QP·v = ", a2); M("QP·w = ", a3)
  R("QP = ", "[" .. a1 .. "," .. a2 .. "," .. a3 .. "]", " dans B0")
  G("Contrôle : (QP·u)u + (QP·v)v + (QP·w)w = " .. C("(" .. a1 .. ")*" .. u .. "+(" .. a2 .. ")*" .. vv .. "+(" .. a3 .. ")*" .. w))
  -- variantes
  T("Variantes possibles (même données)")
  local cr = C("crossP(" .. QP .. "," .. QR .. ")")
  M("Aire du triangle PQR = ||QP×QR||/2 = ", C("norm(" .. cr .. ")/2"))
  M("Aire du parallélogramme (QP, QR) = ", C("norm(" .. cr .. ")"))
  local cosq = C("dotP(" .. QP .. "," .. QR .. ")/(norm(" .. QP .. ")*norm(" .. QR .. "))")
  local dg = nombre("arccos(" .. cosq .. ")*180/π")
  M("Angle PQR : cos = ", cosq, dg and string.format("  ≈ %.4g°", dg) or "")
  M("Volume du tétraèdre PQRS = |[QP;QR;QS]|/6 = ", C("abs(" .. m .. ")/6"))
  M("P, Q, R alignés ? QP×QR = ", cr, cr == "[0,0,0]" and "  → alignés" or "  → non alignés")
  local kk = "[0,0,1]"
  local mk = C("dotP(" .. QP .. ",crossP(" .. QR .. "," .. kk .. "))")
  X("Base B = {QP, QR, k} (k = (0;0;1)) : [QP;QR;k] = " .. mk .. (mk ~= "0" and " ≠ 0 → c'est une base" or " = 0 → pas une base"))
  if mk ~= "0" then
    local c3 = C("solve(" .. "α*" .. QP .. "+β*" .. QR .. "+γ*" .. kk .. "=" .. QS .. ",{α,β,γ})")
    M("QS dans B : ", c3)
    X("B orthonormée ? ||QP|| = " .. C("norm(" .. QP .. ")") .. ", QP·QR = " .. ps .. " → " .. ((C("norm(" .. QP .. ")") == "1" and ps == "0") and "à vérifier avec QR et k" or "non (ni normée ni orthogonale)"))
  end
  memoriser(Tt); memoriser(S)
  montrer("Problème A")
end

------------------------------------------------------------------ probleme B : figure, sommes, base (u, v), multiples
local FIGB = {
  {"Parallélogramme ABCD, centre O, milieux I(AB) M(BC) N(CD) K(DA)", "A=0;B=u;D=v;C=u+v;O=(u+v)/2;I=u/2;M=u+v/2;N=u/2+v;K=v/2"},
  {"Triangle ABC, milieux I(AB) J(BC) K(CA), centre de gravité G", "A=0;B=u;C=v;I=u/2;J=(u+v)/2;K=v/2;G=(u+v)/3"},
  {"Parallélépipède ABCDEFGH (ABCD bas, EFGH haut)", "A=0;B=u;D=v;C=u+v;E=w;F=u+w;H=v+w;G=u+v+w"},
}

local function problemeB(defs, sommes)
  vider(); T("Problème B : figure et Chasles")
  G("Rédaction du prof : remplacer les vecteurs égaux de la figure (parallélogramme : DA = CB, BC = AD…), puis enchaîner Chasles XY + YZ = XZ ; avec une base (u, v), tout exprimer en u et v puis comparer.")
  local P, ordre = {}, {}
  for _, d in ipairs(decouper(defs, ";")) do
    local n, e = d:match("^%s*(%u%d?)%s*=%s*(.-)%s*$")
    if n then
      local e2 = e:gsub("%f[%a]u%f[%A]", "[1,0,0]"):gsub("%f[%a]v%f[%A]", "[0,1,0]"):gsub("%f[%a]w%f[%A]", "[0,0,1]")
      if e2 == "0" then e2 = "[0,0,0]" end
      P[n] = C(e2); table.insert(ordre, n)
      X(n .. " = " .. (e == "0" and "origine A" or e))
    end
  end
  local function enUV(vv)
    local c = comp(vv); local t = {}
    for i, nm in ipairs({"u", "v", "w"}) do
      local ci = c[i] or "0"
      if ci ~= "0" then table.insert(t, (ci == "1" and "" or (ci == "-1" and "-" or (ci .. "*"))) .. nm) end
    end
    if #t == 0 then return "0" end
    return (table.concat(t, "+"):gsub("%+%-", "-"))
  end
  local function reconnaitre(total)
    if comp(total)[1] == "0" and comp(total)[2] == "0" and (comp(total)[3] or "0") == "0" then return "vecteur nul" end
    local egaux, multiples = {}, {}
    for _, a in ipairs(ordre) do for _, b in ipairs(ordre) do if a ~= b then
      local ab = C(P[b] .. "-" .. P[a])
      if C(ab .. "-" .. total) == "[0,0,0]" then table.insert(egaux, a .. b)
      elseif C("crossP(" .. ab .. "," .. total .. ")") == "[0,0,0]" and #multiples < 3 then
        local ca, ct = comp(ab), comp(total)
        local kq
        for i = 1, 3 do if ca[i] ~= "0" then kq = C("(" .. ct[i] .. ")/(" .. ca[i] .. ")"); break end end
        if kq and (kq == "1/2" or kq == "2" or kq == "-1/2" or kq == "-2" or kq == "1/3" or kq == "-1" or kq == "3/2" or kq == "1/4" or kq == "2/3" or kq == "-1/3") then table.insert(multiples, kq .. "·" .. a .. b) end
      end
    end end end
    if #egaux > 0 then return table.concat(egaux, " = ") end
    if #multiples > 0 then return table.concat(multiples, " = ") end
    return nil
  end
  for _, sm in ipairs(decouper(sommes, ";")) do
    local s = sm:gsub("%s", ""):gsub("−", "-")
    if s ~= "" then
      T(s)
      if s:sub(1, 1) ~= "-" and s:sub(1, 1) ~= "+" then s = "+" .. s end
      local total = "[0,0,0]"
      local ok = true
      for signe, coef, X1, Y1 in s:gmatch("([%+%-])([%d/%.]*)%*?(%u%d?)(%u%d?)") do
        if not P[X1] or not P[Y1] then A("Point inconnu : " .. (P[X1] and Y1 or X1)); ok = false; break end
        local vv = C(P[Y1] .. "-" .. P[X1])
        M((signe == "-" and "−" or "+") .. (coef ~= "" and coef or "") .. X1 .. Y1 .. " = ", enUV(vv))
        total = C(total .. signe .. (coef ~= "" and coef or "1") .. "*(" .. vv .. ")")
      end
      if ok then
        R("= ", enUV(total))
        local r = reconnaitre(total)
        if r then R("= ", "", r) else G("Pas de vecteur nommé égal : on garde l'expression en u, v.") end
      end
    end
  end
  montrer("Problème B")
end

------------------------------------------------------------------ problemes A et B : version complete (variantes)
local function pad3(v)
  local c = comp(v)
  if #c == 2 then return "[" .. c[1] .. "," .. c[2] .. ",0]" end
  return v
end
local function CC(e) return (cas1(e):gsub("^%[%[", "["):gsub("%]%]$", "]")) end
local function estNul(v) for _, x in ipairs(comp(v)) do if x ~= "0" then return false end end return true end

-- remplace les noms de vecteurs XY (deux majuscules) par leurs coordonnees
local function vecteursNommes(expr, pts)
  return (expr:gsub("(%u%d?)(%u%d?)", function(a, b)
    if pts[a] and pts[b] then return "(" .. pts[b] .. "-" .. pts[a] .. ")" end
    return a .. b
  end))
end

------------------------------------------------------------------ outils ponctuels
local function vPoint(typ, a, b, c, k)
  vider(); T("Construction d'un point")
  local _, A0 = point(a); local _, B0 = point(b or "0,0,0"); local _, C0 = point(c or "0,0,0")
  if typ == "milieu" then
    G("Le milieu I de [AB] vérifie AI = ½·AB, donc OI = (OA + OB)/2.")
    R("I = (A + B)/2 = ", CC("(" .. A0 .. "+" .. B0 .. ")/2"))
  elseif typ == "gravite" then
    G("Centre de gravité : GA + GB + GC = 0, donc OG = (OA + OB + OC)/3.")
    R("G = (A + B + C)/3 = ", CC("(" .. A0 .. "+" .. B0 .. "+" .. C0 .. ")/3"))
  elseif typ == "para" then
    G("ABCD parallélogramme ⇔ AB = DC (règle du prof « AB = DC », poly p.9), donc D = A + C − B.")
    local D = CC(A0 .. "+" .. C0 .. "-" .. B0)
    R("D = A + C − B = ", D)
    G("Contrôle : AB = " .. CC(B0 .. "-" .. A0) .. " et DC = " .. CC(C0 .. "-" .. D))
  elseif typ == "sym" then
    G("Symétrique A′ de A par rapport à B : B est le milieu de [AA′], donc A′ = 2B − A.")
    R("A′ = 2B − A = ", CC("2*" .. B0 .. "-" .. A0))
  elseif typ == "rapport" then
    G("AM = k·AB, donc OM = OA + k·AB.")
    R("M = A + k(B − A) = ", CC(A0 .. "+(" .. k .. ")*(" .. B0 .. "-" .. A0 .. ")"))
  elseif typ == "relation" then
    local co = decouper(k, ",")
    local al, be, ga = co[1] or "1", co[2] or "1", co[3] or "0"
    G("αMA + βMB + γMC = 0 ⇔ α(A − M) + β(B − M) + γ(C − M) = 0 ⇔ M = (αA + βB + γC)/(α + β + γ).")
    local s = CC("(" .. al .. ")+(" .. be .. ")+(" .. ga .. ")")
    if s == "0" then A("α + β + γ = 0 : pas de point M unique.")
    else R("M = ", CC("((" .. al .. ")*" .. A0 .. "+(" .. be .. ")*" .. B0 .. "+(" .. ga .. ")*" .. C0 .. ")/(" .. s .. ")")) end
  end
  montrer("Point")
end

-- colinearite redigee par lambda (avec ou sans parametre)
local function vColin(u, v)
  u, v = vec(u), vec(v)
  vider(); T("Colinéarité (méthode du prof : v = λ·u)")
  V("u", u); V("v", v)
  G("u et v sont colinéaires ⇔ il existe λ tel que v = λ·u : une équation par composante ; on isole λ dans l'une et on reporte dans les autres.")
  local a, b = comp(u), comp(v)
  local eqs = {}
  for i = 1, #a do
    M("", b[i] .. "=λ*(" .. a[i] .. ")")
    table.insert(eqs, b[i] .. "=λ*(" .. a[i] .. ")")
  end
  local inc = "λ"
  for _, l in ipairs({"m", "x", "t", "k", "a", "y", "z"}) do if (u .. v):find("%f[%a]" .. l .. "%f[%A]") then inc = "{λ," .. l .. "}"; break end end
  local sol = cas1("solve(" .. table.concat(eqs, " and ") .. "," .. inc .. ")")
  if sol == "false" then R("", "", "Aucun λ : u et v ne sont PAS colinéaires (P, Q, R non alignés / droites non parallèles).")
  else R("", sol); X("Il existe λ : colinéaires (points alignés / droites parallèles).") end
  G("Contrôle : u × v = " .. CC("crossP(" .. pad3(u) .. "," .. pad3(v) .. ")"))
  montrer("Colinéarité")
end

-- vecteur unitaire orthogonal a deux vecteurs ; vecteur de norme donnee
local function vUnitOrtho(a, b)
  a, b = pad3(vec(a)), pad3(vec(b))
  vider(); T("Vecteur unitaire orthogonal à a et b")
  G("a × b est orthogonal à a et à b ; on le divise par sa norme. Deux réponses : ± (a × b)/||a × b||.")
  V("a", a); V("b", b)
  local w = CC("crossP(" .. a .. "," .. b .. ")")
  M("a × b = ", w); M("||a × b|| = ", cas1("norm(" .. w .. ")"))
  R("n = ", CC("unitV(" .. w .. ")")); R("ou n = ", CC("-unitV(" .. w .. ")"))
  montrer("Unitaire")
end

local function vNormeDonnee(a, d)
  a = vec(a)
  vider(); T("Vecteur de norme donnée")
  G("Même direction et même sens : w = d·a/||a|| ; sens contraire : −d·a/||a||.")
  V("a", a); M("||a|| = ", cas1("norm(" .. a .. ")"))
  R("w = ", CC("(" .. d .. ")*unitV(" .. a .. ")")); R("sens contraire : ", CC("-(" .. d .. ")*unitV(" .. a .. ")"))
  montrer("Norme donnée")
end

-- composantes dans une base (2D ou 3D) avec etapes par coordonnee
local function composantesBase(w, base, titre)
  local n = #base
  local nom = {"α", "β", "γ"}
  local eqs = {}
  local W = comp(w)
  for i = 1, #W do
    local terms = {}
    for j = 1, n do table.insert(terms, "(" .. (comp(base[j])[i] or "0") .. ")*" .. nom[j]) end
    local lhs = cas1("expand(" .. table.concat(terms, "+") .. ")")
    M((i == 1 and "x" or (i == 2 and "y" or "z")) .. " : ", lhs .. "=" .. W[i])
    table.insert(eqs, table.concat(terms, "+") .. "=" .. W[i])
  end
  local inc = {}
  for j = 1, n do table.insert(inc, nom[j]) end
  local sol = cas1("solve(" .. table.concat(eqs, " and ") .. ",{" .. table.concat(inc, ",") .. "})")
  if sol == "false" then A("Système impossible : le vecteur n'est pas dans le plan de la base.") return end
  local vals = {}
  for j = 1, n do
    local vj = cas1(nom[j] .. "|" .. sol)
    R(nom[j] .. " = ", vj)
    table.insert(vals, vj)
  end
  R((titre or "") .. "(" .. table.concat(vals, " ; ") .. ") dans la base B", "", "")
  return vals
end

------------------------------------------------------------------ probleme A complet (version 2)
local function problemeA2(Ps, Qs, Rs, Ss, cond)
  local nP, P = point(Ps); local nQ, Q = point(Qs); local nR, Rp = point(Rs)
  local _, S0 = point(norm(Ss))
  P, Q, Rp, S0 = pad3(P), pad3(Q), pad3(Rp), pad3(S0)
  local par
  for _, l in ipairs({"x", "t", "k", "m", "a", "λ", "y", "z"}) do if S0:find(l, 1, true) and (l == "λ" or S0:find("%f[%a]" .. l .. "%f[%A]")) then par = l; break end end
  vider(); T("Problème A : vecteurs dans l'espace")
  V(nP, P); V(nQ, Q); V(nR, Rp); V("S", S0)
  local QR = CC(Rp .. "-" .. Q); local QP = CC(P .. "-" .. Q)
  T("a) Projection orthogonale T de P sur (QR)")
  G("Méthode du prof : schéma (1 pt) ; QT = (QP·QR / ||QR||²)·QR puis OT = OQ + QT ; contrôle PT·QR = 0.")
  V("QR", QR); V("QP", QP)
  local ps, n2 = CC("dotP(" .. QP .. "," .. QR .. ")"), CC("dotP(" .. QR .. "," .. QR .. ")")
  M("QP·QR = ", ps); M("||QR||^2 = ", n2)
  local k = CC("(" .. ps .. ")/(" .. n2 .. ")")
  local QT = CC("(" .. k .. ")*" .. QR)
  M("QT = ", "(" .. ps .. ")/(" .. n2 .. ")*QR=" .. QT)
  local Tt = CC(Q .. "+" .. QT)
  R("T = Q + QT = ", Tt)
  local PT = CC(Tt .. "-" .. P)
  G("Contrôle : PT·QR = " .. CC("dotP(" .. PT .. "," .. QR .. ")"))
  M("Distance de P à (QR) = ||PT|| = ", cas1("norm(" .. PT .. ")"))
  M("Symétrique de P par rapport à (QR) : P' = 2T − P = ", CC("2*" .. Tt .. "-" .. P))
  -- b) S
  cond = (cond and cond ~= "") and cond or "QS.QR=0"
  T("b) Point S : " .. cond)
  local pts = {P = P, Q = Q, R = Rp, S = S0, [nP] = P, [nQ] = Q, [nR] = Rp}
  local c = cond:gsub("(%u%d?%u%d?)%.(%u%d?%u%d?)", "dotP(%1,%2)"):gsub("(%u%d?%u%d?)x(%u%d?%u%d?)", "crossP(%1,%2)"):gsub("||(%u%d?%u%d?)||", "norm(%1)")
  c = vecteursNommes(c, pts)
  G("Méthode : on traduit la condition en équation(s) en " .. (par or "?") .. " (⊥ ⇔ produit scalaire nul ; colinéaires ⇔ produit vectoriel nul ; norme donnée ⇔ élever au carré) puis on résout.")
  local QS0 = CC(S0 .. "-" .. Q); V("QS", QS0)
  local lhs, rhs = c:match("^(.-)=(.*)$")
  if lhs then M("", cas1("expand(" .. lhs .. ")") .. "=" .. cas1(rhs)) end
  local sol = par and cas1("solve(" .. c .. "," .. par .. ")") or "?"
  R("", sol)
  local premier = (sol:gsub(" or .*$", ""))
  if sol:find(" or ") then G("Plusieurs solutions : la suite utilise " .. premier .. " (relance avec l'autre si l'énoncé l'impose).") end
  local S = par and CC("(" .. S0 .. ")|" .. premier) or S0
  R("S = ", S)
  local QS = CC(S .. "-" .. Q); V("QS", QS)
  -- c) volume
  T("c) Volume du parallélépipède")
  G("Méthode du prof : V = |[QP ; QS ; QR]| = |QP·(QS × QR)| ; V = 0 ⇔ vecteurs coplanaires.")
  local x = CC("crossP(" .. QS .. "," .. QR .. ")")
  M("QS × QR = ", x)
  local m = CC("dotP(" .. QP .. "," .. x .. ")")
  M("[QP;QS;QR] = ", m)
  R("V = ", CC("abs(" .. m .. ")"), " u.v. (unités de volume)")
  if m == "0" then A("V = 0 : QP, QS et QR sont coplanaires ! (les points P, Q, R, S sont dans un même plan)")
  else
    local nb = cas1("norm(" .. x .. ")")
    M("Hauteur (distance de P au plan QRS) = V / ||QS × QR|| = ", cas1("abs(" .. m .. ")/(" .. nb .. ")"))
    M("Volume du tétraèdre PQRS = V/6 = ", cas1("abs(" .. m .. ")/6"))
  end
  -- d) BON
  T("d) Base orthonormée directe B0 = {u, v, w}")
  local u = CC("unitV(" .. QR .. ")")
  local vv
  if CC("dotP(" .. QS .. "," .. QR .. ")") == "0" and not estNul(QS) then
    G("Observation : QS·QR = 0, donc QS ⊥ QR. On prend u = QR/||QR||, v = QS/||QS||, w = u × v (dans cet ordre : base directe).")
    vv = CC("unitV(" .. QS .. ")")
  else
    G("QS n'est pas ⊥ QR : méthode du prof v = λ·QR + μ·QS avec [1] u·v = 0 et [2] ||v|| = 1.")
    local sl = cas1("solve(dotP(" .. QR .. ",λ*" .. QR .. "+μ*" .. QS .. ")=0 and norm(λ*" .. QR .. "+μ*" .. QS .. ")=1,{λ,μ})")
    M("", sl)
    vv = CC("unitV(" .. QS .. "-dotP(" .. QS .. "," .. u .. ")*" .. u .. ")")
  end
  M("||QR|| = ", cas1("norm(" .. QR .. ")")); R("u = ", u)
  R("v = ", vv)
  local w = CC("crossP(" .. u .. "," .. vv .. ")")
  R("w = u × v = ", w)
  G("Contrôles : u·v = " .. CC("dotP(" .. u .. "," .. vv .. ")") .. " ; ||w|| = " .. cas1("norm(" .. w .. ")") .. " ; [u;v;w] = " .. CC("dotP(" .. u .. ",crossP(" .. vv .. "," .. w .. "))"))
  G("Sens contraire demandé ? Prends u = −QR/||QR|| et garde w = u × v.")
  -- e) composantes
  T("e) Composantes de QP dans B0")
  G("B0 orthonormée : composantes = produits scalaires QP·u, QP·v, QP·w (pas de système).")
  local a1, a2, a3 = cas1("dotP(" .. QP .. "," .. u .. ")"), cas1("dotP(" .. QP .. "," .. vv .. ")"), cas1("dotP(" .. QP .. "," .. w .. ")")
  M("QP·u = ", a1); M("QP·v = ", a2); M("QP·w = ", a3)
  R("QP = (" .. a1 .. " ; " .. a2 .. " ; " .. a3 .. ") dans B0", "", "")
  -- variantes
  T("Variantes (mêmes données)")
  local cr = CC("crossP(" .. QP .. "," .. QR .. ")")
  M("Aire du triangle PQR = ||QP × QR||/2 = ", cas1("norm(" .. cr .. ")/2"))
  local cosq = cas1("dotP(" .. QP .. "," .. QR .. ")/(norm(" .. QP .. ")*norm(" .. QR .. "))")
  local dg = nombre("arccos(" .. cosq .. ")*180/π")
  M("Angle PQR : cos θ = ", cosq, dg and string.format("  ≈ %.4g°", dg) or "")
  X("P, Q, R alignés ? QP × QR = " .. cr .. (estNul(cr) and " → alignés" or " → non alignés"))
  T("Base B = {QP, QR, k}, k = (0;0;1)")
  local kk = "[0,0,1]"
  local mk = cas1("dotP(" .. QP .. ",crossP(" .. QR .. "," .. kk .. "))")
  X("3 vecteurs de R³ ; [QP;QR;k] = " .. mk .. (mk ~= "0" and " ≠ 0 : linéairement indépendants → base" or " = 0 : pas une base"))
  if mk ~= "0" then
    X("Composantes de QS dans B (système, une équation par coordonnée) :")
    composantesBase(QS, {QP, QR, kk}, "QS = ")
    local n1 = cas1("norm(" .. QP .. ")"); local d1 = cas1("dotP(" .. QP .. "," .. QR .. ")"); local d2 = cas1("dotP(" .. QP .. "," .. kk .. ")")
    if n1 ~= "1" then R("B orthonormée ? ", "", "Non : ||QP|| = " .. n1 .. " ≠ 1")
    elseif d1 ~= "0" then R("B orthonormée ? ", "", "Non : QP·QR = " .. d1 .. " ≠ 0")
    elseif d2 ~= "0" then R("B orthonormée ? ", "", "Non : QP·k = " .. d2 .. " ≠ 0")
    else R("B orthonormée ? ", "", "à vérifier avec QR et k (voir menu BON)") end
  end
  memoriser(Tt); memoriser(S)
  montrer("Problème A")
end

------------------------------------------------------------------ probleme B complet (version 2)
local function definirPoints(defs)
  local P, ordre = {}, {}
  for _, d in ipairs(decouper(defs, ";")) do
    local n, e = d:match("^%s*(%u%d?'?)%s*=%s*(.-)%s*$")
    if n then
      local e2 = e
      e2 = e2:gsub("milieu%((%u%d?),(%u%d?)%)", "((%1+%2)/2)"):gsub("grav%((%u%d?),(%u%d?),(%u%d?)%)", "((%1+%2+%3)/3)")
      e2 = e2:gsub("%f[%a]u%f[%A]", "[1,0,0]"):gsub("%f[%a]v%f[%A]", "[0,1,0]"):gsub("%f[%a]w%f[%A]", "[0,0,1]")
      for m, val in pairs(P) do e2 = e2:gsub("%f[%u]" .. m .. "%f[^%w']", "(" .. val .. ")") end
      if e2 == "0" then e2 = "[0,0,0]" end
      if e2:match("^%[[^%[%]]*%]$") then e2 = pad3(e2) end
      P[n] = pad3(CC(e2)); table.insert(ordre, n)
    end
  end
  return P, ordre
end

local function enUV(vv)
  local c = comp(vv); local t = {}
  for i, nm in ipairs({"u", "v", "w"}) do
    local ci = c[i] or "0"
    if ci ~= "0" then table.insert(t, (ci == "1" and "" or (ci == "-1" and "-" or (ci .. "*"))) .. nm) end
  end
  if #t == 0 then return "0" end
  return (table.concat(t, "+"):gsub("%+%-", "-"))
end

local function reconnaitre2(total, P, ordre)
  if estNul(total) then return {"0 (vecteur nul)"} end
  local egaux, multiples = {}, {}
  for _, a in ipairs(ordre) do for _, b in ipairs(ordre) do if a ~= b then
    local ab = CC(P[b] .. "-" .. P[a])
    if estNul(CC(ab .. "-" .. total)) then table.insert(egaux, a .. b)
    elseif not estNul(ab) and estNul(CC("crossP(" .. ab .. "," .. total .. ")")) and #multiples < 4 then
      local ca, ct = comp(ab), comp(total)
      for i = 1, 3 do if ca[i] ~= "0" then
        local kq = cas1("(" .. ct[i] .. ")/(" .. ca[i] .. ")")
        if #kq <= 5 and not kq:find("%.") then table.insert(multiples, kq .. "·" .. a .. b) end
        break
      end end
    end
  end end end
  local out = {}
  if #egaux > 0 then table.insert(out, table.concat(egaux, " = ")) end
  if #multiples > 0 then table.insert(out, table.concat(multiples, " = ")) end
  return out
end

-- chaine de Chasles redigee (glouton) : retourne les soustractions, remplace par des vecteurs egaux
local function chaineChasles(termes, P, ordre)
  local chain = {}
  for _, t in ipairs(termes) do
    local a, b, coef = t.a, t.b, t.coef
    if t.signe == "-" then a, b = b, a end
    if coef == "" or coef == "1" then table.insert(chain, {a, b}) end
  end
  if #chain ~= #termes then return nil end
  local etapes = {}
  local cur = chain[1]
  for i = 2, #chain do
    local nx = chain[i]
    if nx[1] ~= cur[2] then
      local vnx = CC(P[nx[2]] .. "-" .. P[nx[1]])
      local trouve
      for _, z in ipairs(ordre) do
        if z ~= cur[2] and estNul(CC(P[z] .. "-" .. P[cur[2]] .. "-" .. vnx)) then trouve = z; break end
      end
      if not trouve then return etapes, false end
      table.insert(etapes, nx[1] .. nx[2] .. " = " .. cur[2] .. trouve .. " (vecteurs égaux)")
      nx = {cur[2], trouve}
    end
    table.insert(etapes, cur[1] .. cur[2] .. " + " .. nx[1] .. nx[2] .. " = " .. cur[1] .. nx[2] .. " (Chasles)")
    cur = {cur[1], nx[2]}
  end
  return etapes, true, cur[1] .. cur[2]
end

local function problemeB2(defs, sommes)
  vider(); T("Problème B : figure et Chasles")
  G("Rédaction du prof : retourner les vecteurs soustraits (−XY = YX), remplacer un vecteur par un vecteur égal de la figure, enchaîner Chasles XY + YZ = XZ. Avec une base (u, v) : tout exprimer en u, v puis comparer.")
  local P, ordre = definirPoints(defs)
  for _, n in ipairs(ordre) do X(n .. " = " .. enUV(P[n])) end
  for _, sm in ipairs(decouper(sommes, ";")) do
    local s = sm:gsub("%s", ""):gsub("−", "-")
    if s ~= "" then
      T(s)
      local base = s:match("^base=(.*)$")
      local para = s:match("^(%u%d?%u%d?)//(%u%d?%u%d?)$")
      if base then
        X("Base choisie pour la suite : " .. base)
        P.__base = base
      elseif para then
        local a1, b1 = para:sub(1, 1), para:sub(2)
        local v1 = vecteursNommes(s:match("^(.-)//"), P); local v2 = vecteursNommes(s:match("//(.*)$"), P)
        local c1, c2 = CC(v1), CC(v2)
        M("", s:match("^(.-)//") .. " = " .. enUV(c1)); M("", s:match("//(.*)$") .. " = " .. enUV(c2))
        local x = CC("crossP(" .. c1 .. "," .. c2 .. ")")
        R("", "", estNul(x) and "colinéaires : droites parallèles (ou points alignés)" or "non colinéaires")
      else
        local sp = s
        if sp:sub(1, 1) ~= "-" and sp:sub(1, 1) ~= "+" then sp = "+" .. sp end
        local total, ok, termes = "[0,0,0]", true, {}
        for signe, coef, X1, Y1 in sp:gmatch("([%+%-])([%d/%.]*)%*?(%u%d?)(%u%d?)") do
          if not P[X1] or not P[Y1] then A("Point inconnu : " .. (P[X1] and Y1 or X1)); ok = false; break end
          table.insert(termes, {signe = signe, coef = coef, a = X1, b = Y1})
          local vv = CC(P[Y1] .. "-" .. P[X1])
          M((signe == "-" and "−" or "+") .. coef .. X1 .. Y1 .. " = ", enUV(vv))
          total = CC(total .. signe .. (coef ~= "" and coef or "1") .. "*(" .. vv .. ")")
        end
        if ok then
          local et, fini, res = chaineChasles(termes, P, ordre)
          if et and #et > 0 then
            X("Rédaction par Chasles :")
            for _, e in ipairs(et) do M("", "", e) end
            if fini and res then R("= ", "", res) end
          end
          R("En u, v : ", enUV(total))
          for _, r in ipairs(reconnaitre2(total, P, ordre)) do R("= ", "", r) end
          if P.__base then
            local noms = decouper(P.__base, ",")
            local bv = {}
            for _, nb in ipairs(noms) do table.insert(bv, CC(vecteursNommes(nb, P))) end
            X("Dans la base (" .. P.__base .. ") :")
            composantesBase(total, bv, s .. " = ")
          end
        end
      end
    end
  end
  montrer("Problème B")
end

M1.FIGURES = FIGURES; M1.chasles = chasles; M1.nettoie = nettoie; M1.C = C; M1.problemeA = problemeA; M1.FIGB = FIGB
M1.problemeB = problemeB; M1.pad3 = pad3; M1.CC = CC; M1.estNul = estNul; M1.vecteursNommes = vecteursNommes; M1.vPoint = vPoint
M1.vColin = vColin; M1.vUnitOrtho = vUnitOrtho; M1.vNormeDonnee = vNormeDonnee; M1.composantesBase = composantesBase; M1.problemeA2 = problemeA2; M1.definirPoints = definirPoints
M1.enUV = enUV; M1.reconnaitre2 = reconnaitre2; M1.chaineChasles = chaineChasles; M1.problemeB2 = problemeB2
end
