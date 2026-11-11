-- socle commun des classeurs TI-Nspire (genere par tools/nspire/extraire_socle.py, ne pas editer a la main)
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

-- opts (facultatif) : titre (bandeau), aide (texte explicatif sous la question, coupé en lignes),
-- erreur (ligne rouge), note (ligne grise : touches), vide = true (ENTER accepte un champ vide), pied (barre du bas)
local function demander(msg, suite, defaut, opts)
  opts = opts or {}
  saisie = {msg = msg, txt = defaut or "", cur = #(defaut or ""), h = #HIST + 1, suite = suite,
    titre = opts.titre, aide = opts.aide, erreur = opts.erreur, note = opts.note, vide = opts.vide, pied = opts.pied}
  ecran = "saisie"; inval()
end

local function montrer(titre)
  table.insert(ARCH, {titre = titre, doc = DOC})
  while #ARCH > 20 do table.remove(ARCH, 1) end
  vue = {haut = 0, doc = DOC, titre = titre}
  ecran = "vue"; inval()
end

------------------------------------------------------------------ helpers generiques
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

local menuPrincipal
local TITRE_APP = "Solveur"
local function historiqueResultats()
  local it = {}
  for i = #ARCH, 1, -1 do
    local d = ARCH[i]
    table.insert(it, {d.titre, function() vue = {haut = 0, doc = d.doc, titre = d.titre}; ecran = "vue"; inval() end})
  end
  if #it == 0 then table.insert(it, {"(vide)", function() end}) end
  MENU = {titre = "Historique", items = it}; sel = 1; ecran = "menu"; inval()
end
local SOLVEURS = {}          -- fonctions exposees aux tests sur PC (tools/nspire/test_pc.py)
SOLVEURS_GLOBAL = SOLVEURS
local function GRILLE(titre, lignes, opts)
  -- lignes : {{"libelle", "montant", "montant2"…, gras=true, trait=true}} ; opts.entetes = {"", "N", "N-1"}
  table.insert(DOC, {k = "grille", titre = titre, lignes = lignes, opts = opts or {}})
end
local function fmt(x, dec)
  -- montant avec separateur des milliers (apostrophe suisse)
  if type(x) ~= "number" then return tostring(x or "") end
  dec = dec or 0
  local neg = x < 0
  local s = string.format("%." .. dec .. "f", math.abs(x))
  local ent, frac = s:match("^(%d+)(.*)$")
  ent = ent:reverse():gsub("(%d%d%d)", "%1'"):reverse():gsub("^'", "")
  return (neg and "−" or "") .. ent .. frac
end

