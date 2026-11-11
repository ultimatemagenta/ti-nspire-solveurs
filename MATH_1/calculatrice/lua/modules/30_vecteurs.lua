-- 30_vecteurs.lua : vecteurs en composantes (series 4 a 6, test 2025 P2)
-- (lignes 1237-1451 de lua/solveur.lua, decoupees le 11.11.2026 ; code inchange)
do   -- bloc : limite de 200 variables locales du script principal
------------------------------------------------------------------ vecteurs (series 4 a 6, test 2025 P2)
local function vec(s)  -- "2,-1,3" | "(2;-1;3)" | "[2,-1,3]" | "[7,2,5]-[-1,-7,7]" -> "[2,-1,3]"
  s = s:gsub("%s", ""):gsub(";", ",")
  if s:find("%]") and s:find("[%]%)][%+%-%*]") or s:find("[%+%-%*/]%[") then
    local r = cas(s)
    if r then return (r:gsub("^%[%[", "["):gsub("%]%]$", "]")) end
  end
  s = s:gsub("^[%(%[{]", ""):gsub("[%)%]}]$", "")
  return "[" .. s .. "]"
end

local function comp(v)  -- "[a,b,c]" -> {"a","b","c"}
  return decouper((v:gsub("^%[+", ""):gsub("%]+$", "")), ",")
end

local function point(s)  -- "P(1;2;3)" ou "1,2,3"
  local nom, reste = s:match("^%s*(%a)%s*(%b())%s*$")
  if nom then return nom, vec(reste) end
  return "?", vec(s)
end

local function joli(v) return cas1(v) end

local function V(nom, v) M("", nom .. "=" .. v) end

-- 1. norme, unitaire
local function vNorme(u)
  u = vec(u); vider(); T("Norme et vecteur unitaire")
  G("Formule : ||u|| = √(u₁² + u₂² + u₃²) (CRM p.51). Le vecteur unitaire û = u/||u|| a la même direction et le même sens, et une norme 1.")
  V("u", u)
  local c = comp(u)
  local sq = {}
  for _, x in ipairs(c) do table.insert(sq, "(" .. x .. ")^2") end
  M("||u|| = ", "sqrt(" .. table.concat(sq, "+") .. ")=" .. cas1("norm(" .. u .. ")"))
  R("û = ", cas1("unitV(" .. u .. ")"))
  montrer("Norme")
end

-- 2. produit scalaire, angle
local function vScalaire(u, v)
  u, v = vec(u), vec(v); vider(); T("Produit scalaire et angle")
  G("Formules : u·v = u₁v₁ + u₂v₂ + u₃v₃ et cos θ = u·v / (||u||·||v||). u·v = 0 ⇔ u ⊥ v.")
  V("u", u); V("v", v)
  local a, b = comp(u), comp(v)
  local t = {}
  for i = 1, #a do table.insert(t, "(" .. a[i] .. ")*(" .. b[i] .. ")") end
  local ps = cas1("dotP(" .. u .. "," .. v .. ")")
  M("u·v = ", table.concat(t, "+") .. "=" .. ps)
  if ps == "0" then R("u·v = 0 : ", "", "u et v sont orthogonaux") end
  local nu, nv = cas1("norm(" .. u .. ")"), cas1("norm(" .. v .. ")")
  M("||u|| = ", nu); M("||v|| = ", nv)
  local c = cas1("(" .. ps .. ")/((" .. nu .. ")*(" .. nv .. "))")
  M("cos θ = ", "(" .. ps .. ")/((" .. nu .. ")*(" .. nv .. "))=" .. c)
  local deg_ = nombre("arccos(" .. c .. ")*180/π")
  local rad_ = cas1("arccos(" .. c .. ")")
  R("θ = ", rad_, deg_ and string.format("  ≈ %.4g°", deg_) or "")
  memoriser(ps)
  montrer("Angle")
end

-- 3. projection orthogonale d'un point sur une droite (A, B) : test 2025 P2 a
local function vProjPoint(Ps, As, Bs)
  local nP, P = point(Ps); local nA, A0 = point(As); local nB, B0 = point(Bs)
  vider(); T("Projection orthogonale d'un point sur une droite")
  G("Méthode : T = A + k·AB, avec k = AP·AB / ||AB||². Pourquoi : la projection de AP sur la direction AB, puis on part de A.")
  V(nP, P); V(nA, A0); V(nB, B0)
  local u = cas1(B0 .. "-" .. A0)
  local ap = cas1(P .. "-" .. A0)
  V(nA .. nB, u); V(nA .. nP, ap)
  local ps, n2 = cas1("dotP(" .. ap .. "," .. u .. ")"), cas1("dotP(" .. u .. "," .. u .. ")")
  M("", nA .. nP .. "·" .. nA .. nB .. "=" .. ps)
  M("", "||" .. nA .. nB .. "||^2=" .. n2)
  local k = cas1("(" .. ps .. ")/(" .. n2 .. ")")
  M("k = ", "(" .. ps .. ")/(" .. n2 .. ")=" .. k)
  local T0 = cas1(A0 .. "+(" .. k .. ")*" .. u)
  R("T = " .. nA .. " + k·" .. nA .. nB .. " = ", T0)
  local PT = cas1(T0 .. "-" .. P)
  G("Contrôle : PT·" .. nA .. nB .. " = " .. cas1("dotP(" .. PT .. "," .. u .. ")") .. " (doit être 0)")
  M("distance P–droite = ||PT|| = ", cas1("norm(" .. PT .. ")"))
  memoriser(T0)
  montrer("Projection")
end

-- 4. projection d'un vecteur v sur u
local function vProjVect(v, u)
  v, u = vec(v), vec(u); vider(); T("Projection orthogonale de v sur u")
  G("Formule : proj_u(v) = (v·u / ||u||²)·u. On divise par ||u||² : une fois pour rendre u unitaire, une fois pour la mesure.")
  V("v", v); V("u", u)
  local ps, n2 = cas1("dotP(" .. v .. "," .. u .. ")"), cas1("dotP(" .. u .. "," .. u .. ")")
  M("v·u = ", ps); M("||u||² = ", n2)
  R("proj = ", cas1("(" .. ps .. ")/(" .. n2 .. ")*" .. u))
  montrer("Projection")
end

-- 5. produit vectoriel
local function vVectoriel(u, v)
  u, v = vec(u), vec(v)
  if #comp(u) == 2 then u = u:gsub("%]$", ",0]") end
  if #comp(v) == 2 then v = v:gsub("%]$", ",0]") end
  vider(); T("Produit vectoriel")
  G("Formule (déterminants 2×2 en croix) : u×v = (u₂v₃ − u₃v₂ ; u₃v₁ − u₁v₃ ; u₁v₂ − u₂v₁). u×v est orthogonal à u et à v ; ||u×v|| = aire du parallélogramme.")
  V("u", u); V("v", v)
  local a, b = comp(u), comp(v)
  M("x : ", "(" .. a[2] .. ")*(" .. b[3] .. ")-(" .. a[3] .. ")*(" .. b[2] .. ")")
  M("y : ", "(" .. a[3] .. ")*(" .. b[1] .. ")-(" .. a[1] .. ")*(" .. b[3] .. ")")
  M("z : ", "(" .. a[1] .. ")*(" .. b[2] .. ")-(" .. a[2] .. ")*(" .. b[1] .. ")")
  local w = cas1("crossP(" .. u .. "," .. v .. ")")
  R("u×v = ", w)
  G("Contrôles : (u×v)·u = " .. cas1("dotP(" .. w .. "," .. u .. ")") .. " ; (u×v)·v = " .. cas1("dotP(" .. w .. "," .. v .. ")"))
  R("Aire du parallélogramme = ||u×v|| = ", cas1("norm(" .. w .. ")"))
  R("Aire du triangle = ", cas1("norm(" .. w .. ")/2"))
  memoriser(w)
  montrer("Produit vectoriel")
end

-- 6. produit mixte, volume, coplanarite (avec parametre eventuel)
local function vMixte(a, b, c)
  a, b, c = vec(a), vec(b), vec(c); vider(); T("Produit mixte")
  G("Définition : [a;b;c] = a·(b×c). Volume du parallélépipède = |[a;b;c]| ; [a;b;c] = 0 ⇔ a, b, c coplanaires ; > 0 : base directe.")
  V("a", a); V("b", b); V("c", c)
  local bc = cas1("crossP(" .. b .. "," .. c .. ")")
  M("b×c = ", bc)
  local m = cas1("expand(dotP(" .. a .. "," .. bc .. "))")
  R("[a;b;c] = a·(b×c) = ", m)
  local p = nil
  for _, l in ipairs({"m", "t", "k", "λ", "x", "y", "z", "a"}) do if m:find("%f[%a]" .. l .. "%f[%A]") or (l == "λ" and m:find(l, 1, true)) then p = l end end
  if p then
    X("Coplanaires ⇔ [a;b;c] = 0 :")
    R("", cas1("solve(" .. m .. "=0," .. p .. ")"))
  else
    R("Volume du parallélépipède = ", cas1("abs(" .. m .. ")"))
    R("Volume du tétraèdre = ", cas1("abs(" .. m .. ")/6"))
    X(m == "0" and "Coplanaires : pas une base." or ((nombre(m) or 0) > 0 and "Base directe." or "Base indirecte."))
  end
  montrer("Produit mixte")
end

-- 7. trouver un parametre : orthogonalite / colinearite
local function vParam(u, v, cond)
  u, v = vec(u), vec(v); vider(); T("Trouver le paramètre")
  V("u", u); V("v", v)
  local p = nil
  for _, l in ipairs({"x", "t", "m", "k", "λ", "a"}) do if (u .. v):find(l, 1, true) then p = l; break end end
  if cond == "o" then
    G("u ⊥ v ⇔ u·v = 0 : on obtient une équation en " .. (p or "?") .. ".")
    local ps = cas1("expand(dotP(" .. u .. "," .. v .. "))")
    M("u·v = ", ps .. "=0")
    R("", cas1("solve(" .. ps .. "=0," .. p .. ")"))
  else
    G("u et v colinéaires ⇔ u×v = 0 (les 3 composantes nulles).")
    local w = cas1("crossP(" .. u .. "," .. v .. ")")
    M("u×v = ", w)
    local c = comp(w)
    R("", cas1("solve(" .. c[1] .. "=0 and " .. c[2] .. "=0 and " .. c[3] .. "=0," .. p .. ")"))
  end
  montrer("Paramètre")
end

-- 8. composantes dans une base (test 2025 P2 b iii)
local function vComposantes(w, b1, b2, b3)
  w, b1, b2, b3 = vec(w), vec(b1), vec(b2), vec(b3)
  vider(); T("Composantes dans une base")
  G("On cherche α, β, γ tels que w = α·b₁ + β·b₂ + γ·b₃ : une équation par coordonnée, puis on résout le système 3×3.")
  V("w", w); V("b₁", b1); V("b₂", b2); V("b₃", b3)
  local W, A1, A2, A3 = comp(w), comp(b1), comp(b2), comp(b3)
  local eqs, noms = {}, {"x", "y", "z"}
  for i = 1, 3 do
    local e = "(" .. A1[i] .. ")*α+(" .. A2[i] .. ")*β+(" .. A3[i] .. ")*γ=" .. W[i]
    M(noms[i] .. " : ", cas1("expand((" .. A1[i] .. ")*α+(" .. A2[i] .. ")*β+(" .. A3[i] .. ")*γ)") .. "=" .. W[i])
    table.insert(eqs, e)
  end
  R("", cas1("solve(" .. table.concat(eqs, " and ") .. ",{α,β,γ})"))
  montrer("Composantes")
end

-- 9. base orthonormee ? directe ?
local function vBON(a, b, c)
  a, b, c = vec(a), vec(b), vec(c); vider(); T("Base orthonormée directe ?")
  G("Orthonormée : chaque vecteur de norme 1 (normée) et produits scalaires nuls 2 à 2 (orthogonale). Directe : [a;b;c] > 0.")
  V("a", a); V("b", b); V("c", c)
  local ok = true
  for _, x in ipairs({{"a", a}, {"b", b}, {"c", c}}) do
    local n = cas1("norm(" .. x[2] .. ")")
    M("||" .. x[1] .. "|| = ", n, n == "1" and "  ✓" or "  ✗"); ok = ok and n == "1"
  end
  for _, x in ipairs({{"a·b", a, b}, {"a·c", a, c}, {"b·c", b, c}}) do
    local d = cas1("dotP(" .. x[2] .. "," .. x[3] .. ")")
    M(x[1] .. " = ", d, d == "0" and "  ✓" or "  ✗"); ok = ok and d == "0"
  end
  local m = cas1("dotP(" .. a .. ",crossP(" .. b .. "," .. c .. "))")
  M("[a;b;c] = ", m)
  if ok and m == "1" then R("", "", "Base orthonormée directe") elseif ok then R("", "", "Orthonormée mais indirecte")
  else A("Pas orthonormée (voir les ✗).") end
  montrer("BON")
end

-- 10. construire une BON directe (test 2025 P2 c)
local function vConstruire(a, b)
  a, b = vec(a), vec(b); vider(); T("Construire une base orthonormée directe")
  G("Méthode : u = a/||a|| ; v = vecteur unitaire orthogonal à u (ici b/||b|| si a·b = 0) ; w = u × v (dans cet ordre, pour une base directe).")
  V("a", a); V("b", b)
  local ps = cas1("dotP(" .. a .. "," .. b .. ")")
  M("a·b = ", ps)
  if ps ~= "0" then
    A("a·b ≠ 0 : on remplace b par sa composante orthogonale à a.")
    b = cas1(b .. "-(" .. ps .. ")/dotP(" .. a .. "," .. a .. ")*" .. a)
    V("b'", b)
  end
  local u, v = cas1("unitV(" .. a .. ")"), cas1("unitV(" .. b .. ")")
  R("u = a/||a|| = ", u); R("v = b/||b|| = ", v)
  R("w = u × v = ", cas1("crossP(" .. u .. "," .. v .. ")"))
  G("Contrôle : [u;v;w] = " .. cas1("dotP(" .. u .. ",crossP(" .. v .. ",crossP(" .. u .. "," .. v .. ")))"))
  montrer("Construction BON")
end

M1.vec = vec; M1.comp = comp; M1.point = point; M1.joli = joli; M1.V = V; M1.vNorme = vNorme
M1.vScalaire = vScalaire; M1.vProjPoint = vProjPoint; M1.vProjVect = vProjVect; M1.vVectoriel = vVectoriel; M1.vMixte = vMixte; M1.vParam = vParam
M1.vComposantes = vComposantes; M1.vBON = vBON; M1.vConstruire = vConstruire
end
