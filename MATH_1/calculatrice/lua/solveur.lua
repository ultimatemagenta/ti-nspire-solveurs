-- solveur.lua : solveur pas a pas MATH_1 (TI-Nspire CX II, Lua + CAS)
-- Socle : menus a fleches, saisie avec historique, visionneuse avec maths 2D.
platform.apiLevel = '2.4'

------------------------------------------------------------------ CAS
local function cas(expr)
  local ok, r, err = pcall(math.evalStr, expr)
  if not ok then return nil, tostring(r) end
  if r == nil then return nil, tostring(err) end
  r = r:gsub("\226\136\146", "-"):gsub("\226\129\187", "-")  -- signes moins unicode -> -
  r = r:gsub("\226\136\154(%d+)", "sqrt(%1)"):gsub("\226\136\154", "sqrt")  -- √ -> sqrt
  return r
end

local function cas1(expr)  -- resultat ou chaine d'erreur visible
  local r, e = cas(expr)
  return r or ("?(" .. tostring(e) .. ")")
end

------------------------------------------------------------------ rendu 2D
-- Arbre : {t="num"|"var"|"op"|"neg"|"frac"|"pow"|"sqrt"|"fn"|"par"|"list"|"txt", ...}
local function tokens(s)
  local t, i = {}, 1
  s = s:gsub("%s+", " ")
  while i <= #s do
    local c = s:sub(i, i)
    if c == " " then i = i + 1
    elseif s:sub(i, i + 2) == "\226\136\154" then table.insert(t, {"sqrt"}); i = i + 3      -- √
    elseif s:sub(i, i + 2) == "\226\136\158" then table.insert(t, {"id", "∞"}); i = i + 3   -- ∞
    elseif s:sub(i, i + 2) == "\226\137\160" then table.insert(t, {"rel", "≠"}); i = i + 3
    elseif s:sub(i, i + 2) == "\226\137\164" then table.insert(t, {"rel", "≤"}); i = i + 3
    elseif s:sub(i, i + 2) == "\226\137\165" then table.insert(t, {"rel", "≥"}); i = i + 3
    elseif c:match("[%d%.]") then
      local j = i
      while j <= #s and s:sub(j, j):match("[%d%.]") do j = j + 1 end
      table.insert(t, {"num", s:sub(i, j - 1)}); i = j
    elseif c:match("[%a_]") then
      local j = i
      while j <= #s and s:sub(j, j):match("[%w_]") do j = j + 1 end
      local w = s:sub(i, j - 1)
      if w == "and" or w == "or" then table.insert(t, {"rel", " " .. w .. " "})
      else table.insert(t, {"id", w}) end
      i = j
    elseif c == "<" or c == ">" or c == "=" then
      if s:sub(i + 1, i + 1) == "=" then table.insert(t, {"rel", c .. "="}); i = i + 2
      else table.insert(t, {"rel", c}); i = i + 1 end
    elseif c:byte() >= 128 then  -- autre caractere UTF-8 : texte brut
      local n = c:byte() >= 240 and 4 or (c:byte() >= 224 and 3 or 2)
      table.insert(t, {"id", s:sub(i, i + n - 1)}); i = i + n
    else table.insert(t, {"op", c}); i = i + 1 end
  end
  return t
end

local P = {}
function P.new(s) return {t = tokens(s), i = 1} end
local function voir(p) return p.t[p.i] end
local function prendre(p) p.i = p.i + 1; return p.t[p.i - 1] end

local expr
local function atome(p)
  local k = voir(p)
  if not k then return {t = "txt", v = ""} end
  if k[1] == "num" then prendre(p); return {t = "num", v = k[2]} end
  if k[1] == "sqrt" then
    prendre(p)
    if voir(p) and voir(p)[2] == "(" then prendre(p); local e = expr(p); if voir(p) and voir(p)[2] == ")" then prendre(p) end; return {t = "sqrt", a = e} end
    return {t = "sqrt", a = atome(p)}
  end
  if k[1] == "id" then
    prendre(p)
    if voir(p) and voir(p)[2] == "(" then
      prendre(p); local args = {}
      if not (voir(p) and voir(p)[2] == ")") then
        table.insert(args, expr(p))
        while voir(p) and voir(p)[2] == "," do prendre(p); table.insert(args, expr(p)) end
      end
      if voir(p) and voir(p)[2] == ")" then prendre(p) end
      return {t = "fn", v = k[2], args = args}
    end
    return {t = "var", v = k[2]}
  end
  if k[2] == "(" then
    prendre(p); local e = expr(p)
    if voir(p) and voir(p)[2] == ")" then prendre(p) end
    return {t = "par", a = e}
  end
  if k[2] == "[" then
    prendre(p); local args = {}
    if not (voir(p) and voir(p)[2] == "]") then
      table.insert(args, expr(p))
      while voir(p) and voir(p)[2] == "," do prendre(p); table.insert(args, expr(p)) end
    end
    if voir(p) and voir(p)[2] == "]" then prendre(p) end
    if #args == 1 and args[1].t == "vec" then return args[1] end
    return {t = "vec", args = args}
  end
  if k[2] == "{" then
    prendre(p); local args = {}
    if not (voir(p) and voir(p)[2] == "}") then
      table.insert(args, expr(p))
      while voir(p) and voir(p)[2] == "," do prendre(p); table.insert(args, expr(p)) end
    end
    if voir(p) and voir(p)[2] == "}" then prendre(p) end
    return {t = "list", args = args}
  end
  prendre(p); return {t = "txt", v = k[2] or "?"}
end

local function puissance(p)
  local b = atome(p)
  if voir(p) and voir(p)[2] == "^" then
    prendre(p)
    local e
    if voir(p) and voir(p)[2] == "-" then prendre(p); e = {t = "neg", a = puissance(p)} else e = puissance(p) end
    if e.t == "par" then e = e.a end
    return {t = "pow", a = b, b = e}
  end
  return b
end

local function unaire(p)
  if voir(p) and voir(p)[2] == "-" then prendre(p); return {t = "neg", a = unaire(p)} end
  return puissance(p)
end

local function implicite(p)
  local k = voir(p)
  if not k then return false end
  return k[1] == "num" or k[1] == "id" or k[1] == "sqrt" or k[2] == "("
end

local function produit(p)
  local a = unaire(p)
  while voir(p) and (voir(p)[2] == "*" or voir(p)[2] == "/" or implicite(p)) do
    local o = implicite(p) and "*" or prendre(p)[2]
    local b = unaire(p)
    if o == "/" then
      if a.t == "par" then a = a.a end
      if b.t == "par" then b = b.a end
      a = {t = "frac", a = a, b = b}
    else a = {t = "op", v = "·", a = a, b = b} end
  end
  return a
end

local function somme(p)
  local a = produit(p)
  while voir(p) and (voir(p)[2] == "+" or voir(p)[2] == "-") do
    local o = prendre(p)[2]
    a = {t = "op", v = o, a = a, b = produit(p)}
  end
  return a
end

expr = function(p)
  local a = somme(p)
  while voir(p) and voir(p)[1] == "rel" do
    local o = prendre(p)[2]
    a = {t = "op", v = o, a = a, b = somme(p)}
  end
  return a
end

local function arbre(s)
  local p = P.new(s)
  local e = expr(p)
  while voir(p) do  -- reste non lu : on l'ajoute en texte
    local k = prendre(p)
    e = {t = "op", v = "", a = e, b = {t = "txt", v = k[2] or k[1]}}
  end
  return e
end

-- Mise en page : chaque boite = {w, asc, desc, draw(gc, x, base)}
local TAILLES = {11, 9, 7}
local function police(gc, niv, gras) gc:setFont("serif", gras and "b" or "r", TAILLES[math.min(niv, 3)]) end

local mise
local function texte(gc, s, niv, gras)
  police(gc, niv, gras)
  local w = gc:getStringWidth(s); local h = gc:getStringHeight("M")
  return {w = w, asc = math.floor(h * 0.75), desc = math.floor(h * 0.25), draw = function(gc2, x, b)
    police(gc2, niv, gras); gc2:drawString(s, x, b, "baseline") end}
end

local function ligne(gc, boites)
  local w, asc, desc = 0, 0, 0
  for _, b in ipairs(boites) do w = w + b.w; asc = math.max(asc, b.asc); desc = math.max(desc, b.desc) end
  return {w = w, asc = asc, desc = desc, draw = function(gc2, x, base)
    for _, b in ipairs(boites) do b.draw(gc2, x, base); x = x + b.w end end}
end

local function parens(gc, inner, niv)
  local h = inner.asc + inner.desc
  if h <= 18 then
    return ligne(gc, {texte(gc, "(", niv), inner, texte(gc, ")", niv)})
  end
  return {w = inner.w + 8, asc = inner.asc + 1, desc = inner.desc + 1, draw = function(gc2, x, base)
    local top, bot = base - inner.asc - 1, base + inner.desc + 1
    gc2:drawArc(x, top, 6, bot - top, 100, 160)
    inner.draw(gc2, x + 4, base)
    gc2:drawArc(x + inner.w + 2, top, 6, bot - top, -80, 160)
  end}
end

local PREC = {["+"] = 1, ["-"] = 1, ["·"] = 2}

mise = function(gc, n, niv, gras)
  niv = niv or 1
  local t = n.t
  if t == "num" or t == "txt" then return texte(gc, n.v, niv, gras) end
  if t == "var" then return texte(gc, n.v, niv, gras) end
  if t == "par" then return parens(gc, mise(gc, n.a, niv, gras), niv) end
  if t == "neg" then return ligne(gc, {texte(gc, "−", niv, gras), mise(gc, n.a, niv, gras)}) end
  if t == "op" then
    local a, b = mise(gc, n.a, niv, gras), mise(gc, n.b, niv, gras)
    local s = n.v
    if s == "·" then
      -- 2·x -> 2x ; on garde le point entre deux nombres
      if (n.b.t == "var" or n.b.t == "pow" or n.b.t == "par" or n.b.t == "sqrt" or n.b.t == "fn") and n.a.t ~= "frac"
         and not (n.b.t == "par" and (n.a.t == "num" or n.a.t == "par")) and not (n.b.t == "pow" and n.b.a.t == "num") then s = "" end
    end
    if s == "+" or s == "-" then s = " " .. (s == "-" and "−" or "+") .. " " end
    if s == "=" or s == "≠" or s == "<" or s == ">" or s == "≤" or s == "≥" or s == "<=" or s == ">=" then
      s = " " .. (s == "<=" and "≤" or (s == ">=" and "≥" or s)) .. " " end
    return ligne(gc, {a, texte(gc, s, niv, gras), b})
  end
  if t == "frac" then
    local a, b = mise(gc, n.a, niv, gras), mise(gc, n.b, niv, gras)
    local w = math.max(a.w, b.w) + 4
    return {w = w, asc = a.asc + a.desc + 4, desc = b.asc + b.desc + 1, draw = function(gc2, x, base)
      local axe = base - 4
      a.draw(gc2, x + (w - a.w) / 2, axe - 2 - a.desc)
      gc2:drawLine(x + 1, axe, x + w - 1, axe)
      b.draw(gc2, x + (w - b.w) / 2, axe + 2 + b.asc)
    end}
  end
  if t == "pow" then
    local a = mise(gc, n.a, niv, gras)
    if n.a.t == "op" or n.a.t == "neg" or n.a.t == "frac" then a = parens(gc, a, niv) end
    local e = mise(gc, n.b, niv + 1, gras)
    local leve = math.floor(a.asc * 0.55)
    return {w = a.w + e.w + 1, asc = math.max(a.asc, leve + e.asc), desc = a.desc, draw = function(gc2, x, base)
      a.draw(gc2, x, base)
      e.draw(gc2, x + a.w + 1, base - leve)
    end}
  end
  if t == "sqrt" then
    local a = mise(gc, n.a, niv, gras)
    return {w = a.w + 10, asc = a.asc + 3, desc = a.desc, draw = function(gc2, x, base)
      local top = base - a.asc - 2
      gc2:drawLine(x, base - 3, x + 2, base - 4)
      gc2:drawLine(x + 2, base - 4, x + 4, base + a.desc)
      gc2:drawLine(x + 4, base + a.desc, x + 7, top)
      gc2:drawLine(x + 7, top, x + a.w + 10, top)
      a.draw(gc2, x + 9, base)
    end}
  end
  if t == "fn" and n.v == "sqrt" and n.args[1] then return mise(gc, {t = "sqrt", a = n.args[1]}, niv, gras) end
  if t == "fn" then
    local args = {}
    for k, v in ipairs(n.args) do
      if k > 1 then table.insert(args, texte(gc, ", ", niv, gras)) end
      table.insert(args, mise(gc, v, niv, gras))
    end
    return ligne(gc, {texte(gc, n.v, niv, gras), parens(gc, ligne(gc, args), niv)})
  end
  if t == "vec" then
    local bs, w, h = {}, 0, 0
    for _, v in ipairs(n.args) do local b = mise(gc, v, niv, gras); table.insert(bs, b); w = math.max(w, b.w); h = h + b.asc + b.desc + 1 end
    local col = {w = w, asc = math.floor(h / 2) + 3, desc = h - math.floor(h / 2), draw = function(gc2, x, base)
      local y = base - math.floor(h / 2) + 3
      for _, b in ipairs(bs) do b.draw(gc2, x + (w - b.w) / 2, y + b.asc - 3); y = y + b.asc + b.desc + 1 end
    end}
    local cadre = {w = col.w + 8, asc = col.asc + 1, desc = col.desc + 1, draw = function(gc2, x, base)
      local top, bot = base - col.asc - 1, base + col.desc + 1
      gc2:drawArc(x, top, 6, bot - top, 100, 160)
      col.draw(gc2, x + 4, base)
      gc2:drawArc(x + col.w + 2, top, 6, bot - top, -80, 160)
    end}
    return cadre
  end
  if t == "list" then
    local args = {texte(gc, "{", niv, gras)}
    for k, v in ipairs(n.args) do
      if k > 1 then table.insert(args, texte(gc, " ; ", niv, gras)) end
      table.insert(args, mise(gc, v, niv, gras))
    end
    table.insert(args, texte(gc, "}", niv, gras))
    return ligne(gc, args)
  end
  return texte(gc, "?", niv, gras)
end

------------------------------------------------------------------ document de resultats
-- Un document = liste d'elements : {k="titre"|"txt"|"math"|"res"|"alerte"|"gris", s=..., avant=texte}
local DOC = {}
local function vider() DOC = {} end
local function T(s) table.insert(DOC, {k = "titre", s = s}) end
local function X(s) table.insert(DOC, {k = "txt", s = s}) end
local function G(s) table.insert(DOC, {k = "gris", s = s}) end
local function A(s) table.insert(DOC, {k = "alerte", s = s}) end
local function M(avant, e, apres) table.insert(DOC, {k = "math", avant = avant or "", s = e, apres = apres or ""}) end
local function R(avant, e, apres) table.insert(DOC, {k = "res", avant = avant or "", s = e, apres = apres or ""}) end

------------------------------------------------------------------ memoire (historique + resultats)
local HIST = {}       -- saisies et resultats reutilisables
local ARCH = {}       -- documents deja affiches
local function memoriser(s)
  if not s or s == "" then return end
  for i = #HIST, 1, -1 do if HIST[i] == s then table.remove(HIST, i) end end
  table.insert(HIST, s)
  while #HIST > 30 do table.remove(HIST, 1) end
end

------------------------------------------------------------------ etat de l'interface
local ecran = "menu"     -- "menu" | "saisie" | "vue"
local MENU = {}          -- {titre, items = {{texte, fonction}}}
local sel = 1
local saisie = {msg = "", txt = "", cur = 0, h = 0, suite = nil}
local vue = {haut = 0, lignes = nil, titre = ""}

local function inval() platform.window:invalidate() end

local function demander(msg, suite, defaut)
  saisie = {msg = msg, txt = defaut or "", cur = #(defaut or ""), h = #HIST + 1, suite = suite}
  ecran = "saisie"; inval()
end

local function montrer(titre)
  table.insert(ARCH, {titre = titre, doc = DOC})
  while #ARCH > 20 do table.remove(ARCH, 1) end
  vue = {haut = 0, doc = DOC, titre = titre}
  ecran = "vue"; inval()
end

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
local function nombre(e)
  local r = cas("approx(" .. e .. ")")
  if not r then return nil end
  r = r:gsub("ᴇ", "e"):gsub("E", "e")
  return tonumber(r)
end

local function decouper(s, sep)  -- coupe au niveau 0 des parentheses
  local out, prof, cur = {}, 0, ""
  for i = 1, #s do
    local c = s:sub(i, i)
    if c == "(" or c == "{" or c == "[" then prof = prof + 1 end
    if c == ")" or c == "}" or c == "]" then prof = prof - 1 end
    if c == sep and prof == 0 then table.insert(out, cur); cur = "" else cur = cur .. c end
  end
  table.insert(out, cur)
  return out
end

local function liste(s)  -- "{a,b}" -> {"a","b"}
  s = s:gsub("^%s*{", ""):gsub("}%s*$", "")
  if s == "" then return {} end
  return decouper(s, ",")
end

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

local function horner(c, x) local r = 0; for _, a in ipairs(c) do r = r * x + a end; return r end

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

local function menuVecteurs()
  MENU = {titre = "Vecteurs (séries 4 à 6)", items = {
    {"Norme, vecteur unitaire", function() demander("u = ", function(u) vNorme(u) end, "2,-1,2") end},
    {"Produit scalaire, angle", function() demander("u = ", function(u) demander("v = ", function(v) vScalaire(u, v) end, "3,4,0") end, "1,1,0") end},
    {"Projection d'un point sur une droite (AB)", function()
      demander("point P = ", function(p) demander("A = ", function(a) demander("B = ", function(b) vProjPoint(p, a, b) end, "R(2;0;6)") end, "Q(7;2;5)") end, "P(-1;-7;7)") end},
    {"Projection d'un vecteur v sur u", function() demander("v = ", function(v) demander("u = ", function(u) vProjVect(v, u) end, "1,0,1") end, "2,3,1") end},
    {"Produit vectoriel, aire", function() demander("u = ", function(u) demander("v = ", function(v) vVectoriel(u, v) end, "4,5,6") end, "1,2,3") end},
    {"Produit mixte, volume, coplanarité", function()
      demander("a = ", function(a) demander("b = ", function(b) demander("c = ", function(c) vMixte(a, b, c) end, "-1,2,5") end, "0,4,2") end, "2,0,3") end},
    {"Paramètre : u ⊥ v", function() demander("u = ", function(u) demander("v = ", function(v) vParam(u, v, "o") end, "-5,-2,1") end, "x-7,x,x-5") end},
    {"Paramètre : u, v colinéaires", function() demander("u = ", function(u) demander("v = ", function(v) vParam(u, v, "c") end, "2,4,6") end, "1,m,3") end},
    {"Composantes dans une base", function()
      demander("w = ", function(w) demander("b1 = ", function(b1) demander("b2 = ", function(b2) demander("b3 = ", function(b3) vComposantes(w, b1, b2, b3) end, "0,0,1") end, "-5,-2,1") end, "-8,-9,2") end, "-1,2,0") end},
    {"Base orthonormée directe ?", function()
      demander("a = ", function(a) demander("b = ", function(b) demander("c = ", function(c) vBON(a, b, c) end, "-2/3,2/3,-1/3") end, "2/3,1/3,-2/3") end, "1/3,2/3,2/3") end},
    {"Construire une BON directe", function() demander("a (direction de u) = ", function(a) demander("b (⊥ a) = ", function(b) vConstruire(a, b) end, "-1,2,0") end, "-5,-2,1") end},
  }}
  sel = 1; ecran = "menu"; inval()
end

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

------------------------------------------------------------------ resolution automatique et aide
local function aide()
  vider(); T("Aide à la saisie")
  X("Puissance : touche ^  →  x^2, x^3, e^(2x)")
  X("Produit : 2x et 3(x+1) marchent ; entre deux lettres mets * : a*x, m*x")
  X("Fraction : (x^2+1)/(2x^2-3) — parenthèses autour du numérateur et du dénominateur")
  X("Racine : sqrt(x) ou √(x) ; exponentielle : e^(x) ; logarithme : ln(x)")
  T("Équations")
  X("x^2-3x+2=0   ou   x^2=x+6   (le = est obligatoire)")
  X("Paramètre : utilise m, k, λ ou a →  (m*x)^2-2m*x-3=0")
  X("eˣ : 6e^(3x)+5e^(2x)-2e^(x)-1=0 → changement X = eˣ automatique")
  T("Inéquations")
  X("Signes : >  <  >=  <=   (ou ≥ ≤ du catalogue)")
  X("(3x+1)/(2x-1)>=0     x^2-4<0     (x-1)/(x+2)>=1/2")
  X("Valeur absolue : abs(x-1)  (ou |x-1|)  →  abs(x-1)/(x+2)>=1/2")
  T("Polynôme ou fonction seule")
  X("Sans = ni < : un polynôme est factorisé avec son signe ; une fraction rationnelle (avec /) reçoit l'analyse complète du problème C.")
  T("Vecteurs et points")
  X("Vecteur : 2,-1,3  ou  (2;-1;3)  ou  [2,-1,3]")
  X("Point : P(-1;-7;7)")
  T("Touches")
  X("Saisie : ◄► curseur, ▲▼ saisies et résultats précédents, clear efface")
  X("Résultats : ▲▼ défilent, ◄► changent de page, esc ou enter : menu")
  montrer("Aide")
end

local function auto(e)
  e = norm(e)
  local sans = e:gsub("%s", "")
  if sans:find("[<>≤≥]") then inequation(sans); return end
  if sans:find("=") then
    if sans:find("e%^") then
      local g, d = cotes(sans)
      vider()
      changement(sans, "e^(x)", "x")
      return
    end
    equation(sans); return
  end
  if (sans:find("sqrt") or sans:find("√")) and sans:find("x") then domaineGeneral(sans); return end
  if sans:find("/") and sans:find("x") then analyse(sans); return end
  if not sans:find("x") and sans:find("/") and sans:find("%a") then simplifier(sans); return end
  if not sans:find("x") and sans:find("%a") then factoLitterale(sans); return end
  if sans:find("x") or sans:find("%f[%a][aut]%f[%A]") then signePoly(sans); return end
  vider(); T("Calcul"); M("", sans); R("= ", cas1(sans)); montrer("Calcul")
end

------------------------------------------------------------------ menus
local menuPrincipal

local function lancerAnalyse()
  demander("f(x) = ", function(f) analyse(f) end, HIST[#HIST])
end

local function lancerFacto()
  demander("P(x) = ", function(p)
    p = norm(p)
    vider(); T("Factorisation de P(x)")
    M("P(x) = ", p)
    bilanFacto(cas1("expand(" .. p .. ")"), "P")
    montrer("Factorisation")
  end, HIST[#HIST])
end

local function lancerIdent()
  demander("f(x) = ", function(f)
    demander("forme (a,b,c,d) = ", function(forme) identifier(f, forme) end, "a*x+b+c/(x^2+1)")
  end, HIST[#HIST])
end

local function historiqueResultats()
  local it = {}
  for i = #ARCH, 1, -1 do
    local d = ARCH[i]
    table.insert(it, {d.titre, function() vue = {haut = 0, doc = d.doc, titre = d.titre}; ecran = "vue"; inval() end})
  end
  if #it == 0 then table.insert(it, {"(vide)", function() end}) end
  MENU = {titre = "Historique", items = it}; sel = 1; ecran = "menu"; inval()
end

local function menuOutils()
  MENU = {titre = "Outils séries 1 à 3", items = {
    {"Résoudre une équation (Δ, paramètre…)", function()
      demander("équation = ", function(e) equation(norm(e)) end, "x^2-3x+2=0") end},
    {"Inéquation, valeur absolue", function()
      demander("inéquation = ", function(e) inequation(norm(e)) end, "(3x+1)/(2x-1)>=0") end},
    {"Changement de variable", function()
      demander("équation = ", function(e)
        demander("X = ", function(sub) changement(norm(e), norm(sub), variable(e)) end, "x^2")
      end, "x^4-5x^2+4=0") end},
    {"Division en potence A ÷ B", function()
      demander("A(x) = ", function(a)
        demander("B(x) = ", function(b) division(norm(a), norm(b)) end, "x^2+x+1")
      end, "x^3+2x^2-3") end},
    {"Simplifier une fraction / expression", function()
      demander("expression = ", function(e) simplifier(norm(e)) end, "(a-3)/(2a^2-18)") end},
    {"Factoriser et étudier le signe", function()
      demander("P = ", function(e) signePoly(norm(e)) end, "x^3-7x^2-4x+28") end},
  }}
  sel = 1; ecran = "menu"; inval()
end

menuPrincipal = function()
  MENU = {titre = "MATH_1 – solveur", items = {
    {"Résoudre (automatique)", function() demander("à résoudre = ", function(e) auto(e) end, HIST[#HIST]) end},
    {"Problème A complet (vecteurs, blanc/test)", function()
      demander("P = ", function(p) demander("Q = ", function(q) demander("R = ", function(r) demander("S (avec paramètre) = ", function(sx)
        demander("condition sur S = ", function(cd) problemeA2(p, q, r, sx, cd) end, "QS.QR=0") end, "x,x+2,x") end, "R(2;0;6)") end, "Q(7;2;5)") end, "P(-1;-7;7)") end},
    {"Problème B complet (figure, Chasles)", function()
      local it = {}
      for _, fg in ipairs(FIGB) do
        table.insert(it, {fg[1], function() demander("sommes (séparées par ;) = ", function(sm) problemeB2(fg[2], sm) end, "AB+BC;AO+OC;AM;MN") end})
      end
      table.insert(it, {"Figure libre", function() demander("points (A=0;B=u;…) = ", function(d) demander("sommes = ", function(sm) problemeB2(d, sm) end, "AB+BC") end, "A=0;B=u;D=v;C=u+v") end})
      MENU = {titre = "Problème B : figure", items = it}; sel = 1; ecran = "menu"; inval() end},
    {"Analyse de fonction (S7 ex.7-8)", lancerAnalyse},
    {"Identifier des réels a, b, c (S7 ex.5)", lancerIdent},
    {"Factoriser un polynôme (détail)", lancerFacto},
    {"Outils séries 1 à 3 (équations, inéquations…)", menuOutils},
    {"Vecteurs (séries 4 à 6)", menuVecteurs},
    {"Fonctions : domaine, parité, composition, bijection sur I", function()
      MENU = {titre = "Fonctions (série 7)", items = {
        {"Domaine (racines, fractions)", function() demander("f(x) = ", function(f) domaineGeneral(norm(f)) end, "sqrt((x-2)/(x+2))") end},
        {"Bijection sur I, f⁻¹ et courbes", function() demander("f(x) = ", function(f) demander("I = ", function(I) bijectionI(f, I) end, "]sqrt(3/2);+inf[") end, HIST[#HIST]) end},
        {"Parité", function() demander("f(x) = ", function(f) parite(f) end, "x^3+x") end},
        {"Composition f∘g et g∘f", function() demander("f(x) = ", function(f) demander("g(x) = ", function(g) composition(f, g) end, "sqrt(1-x)") end, "sqrt(x^2-1)") end},
      }}; sel = 1; ecran = "menu"; inval() end},
    {"Figure : Chasles, combinaisons (problème B)", function()
      local it = {}
      for _, fg in ipairs(FIGURES) do
        table.insert(it, {fg[1], function() demander("somme = ", function(sm) chasles(fg[2], sm) end, "AG+GH+AB") end})
      end
      table.insert(it, {"Figure libre (définir les points)", function()
        demander("points (A=0;B=u;…) = ", function(d) demander("somme = ", function(sm) chasles(d, sm) end, "AB+BC") end, "A=0;B=u;D=v;C=u+v") end})
      MENU = {titre = "Figures", items = it}; sel = 1; ecran = "menu"; inval() end},
    {"Vecteurs sans composantes, systèmes", function()
      MENU = {titre = "Vecteurs (suite)", items = {
        {"Angle par bilinéarité (||a||, ||b|| connus)", function()
          demander("équation en a, b = ", function(e) demander("||a|| = ", function(na) demander("||b|| = ", function(nb) bilin(norm(e), na, nb) end, "3") end, "2") end, "(2a-b)*(a+b)=0") end},
        {"Points : milieu, gravité, parallélogramme, symétrique, rapport, relation", function()
          MENU = {titre = "Points", items = {
            {"Milieu de [AB]", function() demander("A = ", function(a) demander("B = ", function(b) vPoint("milieu", a, b) end, "3,3,1") end, "1,2,3") end},
            {"Centre de gravité ABC", function() demander("A = ", function(a) demander("B = ", function(b) demander("C = ", function(c) vPoint("gravite", a, b, c) end, "0,0,3") end, "3,3,1") end, "1,2,3") end},
            {"D tel que ABCD parallélogramme", function() demander("A = ", function(a) demander("B = ", function(b) demander("C = ", function(c) vPoint("para", a, b, c) end, "4,1,0") end, "3,3,1") end, "1,2,3") end},
            {"Symétrique de A par rapport à B", function() demander("A = ", function(a) demander("B = ", function(b) vPoint("sym", a, b) end, "3,3,1") end, "1,2,3") end},
            {"M tel que AM = k·AB", function() demander("A = ", function(a) demander("B = ", function(b) demander("k = ", function(k) vPoint("rapport", a, b, nil, k) end, "2/3") end, "3,3,1") end, "1,2,3") end},
            {"M tel que αMA + βMB + γMC = 0", function() demander("A = ", function(a) demander("B = ", function(b) demander("C = ", function(c) demander("α,β,γ = ", function(k) vPoint("relation", a, b, c, k) end, "1,2,0") end, "0,0,0") end, "3,3,1") end, "1,2,3") end},
          }}; sel = 1; ecran = "menu"; inval() end},
        {"Colinéarité / alignement par λ", function() demander("u = ", function(u) demander("v = ", function(v) vColin(u, v) end, "-2,m+4") end, "1,5") end},
        {"Vecteur unitaire ⊥ à deux vecteurs", function() demander("a = ", function(a) demander("b = ", function(b) vUnitOrtho(a, b) end, "1,0,1") end, "1,2,3") end},
        {"Vecteur de norme donnée", function() demander("a = ", function(a) demander("norme = ", function(d) vNormeDonnee(a, d) end, "3") end, "2,-1,2") end},
        {"Composantes dans une base (2D ou 3D)", function()
          demander("w = ", function(w) demander("base (b1;b2[;b3]) = ", function(bs)
            vider(); T("Composantes dans une base")
            local b = {}
            for _, x in ipairs(decouper(bs, ";")) do table.insert(b, vec(x)) end
            G("Méthode : w = α·b1 + β·b2 (+ γ·b3) : une équation par coordonnée, puis résolution (substitution ou combinaison de lignes).")
            composantesBase(vec(w), b, "w = ")
            montrer("Composantes") end, "[1,1];[1,-1]") end, "3,1") end},
        {"Système de conditions (u.v=0 and …)", function()
          demander("vecteurs (u=…;v=…) = ", function(d) demander("conditions = ", function(c) systemeVect(d, c) end, "u.v=0 and u.w=0") end, "u=[a,b,1];v=[1,2,3];w=[2,0,1]") end},
      }}; sel = 1; ecran = "menu"; inval() end},
    {"Isoler une lettre / factoriser (lettres)", function()
      MENU = {titre = "Calcul littéral (série 1)", items = {
        {"Factoriser une expression", function() demander("expression = ", function(e) factoLitterale(norm(e)) end, "a^3*b+a*b^3-2*a^2*b^2") end},
        {"Isoler une lettre", function() demander("équation = ", function(e) demander("lettre = ", function(l) isoler(norm(e), l) end, "c") end, "1/a+1/b=1/c") end},
      }}; sel = 1; ecran = "menu"; inval() end},
    {"Historique des résultats", historiqueResultats},
    {"Aide à la saisie", aide},
  }}
  sel = 1; ecran = "menu"; inval()
end

------------------------------------------------------------------ dessin : tableau de signes et graphe
local function hauteurTab(e) return 20 + 17 * #e.tab.lignes + 4 end

local function dessinerTab(gc, e, x0, y0, w)
  local t = e.tab
  local n = #t.pts
  -- largeur colonne des noms
  gc:setFont("serif", "r", 9)
  local nomw = 22
  local boites = {}
  for i, l in ipairs(t.lignes) do
    l.txt = l.txt or (l.nom:gsub("%^2", "²"):gsub("%^3", "³"):gsub("%^4", "⁴"):gsub("%*", ""))
    boites[i] = nil
    nomw = math.max(nomw, gc:getStringWidth(l.txt) + 6)
  end
  nomw = math.min(nomw, math.floor(w * 0.35))
  local W = w - nomw - 4
  local larg = W / (n + 1)
  local function xb(i) return x0 + nomw + larg * i end  -- frontiere i (1..n)
  -- cadre
  gc:setColorRGB(0, 0, 0); gc:setPen("thin", "smooth")
  local H = hauteurTab(e) - 4
  gc:drawRect(x0, y0, w - 2, H)
  gc:drawLine(x0 + nomw, y0, x0 + nomw, y0 + H)
  gc:drawLine(x0, y0 + 18, x0 + w - 2, y0 + 18)
  -- en-tete
  gc:setFont("serif", "i", 10); gc:drawString(t.var, x0 + 4, y0 + 2, "top")
  gc:setFont("serif", "r", 9)
  gc:drawString("−∞", x0 + nomw + 2, y0 + 3, "top")
  local pinf = "+∞"; gc:drawString(pinf, x0 + w - 4 - gc:getStringWidth(pinf), y0 + 3, "top")
  for i, p in ipairs(t.pts) do
    local ok, b = pcall(function() return mise(gc, arbre(p.s), 3) end)
    if ok and b.w < larg * 1.6 and b.asc + b.desc <= 13 then b.draw(gc, xb(i) - b.w / 2, y0 + 3 + b.asc)
    else local s = (#p.s <= 11) and p.s or string.format("%.3g", p.v); gc:drawString(s, xb(i) - gc:getStringWidth(s) / 2, y0 + 3, "top") end
  end
  -- lignes
  for li, l in ipairs(t.lignes) do
    local y = y0 + 18 + (li - 1) * 17
    if li > 1 then gc:setColorRGB(170, 170, 170); gc:drawLine(x0, y, x0 + w - 2, y) end
    local res = li == #t.lignes
    gc:setColorRGB(res and 0 or 0, res and 120 or 0, 0)
    if boites[li] and boites[li].w <= nomw - 4 then boites[li].draw(gc, x0 + 3, y + 3 + boites[li].asc)
    else gc:setFont("serif", "r", 9); gc:drawString(l.txt, x0 + 2, y + 2, "top") end
    gc:setFont("sansserif", res and "b" or "r", 10)
    for k, c in ipairs(l.cells) do
      if k % 2 == 1 then  -- intervalle
        local i = (k + 1) / 2
        local xc = x0 + nomw + larg * (i - 0.5)
        gc:setColorRGB(c == "+" and 0 or 200, 0, c == "+" and 160 or 0)
        gc:drawString(c, xc - gc:getStringWidth(c) / 2, y + 2, "top")
      else
        local i = k / 2
        gc:setColorRGB(0, 0, 0)
        if c == "0" then gc:drawString("0", xb(i) - gc:getStringWidth("0") / 2, y + 2, "top")
        elseif c == "||" then gc:drawLine(xb(i) - 1, y, xb(i) - 1, y + 17); gc:drawLine(xb(i) + 1, y, xb(i) + 1, y + 17)
        else gc:setColorRGB(200, 200, 200); gc:drawLine(xb(i), y + 2, xb(i), y + 15) end
      end
    end
  end
end

local HGRAPHE = 190

local function pas(l)  -- pas de graduation 1, 2, 5 x 10^k pour ~6 graduations
  local b = 10 ^ math.floor(math.log10(l / 6))
  for _, m in ipairs({1, 2, 5, 10}) do if l / (m * b) <= 8 then return m * b end end
  return 10 * b
end

local function dessinerCourbes(gc, e, x0, y0, w)
  local h = HGRAPHE
  local xmin, xmax, ymin, ymax = 1e9, -1e9, 1e9, -1e9
  local ys = {}
  for _, c in ipairs(e.courbes) do for _, p in ipairs(c.pts) do
    if p[1] and p[2] then table.insert(ys, p[1]); table.insert(ys, p[2]) end
  end end
  table.sort(ys)
  if #ys == 0 then return end
  local lo, hi = ys[math.max(1, math.floor(#ys * 0.08))], ys[math.max(1, math.floor(#ys * 0.92))]
  lo = math.min(lo, 0); hi = math.max(hi, 0)
  if e.lo then lo, hi = e.lo, e.hi end
  if hi - lo < 1 then hi = lo + 1 end
  lo = lo - 0.1 * (hi - lo); hi = hi + 0.1 * (hi - lo)
  local function X(x) return x0 + (x - lo) / (hi - lo) * (w - 2) end
  local function Y(y) return y0 + h - (y - lo) / (hi - lo) * h end
  gc:setColorRGB(255, 255, 255); gc:fillRect(x0, y0, w - 2, h)
  gc:setColorRGB(0, 0, 0); gc:drawRect(x0, y0, w - 2, h)
  gc:clipRect("set", x0, y0, w - 2, h)
  gc:setColorRGB(120, 120, 120); gc:setPen("thin", "smooth")
  if lo < 0 and hi > 0 then gc:drawLine(X(0), y0, X(0), y0 + h); gc:drawLine(x0, Y(0), x0 + w, Y(0)) end
  gc:setFont("sansserif", "r", 7)
  local pp = pas(hi - lo)
  for k = math.ceil(lo / pp), math.floor(hi / pp) do
    local v = k * pp
    if math.abs(v) > 1e-9 then
      gc:drawLine(X(v), Y(0) - 2, X(v), Y(0) + 2); gc:drawString(string.format("%g", v), X(v) - 4, Y(0) + 2, "top")
      gc:drawLine(X(0) - 2, Y(v), X(0) + 2, Y(v)); gc:drawString(string.format("%g", v), X(0) + 3, Y(v) - 5, "top")
    end
  end
  if e.diag then gc:setColorRGB(200, 0, 0); gc:setPen("thin", "dashed"); gc:drawLine(X(lo), Y(lo), X(hi), Y(hi)) end
  gc:setPen("medium", "smooth")
  for _, c in ipairs(e.courbes) do
    gc:setColorRGB(c.coul[1], c.coul[2], c.coul[3])
    local prev = nil
    for _, p in ipairs(c.pts) do
      if p[1] and p[2] and p[2] > lo - 3 * (hi - lo) and p[2] < hi + 3 * (hi - lo) then
        if prev then gc:drawLine(X(prev[1]), Y(prev[2]), X(p[1]), Y(p[2])) end
        prev = p
      else prev = nil end
    end
  end
  gc:clipRect("reset")
  gc:setColorRGB(80, 80, 80); gc:setFont("sansserif", "r", 7)
  gc:drawString(e.legende or "", x0 + 2, y0 + h + 1, "top")
end

local COULB = {{255, 225, 225}, {220, 240, 255}, {225, 250, 220}, {255, 240, 210}, {240, 225, 255}}
local COULBT = {{200, 0, 0}, {0, 90, 200}, {0, 140, 0}, {210, 120, 0}, {130, 0, 180}}

local function dessinerGraphe(gc, e, x0, y0, w)
  local h = HGRAPHE
  local function f(x)
    local d = horner(e.den, x)
    if math.abs(d) < 1e-12 then return nil end
    return horner(e.num, x) / d
  end
  -- fenetre
  local xs = {}
  for _, l in ipairs({e.poles, e.interdits, e.zeros, e.crit}) do for _, p in ipairs(l or {}) do table.insert(xs, p.v) end end
  local a, b = -2, 2
  if #xs > 0 then a, b = math.min(unpack(xs)), math.max(unpack(xs)) end
  local larg = math.max(b - a, 4)
  local xmin, xmax = a - 0.6 * larg, b + 0.6 * larg
  local ys = {0}
  for _, l in ipairs({e.crit, e.zeros}) do for _, p in ipairs(l or {}) do local v = f(p.v); if v then table.insert(ys, v) end end end
  for _, x in ipairs({xmin, xmax}) do local v = f(x); if v then table.insert(ys, v) end end
  if e.asym and #e.asym == 1 then table.insert(ys, e.asym[1]) end
  local ymin, ymax = math.min(unpack(ys)), math.max(unpack(ys))
  local hy = math.max(ymax - ymin, 4)
  ymin, ymax = ymin - 0.5 * hy, ymax + 0.5 * hy
  local function X(x) return x0 + (x - xmin) / (xmax - xmin) * (w - 2) end
  local function Y(y) return y0 + h - (y - ymin) / (ymax - ymin) * h end
  gc:setColorRGB(255, 255, 255); gc:fillRect(x0, y0, w - 2, h)
  gc:setColorRGB(0, 0, 0); gc:drawRect(x0, y0, w - 2, h)
  gc:clipRect("set", x0, y0, w - 2, h)
  -- encadres de bijection (sous la courbe)
  for _, bx in ipairs(e.boites or {}) do
    local c = COULB[(bx.n - 1) % 5 + 1]
    local xa, xb = X(math.max(bx.x1, xmin - 1)), X(math.min(bx.x2, xmax + 1))
    local ya, yb = Y(math.min(bx.y2, ymax + 1)), Y(math.max(bx.y1, ymin - 1))
    gc:setColorRGB(c[1], c[2], c[3]); gc:fillRect(xa, ya, xb - xa, yb - ya)
    local ct = COULBT[(bx.n - 1) % 5 + 1]
    gc:setColorRGB(ct[1], ct[2], ct[3]); gc:setPen("thin", "smooth"); gc:drawRect(xa, ya, xb - xa, yb - ya)
  end
  -- axes et graduations
  gc:setColorRGB(120, 120, 120); gc:setPen("thin", "smooth")
  if xmin < 0 and xmax > 0 then gc:drawLine(X(0), y0, X(0), y0 + h) end
  if ymin < 0 and ymax > 0 then gc:drawLine(x0, Y(0), x0 + w, Y(0)) end
  gc:setFont("sansserif", "r", 7)
  local yax = (ymin < 0 and ymax > 0) and Y(0) or (y0 + h - 1)
  local xax = (xmin < 0 and xmax > 0) and X(0) or (x0 + 1)
  local px_ = pas(xmax - xmin)
  for k = math.ceil(xmin / px_), math.floor(xmax / px_) do
    local v = k * px_
    if math.abs(v) > 1e-9 then
      gc:drawLine(X(v), yax - 2, X(v), yax + 2)
      local s = string.format("%g", v)
      gc:drawString(s, X(v) - gc:getStringWidth(s) / 2, math.min(yax + 2, y0 + h - 10), "top")
    end
  end
  local py_ = pas(ymax - ymin)
  for k = math.ceil(ymin / py_), math.floor(ymax / py_) do
    local v = k * py_
    if math.abs(v) > 1e-9 then
      gc:drawLine(xax - 2, Y(v), xax + 2, Y(v))
      local s = string.format("%g", v)
      gc:drawString(s, math.max(xax + 3, x0 + 2), Y(v) - 5, "top")
    end
  end
  -- asymptotes
  gc:setColorRGB(220, 0, 0); gc:setPen("thin", "dashed")
  for _, p in ipairs(e.poles or {}) do gc:drawLine(X(p.v), y0, X(p.v), y0 + h) end
  if e.asym then
    local q = function(x) return horner(e.asym, x) end
    gc:drawLine(X(xmin), Y(q(xmin)), X(xmax), Y(q(xmax)))
  end
  -- courbe
  gc:setColorRGB(0, 0, 200); gc:setPen("medium", "smooth")
  local px, py = nil, nil
  local N = 260
  for i = 0, N do
    local x = xmin + (xmax - xmin) * i / N
    local y = f(x)
    local coupe = false
    if px then for _, p in ipairs(e.poles or {}) do if px < p.v and p.v <= x then coupe = true end end end
    if y and px and py and not coupe and math.abs(y - py) < 3 * (ymax - ymin) then
      gc:drawLine(X(px), Y(math.max(math.min(py, ymax + hy), ymin - hy)), X(x), Y(math.max(math.min(y, ymax + hy), ymin - hy)))
    end
    px, py = x, y
    if coupe then py = nil end
  end
  -- zeros et trous
  gc:setPen("thin", "smooth")
  gc:setColorRGB(0, 150, 0)
  for _, z in ipairs(e.zeros or {}) do gc:fillArc(X(z.v) - 3, Y(0) - 3, 6, 6, 0, 360) end
  for _, r in ipairs(e.interdits or {}) do
    local pole = false
    for _, p in ipairs(e.poles or {}) do if math.abs(p.v - r.v) < 1e-9 then pole = true end end
    if not pole then
      local v = f(r.v + 1e-6) or 0
      gc:setColorRGB(255, 255, 255); gc:fillArc(X(r.v) - 3, Y(v) - 3, 6, 6, 0, 360)
      gc:setColorRGB(200, 0, 0); gc:drawArc(X(r.v) - 3, Y(v) - 3, 6, 6, 0, 360)
    end
  end
  gc:clipRect("reset")
  gc:setColorRGB(80, 80, 80); gc:setFont("sansserif", "r", 7)
  gc:drawString(string.format("x∈[%.3g;%.3g] y∈[%.3g;%.3g]", xmin, xmax, ymin, ymax), x0 + 2, y0 + h + 1, "top")
end

------------------------------------------------------------------ dessin
local BLEU = {30, 70, 160}

local function bandeau(gc, w, s)
  gc:setColorRGB(BLEU[1], BLEU[2], BLEU[3]); gc:fillRect(0, 0, w, 20)
  gc:setColorRGB(255, 255, 255); gc:setFont("sansserif", "b", 11); gc:drawString(s, 4, 2, "top")
end

local function pied(gc, w, h, s)
  gc:setColorRGB(225, 225, 225); gc:fillRect(0, h - 16, w, 16)
  gc:setColorRGB(60, 60, 60); gc:setFont("sansserif", "r", 9); gc:drawString(s, 4, h - 15, "top")
end

local function dessinerMenu(gc, w, h)
  bandeau(gc, w, MENU.titre)
  local y = 24
  local nvis = math.floor((h - 44) / 20)
  local debut = math.max(1, sel - nvis + 1)
  for i, it in ipairs(MENU.items) do
    if i >= debut and i < debut + nvis then
      if i == sel then gc:setColorRGB(200, 220, 255); gc:fillRect(2, y - 1, w - 4, 19) end
      gc:setColorRGB(0, 0, 0); gc:setFont("sansserif", i == sel and "b" or "r", 10)
      gc:drawString((i < 10 and i or " ") .. "  " .. it[1], 8, y, "top")
      y = y + 20
    end
  end
  if #MENU.items > nvis then
    gc:setColorRGB(120, 120, 120); gc:setFont("sansserif", "r", 9)
    gc:drawString(sel .. "/" .. #MENU.items, w - 34, h - 32, "top")
  end
  pied(gc, w, h, "▲▼ choisir   enter : ouvrir   esc : retour")
end

local function dessinerSaisie(gc, w, h)
  bandeau(gc, w, "Saisie")
  gc:setColorRGB(0, 0, 0); gc:setFont("sansserif", "b", 11)
  gc:drawString(saisie.msg, 6, 30, "top")
  gc:setColorRGB(245, 245, 255); gc:fillRect(4, 52, w - 8, 24)
  gc:setColorRGB(30, 70, 160); gc:drawRect(4, 52, w - 8, 24)
  gc:setColorRGB(0, 0, 0); gc:setFont("sansserif", "r", 11)
  gc:drawString(saisie.txt, 8, 56, "top")
  local cx = 8 + gc:getStringWidth(saisie.txt:sub(1, saisie.cur))
  gc:drawLine(cx, 55, cx, 73)
  -- apercu 2D
  if saisie.txt ~= "" then
    local ok, b = pcall(function() return mise(gc, arbre(saisie.txt), 1) end)
    if ok then gc:setColorRGB(0, 0, 0); b.draw(gc, 8, 90 + b.asc) end
  end
  pied(gc, w, h, "◄► curseur  ▲▼ historique  enter : ok  esc : annuler")
end

local function couper(gc, s, larg)
  local out, cur = {}, ""
  for mot in s:gmatch("%S+") do
    local essai = cur == "" and mot or (cur .. " " .. mot)
    if gc:getStringWidth(essai) <= larg then cur = essai
    else if cur ~= "" then table.insert(out, cur) end; cur = mot end
  end
  if cur ~= "" then table.insert(out, cur) end
  if #out == 0 then out = {""} end
  return out
end

local function hauteurElt(gc, e, w)
  if e.k == "txt" or e.k == "gris" or e.k == "alerte" then
    gc:setFont("sansserif", e.k == "gris" and "i" or (e.k == "alerte" and "b" or "r"), 10)
    e._l = couper(gc, e.s, w - 10)
    return 4 + 15 * #e._l
  end
  if e.k == "tab" then return hauteurTab(e) + 2 end
  if e.k == "graphe" then return HGRAPHE + 14 end
  if e.k == "courbes" then return HGRAPHE + 14 end
  if e.k == "math" or e.k == "res" then
    local ok, b = pcall(function() return mise(gc, arbre(e.s), 1, e.k == "res") end)
    e._b = ok and b or nil
    police(gc, 1, e.k == "res")
    if e._b then return e._b.asc + e._b.desc + 6 end
  end
  return 18
end

local function dessinerVue(gc, w, h)
  bandeau(gc, w, vue.titre)
  gc:clipRect("set", 0, 20, w, h - 36)
  local y = 22 - vue.haut
  local total = 0
  for _, e in ipairs(vue.doc) do
    local he = hauteurElt(gc, e, w)
    if y + he > 20 and y < h - 16 then
      if e.k == "tab" then dessinerTab(gc, e, 2, y + 1, w - 2)
      elseif e.k == "graphe" then dessinerGraphe(gc, e, 2, y + 1, w - 2)
      elseif e.k == "courbes" then dessinerCourbes(gc, e, 2, y + 1, w - 2)
      elseif e.k == "titre" then
        gc:setColorRGB(220, 230, 250); gc:fillRect(0, y, w, he)
        gc:setColorRGB(BLEU[1], BLEU[2], BLEU[3]); gc:setFont("sansserif", "b", 11); gc:drawString(e.s, 4, y + 2, "top")
      elseif e.k == "txt" or e.k == "gris" or e.k == "alerte" then
        if e.k == "txt" then gc:setColorRGB(0, 0, 0); gc:setFont("sansserif", "r", 10)
        elseif e.k == "gris" then gc:setColorRGB(110, 110, 110); gc:setFont("sansserif", "i", 10)
        else gc:setColorRGB(200, 0, 0); gc:setFont("sansserif", "b", 10) end
        for i, l in ipairs(e._l or {e.s}) do gc:drawString(l, 4, y + 2 + 15 * (i - 1), "top") end
      else
        local res = e.k == "res"
        if res then gc:setColorRGB(0, 120, 0) else gc:setColorRGB(0, 0, 0) end
        gc:setFont("sansserif", res and "b" or "r", 10)
        local x = 8 + gc:getStringWidth(e.avant)
        if e._b then
          local base = y + 3 + e._b.asc
          gc:drawString(e.avant, 8, base, "baseline")
          e._b.draw(gc, x, base)
          gc:setFont("sansserif", res and "b" or "r", 10)
          gc:drawString(e.apres, x + e._b.w, base, "baseline")
        else gc:drawString(e.avant .. e.s .. e.apres, 8, y + 2, "top") end
      end
    end
    y = y + he; total = total + he
  end
  gc:clipRect("reset")
  vue.total = total
  vue.visible = h - 36
  pied(gc, w, h, "▲▼ défiler  ◄► page  enter/esc : menu")
end

function on.paint(gc)
  local w, h = platform.window:width(), platform.window:height()
  gc:setColorRGB(255, 255, 255); gc:fillRect(0, 0, w, h)
  if ecran == "menu" then dessinerMenu(gc, w, h)
  elseif ecran == "saisie" then dessinerSaisie(gc, w, h)
  else dessinerVue(gc, w, h) end
end

------------------------------------------------------------------ touches
function on.arrowUp()
  if ecran == "menu" then sel = sel > 1 and sel - 1 or #MENU.items
  elseif ecran == "saisie" then
    if saisie.h > 1 then saisie.h = saisie.h - 1; saisie.txt = HIST[saisie.h]; saisie.cur = #saisie.txt end
  else vue.haut = math.max(0, vue.haut - 16) end
  inval()
end

function on.arrowDown()
  if ecran == "menu" then sel = sel < #MENU.items and sel + 1 or 1
  elseif ecran == "saisie" then
    if saisie.h < #HIST then saisie.h = saisie.h + 1; saisie.txt = HIST[saisie.h]; saisie.cur = #saisie.txt
    else saisie.h = #HIST + 1; saisie.txt = ""; saisie.cur = 0 end
  else vue.haut = math.min(math.max(0, (vue.total or 0) - (vue.visible or 120)), vue.haut + 16) end
  inval()
end

function on.arrowLeft()
  if ecran == "saisie" then saisie.cur = math.max(0, saisie.cur - 1)
  elseif ecran == "vue" then vue.haut = math.max(0, vue.haut - (vue.visible or 150) + 20) end
  inval()
end

function on.arrowRight()
  if ecran == "saisie" then saisie.cur = math.min(#saisie.txt, saisie.cur + 1)
  elseif ecran == "vue" then vue.haut = math.min(math.max(0, (vue.total or 0) - (vue.visible or 120)), vue.haut + (vue.visible or 150) - 20) end
  inval()
end

function on.charIn(ch)
  if ecran == "saisie" then
    saisie.txt = saisie.txt:sub(1, saisie.cur) .. ch .. saisie.txt:sub(saisie.cur + 1)
    saisie.cur = saisie.cur + #ch; inval()
  elseif ecran == "menu" and tonumber(ch) and MENU.items[tonumber(ch)] then
    sel = tonumber(ch); MENU.items[sel][2]()
  end
end

function on.backspaceKey()
  if ecran == "saisie" and saisie.cur > 0 then
    saisie.txt = saisie.txt:sub(1, saisie.cur - 1) .. saisie.txt:sub(saisie.cur + 1)
    saisie.cur = saisie.cur - 1; inval()
  end
end

function on.clearKey()
  if ecran == "saisie" then saisie.txt = ""; saisie.cur = 0; inval() end
end

function on.enterKey()
  if ecran == "menu" then MENU.items[sel][2]()
  elseif ecran == "saisie" then
    local t = saisie.txt
    if t == "" then return end
    memoriser(t)
    local s = saisie.suite
    local ok, err = pcall(s, t)
    if not ok then vider(); T("Erreur"); A(tostring(err)); montrer("Erreur") end
  else menuPrincipal() end
end

function on.escapeKey()
  if ecran == "menu" and MENU.titre ~= "MATH_1 – solveur" then menuPrincipal()
  elseif ecran ~= "menu" then menuPrincipal() end
end

------------------------------------------------------------------ demarrage et sauvegarde
function on.construction() menuPrincipal() end
function on.resize() inval() end
function on.save() return {hist = HIST} end
function on.restore(t) if type(t) == "table" and t.hist then HIST = t.hist end end
