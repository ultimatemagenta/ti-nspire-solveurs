-- 70_nouveaux.lua : solveurs ajoutes le 11.11.2026 (etude tools/nspire/ETUDE-CHOIX-SOLVEUR.md, section 5)
--   aireFigure     : aire d'une figure sur quadrillage (test 2025 P3 c ; VARIANTES-AB.md § 6, B23)
--   minMaxTrinome  : minimum et maximum d'un trinome sur des intervalles (serie 7 ex.6)
-- Calcul exact en fractions, sans CAS (donc aussi verifiable sur PC avec tools/nspire/test_pc.py).
do   -- bloc : limite de 200 variables locales du script principal

------------------------------------------------------------------ fractions exactes
local function pgcd(a, b) a, b = math.abs(a), math.abs(b); while b ~= 0 do a, b = b, a % b end; return a end
local function Q(n, d)
  d = d or 1
  if d < 0 then n, d = -n, -d end
  local g = pgcd(n, d)
  if g > 1 then n, d = n / g, d / g end
  return {n = n, d = d}
end
local function qadd(a, b) return Q(a.n * b.d + b.n * a.d, a.d * b.d) end
local function qsub(a, b) return Q(a.n * b.d - b.n * a.d, a.d * b.d) end
local function qmul(a, b) return Q(a.n * b.n, a.d * b.d) end
local function qdiv(a, b) return Q(a.n * b.d, a.d * b.n) end
local function qcmp(a, b) local x = a.n * b.d - b.n * a.d; return x > 0 and 1 or (x < 0 and -1 or 0) end
local function qtxt(a) if a.d == 1 then return string.format("%d", a.n) end; return string.format("%d/%d", a.n, a.d) end
local function qpar(a) if a.n < 0 or a.d ~= 1 then return "(" .. qtxt(a) .. ")" end; return qtxt(a) end  -- facteur ou base d'une puissance
local function qneg(a) if a.n < 0 then return "(" .. qtxt(a) .. ")" end; return qtxt(a) end           -- terme apres « + » ou « · »
local function qabs(a) return Q(math.abs(a.n), a.d) end

-- "3", "-1/2", "0.25", "+2" -> fraction (nil si illisible)
local function lireQ(s)
  s = tostring(s or ""):gsub("%s", ""):gsub("−", "-"):gsub("^%((.*)%)$", "%1")
  local n, d = s:match("^([%+%-]?%d+)/(%d+)$")
  if n and tonumber(d) ~= 0 then return Q(tonumber(n), tonumber(d)) end
  if s:match("^[%+%-]?%d+$") then return Q(tonumber(s)) end
  local sg, e, f = s:match("^([%+%-]?)(%d*)%.(%d+)$")
  if sg then
    local den = 10 ^ #f
    local v = (tonumber(e ~= "" and e or "0") * den + tonumber(f)) * (sg == "-" and -1 or 1)
    return Q(v, den)
  end
  return nil
end

------------------------------------------------------------------ aire d'une figure sur quadrillage
-- points : "A=-1,4;B=1,4;…" (ou A(-1;4)) ; pieces : "4*par(A,B,G)-2*tri(A,B,E)" ; contour : "A,B,C,I,H,G-E,D,J,F" (trous apres -)
local function lirePoints(txt)
  local P, ordre = {}, {}
  for _, d in ipairs(decouper(tostring(txt or ""):gsub("%s", ""), ";")) do
    if d ~= "" then
      local nom, co = d:match("^(%u%d*'?)=?%((.-)%)$")
      if not nom then nom, co = d:match("^(%u%d*'?)=(.+)$") end
      if not nom then return nil, "point illisible : « " .. d .. " » (exemple : A=-1,4)" end
      co = co:gsub("^%[", ""):gsub("%]$", "")
      local xs, ys, zs = co:match("^([^,;]+)[,;]([^,;]+)[,;]?([^,;]*)$")
      local x, y = lireQ(xs), lireQ(ys)
      if not (x and y) then return nil, "coordonnées illisibles pour " .. nom .. " : « " .. co .. " »" end
      if zs and zs ~= "" and not (lireQ(zs) and lireQ(zs).n == 0) then
        return nil, "figure plane seulement (point " .. nom .. " : 3e coordonnée non nulle)"
      end
      if not P[nom] then table.insert(ordre, nom) end
      P[nom] = {x = x, y = y}
    end
  end
  return P, ordre
end

local function nomDuPoint(P, ordre, x, y)
  for _, n in ipairs(ordre) do if qcmp(P[n].x, x) == 0 and qcmp(P[n].y, y) == 0 then return n end end
  return nil
end

local function aireLacets(P, noms)    -- 2 * aire signee (formule des lacets)
  local s = Q(0)
  for i = 1, #noms do
    local a, b = P[noms[i]], P[noms[i % #noms + 1]]
    s = qadd(s, qsub(qmul(a.x, b.y), qmul(b.x, a.y)))
  end
  return s
end

local function aireFigure(ptsTxt, piecesTxt, contourTxt)
  vider(); T("Aire d'une figure sur quadrillage")
  local P, ordre = lirePoints(ptsTxt)
  if not P then A(ordre); montrer("Aire"); return end
  G("Méthode du prof (test 2025 P3 c) : décomposer la figure en parallélogrammes et triangles, puis "
    .. "aire d'un parallélogramme XYZW = ||XY × XZ|| et aire d'un triangle XYZ = 1/2·||XY × XZ|| (poly, Prop. 1.13). "
    .. "En 2D : XY × XZ = (0 ; 0 ; x1·y2 − y1·x2). Unité : u.a. (1 carré = 1 unité).")
  local pts = {}
  for _, n in ipairs(ordre) do table.insert(pts, n .. "(" .. qtxt(P[n].x) .. " ; " .. qtxt(P[n].y) .. ")") end
  X("Points lus sur le quadrillage : " .. table.concat(pts, "  "))
  local total, morceaux, deja, formule, formule2 = nil, {}, {}, {}, {}
  local s = tostring(piecesTxt or ""):gsub("%s", ""):gsub("−", "-")
  if s ~= "" then
    if s:sub(1, 1) ~= "-" and s:sub(1, 1) ~= "+" then s = "+" .. s end
    local lu = s:gsub("([%+%-])([%d/%.]*)%*?(%a+)%((%u%d*'?),(%u%d*'?),(%u%d*'?)%)", "")
    if lu ~= "" then A("Décomposition illisible près de « " .. lu .. " ». Exemple : 4*par(A,B,G)-2*tri(A,B,E)"); montrer("Aire"); return end
    total = Q(0)
    local vus = {}
    local function vect(X1, Y1)
      local cle = X1 .. Y1
      local v = {x = qsub(P[Y1].x, P[X1].x), y = qsub(P[Y1].y, P[X1].y)}
      if not vus[cle] then
        vus[cle] = true
        M("", cle .. "=[" .. qtxt(P[Y1].x) .. "-" .. qpar(P[X1].x) .. "," .. qtxt(P[Y1].y) .. "-" .. qpar(P[X1].y) .. "]=["
          .. qtxt(v.x) .. "," .. qtxt(v.y) .. "]")
      end
      return v
    end
    for sg, k, typ, X1, Y1, Z1 in s:gmatch("([%+%-])([%d/%.]*)%*?(%a+)%((%u%d*'?),(%u%d*'?),(%u%d*'?)%)") do
      typ = typ:lower()
      if typ ~= "par" and typ ~= "tri" then A("Morceau inconnu « " .. typ .. " » : par(…) = parallélogramme, tri(…) = triangle"); montrer("Aire"); return end
      for _, n in ipairs({X1, Y1, Z1}) do
        if not P[n] then A("Point inconnu : " .. n); montrer("Aire"); return end
      end
      local coef = lireQ(k ~= "" and k or "1")
      if not coef then A("Coefficient illisible : " .. k); montrer("Aire"); return end
      if sg == "-" then coef = qsub(Q(0), coef) end
      local nomM
      if typ == "par" then
        local W = nomDuPoint(P, ordre, qsub(qadd(P[Y1].x, P[Z1].x), P[X1].x), qsub(qadd(P[Y1].y, P[Z1].y), P[X1].y))
        nomM = X1 .. Y1 .. (W or "?") .. Z1
      else nomM = X1 .. Y1 .. Z1 end
      local cle = typ .. X1 .. Y1 .. Z1
      local aire = deja[cle]
      if not aire then
        local u, v = vect(X1, Y1), vect(X1, Z1)
        local det = qsub(qmul(u.x, v.y), qmul(u.y, v.x))
        X("||" .. X1 .. Y1 .. " × " .. X1 .. Z1 .. "|| = |" .. qneg(u.x) .. "·" .. qneg(v.y) .. " − " .. qneg(u.y) .. "·" .. qneg(v.x)
          .. "| = |" .. qtxt(det) .. "| = " .. qtxt(qabs(det)))
        aire = qabs(det)
        if typ == "tri" then aire = qmul(aire, Q(1, 2)) end
        deja[cle] = aire
        R("Aire(" .. nomM .. ") = ", (typ == "tri" and ("1/2*" .. qtxt(qabs(det)) .. "=") or "") .. qtxt(aire), " u.a.")
      end
      total = qadd(total, qmul(coef, aire))
      local c = qtxt(qabs(coef))
      local signe = (#formule == 0) and (coef.n < 0 and "−" or "") or (coef.n < 0 and " − " or " + ")
      table.insert(formule, signe .. (c == "1" and "" or c) .. "Aire(" .. nomM .. ")")
      table.insert(formule2, (#formule2 == 0 and (coef.n < 0 and "-" or "") or (coef.n < 0 and "-" or "+"))
        .. (c == "1" and "" or (c .. "*")) .. qpar(aire))
      table.insert(morceaux, nomM)
    end
    X("Aire totale = " .. table.concat(formule))
    R("Aire totale = ", table.concat(formule2) .. "=" .. qtxt(total), " u.a.")
    if total.n < 0 then A("Total négatif : vérifier les signes de la décomposition.") end
  end
  -- controle : formule des lacets sur le contour (trous apres « - »)
  local c = tostring(contourTxt or ""):gsub("%s", "")
  if c ~= "" then
    T(total and "Contrôle : formule des lacets" or "Aire par la formule des lacets")
    G("Aire = 1/2·|somme des (xi·y(i+1) − x(i+1)·yi)| en parcourant le contour dans l'ordre ; les trous (après « - ») sont retranchés.")
    local parts = decouper(c, "-")
    local res = Q(0)
    for i, part in ipairs(parts) do
      local noms = {}
      for n in part:gmatch("[^,;]+") do
        if not P[n] then A("Point inconnu dans le contour : " .. n); montrer("Aire"); return end
        table.insert(noms, n)
      end
      if #noms < 3 then A("Contour de moins de 3 points : « " .. part .. " »"); montrer("Aire"); return end
      local a = qmul(qabs(aireLacets(P, noms)), Q(1, 2))
      X((i == 1 and "Contour " or "Trou ") .. table.concat(noms) .. " : Aire = " .. qtxt(a) .. " u.a.")
      if i == 1 then res = a else res = qsub(res, a) end
    end
    if total then
      R("Lacets : Aire = ", qtxt(res), " u.a." .. (qcmp(res, total) == 0 and "  ✓ (même aire)" or "  ✗ différent de la décomposition"))
    else
      R("Aire = ", qtxt(res), " u.a.")
      G("Au test, rédiger par décomposition (||XY × XZ||) : c'est la méthode notée par le prof.")
    end
  end
  if not total and c == "" then A("Rien à calculer : donner une décomposition ou un contour.") end
  montrer("Aire")
end

------------------------------------------------------------------ min et max d'un trinome sur des intervalles
-- f : "x^2+x+2" (ou "a,b,c") ; intervalles : "R;[-1,1];[-3,-2]" (bornes inf, ]a,b[ ouvert)
local function lireTrinome(s)
  s = tostring(s or ""):gsub("%s", ""):gsub("−", "-"):gsub("²", "^2"):gsub("%*", ""):gsub("^f%(x%)=", ""):gsub("^y=", "")
  local a, b, c = s:match("^([^,;]+)[,;]([^,;]+)[,;]([^,;]+)$")
  if a then
    a, b, c = lireQ(a), lireQ(b), lireQ(c)
    if a and b and c then return a, b, c end
    return nil
  end
  if s:sub(1, 1) ~= "-" and s:sub(1, 1) ~= "+" then s = "+" .. s end
  local co = {Q(0), Q(0), Q(0)}
  local reste = s:gsub("([%+%-])([^%+%-]+)", function(sg, t)
    local k, p = t:match("^(.-)x%^2$"), 3
    if not k then k, p = t:match("^(.-)x$"), 2 end
    if not k then k, p = t, 1 end
    k = k:gsub("^%((.*)%)$", "%1")
    if p > 1 and k == "" then k = "1" end
    local q = lireQ(k)
    if not q then return nil end
    if sg == "-" then q = qsub(Q(0), q) end
    co[p] = qadd(co[p], q)
    return ""
  end)
  if reste ~= "" then return nil end
  return co[3], co[2], co[1]
end

local function lireIntervalles(s)
  s = tostring(s or ""):gsub("%s", ""):gsub("−", "-"):gsub("∞", "inf"):gsub("ℝ", "R")
  local out, i = {}, 1
  while i <= #s do
    local ch = s:sub(i, i)
    if ch == "R" then table.insert(out, {g = nil, d = nil, gf = false, df = false, txt = "ℝ"}); i = i + 1
    elseif ch == "[" or ch == "]" then
      local o, ga, dr, f = s:match("^([%[%]])([^,;%[%]]+)[,;]([^%[%]]+)([%[%]])", i)
      if not o then return nil, "intervalle illisible près de « " .. s:sub(i) .. " »" end
      local function borne(t)
        if t == "-inf" or t == "+inf" or t == "inf" then return nil end
        return lireQ(t) or false
      end
      local g, d = borne(ga), borne(dr)
      if g == false or d == false then return nil, "borne illisible dans « " .. o .. ga .. "," .. dr .. f .. " »" end
      if g and d and qcmp(g, d) > 0 then return nil, "borne gauche > borne droite dans « " .. o .. ga .. "," .. dr .. f .. " »" end
      local it = {g = g, d = d, gf = (o == "[") and g ~= nil, df = (f == "]") and d ~= nil}
      it.txt = (it.gf and "[" or "]") .. (g and qtxt(g) or "−∞") .. " ; " .. (d and qtxt(d) or "+∞") .. (it.df and "]" or "[")
      table.insert(out, it)
      i = i + #o + #ga + 1 + #dr + #f
    else i = i + 1 end
  end
  if #out == 0 then return nil, "aucun intervalle (exemples : R ; [-1,1] ; ]0,+inf[)" end
  return out
end

local function minMaxTrinome(fTxt, intTxt)
  vider(); T("Minimum et maximum d'un trinôme")
  local a, b, c = lireTrinome(fTxt)
  if not a then A("f illisible : taper par exemple x^2+x+2 (ou les coefficients 1,1,2)."); montrer("Min et max"); return end
  if a.n == 0 then A("a = 0 : ce n'est pas un trinôme du 2e degré (f est affine : extrema aux bornes seulement)."); montrer("Min et max"); return end
  local I, err = lireIntervalles(intTxt)
  if not I then A(err); montrer("Min et max"); return end
  local function f(x) return qadd(qadd(qmul(a, qmul(x, x)), qmul(b, x)), c) end
  local function terme(k, corps, premier)       -- k·corps avec signe, coefficient 1 omis
    if k.n == 0 then return "" end
    local s = (k.n < 0) and "-" or (premier and "" or "+")
    local ka = qabs(k)
    if corps == "" then return s .. qtxt(ka) end
    if qcmp(ka, Q(1)) == 0 then return s .. corps end
    return s .. qtxt(ka) .. "*" .. corps
  end
  local function ftxt(var) local t = terme(a, var .. "^2", true) .. terme(b, var, false) .. terme(c, "", false); return t end
  local function calc(x)       -- "f(x0)=… = valeur"
    local xp = qpar(x)
    return "f(" .. qtxt(x) .. ")=" .. ftxt(xp) .. "=" .. qtxt(f(x))
  end
  M("f(x) = ", ftxt("x"))
  G("Méthode du prof (S7 ex.6) : propriétés du trinôme ax² + bx + c (sens de la parabole, sommet), puis pour chaque intervalle : "
    .. "le sommet est-il dans l'intervalle ? valeurs aux bornes ; conclusion. Un schéma de la parabole aide (il est noté).")
  local haut = a.n > 0
  X("a = " .. qtxt(a) .. (haut and " > 0 : parabole tournée vers le haut (« pointe en bas ») : le sommet est le minimum."
    or " < 0 : parabole tournée vers le bas (« pointe en haut ») : le sommet est le maximum."))
  local xs = qdiv(qsub(Q(0), b), qmul(Q(2), a))
  local ys = f(xs)
  M("x_S = ", "-b/(2a)=-" .. qpar(b) .. "/(2*" .. qpar(a) .. ")=" .. qtxt(xs))
  M("", calc(xs))
  R("Sommet S", "(" .. qtxt(xs) .. " ; " .. qtxt(ys) .. ")")
  X("f est " .. (haut and "décroissante" or "croissante") .. " sur ]−∞ ; " .. qtxt(xs) .. "] et "
    .. (haut and "croissante" or "décroissante") .. " sur [" .. qtxt(xs) .. " ; +∞[.")
  local lettres = "abcdefghij"
  for k, it in ipairs(I) do
    T(lettres:sub(k, k) .. ") sur " .. it.txt)
    -- candidats : sommet s'il est dans I, bornes finies (atteintes si fermees)
    local dedans = (it.g == nil or qcmp(xs, it.g) > 0 or (it.gf and qcmp(xs, it.g) == 0))
      and (it.d == nil or qcmp(xs, it.d) < 0 or (it.df and qcmp(xs, it.d) == 0))
    local aDroite = (it.g ~= nil) and qcmp(xs, it.g) <= 0      -- intervalle a droite du sommet
    X("x_S = " .. qtxt(xs) .. (dedans and " ∈ " or " ∉ ") .. it.txt
      .. (dedans and "" or (" : f est " .. ((aDroite == haut) and "croissante" or "décroissante") .. " sur cet intervalle.")))
    local att, lim = {}, {}      -- att : valeurs atteintes {x, v, quoi} ; lim : valeurs approchees non atteintes
    if dedans then table.insert(att, {x = xs, v = ys, sommet = true}) end
    for _, bo in ipairs({{it.g, it.gf, "gauche"}, {it.d, it.df, "droite"}}) do
      local x0, ferme = bo[1], bo[2]
      if x0 then
        local v = f(x0)
        M("", calc(x0))
        if ferme then table.insert(att, {x = x0, v = v}) else
          table.insert(lim, {v = v, txt = "f(" .. qtxt(x0) .. ") = " .. qtxt(v) .. " (borne exclue : valeur non atteinte)"}) end
      else
        table.insert(lim, {inf = true, txt = "f(x) → " .. (haut and "+∞" or "−∞") .. " quand x → " .. (bo[3] == "gauche" and "−∞" or "+∞")})
      end
    end
    for _, l in ipairs(lim) do if not l.inf and l.txt:find("exclue") then G(l.txt) end end
    local function conclure(estMax)
      local best
      for _, p in ipairs(att) do
        if not best or (estMax and qcmp(p.v, best.v) > 0) or (not estMax and qcmp(p.v, best.v) < 0) then best = p end
      end
      local nom = estMax and "maximum" or "minimum"
      local pire        -- borne exclue la plus extreme (valeur approchee, non atteinte)
      for _, l in ipairs(lim) do
        if l.inf then
          if haut == estMax then X("Il n'y a pas de " .. nom .. " (" .. l.txt .. ")."); return end
        elseif not pire or (estMax and qcmp(l.v, pire.v) > 0) or (not estMax and qcmp(l.v, pire.v) < 0) then pire = l end
      end
      if pire and (not best or (estMax and qcmp(pire.v, best.v) > 0) or (not estMax and qcmp(pire.v, best.v) < 0)) then
        X("Il n'y a pas de " .. nom .. " : la valeur " .. pire.txt:gsub(" %(borne exclue.*", "") .. " est approchée sans être atteinte (borne exclue).")
        return
      end
      if not best then X("Il n'y a pas de " .. nom .. "."); return end
      if best.sommet then
        R("", "", "Il y a un " .. nom .. " (global) en (" .. qtxt(best.x) .. " ; " .. qtxt(best.v) .. ")")
      else
        R("", "", "Il y a un " .. nom .. " (local) en x = " .. qtxt(best.x) .. ", de valeur f(" .. qtxt(best.x) .. ") = " .. qtxt(best.v))
      end
    end
    conclure(true)
    conclure(false)
  end
  G("Le prof appelle « local » un extremum atteint à une borne : c'est aussi la plus grande (ou la plus petite) valeur de f sur l'intervalle.")
  montrer("Min et max")
end

M1.aireFigure = aireFigure; M1.minMaxTrinome = minMaxTrinome; M1.lireQ = lireQ
end
