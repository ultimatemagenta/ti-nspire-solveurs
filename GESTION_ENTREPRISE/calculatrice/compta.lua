-- socle commun des classeurs TI-Nspire (edite a la main depuis le 11.11.2026 ; ne plus relancer extraire_socle.py)
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
  -- opts.compact = true : grille compacte qui tient sur un ecran (police 9 -> 7, lignes 13 -> 9 px, colonnes mesurees,
  --   titre facultatif) ; plus de opts.max lignes (10 par defaut) : tableaux successifs « titre (1/2) », chacun sur un ecran.
  --   opts.pos : rang d'insertion dans le document (2 = juste sous le titre) ; opts.legende : ligne grise en petit sous les tableaux.
  opts = opts or {}
  if not opts.compact then table.insert(DOC, {k = "grille", titre = titre, lignes = lignes, opts = opts}); return end
  local n, k = #lignes, 0
  local nb = math.max(1, math.ceil(n / (opts.max or 10)))
  local par = math.ceil(n / nb)
  local function poser(e) if opts.pos then table.insert(DOC, opts.pos + k, e) else table.insert(DOC, e) end; k = k + 1 end
  for c = 1, nb do
    local sous = {}
    for i = (c - 1) * par + 1, math.min(n, c * par) do table.insert(sous, lignes[i]) end
    local t = titre
    if nb > 1 then t = (titre or "Tableau") .. " (" .. c .. "/" .. nb .. ")" end
    poser({k = "grille", compact = true, titre = t, lignes = sous, opts = opts})
  end
  if opts.legende and opts.legende ~= "" then poser({k = "gris", s = opts.legende, petit = true}) end
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


-- ===== module 00_commun.lua
-- 00_commun.lua : outils communs du classeur compta (charge en premier, apres le socle)
TITRE_APP = "Compta – solveur"
MENUS_COMPTA = {}   -- chaque module ajoute : table.insert(MENUS_COMPTA, {ordre = n, titre = "…", items = {{"libellé", fonction}, …}})
do   -- tout dans un bloc : limite de 200 variables locales du script principal

-- nombres : accepte 12'500, 12 500, 12500.5, 12,5 (virgule décimale), 15% -> 0.15, expressions simples (1200*3, 15+10+30)
local function num(s)
  if type(s) == "number" then return s end
  if s == nil then return nil end
  s = tostring(s):gsub("'", ""):gsub("’", ""):gsub("%s", ""):gsub(",", ".")
  local pc = s:match("^(.-)%%$")
  if pc then local v = num(pc); return v and v / 100 end
  local v = tonumber(s)
  if v then return v end
  if s:match("^[%d%.%+%-%*/%(%)]+$") then
    local f = (loadstring or load)("return " .. s)
    if f then local ok, r = pcall(f); if ok and type(r) == "number" then return r end end
  end
  return nil
end

-- pourcentage affiche a la maniere du prof : 14.44 %
local function pct(x, dec) if not x then return "?" end; return string.format("%." .. (dec or 2) .. "f %%", x * 100) end
local function dec2(x) if not x then return "?" end; return string.format("%.2f", x) end

-- montant : 12'500, 1'670'841.5, 1'216.8
local function montant(x)
  if type(x) ~= "number" then return "?" end
  if math.abs(x - math.floor(x + 0.5)) < 1e-9 then return fmt(x, 0) end
  if math.abs(x * 10 - math.floor(x * 10 + 0.5)) < 1e-6 then return fmt(x, 1) end
  return fmt(x, 2)
end

-- une saisie est-elle une composition (« 15+10+30 ») plutot qu'un montant seul ?
local function estExpr(s)
  s = tostring(s or ""):gsub("%s", "")
  return s:find("[%+%*/]", 2) ~= nil or s:find("%-", 2) ~= nil
end

-- « 35600+292979-6 » -> « 35'600 + 292'979 − 6 » (pour ecrire l'application numerique d'une composition)
local function exprTexte(s)
  s = tostring(s or ""):gsub("'", ""):gsub("’", ""):gsub("%s", ""):gsub(",", ".")
  s = s:gsub("%d+%.?%d*", function(n) local x = tonumber(n); return x and montant(x) or n end)
  s = s:gsub("%+", " + "):gsub("%-", " − "):gsub("%*", " × "):gsub("/", " ÷ ")
  return (s:gsub("^%s+", ""))
end

-- formulaire en une ligne « clé=valeur ; clé=valeur » (saisie éclair, et arguments des solveurs dans les tests)
-- champs : {{cle="ca", lib="Chiffre d'affaires", defaut="1000000"}, …} ; v._txt[cle] garde le texte saisi (composition)
local function lireChamps(txt, champs)
  local v = {_txt = {}}
  for _, c in ipairs(champs) do
    v[c.cle] = num(c.defaut)
    if c.defaut ~= nil then v._txt[c.cle] = tostring(c.defaut) end
  end
  for paire in tostring(txt or ""):gmatch("[^;]+") do
    local k, val = paire:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
    if k then v[k] = num(val); v._txt[k] = val end
  end
  return v
end

local function aideChamps(champs)
  local t = {}
  for _, c in ipairs(champs) do table.insert(t, c.cle .. " = " .. c.lib) end
  return table.concat(t, " ; ")
end

-- demande un formulaire : une ligne pre-remplie avec les valeurs par defaut, modifiable
local function formulaire(titre, champs, suite)
  local pre = {}
  for _, c in ipairs(champs) do table.insert(pre, c.cle .. "=" .. (c.defaut or "")) end
  demander(titre, function(txt) suite(lireChamps(txt, champs), txt) end, table.concat(pre, ";"),
    {aide = aideChamps(champs), note = "Modifier les valeurs après « = » ; ENTER : calculer."})
end

-- questionnaire guide : une question par champ, pre-remplie avec la valeur par defaut.
-- champs : {{cle = "liq", lib = "Liquidités", defaut = "35+30", aide = "Liquidités = caisse + poste + banque …",
--            opt = true (vide = ignoré), texte = true (pas un nombre : nom…), valider = function(s) return msgErreur end}, …}
-- Touches : ENTER garde la valeur ; « < » (seul ou en fin de saisie) revient à la question précédente ;
-- « ! » valide tout le reste par défaut ; champ vide (ou « - ») = ignoré.
-- suite(v, brut, rep) : v = valeurs numériques (v._txt = textes saisis), brut = « cle=texte;… » (comme formulaire), rep = textes par rang
local NOTE_Q = "ENTER : garder · < : question précédente · ! : tout le reste par défaut · esc : annuler"
local function questionnaire(titre, champs, suite)
  local rep = {}
  for i, c in ipairs(champs) do rep[i] = c.defaut ~= nil and tostring(c.defaut) or "" end
  local i, erreur = 1, nil
  local poser
  local function fin()
    local v, parts = {_txt = {}}, {}
    for k, c in ipairs(champs) do
      local s = rep[k]
      v._txt[c.cle] = s
      if c.texte then v[c.cle] = s ~= "" and s or nil else v[c.cle] = num(s) end
      table.insert(parts, c.cle .. "=" .. s)
    end
    suite(v, table.concat(parts, ";"), rep)
  end
  poser = function()
    local c = champs[i]
    local note = NOTE_Q .. ((c.opt or c.defaut == nil or c.defaut == "") and " · vide : ignoré" or "")
    demander(c.lib, function(txt)
      local t = tostring(txt or ""):gsub("^%s+", ""):gsub("%s+$", "")
      erreur = nil
      local cmd = t:sub(-1)
      if cmd == "<" then i = math.max(1, i - 1); return poser() end
      if cmd == "!" then
        local reste = t:sub(1, -2):gsub("%s+$", "")
        if reste ~= "" then rep[i] = reste end
        return fin()
      end
      if t == "-" then t = "" end
      if t ~= "" and not c.texte and num(t) == nil then
        erreur = "« " .. t .. " » n'est pas un nombre (exemples : 12500, 12'500, 15+10+30, 15%)."
        return poser()
      end
      if c.valider then
        erreur = c.valider(t)
        if erreur then return poser() end
      end
      rep[i] = t
      i = i + 1
      if i > #champs then fin() else poser() end
    end, rep[i], {titre = titre .. "  " .. i .. "/" .. #champs, aide = c.aide, erreur = erreur, note = note, vide = true,
      pied = "enter : ok   < : précédente   ! : fin   esc : annuler"})
  end
  if #champs == 0 then fin() else poser() end
end

-- ligne de calcul « formule ; application numerique ; resultat » (texte simple, pas de CAS)
local function calc(nom, formule, application, resultat)
  X(nom .. " = " .. formule)
  M("", "", "  = " .. application)
  R("  = ", "", resultat)
end

-- commentaire de ratio : valeur, comparaison a la norme, consequence
local function commentaire(valeur, norme, ok, consequence)
  G("Commentaire : " .. valeur .. (norme and (" ; valeur indicative " .. norme) or "") .. " → " .. (ok and "satisfaisant" or "insuffisant") .. ". " .. (consequence or ""))
end

-- rend les helpers visibles aux modules suivants
COMMUN = {num = num, pct = pct, dec2 = dec2, montant = montant, estExpr = estExpr, exprTexte = exprTexte,
  lireChamps = lireChamps, formulaire = formulaire, questionnaire = questionnaire, calc = calc, commentaire = commentaire,
  aideChamps = aideChamps}
end

-- ===== module 10_aide.lua
-- 10_aide.lua : aide-mémoire du classeur compta (consultation : tableaux vides, schémas, 26 ratios, formules,
-- définitions, articles du CO, pièges et barème, phrases de commentaire). Menu ordre 10.
-- Abréviations des sources : voir l'écran « Sources (abréviations) » (SOLVEURS.aide_sources).
do
  local E = "…"   -- case à compléter

  local function S(s) G("Source : " .. s) end

  -- ligne de grille : libellé + n cases vides ; o = options (gras, trait, fond, retrait) ou cases imposées
  local function lv(lib, n, o)
    local t = {lib}
    for i = 1, n do t[i + 1] = E end
    if o then for k, v in pairs(o) do t[k] = v end end
    return t
  end
  -- ligne de section (fond bleuté, sans montants)
  local function sec(lib) return {lib, gras = true, fond = true} end
  -- compte de résultat en 2 colonnes : charge (case à gauche) ou produit (case à droite)
  local function ch(lib, v, o) local t = {lib, v or E, ""}; if o then for k, x in pairs(o) do t[k] = x end end; return t end
  local function pr(lib, v, o) local t = {lib, "", v or E}; if o then for k, x in pairs(o) do t[k] = x end end; return t end

  -- enregistre un écran : exposé aux tests (SOLVEURS.aide_<cle>) et renvoyé comme entrée de menu
  local function ecr(lib, cle, titre, corps)
    local f = function() vider(); corps(); montrer(titre) end
    SOLVEURS["aide_" .. cle] = f
    return {lib, f}
  end
  local function sousMenu(lib, titre, items)
    return {lib, function() MENU = {titre = titre, items = items}; sel = 1; ecran = "menu"; inval() end}
  end

  ------------------------------------------------------------------ révision du 12.11
  local revision = ecr("Révision du 12.11 (test 2025)", "revision", "Test 2025 : 10 exercices", function()
    T("Test intermédiaire 2025 : 51,5 pts")
    G("Chapitres 37, 44, 51 (≤ p.65 imprimée). Matériel : écriture + calculatrice simple, pas de CAS, pas de résumé.")
    GRILLE("Exercices et points", {
      {"1 Résultat réel (RL)", "3", "37"},
      {"2 CR à 2 degrés", "7", "44"},
      {"3 Liquidités, couvert.", "6.5", "51"},
      {"4 Stock CO 960c", "1", "37"},
      {"5 Ratios 3 bilans", "9", "51"},
      {"6 Point mort quantité", "2", "44"},
      {"7 Tableau des RL", "8", "37"},
      {"8 Graphique du seuil", "5", "44"},
      {"9 Titres cotés / non", "3", "37"},
      {"10 Licence (44.16)", "7", "44"},
      {"Total", "51.5", "", gras = true, trait = true},
    }, {entetes = {"Exercice", "Pts", "Chap."}})
    X("Où regarder dans l'aide-mémoire : ex. 1 et 7 → Tableaux vides › Tableau des RL ; ex. 2 → CR à 2 degrés ; "
      .. "ex. 3 et 5 → Ratios + Phrases de commentaire ; ex. 4 et 9 → Stock, Titres ; ex. 6, 8, 10 → Formules › chap. 44.")
    A("Commentaires : 2 pts chacun contre 0,5 pt par ratio calculé. 8 pts sur 15,5 du chap. 51 sont des commentaires.")
    X("Note = 1 + 5 × points ÷ 51,5 ; 4 = 30,9 pts (60 %).")
    S("[B] §1, §7 ; [T25] ; [C25]")
  end)

  ------------------------------------------------------------------ tableaux vides
  local tBilan = ecr("Bilan analytique", "bilan", "Bilan analytique (vide)", function()
    T("Bilan analytique : à compléter")
    GRILLE("Actif", {
      sec("Actifs circulants (AC)"),
      lv("Liquidités", 2, {retrait = 1}),
      lv("Créances", 2, {retrait = 1}),
      lv("./. Ducroire", 2, {retrait = 2}),
      lv("Stocks", 2, {retrait = 1}),
      lv("Total AC", 2, {gras = true, trait = true}),
      sec("Actifs immob. (AI)"),
      lv("Immobilisations", 2, {retrait = 1}),
      lv("./. FAC", 2, {retrait = 2}),
      lv("Participations", 2, {retrait = 1}),
      lv("Total AI", 2, {gras = true, trait = true}),
      lv("TOTAL ACTIF", 2, {gras = true, trait = true}),
    }, {entetes = {"Actif", "N-1", "N"}})
    GRILLE("Passif", {
      sec("CE à court terme"),
      lv("Dettes fournisseurs", 2, {retrait = 1}),
      lv("Passifs de régul.", 2, {retrait = 1}),
      lv("Dividende décidé", 2, {retrait = 1}),
      lv("Total CE ct", 2, {gras = true, trait = true}),
      sec("CE à long terme"),
      lv("Emprunts, hypothèques", 2, {retrait = 1}),
      lv("Provisions à lt", 2, {retrait = 1}),
      lv("Total CE lt", 2, {gras = true, trait = true}),
      sec("Capitaux propres (FP)"),
      lv("Capital social", 2, {retrait = 1}),
      lv("Capital de croissance", 2, {retrait = 1}),
      lv("Total FP", 2, {gras = true, trait = true}),
      lv("TOTAL PASSIF", 2, {gras = true, trait = true}),
    }, {entetes = {"Passif", "N-1", "N"}})
    T("Règles de classement")
    X("• Répartir le bénéfice AVANT de classer ; dividende décidé → CE ct.")
    X("• Actifs de régularisation → créances ; passifs de régularisation → CE ct.")
    X("• Ducroire et fonds d'amortissement (FAC) en déduction de l'actif concerné.")
    X("• Titres de placement → liquidités ; participations (≥ 20 % des voix) → AI.")
    X("• Provision à long terme → CE lt ; actionnaires (capital non libéré) et pertes reportées en déduction des FP.")
    X("• Capital de croissance = réserves issues du bénéfice + bénéfice reporté + réserves latentes.")
    A("Au test, garder le classement du bilan donné (2025 : dividendes en CE lt dans l'énoncé, suivi par le corrigé).")
    X("Contrôle : total actif = total passif.")
    S("[51 p.4, p.10] ; CLAUDE.md du cours (sous-totaux) ; [C25] ex. 3")
  end)

  local tCR2 = ecr("CR à 2 degrés", "cr2", "CR à 2 degrés (vide)", function()
    T("Compte de résultat à 2 degrés")
    GRILLE("1er degré (frais variables)", {
      ch("Déductions accordées"), ch("Achats de march."), ch("Frais d'achats"), ch("Diminution de stock"),
      pr("Ventes de march."), pr("Déductions obtenues"), pr("Augmentation de stock"),
      ch("Marge brute (MB)", E, {gras = true}),
      {"Total", E, E, gras = true, trait = true},
    }, {entetes = {"", "Charges", "Produits"}})
    GRILLE("2e degré (frais fixes)", {
      ch("ACE (FF)"), pr("Marge brute (MB)"),
      ch("Bénéfice net (BN)", E, {gras = true}), pr("ou Perte nette (PN)", E, {gras = true}),
      {"Total", E, E, gras = true, trait = true},
    }, {entetes = {"", "Charges", "Produits"}})
    G("Seul l'un des deux soldes existe : stock (diminution OU augmentation), résultat (BN OU PN). Totaux égaux dans chaque degré.")
    T("Formules à écrire avant le calcul")
    X("CAN = ventes − déductions accordées (− pertes s/créances − frais de vente)")
    X("PRAMA = achats + frais d'achats − déductions obtenues")
    X("PRAMV = PRAMA + diminution de stock (− augmentation)")
    X("MB = CAN − PRAMV = FF + BN")
    T("Exemple du prof : test 2025, ex. 2")
    GRILLE("1er degré", {
      ch("Déductions accordées", "30"), ch("Achats", "1'100"), ch("Frais d'achats", "70"),
      pr("Ventes", "2'000"), pr("Déductions obtenues", "20"), pr("Augmentation stock", "100"),
      ch("Marge brute", "920", {gras = true}),
      {"Total", "2'120", "2'120", gras = true, trait = true},
    }, {entetes = {"", "Charges", "Produits"}})
    GRILLE("2e degré", {
      ch("ACE", "400"), pr("Marge brute", "920"), ch("BN", "520", {gras = true}),
      {"Total", "920", "920", gras = true, trait = true},
    }, {entetes = {"", "Charges", "Produits"}})
    X("PRAMA = 1'100 + 70 − 20 = 1'150 ; PRAMV = 1'150 − 100 = 1'050 ; CAN = 2'000 − 30 = 1'970 ; MB = 1'970 − 1'050 = 920.")
    A("Barème : 1er degré 3 pts, 2e degré 1 pt, PRAMA, PRAMV, CAN 1 pt chacun.")
    S("[44 p.3-4] ; [C25] ex. 2 ; [B] R3")
  end)

  local tCR3 = ecr("CR à 3 degrés", "cr3", "CR à 3 degrés (vide)", function()
    T("Compte de résultat à 3 degrés")
    G("Modèle : 37.15 (compte de résultat interne à 3 degrés). 3e degré = éléments hors exploitation (immeubles, exceptionnels).")
    GRILLE("1er degré", {
      ch("Déductions accordées"), ch("Pertes s/créances"), ch("Achats de march."), ch("Frais d'achats"),
      ch("Variation de stock"), pr("Ventes de march."), pr("Déductions obtenues"),
      ch("Marge brute (MB)", E, {gras = true}),
      {"Total", E, E, gras = true, trait = true},
    }, {entetes = {"", "Charges", "Produits"}})
    GRILLE("2e degré (exploitation)", {
      ch("ACE"), ch("Charges financières"), ch("Amortissements"), pr("Marge brute"), pr("Produits financiers"),
      ch("BN d'exploitation", E, {gras = true}),
      {"Total", E, E, gras = true, trait = true},
    }, {entetes = {"", "Charges", "Produits"}})
    GRILLE("3e degré (hors exploit.)", {
      ch("Charges d'immeubles"), ch("Charges exception."), pr("BN d'exploitation"), pr("Produits d'immeubles"),
      ch("BN de l'exercice", E, {gras = true}),
      {"Total", E, E, gras = true, trait = true},
    }, {entetes = {"", "Charges", "Produits"}})
    G("Variation de stock : côté charges si diminution, côté produits si augmentation.")
    S("[c37 p.17, p.19] (37.15) ; 2e degré avec charges financières : [44 p.4]")
  end)

  local tCRliste = ecr("CR à degrés en liste (51)", "crliste", "CR à degrés (EBITDA, EBIT)", function()
    T("Compte de résultat en liste (chap. 51)")
    GRILLE("Calculs préliminaires", {
      {"CAB (ventes − retours)", E},
      {"CAN = CAB − déd. acc.", E},
      {"  − pertes s/créances", ""},
      {"  − frais directs vente", ""},
      {"PRAMA = achats − ret.", E},
      {"  − déd. obt. + frais ach.", ""},
      {"Variation de stock", E},
      {"PRAMV", E, gras = true},
    }, {entetes = {"", "CHF"}})
    GRILLE("Compte de résultat", {
      lv("CAN", 1),
      lv("./. PRAMV", 1),
      lv("= Marge brute", 1, {gras = true, trait = true}),
      lv("./. Charges de personnel", 1),
      lv("./. Autres ch. d'exploit.", 1),
      lv("= EBITDA", 1, {gras = true, trait = true}),
      lv("./. Amortissements", 1),
      lv("= EBIT", 1, {gras = true, trait = true}),
      lv("./. Charges financières", 1),
      lv("+ Produits financiers", 1),
      lv("= Bénéfice net (BN)", 1, {gras = true, trait = true}),
      lv("./. Impôts", 1),
      lv("= Bénéfice de l'exercice", 1, {gras = true, trait = true}),
    }, {entetes = {"", "CHF"}})
    G("Exemple du manuel : CAN 3'017 ; PRAMV 1'894 ; MB 1'123 ; EBITDA 203 ; EBIT 153 ; BN 152.")
    S("[51 p.31-32] ; modèle 51.19 [c51 p.23-24]")
  end)

  local tRL = ecr("Tableau des réserves latentes", "rl", "Tableau des RL (vide)", function()
    T("Tableau des réserves latentes (modèle du prof)")
    G("Le tableau du prof a 8 colonnes ; ici en 2 volets. RL = valeur réelle − valeur comptable.")
    GRILLE("Volet 1 : bilan initial", {
      lv("./. Ducroire", 3), lv("Titres", 3), lv("Stock de march.", 3), lv("Installations", 3),
      {"Totaux", "", "", E, gras = true, trait = true},
    }, {entetes = {"Comptes", "Compt.", "Réelle", "RL"}})
    GRILLE("Volet 2 : bilan final", {
      lv("./. Ducroire", 4), lv("Titres", 4), lv("Stock de march.", 4), lv("Installations", 4),
      {"Totaux", "", "", E, E, gras = true, trait = true},
    }, {entetes = {"Comptes", "Compt.", "Réelle", "RL", "Var."}})
    T("Puis, formule écrite avant le calcul")
    X("Variation des RL = RL finale − RL initiale")
    X("Bénéfice réel = bénéfice publié + variation des réserves latentes")
    X("Fonds propres réels = fonds propres publiés + réserve latente (au 31.12)")
    A("Ducroire en négatif : comptable −15, réelle −10 → RL = −10 − (−15) = 5 (passif surévalué).")
    A("Stock « aux 2/3 de sa valeur réelle » : réelle = comptable × 3/2.")
    T("Exemple du prof : test 2025, ex. 7")
    GRILLE("Bilan initial", {
      {"./. Ducroire", "−15", "−10", "5"}, {"Titres", "100", "130", "30"},
      {"Stock de march.", "140", "210", "70"}, {"Installations", "175", "210", "35"},
      {"Totaux", "", "", "140", gras = true, trait = true},
    }, {entetes = {"Comptes", "Compt.", "Réelle", "RL"}})
    GRILLE("Bilan final", {
      {"./. Ducroire", "−20", "−12", "8", "3"}, {"Titres", "105", "120", "15", "−15"},
      {"Stock de march.", "150", "225", "75", "5"}, {"Installations", "155", "200", "45", "10"},
      {"Totaux", "", "", "143", "3", gras = true, trait = true},
    }, {entetes = {"Comptes", "Compt.", "Réelle", "RL", "Var."}})
    R("Bénéfice réel = 500 + 3 = 503", "", "")
    R("FP réels = 1'500 + 143 = 1'643", "", "")
    G("Barème : ducroire 2 pts, titres 1, stock 2, installations 1 ; bénéfice réel 1 ; FP réels 1.")
    S("[37 p.18] ; [C25] ex. 7 ; [B] R2, R5")
  end)

  local tStock = ecr("Évaluation du stock (960c)", "stock", "Stock : valeur maximale", function()
    T("Valeur maximale du stock (CO 960c)")
    GRILLE("À compléter", {
      lv("Article 1", 5), lv("Article 2", 5),
      {"Total", "", "", "", "", E, gras = true, trait = true},
    }, {entetes = {"March.", "Qté", "PRA", "VVN", "Éval.", "Total"}})
    X("Évaluation = min(PRA unitaire ; valeur vénale nette) ; total = quantité × évaluation.")
    A("Article par article, jamais sur le total du stock.")
    T("Exemple du prof : test 2025, ex. 4")
    GRILLE("Corrigé", {
      {"Ours en peluche", "10", "12", "11", "11", "110"},
      {"Marmotte en béton", "5", "24", "32", "24", "120"},
      {"Total", "", "", "", "", "230", gras = true, trait = true},
    }, {entetes = {"March.", "Qté", "PRA", "VVN", "Éval.", "Total"}})
    S("[37 p.37] ; [C25] ex. 4 ; modèle 37.20 [c37 p.23-24]")
  end)

  local tTitres = ecr("Titres cotés / non cotés", "titres", "Titres au bilan", function()
    T("Titres au bilan")
    GRILLE("Titres cotés (CO 960b)", {lv("Titre A", 3), lv("Titre B", 3)},
      {entetes = {"Titres", "Nombre", "Prix", "Valeur"}})
    GRILLE("Titres non cotés (960a)", {lv("Titre C", 3), lv("Titre D", 3)},
      {entetes = {"Titres", "Nombre", "Prix", "Valeur"}})
    X("Cotés : cours du 31.12, même au-dessus du prix d'achat (CO 960b) ; si le cours est plus bas, il s'impose (CO 960 al. 3).")
    X("Non cotés : min(prix d'achat ; valeur au 31.12), jamais au-dessus du coût d'acquisition (CO 960a).")
    X("Valeur au bilan = nombre × prix retenu (prix retenu écrit explicitement).")
    T("Exemple du prof : test 2025, ex. 9")
    GRILLE("Cotés", {{"Taupe SA", "10", "70", "700"}, {"Renard SA", "20", "25", "500"}},
      {entetes = {"Titres", "Nombre", "Prix", "Valeur"}})
    GRILLE("Non cotés", {{"Corbeau SA", "15", "200", "3'000"}, {"Éléphant SA", "5", "80", "400"}},
      {entetes = {"Titres", "Nombre", "Prix", "Valeur"}})
    S("[37 p.3, p.35] ; [C25] ex. 9 ; modèle 37.19 [c37 p.22-23] ; [B] R8")
  end)

  local tSeuil = ecr("Seuil de rentabilité", "seuil", "Seuil (vide)", function()
    T("Seuil de rentabilité : tableau")
    GRILLE("Compte de résultat", {
      lv("Chiffre d'affaires", 4),
      lv("./. Charges variables", 4),
      {"Marge brute", "", E, E, E, gras = true, trait = true},
      {"./. Charges fixes", "", "", E, ""},
      {"Marge nette (BN)", "", "", E, "", gras = true, trait = true},
    }, {entetes = {"", "Qté", "Unit.", "CHF", "%"}})
    X("MB unitaire = PV unitaire − CV unitaire")
    X("Seuil (quantité) = charges fixes ÷ MB unitaire → arrondi à l'unité SUPÉRIEURE")
    X("CA au point mort = charges fixes × 100 ÷ taux de MB = CA × CF ÷ MB")
    X("Quantité pour un BN visé = (CF + BN) ÷ MB unitaire")
    T("Exemple du manuel (DVD)")
    GRILLE("Compte de résultat", {
      {"Chiffre d'affaires", "60", "20", "1'200", "100 %"},
      {"./. Charges variables", "60", "12", "720", "60 %"},
      {"Marge brute", "", "8", "480", "40 %", gras = true, trait = true},
      {"./. Charges fixes", "", "", "320", ""},
      {"Marge nette (BN)", "", "", "160", "", gras = true, trait = true},
    }, {entetes = {"", "Qté", "Unit.", "CHF", "%"}})
    R("CA au point mort = 320 × 100 ÷ 40 = 800", "", "")
    R("Seuil = 320 ÷ 8 = 40 DVD", "", "")
    S("[44 p.8-9] ; arrondi : [C25] ex. 6 b, [B] R9")
  end)

  local tRatios = ecr("Tableau des ratios", "tabratios", "Tableau des ratios (vide)", function()
    T("Ratios : présentation du prof")
    GRILLE("Une entreprise (test 2025 ex. 3)", {
      lv("Liquidités 1", 2), lv("Liquidités 2", 2), lv("Liquidités 3", 2), {"Commentaire", "→ 2 pts", ""},
      lv("Couverture 1", 2), lv("Couverture 2", 2), {"Commentaire", "→ 2 pts", ""},
    }, {entetes = {"Ratio", "Calcul", "Résultat"}})
    G("Calcul en fraction (numérateur / dénominateur), puis résultat : liquidités en % (14.44 %), couvertures en décimal (1.28).")
    GRILLE("Trois entreprises (ex. 5)", {
      lv("Liquidités 1", 3), lv("Liquidités 2", 3), lv("Liquidités 3", 3),
      lv("Intensité AI", 3), lv("Endettement", 3), lv("Couverture 2", 3),
    }, {entetes = {"Ratio", "A", "B", "C"}})
    G("Ex. 5 : résultats en décimal (0.82). 3 pts de calculs, 6 pts de commentaires (une à deux phrases par entreprise et par question).")
    S("[C25] ex. 3, ex. 5 ; [B] R6, R7, §3")
  end)

  local tLiq = ecr("Tableau des liquidités (57)", "liquidites", "Tableau des liquidités", function()
    T("Tableau des liquidités (fonds)")
    GRILLE("À compléter", {
      lv("Caisse", 3), lv("Poste", 3), lv("Banque (si fonds)", 3),
      lv("Total du fonds", 3, {gras = true, trait = true}),
    }, {entetes = {"Fonds", "N-1", "N", "Var."}})
    X("Définir d'abord le fonds (avec ou sans banque c/c, titres) : un compte courant débiteur se porte en diminution du fonds.")
    X("Variation du fonds = contrôle du tableau des flux (somme des 3 secteurs).")
    GRILLE("Exemple du manuel", {
      {"Caisse", "7", "4", "−3"}, {"Poste", "17", "9", "−8"},
      {"Total", "24", "13", "−11", gras = true, trait = true},
    }, {entetes = {"Fonds", "N-1", "N", "Var."}})
    S("[57 p.4, p.12] ; modèles 57.2, 57.3")
  end)

  local tTFT = ecr("Tableau des flux (57)", "tft", "Tableau des flux de trésorerie", function()
    T("Tableau des flux de trésorerie (CO 961b)")
    GRILLE("Exploitation (directe)", {
      lv("Encaiss. des clients", 1),
      lv("./. Paiem. fournisseurs", 1),
      lv("./. Paiem. salaires", 1),
      lv("./. Autres ch. payées", 1),
      lv("./. Charges financières", 1),
      lv("= Cash flow", 1, {gras = true, trait = true}),
    }, {entetes = {"", "CHF"}})
    GRILLE("Investissement", {
      lv("./. Investissements", 1),
      lv("+ Désinvestissements", 1),
      lv("= Flux investissement", 1, {gras = true, trait = true}),
    }, {entetes = {"", "CHF"}})
    GRILLE("Financement", {
      lv("+ Augm. capital (agio)", 1),
      lv("+ Nouvel emprunt", 1),
      lv("./. Remboursement", 1),
      lv("./. Dividende N-1 payé", 1),
      lv("= Flux financement", 1, {gras = true, trait = true}),
    }, {entetes = {"", "CHF"}})
    GRILLE("Contrôle", {
      lv("Variation du fonds", 1, {gras = true}),
      lv("Liquidités au 1.1", 1),
      lv("Liquidités au 31.12", 1),
    }, {entetes = {"", "CHF"}})
    GRILLE("Exploitation (indirecte)", {
      lv("Bénéfice net", 1),
      lv("+ Amortissements", 1),
      lv("+ Dotations provisions", 1),
      lv("./. Dissolutions prov.", 1),
      lv("./. Augm. créances", 1),
      lv("./. Augm. stocks", 1),
      lv("+ Augm. dettes fourn.", 1),
      lv("= Cash flow", 1, {gras = true, trait = true}),
    }, {entetes = {"", "CHF"}})
    G("Encaissements positifs, paiements négatifs. Une diminution de créances ou de stock, ou une diminution des dettes fournisseurs : signes inverses.")
    G("Exemple du manuel : CF 65 ; investissement −100 ; financement +24 ; variation du fonds −11 (24 → 13).")
    S("[57 p.9-13, p.21] ; test 2026-02 ex. 2 (corrigé Excel 002_57_06)")
  end)

  local tCMP = ecr("Compte de stock au CMP (59)", "cmp", "Compte de stock (CMP)", function()
    T("Compte de stock au coût moyen pondéré")
    GRILLE("Entrées", {lv("Stock initial", 3), lv("Entrée (date)", 3), lv("Entrée (date)", 3),
      lv("Total entrées", 3, {gras = true, trait = true})}, {entetes = {"Libellé", "Q", "Coût u.", "Total"}})
    GRILLE("Sorties", {lv("Sortie (date)", 3), lv("Sortie (date)", 3), lv("Stock final", 3),
      lv("Total sorties", 3, {gras = true, trait = true})}, {entetes = {"Libellé", "Q", "Coût u.", "Total"}})
    X("CMP = Σ (quantité × coût) ÷ Σ quantités ; sorties et stock final valorisés au CMP.")
    G("Exemple : (120 × 25 + 60 × 28 + 30 × 30) ÷ (120 + 60 + 30) = 26.5714. Test 2026-02 : CMP à 4 décimales.")
    S("[59 p.34] ; modèles 59.13, 59.14")
  end)

  local tableaux = sousMenu("Tableaux vides", "Tableaux vides", {
    tBilan, tCR2, tCR3, tCRliste, tRL, tStock, tTitres, tSeuil, tRatios, tLiq, tTFT, tCMP,
  })

  ------------------------------------------------------------------ schémas
  local sCascade = ecr("PRAMA, PRAMV, CAN, MB", "cascade", "Schéma du 1er degré", function()
    T("Du chiffre d'affaires à la marge brute")
    GRILLE("Chiffre d'affaires", {
      {"Ventes (CAB)", E, "1'100"},
      {"+ Prestations propres", E, ""},
      {"./. Déd. accordées", E, "100"},
      {"./. Pertes s/créances", E, ""},
      {"./. Frais de vente", E, ""},
      {"= CAN", E, "1'000", gras = true, trait = true},
    }, {entetes = {"", "Vide", "44 p.4"}})
    GRILLE("Achats", {
      {"Achats", E, "560"},
      {"+ Frais d'achats", E, "20"},
      {"./. Déd. obtenues", E, "10"},
      {"= PRAMA", E, "570", gras = true, trait = true},
      {"+ Dimin. de stock", E, "30"},
      {"(./. Augm. de stock)", E, ""},
      {"= PRAMV (FV)", E, "600", gras = true, trait = true},
    }, {entetes = {"", "Vide", "44 p.4"}})
    GRILLE("Résultat", {
      {"CAN", E, "1'000"},
      {"./. PRAMV", E, "600"},
      {"= Marge brute", E, "400", gras = true, trait = true},
      {"./. Frais fixes (FF)", E, "350"},
      {"= BN", E, "50", gras = true, trait = true},
    }, {entetes = {"", "Vide", "44 p.4"}})
    X("MB = CAN − PRAMV = FF + BN ; taux de MB = MB × 100 ÷ CAN (ici 40 %).")
    G("Variation de stock = stock final − stock initial : augmentation → PRAMV diminue (côté produits dans le CR en T).")
    S("[44 p.3-4] ; [51 p.31] (CAB, retours)")
  end)

  local sBlocs = ecr("Bilan en blocs, FRN", "blocs", "Bilan en blocs", function()
    T("Bilan en blocs")
    GRILLE("Actif | Passif", {
      {"AC : liquidités", "CE ct", ""},
      {"  créances, stocks", "", ""},
      {"AI : immobilisations", "CE lt", ""},
      {"  participations", "FP", ""},
    }, {entetes = {"Actif", "Passif", ""}})
    X("Liquidités 1, 2, 3 : une partie de l'AC face aux CE ct.")
    X("Couverture 1 : FP face aux AI ; couverture 2 : (FP + CE lt) face aux AI.")
    X("FRN = AC − CE ct = (FP + CE lt) − AI : positif = favorable.")
    X("Règle d'or : les AI sont financés par les capitaux permanents (FP + CE lt) → couverture 2 > 1.")
    X("Capitaux permanents = FP + CE lt.")
    S("[51 p.4, p.11-13]")
  end)

  local sGraphe = ecr("Graphique du seuil", "graphe", "Graphique du seuil", function()
    T("Graphique du point mort : 4 droites")
    X("Abscisse : quantités (ou activité) ; ordonnée : CHF.")
    X("1. CAN = PV × quantité (part de 0)")
    X("2. FV (charges variables) = CV × quantité (part de 0) ; ou la marge brute BB = MB unitaire × quantité")
    X("3. FF (charges fixes) : droite horizontale")
    X("4. PR (prix de revient) = FV + FF (part du niveau des FF)")
    R("Point mort : CAN = PR (ou BB = FF)", "", "")
    X("À gauche : zone de perte (accolade PN entre PR et CAN) ; à droite : zone de bénéfice (accolade BN).")
    X("Lire et annoter les CA demandés (flèches « CAN = … », « PM BN = 0 ») ; nommer les droites dans une légende.")
    G("Test 2025 ex. 8 : point mort 375'000 ; BN 30'000 → 450'000 ; PN 60'000 → 225'000.")
    S("[44 p.10] ; [C25] ex. 8 ; corrigé 44.13 [c44 p.15] ; [B] R10")
  end)

  local sRL = ecr("Réserves latentes et résultat", "schemarl", "RL : résultat et FP", function()
    T("Effet des réserves latentes")
    G("Interne = réel ; externe = comptable, publié. RL = valeur réelle − valeur comptable.")
    GRILLE("Résultat", {
      {"Bénéfice publié", E},
      {"+ Augmentation des RL", E},
      {"(./. Diminution des RL)", E},
      {"= Bénéfice réel", E, gras = true, trait = true},
    }, {entetes = {"", "CHF"}})
    GRILLE("Fonds propres", {
      {"FP publiés", E},
      {"+ RL au 31.12", E},
      {"= FP réels (internes)", E, gras = true, trait = true},
    }, {entetes = {"", "CHF"}})
    X("Ce n'est pas l'existence d'une RL qui influence le résultat, mais sa variation : constituer des RL diminue le bénéfice publié, les dissoudre l'augmente.")
    G("Test 2025 ex. 1 : RL 160 → 120 (diminution 40) ; perte publiée −40 − 40 = perte réelle −80.")
    S("[37 p.18] ; [C25] ex. 1")
  end)

  local schemas = sousMenu("Schémas", "Schémas", {sCascade, sBlocs, sGraphe, sRL})

  ------------------------------------------------------------------ ratios (26 de la liste Profil M)
  local function ratio(nom, formule, unite, norme, lecture)
    X(nom .. " = " .. formule)
    G(unite .. " · " .. norme .. (lecture and (" · " .. lecture) or ""))
  end

  local rVue = ecr("Vue d'ensemble (26)", "ratios", "Les 26 ratios", function()
    T("Liste Profil M : 26 ratios")
    GRILLE("Bilan", {
      {"Liquidité I", "%", "20-30 %"}, {"Liquidité II", "%", "≥ 100 %"}, {"Liquidité III", "%", "> 150 %"},
      {"Intensité AC", "%", "secteur"}, {"Intensité AI", "%", "secteur"},
      {"Endettement", "%", "repères"}, {"Financement propre", "%", "élevé"}, {"Autofinancement", "%", "âge"},
      {"Couverture I", "% / déc.", "60-80 %"}, {"Couverture II", "% / déc.", "> 100 %"},
    }, {entetes = {"Ratio", "Unité", "Repère"}})
    GRILLE("Compte de résultat", {
      {"Taux de marge brute", "%", "temps"}, {"Taux marge économique", "%", "temps"}, {"Taux de marge nette", "%", "temps"},
    }, {entetes = {"Ratio", "Unité", "Repère"}})
    GRILLE("Cycle des liquidités", {
      {"Rotation créances", "fois", "—"}, {"Durée crédits accordés", "jours", "délai"},
      {"Rotation fournisseurs", "fois", "—"}, {"Durée crédits obtenus", "jours", "délai"},
      {"Rotation stocks", "fois", "—"}, {"Durée stockage", "jours", "courte"},
    }, {entetes = {"Ratio", "Unité", "Repère"}})
    GRILLE("Rentabilité", {
      {"ROI", "%", "temps"}, {"ROE", "%", "temps"},
      {"Rotation de l'actif", "fois", "D1"}, {"Effet de levier", "%", "D1"},
    }, {entetes = {"Ratio", "Unité", "Repère"}})
    GRILLE("Cash flow (57)", {
      {"Ratio d'investissement", "%", "—"}, {"Marge de cash flow", "%", "temps"}, {"Facteur endettement", "déc.", "1-3 ; > 5"},
    }, {entetes = {"Ratio", "Unité", "Repère"}})
    G("% : formule « × 100 » de la liste. Le prof écrit aussi le décimal (couvertures 1.28 et 1.75 en 2025 ex. 3 ; tout en décimal à l'ex. 5).")
    G("D1 : rotation de l'actif et effet de levier hors périmètre du 12.11. « temps » = comparer dans le temps ou au secteur.")
    S("[R] ; glossaire.md §1 ; normes [51 p.9-13], [57 p.62]")
  end)

  local rLiq = ecr("Liquidité (+ FRN)", "r_liquidite", "Ratios de liquidité", function()
    T("Liquidité (trésorerie)")
    ratio("Liquidité I", "Liquidités × 100 ÷ CE à c.t.", "%", "20 à 30 % (0.2 à 0.3)", "trop élevé : liquidités qui dorment ; trop bas : manque de trésorerie")
    ratio("Liquidité II", "(Liquidités + Créances) × 100 ÷ CE à c.t.", "%", "au moins 100 %", "le plus important : peut payer ses dettes à court terme")
    ratio("Liquidité III", "Actifs circulants × 100 ÷ CE à c.t.", "%", "> 150 %", "un léger écart n'est pas forcément grave (dépend de la vente du stock)")
    ratio("FRN (hors liste)", "AC − CE ct = (FP + CE lt) − AI", "CHF", "positif = favorable")
    G("Normes « communément admises par les banques », à prendre avec prudence.")
    G("Test 2025 ex. 3 : 65/450 = 14.44 % ; 535/450 = 118.89 % ; 975/450 = 216.67 %.")
    S("[R] ; [51 p.11-12] ; [C25] ex. 3")
  end)

  local rActif = ecr("Structure de l'actif", "r_actif", "Structure de l'actif", function()
    T("Structure de l'actif (investissement)")
    ratio("Intensité de l'actif circulant", "AC × 100 ÷ Actifs (total du bilan)", "%", "pas de norme", "dépend de l'activité ; comparer au secteur et dans le temps")
    ratio("Intensité de l'actif immobilisé", "AI × 100 ÷ Actifs (total du bilan)", "%", "pas de norme", "AI élevés = frais fixes importants")
    G("IAC + IAI = 100 %. Test 2025 ex. 5 : intensité AI 0.5 / 0.62 / 0.24.")
    S("[R] ; [51 p.9] ; [C25] ex. 5")
  end)

  local rFin = ecr("Structure du passif", "r_financement", "Structure du financement", function()
    T("Structure du passif (financement)")
    ratio("Degré d'endettement", "CE × 100 ÷ Passifs (total du bilan)", "%", "pas de norme chiffrée dans le manuel",
      "élevé = plus de charges financières et de risque, mais peut augmenter le ROE")
    G("Repères tirés des corrigés (pas des normes) : 40 % et 43.78 % « faible » ; 56-58 % « dans la norme » ; 82 % « surendettée ».")
    ratio("Degré de financement propre", "FP × 100 ÷ Passifs (total du bilan)", "%", "élevé = indépendance",
      "sécurité en cas de pertes, charges financières faibles")
    ratio("Degré d'autofinancement", "Capital de croissance × 100 ÷ FP", "%", "pas de norme",
      "dépend de l'âge de l'entreprise et des bénéfices antérieurs")
    G("Endettement + financement propre = 100 %. Capital de croissance = réserves issues du bénéfice + bénéfice reporté + RL.")
    S("[R] ; [51 p.10] ; 51.8 [c51 p.2], 51.10 [c51 p.4]")
  end)

  local rCouv = ecr("Couverture des immob.", "r_couverture", "Couverture des immobilisations", function()
    T("Couverture des immobilisations")
    ratio("Couverture I", "FP × 100 ÷ AI", "% (prof : décimal)", "60 à 80 %", "plus il est élevé, plus le risque est faible")
    ratio("Couverture II", "(FP + CE à l.t.) × 100 ÷ AI", "% (prof : décimal)", "toujours > 100 % (> 1)", "règle d'or : AI financés par des capitaux permanents")
    G("Test 2025 ex. 3 : 895/700 = 1.28 ; 1'225/700 = 1.75 → « La règle d'or est respectée… ».")
    A("Couverture II élevée peut venir d'AI faibles (Husky, ex. 5) : le dire dans le commentaire.")
    S("[R] ; [51 p.13] ; [C25] ex. 3 ; [B] §3")
  end)

  local rMarges = ecr("Marges (CR)", "r_marges", "Taux de marge", function()
    T("Compte de résultat")
    ratio("Taux de marge brute", "MB × 100 ÷ CAN", "%", "comparer dans le temps, au secteur")
    ratio("Taux de marge économique", "EBIT × 100 ÷ CAN", "%", "idem")
    ratio("Taux de marge nette", "BN × 100 ÷ CAN", "%", "idem", "aussi « rendement du chiffre d'affaires »")
    G("Chiffres clés hors liste : évolution du CA = (CA − CA précédent) × 100 ÷ CA précédent ; CA par employé ; CA au m².")
    S("[R] ; [51 p.35] ; 51.21 [c51 p.25]")
  end)

  local rRot = ecr("Rotations et durées", "r_rotations", "Rotations et durées", function()
    T("Cycle des liquidités")
    ratio("Rotation des créances", "CA à crédit ÷ moyenne des créances clients", "fois par an", "—", "CA total si le CA à crédit est inconnu")
    ratio("Durée des crédits accordés", "360 ÷ rotation des clients", "jours", "comparer au délai de paiement accordé", "trop long : relancer les clients")
    ratio("Rotation des fournisseurs", "PRAMA à crédit ÷ moyenne des dettes fournisseurs", "fois par an", "—", "PRAMA total si inconnu")
    ratio("Durée des crédits obtenus", "360 ÷ rotation des fournisseurs", "jours", "comparer aux délais fournisseurs", "trop longue : retards ; trop courte : utile seulement avec escompte")
    ratio("Rotation des stocks", "PRAMV ÷ moyenne des stocks", "fois par an", "—")
    ratio("Durée de stockage", "360 ÷ rotation des stocks", "jours", "aussi courte que possible", "sans rupture de stock")
    X("Moyenne = (valeur N−1 + valeur N) ÷ 2.")
    A("Fournisseurs : PRAMA ; stocks : PRAMV. Ne pas les confondre.")
    S("[R] ; [51 p.27-30] ; 51.24 [c51 p.27-29]")
  end)

  local rRent = ecr("Rentabilité (ROI, ROE)", "r_rentabilite", "Rentabilité", function()
    T("Rentabilité")
    ratio("ROI", "EBIT × 100 ÷ total moyen des bilans", "%", "comparer dans le temps", "indépendant du financement et des impôts")
    ratio("ROE", "BN × 100 ÷ total moyen des capitaux propres", "%", "comparer dans le temps", "intéresse les actionnaires")
    ratio("Rotation de l'actif", "CAN ÷ moyenne des actifs", "fois", "hors périmètre 12.11 (D1)")
    ratio("Effet de levier", "(ROI − t) × ⌀ FE ÷ ⌀ FP, t = charges fin. × 100 ÷ ⌀ FE", "%", "hors périmètre 12.11 (D1)", "si ROI > t, l'endettement augmente le ROE")
    X("EBIT = BN + charges financières − produits financiers (+ impôts). Total moyen = (N−1 + N) ÷ 2.")
    G("ROI = taux de marge économique × rotation de l'actif (D1). ⌀ = moyenne.")
    S("[R] ; [51 p.41-42, p.44] ; 51.25 [c51 p.29-30]")
  end)

  local rCF = ecr("Cash flow (57)", "r_cashflow", "Ratios de cash flow", function()
    T("Cash flow (chap. 57, test de janvier)")
    ratio("Ratio d'investissement", "Cash flow × 100 ÷ investissements nets", "%", "part des investissements financés par le cash flow")
    ratio("Marge de cash flow", "Cash flow × 100 ÷ CAN", "%", "comparer dans le temps")
    ratio("Facteur d'endettement", "Endettement effectif ÷ cash flow", "décimal (années)", "1 à 3 très bon ; > 5 insuffisant", "plus il est faible, plus le prêteur est en sécurité")
    X("Endettement effectif = CE − liquidités − créances.")
    X("Free cash flow (hors liste) = cash flow − investissements nets.")
    X("Investissements nets = investissements − désinvestissements = (AI N − AI N−1) + amortissements (si amort. direct) + pertes s/cession − bénéfices s/cession.")
    S("[R] ; [57 p.62] ; 57.22 [c57 p.45-46]")
  end)

  local ratiosMenu = sousMenu("Ratios (26, Profil M)", "Ratios", {rVue, rLiq, rActif, rFin, rCouv, rMarges, rRot, rRent, rCF})

  ------------------------------------------------------------------ formules par chapitre
  local f37 = ecr("Chap. 37 : évaluation, RL", "f37", "Formules du chap. 37", function()
    T("Réserves latentes")
    X("RL = valeur réelle − valeur comptable (= interne − externe)")
    X("Variation des RL = RL au 31.12 − RL au 01.01")
    X("Résultat réel = résultat publié + variation des RL (augmentation +, diminution −)")
    X("FP réels = FP publiés + RL au 31.12")
    G("Ex. 1 2025 : −40 − 40 = −80. Ex. 7 : 500 + 3 = 503 ; 1'500 + 143 = 1'643.")
    T("Ducroire")
    X("Provision = taux × créances commerciales (5 % suisses, 10 % étrangers)")
    X("RL ducroire = provision comptable − risque réel (passif surévalué)")
    G("37.21 : RL 2'000 → 5'000, +3'000.")
    T("Stock à une fraction")
    X("Comptable = 2/3 du réel ⇒ RL = comptable ÷ 2 ; réel = comptable × 3/2")
    X("RL = 1/3 de la valeur réelle ⇒ comptable = réel × 2/3 (abattement fiscal max. 1/3)")
    X("Stock au bilan (CO 960c) = Σ quantité × min(PRA ; valeur vénale nette), article par article")
    G("37.14 : RL 200'000 → 250'000.")
    T("Titres")
    X("Cotés : nombre × cours du 31.12 (CO 960b) ; non cotés : nombre × min(achat ; valeur) (CO 960a)")
    T("Immobilisation et fisc")
    X("Coût d'acquisition = prix d'achat − remise + transport + installation (max. à la 1re inscription, CO 960a al. 1)")
    G("37.18 : 800'000 + 10'000 + 40'000 − 80'000 = 770'000. Manuel : 50'000 − 5'000 + 1'000 + 200 = 46'200.")
    X("Reprise fiscale = RL comptabilisée − RL admise ; bénéfice fiscal = bénéfice comptable + reprise")
    G("37.24 : 58'700 − 45'500 = 13'200 ; 57'900 + 13'200 = 71'100.")
    S("[37 p.18, p.33, p.35, p.37, p.41] ; [c37 p.15-16, 21, 24-27]")
  end)

  local f44 = ecr("Chap. 44 : seuil", "f44", "Formules du chap. 44", function()
    T("Compte de résultat")
    X("CAN = CAB + prestations propres − déductions accordées − pertes s/créances − frais de vente")
    X("PRAMA = achats + frais d'achats − déductions obtenues")
    X("PRAMV = PRAMA + diminution de stock (− augmentation)")
    X("MB = CAN − PRAMV = FF + BN ; taux de MB = MB × 100 ÷ CAN")
    T("Seuil en valeur")
    X("CA au point mort = CA × CF ÷ MB = CF × 100 ÷ taux de MB")
    X("CA pour un BN visé = (CF + BN) × 100 ÷ taux de MB")
    X("Date du point mort (jours) = CA au PM × 360 ÷ CA annuel")
    X("BN à un autre CA = taux de MB × CA − CF")
    G("Manuel : 350 × 100 ÷ 40 = 875 ; (350 + 100) × 100 ÷ 40 = 1'125 ; 875 × 360 ÷ 1'000 = 315 → 15 novembre. Recueil : arrondi aux 5 centimes.")
    T("Seuil en quantité")
    X("MB unitaire = PV − CV unitaire")
    X("Seuil (qté) = CF ÷ MB unitaire ; qté visée = (CF + BN) ÷ MB unitaire → unité SUPÉRIEURE")
    X("CAN au PM = quantité au PM × PV ; BN = quantité × MB unitaire − CF")
    X("Taux de marge en % du PVN : MB u. = CV × t ÷ (100 − t) ; en % du coût : MB u. = CV × t")
    G("Ex. 6 2025 : 640 ÷ 8 = 80 ; 1'140 ÷ 8 = 142,5 → 143.")
    T("Licence, prix minimum, recettes annexes")
    X("À couvrir = CF + BN visé ; quantité = à couvrir ÷ marge sur coût variable")
    X("Prix minimum = CV unitaire + CF ÷ quantité (commande minimale)")
    X("Baisse de prix : nouveau PV → nouvelle MB u. → nouveau seuil ; augmentation = (nouveau − ancien) × 100 ÷ ancien")
    G("44.16 : 230'000 ÷ 40 = 5'750 ; 80 + 180'000 ÷ 5'000 = 116 ; 4'500 → 6'429 (+42.9 %).")
    X("Recettes annexes déduites des CF ; taux d'occupation = seuil × 100 ÷ capacité (44.15 : 80.125 %)")
    A("Ex. 10 2025 : référence = corrigé du prof (850 ; 6'750 ; +11,1 %), incohérent avec l'énoncé ; méthode du livre en regard : 200 ; 6'750 ; +114 %.")
    S("[44 p.3, p.8-10] ; [c44 p.4, 8-10, 17-19] ; [C25] ex. 6, 10")
  end)

  local f51 = ecr("Chap. 51 : analyse", "f51", "Formules du chap. 51", function()
    T("Bilan")
    X("AC = liquidités + créances + stocks ; FRN = AC − CE ct = (FP + CE lt) − AI")
    X("Capital de croissance = réserves issues du bénéfice + bénéfice reporté (− pertes reportées) + RL")
    T("Compte de résultat")
    X("CAB = ventes − retours des clients ; CAN = CAB − déd. accordées − pertes s/créances − frais directs de vente")
    X("PRAMA = achats − retours aux fournisseurs − déd. obtenues + frais d'achats")
    X("MB − personnel − autres charges d'exploitation = EBITDA ; EBITDA − amortissements = EBIT")
    X("EBIT − charges financières + produits financiers = BN ; BN − impôts = bénéfice de l'exercice")
    T("Rotations, rentabilité")
    X("Moyenne = (N−1 + N) ÷ 2 ; rotation = flux ÷ moyenne ; durée = 360 ÷ rotation")
    X("ROI = EBIT × 100 ÷ total moyen des bilans ; ROE = BN × 100 ÷ FP moyens")
    X("Évolution du CA = (CA − CA précédent) × 100 ÷ CA précédent")
    G("51.21 : 102'000 × 100 ÷ 2'356'000 ≈ 4 %.")
    A("Hors périmètre du 12.11 : décomposition du ROI, effet de levier (51.26-51.33), cycle des liquidités (51.16-51.18).")
    S("[51 p.4, p.10-13, p.27-35, p.41-42] ; CLAUDE.md du cours (hors scope)")
  end)

  local f57 = ecr("Chap. 57 : trésorerie", "f57", "Formules du chap. 57", function()
    T("Cash flow")
    X("Méthode directe : produits à effet monétaire − charges à effet monétaire")
    X("Méthode indirecte : BN + charges sans effet monétaire (amortissements, dotations aux provisions) − produits sans effet monétaire (dissolutions)")
    X("Avec ventes et achats à crédit : − augmentation des créances, − augmentation des stocks, + augmentation des dettes fournisseurs")
    G("Manuel : 260'000 − 120'000 − 15'000 − 80'000 − 26'000 − 4'000 = 15'000 = 5'000 + 10'000.")
    T("Secteurs")
    X("Investissement : − achats d'AI + ventes d'AI ; financement : + capital (agio inclus) + emprunts − remboursements − dividende N−1")
    X("Variation du fonds = cash flow + flux investissement + flux financement = liquidités 31.12 − liquidités 1.1")
    T("Analyse")
    X("Free cash flow = cash flow − investissements nets ; endettement effectif = CE − liquidités − créances")
    X("Investissements nets (amort. indirect) = (AI N − AI N−1) + pertes s/cession − bénéfices s/cession")
    G("Test 2026-02 ex. 2 : 290 − 140 − 155 = −5 (fonds 185 → 180).")
    S("[57 p.9-13, p.21, p.62] ; corrigé Excel 002_57_06")
  end)

  local f59 = ecr("Chap. 59 : coûts", "f59", "Formules du chap. 59", function()
    T("Comptabilité analytique (« 59 ? » au test de janvier)")
    X("Charges de la CAE = charges de la comptabilité générale + charges supplétives − charges non incorporables")
    G("Supplétives : rémunération des capitaux propres, de l'exploitant. Non incorporables : charges exceptionnelles, provisions sans risque réel.")
    X("Coûts en cascade : coût d'achat des matières → coût de production → prix de revient des produits vendus → résultat analytique")
    X("CMP = Σ (quantité × coût) ÷ Σ quantités (test 2026-02 : 4 décimales)")
    X("Coût de l'unité d'œuvre = total de la section après répartition secondaire ÷ nombre d'unités d'œuvre")
    S("[59 p.5, p.34] ; 59.9-59.15 ; test 2026-02 ex. 1, 3")
  end)

  local formules = sousMenu("Formules par chapitre", "Formules", {f37, f44, f51, f57, f59})

  ------------------------------------------------------------------ définitions
  local d37 = ecr("Chap. 37", "def37", "Définitions : chap. 37", function()
    T("Principes d'évaluation")
    X("Principe : pas d'actif surévalué ni de passif sous-évalué ; actifs = valeurs plafonds, passifs = valeurs planchers.")
    X("Valeur maximale d'un actif : prix de revient d'acquisition − moins-value subie.")
    X("Valeur vénale nette : valeur de marché − coûts résiduels prévisibles.")
    X("Valeur nominale : liquidités, créances, dettes (aucun problème d'évaluation).")
    X("Réserves apparentes : créées APRÈS le bénéfice (répartition, agio).")
    X("Réserve latente : fonds propres dissimulés, créés AVANT le bénéfice (sous-évaluation d'actifs, passifs fictifs ou surévalués).")
    X("Catégories : forcées (CO 960a-e), d'appréciation (CO 960, prudence), arbitraires (refusées par IFRS, US GAAP, RPC).")
    X("Reprise fiscale : montant au-delà des normes fiscales, ajouté au bénéfice comptable.")
    X("Participation : ≥ 20 % des droits de vote, détenue à long terme (CO 960d) → AI.")
    S("glossaire.md §2 ; [37 p.3-9, p.18, p.38, p.40-41]")
  end)

  local d44 = ecr("Chap. 44", "def44", "Définitions : chap. 44", function()
    T("Seuil de rentabilité")
    X("Seuil de rentabilité (CA au point mort) : CA pour lequel BN = 0.")
    X("Charges variables : rigoureusement proportionnelles à l'activité (commerce : PRAMV). Charges fixes : toutes les autres (ACE…).")
    X("Marge brute = marge sur coût variable = CAN − charges variables.")
    X("Marge contributive : CAN − charges directes (affectables sans ambiguïté) ; le manuel appelle aussi la MB « marge contributive ».")
    X("Hypothèses : valables à court terme (1 an) ; à long terme, les charges fixes varient par paliers.")
    X("1er degré : frais variables (PRAMV) → MB ; 2e degré : frais fixes → BN ou PN.")
    S("glossaire.md §2 ; [44 p.3-4, p.8-10]")
  end)

  local d51 = ecr("Chap. 51", "def51", "Définitions : chap. 51", function()
    T("Analyse de bilan et du résultat")
    X("Bilan analytique : bilan regroupé en AC (liquidités, créances, stocks), AI ; CE ct, CE lt, FP.")
    X("CE ct : dettes à moins d'un an + passifs de régularisation ; CE lt : plus d'un an (hypothèques).")
    X("Capitaux permanents = FP + CE lt. Règle d'or : AI financés par des capitaux permanents.")
    X("EBITDA : résultat avant intérêts, impôts, amortissements. EBIT : avant intérêts et impôts (« bénéfice économique »).")
    X("Cadence de rotation : nombre de renouvellements par an ; durée moyenne = 360 ÷ cadence.")
    X("Rentabilité = revenu × 100 ÷ capital investi.")
    X("Dividende à payer : CE ct dans le manuel ; garder le classement de l'énoncé.")
    S("glossaire.md §2 ; [51 p.4, p.13, p.27, p.31, p.40]")
  end)

  local d57 = ecr("Chap. 57 et 59", "def57", "Définitions : chap. 57, 59", function()
    T("Trésorerie (57)")
    X("Fonds : regroupement de comptes de liquidités (caisse, poste, banque…) à définir avant tout tableau.")
    X("Tableau des flux de trésorerie : explique la variation du fonds en 3 secteurs (exploitation, investissement, financement), CO 961b.")
    X("Cash flow : flux d'exploitation positif ; cash drain : négatif.")
    X("Charges sans effet monétaire : amortissements, dotations aux provisions ; produit sans effet monétaire : dissolution de provision.")
    X("Free cash flow : cash flow disponible après les investissements nets.")
    T("Coûts (59)")
    X("Charges supplétives : non comptabilisées en comptabilité générale mais incorporées aux coûts. Non incorporables : exclues des coûts.")
    S("[57 p.4, p.9, p.62] ; [59 p.5]")
  end)

  local definitions = sousMenu("Définitions", "Définitions", {d37, d44, d51, d57})

  ------------------------------------------------------------------ articles du CO
  local co = ecr("Articles du CO", "co", "Articles du CO", function()
    T("Code des obligations (droit comptable)")
    X("CO 960 : évaluation individuelle ; prudente sans fausser l'appréciation ; vérifier les actifs surévalués et provisions insuffisantes (al. 3).")
    X("CO 960a : 1re inscription au plus au coût d'acquisition (al. 1) ; ensuite jamais au-dessus (al. 2) ; amortissements et corrections de valeur (al. 3) ; amortissements supplémentaires admis (al. 4).")
    X("CO 960b : actifs cotés au cours du jour de clôture, même au-dessus du coût d'acquisition ; réserve de fluctuation possible.")
    X("CO 960c : stocks au plus au coût d'acquisition ou de revient ; à la valeur vénale nette si elle est inférieure.")
    X("CO 960d : AI = détention à plus de 12 mois ; participation ≥ 20 % des voix.")
    X("CO 960e : dettes à la valeur nominale ; provisions obligatoires (al. 2) ou facultatives (al. 3) ; pas d'obligation de dissoudre (al. 4).")
    X("CO 961b : tableau des flux de trésorerie en 3 secteurs (exploitation, investissement, financement).")
    G("CO 960a al. 4 et 960e al. 4 laissent la porte ouverte aux réserves latentes (en contradiction avec 960 al. 2).")
    S("[37 p.32-38, p.40] ; [57 p.9]")
  end)

  ------------------------------------------------------------------ pièges et barème
  local p37 = ecr("Pièges chap. 37", "pieges37", "Pièges : chap. 37", function()
    T("Réserves latentes, évaluation")
    A("C'est la VARIATION des RL qui change le résultat, pas la RL elle-même.")
    A("FP réels : + RL au 31.12 (pas la variation).")
    A("Ducroire en négatif : RL = comptable − réelle en valeur absolue.")
    A("Stock 2/3 : réelle = comptable × 3/2 ; « RL = 1/3 du réel » : comptable = réel × 2/3.")
    A("Stock (960c) : article par article, jamais sur le total.")
    A("Titres cotés : cours du 31.12 même plus haut ; non cotés : jamais au-dessus du prix d'achat.")
    A("Ducroire fiscal : 5 % des créances commerciales seulement (exclure AFC, etc.).")
    A("Résultat publié négatif : garder le signe (−40 − 40 = −80).")
    S("PLAN-CLASSEUR-COMPTA.md §2.1 ; [C25] ex. 1, 4, 7, 9")
  end)

  local p44 = ecr("Pièges chap. 44", "pieges44", "Pièges : chap. 44", function()
    T("Seuil, compte de résultat")
    A("Augmentation de stock côté PRODUITS (diminue le PRAMV) ; déductions accordées côté charges.")
    A("1er degré = 3 pts sur 4 : soigner PRAMV et variation de stock.")
    A("Quantités arrondies à l'unité SUPÉRIEURE (142,5 → 143).")
    A("Période des charges fixes (jour, mois, an) = période du seuil.")
    A("Base du taux de marge : 33 1/3 % du PVN ≠ 50 % du PRAMV.")
    A("Graphique : 4 droites nommées, CA lus et annotés ; perte visée ⇒ CA sous le seuil.")
    A("Recettes annexes : en déduction des charges fixes.")
    A("Ex. 10 2025 : chiffres du prof en référence (850 ; 6'750 ; +11,1 %), méthode du livre en regard.")
    S("PLAN-CLASSEUR-COMPTA.md §2.2 ; [B] R3, R9, R10")
  end)

  local p51 = ecr("Pièges chap. 51", "pieges51", "Pièges : chap. 51", function()
    T("Ratios")
    A("Prendre la bonne année (N ou N−1) et garder le classement du bilan donné.")
    A("Chaque ratio de liquidité ou de couverture : commentaire (valeur, norme, conséquence) = 2 pts.")
    A("% ou décimal comme le prof : liquidités 14.44 %, couvertures 1.28 ; ex. 5 tout en décimal.")
    A("Rotations : moyenne des 2 bilans ; PRAMA pour les fournisseurs, PRAMV pour les stocks.")
    A("EBIT = avant charges et produits financiers (et impôts).")
    A("Bilan analytique : répartir le bénéfice avant de classer ; titres de placement = liquidités, participations = AI.")
    A("Hors 12.11 : effet de levier, décomposition du ROI, cycle des liquidités.")
    S("PLAN-CLASSEUR-COMPTA.md §2.3 ; [B] R6, R7 ; CLAUDE.md du cours")
  end)

  local bareme = ecr("Barème : règles R1-R10", "bareme", "Barème du prof", function()
    T("Règles de notation (corrigé 2025)")
    X("R1 Points par étape : chaque montant intermédiaire compte.")
    X("R2 Tableau des RL : points par ligne (ducroire, stock 2 pts ; autres 1).")
    X("R3 CR : 1er degré 3 pts, 2e degré 1 pt.")
    X("R4 Un point par grandeur demandée (PRAMA, PRAMV, CAN, BR, FP réels).")
    X("R5 Formule écrite avant le calcul.")
    X("R6 Ratio 0,5 pt, commentaire 2 pts.")
    X("R7 Ratio en fraction puis résultat (% ou décimal).")
    X("R8 Évaluation au bilan en tableau, prix retenu explicite.")
    X("R9 Quantités à l'unité supérieure.")
    X("R10 Graphique : 4 droites, CA lus et annotés.")
    G("Présentation : nom, prénom, classe sur TOUTES les feuilles ; tableaux alignés ; ≈ 3,5 min par point.")
    S("[B] §2, §5, §6")
  end)

  local pieges = sousMenu("Pièges et barème", "Pièges et barème", {p37, p44, p51, bareme})

  ------------------------------------------------------------------ phrases de commentaire
  local phrases = ecr("Phrases de commentaire", "phrases", "Phrases de commentaire", function()
    T("Structure d'un commentaire")
    X("1. Valeur chiffrée  2. Comparaison à la valeur indicative du manuel  3. Conséquence pour l'entreprise (hypothèse, risque).")
    T("Le prof, test 2025 ex. 3")
    X("Liquidités (2 pts) : « L'entreprise a un ratio 1 de mauvaise façon, mais ses créances clients devraient lui permettre de s'en sortir aisément. »")
    X("Couverture (2 pts) : « La règle d'or est respectée et elle se paie ses actifs immobilisés avec ses fonds propres, donc tout va bien. »")
    G("Version complète (hypothèse du barème) : L1 14 % < 20-30 % ; L2 119 % ≥ 100 % → peut payer ses dettes à c.t. ; couverture 2 = 1.75 > 1 (règle d'or) ; couverture 1 = 1.28 : AI financés entièrement par les FP.")
    T("Le prof, 51.10 (ratio par ratio)")
    X("L1 49.50 % : « Ratio un peu trop élevé par rapport à la norme (entre 0.2 et 0.3). »")
    X("L2 89.62 % : « Ratio un peu faible par rapport à la norme (min. 100 %). »")
    X("Endettement 43.78 % : « Endettement faible. » ; financement propre 56.22 % : « Capitaux propres élevés. Sécurité en cas de pertes. »")
    X("Autofinancement 16.67 % : « Dépend de l'âge de l'entreprise et des bénéfices antérieurs. »")
    X("Couverture 1 73.58 % : « Dans la norme (entre 60 et 80 %). » ; couverture 2 96.42 % : « Ratio un peu faible par rapport à la règle d'or (min 100 %). »")
    T("Le prof, 51.8 (trois entreprises)")
    X("Liquidité : « nettement en excédent de liquidités. Peut-être est-ce volontaire pour acheter une autre entreprise ou réaliser prochainement des investissements importants » ; « assez dans la norme (entre 0.2 et 0.3) » ; « largement en manque de liquidités. De plus, ses dettes à court terme sont très importantes ».")
    X("Financement : « avant tout par des fonds propres : cela va compromettre la rentabilité des fonds propres, en revanche les risques sont moindres » ; « correspond assez à la norme » ; « surendettée et très vulnérable en cas de perte ».")
    T("Gabarits (à reformuler)")
    G("Rotation : « Les clients paient en moyenne en … jours pour un délai accordé de … jours : il faut les relancer. »")
    G("Stock : « Le stock reste en moyenne … jours : à réduire sans risquer la rupture. »")
    G("Couverture 2 élevée et AI faibles : « La règle d'or est respectée, mais surtout parce que les immobilisations sont faibles. »")
    S("[C25] ex. 3 ; [c51 p.1-2] (51.8), [c51 p.3-4] (51.10) ; [B] §3 ; [51 p.27-30]")
  end)

  ------------------------------------------------------------------ sources
  local sources = ecr("Sources (abréviations)", "sources", "Sources", function()
    T("Abréviations des sources")
    X("[37 p.N], [44 p.N], [51 p.N], [57 p.N], [59 p.N] : exercices/chap-NN/enonce.md, page PDF N (chap. 51 : page imprimée ≠ PDF, p.11 PDF = p.18 imprimée).")
    X("[c37 p.N]… : exercices/chap-NN/corrige-prof.pdf, page N.")
    X("[R] : sources/txt/Liste des ratios 2018 Profil M.md (26 ratios).")
    X("[T25] / [C25] : examens/2025-11-intermediaire/txt/enonce.md / corrige-prof.md.")
    X("[B] : examens/2026-11-intermediaire/BAREME.md.")
    X("glossaire.md : définitions et lectures des ratios.")
    G("Ce classeur ne va pas au test (calculatrice simple, sans résumé) : tout ici doit être su par cœur.")
  end)

  table.insert(MENUS_COMPTA, {ordre = 10, titre = "Aide-mémoire", items = {
    revision, tableaux, schemas, ratiosMenu, formules, definitions, co, pieges, phrases, sources,
  }})
end

-- ===== module 37_reserves.lua
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

-- ===== module 44_seuil.lua
-- 44_seuil.lua : chapitre 44, compte de résultat à 2 degrés, seuil de rentabilité, marge contributive
-- Types B1-B10 du plan (PLAN-CLASSEUR-COMPTA.md, § 2.2) + extensions (hors cours) : marge de sécurité,
-- levier opérationnel, seuil multiproduits. Données par défaut = corrigés du prof (indiqués dans chaque solveur).
do
  local num, calc = COMMUN.num, COMMUN.calc
  local EPS = 1e-9

  -- montants : entier sans décimales, sinon 2 décimales (format du prof : 420'000, 8'274'285.70)
  local function mt(x)
    if type(x) ~= "number" then return "?" end
    if math.abs(x - math.floor(x + 0.5)) < 1e-6 then return fmt(math.floor(x + 0.5)) end
    return fmt(x, 2)
  end
  local function m2(x) return fmt(x, 2) end
  -- arrondi aux 5 centimes (corrigés du recueil : 8'274'285.70, 13'988'571.45)
  local function r5(x) return math.floor(x * 20 + 0.5) / 20 end
  -- quantité arrondie à l'unité supérieure (corrigé 2025, ex. 6 b)
  local function sup(x) return math.ceil(x - EPS) end
  -- taux « à la manière du prof » : 35 %, 43.75 %, 80.125 %
  local function tx(t, d)
    if not t then return "?" end
    local s = string.format("%." .. (d or 3) .. "f", t * 100)
    s = s:gsub("0+$", ""); s = s:gsub("%.$", "")
    return s .. " %"
  end
  local function dec(x, d)
    local s = fmt(x, d or 2)
    if s:find("%.") then s = s:gsub("0+$", ""); s = s:gsub("%.$", "") end
    return s
  end
  local function nz(x) return x and math.abs(x) > EPS end
  local function lancer(champs, f) return function(txt) f(COMMUN.lireChamps(txt or "", champs)) end end
  local function menu(titre, champs, f) return function() COMMUN.formulaire(titre, champs, function(v) f(v) end) end end

  local MOIS = {"janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"}
  -- jour n d'une année commerciale de 360 jours (mois de 30 jours) -> « 18 mai »
  local function dateJour(n)
    local m = math.max(1, math.min(12, math.ceil(n / 30)))
    return (n - 30 * (m - 1)) .. " " .. MOIS[m]
  end

  -- graphique du seuil : 4 droites (CAN, marge brute, prix de revient, frais fixes), axes normalisés 0-100
  local function graphique(pv, cv, cf, qmax, reperes, nomCA)
    local ymax = pv * qmax
    local function P(q, v) return {q / qmax * 100, v / ymax * 100} end
    local c = {
      {pts = {P(0, 0), P(qmax, pv * qmax)}, coul = {200, 0, 0}},
      {pts = {P(0, 0), P(qmax, (pv - cv) * qmax)}, coul = {0, 140, 0}},
      {pts = {P(0, cf), P(qmax, cf + cv * qmax)}, coul = {0, 90, 200}},
      {pts = {P(0, cf), P(qmax, cf)}, coul = {210, 120, 0}},
    }
    for _, r in ipairs(reperes or {}) do
      table.insert(c, {pts = {P(r.q, 0), P(r.q, pv * r.q)}, coul = {150, 150, 150}})
    end
    table.insert(DOC, {k = "courbes", courbes = c, lo = 0, hi = 100,
      legende = "x : 100 = " .. fmt(qmax) .. " u ; y : 100 = " .. fmt(ymax) .. " CHF"})
    G("Rouge = " .. (nomCA or "CAN") .. " ; vert = marge brute ; bleu = prix de revient (FF + FV) ; orange = frais fixes ; gris = repères.")
    GRILLE("Points pour tracer les droites", {
      {nomCA or "CAN", "0", fmt(pv * qmax)},
      {"Marge brute", "0", fmt((pv - cv) * qmax)},
      {"Prix de revient", fmt(cf), fmt(cf + cv * qmax)},
      {"Frais fixes", fmt(cf), fmt(cf)},
    }, {entetes = {"Droite", "q = 0", "q = " .. fmt(qmax)}})
  end

  local function qmaxRond(q)
    local b = 10 ^ math.floor(math.log(q) / math.log(10))
    for _, k in ipairs({1, 1.2, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10}) do if k * b >= q then return k * b end end
    return 10 * b
  end

  ------------------------------------------------------------------ B1 compte de résultat à 2 degrés
  local CH_CR = {
    {cle = "vb", lib = "ventes brutes", defaut = "2000"},
    {cle = "da", lib = "déductions accordées", defaut = "30"},
    {cle = "pc", lib = "pertes sur créances", defaut = "0"},
    {cle = "fv", lib = "frais de vente", defaut = "0"},
    {cle = "ab", lib = "achats bruts", defaut = "1100"},
    {cle = "do", lib = "déductions obtenues", defaut = "20"},
    {cle = "fa", lib = "frais d'achats", defaut = "70"},
    {cle = "ace", lib = "autres charges d'exploitation", defaut = "400"},
    {cle = "si", lib = "inventaire initial au PRA", defaut = "150"},
    {cle = "sf", lib = "inventaire final au PRA", defaut = "250"},
  }
  local function cr2(v)
    vider()
    T("Compte de résultat à 2 degrés")
    G("Méthode (modèle : 44.1 ; test 2025 ex. 2) : 1er degré = opérations sur marchandises → marge brute ; 2e degré = ACE → résultat net. Formules du 1er degré écrites avant le calcul (44 p.3).")
    local vb, da, pc, fv, ab, dob, fa, ace = v.vb or 0, v.da or 0, v.pc or 0, v.fv or 0, v.ab or 0, v["do"] or 0, v.fa or 0, v.ace or 0
    local varS = (v.sf or 0) - (v.si or 0)   -- > 0 augmentation, < 0 diminution
    local can = vb - da - pc - fv
    local prama = ab + fa - dob
    local pramv = prama - varS
    local mb = can - pramv
    local bn = mb - ace
    -- 1er degré
    local L1, tch, tpr = {}, 0, 0
    local function ch(l, x) if nz(x) then table.insert(L1, {l, mt(x), ""}); tch = tch + x end end
    local function pr(l, x) if nz(x) then table.insert(L1, {l, "", mt(x)}); tpr = tpr + x end end
    ch("Déductions accordées", da); ch("Pertes sur créances", pc); ch("Frais de vente", fv)
    ch("Achats", ab); ch("Frais d'achats", fa)
    pr("Ventes", vb); pr("Déductions obtenues", dob)
    if varS > 0 then pr("Augmentation du stock", varS) elseif varS < 0 then ch("Diminution du stock", -varS) end
    if mb >= 0 then table.insert(L1, {"Marge brute", mt(mb), "", gras = true}); tch = tch + mb
    else table.insert(L1, {"Marge brute (négative)", "", mt(-mb), gras = true}); tpr = tpr - mb end
    table.insert(L1, {"Total", mt(tch), mt(tpr), gras = true, trait = true, fond = true})
    GRILLE("1er degré", L1, {entetes = {"", "Charges", "Produits"}})
    local L2 = {{"ACE", mt(ace), ""}, {"Marge brute", "", mt(mb)}}
    if bn >= 0 then table.insert(L2, {"BN", mt(bn), "", gras = true})
    else table.insert(L2, {"PN", "", mt(-bn), gras = true}) end
    local t2 = math.max(ace + math.max(bn, 0), mb + math.max(-bn, 0))
    table.insert(L2, {"Total", mt(t2), mt(t2), gras = true, trait = true, fond = true})
    GRILLE("2e degré", L2, {entetes = {"", "Charges", "Produits"}})
    G("Augmentation du stock côté produits (elle diminue le PRAMV) ; diminution côté charges. Déductions accordées côté charges, obtenues côté produits.")
    T("PRAMA, PRAMV, CAN, marge brute")
    calc("PRAMA", "achats + frais d'achats − déductions obtenues", mt(ab) .. " + " .. mt(fa) .. " − " .. mt(dob), m2(prama))
    local sv = varS >= 0 and (" − " .. mt(varS) .. " (augmentation)") or (" + " .. mt(-varS) .. " (diminution)")
    calc("PRAMV", "PRAMA ± variation de stock (+ diminution, − augmentation)", mt(prama) .. sv, m2(pramv))
    local app = mt(vb) .. " − " .. mt(da)
    if nz(pc) then app = app .. " − " .. mt(pc) end
    if nz(fv) then app = app .. " − " .. mt(fv) end
    calc("CAN", "ventes − déductions accordées" .. ((nz(pc) or nz(fv)) and " − pertes sur créances − frais de vente" or ""), app, m2(can))
    calc("MB", "CAN − PRAMV", mt(can) .. " − " .. mt(pramv), m2(mb))
    if nz(can) then calc("MB en % du CAN", "MB × 100 ÷ CAN", mt(mb) .. " × 100 ÷ " .. mt(can), tx(mb / can, 2)) end
    calc(bn >= 0 and "BN" or "PN", "MB − ACE", mt(mb) .. " − " .. mt(ace), m2(bn))
    GRILLE("Présentation en liste", {
      {"Chiffre d'affaires net", mt(can)}, {"./. PRAMV", mt(-pramv)},
      {"Marge brute", mt(mb), gras = true, trait = true}, {"./. ACE", mt(-ace)},
      {bn >= 0 and "Bénéfice net" or "Perte nette", mt(bn), gras = true, trait = true}})
    G("Contrôle : MB = FF + BN → " .. mt(mb) .. " = " .. mt(ace) .. " + " .. mt(bn) .. ". Défaut = test 2025 ex. 2 (prof : PRAMA 1'150, PRAMV 1'050, CAN 1'970, MB 920, BN 520) ; 44.1 : vb=1000000;da=40000;ab=600000;do=30000;fa=50000;ace=340000;si=120000;sf=200000.")
    montrer("CR à 2 degrés")
  end
  SOLVEURS.cr2 = lancer(CH_CR, cr2)

  ------------------------------------------------------------------ B3, B4 seuil en quantité, bénéfice visé, résultat à un volume
  local CH_Q = {
    {cle = "pv", lib = "prix de vente unitaire (0 si inconnu)", defaut = "10"},
    {cle = "cv", lib = "coût variable unitaire (0 si inconnu)", defaut = "2"},
    {cle = "t", lib = "taux de marge brute (si PV ou CV inconnu)", defaut = "0"},
    {cle = "base", lib = "base du taux : 0 = % du PVN, 1 = % du coût variable", defaut = "0"},
    {cle = "cf", lib = "charges fixes de la période", defaut = "640"},
    {cle = "bn", lib = "bénéfice visé (négatif = perte)", defaut = "500"},
    {cle = "q", lib = "quantité vendue (résultat, 0 = non)", defaut = "0"},
  }
  local function seuilQ(v)
    vider()
    T("Seuil en quantité, bénéfice visé")
    G("Méthode (modèles : 44.6, 44.7, 44.8 ; test 2025 ex. 6) : chaque unité vendue rapporte sa marge brute unitaire, qui couvre d'abord les charges fixes. Quantité = montant à couvrir ÷ MB unitaire, arrondie à l'unité supérieure.")
    local pv, cv, t, cf, bn, q = v.pv or 0, v.cv or 0, v.t or 0, v.cf or 0, v.bn or 0, v.q or 0
    local mbu
    if nz(pv) and nz(cv) then
      mbu = pv - cv
      calc("Marge brute unitaire", "PV − CV", m2(pv) .. " − " .. m2(cv), m2(mbu))
    elseif nz(cv) and nz(t) then
      if (v.base or 0) == 0 then
        mbu = cv * t / (1 - t)
        G("Taux en % du PVN : le coût variable vaut " .. tx(1 - t) .. " du PVN (44.7 b).")
        calc("Marge brute unitaire", "CV × taux ÷ (100 % − taux)", m2(cv) .. " × " .. tx(t) .. " ÷ " .. tx(1 - t), m2(mbu))
      else
        mbu = cv * t
        G("Taux en % du coût variable (44.8 c, piège de la base).")
        calc("Marge brute unitaire", "CV × taux", m2(cv) .. " × " .. tx(t), m2(mbu))
      end
      pv = cv + mbu
      calc("Prix de vente", "CV + MB unitaire", m2(cv) .. " + " .. m2(mbu), m2(pv))
    elseif nz(pv) and nz(t) then
      if (v.base or 0) == 0 then
        mbu = pv * t
        calc("Marge brute unitaire", "PV × taux", m2(pv) .. " × " .. tx(t), m2(mbu))
      else
        mbu = pv * t / (1 + t)
        G("Taux en % du coût variable : le PV vaut " .. tx(1 + t) .. " du coût (44.7 c).")
        calc("Marge brute unitaire", "PV × taux ÷ (100 % + taux)", m2(pv) .. " × " .. tx(t) .. " ÷ " .. tx(1 + t), m2(mbu))
      end
      cv = pv - mbu
      G("Coût variable = " .. m2(pv) .. " − " .. m2(mbu) .. " = " .. m2(cv))
    else
      A("Il faut PV et CV, ou l'un des deux et le taux de marge."); montrer("Seuil en quantité"); return
    end
    if mbu <= EPS then A("Marge brute unitaire nulle ou négative : pas de seuil."); montrer("Seuil en quantité"); return end
    T("Point mort")
    local qpm = cf / mbu
    calc("Quantité au point mort", "charges fixes ÷ MB unitaire", mt(cf) .. " ÷ " .. m2(mbu), dec(qpm) .. (math.abs(qpm - sup(qpm)) > 1e-6 and (" → " .. fmt(sup(qpm)) .. " unités (unité supérieure)") or " unités"))
    calc("CAN au point mort", "quantité × PV", dec(qpm) .. " × " .. m2(pv), m2(qpm * pv))
    if math.abs(qpm - sup(qpm)) > 1e-6 then
      G("Avec " .. math.floor(qpm) .. " unités on est encore en perte, avec " .. fmt(sup(qpm)) .. " déjà en bénéfice (44.15).")
    end
    if nz(bn) then
      T(bn > 0 and "Quantité pour le bénéfice visé" or "Quantité vendue avec cette perte")
      local acouv = cf + bn
      calc(bn > 0 and "Marge brute nécessaire" or "Marge brute totale", bn > 0 and "CF + BN visé" or "CF − perte", mt(cf) .. (bn > 0 and " + " or " − ") .. mt(math.abs(bn)), m2(acouv))
      local qb = acouv / mbu
      calc("Quantité", "marge nécessaire ÷ MB unitaire", mt(acouv) .. " ÷ " .. m2(mbu), dec(qb) .. (math.abs(qb - sup(qb)) > 1e-6 and (" → " .. fmt(sup(qb)) .. " unités") or " unités"))
      calc("CAN correspondant", "quantité × PV", mt(sup(qb)) .. " × " .. m2(pv), m2(sup(qb) * pv))
    end
    if nz(q) then
      T("Résultat pour " .. mt(q) .. " unités")
      local ca, fvar, mb = q * pv, q * cv, q * mbu
      GRILLE("CR en liste (44.2 d)", {
        {"CAN", mt(q) .. " × " .. dec(pv), m2(ca)},
        {"./. PRAMV", mt(q) .. " × " .. dec(cv), m2(-fvar)},
        {"MB", mt(q) .. " × " .. dec(mbu), m2(mb), trait = true},
        {"./. FF", "", m2(-cf)},
        {mb - cf >= 0 and "BN" or "PN", "", m2(mb - cf), gras = true, trait = true}})
    end
    G("Défaut = test 2025 ex. 6 (prof : 80 ; 1'140 ÷ 8 = 142.5 → 143 ; le corrigé écrit « 117.5 » par coquille). 44.6 : pv=18;cv=8;cf=750;bn=250 → 75, 100. 44.7 b : pv=0;cv=9;t=100/3%;base=0;cf=90000 → 4.50, 20'000, 270'000. 44.8 b : pv=0;cv=9;t=25%;base=0;cf=63000;bn=-6000 → 19'000.")
    montrer("Seuil en quantité")
  end
  SOLVEURS.seuilQ = lancer(CH_Q, seuilQ)

  ------------------------------------------------------------------ B2 seuil en valeur par le taux de marge brute
  local CH_V = {
    {cle = "ca", lib = "chiffre d'affaires net", defaut = "12568000"},
    {cle = "pramv", lib = "PRAMV (charges variables)", defaut = "8169200"},
    {cle = "cf", lib = "charges fixes", defaut = "2896000"},
    {cle = "bn", lib = "bénéfice net visé (0 = non)", defaut = "2000000"},
    {cle = "fp", lib = "fonds propres à rémunérer (0 = non)", defaut = "0"},
    {cle = "tfp", lib = "taux de rémunération des FP", defaut = "0"},
  }
  local function seuilV(v)
    vider()
    T("Seuil en valeur (taux de marge brute)")
    G("Méthode (modèles : 44.3, 44.10 ; 44 p.8, p.10) : le taux de marge brute dit quelle part de chaque franc de CA reste pour couvrir les charges fixes ; CA au point mort = CF ÷ taux.")
    local ca, pramv, cf, bn = v.ca or 0, v.pramv or 0, v.cf or 0, v.bn or 0
    if not nz(ca) then A("CA nul."); montrer("Seuil en valeur"); return end
    local mb = ca - pramv
    GRILLE("Compte de résultat", {{"Chiffre d'affaires", mt(ca)}, {"./. PRAMV", mt(-pramv)},
      {"Marge brute", mt(mb), gras = true, trait = true}, {"./. Charges fixes", mt(-cf)},
      {mb - cf >= 0 and "Marge nette" or "Perte nette", mt(mb - cf), gras = true, trait = true}})
    calc("Marge brute", "CA − PRAMV", mt(ca) .. " − " .. mt(pramv), m2(mb))
    local t = mb / ca
    calc("Taux de marge brute", "MB × 100 ÷ CA", mt(mb) .. " × 100 ÷ " .. mt(ca), tx(t))
    if t <= EPS then A("Taux de marge nul ou négatif : pas de point mort."); montrer("Seuil en valeur"); return end
    T("CA au point mort (deux formules)")
    calc("CA au PM", "CF × 100 ÷ taux de MB", mt(cf) .. " × 100 ÷ " .. dec(t * 100, 3), m2(r5(cf / t)))
    calc("CA au PM", "CA × CF ÷ MB", mt(ca) .. " × " .. mt(cf) .. " ÷ " .. mt(mb), m2(r5(ca * cf / mb)))
    G("Arrondi aux 5 centimes, comme les corrigés du recueil.")
    local fp, tfp = v.fp or 0, v.tfp or 0
    if nz(bn) or (nz(fp) and nz(tfp)) then
      T("CA pour le bénéfice visé")
      local L, ac = {{"Frais fixes", mt(cf)}}, cf
      if nz(fp) and nz(tfp) then
        local it = fp * tfp
        calc("Intérêt sur fonds propres", "taux × FP", tx(tfp) .. " × " .. mt(fp), m2(it))
        table.insert(L, {"Intérêt sur FP", mt(it)}); ac = ac + it
      end
      table.insert(L, {"Bénéfice prévisionnel", mt(bn)}); ac = ac + bn
      table.insert(L, {"À couvrir", mt(ac), gras = true, trait = true})
      GRILLE("Montant à couvrir (44.10 c)", L)
      calc("CA visé", "à couvrir × 100 ÷ taux de MB", mt(ac) .. " × 100 ÷ " .. dec(t * 100, 3), m2(r5(ac / t)))
    end
    G("Défaut = 44.3 (prof : 35 %, 8'274'285.70, 13'988'571.45). 44.10 : ca=2000000;pramv=1680000;cf=460000;bn=150000;fp=2400000;tfp=5% → 16 %, 2'875'000, 4'562'500.")
    montrer("Seuil en valeur")
  end
  SOLVEURS.seuilV = lancer(CH_V, seuilV)

  ------------------------------------------------------------------ B4 base du taux, CAN depuis la marge brute
  local CH_T = {
    {cle = "t", lib = "taux de marge brute", defaut = "50%"},
    {cle = "base", lib = "base : 0 = % du CAN, 1 = % du PRAMV", defaut = "1"},
    {cle = "mb", lib = "marge brute (bénéfice brut) connue", defaut = "15000"},
  }
  local function tauxBase(v)
    vider()
    T("Base du taux, CAN depuis la MB")
    G("Méthode (modèle : 44.8 c) : un taux « en % du PRAMV » se rapporte au coût ; le ramener au CAN avant de calculer. Si PRAMV = 100 %, MB = taux et CAN = 100 % + taux.")
    local t, mb = v.t or 0, v.mb or 0
    local tc, tv
    if (v.base or 0) == 1 then
      tc = t; tv = t / (1 + t)
      calc("Taux en % du CAN", "taux ÷ (100 % + taux)", tx(t) .. " ÷ " .. tx(1 + t), tx(tv))
    else
      tv = t; tc = t / (1 - t)
      calc("Taux en % du PRAMV", "taux ÷ (100 % − taux)", tx(t) .. " ÷ " .. tx(1 - t), tx(tc))
    end
    if nz(mb) and tv > EPS then
      local can = mb / tv
      calc("CAN", "MB × (100 % + taux du PRAMV) ÷ taux du PRAMV", mt(mb) .. " × " .. tx(1 + tc) .. " ÷ " .. tx(tc), m2(can))
      calc("PRAMV", "CAN − MB", mt(can) .. " − " .. mt(mb), m2(can - mb))
    end
    G("Défaut = 44.8 c (prof : CAN = 15'000 × 150 ÷ 50 = 45'000). Piège : 33 1/3 % du PVN = 50 % du coût.")
    montrer("Base du taux")
  end
  SOLVEURS.taux = lancer(CH_T, tauxBase)

  ------------------------------------------------------------------ B7 budget : PRAMV, taux, PM, résultat, prévisions, date
  local CH_B = {
    {cle = "ca", lib = "CAN", defaut = "800000"},
    {cle = "ach", lib = "achats (PRAMA)", defaut = "360000"},
    {cle = "aug", lib = "augmentation de stock (− = diminution)", defaut = "40000"},
    {cle = "cf", lib = "charges fixes", defaut = "120000"},
    {cle = "cab", lib = "CA du budget (0 = non)", defaut = "760000"},
    {cle = "dt", lib = "baisse du taux en points (− = hausse)", defaut = "2"},
    {cle = "dcf", lib = "hausse des charges fixes", defaut = "20000"},
  }
  local function budget(v)
    vider()
    T("Budget : PM, résultat, prévisions")
    G("Méthode (modèle : 44.9 ; date : 44.11) : PRAMV → MB et taux → CA au PM = CF ÷ taux ; à un autre CA, BN = taux × CA − CF.")
    local ca, ach, aug, cf = v.ca or 0, v.ach or 0, v.aug or 0, v.cf or 0
    local pramv = ach - aug
    calc("a) PRAMV", "achats − augmentation de stock", mt(ach) .. " − " .. mt(aug), m2(pramv))
    local mb = ca - pramv
    calc("b) Marge brute", "CAN − PRAMV", mt(ca) .. " − " .. mt(pramv), m2(mb))
    local t = mb / ca
    calc("Taux de marge brute", "MB × 100 ÷ CAN", mt(mb) .. " × 100 ÷ " .. mt(ca), tx(t))
    if t <= EPS then A("Taux nul ou négatif."); montrer("Budget"); return end
    local pm = r5(cf / t)
    calc("c) CA au point mort", "CF × 100 ÷ taux", mt(cf) .. " × 100 ÷ " .. dec(t * 100, 3), m2(pm))
    local j = sup(pm * 360 / ca)
    calc("Date du PM (ventes régulières)", "CA au PM × 360 ÷ CAN", m2(pm) .. " × 360 ÷ " .. mt(ca), j .. " jours, soit le " .. dateJour(j))
    local bn0 = mb - cf
    if nz(v.cab) then
      local bb = t * v.cab
      calc("d) Bénéfice brut", "taux × CA du budget", tx(t) .. " × " .. mt(v.cab), m2(bb))
      calc("Bénéfice net", "bénéfice brut − CF", mt(bb) .. " − " .. mt(cf), m2(bb - cf))
    end
    if nz(v.dt) or nz(v.dcf) then
      T("Prévisions")
      local t2, cf2 = t - (v.dt or 0) / 100, cf + (v.dcf or 0)
      calc("e) Taux de marge brute", "taux − baisse", tx(t) .. " − " .. dec(v.dt or 0) .. " %", tx(t2))
      calc("Frais fixes prévus", "CF + hausse", mt(cf) .. " + " .. mt(v.dcf or 0), m2(cf2))
      if t2 <= EPS then A("Nouveau taux nul ou négatif."); montrer("Budget"); return end
      calc("CAN au point mort", "CF prévus ÷ taux", mt(cf2) .. " ÷ " .. tx(t2), m2(r5(cf2 / t2)))
      GRILLE("f) À couvrir (même BN que l'exercice)", {
        {"Bénéfice prévu", mt(mb) .. " − " .. mt(cf), mt(bn0)},
        {"Charges fixes", "", mt(cf2)},
        {"À couvrir", "", mt(bn0 + cf2), gras = true, trait = true}})
      calc("CAN à réaliser", "à couvrir ÷ taux", mt(bn0 + cf2) .. " ÷ " .. tx(t2), m2(r5((bn0 + cf2) / t2)))
      local bb2 = t2 * ca
      GRILLE("g) Résultat si le CA reste à " .. mt(ca), {
        {"Bénéfice brut", tx(t2) .. " × " .. mt(ca), m2(bb2)},
        {"./. Charges fixes", "", m2(-cf2)},
        {bb2 - cf2 >= 0 and "Bénéfice net" or "Perte nette", "", m2(bb2 - cf2), gras = true, trait = true}})
    end
    G("Défaut = 44.9 (prof : 320'000 ; 60 % ; 200'000 ; 336'000 ; 58 %, 241'379.30 ; 862'068.95 ; 324'000). Année de 360 jours, mois de 30 jours.")
    montrer("Budget")
  end
  SOLVEURS.budget = lancer(CH_B, budget)

  ------------------------------------------------------------------ B7 CR prévisionnel à 2 degrés et date du point mort
  local CH_P = {
    {cle = "ca", lib = "CA budgété", defaut = "8200000"},
    {cle = "t", lib = "taux de marge brute (% du CA)", defaut = "60%"},
    {cle = "pers", lib = "charges de personnel", defaut = "1200000"},
    {cle = "autres", lib = "autres charges", defaut = "400000"},
    {cle = "amort", lib = "amortissements", defaut = "280000"},
  }
  local function crPrev(v)
    vider()
    T("CR prévisionnel, date du PM")
    G("Méthode (modèle : 44.11) : charges de marchandises = CA × (100 % − taux) ; MB = CA × taux ; 2e degré = charges fixes → marge nette. Date du PM : nombre de jours = 360 × CA au PM ÷ CA (activité régulière).")
    local ca, t = v.ca or 0, v.t or 0
    local mb = ca * t
    local cm = ca - mb
    local cf = (v.pers or 0) + (v.autres or 0) + (v.amort or 0)
    local mn = mb - cf
    calc("Charges marchandises", "CA × (100 % − taux)", mt(ca) .. " × " .. tx(1 - t), m2(cm))
    calc("Marge brute", "CA × taux", mt(ca) .. " × " .. tx(t), m2(mb))
    GRILLE("1er degré", {{"Charges marchandises", mt(cm), ""}, {"Chiffre d'affaires net", "", mt(ca)},
      {"Marge brute", mt(mb), "", gras = true}, {"Total", mt(ca), mt(ca), gras = true, trait = true, fond = true}},
      {entetes = {"", "Charges", "Produits"}})
    local L = {{"Marge brute", "", mt(mb)}}
    if nz(v.pers) then table.insert(L, {"Charges de personnel", mt(v.pers), ""}) end
    if nz(v.autres) then table.insert(L, {"Autres charges", mt(v.autres), ""}) end
    if nz(v.amort) then table.insert(L, {"Amortissements", mt(v.amort), ""}) end
    if mn >= 0 then table.insert(L, {"Marge nette", mt(mn), "", gras = true}) else table.insert(L, {"Perte nette", "", mt(-mn), gras = true}) end
    local tt = math.max(mb, cf)
    table.insert(L, {"Total", mt(tt), mt(tt), gras = true, trait = true, fond = true})
    GRILLE("2e degré", L, {entetes = {"", "Charges", "Produits"}})
    T("Date du point mort")
    calc("Charges fixes", "personnel + autres + amortissements", mt(v.pers or 0) .. " + " .. mt(v.autres or 0) .. " + " .. mt(v.amort or 0), m2(cf))
    if t <= EPS then A("Taux nul."); montrer("CR prévisionnel"); return end
    local pm = r5(cf / t)
    calc("CAN au point mort", "CF × 100 ÷ taux", mt(cf) .. " × 100 ÷ " .. dec(t * 100, 3), m2(pm))
    local jr = 360 * pm / ca
    calc("Nombre de jours", "360 × CA au PM ÷ CA", "360 × " .. m2(pm) .. " ÷ " .. mt(ca), dec(jr) .. " → " .. fmt(sup(jr)) .. " jours")
    R("Date du point mort : " .. fmt(sup(jr)) .. " jours après le début de l'année, soit le " .. dateJour(sup(jr)), "", "")
    G("Défaut = 44.11 (prof : 3'280'000 ; 4'920'000 ; marge nette 3'040'000 ; 3'133'333.35 ; 138 jours, 18 mai).")
    montrer("CR prévisionnel")
  end
  SOLVEURS.crprev = lancer(CH_P, crPrev)

  ------------------------------------------------------------------ B5 graphique du seuil
  local CH_G = {
    {cle = "pv", lib = "prix de vente unitaire", defaut = "15"},
    {cle = "cv", lib = "coût variable unitaire", defaut = "9"},
    {cle = "cf", lib = "coûts fixes", defaut = "150000"},
    {cle = "bn", lib = "bénéfice net visé (0 = non)", defaut = "30000"},
    {cle = "pn", lib = "perte nette visée (0 = non)", defaut = "60000"},
    {cle = "qmax", lib = "quantité max. de l'axe (0 = auto)", defaut = "30000"},
  }
  local function seuilGraphe(v)
    vider()
    T("Graphique du seuil")
    G("Méthode (modèles : 44.13, 44.14 ; test 2025 ex. 8 ; 44 p.10) : abscisse = quantités, ordonnée = CHF. Tracer 4 droites : CAN, marge brute, prix de revient (= FF + FV), frais fixes. Point mort à l'intersection CAN / prix de revient (et MB / FF).")
    local pv, cv, cf, bn, pn = v.pv or 0, v.cv or 0, v.cf or 0, v.bn or 0, v.pn or 0
    local mbu = pv - cv
    if mbu <= EPS then A("PV ≤ CV : pas de point mort."); montrer("Graphique du seuil"); return end
    calc("Marge brute unitaire", "PV − CV", m2(pv) .. " − " .. m2(cv), m2(mbu))
    local rep, L = {}, {}
    local function cas_(lib, montant)
      local q = (cf + montant) / mbu
      table.insert(rep, {q = q})
      table.insert(L, {lib, fmt(q, math.abs(q - math.floor(q + 0.5)) < 1e-6 and 0 or 2), mt(q * pv)})
      return q
    end
    if nz(pn) then cas_("PN = " .. mt(pn), -pn) end
    local qpm = cas_("PM (BN = 0)", 0)
    if nz(bn) then cas_("BN = " .. mt(bn), bn) end
    calc("Quantité au PM", "CF ÷ MB unitaire", mt(cf) .. " ÷ " .. m2(mbu), dec(qpm))
    if nz(bn) then calc("Quantité pour le BN", "(CF + BN) ÷ MB unitaire", "(" .. mt(cf) .. " + " .. mt(bn) .. ") ÷ " .. m2(mbu), dec((cf + bn) / mbu)) end
    if nz(pn) then calc("Quantité pour la PN", "(CF − PN) ÷ MB unitaire", "(" .. mt(cf) .. " − " .. mt(pn) .. ") ÷ " .. m2(mbu), dec((cf - pn) / mbu)) end
    GRILLE("CA à lire sur le graphique", L, {entetes = {"Cas", "Quantité", "CAN"}})
    local qm = v.qmax or 0
    if not nz(qm) then local mx = 0; for _, r in ipairs(rep) do mx = math.max(mx, r.q) end; qm = qmaxRond(mx * 1.15) end
    graphique(pv, cv, cf, qm, rep)
    G("Annoter : accolade BN entre CAN et prix de revient à droite du PM, PN à gauche ; nommer les 4 droites. Perte visée ⇒ CA sous le seuil.")
    G("Défaut = test 2025 ex. 8 et 44.13 (prof : 375'000 ; 450'000 ; 225'000).")
    montrer("Graphique du seuil")
  end
  SOLVEURS.graphe = lancer(CH_G, seuilGraphe)

  ------------------------------------------------------------------ B6 licence : quantité, prix minimum, baisse de prix
  local CH_L = {
    {cle = "pa", lib = "prix de revient d'achat unitaire", defaut = "80"},
    {cle = "cmin", lib = "commande minimale", defaut = "5000"},
    {cle = "pv", lib = "prix de vente", defaut = "120"},
    {cle = "cf", lib = "charges fixes annuelles", defaut = "180000"},
    {cle = "bn", lib = "bénéfice net visé", defaut = "50000"},
    {cle = "baisse", lib = "réduction du prix de vente", defaut = "10%"},
  }
  local function licenceCorps(v)
    local pa, cmin, pv, cf, bn, b = v.pa or 0, v.cmin or 0, v.pv or 0, v.cf or 0, v.bn or 0, v.baisse or 0
    local mcv = pv - pa
    T("a) Quantité pour le bénéfice")
    GRILLE("À couvrir", {{"Charges fixes", mt(cf)}, {"Bénéfice", mt(bn)}, {"À couvrir", mt(cf + bn), gras = true, trait = true}})
    calc("Marge sur coût variable unitaire", "PV − coût variable", m2(pv) .. " − " .. m2(pa), m2(mcv))
    if mcv <= EPS then A("PV ≤ coût : pas de solution."); return end
    local q = (cf + bn) / mcv
    calc("Nombre d'unités", "à couvrir ÷ marge unitaire", mt(cf + bn) .. " ÷ " .. m2(mcv), dec(q) .. (math.abs(q - sup(q)) > 1e-6 and (" → " .. fmt(sup(q))) or ""))
    T("b) Prix minimum (commande minimale)")
    if nz(cmin) then
      local mseuil = cf / cmin
      calc("Marge sur coût variable (seuil)", "CF ÷ commande minimale", mt(cf) .. " ÷ " .. mt(cmin), m2(mseuil))
      GRILLE("Prix minimum", {{"Prix d'achat unitaire", m2(pa)}, {"Marge s/ coût variable", m2(mseuil)},
        {"Prix de vente", m2(pa + mseuil), gras = true, trait = true}})
    end
    T("c) Baisse de prix et volume")
    local npv = pv * (1 - b)
    local nm = npv - pa
    GRILLE("Nouvelle marge", {{"Prix de vente initial", m2(pv)}, {"./. Réduction (" .. tx(b) .. ")", m2(-pv * b)},
      {"Nouveau prix de vente", m2(npv), trait = true}, {"./. Coût variable unit.", m2(-pa)},
      {"Marge s/ coût variable", m2(nm), gras = true, trait = true}})
    if nm <= EPS then A("La nouvelle marge est nulle ou négative : plus de seuil."); return end
    local s1, s2 = cf / mcv, cf / nm
    calc("Seuil avec PV à " .. m2(pv), "CF ÷ marge", mt(cf) .. " ÷ " .. m2(mcv), dec(s1) .. (math.abs(s1 - sup(s1)) > 1e-6 and (" → " .. fmt(sup(s1))) or ""))
    calc("Seuil avec PV à " .. m2(npv), "CF ÷ nouvelle marge", mt(cf) .. " ÷ " .. m2(nm), dec(s2) .. (math.abs(s2 - sup(s2)) > 1e-6 and (" → " .. fmt(sup(s2))) or ""))
    local d = sup(s2) - sup(s1)
    calc("Augmentation", "nouveau seuil − ancien seuil", fmt(sup(s2)) .. " − " .. fmt(sup(s1)), fmt(d) .. " unités")
    calc("Augmentation en %", "augmentation × 100 ÷ ancien seuil", fmt(d) .. " × 100 ÷ " .. fmt(sup(s1)), tx(d / sup(s1), 1))
  end
  local function licence(v)
    vider()
    T("Licence : quantité, prix min., baisse")
    G("Méthode (modèle : 44.16) : a) à couvrir = CF + BN, divisé par la marge sur coût variable unitaire ; b) marge minimale = CF ÷ commande minimale, prix = coût + marge ; c) nouvelle marge, seuils ancien et nouveau (unité supérieure), augmentation en %.")
    licenceCorps(v)
    G("Défaut = 44.16 (prof : 5'750 ; 116.00 ; 4'500 → 6'429, +1'929, 42.9 %).")
    montrer("Licence")
  end
  SOLVEURS.licence = lancer(CH_L, licence)

  local function licence2025()
    vider()
    T("Test 2025 ex. 10 : corrigé du prof")
    A("Référence = corrigé du prof, chiffres compris. Ses chiffres sont incohérents avec l'énoncé (CF 250'000) : méthode du livre en regard ci-dessous, à ne pas substituer.")
    GRILLE("Feuille du prof (7 pts)", {
      {"a) Charges fixes", "6'750'000"}, {"Bénéfice", "50'000"}, {"À couvrir (1 pt)", "6'800'000", trait = true},
      {"Marge s/ CV unitaire", "8'000"}, {"Nombre (1 pt)", "850", gras = true},
      {"b) Commande minimale", "1'000"}, {"Marge s/ CV (1 pt)", "250"}, {"Prix de vente (1 pt)", "6'750", gras = true},
      {"c) Nouveau PV", "7'200"}, {"Marge s/ CV (1 pt)", "700"},
      {"Seuil nouv. PV (1 pt)", "937.5"}, {"Seuil ancien PV", "843.75"}, {"Augmentation", "93.75"},
      {"Augmentation % (1 pt)", "11.1 %", gras = true}})
    G("Le prof divise par le PV (8'000, 7'200) au lieu de la marge et prend CF = 6'750'000 en a) et c).")
    licenceCorps({pa = 6500, cmin = 1000, pv = 8000, cf = 250000, bn = 50000, baisse = 0.1})
    G("Méthode du livre (44.16) : 200 ; 6'750 ; 167 → 358, +114.4 %.")
    montrer("Test 2025 ex. 10")
  end
  SOLVEURS.licence2025 = licence2025

  ------------------------------------------------------------------ B8 lot acheté, changement de prix en cours de vente
  local CH_LOT = {
    {cle = "qa", lib = "quantité achetée", defaut = "600"},
    {cle = "pa", lib = "prix d'achat unitaire", defaut = "6"},
    {cle = "pv", lib = "prix de vente initial", defaut = "11"},
    {cle = "cf", lib = "charges générales (fixes)", defaut = "1700"},
    {cle = "qv", lib = "quantité déjà vendue", defaut = "60"},
    {cle = "npv", lib = "nouveau prix de vente", defaut = "9"},
  }
  local function lot(v)
    vider()
    T("Lot : changement de prix")
    G("Méthode (modèle : 44.12) : les unités déjà vendues ont couvert une partie des frais fixes à l'ancienne marge ; le solde se couvre à la nouvelle marge. Nouveau seuil = déjà vendues + supplément.")
    local qa, pa, pv, cf, qv, npv = v.qa or 0, v.pa or 0, v.pv or 0, v.cf or 0, v.qv or 0, v.npv or 0
    local m1 = pv - pa
    if m1 <= EPS then A("PV ≤ prix d'achat."); montrer("Lot"); return end
    T("a) Seuil de rentabilité")
    calc("Marge brute unitaire", "PV − PA", m2(pv) .. " − " .. m2(pa), m2(m1))
    local s = cf / m1
    calc("Unités au point mort", "charges ÷ marge unitaire", mt(cf) .. " ÷ " .. m2(m1), dec(s) .. (math.abs(s - sup(s)) > 1e-6 and (" → " .. fmt(sup(s))) or ""))
    T("b) Bénéfice si tout est vendu")
    calc("Marge brute totale", "quantité × marge unitaire", mt(qa) .. " × " .. m2(m1), m2(qa * m1))
    calc("Bénéfice net", "MB totale − charges", mt(qa * m1) .. " − " .. mt(cf), m2(qa * m1 - cf))
    T("c) Nouveau seuil")
    local m2_ = npv - pa
    calc("Nouvelle marge brute", "nouveau PV − PA", m2(npv) .. " − " .. m2(pa), m2(m2_))
    local couv = qv * m1
    calc("Frais fixes déjà couverts", "déjà vendues × ancienne marge", mt(qv) .. " × " .. m2(m1), m2(couv))
    local reste = cf - couv
    if reste <= EPS then R("Les frais fixes sont déjà couverts : seuil atteint avec " .. mt(qv) .. " unités.", "", ""); montrer("Lot"); return end
    if m2_ <= EPS then A("Nouvelle marge nulle ou négative : le solde ne sera jamais couvert."); montrer("Lot"); return end
    local sp = reste / m2_
    calc("Unités supplémentaires", "(charges − déjà couverts) ÷ nouvelle marge", mt(reste) .. " ÷ " .. m2(m2_), dec(sp) .. (math.abs(sp - sup(sp)) > 1e-6 and (" → " .. fmt(sup(sp))) or ""))
    local ns = qv + sup(sp)
    calc("Nouveau seuil", "déjà vendues + supplément", mt(qv) .. " + " .. fmt(sup(sp)), fmt(ns) .. " unités")
    local bnf = couv + (qa - qv) * m2_ - cf
    if ns <= qa then
      G("Commentaire : le nouveau seuil (" .. fmt(ns) .. ") reste sous la quantité achetée (" .. fmt(qa) .. ") : un bénéfice reste possible, mais si tout est vendu il tombe de " .. mt(qa * m1 - cf) .. " à " .. mt(bnf) .. " ; il faut vendre " .. fmt(ns - sup(s)) .. " unités de plus pour atteindre le seuil.")
    else
      G("Commentaire : le nouveau seuil (" .. fmt(ns) .. ") dépasse la quantité achetée (" .. fmt(qa) .. ") : la perte est inévitable (" .. mt(bnf) .. " si tout est vendu).")
    end
    G("Défaut = 44.12 (prof : 5.00 ; 340 ; 3'000 − 1'700 = 1'300 ; 3.00 ; 300 ; 1'400 ÷ 3 → 467 ; 60 + 467 = 527).")
    montrer("Lot")
  end
  SOLVEURS.lot = lancer(CH_LOT, lot)

  ------------------------------------------------------------------ B9 taux de remplissage, recettes annexes
  local CH_R = {
    {cle = "cap", lib = "capacité (places)", defaut = "120"},
    {cle = "cf", lib = "coûts fixes par vol", defaut = "30000"},
    {cle = "cv", lib = "frais variables par passager", defaut = "40"},
    {cle = "pv", lib = "prix payé par passager", defaut = "300"},
    {cle = "ra", lib = "recettes annexes (fret) par vol", defaut = "5000"},
  }
  local function remplissage(v)
    vider()
    T("Taux de remplissage")
    G("Méthode (modèle : 44.15) : les recettes annexes se déduisent des coûts fixes ; passagers au PM = CF nets ÷ MB unitaire ; taux d'occupation = PM × 100 ÷ capacité.")
    local cap, cf, cv, pv, ra = v.cap or 0, v.cf or 0, v.cv or 0, v.pv or 0, v.ra or 0
    local cfn = cf - ra
    calc("Coûts fixes nets", "CF − recettes annexes", mt(cf) .. " − " .. mt(ra), m2(cfn))
    local mbu = pv - cv
    calc("Marge brute unitaire", "prix − frais variables", mt(pv) .. " − " .. mt(cv), m2(mbu))
    if mbu <= EPS then A("Marge nulle ou négative."); montrer("Remplissage"); return end
    local q = cfn / mbu
    calc("Passagers au PM", "CF nets ÷ MB unitaire", mt(cfn) .. " ÷ " .. m2(mbu), dec(q))
    if math.abs(q - sup(q)) > 1e-6 then
      R("Avec " .. math.floor(q) .. " passagers : encore en perte ; avec " .. fmt(sup(q)) .. " : déjà en bénéfice.", "", "")
    end
    if nz(cap) then
      calc("Taux d'occupation au PM", "PM × 100 ÷ capacité", dec(q) .. " × 100 ÷ " .. mt(cap), tx(math.floor(q * 100 + 0.5) / 100 / cap))
      if q > cap then A("Le point mort dépasse la capacité : vol toujours déficitaire.") end
    end
    G("Coûts fixes possibles (44.15 a) : carburant, salaires de l'équipage, amortissement de l'avion, intérêts, frais d'atterrissage.")
    graphique(pv, cv, cfn, nz(cap) and cap or qmaxRond(q * 1.2), {{q = q}}, "Recettes voyageurs")
    G("Défaut = 44.15 (prof : 25'000 ; 260 ; 96.15 ; 80.125 %). Le taux du prof part de 96.15 (arrondi à 2 décimales).")
    montrer("Remplissage")
  end
  SOLVEURS.remplissage = lancer(CH_R, remplissage)

  ------------------------------------------------------------------ B10 théorie : marge contributive
  local function theorie()
    vider()
    T("Marge contributive (théorie)")
    X("Charges variables (proportionnelles) : varient avec les quantités vendues (marchandises, emballage, commissions).")
    X("Charges fixes : indépendantes du volume à court terme (loyer, salaires fixes, amortissements, intérêts).")
    X("Marge sur coût variable (marge brute) = CAN − charges variables ; elle couvre les charges fixes puis forme le bénéfice.")
    X("Marge contributive = CAN − charges directes d'un produit ; elle contribue à couvrir les charges communes (indirectes).")
    G("Le manuel emploie aussi « marge contributive » pour la marge brute (44 p.4).")
    T("Formules du 1er degré (44 p.3)")
    X("CAN = ventes − déductions accordées (− pertes sur créances − frais de vente)")
    X("PRAMA = achats + frais d'achats − déductions obtenues")
    X("PRAMV = PRAMA ± variation de stock (+ diminution, − augmentation)")
    X("MB = CAN − PRAMV = FF + BN")
    T("Seuil (44 p.8-10)")
    X("Taux de MB = MB × 100 ÷ CAN")
    X("CA au PM = CF × 100 ÷ taux de MB = CA × CF ÷ MB")
    X("Quantité au PM = CF ÷ MB unitaire ; quantité visée = (CF + BN) ÷ MB unitaire")
    X("CA visé = (CF + BN) × 100 ÷ taux de MB")
    X("Date du PM = CA au PM × 360 ÷ CA annuel (ventes régulières)")
    G("Quantités arrondies à l'unité supérieure ; CA en CHF arrondis aux 5 centimes dans le recueil.")
    montrer("Marge contributive")
  end
  SOLVEURS.theorie = theorie

  ------------------------------------------------------------------ X1 marge de sécurité, levier opérationnel (hors cours)
  local CH_S = {
    {cle = "ca", lib = "CAN", defaut = "800000"},
    {cle = "cv", lib = "charges variables (PRAMV)", defaut = "320000"},
    {cle = "cf", lib = "charges fixes", defaut = "120000"},
  }
  local function securite(v)
    vider()
    T("Marge de sécurité, levier (hors cours)")
    A("Hors cours : notion absente du chap. 44 (aucune source du prof).")
    G("Méthode : la marge de sécurité mesure de combien le CA peut baisser avant la perte ; le levier opérationnel dit de combien de % varie le résultat quand le CA varie de 1 %.")
    local ca, cv, cf = v.ca or 0, v.cv or 0, v.cf or 0
    if not nz(ca) then A("CA nul."); montrer("Marge de sécurité"); return end
    local mb = ca - cv
    local t = mb / ca
    calc("Marge brute", "CAN − charges variables", mt(ca) .. " − " .. mt(cv), m2(mb))
    calc("Taux de marge brute", "MB × 100 ÷ CAN", mt(mb) .. " × 100 ÷ " .. mt(ca), tx(t))
    if t <= EPS then A("Taux nul ou négatif."); montrer("Marge de sécurité"); return end
    local pm = r5(cf / t)
    calc("CA au point mort", "CF × 100 ÷ taux", mt(cf) .. " × 100 ÷ " .. dec(t * 100, 3), m2(pm))
    local ms = ca - pm
    calc("Marge de sécurité", "CAN − CA au PM", mt(ca) .. " − " .. m2(pm), m2(ms))
    calc("Indice de sécurité", "marge de sécurité × 100 ÷ CAN", m2(ms) .. " × 100 ÷ " .. mt(ca), tx(ms / ca, 2))
    local bn = mb - cf
    calc("Résultat", "MB − CF", mt(mb) .. " − " .. mt(cf), m2(bn))
    if nz(bn) then
      local lo = mb / bn
      calc("Levier opérationnel", "MB ÷ résultat", mt(mb) .. " ÷ " .. mt(bn), dec(lo))
      G("Commentaire : si le CA varie de 10 %, le résultat varie d'environ " .. dec(lo * 10, 1) .. " %. Plus on est proche du point mort, plus le levier est fort et le risque élevé.")
    end
    G("Défaut = données de 44.9 (CA 800'000, PRAMV 320'000, CF 120'000).")
    montrer("Marge de sécurité")
  end
  SOLVEURS.securite = lancer(CH_S, securite)

  ------------------------------------------------------------------ X seuil multiproduits (hors cours)
  local CH_M = {
    {cle = "p1", lib = "PV produit 1", defaut = "20"}, {cle = "c1", lib = "CV produit 1", defaut = "12"}, {cle = "m1", lib = "part du mix 1", defaut = "3"},
    {cle = "p2", lib = "PV produit 2", defaut = "50"}, {cle = "c2", lib = "CV produit 2", defaut = "30"}, {cle = "m2", lib = "part du mix 2", defaut = "1"},
    {cle = "p3", lib = "PV produit 3 (0 = aucun)", defaut = "0"}, {cle = "c3", lib = "CV produit 3", defaut = "0"}, {cle = "m3", lib = "part du mix 3", defaut = "0"},
    {cle = "cf", lib = "charges fixes communes", defaut = "44000"},
  }
  local function multi(v)
    vider()
    T("Seuil multiproduits (hors cours)")
    A("Hors cours : le chap. 44 ne traite qu'un produit. Hypothèse : composition des ventes (mix en quantités) constante.")
    G("Méthode : MB unitaire moyenne pondérée par le mix → quantité totale au PM = CF ÷ MB moyenne → répartition selon le mix.")
    local P, sm, smb = {}, 0, 0
    for i = 1, 3 do
      local p, c, m = v["p" .. i] or 0, v["c" .. i] or 0, v["m" .. i] or 0
      if nz(p) and nz(m) then table.insert(P, {i = i, p = p, c = c, m = m, mb = p - c}); sm = sm + m; smb = smb + m * (p - c) end
    end
    if #P == 0 or sm <= EPS then A("Aucun produit."); montrer("Multiproduits"); return end
    local L = {}
    for _, x in ipairs(P) do table.insert(L, {"Produit " .. x.i .. " (mix " .. dec(x.m) .. ")", m2(x.mb), m2(x.m * x.mb)}) end
    table.insert(L, {"Total (" .. dec(sm) .. ")", "", m2(smb), gras = true, trait = true})
    GRILLE("Marges unitaires", L, {entetes = {"", "MB unit.", "× mix"}})
    local mmoy = smb / sm
    calc("MB moyenne", "Σ (mix × MB unit.) ÷ Σ mix", m2(smb) .. " ÷ " .. dec(sm), m2(mmoy))
    if mmoy <= EPS then A("Marge moyenne nulle ou négative."); montrer("Multiproduits"); return end
    local cf = v.cf or 0
    local q = cf / mmoy
    calc("Quantité totale au PM", "CF ÷ MB moyenne", mt(cf) .. " ÷ " .. m2(mmoy), dec(q))
    local L2, ca, mbt = {}, 0, 0
    for _, x in ipairs(P) do
      local qi = sup(q * x.m / sm)
      ca = ca + qi * x.p; mbt = mbt + qi * x.mb
      table.insert(L2, {"Produit " .. x.i, fmt(qi), mt(qi * x.p)})
    end
    table.insert(L2, {"Total", "", mt(ca), gras = true, trait = true})
    GRILLE("Répartition au PM", L2, {entetes = {"", "Quantité", "CAN"}})
    G("Contrôle : MB totale " .. mt(mbt) .. " ≥ CF " .. mt(cf) .. " (quantités arrondies à l'unité supérieure).")
    montrer("Multiproduits")
  end
  SOLVEURS.multi = lancer(CH_M, multi)

  ------------------------------------------------------------------ menu
  table.insert(MENUS_COMPTA, {ordre = 44, titre = "Compte de résultat, seuil (44)", items = {
    {"CR à 2 degrés, PRAMA, PRAMV, CAN", menu("CR à 2 degrés", CH_CR, cr2)},
    {"Seuil en quantité, bénéfice visé", menu("Seuil en quantité", CH_Q, seuilQ)},
    {"Seuil en valeur (taux de marge)", menu("Seuil en valeur", CH_V, seuilV)},
    {"Base du taux, CAN depuis la MB", menu("Base du taux", CH_T, tauxBase)},
    {"Budget : PM, résultat, prévisions", menu("Budget", CH_B, budget)},
    {"CR prévisionnel, date du PM", menu("CR prévisionnel", CH_P, crPrev)},
    {"Graphique du seuil", menu("Graphique du seuil", CH_G, seuilGraphe)},
    {"Licence : quantité, prix min., baisse", menu("Licence", CH_L, licence)},
    {"Test 2025 ex. 10 (prof + livre)", licence2025},
    {"Lot : changement de prix", menu("Lot", CH_LOT, lot)},
    {"Taux de remplissage", menu("Remplissage", CH_R, remplissage)},
    {"Marge contributive (théorie)", theorie},
    {"Marge de sécurité, levier (hors cours)", menu("Marge de sécurité", CH_S, securite)},
    {"Seuil multiproduits (hors cours)", menu("Multiproduits", CH_M, multi)},
  }})
end

-- ===== module 51_analyse.lua
-- 51_analyse.lua : analyse de bilan et du résultat (chap. 51) — types C1 à C9 du plan, extensions marquées « (hors test) »
-- Sources : liste des ratios Profil M [R] ; chap. 51 (pages PDF) ; corrigés 51.8, 51.10, 51.11, 51.14, 51.15, 51.19, 51.21,
-- 51.23, 51.24, 51.25, 51.27, 51.28 ; test 2025 ex. 3 et 5 ; 57.22 (ratios de cash flow).
do
local F = {}          -- fonctions internes du module (une seule variable locale pour tout ranger)

------------------------------------------------------------------ formats
local function m(x)   -- montant : 12'500, 1'670'841.5, 1'216.8
  if type(x) ~= "number" then return "?" end
  if math.abs(x - math.floor(x + 0.5)) < 1e-9 then return fmt(x, 0) end
  if math.abs(x * 10 - math.floor(x * 10 + 0.5)) < 1e-6 then return fmt(x, 1) end
  return fmt(x, 2)
end
local function p2(x) if not x then return "—" end; return string.format("%.2f %%", x) end   -- x déjà multiplié par 100
local function d2(x) if not x then return "—" end; return string.format("%.2f", x) end
local function r2(x) return math.floor(x * 100 + 0.5) / 100 end
function F.ok(...)
  for i = 1, select("#", ...) do if select(i, ...) == nil then return false end end
  return true
end

------------------------------------------------------------------ champs et exemples du prof
local CAT = {
  liq = "Liquidités", cre = "Créances", sto = "Stocks", ac = "Actifs circulants", ai = "Actifs immobilisés", tot = "Total du bilan",
  ct = "CE à court terme", lt = "CE à long terme", ce = "Capitaux étrangers", fp = "Capitaux propres", cc = "Capital de croissance",
  liq1 = "Liquidités N-1", cre1 = "Créances N-1", sto1 = "Stocks N-1", ai1 = "AI N-1", ct1 = "CE ct N-1", lt1 = "CE lt N-1",
  fp1 = "Capitaux propres N-1", cc1 = "Cap. croissance N-1", tot1 = "Total du bilan N-1", ce1 = "CE N-1",
  can = "CA net", cac = "CA à crédit (vide = CAN)", pramv = "PRAMV", prama = "PRAMA (vide = PRAMV + var. stock)", mb = "Marge brute",
  ebit = "EBIT (vide = BN + ch. fin. − prod. fin. + impôts)", bn = "Bénéfice net", chf = "Charges financières",
  pf = "Produits financiers", imp = "Impôts", amo = "Amortissements",
  frs = "Dettes fournisseurs (vide = CE ct)", frs1 = "Dettes fournisseurs N-1 (vide = CE ct N-1)",
  cf = "Cash flow (vide = BN + amort.)", inv = "Investissements nets (vide = AI − AI N-1 + amort.)",
  ee = "Endettement effectif (vide = CE − liq. − créances)", dcl = "Délai accordé aux clients (jours)", dfo = "Délai des fournisseurs (jours)",
}
-- composition de chaque poste (affichée sous la question du questionnaire) : liste Profil M [R], 51 p.4 (bilan analytique), 51 p.31
local AIDE = {
  liq = "Liquidités = caisse + poste + banque (c/c actif) + titres cotés détenus à court terme (placements facilement réalisables). Les participations vont dans les AI (51 p.4).",
  cre = "Créances = créances clients − ducroire (provision pour pertes sur créances) + autres créances à court terme (AFC, impôt préalable) + actifs de régularisation (51 p.4).",
  sto = "Stocks = stock de marchandises (+ matières, produits finis, en-cours) + acomptes aux fournisseurs pour marchandises − acomptes de clients (51 p.4).",
  ai = "Actifs immobilisés = mobilier + machines + véhicules + immeubles + brevets + participations (− fonds d'amortissements cumulés) (51 p.4).",
  ct = "CE à court terme = dettes fournisseurs + dividendes à payer (décidés par l'AG) + dettes bancaires à court terme (banque c/c passif) + autres dettes à c.t. + passifs de régularisation. Garder le classement de l'énoncé (test 2025 : dividendes en CE l.t.).",
  lt = "CE à long terme = prêts et emprunts bancaires à long terme + hypothèques + obligations + provisions à long terme (51 p.4).",
  fp = "Capitaux propres = capital-actions (− actionnaires : capital non libéré) + réserves (issues du capital et du bénéfice) + bénéfice reporté (− perte reportée) + bénéfice non distribué.",
  cc = "Capital de croissance = réserves issues du bénéfice + bénéfice reporté (− perte reportée), sans agio ni réserve issue du capital (51 p.10). Sert au degré d'autofinancement.",
  ac = "Actifs circulants = liquidités + créances + stocks.",
  tot = "Total du bilan = actifs circulants + actifs immobilisés (= total du passif).",
  ce = "Capitaux étrangers = CE à court terme + CE à long terme.",
  can = "CA net = ventes − retours des clients − déductions accordées (rabais, escomptes) − pertes sur créances − frais directs de vente (51 p.31).",
  cac = "CA à crédit = part du CA vendue à crédit. Vide = on prend le CAN total (51 p.41).",
  pramv = "PRAMV = PRAMA + diminution de stock (ou − augmentation) ; PRAMA = achats + frais d'achats − déductions obtenues (51 p.31).",
  prama = "PRAMA (à crédit) = achats − retours aux fournisseurs − déductions obtenues + frais d'achats. Vide = PRAMV + stock final − stock initial.",
  mb = "Marge brute = CAN − PRAMV.",
  ebit = "EBIT = bénéfice net + impôts + charges financières − produits financiers (résultat avant intérêts et impôts). Vide = calculé ainsi (51.25).",
  bn = "Bénéfice net de l'exercice : dernière ligne du compte de résultat.",
  chf = "Charges financières = intérêts payés sur les dettes (+ frais bancaires). Sert à l'EBIT.",
  pf = "Produits financiers = intérêts et dividendes reçus ; 0 s'il n'y en a pas.",
  imp = "Impôts directs (sur le bénéfice et le capital) ; 0 s'ils ne sont pas donnés.",
  amo = "Amortissements de l'exercice (compte de résultat). Sert au cash flow (chap. 57).",
  frs = "Dettes fournisseurs (bilan). Vide = on prend les CE à court terme, comme le prof en 51.24.",
  cf = "Cash flow = bénéfice net + amortissements (méthode indirecte simplifiée, chap. 57). Vide = calculé ainsi.",
  inv = "Investissements nets = AI N − AI N-1 + amortissements (57 p.62). Vide = calculé ainsi.",
  ee = "Endettement effectif = capitaux étrangers − liquidités − créances. Vide = calculé ainsi.",
  dcl = "Délai de paiement accordé aux clients, en jours (ex. 30). Vide = pas de comparaison.",
  dfo = "Délai de paiement des fournisseurs, en jours. Vide = pas de comparaison.",
}
-- champs facultatifs : vide = ignoré ou valeur reconstituée
local OPT = {cc = true, cac = true, prama = true, ebit = true, frs = true, frs1 = true, cf = true, inv = true, ee = true, dcl = true,
  dfo = true, pf = true, imp = true, amo = true, chf = true}
-- par défaut : sommes des comptes de l'énoncé du prof (le rendu réécrit la composition : « Liquidités = 35 + 30 = 65 »)
local EX = {
  T25 = {nom = "test 2025 ex. 3, année 2026", liq = "35+30", cre = "470", sto = "440", ac = "65+470+440", ai = "20+590+90", tot = "975+700",
         ct = "450", lt = "110+220", ce = "450+330", fp = "625+250+20", cc = "250+20"},
  M23 = {nom = "51.23, année N", can = 4500845, mb = 1800338, ebit = 298274, bn = 205016},
  C24 = {nom = "51.24, coopérative A 2014", cac = 6134.2, cre = 1216.8, cre1 = 1149.1, pramv = 5356.4, sto = 228.5, sto1 = 261.3,
         prama = 5323.6, frs = 1737.1, frs1 = 1979.6},
  CF = {nom = "57.22, Chaudpain SA", cf = 18, inv = 77, can = 369, ce = 288, liq = 6, cre = 55},
  COL = {nom = "51.25 et 51.27, Colibri SA", can = 8432560, ebit = 124361, bn = 117881, chf = 6480, tot = 1828321, tot1 = 1513362,
         fp = 1289789, fp1 = 1226908},
}
function F.champs(cles, ex)
  local t = {}
  for _, k in ipairs(cles) do
    local d = ex and ex[k]
    local base, an = k:match("^(%a+)(1)$")
    local aide = AIDE[k] or (base and AIDE[base] and (AIDE[base] .. " — Année N-1 (vide = pas de moyenne, on prend la valeur N).")) or nil
    table.insert(t, {cle = k, lib = CAT[k] or k, defaut = d and tostring(d) or "", aide = aide, opt = OPT[k] or (an ~= nil)})
  end
  return t
end

------------------------------------------------------------------ valeurs déduites et moyennes
-- complète les grandeurs qui manquent (sans écraser une saisie) ; v._auto garde l'explication de chaque déduction
function F.deriver(v)
  v._r = v._r or {}; v._m = v._m or {}; v._auto = v._auto or {}
  local function note(s) table.insert(v._auto, s) end
  for _, s in ipairs({"", "1"}) do
    local liq, cre, sto = v["liq" .. s], v["cre" .. s], v["sto" .. s]
    if not v["ac" .. s] and F.ok(liq, cre, sto) then v["ac" .. s] = liq + cre + sto end
    if not v["tot" .. s] and F.ok(v["ac" .. s], v["ai" .. s]) then v["tot" .. s] = v["ac" .. s] + v["ai" .. s] end
    if not v["ce" .. s] and F.ok(v["ct" .. s], v["lt" .. s]) then v["ce" .. s] = v["ct" .. s] + v["lt" .. s] end
    if not v["ce" .. s] and F.ok(v["tot" .. s], v["fp" .. s]) then v["ce" .. s] = v["tot" .. s] - v["fp" .. s] end
  end
  if not v.mb and F.ok(v.can, v.pramv) then
    v.mb = v.can - v.pramv; note("Marge brute = CAN − PRAMV = " .. m(v.can) .. " − " .. m(v.pramv) .. " = " .. m(v.mb))
  end
  if not v.ebit and v.bn then
    v.ebit = v.bn + (v.imp or 0) + (v.chf or 0) - (v.pf or 0)
    note("EBIT = BN + impôts + charges financières − produits financiers = " .. m(v.bn) .. " + " .. m(v.imp or 0) .. " + "
      .. m(v.chf or 0) .. " − " .. m(v.pf or 0) .. " = " .. m(v.ebit) .. " (modèle 51.25)")
  end
  if not v.cac and v.can then v.cac = v.can; note("CA à crédit inconnu : on prend le CAN total = " .. m(v.can) .. " (51 p.41)") end
  if not v.prama and F.ok(v.pramv, v.sto, v.sto1) then
    v.prama = v.pramv + v.sto - v.sto1
    note("PRAMA = PRAMV + stock final − stock initial = " .. m(v.pramv) .. " + " .. m(v.sto) .. " − " .. m(v.sto1) .. " = " .. m(v.prama))
  end
  if not v.frs and v.ct then v.frs = v.ct; note("Dettes fournisseurs inconnues : on prend les CE à court terme (comme le prof en 51.24)") end
  if not v.frs1 and v.ct1 then v.frs1 = v.ct1 end
  if not v.cf and F.ok(v.bn, v.amo) then
    v.cf = v.bn + v.amo; note("Cash flow (méthode indirecte simplifiée, chap. 57) = BN + amortissements = " .. m(v.bn) .. " + " .. m(v.amo) .. " = " .. m(v.cf))
  end
  if not v.inv and F.ok(v.ai, v.ai1, v.amo) then
    v.inv = v.ai - v.ai1 + v.amo
    note("Investissements nets = AI N − AI N-1 + amortissements = " .. m(v.ai) .. " − " .. m(v.ai1) .. " + " .. m(v.amo) .. " = " .. m(v.inv) .. " (57 p.62, amortissement direct)")
  end
  return v
end

-- moyenne de deux bilans : ø = (N-1 + N) ÷ 2, écrite une seule fois par document
function F.moy(v, k, lib)
  if v._m[k] then return v._m[k] end
  local a, b = v[k], v[k .. "1"]
  if not a then return nil end
  local r
  if b then r = (a + b) / 2; X("ø " .. lib .. " = (" .. m(b) .. " + " .. m(a) .. ") ÷ 2 = " .. m(r))
  else r = a; G("ø " .. lib .. " : pas de valeur N-1, on prend la valeur N (" .. m(a) .. ")") end
  v._m[k] = r
  return r
end

------------------------------------------------------------------ commentaires (tournures des corrigés du prof)
local REP = "(repères tirés des corrigés 51.8, 51.10, 51.11 : le manuel ne donne pas de norme)"
function F.synthLiq(l1, l2, l3)
  if not F.ok(l1, l2, l3) then return "Liquidité : données incomplètes." end
  local s
  if l2 >= 100 then
    if l1 < 20 then
      s = string.format("La liquidité 1 (%s) est sous la valeur indicative de 20 à 30 %%, mais les créances clients devraient permettre à l'entreprise de payer ses dettes à court terme sans difficulté : la liquidité 2 (%s) dépasse 100 %% (modèle : test 2025 ex. 3).", p2(l1), p2(l2))
    elseif l1 <= 30 then
      s = string.format("Liquidité saine : la liquidité 1 (%s) est dans la norme (20 à 30 %%) et la liquidité 2 (%s) dépasse 100 %% ; l'entreprise peut faire face à ses dettes à court terme.", p2(l1), p2(l2))
    else
      s = string.format("L'entreprise est nettement en excédent de liquidités (liquidité 1 = %s > 30 %%). Peut-être est-ce volontaire pour acheter une autre entreprise ou réaliser prochainement des investissements importants ; sinon, c'est de l'argent qui ne rapporte rien (modèle 51.8). Ses dettes à court terme sont largement couvertes (liquidité 2 = %s).", p2(l1), p2(l2))
    end
  else
    s = string.format("La liquidité 2 (%s) est sous la norme de 100 %% : liquidités et créances ne suffisent pas à payer les dettes à court terme", p2(l2))
    if l3 >= 100 then s = s .. string.format(" ; l'entreprise devra vendre ses stocks (liquidité 3 = %s) ou obtenir un crédit.", p2(l3))
    else s = s .. string.format(", même en vendant tous ses stocks (liquidité 3 = %s < 100 %%) : risque d'insolvabilité, ses dettes à court terme sont très importantes.", p2(l3)) end
    if l1 < 20 then s = s .. string.format(" La liquidité 1 (%s) est elle aussi insuffisante : l'entreprise manque de liquidités.", p2(l1))
    elseif l1 > 30 then s = s .. string.format(" La liquidité 1 (%s) est pourtant élevée : ce sont les créances qui sont faibles.", p2(l1)) end
  end
  return s
end
function F.synthFin(e)
  if not e then return "Financement : données incomplètes." end
  if e < 50 then
    return string.format("Endettement faible (%s) : l'entreprise se finance avant tout par des fonds propres. Les risques sont moindres, mais cela va compromettre la rentabilité des fonds propres (modèle 51.8). %s", p2(e), REP)
  elseif e <= 70 then
    return string.format("Endettement de %s : un financement qui correspond assez à la norme (51.8 : 56 %% « dans la norme »). %s", p2(e), REP)
  end
  return string.format("Endettement de %s : l'entreprise est surendettée et très vulnérable en cas de perte ; ses charges financières sont élevées (modèle 51.8 : 82 %%). %s", p2(e), REP)
end
function F.synthCouv(c1, c2, iai, e)
  if not F.ok(c1, c2) then return "Couverture : données incomplètes." end
  local s
  if c2 >= 100 and c1 >= 100 then
    s = string.format("La règle d'or est respectée (couverture 2 = %s ≥ 100 %%) et l'entreprise paie ses actifs immobilisés avec ses fonds propres (couverture 1 = %s), donc tout va bien (modèle : test 2025 ex. 3).", p2(c2), p2(c1))
  elseif c2 >= 100 and c1 > 80 then
    s = string.format("La règle d'or est respectée (couverture 2 = %s ≥ 100 %%) et les immobilisations sont largement financées par les fonds propres (couverture 1 = %s > 80 %%) : risque faible.", p2(c2), p2(c1))
  elseif c2 >= 100 and c1 >= 60 then
    s = string.format("La règle d'or est respectée (couverture 2 = %s ≥ 100 %%) : les immobilisations sont financées par des capitaux permanents, majoritairement par des fonds propres (couverture 1 = %s, dans la norme de 60 à 80 %%).", p2(c2), p2(c1))
  elseif c2 >= 100 then
    s = string.format("La règle d'or est respectée (couverture 2 = %s ≥ 100 %%) grâce aux capitaux étrangers à long terme, mais la part des fonds propres est insuffisante (couverture 1 = %s < 60 %%).", p2(c2), p2(c1))
  else
    s = string.format("La règle d'or n'est pas respectée (couverture 2 = %s < 100 %%) : une partie des immobilisations est financée par des dettes à court terme, qu'il faudra rembourser avant que ces investissements ne rapportent (couverture 1 = %s).", p2(c2), p2(c1))
  end
  if c2 >= 100 and iai and iai < 30 and e and e > 70 then
    s = s .. string.format(" Attention : la couverture 2 n'est élevée que parce que les immobilisations sont faibles (intensité de l'AI = %s), alors que l'entreprise est très endettée.", p2(iai))
  end
  return s
end

------------------------------------------------------------------ les 26 ratios de la liste Profil M [R]
-- calc(v) -> numérateur, dénominateur, application écrite (ou {r = valeur}, nil, application)
-- u : "%" (× 100), "x" (fois), "j" (jours), "f" (facteur), "pt" (pourcentage déjà calculé)
local RAT = {
  {id = "liq1", nom = "Liquidité 1", u = "%", dec = true, ex = "T25", champs = {"liq", "ct"}, fam = "Liquidité",
   formule = "Liquidités × 100 ÷ CE à court terme",
   calc = function(v) return v.liq, v.ct, m(v.liq) .. " × 100 ÷ " .. m(v.ct) end,
   comm = function(r)
     if r < 20 then return p2(r) .. " < valeur indicative de 20 à 30 % : peu de liquidités immédiates pour payer les dettes à court terme ; à juger avec la liquidité 2 (créances)." end
     if r <= 30 then return p2(r) .. " : dans la valeur indicative (20 à 30 %) ; les dettes urgentes peuvent être payées sans garder trop d'argent qui ne rapporte rien." end
     return p2(r) .. " > 30 % : ratio trop élevé, excédent de liquidités (peut-être volontaire : investissement prévu, rachat d'entreprise) ; de l'argent qui dort (51.8, 51.10)."
   end, src = "51 p.11 (PDF) · modèle : test 2025 ex. 3, 51.10"},
  {id = "liq2", nom = "Liquidité 2", u = "%", dec = true, ex = "T25", champs = {"liq", "cre", "ct"}, fam = "Liquidité",
   formule = "(Liquidités + Créances) × 100 ÷ CE à court terme",
   calc = function(v) if not F.ok(v.liq, v.cre) then return nil end
     return v.liq + v.cre, v.ct, "(" .. m(v.liq) .. " + " .. m(v.cre) .. ") × 100 ÷ " .. m(v.ct) end,
   comm = function(r)
     if r >= 100 then return p2(r) .. " ≥ 100 % (le ratio le plus important) : liquidités et créances couvrent les dettes à court terme ; l'entreprise peut y faire face." end
     return p2(r) .. " < 100 % : ratio faible par rapport à la norme ; il faudra vendre des stocks ou obtenir un crédit pour payer les dettes à court terme (risque d'illiquidité)."
   end, src = "51 p.11-12 · modèle : 51.10, 51.11"},
  {id = "liq3", nom = "Liquidité 3", u = "%", dec = true, ex = "T25", champs = {"ac", "ct"}, fam = "Liquidité",
   formule = "Actifs circulants × 100 ÷ CE à court terme",
   calc = function(v) return v.ac, v.ct, m(v.ac) .. " × 100 ÷ " .. m(v.ct) end,
   comm = function(r)
     if r >= 150 then return p2(r) .. " > 150 % : les actifs circulants couvrent largement les dettes à court terme (FRN positif)." end
     if r >= 100 then return p2(r) .. " : sous la valeur indicative de 150 %, mais ce n'est pas forcément problématique si la liquidité 2 est bonne (51 p.12)." end
     return p2(r) .. " < 100 % : FRN négatif, une partie des immobilisations est financée par des dettes à court terme ; situation dangereuse."
   end, src = "51 p.11-12 · 51.11 : « dans la norme (150 à 200 %) »"},
  {id = "iac", nom = "Intensité de l'actif circulant", u = "%", dec = true, ex = "T25", champs = {"ac", "tot"}, fam = "Structure de l'actif",
   formule = "Actifs circulants × 100 ÷ Total de l'actif",
   calc = function(v) return v.ac, v.tot, m(v.ac) .. " × 100 ÷ " .. m(v.tot) end,
   comm = function(r) return p2(r) .. " : pas de valeur indicative ; dépend du secteur (une bijouterie n'est pas une industrie chimique). À comparer avec des entreprises du même secteur et dans le temps (51 p.9)." end,
   src = "51 p.9 · modèle 51.10"},
  {id = "iai", nom = "Intensité de l'actif immobilisé", u = "%", dec = true, ex = "T25", champs = {"ai", "tot"}, fam = "Structure de l'actif",
   formule = "Actifs immobilisés × 100 ÷ Total de l'actif",
   calc = function(v) return v.ai, v.tot, m(v.ai) .. " × 100 ÷ " .. m(v.tot) end,
   comm = function(r)
     local s = r >= 60 and "élevée : beaucoup d'immobilisations, donc des charges fixes importantes (amortissements, entretien) (51.15)"
       or (r < 30 and "faible : peu d'immobilisations (commerce, services), peu de charges fixes" or "moyenne")
     return p2(r) .. " : " .. s .. " ; la valeur dépend du secteur d'activité."
   end, src = "51 p.9 · 51.15"},
  {id = "end", nom = "Degré d'endettement", u = "%", dec = true, ex = "T25", champs = {"ce", "tot"}, fam = "Financement",
   formule = "Capitaux étrangers × 100 ÷ Total du passif",
   calc = function(v) return v.ce, v.tot, m(v.ce) .. " × 100 ÷ " .. m(v.tot) end,
   comm = function(r)
     if r < 50 then return p2(r) .. " : endettement faible (51.10 : 43.78 % « faible »), risque moindre ; mais rentabilité des fonds propres moins favorisée. " .. REP end
     if r <= 70 then return p2(r) .. " : endettement dans la norme (51.8 : 56 %). Un endettement fort implique des charges financières et un risque plus élevés. " .. REP end
     return p2(r) .. " : endettement élevé, entreprise surendettée et vulnérable en cas de perte (51.8 : 82 %). " .. REP
   end, src = "51 p.10-11 · 51.8, 51.10"},
  {id = "fp", nom = "Degré de financement propre", u = "%", dec = true, ex = "T25", champs = {"fp", "tot"}, fam = "Financement",
   formule = "Capitaux propres × 100 ÷ Total du passif",
   calc = function(v) return v.fp, v.tot, m(v.fp) .. " × 100 ÷ " .. m(v.tot) end,
   comm = function(r)
     if r >= 50 then return p2(r) .. " : capitaux propres élevés ; indépendance envers les bailleurs de fonds, sécurité en cas de pertes, charges financières faibles (51.10)." end
     if r >= 30 then return p2(r) .. " : dans la moyenne (environ 30 %), mais sous l'idéal bancaire de 50 % (51.11)." end
     return p2(r) .. " : faible ; forte dépendance envers les créanciers, peu de réserve pour absorber des pertes."
   end, src = "51 p.10 · 51.10, 51.11 ; endettement + financement propre = 100 % (51.15)"},
  {id = "auto", nom = "Degré d'autofinancement", u = "%", dec = true, ex = "T25", champs = {"cc", "fp"}, fam = "Financement",
   formule = "Capital de croissance × 100 ÷ Capitaux propres",
   calc = function(v) return v.cc, v.fp, m(v.cc) .. " × 100 ÷ " .. m(v.fp) end,
   comm = function(r)
     local s = r < 20 and "faible : entreprise jeune, faible capacité bénéficiaire ou bénéfices distribués"
       or (r > 60 and "élevé : les bénéfices ont été accumulés dans les réserves (cas des coopératives, 51.14)" or "moyen")
     return p2(r) .. " : " .. s .. ". Dépend de l'âge de l'entreprise, des bénéfices antérieurs et de la politique de dividendes : à utiliser avec prudence (51.10, 51.15)."
   end, src = "51 p.10-11 · capital de croissance = réserves issues du bénéfice + bénéfice reporté (sans agio ni réserve issue du capital)"},
  {id = "couv1", nom = "Degré de couverture 1", u = "%", dec = true, ex = "T25", champs = {"fp", "ai"}, fam = "Couverture des immobilisations",
   formule = "Capitaux propres × 100 ÷ Actifs immobilisés",
   calc = function(v) return v.fp, v.ai, m(v.fp) .. " × 100 ÷ " .. m(v.ai) end,
   comm = function(r)
     if r > 80 then return p2(r) .. " > 80 % : les immobilisations sont " .. (r >= 100 and "entièrement" or "largement") .. " payées par les fonds propres ; risque très faible, entreprise pérenne." end
     if r >= 60 then return p2(r) .. " : dans la norme (entre 60 et 80 %) ; investissements majoritairement financés par les fonds propres." end
     return p2(r) .. " < 60 % : insuffisant par rapport à la norme (60 à 80 %) ; les immobilisations dépendent des capitaux étrangers."
   end, src = "51 p.13 · 51.10, 51.11"},
  {id = "couv2", nom = "Degré de couverture 2", u = "%", dec = true, ex = "T25", champs = {"fp", "lt", "ai"}, fam = "Couverture des immobilisations",
   formule = "(Capitaux propres + CE à long terme) × 100 ÷ Actifs immobilisés",
   calc = function(v) if not F.ok(v.fp, v.lt) then return nil end
     return v.fp + v.lt, v.ai, "(" .. m(v.fp) .. " + " .. m(v.lt) .. ") × 100 ÷ " .. m(v.ai) end,
   comm = function(r)
     if r >= 100 then return p2(r) .. " ≥ 100 % : la règle d'or est respectée ; les immobilisations sont financées par des capitaux permanents." end
     return p2(r) .. " < 100 % : ratio faible par rapport à la règle d'or (min. 100 %) ; une partie des immobilisations est financée à court terme."
   end, src = "51 p.13 · test 2025 ex. 3 (1.75) · 51.10"},
  {id = "tmb", nom = "Taux de marge brute", u = "%", ex = "M23", champs = {"mb", "can"}, fam = "Marges",
   formule = "Marge brute × 100 ÷ CAN",
   calc = function(v) return v.mb, v.can, m(v.mb) .. " × 100 ÷ " .. m(v.can) end,
   comm = function(r) return p2(r) .. " du CA reste après le coût des marchandises vendues pour couvrir les frais généraux et le bénéfice ; à comparer dans le temps et avec le secteur (51.23)." end,
   src = "51 p.35-37 · modèle 51.23"},
  {id = "tme", nom = "Taux de marge économique", u = "%", ex = "M23", champs = {"ebit", "can"}, fam = "Marges",
   formule = "EBIT × 100 ÷ CAN",
   calc = function(v) return v.ebit, v.can, m(v.ebit) .. " × 100 ÷ " .. m(v.can) end,
   comm = function(r, v)
     local s = p2(r) .. " : rentabilité de l'exploitation, avant intérêts et impôts"
     if v._r.tmb then s = s .. string.format(" ; l'écart avec le taux de marge brute (%s) mesure le poids des charges d'exploitation", p2(v._r.tmb)) end
     return s .. "."
   end, src = "51 p.36 · 51.23 · 51.27 (marge EBIT)"},
  {id = "tmn", nom = "Taux de marge nette", u = "%", ex = "M23", champs = {"bn", "can"}, fam = "Marges",
   formule = "Bénéfice net × 100 ÷ CAN",
   calc = function(v) return v.bn, v.can, m(v.bn) .. " × 100 ÷ " .. m(v.can) end,
   comm = function(r) return p2(r) .. " : part de chaque franc de CA qui reste en bénéfice net ; à comparer dans le temps (51.23)." end,
   src = "51 p.36 · 51.23"},
  {id = "rotcli", nom = "Rotation des créances clients", u = "x", ex = "C24", champs = {"cac", "cre", "cre1"}, fam = "Rotations et durées",
   formule = "CA à crédit ÷ ø créances clients",
   calc = function(v) local mo = F.moy(v, "cre", "créances clients"); return v.cac, mo, m(v.cac) .. " ÷ " .. m(mo) end,
   comm = function(r) return d2(r) .. " fois : plus la rotation est rapide, plus les clients paient vite (CAN total si le CA à crédit est inconnu)." end,
   src = "51 p.41 · 51.24"},
  {id = "durcli", nom = "Durée moyenne des crédits accordés", u = "j", ex = "C24", champs = {"cac", "cre", "cre1", "dcl"}, fam = "Rotations et durées",
   formule = "360 ÷ Rotation des clients", rot = "rotcli",
   comm = function(r, v)
     if v.dcl then
       if r > v.dcl then return string.format("%s jours > délai accordé de %s jours : les clients paient en retard ; relancer et suivre les factures, avec diplomatie (un débiteur reste un client, 51 p.41).", d2(r), m(v.dcl)) end
       return string.format("%s jours ≤ délai accordé de %s jours : les clients paient dans les délais.", d2(r), m(v.dcl))
     end
     return d2(r) .. " jours : les clients paient en moyenne après ce délai ; à comparer au délai de paiement accordé (au-delà : retards de paiement)."
   end, src = "51 p.41 · 51.24"},
  {id = "rotfrs", nom = "Rotation des dettes fournisseurs", u = "x", ex = "C24", champs = {"prama", "frs", "frs1"}, fam = "Rotations et durées",
   formule = "PRAMA à crédit ÷ ø dettes fournisseurs",
   calc = function(v) local mo = F.moy(v, "frs", "dettes fournisseurs"); return v.prama, mo, m(v.prama) .. " ÷ " .. m(mo) end,
   comm = function(r) return d2(r) .. " fois : PRAMA total si le PRAMA à crédit est inconnu (51 p.42) ; attention, PRAMA et non PRAMV." end,
   src = "51 p.42 · 51.24"},
  {id = "durfrs", nom = "Durée moyenne des crédits obtenus", u = "j", ex = "C24", champs = {"prama", "frs", "frs1", "dfo"}, fam = "Rotations et durées",
   formule = "360 ÷ Rotation des fournisseurs", rot = "rotfrs",
   comm = function(r, v)
     if v.dfo then
       if r > v.dfo then return string.format("%s jours > délai de %s jours : l'entreprise paie ses fournisseurs en retard (perte des escomptes, mauvaise image).", d2(r), m(v.dfo)) end
       return string.format("%s jours ≤ délai de %s jours : l'entreprise respecte les conditions de paiement ; inutile de payer avant l'échéance de l'escompte.", d2(r), m(v.dfo))
     end
     return d2(r) .. " jours : à comparer aux délais des fournisseurs ; plus long = retards de paiement (ou délais favorables obtenus, 51.24)."
   end, src = "51 p.42 · 51.24"},
  {id = "rotsto", nom = "Rotation des stocks", u = "x", ex = "C24", champs = {"pramv", "sto", "sto1"}, fam = "Rotations et durées",
   formule = "PRAMV ÷ ø stocks",
   calc = function(v) local mo = F.moy(v, "sto", "stocks"); return v.pramv, mo, m(v.pramv) .. " ÷ " .. m(mo) end,
   comm = function(r) return d2(r) .. " fois par an : une rotation rapide = gestion des stocks efficace (51.24)." end,
   src = "51 p.43 · 51.24"},
  {id = "dursto", nom = "Durée de stationnement des stocks", u = "j", ex = "C24", champs = {"pramv", "sto", "sto1"}, fam = "Rotations et durées",
   formule = "360 ÷ Rotation des stocks", rot = "rotsto",
   comm = function(r) return d2(r) .. " jours : durée à garder aussi courte que possible sans risque de rupture (flux tendus)." end,
   src = "51 p.40, 43 · 51.24"},
  {id = "rinv", nom = "Ratio d'investissement", u = "%", ex = "CF", champs = {"cf", "inv"}, fam = "Cash flow (chap. 57)",
   formule = "Cash flow × 100 ÷ Investissements nets",
   calc = function(v) return v.cf, v.inv, m(v.cf) .. " × 100 ÷ " .. m(v.inv) end,
   comm = function(r)
     if r >= 100 then return p2(r) .. " ≥ 100 % : les investissements nets sont entièrement financés par le cash flow (financement interne)." end
     return p2(r) .. " < 100 % : l'entreprise n'arrive pas à financer l'intégralité de ses investissements avec le cash flow qu'elle dégage ; prendre en compte la tendance à long terme (57.22)."
   end, src = "57 p.62 · modèle 57.22 (23.38 %)"},
  {id = "mcf", nom = "Marge de cash flow", u = "%", ex = "CF", champs = {"cf", "can"}, fam = "Cash flow (chap. 57)",
   formule = "Cash flow × 100 ÷ CAN",
   calc = function(v) return v.cf, v.can, m(v.cf) .. " × 100 ÷ " .. m(v.can) end,
   comm = function(r) return p2(r) .. " : liquidités dégagées par l'exploitation pour 100 CHF de CA ; à utiliser pour des comparaisons dans le temps (57 p.62)." end,
   src = "57 p.62 · modèle 57.22 (4.88 %)"},
  {id = "fend", nom = "Facteur d'endettement", u = "f", ex = "CF", champs = {"ce", "liq", "cre", "cf"}, fam = "Cash flow (chap. 57)",
   formule = "Endettement effectif ÷ Cash flow",
   calc = function(v)
     if not v.ee and F.ok(v.ce, v.liq, v.cre) then
       v.ee = v.ce - v.liq - v.cre
       X("Endettement effectif = CE − liquidités − créances = " .. m(v.ce) .. " − " .. m(v.liq) .. " − " .. m(v.cre) .. " = " .. m(v.ee))
     end
     return v.ee, v.cf, m(v.ee) .. " ÷ " .. m(v.cf)
   end,
   comm = function(r)
     if r <= 0 then return d2(r) .. " : endettement effectif négatif, liquidités et créances couvrent toutes les dettes." end
     if r <= 3 then return d2(r) .. " : très bon (entre 1 et 3) ; grande sécurité pour les prêteurs." end
     if r <= 5 then return d2(r) .. " : acceptable (entre 3 et 5)." end
     return string.format("%s : largement insuffisant (> 5) ; il faudrait plus de %d ans à l'entreprise pour rembourser ses dettes avec le cash flow qu'elle dégage (57.22).", d2(r), math.floor(r))
   end, src = "57 p.62 · modèle 57.22 (12.6)"},
  {id = "roi", nom = "Rendement des capitaux investis (ROI)", u = "%", ex = "COL", champs = {"ebit", "tot", "tot1"}, fam = "Rentabilité",
   formule = "EBIT × 100 ÷ Total moyen des bilans",
   calc = function(v) local mo = F.moy(v, "tot", "actifs (total des bilans)"); return v.ebit, mo, m(v.ebit) .. " × 100 ÷ " .. m(mo) end,
   comm = function(r, v)
     local s = p2(r) .. " : rentabilité de l'ensemble des capitaux investis (propres et étrangers), avant intérêts"
     if v.chf and v._m.ce then
       local t = v.chf * 100 / v._m.ce
       s = s .. string.format(" ; supérieure au taux d'intérêt moyen (%s) : l'endettement est rentable", p2(t))
       if r < t then s = p2(r) .. string.format(" : rentabilité des capitaux investis inférieure au taux d'intérêt moyen (%s) : l'endettement coûte plus qu'il ne rapporte", p2(t)) end
     else s = s .. " ; à comparer au taux d'intérêt des dettes et au rendement d'un placement sans risque" end
     return s .. "."
   end, src = "51 p.41-42 (PDF 45-46) · modèle 51.25 (7.44 %)"},
  {id = "roe", nom = "Rendement des fonds propres (ROE)", u = "%", ex = "COL", champs = {"bn", "fp", "fp1"}, fam = "Rentabilité",
   formule = "BN × 100 ÷ Total moyen des capitaux propres",
   calc = function(v) local mo = F.moy(v, "fp", "capitaux propres"); return v.bn, mo, m(v.bn) .. " × 100 ÷ " .. m(mo) end,
   comm = function(r, v)
     local s = p2(r) .. " : rémunération des actionnaires, à comparer au rendement d'un placement sans risque"
     if v._r.roi then
       if r > v._r.roi then s = s .. string.format(" ; ROE > ROI (%s) : l'endettement a un effet de levier positif", p2(v._r.roi))
       else s = s .. string.format(" ; ROE ≤ ROI (%s) : pas d'effet de levier positif", p2(v._r.roi)) end
     end
     return s .. "."
   end, src = "51 p.42 · modèle 51.25 (9.37 %)"},
  {id = "rota", nom = "Rotation de l'actif (hors test)", u = "x", ex = "COL", champs = {"can", "tot", "tot1"}, fam = "Rentabilité",
   formule = "CAN ÷ Moyenne des actifs",
   calc = function(v) local mo = F.moy(v, "tot", "actifs (total des bilans)"); return v.can, mo, m(v.can) .. " ÷ " .. m(mo) end,
   comm = function(r, v)
     local s = string.format("%.5f fois : chaque franc d'actif génère %s CHF de CA", r, d2(r))
     if v.ebit and v.can then
       local tme = v.ebit * 100 / v.can
       s = s .. string.format(". Décomposition (DuPont) : ROI = taux de marge économique × rotation de l'actif = %.4f %% × %.5f = %s", tme, r, p2(tme * r))
       s = s .. (r >= 3 and " ; c'est la rotation élevée qui explique le ROI, la marge EBIT est plutôt faible (51.27)" or
         (r < 1.5 and " ; rotation faible : c'est la marge EBIT qui porte le ROI (51.28)" or ""))
     end
     return s .. "."
   end, src = "51.27, 51.28 · décomposition du ROI : hors périmètre du 12.11"},
  {id = "levier", nom = "Effet de levier (hors test)", u = "pt", ex = "COL", champs = {"ebit", "chf", "tot", "tot1", "fp", "fp1"}, fam = "Rentabilité",
   formule = "(ROI − t) × ø CE ÷ ø FP",
   calc = function(v)
     local roi = F.val(v, "roi", true)
     local mce = F.moy(v, "ce", "capitaux étrangers")
     local mfp = F.moy(v, "fp", "capitaux propres")
     if not F.ok(roi, mce, mfp, v.chf) or mce == 0 or mfp == 0 then return nil end
     local t = v.chf * 100 / mce
     v._t = t
     X(string.format("t = charges financières × 100 ÷ ø CE = %s × 100 ÷ %s = %.4f %%", m(v.chf), m(mce), t))
     return {r = (roi - t) * mce / mfp}, nil, string.format("(%.4f %% − %.4f %%) × %s ÷ %s", roi, t, m(mce), m(mfp))
   end,
   comm = function(r, v)
     local roi = v._r.roi
     local s = string.format("ROE = ROI + effet de levier = %.4f %% + %.4f %% = %s. ", roi, r, p2(roi + r))
     if r > 0 then
       s = s .. "Le différentiel (ROI − t) est favorable : chaque franc emprunté rapporte plus qu'il ne coûte"
       s = s .. (r > roi and " ; la rentabilité des fonds propres est avant tout due à l'effet de levier (51.28)." or
         " ; la rentabilité des fonds propres est avant tout due à la rentabilité des capitaux investis, l'effet de levier est faible mais pourrait augmenter avec plus de fonds étrangers (51.27).")
     else s = s .. "Effet de levier négatif : les dettes coûtent plus qu'elles ne rapportent ; s'endetter fait baisser le ROE." end
     return s .. " Un effet de levier positif peut vite devenir négatif si la rentabilité baisse ou si les taux montent."
   end, src = "51.27, 51.28 · effet de levier : hors périmètre du 12.11"},
}
local RID = {}
for i, d in ipairs(RAT) do RID[d.id] = d; d.no = i end
-- libellés courts pour les grilles (écran de 318 px : 22 caractères au plus)
local COURT = {liq1 = "Liquidité 1", liq2 = "Liquidité 2", liq3 = "Liquidité 3", iac = "Intensité AC", iai = "Intensité AI",
  ["end"] = "Endettement", fp = "Financement propre", auto = "Autofinancement", couv1 = "Couverture 1", couv2 = "Couverture 2",
  tmb = "Taux marge brute", tme = "Taux marge écon.", tmn = "Taux marge nette", rotcli = "Rotation clients", durcli = "Durée crédits accordés",
  rotfrs = "Rotation fournisseurs", durfrs = "Durée crédits obtenus", rotsto = "Rotation stocks", dursto = "Durée stocks",
  rinv = "Ratio d'investissement", mcf = "Marge de cash flow", fend = "Facteur d'endettement", roi = "ROI", roe = "ROE",
  rota = "Rotation actif (HT)", levier = "Effet levier (HT)"}
-- abréviations des tableaux comparatifs compacts (premier écran) ; légende : F.legende(ids)
local ABR = {liq1 = "Liq. 1", liq2 = "Liq. 2", liq3 = "Liq. 3", iac = "Int. AC", iai = "Int. AI", ["end"] = "Endett.", fp = "Fin. propre",
  auto = "Autofin.", couv1 = "Couv. 1", couv2 = "Couv. 2", tmb = "TMB", tme = "TME", tmn = "TMN", rotcli = "Rot. cli.",
  durcli = "Durée cli.", rotfrs = "Rot. fourn.", durfrs = "Durée fourn.", rotsto = "Rot. stocks", dursto = "Durée stocks",
  rinv = "Invest.", mcf = "Marge CF", fend = "Fact. endett.", roi = "ROI", roe = "ROE", rota = "Rot. actif HT", levier = "Levier HT"}
-- {ids concernés, texte de légende} dans l'ordre d'affichage
local LEG = {{{"liq1", "liq2", "liq3"}, "Liq. = liquidité"}, {{"iac"}, "Int. AC = intensité des actifs circulants"}, {{"iai"}, "Int. AI = intensité des actifs immobilisés"},
  {{"end"}, "Endett. = degré d'endettement"}, {{"fp"}, "Fin. propre = degré de financement propre"}, {{"auto"}, "Autofin. = degré d'autofinancement"},
  {{"couv1", "couv2"}, "Couv. = degré de couverture des AI"}, {{"tmb", "tme", "tmn"}, "TMB, TME, TMN = taux de marge brute, économique, nette"},
  {{"rotcli", "durcli", "rotfrs", "durfrs", "rotsto", "dursto", "rota"}, "Rot. = rotation, cli. = clients, fourn. = fournisseurs (durée en jours)"},
  {{"rinv"}, "Invest. = ratio d'investissement"}, {{"mcf"}, "Marge CF = marge de cash flow"}, {{"fend"}, "Fact. endett. = facteur d'endettement"},
  {{"roi", "roe"}, "ROI, ROE = rentabilité des capitaux investis, des fonds propres"}, {{"rota", "levier"}, "HT = hors test"}}
function F.legende(ids)
  local pres, t = {}, {}
  for _, id in ipairs(ids) do pres[id] = true end
  for _, g in ipairs(LEG) do
    local ok = false
    for _, id in ipairs(g[1]) do if pres[id] then ok = true end end
    if ok then table.insert(t, g[2]) end
  end
  return table.concat(t, " · ")
end

-- durées : 360 ÷ rotation arrondie à 2 décimales (le prof divise par la rotation arrondie : 51.24, 360 ÷ 5.19 = 69.36)
for _, d in ipairs(RAT) do
  if d.rot then
    d.calc = function(v)
      local rt = F.val(v, d.rot, true)
      if not rt then return nil end
      return 360, r2(rt), "360 ÷ " .. d2(r2(rt))
    end
  end
end

function F.res(d, r)
  if d.u == "%" then return p2(r) .. (d.dec and ("   (ou " .. d2(r / 100) .. ")") or "") end
  if d.u == "x" then return d2(r) .. " fois" end
  if d.u == "j" then return d2(r) .. " jours" end
  if d.u == "pt" then return string.format("%.4f %%", r) end
  return d2(r)
end
function F.court(d, r)
  if not r then return "—" end
  if d.u == "%" or d.u == "pt" then return p2(r) end
  if d.u == "j" then return string.format("%.1f j", r) end
  return d2(r)
end

-- valeur d'un ratio (sans commentaire) ; avecLigne : écrit « Nom = application = résultat » sur une ligne
function F.val(v, id, avecLigne)
  if v._r[id] then return v._r[id] end
  local d = RID[id]
  local n, den, app = d.calc(v)
  local r
  if type(n) == "table" then r = n.r
  else
    if not F.ok(n, den) or den == 0 then return nil end
    r = n / den; if d.u == "%" then r = r * 100 end
  end
  v._r[id] = r
  if avecLigne then X(d.nom .. " = " .. app .. " = " .. F.res(d, r)) end
  return r
end

-- affichage complet : formule [R], application numérique, résultat, commentaire
function F.aff(d, v, sansComm)
  local n, den, app = d.calc(v)
  local r
  if type(n) == "table" then r = n.r
  else
    if not F.ok(n, den) then A(d.nom .. " : données manquantes (" .. table.concat(d.champs, ", ") .. ")"); return nil end
    if den == 0 then A(d.nom .. " : dénominateur nul"); return nil end
    r = n / den; if d.u == "%" then r = r * 100 end
  end
  v._r[d.id] = r
  COMMUN.calc(d.nom, d.formule, app, F.res(d, r))
  if not sansComm and d.comm then X("Commentaire : " .. d.comm(r, v)) end
  return r
end

-- famille de ratios du bilan (1 à 10) + FRN + commentaires de synthèse
function F.ratiosBilan(v)
  T("Liquidité")
  for _, id in ipairs({"liq1", "liq2", "liq3"}) do F.aff(RID[id], v) end
  X("Commentaire (liquidité) : " .. F.synthLiq(v._r.liq1, v._r.liq2, v._r.liq3))
  F.frn(v)
  T("Structure de l'actif")
  F.aff(RID.iac, v); F.aff(RID.iai, v)
  T("Financement")
  F.aff(RID["end"], v); F.aff(RID.fp, v)
  if v.cc then F.aff(RID.auto, v) else G("Degré d'autofinancement : capital de croissance non saisi (cc = réserves issues du bénéfice + bénéfice reporté).") end
  X("Commentaire (financement) : " .. F.synthFin(v._r["end"]))
  T("Couverture des immobilisations")
  F.aff(RID.couv1, v); F.aff(RID.couv2, v)
  X("Commentaire (couverture) : " .. F.synthCouv(v._r.couv1, v._r.couv2, v._r.iai, v._r["end"]))
end

function F.frn(v)
  if not F.ok(v.ac, v.ct, v.fp, v.lt, v.ai) then return end
  local a, b = v.ac - v.ct, v.fp + v.lt - v.ai
  COMMUN.calc("FRN", "Actifs circulants − CE à court terme", m(v.ac) .. " − " .. m(v.ct), m(a))
  COMMUN.calc("FRN", "(Capitaux propres + CE à long terme) − Actifs immobilisés", m(v.fp) .. " + " .. m(v.lt) .. " − " .. m(v.ai), m(b))
  if math.abs(a - b) > 0.5 then A("Les deux calculs du FRN diffèrent : le bilan n'est pas équilibré.") end
  X("Commentaire (FRN) : " .. (a >= 0 and "FRN positif, la situation est favorable : les capitaux permanents financent toutes les immobilisations et une partie de l'actif circulant (51 p.12)."
    or "FRN négatif : une partie des immobilisations est financée par des dettes à court terme ; la règle d'or n'est pas respectée (51 p.12)."))
end

------------------------------------------------------------------ bilan structuré
function F.grilleBilan(v, deux)
  local function L(lib, k, o)
    local l = {lib, m(v[k])}
    if deux then l[3] = m(v[k .. "1"]) end
    for kk, vv in pairs(o or {}) do l[kk] = vv end
    return l
  end
  for _, s in ipairs(deux and {"", "1"} or {""}) do
    if F.ok(v["ce" .. s], v["fp" .. s]) then v["pas" .. s] = v["ce" .. s] + v["fp" .. s] end
  end
  GRILLE("Bilan structuré", {
    L("Liquidités", "liq", {retrait = 1}), L("Créances", "cre", {retrait = 1}), L("Stocks", "sto", {retrait = 1}),
    L("Actifs circulants", "ac", {gras = true}), L("Actifs immobilisés", "ai", {gras = true}),
    L("Total de l'actif", "tot", {gras = true, trait = true, fond = true}),
    L("CE à court terme", "ct", {retrait = 1}), L("CE à long terme", "lt", {retrait = 1}),
    L("Capitaux étrangers", "ce", {gras = true}), L("Capitaux propres", "fp", {gras = true}),
    L("dont cap. croissance", "cc", {retrait = 1}),
    L("Total du passif", "pas", {gras = true, trait = true, fond = true}),
  }, {entetes = deux and {"", "N", "N-1"} or {"", "Montant"}})
  for _, s in ipairs(deux and {"", "1"} or {""}) do
    if F.ok(v["tot" .. s], v["pas" .. s]) and math.abs(v["tot" .. s] - v["pas" .. s]) > 0.5 then
      A("Bilan " .. (s == "" and "N" or "N-1") .. " déséquilibré : actif " .. m(v["tot" .. s]) .. " ≠ passif " .. m(v["pas" .. s]) .. ". Vérifier la saisie.")
    end
  end
end

------------------------------------------------------------------ composition chiffrée des postes agrégés
local POSTES = {
  {"liq", "Liquidités", "caisse + poste + banque + titres à court terme"},
  {"cre", "Créances", "créances clients − ducroire + autres créances à c.t."},
  {"sto", "Stocks", "marchandises (+ acomptes aux fournisseurs − acomptes de clients)"},
  {"ai", "Actifs immobilisés", "mobilier + machines + véhicules + immeubles + brevets + participations"},
  {"ct", "CE à court terme", "dettes fournisseurs + dividendes à payer + dettes bancaires à c.t. + autres dettes à c.t."},
  {"lt", "CE à long terme", "prêts et emprunts à long terme + hypothèques + provisions à l.t."},
  {"fp", "Capitaux propres", "capital-actions + réserves + bénéfice reporté"},
  {"cc", "Capital de croissance", "réserves issues du bénéfice + bénéfice reporté"},
}
function F.postes(v, deux)
  T("Postes du bilan (composition)")
  G("Chaque poste agrégé est la somme des comptes de l'énoncé (51 p.4) ; une somme saisie (ex. 35600+292979) est réécrite ici. Puis les sous-totaux du bilan structuré.")
  for _, s in ipairs(deux and {"", "1"} or {""}) do
    local an = s == "" and "" or " N-1"
    if deux then X(s == "" and "Année N :" or "Année N-1 :") end
    for _, p in ipairs(POSTES) do
      local k = p[1] .. s
      local val, t = v[k], v._txt and v._txt[k]
      if val then
        X(p[2] .. an .. " = " .. p[3])
        local app = (t and COMMUN.estExpr(t)) and (COMMUN.exprTexte(t) .. " = " .. m(val)) or (m(val) .. " (montant saisi)")
        if #app <= 44 then R("  = ", "", app) else X("  = " .. app) end   -- R ne coupe pas les lignes
      end
    end
    local liq, cre, sto, ai, ct, lt, fp = v["liq" .. s], v["cre" .. s], v["sto" .. s], v["ai" .. s], v["ct" .. s], v["lt" .. s], v["fp" .. s]
    if F.ok(liq, cre, sto) then
      X("Actifs circulants" .. an .. " = liquidités + créances + stocks = " .. m(liq) .. " + " .. m(cre) .. " + " .. m(sto) .. " = " .. m(liq + cre + sto))
    end
    if F.ok(v["ac" .. s], ai) then X("Total de l'actif" .. an .. " = AC + AI = " .. m(v["ac" .. s]) .. " + " .. m(ai) .. " = " .. m(v["ac" .. s] + ai)) end
    if F.ok(ct, lt) then X("Capitaux étrangers" .. an .. " = CE ct + CE lt = " .. m(ct) .. " + " .. m(lt) .. " = " .. m(ct + lt)) end
    if F.ok(v["ce" .. s], fp) then X("Total du passif" .. an .. " = CE + capitaux propres = " .. m(v["ce" .. s]) .. " + " .. m(fp) .. " = " .. m(v["ce" .. s] + fp)) end
  end
end

-- conclusion rédigée : points forts, points faibles, appréciation d'ensemble (à partir des ratios déjà calculés dans v._r)
function F.conclusion(v)
  local r = v._r
  local fort, faible = {}, {}
  local function aj(t, s) table.insert(t, s) end
  if r.liq2 then
    if r.liq2 >= 100 then aj(fort, "dettes à court terme couvertes par liquidités et créances (liquidité 2 = " .. p2(r.liq2) .. " ≥ 100 %)")
    else aj(faible, "liquidités et créances insuffisantes pour payer les dettes à court terme (liquidité 2 = " .. p2(r.liq2) .. " < 100 %)") end
  end
  if r.liq1 then
    if r.liq1 > 30 then aj(faible, "excédent de liquidités qui ne rapportent rien (liquidité 1 = " .. p2(r.liq1) .. " > 30 %), sauf investissement prévu")
    elseif r.liq1 < 20 and not (r.liq2 and r.liq2 >= 100) then aj(faible, "manque de liquidités immédiates (liquidité 1 = " .. p2(r.liq1) .. " < 20 %)") end
  end
  if r.liq3 and r.liq3 < 100 then aj(faible, "FRN négatif (liquidité 3 = " .. p2(r.liq3) .. " < 100 %)") end
  if r["end"] then
    if r["end"] < 50 then aj(fort, "endettement faible (" .. p2(r["end"]) .. "), risque réduit")
    elseif r["end"] > 70 then aj(faible, "surendettement (" .. p2(r["end"]) .. "), vulnérable en cas de perte") end
  end
  if r.couv2 then
    if r.couv2 >= 100 then aj(fort, "règle d'or respectée (couverture 2 = " .. p2(r.couv2) .. ")")
    else aj(faible, "règle d'or non respectée (couverture 2 = " .. p2(r.couv2) .. " < 100 %)") end
  end
  if r.couv1 and r.couv1 < 60 then aj(faible, "immobilisations trop peu financées par les fonds propres (couverture 1 = " .. p2(r.couv1) .. " < 60 %)") end
  if r.roi and r.roe then
    if r.roe > r.roi then aj(fort, "ROE (" .. p2(r.roe) .. ") supérieur au ROI (" .. p2(r.roi) .. ") : l'endettement profite aux actionnaires")
    else aj(faible, "ROE (" .. p2(r.roe) .. ") pas supérieur au ROI (" .. p2(r.roi) .. ")") end
  end
  if r.tme and r.tme < 3 then aj(faible, "marge économique faible (" .. p2(r.tme) .. " du CA)") end
  if r.fend and r.fend > 5 then aj(faible, "facteur d'endettement de " .. d2(r.fend) .. " (> 5)") end
  if r.durcli and v.dcl and r.durcli > v.dcl then aj(faible, "clients en retard de paiement (" .. d2(r.durcli) .. " j > " .. m(v.dcl) .. " j)") end
  T("Conclusion")
  if #fort > 0 then X("Points forts : " .. table.concat(fort, " ; ") .. ".") end
  if #faible > 0 then X("Points faibles ou à surveiller : " .. table.concat(faible, " ; ") .. ".") end
  local grave = (r.liq2 and r.liq2 < 100 and r.liq3 and r.liq3 < 100) or (r["end"] and r["end"] > 70) or (r.couv2 and r.couv2 < 100)
  local s
  if grave then s = "Situation financière fragile : à corriger en priorité (encaisser les créances, obtenir des capitaux permanents, réduire l'endettement)."
  elseif #faible == 0 then s = "Situation financière saine : l'entreprise peut payer ses dettes et finance correctement ses immobilisations."
  else s = "Situation financière globalement saine, avec les points à surveiller ci-dessus." end
  X("Appréciation : " .. s)
end

------------------------------------------------------------------ 1. analyse complète
local CH_ANA = {"liq", "cre", "sto", "ai", "ct", "lt", "fp", "cc", "liq1", "cre1", "sto1", "ai1", "ct1", "lt1", "fp1", "cc1",
  "can", "cac", "pramv", "prama", "bn", "chf", "pf", "imp", "amo", "ebit", "frs", "frs1", "cf", "inv", "dcl", "dfo"}
local EX_ANA = {liq = "35600+292979", cre = 528920, sto = 459822, ai = "305000+106000+100000", ct = 202540, lt = "55000+280992",
  fp = "1000000+284000+5789", cc = "284000+5789",
  liq1 = "14560+48250", cre1 = 450622, sto1 = 368930, ai1 = "365000+146000+120000", ct1 = 125654, lt1 = "40000+120800",
  fp1 = "1000000+218000+8908", cc1 = "218000+8908",
  can = 8432560, pramv = 5059536, bn = 117881, chf = 6480, pf = 0, imp = 0, amo = 125000}

function F.analyse(brut)
  local v = F.deriver(COMMUN.lireChamps(brut or "", F.champs(CH_ANA, EX_ANA)))
  local deux = v.liq1 ~= nil
  vider()
  T("Analyse complète du bilan et du résultat")
  G("Méthode : bilan structuré (liquidités, créances, stocks | AI ; CE ct, CE lt, FP), puis les 26 ratios de la liste Profil M, chacun avec la formule, l'application numérique, le résultat (en % et en décimal) et un commentaire : valeur, valeur indicative du manuel, conséquence pour l'entreprise. Les ratios du bilan portent sur l'année N ; rotations et rentabilités utilisent les moyennes (N-1 + N) ÷ 2.")
  G("Par défaut : Colibri SA (51.25, corrigé : EBIT 124'361, ROI 7.44 %, ROE 9.37 % ; 51.27 : levier 1.9249 %). Dividendes laissés en CE l.t. comme dans le bilan du prof.")
  F.grilleBilan(v, deux)
  F.postes(v, deux)
  if v.can then
    local l = {{"CA net", m(v.can)}, {"./. PRAMV", m(v.pramv and -v.pramv)}, {"Marge brute", m(v.mb), gras = true, trait = true}}
    table.insert(l, {"EBIT", m(v.ebit), gras = true})
    table.insert(l, {"./. Charges financières", m(-(v.chf or 0))})
    if (v.pf or 0) ~= 0 then table.insert(l, {"+ Produits financiers", m(v.pf)}) end
    if (v.imp or 0) ~= 0 then table.insert(l, {"./. Impôts", m(-v.imp)}) end
    table.insert(l, {"Bénéfice net", m(v.bn), gras = true, trait = true, fond = true})
    GRILLE("Compte de résultat (résumé)", l, {entetes = {"", "N"}})
  end
  if #v._auto > 0 then
    T("Valeurs déduites")
    for _, s in ipairs(v._auto) do X(s) end
  end
  F.ratiosBilan(v)
  local fam = ""
  for i = 11, #RAT do
    local d = RAT[i]
    if d.fam ~= fam then
      fam = d.fam; T(fam)
      if fam == "Cash flow (chap. 57)" then G("Ratios du chap. 57 (test de janvier) ; cash flow et investissements nets reconstitués s'ils ne sont pas saisis.") end
    end
    F.aff(d, v)
  end
  if F.ok(v.cf, v.inv) then
    COMMUN.calc("Free cash flow", "Cash flow − Investissements nets", m(v.cf) .. " − " .. m(v.inv), m(v.cf - v.inv))
    X("Commentaire : " .. (v.cf - v.inv >= 0 and "free cash flow positif : marge de manœuvre pour rembourser des dettes ou verser un dividende."
      or "free cash flow négatif : aucune marge de manœuvre pour rembourser des dettes ou verser un dividende exceptionnel (57.22)."))
  end
  F.conclusion(v)
  -- tableau des 26 ratios en tête du document (juste sous le titre) : 2 tableaux compacts de 13 lignes, chacun sur un écran
  local l, ids = {}, {}
  local v1
  if deux then
    v1 = F.deriver({liq = v.liq1, cre = v.cre1, sto = v.sto1, ai = v.ai1, ct = v.ct1, lt = v.lt1, fp = v.fp1, cc = v.cc1})
  end
  for i, d in ipairs(RAT) do
    local ligne = {ABR[d.id], F.court(d, v._r[d.id])}
    if deux then ligne[3] = (i <= 10) and F.court(d, F.val(v1, d.id)) or "" end
    table.insert(l, ligne); table.insert(ids, d.id)
  end
  GRILLE("Les 26 ratios", l, {entetes = deux and {"", "N", "N-1"} or {"", "N"}, compact = true, pos = 2,
    legende = F.legende(ids) .. ". N-1 : ratios du bilan seulement ; détail et commentaires plus bas (liste Profil M ; normes 51 p.11-13)."})
  montrer("Analyse complète")
end

------------------------------------------------------------------ 2. ratios du bilan, une année (test 2025 ex. 3)
local CH_BIL = {"liq", "cre", "sto", "ai", "ct", "lt", "fp", "cc"}
function F.bilan(brut)
  local v = F.deriver(COMMUN.lireChamps(brut or "", F.champs(CH_BIL, EX.T25)))
  vider()
  T("Ratios du bilan (une année)")
  G("Méthode : classer le bilan en liquidités, créances, stocks, AI | CE ct, CE lt, FP (garder le classement de l'énoncé : en 2025, dividendes en CE l.t.), choisir la bonne année, puis formule, application, résultat et commentaire (2 pts par commentaire). Modèle : test 2025 ex. 3 (14.44 % · 118.89 % · 216.67 % · 1.28 · 1.75).")
  G("Par défaut : test 2025 ex. 3, colonne 2026 ; capital de croissance = réserves 250 + bénéfice reporté 20 (hypothèse : réserves issues du bénéfice).")
  F.grilleBilan(v, false)
  F.postes(v, false)
  F.ratiosBilan(v)
  F.conclusion(v)
  montrer("Ratios du bilan")
end

------------------------------------------------------------------ 3. comparer des entreprises (test 2025 ex. 5, 51.8)
-- deux entrées : à partir des bilans (F.comparer) ou des ratios déjà calculés (F.comparerRatios) ; même analyse (F.cmpRendu).
-- Ratios du bilan en décimal comme le corrigé du prof (0.82) ; rentabilités et marges en %.
local CMP_IDS = {"liq1", "liq2", "liq3", "iai", "end", "fp", "couv1", "couv2", "roi", "roe", "tmb", "tme", "tmn"}
local CMP_PCT = {roi = true, roe = true, tmb = true, tme = true, tmn = true}
local CMP_AIDE = {
  liq1 = "Liquidité 1 = liquidités ÷ CE à court terme. Valeur indicative 0.2 à 0.3.",
  liq2 = "Liquidité 2 = (liquidités + créances) ÷ CE à court terme. Valeur indicative ≥ 1 (le ratio le plus important).",
  liq3 = "Liquidité 3 = actifs circulants ÷ CE à court terme. Valeur indicative 1.5 à 2 ; < 1 = FRN négatif.",
  iai = "Intensité des actifs immobilisés = AI ÷ total du bilan. Pas de norme : élevée = charges fixes importantes.",
  ["end"] = "Degré d'endettement = capitaux étrangers ÷ total du passif. Repères des corrigés : 0.40 faible, 0.56 dans la norme, 0.82 surendettée.",
  fp = "Degré de financement propre = capitaux propres ÷ total du passif (= 1 − endettement). Idéal bancaire ≥ 0.5.",
  couv1 = "Degré de couverture 1 = capitaux propres ÷ AI. Valeur indicative 0.6 à 0.8.",
  couv2 = "Degré de couverture 2 = (capitaux propres + CE à long terme) ÷ AI. Règle d'or : ≥ 1.",
  roi = "ROI = EBIT ÷ total moyen des bilans. Facultatif.",
  roe = "ROE = bénéfice net ÷ capitaux propres moyens. Facultatif.",
  tmb = "Taux de marge brute = marge brute ÷ CAN. Facultatif.",
  tme = "Taux de marge économique = EBIT ÷ CAN. Facultatif.",
  tmn = "Taux de marge nette = bénéfice net ÷ CAN. Facultatif.",
}
local FORMAT_R = " En décimal (0.82) ou en % (82%) ; un nombre > 10 (ratios du bilan) ou ≥ 1 (rentabilités, marges) est lu comme un %. Vide = ignoré."
local DEF_NOMS = {"Bouvier", "Corgi", "Husky", "E4", "E5"}
-- corrigé du prof (test 2025 ex. 5) ; fp et couv1 : calculés depuis les bilans de l'énoncé (non demandés en 2025)
local DEF_RAT = {
  {liq1 = "0.82", liq2 = "0.95", liq3 = "2.27", iai = "0.5", ["end"] = "0.4", fp = "0.6", couv1 = "1.2", couv2 = "1.56"},
  {liq1 = "0.26", liq2 = "0.97", liq3 = "1", iai = "0.62", ["end"] = "0.58", fp = "0.42", couv1 = "0.68", couv2 = "1.00"},
  {liq1 = "0.17", liq2 = "0.75", liq3 = "1.27", iai = "0.24", ["end"] = "0.82", fp = "0.18", couv1 = "0.75", couv2 = "1.67"},
}
-- bilans de l'énoncé (test 2025 ex. 5) : liquidités, créances, stocks, AI, CE ct, CE lt, capitaux propres, [capital de croissance]
local CMP_K = {"liq", "cre", "sto", "ai", "ct", "lt", "fp", "cc"}
local DEF_BIL = {{"18", "3", "29", "50", "22", "18", "60", ""}, {"10", "27", "1", "62", "38", "20", "42", ""}, {"10", "35", "31", "24", "60", "22", "18", ""}}
local DEF_CMP = "Bouvier: 18 3 29 50 22 18 60 / Corgi: 10 27 1 62 38 20 42 / Husky: 10 35 31 24 60 22 18"

function F.defRatios()
  local seg = {}
  for j, d in ipairs(DEF_RAT) do
    local t = {}
    for _, id in ipairs(CMP_IDS) do if d[id] then table.insert(t, id .. "=" .. d[id]) end end
    table.insert(seg, DEF_NOMS[j] .. ": " .. table.concat(t, ";"))
  end
  return table.concat(seg, " / ")
end

-- 82 -> 0.82 pour un ratio du bilan ; 9.37 -> 0.0937 pour une rentabilité
function F.normR(id, x)
  if not x then return nil end
  if CMP_PCT[id] then if math.abs(x) >= 1 then return x / 100 end
  elseif math.abs(x) > 10 then return x / 100 end
  return x
end

-- coupe un nom à n caractères (UTF-8) pour les en-têtes de colonnes
function F.tronquer(s, n)
  local out, k = "", 0
  for ch in tostring(s):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    k = k + 1
    if k > n then return out end
    out = out .. ch
  end
  return out
end

local NIV_LIQ = {[0] = "risque d'insolvabilité", "liquidité tendue", "liquidité juste suffisante", "aucun problème de paiement"}
local NIV_LIQC = {[0] = "critique", "tendue", "juste", "bonne"}
local NIV_FIN = {[0] = "structure de financement fragile", "structure de financement correcte", "structure de financement solide"}
local NIV_FINC = {[0] = "fragile", "correcte", "solide"}

-- appréciation de la liquidité (ratios en décimal) : phrases (tournures du corrigé 51.8) et niveau 0 à 3
function F.cmpLiq(r)
  local l1, l2, l3 = r.liq1, r.liq2, r.liq3
  local p = {}
  if l1 then
    if l1 > 0.3 then table.insert(p, "liquidité 1 = " .. d2(l1) .. " > 0.3 : nettement en excédent de liquidités ; peut-être est-ce volontaire (achat d'une autre entreprise, investissements importants à venir), sinon c'est de l'argent qui ne rapporte rien")
    elseif l1 >= 0.2 then table.insert(p, "liquidité 1 = " .. d2(l1) .. " : assez dans la norme (entre 0.2 et 0.3)")
    else table.insert(p, "liquidité 1 = " .. d2(l1) .. " < 0.2 : en manque de liquidités immédiates") end
  end
  if l2 then
    if l2 >= 1 then table.insert(p, "liquidité 2 = " .. d2(l2) .. " ≥ 1 : liquidités et créances couvrent les dettes à court terme")
    elseif l2 >= 0.9 then table.insert(p, "liquidité 2 = " .. d2(l2) .. ", juste sous 1 : liquidités et créances couvrent presque les dettes à court terme")
    else table.insert(p, "liquidité 2 = " .. d2(l2) .. " < 1 : liquidités et créances ne suffisent pas à payer les dettes à court terme ; il faudra vendre du stock ou obtenir un crédit") end
  end
  if l3 then
    if l3 >= 1.5 then table.insert(p, "liquidité 3 = " .. d2(l3) .. " > 1.5 : avec les stocks, les dettes à court terme sont largement couvertes")
    elseif l3 >= 1 then
      if l2 and l3 - l2 < 0.1 then table.insert(p, "liquidité 3 = " .. d2(l3) .. ", sous 1.5 et à peine au-dessus de la liquidité 2 : presque pas de stock pour compléter")
      else table.insert(p, "liquidité 3 = " .. d2(l3) .. ", entre 1 et 1.5 : les dettes à court terme ne sont couvertes que si le stock se vend") end
    else table.insert(p, "liquidité 3 = " .. d2(l3) .. " < 1 : même en vendant tout son stock, l'entreprise ne peut pas payer ses dettes à court terme (FRN négatif)") end
  end
  local n
  if l3 and l3 < 1 then n = 0
  elseif l2 and l2 < 0.9 then n = 1
  elseif (l2 and l2 >= 1) or (l3 and l3 >= 1.5) then n = 3
  elseif l2 or l3 then n = 2
  elseif l1 then n = l1 >= 0.2 and 2 or 1 end
  return p, n
end

-- appréciation de la structure de financement : phrases et niveau 0 à 2
function F.cmpFin(r)
  local e, f, i, c1, c2 = r["end"], r.fp, r.iai, r.couv1, r.couv2
  local p = {}
  if e then
    if e < 0.5 then table.insert(p, "degré d'endettement = " .. d2(e) .. " : endettement faible, l'entreprise se finance avant tout par des fonds propres ; les risques sont moindres, mais cela va compromettre la rentabilité des fonds propres")
    elseif e <= 0.7 then table.insert(p, "degré d'endettement = " .. d2(e) .. " : un financement qui correspond assez à la norme (51.8 : 0.56)")
    else table.insert(p, "degré d'endettement = " .. d2(e) .. " : l'entreprise est surendettée, très dépendante de ses créanciers et vulnérable en cas de perte ; ses charges financières sont élevées") end
  end
  if f then
    local s = "financement propre = " .. d2(f) .. (f >= 0.5 and " ≥ 0.5 (idéal bancaire) : indépendance envers les bailleurs de fonds"
      or (f >= 0.3 and ", dans la moyenne (environ 0.3) mais sous l'idéal bancaire de 0.5" or " : faible, peu de réserve pour absorber des pertes"))
    if e and math.abs(e + f - 1) > 0.02 then s = s .. " (attention : endettement + financement propre ≠ 1, vérifier la saisie)" end
    table.insert(p, s)
  end
  if i then
    if i >= 0.6 then table.insert(p, "intensité des AI = " .. d2(i) .. " : beaucoup d'immobilisations, donc des charges fixes importantes (amortissements, entretien)")
    elseif i < 0.3 then table.insert(p, "intensité des AI = " .. d2(i) .. " : peu d'immobilisations (commerce, services), peu de charges fixes")
    else table.insert(p, "intensité des AI = " .. d2(i) .. " : immobilisations moyennes") end
  end
  if c1 then
    if c1 >= 1 then table.insert(p, "couverture 1 = " .. d2(c1) .. " ≥ 1 : les immobilisations sont entièrement payées par les fonds propres")
    elseif c1 > 0.8 then table.insert(p, "couverture 1 = " .. d2(c1) .. " > 0.8 : les immobilisations sont largement payées par les fonds propres")
    elseif c1 >= 0.6 then table.insert(p, "couverture 1 = " .. d2(c1) .. " : dans la norme (0.6 à 0.8), immobilisations financées surtout par les fonds propres")
    else table.insert(p, "couverture 1 = " .. d2(c1) .. " < 0.6 : les immobilisations dépendent des capitaux étrangers") end
  end
  local n
  if (e and e > 0.7) or (c2 and r2(c2) < 1) then n = 0
  elseif (e or c2) and (not e or e <= 0.5) and (not c2 or r2(c2) > 1) then n = 2
  elseif e or c2 then n = 1 end
  return p, n
end

-- règle d'or (couverture 2) ; nil si non saisie
function F.cmpOr(r)
  local c2 = r.couv2
  if not c2 then return nil end
  local s
  if r2(c2) > 1 then s = "couverture 2 = " .. d2(c2) .. " > 1 : règle d'or respectée, les immobilisations sont financées par des capitaux permanents (fonds propres + CE à long terme)"
  elseif r2(c2) == 1 then s = "couverture 2 = " .. d2(c2) .. " : tout juste à la limite de la règle d'or ; les capitaux permanents couvrent exactement les immobilisations, sans aucune marge (FRN nul)"
  else s = "couverture 2 = " .. d2(c2) .. " < 1 : règle d'or non respectée ; une partie des immobilisations est financée par des dettes à court terme, à rembourser avant que ces investissements ne rapportent" end
  if r2(c2) > 1 and r.iai and r.iai < 0.3 and r["end"] and r["end"] > 0.7 then
    s = s .. " ; mais elle n'est élevée que parce que les immobilisations sont faibles (intensité des AI = " .. d2(r.iai) .. "), alors que l'entreprise est très endettée"
  end
  return s
end

-- analyse complète d'un groupe d'entreprises : ents = {{nom = "…", r = {liq1 = 0.82, …}}, …}
-- tableau comparatif compact (ratios renseignés seulement), à placer juste sous le titre : pos = rang dans le document
function F.cmpTableau(ents, lignesSup, pos)
  local ent = {""}
  for _, e in ipairs(ents) do table.insert(ent, e.nom) end   -- la grille compacte tronque les noms à la largeur des colonnes
  local l, ids = {}, {}
  for _, id in ipairs(CMP_IDS) do
    local present = false
    for _, e in ipairs(ents) do if e.r[id] then present = true end end
    if present then
      local ligne = {ABR[id]}
      for _, e in ipairs(ents) do local x = e.r[id]; ligne[#ligne + 1] = x and (CMP_PCT[id] and p2(x * 100) or d2(x)) or "—" end
      table.insert(l, ligne); table.insert(ids, id)
    end
  end
  for _, x in ipairs(lignesSup or {}) do table.insert(l, x) end
  local leg = F.legende(ids)
  if lignesSup and #lignesSup > 0 then leg = leg .. " · FRN = fonds de roulement net (AC − CE ct)" end
  GRILLE("", l, {entetes = ent, compact = true, pos = pos, legende = leg .. ". Rentabilités et marges en %, autres ratios en décimal."})
end

function F.cmpRendu(ents)
  local n = #ents
  G("Valeurs indicatives (51 p.11-13) : liquidité 1 de 0.2 à 0.3 ; liquidité 2 ≥ 1 ; liquidité 3 de 1.5 à 2 ; couverture 1 de 0.6 à 0.8 ; couverture 2 ≥ 1 (règle d'or). Endettement, repères des corrigés 51.8 et 51.10 : 0.40 faible, 0.56 dans la norme, 0.82 surendetté.")

  local function classer(cle, ratio, desc)
    local t = {}
    for _, e in ipairs(ents) do if e[cle] then table.insert(t, e) end end
    table.sort(t, function(a, b)
      if a[cle] ~= b[cle] then return a[cle] > b[cle] end
      local x, y = a.r[ratio] or 0, b.r[ratio] or 0
      if desc then return x > y end
      return x < y
    end)
    return t
  end
  local function extreme(id, plusGrand)
    local best
    for _, e in ipairs(ents) do
      local x = e.r[id]
      if x and (not best or (plusGrand and x > best.r[id]) or (not plusGrand and x < best.r[id])) then best = e end
    end
    return best
  end

  -- a) liquidité
  T("a) Niveau de liquidité")
  G("Pour chaque entreprise : ratio, valeur indicative, conséquence (tournures du corrigé 51.8). Barème 2025 (hypothèse, BAREME.md §3) : 3 pts, soit 1 pt par entreprise.")
  for _, e in ipairs(ents) do
    local p, nl = F.cmpLiq(e.r)
    e.nl = nl
    if #p > 0 then X(e.nom .. " : " .. table.concat(p, " ; ") .. ". → " .. NIV_LIQ[nl] .. ".")
    else G(e.nom .. " : aucun ratio de liquidité saisi.") end
  end
  local tl = classer("nl", "liq2", true)
  if #tl >= 2 then
    local a, z = tl[1], tl[#tl]
    local s = a.nom .. " a la meilleure liquidité (" .. NIV_LIQ[a.nl] .. "), " .. z.nom .. " la plus faible (" .. NIV_LIQ[z.nl] .. ")"
    for k = 2, #tl - 1 do s = s .. " ; " .. tl[k].nom .. " se situe entre les deux (" .. NIV_LIQ[tl[k].nl] .. ")" end
    local hi, lo = extreme("liq2", true), extreme("liq2", false)
    if hi and lo and hi ~= lo then
      s = s .. ". La liquidité 2, le ratio le plus important, va de " .. d2(lo.r.liq2) .. " (" .. lo.nom .. ") à " .. d2(hi.r.liq2) .. " (" .. hi.nom .. ")"
    end
    local exc = {}
    for _, e in ipairs(ents) do if e.r.liq1 and e.r.liq1 > 0.3 then table.insert(exc, e.nom) end end
    if #exc > 0 then s = s .. ". " .. table.concat(exc, " et ") .. (#exc > 1 and " gardent" or " garde") .. " beaucoup de liquidités qui ne rapportent rien" end
    X("Comparaison : " .. s .. ".")
  end

  -- b) structure de financement
  T("b) Structure de financement")
  G("Endettement, financement propre, poids des immobilisations, couverture 1 (barème 2025, hypothèse : 3 pts, 1 pt par entreprise).")
  for _, e in ipairs(ents) do
    local p, nf = F.cmpFin(e.r)
    e.nf = nf
    if #p > 0 then X(e.nom .. " : " .. table.concat(p, " ; ") .. ". → " .. (nf and NIV_FIN[nf] or "à compléter avec la règle d'or") .. ".")
    else G(e.nom .. " : aucun ratio de financement saisi.") end
  end
  local tf = classer("nf", "end", false)
  if #tf >= 2 then
    local function det(e) return NIV_FIN[e.nf] .. (e.r["end"] and (", endettement " .. d2(e.r["end"])) or "") end
    local a, z = tf[1], tf[#tf]
    local s = a.nom .. " a la structure la plus sûre (" .. det(a) .. "), " .. z.nom .. " la plus risquée (" .. det(z) .. ")"
    for k = 2, #tf - 1 do s = s .. " ; " .. tf[k].nom .. " se situe entre les deux (" .. det(tf[k]) .. ")" end
    local im = extreme("iai", true)
    if im and im.r.iai >= 0.5 then s = s .. ". " .. im.nom .. " a le plus d'immobilisations (intensité " .. d2(im.r.iai) .. "), donc le plus de charges fixes" end
    X("Comparaison : " .. s .. ". Moins d'endettement = moins de risque, mais une rentabilité des fonds propres moins favorisée (51.8).")
  end

  -- c) règle d'or
  local ok, lim, non = {}, {}, {}
  local avecOr = false
  for _, e in ipairs(ents) do if e.r.couv2 then avecOr = true end end
  if avecOr then
    T("c) Règle d'or (couverture 2)")
    for _, e in ipairs(ents) do
      local s = F.cmpOr(e.r)
      if s then
        X(e.nom .. " : " .. s .. ".")
        local c = r2(e.r.couv2)
        table.insert(c > 1 and ok or (c == 1 and lim or non), e.nom)
      end
    end
    if n >= 2 then
      local t = {}
      if #ok > 0 then table.insert(t, "respectée par " .. table.concat(ok, ", ")) end
      if #lim > 0 then table.insert(t, "tout juste par " .. table.concat(lim, ", ")) end
      if #non > 0 then table.insert(t, "non respectée par " .. table.concat(non, ", ")) end
      X("Bilan : règle d'or " .. table.concat(t, " ; ") .. ".")
    end
  end

  -- d) rentabilité (facultatif)
  local avecRen = false
  for _, e in ipairs(ents) do for id in pairs(CMP_PCT) do if e.r[id] then avecRen = true end end end
  if avecRen then
    T("d) Rentabilité et marges")
    for _, e in ipairs(ents) do
      local t = {}
      for _, id in ipairs({"roe", "roi", "tmb", "tme", "tmn"}) do if e.r[id] then table.insert(t, COURT[id] .. " = " .. p2(e.r[id] * 100)) end end
      if #t > 0 then
        local s = e.nom .. " : " .. table.concat(t, ", ")
        if e.r.roe and e.r.roi then
          s = s .. (e.r.roe > e.r.roi and " ; ROE > ROI : l'endettement profite aux actionnaires (effet de levier positif, hors test)"
            or " ; ROE ≤ ROI : l'endettement ne profite pas aux actionnaires")
        end
        X(s .. ".")
      end
    end
    local b, nroe = extreme("roe", true), 0
    for _, e in ipairs(ents) do if e.r.roe then nroe = nroe + 1 end end
    if b and nroe >= 2 then X("Comparaison : " .. b.nom .. " rémunère le mieux ses actionnaires (ROE = " .. p2(b.r.roe * 100) .. ") ; à rapprocher de son endettement (le levier augmente le ROE mais aussi le risque).") end
  end

  -- classement et conclusion
  for _, e in ipairs(ents) do
    e.score = (e.nl or 0) + 1.5 * (e.nf or 0) + 0.1 * (e.r.liq2 or 0) - 0.1 * (e.r["end"] or 0) + (e.r.roe or 0)
  end
  local cl = {}
  for _, e in ipairs(ents) do table.insert(cl, e) end
  table.sort(cl, function(a, b) return a.score > b.score end)
  if n >= 2 then
    T("Classement")
    local lc = {}
    for k, e in ipairs(cl) do
      table.insert(lc, {k .. ". " .. e.nom, e.nl and NIV_LIQC[e.nl] or "—", e.nf and NIV_FINC[e.nf] or "—", gras = k == 1})
    end
    GRILLE("Du plus solide au plus fragile", lc, {entetes = {"", "Liquidité", "Financement"}})
    G("Classement de la calculatrice : niveau de liquidité + 1.5 × niveau de financement (le financement pèse plus : il engage l'entreprise à long terme). Repère personnel, pas une règle du prof.")
  end
  T("Conclusion")
  for k, e in ipairs(cl) do
    local liq = e.nl and NIV_LIQ[e.nl] or "liquidité non évaluée"
    local fin = e.nf and NIV_FIN[e.nf] or "financement non évalué"
    local det = {}
    if e.r["end"] then table.insert(det, "endettement " .. d2(e.r["end"])) end
    if e.r.couv2 then
      local c = r2(e.r.couv2)
      table.insert(det, c > 1 and "règle d'or respectée" or (c == 1 and "règle d'or tout juste respectée" or "règle d'or non respectée"))
    end
    local s
    if n == 1 then s = e.nom .. " : " .. liq .. " et " .. fin
    elseif k == 1 then s = e.nom .. " présente la situation la plus solide : " .. liq .. " et " .. fin
    elseif k == n then s = e.nom .. " est la plus fragile : " .. liq .. " et " .. fin
    else s = e.nom .. " se situe entre les deux : " .. liq .. " et " .. fin end
    if #det > 0 then s = s .. " (" .. table.concat(det, ", ") .. ")" end
    local c = {}
    if e.nl and e.nl <= 1 then table.insert(c, "encaisser ses créances, vendre du stock ou obtenir un crédit pour payer ses dettes à court terme") end
    if e.nf == 0 then table.insert(c, "renforcer ses fonds propres ou réduire son endettement") end
    if e.r.liq1 and e.r.liq1 > 0.3 then table.insert(c, "placer ou investir son excédent de liquidités") end
    if #c > 0 then s = s .. " ; elle devrait " .. table.concat(c, " et ") end
    X(s .. ".")
  end
end

-- a) à partir des ratios déjà calculés : « Nom: liq1=0.82;liq2=0.95;… / Nom: … » (1 à 5 entreprises)
function F.comparerRatios(brut)
  local defaut = brut == nil or brut == F.defRatios()
  brut = brut or F.defRatios()
  local champs = {}
  for _, id in ipairs(CMP_IDS) do table.insert(champs, {cle = id}) end
  local ents = {}
  local i = 0
  for seg in brut:gmatch("[^/]+") do
    i = i + 1
    if i > 5 then break end
    local nom, reste = seg:match("^%s*([^:]+):(.*)$")
    if not nom then nom, reste = "E" .. i, seg end
    local v = COMMUN.lireChamps(reste, champs)
    local r = {}
    for _, id in ipairs(CMP_IDS) do r[id] = F.normR(id, v[id]) end
    table.insert(ents, {nom = (nom:gsub("%s+$", "")), r = r})
  end
  vider()
  T("Comparer " .. #ents .. " entreprise" .. (#ents > 1 and "s" or "") .. " (ratios)")
  F.cmpTableau(ents)   -- tableau comparatif en tête : tout le premier écran, détails dessous
  G("Méthode (modèle : test 2025 ex. 5 et 51.8) : tableau des ratios en décimal comme le corrigé du prof, puis, par entreprise et par question, une à deux phrases (constat chiffré, valeur indicative, hypothèse ou conséquence) et une comparaison. Barème 2025 : 3 pts de calculs, 6 pts de commentaires (liquidité, structure de financement).")
  if defaut then G("Par défaut : test 2025 ex. 5, ratios du corrigé du prof (Bouvier, Corgi, Husky) ; financement propre et couverture 1 calculés depuis les bilans de l'énoncé (non demandés en 2025).") end
  F.cmpRendu(ents)
  montrer("Comparer (ratios)")
end

-- b) à partir des bilans : « Nom: liquidités créances stocks AI CEct CElt FP [cap. croissance] / Nom: … » (1 à 5)
function F.comparer(brut)
  local defaut = brut == nil or brut == DEF_CMP
  brut = brut or DEF_CMP
  local vs = {}
  local i = 0
  for seg in brut:gmatch("[^/]+") do
    i = i + 1
    if i > 5 then break end
    local nom, reste = seg:match("^%s*([^:]+):(.*)$")
    if not nom then nom, reste = "E" .. i, seg end
    local t = {}
    for x in reste:gmatch("%S+") do table.insert(t, COMMUN.num(x)) end
    local v = F.deriver({liq = t[1], cre = t[2], sto = t[3], ai = t[4], ct = t[5], lt = t[6], fp = t[7], cc = t[8]})
    v.nom = (nom:gsub("%s+$", ""))
    table.insert(vs, v)
  end
  vider()
  T("Comparer " .. #vs .. " bilan" .. (#vs > 1 and "s" or ""))
  G("Méthode (modèle : test 2025 ex. 5 et 51.8) : pour chaque bilan, ratio = numérateur ÷ dénominateur, en décimal comme le corrigé du prof ; puis une à deux phrases par entreprise et par question (constat chiffré, norme, hypothèse ou conséquence) et une comparaison. Barème 2025 : 3 pts de calculs, 6 pts de commentaires.")
  if defaut then G("Par défaut : test 2025 ex. 5 (bilans de Bouvier, Corgi, Husky).") end
  -- rappel des bilans structurés
  local larg = math.max(4, math.floor(170 / math.max(#vs, 1) / 6))
  local ent = {""}
  for _, v in ipairs(vs) do table.insert(ent, F.tronquer(v.nom, larg)) end
  local function rang(lib, k, o)
    local l = {lib}
    for _, v in ipairs(vs) do l[#l + 1] = m(v[k]) end
    for kk, vv in pairs(o or {}) do l[kk] = vv end
    return l
  end
  for _, v in ipairs(vs) do if F.ok(v.ce, v.fp) then v.pas = v.ce + v.fp end end
  GRILLE("Bilans structurés", {
    rang("Liquidités", "liq", {retrait = 1}), rang("Créances", "cre", {retrait = 1}), rang("Stocks", "sto", {retrait = 1}),
    rang("Actifs circulants", "ac", {gras = true}), rang("Actifs immobilisés", "ai", {gras = true}),
    rang("Total de l'actif", "tot", {gras = true, trait = true, fond = true}),
    rang("CE à court terme", "ct", {retrait = 1}), rang("CE à long terme", "lt", {retrait = 1}),
    rang("Capitaux propres", "fp", {gras = true}), rang("Total du passif", "pas", {gras = true, trait = true, fond = true}),
  }, {entetes = ent})
  for _, v in ipairs(vs) do
    if F.ok(v.tot, v.pas) and math.abs(v.tot - v.pas) > 0.5 then A(v.nom .. " : bilan déséquilibré (actif " .. m(v.tot) .. " ≠ passif " .. m(v.pas) .. ").") end
  end
  -- calculs : formule (liste Profil M, en décimal) puis application
  T("Calcul des ratios")
  local ids = {"liq1", "liq2", "liq3", "iai", "end", "fp", "couv1", "couv2"}
  local ents = {}
  for _, id in ipairs(ids) do
    local d = RID[id]
    X(d.nom .. " = " .. d.formule:gsub(" × 100", ""))
    for _, v in ipairs(vs) do
      local nn, den, app = d.calc(v)
      if F.ok(nn, den) and den ~= 0 then
        R("  " .. v.nom .. " : ", "", app:gsub(" × 100", "") .. " = " .. d2(nn / den))
        v._r[id] = nn * 100 / den
      end
    end
  end
  local lf = {"FRN"}
  for _, v in ipairs(vs) do
    table.insert(ents, {nom = v.nom, r = {liq1 = v._r.liq1 and v._r.liq1 / 100, liq2 = v._r.liq2 and v._r.liq2 / 100,
      liq3 = v._r.liq3 and v._r.liq3 / 100, iai = v._r.iai and v._r.iai / 100, ["end"] = v._r["end"] and v._r["end"] / 100,
      fp = v._r.fp and v._r.fp / 100, couv1 = v._r.couv1 and v._r.couv1 / 100, couv2 = v._r.couv2 and v._r.couv2 / 100}})
    lf[#lf + 1] = F.ok(v.ac, v.ct) and m(v.ac - v.ct) or "—"
  end
  X("FRN = actifs circulants − CE à court terme")
  for _, v in ipairs(vs) do if F.ok(v.ac, v.ct) then R("  " .. v.nom .. " : ", "", m(v.ac) .. " − " .. m(v.ct) .. " = " .. m(v.ac - v.ct)) end end
  F.cmpTableau(ents, {lf}, 2)   -- inséré juste sous le titre (premier écran), les calculs restent dessous
  F.cmpRendu(ents)
  if defaut then G("Corrigé du prof (test 2025 ex. 5) : Bouvier 0.82 · 0.95 · 2.27 · 0.5 · 0.4 · 1.56 ; Corgi 0.26 · 0.97 · 1 · 0.62 · 0.58 · 1.00 ; Husky 0.17 · 0.75 · 1.27 · 0.24 · 0.82 · 1.67.") end
  montrer("Comparer des bilans")
end

-- questionnaire en trois temps : nombre d'entreprises, noms, puis chaque bilan ou chaque ratio
function F.qComparer(parRatios)
  local titre = parRatios and "Comparer (ratios)" or "Comparer (bilans)"
  COMMUN.questionnaire(titre, {{cle = "n", lib = "Nombre d'entreprises à comparer (1 à 5)", defaut = "3",
      aide = "Modèle : test 2025 ex. 5 (Bouvier, Corgi, Husky) et 51.8 (X, Y, Z). Les valeurs proposées ensuite sont celles du corrigé du prof.",
      valider = function(t) local x = COMMUN.num(t); if not x or x < 1 or x > 5 or x ~= math.floor(x) then return "Entrer un nombre entier de 1 à 5." end end}},
    function(v1)
      local n = v1.n
      local cn = {}
      for j = 1, n do
        table.insert(cn, {cle = "nom" .. j, lib = "Nom de l'entreprise " .. j, defaut = DEF_NOMS[j], texte = true,
          aide = "Nom court (8 caractères au plus) : il sert d'en-tête de colonne dans le tableau comparatif."})
      end
      COMMUN.questionnaire(titre, cn, function(v2)
        local noms = {}
        for j = 1, n do noms[j] = ((v2["nom" .. j] or ("E" .. j)):gsub("[/:;]", " ")) end
        local ch = {}
        for j = 1, n do
          if parRatios then
            for _, id in ipairs(CMP_IDS) do
              table.insert(ch, {cle = id .. "_" .. j, lib = noms[j] .. " — " .. RID[id].nom, defaut = DEF_RAT[j] and DEF_RAT[j][id] or "",
                aide = CMP_AIDE[id] .. FORMAT_R, opt = true})
            end
          else
            for q, k in ipairs(CMP_K) do
              table.insert(ch, {cle = k .. "_" .. j, lib = noms[j] .. " — " .. CAT[k], defaut = DEF_BIL[j] and DEF_BIL[j][q] or "",
                aide = AIDE[k], opt = k == "cc"})
            end
          end
        end
        COMMUN.questionnaire(titre, ch, function(v3)
          local seg = {}
          for j = 1, n do
            local t = {}
            if parRatios then
              for _, id in ipairs(CMP_IDS) do
                local s = v3._txt[id .. "_" .. j] or ""
                if s ~= "" then table.insert(t, id .. "=" .. s:gsub("%s", "")) end
              end
              table.insert(seg, noms[j] .. ": " .. table.concat(t, ";"))
            else
              for _, k in ipairs(CMP_K) do
                local s = (v3._txt[k .. "_" .. j] or ""):gsub("%s", "")
                table.insert(t, s ~= "" and s or "-")
              end
              table.insert(seg, noms[j] .. ": " .. table.concat(t, " "))
            end
          end
          if parRatios then F.comparerRatios(table.concat(seg, " / ")) else F.comparer(table.concat(seg, " / ")) end
        end)
      end)
    end)
end

------------------------------------------------------------------ 4. bilan analytique depuis une liste de postes (51.10, 51.11)
local DEF_LISTE = "Actionnaires=60000;Bénéfice de l'exercice=25000;Caisse=2600;Capital-actions=160000;Créances clients=24800;"
  .. "Dettes fournisseurs=46820;Mobilier=64800;Poste=28000;Emprunt bancaire à long terme=40980;Réserve issue du bénéfice=12000;"
  .. "Réserve issue du capital=10000;Véhicules=46000;Infra. informatique=68600;div=15000"
-- règles de classement : motif (minuscules sans accents), catégorie, signe ; la première qui correspond gagne
local REGLES = {
  {"ducroire", "cre", -1}, {"^fac", "ai", -1}, {"amort.*cumul", "ai", -1}, {"actionnaire", "cs", -1}, {"perte", "cc", -1},
  {"reserve.*capital", "cs", 1}, {"agio", "cs", 1}, {"capital", "cs", 1},
  {"reserve", "cc", 1}, {"benefice reporte", "cc", 1}, {"report", "cc", 1}, {"benefice", "bn", 1}, {"resultat", "bn", 1},
  {"dividende", "ct", 1}, {"fournisseur", "ct", 1}, {"creancier", "ct", 1}, {"passif.*regul", "ct", 1}, {"passifs? transitoire", "ct", 1},
  {"c/c passif", "ct", 1}, {"court terme", "ct", 1}, {"tva due", "ct", 1},
  {"emprunt", "lt", 1}, {"hypoth", "lt", 1}, {"pret", "lt", 1}, {"obligat", "lt", 1}, {"long terme", "lt", 1}, {"provision", "lt", 1},
  {"participation", "ai", 1}, {"liquidit", "liq", 1}, {"caisse", "liq", 1}, {"poste", "liq", 1}, {"banque", "liq", 1}, {"titre", "liq", 1},
  {"placement", "liq", 1},
  {"client", "cre", 1}, {"debiteur", "cre", 1}, {"creance", "cre", 1}, {"actif.*regul", "cre", 1}, {"actifs? transitoire", "cre", 1},
  {"impot prealable", "cre", 1}, {"tva", "cre", 1},
  {"stock", "sto", 1}, {"marchandise", "sto", 1}, {"matiere", "sto", 1}, {"produits? finis", "sto", 1}, {"en.cours", "sto", 1},
  {"mobilier", "ai", 1}, {"machine", "ai", 1}, {"vehicule", "ai", 1}, {"immeuble", "ai", 1}, {"immobil", "ai", 1}, {"terrain", "ai", 1},
  {"informatique", "ai", 1}, {"equipement", "ai", 1}, {"installation", "ai", 1}, {"brevet", "ai", 1}, {"licence", "ai", 1},
  {"outillage", "ai", 1}, {"agencement", "ai", 1}, {"goodwill", "ai", 1},
}
local ACC = {{"é", "e"}, {"è", "e"}, {"ê", "e"}, {"ë", "e"}, {"à", "a"}, {"â", "a"}, {"ô", "o"}, {"û", "u"}, {"ù", "u"}, {"î", "i"},
  {"ï", "i"}, {"ç", "c"}, {"É", "e"}, {"È", "e"}, {"À", "a"}, {"’", "'"}}
function F.cle(s)
  for _, p in ipairs(ACC) do s = s:gsub(p[1], p[2]) end   -- accents d'abord : lower() peut abîmer l'UTF-8 selon la locale
  return (s:gsub("%a", string.lower))
end
local CODES = {liq = true, cre = true, sto = true, ai = true, ct = true, lt = true, cs = true, cc = true, bn = true}
function F.classer(nom)
  local code, reste = nom:match("^%s*(%a+)%s*:%s*(.+)$")
  if code and CODES[code:lower()] then return code:lower(), 1, reste end
  local s = F.cle(nom):gsub("^%./%.%s*", "")
  for _, r in ipairs(REGLES) do if s:find(r[1]) then return r[2], r[3], nom end end
  return nil, 1, nom
end

function F.analytique(brut)
  brut = brut or DEF_LISTE
  local G_ = {liq = {}, cre = {}, sto = {}, ai = {}, ct = {}, lt = {}, cs = {}, cc = {}}
  local tot = {liq = 0, cre = 0, sto = 0, ai = 0, ct = 0, lt = 0, cs = 0, cc = 0}
  local inconnus, bn, div = {}, nil, nil
  for seg in brut:gmatch("[^;]+") do
    local nom, val = seg:match("^%s*(.-)%s*=%s*(.-)%s*$")
    local x = val and COMMUN.num(val)
    if nom and x then
      if F.cle(nom) == "div" or F.cle(nom):find("^dividende decide") then div = x
      else
        local cat, signe, lib = F.classer(nom)
        if nom:match("^%s*%./%.") then signe = -1 end
        if cat == "bn" then bn = (bn or 0) + x * signe
        elseif cat then
          local mt = math.abs(x) * signe
          if x < 0 then mt = x end
          table.insert(G_[cat], {(mt < 0 and "./. " or "") .. lib:gsub("^%s*%./%.%s*", ""), mt}); tot[cat] = tot[cat] + mt
        else table.insert(inconnus, nom) end
      end
    end
  end
  vider()
  T("Bilan analytique")
  G("Méthode (51 p.4, modèles 51.10 et 51.11) : 1) répartir le bénéfice AVANT de classer : dividende décidé → CE à court terme, solde → réserve issue du bénéfice (capital de croissance) ; 2) liquidités (caisse, poste, banque, titres de placement), créances (./. ducroire, actifs de régularisation), stocks ; AI (./. FAC, participations) ; CE ct (fournisseurs, dividende, passifs de régularisation) ; CE lt (emprunts, hypothèque, provisions à long terme) ; capital social (capital-actions ./. actionnaires + réserve issue du capital) ; capital de croissance (réserves issues du bénéfice, bénéfice reporté ./. perte reportée).")
  G("Saisie : nom=montant;… ; div=dividende décidé ; forcer une catégorie avec un code devant le nom : liq: cre: sto: ai: ct: lt: cs: cc: bn: (ex. « ct:Banque=500 »). Par défaut : Xénon SA (51.10).")
  if bn then
    if div then
      X("Répartition du bénéfice : dividende " .. m(div) .. " → CE à court terme ; solde " .. m(bn) .. " − " .. m(div) .. " = " .. m(bn - div) .. " → réserve issue du bénéfice.")
      table.insert(G_.ct, {"Dividende", div}); tot.ct = tot.ct + div
      table.insert(G_.cc, {"Attribution à la réserve", bn - div}); tot.cc = tot.cc + bn - div
    else
      G("Bénéfice de l'exercice sans répartition donnée : laissé dans le capital de croissance (préciser div=… si l'AG a décidé un dividende).")
      table.insert(G_.cc, {"Bénéfice de l'exercice", bn}); tot.cc = tot.cc + bn
    end
  elseif div then A("Dividende saisi mais pas de bénéfice de l'exercice : dividende ignoré.") end
  if #inconnus > 0 then A("Postes non classés (ajouter un code devant le nom) : " .. table.concat(inconnus, ", ")) end
  local v = F.deriver({liq = tot.liq, cre = tot.cre, sto = tot.sto, ai = tot.ai, ct = tot.ct, lt = tot.lt, fp = tot.cs + tot.cc, cc = tot.cc})
  local function bloc(l, cat, lib, ret)
    table.insert(l, {lib, "", m(tot[cat]), retrait = ret, gras = ret == 0})
    for _, it in ipairs(G_[cat]) do table.insert(l, {it[1], m(it[2]), "", retrait = ret + 1}) end
  end
  local la = {{"Actifs circulants", "", m(v.ac), gras = true, fond = true}}
  bloc(la, "liq", "Liquidités", 1); bloc(la, "cre", "Créances", 1); bloc(la, "sto", "Stocks", 1)
  table.insert(la, {"Actifs immobilisés", "", m(v.ai), gras = true, fond = true})
  for _, it in ipairs(G_.ai) do table.insert(la, {it[1], m(it[2]), "", retrait = 1}) end
  table.insert(la, {"Total de l'actif", "", m(v.tot), gras = true, trait = true})
  GRILLE("Actif", la, {entetes = {"", "Détail", "Total"}})
  local lp = {{"Capitaux étrangers", "", m(v.ce), gras = true, fond = true}}
  bloc(lp, "ct", "Dettes à court terme", 1); bloc(lp, "lt", "Dettes à long terme", 1)
  table.insert(lp, {"Capitaux propres", "", m(v.fp), gras = true, fond = true})
  bloc(lp, "cs", "Capital social", 1); bloc(lp, "cc", "Capital de croissance", 1)
  table.insert(lp, {"Total du passif", "", m(v.ce + v.fp), gras = true, trait = true})
  GRILLE("Passif", lp, {entetes = {"", "Détail", "Total"}})
  if math.abs(v.tot - v.ce - v.fp) > 0.5 then A("Actif " .. m(v.tot) .. " ≠ passif " .. m(v.ce + v.fp) .. " : vérifier la saisie et le classement.") end
  F.ratiosBilan(v)
  G("Corrigé 51.10 : AC 55'400, AI 179'400, CE ct 61'820, CE lt 40'980, CP 132'000 (capital social 110'000, croissance 22'000), total 234'800 ; ratios 49.50 % · 89.62 % · 23.59 % · 76.41 % · 43.78 % · 56.22 % · 16.67 % · 73.58 % · 96.42 %.")
  montrer("Bilan analytique")
end

------------------------------------------------------------------ 5. compte de résultat à degrés (51.19, 51.20)
local CH_CR = {
  {cle = "ven", lib = "Ventes", defaut = "2650", aide = "Ventes brutes de marchandises. CAB = ventes − retours des clients."}, {cle = "rcl", lib = "Retours des clients", defaut = "21", aide = "Retours des clients : diminuent les ventes (CAB = ventes − retours)."},
  {cle = "dac", lib = "Déductions accordées", defaut = "28", aide = "Déductions accordées (rabais, remises, escomptes accordés). CAN = CAB − déductions − pertes sur créances − frais directs de vente."}, {cle = "pcr", lib = "Pertes sur créances", defaut = "140", aide = "Pertes sur créances (clients insolvables) : diminuent le CAN (51 p.31)."},
  {cle = "fdv", lib = "Frais directs de vente", defaut = "200", aide = "Frais directs de vente (commissions sur cartes de crédit…) : diminuent le CAN."}, {cle = "ach", lib = "Achats", defaut = "1200", aide = "Achats de marchandises. PRAMA = achats − retours aux fournisseurs − déductions obtenues + frais d'achats."},
  {cle = "rfo", lib = "Retours aux fournisseurs", defaut = "14", aide = "Retours aux fournisseurs : diminuent les achats."}, {cle = "dob", lib = "Déductions obtenues", defaut = "15", aide = "Déductions obtenues (rabais, escomptes obtenus) : diminuent le PRAMA."},
  {cle = "fra", lib = "Frais d'achats", defaut = "274", aide = "Frais d'achats (transport, douane) : augmentent le PRAMA."}, {cle = "si", lib = "Stock initial", defaut = "10", aide = "Stock initial de marchandises (bilan d'ouverture)."},
  {cle = "sf", lib = "Stock final", defaut = "40", aide = "Stock final de marchandises (inventaire). PRAMV = PRAMA − augmentation de stock (+ diminution)."}, {cle = "sal", lib = "Salaires", defaut = "360", aide = "Salaires et charges sociales (charges de personnel)."},
  {cle = "ace", lib = "Autres charges d'exploitation", defaut = "140", aide = "Autres charges d'exploitation (loyer, énergie, publicité…). EBITDA = MB − personnel − autres charges."}, {cle = "amo", lib = "Amortissements", defaut = "60", aide = "Amortissements de l'exercice. EBIT = EBITDA − amortissements."},
  {cle = "chf", lib = "Charges financières", defaut = "3", aide = "Charges financières (intérêts payés). Bénéfice = EBIT − charges financières + produits financiers − impôts."}, {cle = "pf", lib = "Produits financiers", defaut = "2", aide = "Produits financiers (intérêts reçus) ; 0 s'il n'y en a pas."},
  {cle = "imp", lib = "Impôts", defaut = "0", aide = "Impôts directs ; 0 s'ils ne sont pas donnés."},
}
function F.cr(brut)
  local v = COMMUN.lireChamps(brut or "", CH_CR)
  for _, c in ipairs(CH_CR) do v[c.cle] = v[c.cle] or 0 end
  vider()
  T("Compte de résultat à degrés")
  G("Méthode (51 p.31-33, modèle 51.19) : calculs préliminaires CAB, CAN, PRAMA, variation de stock, PRAMV, puis le CR en liste : marge brute, EBITDA (avant amortissements), EBIT (avant charges et produits financiers et impôts), bénéfice net. Par défaut : 51.19 (en milliers de CHF).")
  T("Calculs préliminaires")
  local cab = v.ven - v.rcl
  COMMUN.calc("CAB", "Ventes − Retours des clients", m(v.ven) .. " − " .. m(v.rcl), m(cab))
  local can = cab - v.dac - v.pcr - v.fdv
  COMMUN.calc("CAN", "CAB − Déductions accordées − Pertes sur créances − Frais directs de vente", m(cab) .. " − " .. m(v.dac) .. " − " .. m(v.pcr) .. " − " .. m(v.fdv), m(can))
  local prama = v.ach - v.rfo - v.dob + v.fra
  COMMUN.calc("PRAMA", "Achats − Retours aux fournisseurs − Déductions obtenues + Frais d'achats", m(v.ach) .. " − " .. m(v.rfo) .. " − " .. m(v.dob) .. " + " .. m(v.fra), m(prama))
  local var = v.sf - v.si
  COMMUN.calc("Variation de stock", "Stock final − Stock initial", m(v.sf) .. " − " .. m(v.si), m(var) .. (var >= 0 and " (augmentation)" or " (diminution)"))
  local pramv = prama - var
  COMMUN.calc("PRAMV", "PRAMA − augmentation de stock (ou + diminution)", m(prama) .. (var >= 0 and " − " or " + ") .. m(math.abs(var)), m(pramv))
  local mb = can - pramv
  local ebitda = mb - v.sal - v.ace
  local ebit = ebitda - v.amo
  local bai = ebit - v.chf + v.pf
  local bn = bai - v.imp
  local l = {
    {"CAN", m(can)}, {"./. PRAMV", m(-pramv)}, {"Marge brute", m(mb), gras = true, trait = true},
    {"./. Salaires", m(-v.sal)}, {"./. Autres ch. d'exploit.", m(-v.ace)}, {"EBITDA", m(ebitda), gras = true, trait = true},
    {"./. Amortissements", m(-v.amo)}, {"EBIT", m(ebit), gras = true, trait = true},
    {"./. Charges financières", m(-v.chf)}, {"+ Produits financiers", m(v.pf)},
  }
  if v.imp ~= 0 then
    table.insert(l, {"Bénéfice avant impôts", m(bai), gras = true, trait = true})
    table.insert(l, {"./. Impôts", m(-v.imp)})
  end
  table.insert(l, {bn >= 0 and "Bénéfice net" or "Perte nette", m(bn), gras = true, trait = true, fond = true})
  GRILLE("Compte de résultat", l, {entetes = {"", "N"}})
  if can ~= 0 then
    T("Taux de marge")
    COMMUN.calc("Taux de marge brute", "Marge brute × 100 ÷ CAN", m(mb) .. " × 100 ÷ " .. m(can), p2(mb * 100 / can))
    COMMUN.calc("Taux de marge économique", "EBIT × 100 ÷ CAN", m(ebit) .. " × 100 ÷ " .. m(can), p2(ebit * 100 / can))
    COMMUN.calc("Taux de marge nette", "Bénéfice net × 100 ÷ CAN", m(bn) .. " × 100 ÷ " .. m(can), p2(bn * 100 / can))
  end
  G("Pièges : retours des clients → CAB ; pertes sur créances et frais directs de vente (commissions sur carte) diminuent le CAN ; une augmentation de stock diminue le PRAMV. Corrigé 51.19 : 2'629 · 2'261 · 1'445 · 30 · 1'415 · MB 846 · EBITDA 346 · EBIT 286 · BN 285.")
  memoriser(tostring(bn))
  montrer("CR à degrés")
end

------------------------------------------------------------------ 6. chiffres clés sur plusieurs années (51.21, 51.22, 51.23)
local DEF_CLES = "an=1 2 3 4;ca=2356000 2458000 2625000 2825000;mb=942400 1007780 997500 1186500;ebit=122400 177780 87500 246500;"
  .. "bn=24400 89780 15500 166500;eff=6 6 8 8;m2=220 220 220 220"
function F.cles(brut)
  brut = brut or DEF_CLES
  local d = {}
  for seg in brut:gmatch("[^;]+") do
    local k, val = seg:match("^%s*(%w+)%s*=%s*(.-)%s*$")
    if k then
      d[k] = {}
      for x in val:gmatch("%S+") do table.insert(d[k], k == "an" and x or COMMUN.num(x)) end
    end
  end
  local ca = d.ca or {}
  local n = #ca
  local an = d.an or {}
  for i = 1, n do an[i] = an[i] or ("A" .. i) end
  vider()
  T("Chiffres clés du compte de résultat")
  G("Méthode (51 p.35-37, modèles 51.21 et 51.23) : évolution du CA = (CA − CA précédent) × 100 ÷ CA précédent (base = année précédente) ; taux de marge = marge × 100 ÷ CAN ; CA par employé ; CA au m². Le prof arrondit au % dans le tableau (51.21).")
  G("Saisie : an=… ; ca=… ; mb=… ; ebit=… ; bn=… ; eff=… ; m2=… (valeurs séparées par des espaces). Par défaut : Medica SA (51.21).")
  local ent = {""}
  for i = 1, n do ent[#ent + 1] = an[i] end
  local function rang(lib, f, form)
    local l = {lib}
    for i = 1, n do local r = f(i); l[#l + 1] = r and form(r) or "—" end
    return l
  end
  local pc0 = function(r) return string.format("%.0f %%", r) end
  local function taux(k) return function(i) local x = d[k] and d[k][i]; return x and ca[i] and ca[i] ~= 0 and x * 100 / ca[i] or nil end end
  local evol = function(i) return i > 1 and ca[i - 1] and ca[i - 1] ~= 0 and (ca[i] - ca[i - 1]) * 100 / ca[i - 1] or nil end
  local par = function(k) return function(i) local x = d[k] and d[k][i]; return x and x ~= 0 and ca[i] / x or nil end end
  local l0 = {rang("Évol. CA", evol, pc0), rang("TMB", taux("mb"), pc0), rang("TME", taux("ebit"), pc0),
    rang("TMN", taux("bn"), pc0), rang("CA/employé", par("eff"), function(r) return m(math.floor(r + 0.5)) end),
    rang("CA/m²", par("m2"), function(r) return m(math.floor(r + 0.5)) end)}
  local l = {}   -- lignes renseignées seulement
  for _, x in ipairs(l0) do local plein = false; for i = 2, #x do if x[i] ~= "—" then plein = true end end; if plein then table.insert(l, x) end end
  -- tableau en tête (juste sous le titre) : tout le premier écran, calculs et commentaire dessous
  GRILLE("", l, {entetes = ent, compact = true, pos = 2,
    legende = "Évol. CA = évolution du CA par rapport à l'année précédente · TMB, TME, TMN = taux de marge brute, économique (EBIT), nette · CA/employé = CAN ÷ effectif · CA/m² = CAN ÷ surface de vente."})
  T("Calculs")
  X("Évolution du CA = (CA − CA précédent) × 100 ÷ CA précédent")
  for i = 2, n do X(string.format("  %s : (%s − %s) × 100 ÷ %s = %s", an[i], m(ca[i]), m(ca[i - 1]), m(ca[i - 1]), p2(evol(i)))) end
  for _, t in ipairs({{"mb", "Taux de marge brute = Marge brute × 100 ÷ CAN"}, {"ebit", "Taux de marge économique = EBIT × 100 ÷ CAN"},
      {"bn", "Taux de marge nette = Bénéfice net × 100 ÷ CAN"}}) do
    if d[t[1]] then
      X(t[2])
      for i = 1, n do X(string.format("  %s : %s × 100 ÷ %s = %s", an[i], m(d[t[1]][i]), m(ca[i]), p2(taux(t[1])(i)))) end
    end
  end
  for _, t in ipairs({{"eff", "CA par employé = CAN ÷ effectif"}, {"m2", "CA au m² = CAN ÷ surface de vente"}}) do
    if d[t[1]] then
      X(t[2])
      for i = 1, n do X(string.format("  %s : %s ÷ %s = %s", an[i], m(ca[i]), m(d[t[1]][i]), m(par(t[1])(i)))) end
    end
  end
  if n >= 2 and d.mb and d.ebit then
    local a, b = n - 1, n
    local tb0, tb1 = taux("mb")(a), taux("mb")(b)
    local te0, te1 = taux("ebit")(a), taux("ebit")(b)
    if F.ok(tb0, tb1, te0, te1) then
      T("Commentaire (" .. an[a] .. " → " .. an[b] .. ")")
      local s = string.format("Le taux de marge brute %s de %.2f points (ou %.2f %%) ; le taux de marge économique %s de %.2f points.",
        tb1 < tb0 and "a diminué" or "a augmenté", math.abs(tb1 - tb0), math.abs((tb1 - tb0) * 100 / tb0),
        te1 < te0 and "a diminué" or "a augmenté", math.abs(te1 - te0))
      if tb1 < tb0 and te1 > te0 then
        s = s .. " L'entreprise a bien contrôlé ses charges fixes, mais elle a dû soit diminuer son prix de vente, soit subir une hausse des charges de marchandises sans pouvoir la répercuter sur le prix de vente (modèle 51.23)."
      elseif tb1 > tb0 and te1 < te0 then
        s = s .. " La marge sur les marchandises s'améliore, mais les charges d'exploitation (personnel, loyers, amortissements) augmentent plus vite : à surveiller."
      elseif tb1 < tb0 then
        s = s .. " Les deux taux baissent : prix de vente sous pression ou coût des marchandises en hausse, sans compensation par les charges fixes."
      else s = s .. " Les deux taux progressent : meilleure rentabilité de l'exploitation." end
      X(s)
    end
  end
  G("Corrigé 51.21 : évolution 4 % · 7 % · 8 % ; marge brute 40 % · 41 % · 38 % · 42 % ; économique 5 % · 7 % · 3 % · 9 % ; nette 1 % · 4 % · 1 % · 6 % ; CA/employé 392'667 · 409'667 · 328'125 · 353'125 ; CA/m² 10'709 · 11'173 · 11'932 · 12'841.")
  montrer("Chiffres clés")
end

------------------------------------------------------------------ 7. rotations et durées (51.24)
local CH_ROT = {"cac", "cre", "cre1", "pramv", "sto", "sto1", "prama", "frs", "frs1", "dcl", "dfo"}
local EX_ROT = {cac = 6134.2, cre = 1216.8, cre1 = 1149.1, pramv = 5356.4, sto = 228.5, sto1 = 261.3, frs = 1737.1, frs1 = 1979.6}
function F.rotations(brut)
  local v = F.deriver(COMMUN.lireChamps(brut or "", F.champs(CH_ROT, EX_ROT)))
  vider()
  T("Rotations et durées")
  G("Méthode (51 p.40-43, modèle 51.24) : moyenne = (N-1 + N) ÷ 2 ; rotation = flux ÷ moyenne ; durée = 360 ÷ rotation. Flux : CA à crédit (sinon CAN) pour les clients, PRAMA pour les fournisseurs, PRAMV pour les stocks. Le prof divise 360 par la rotation arrondie à 2 décimales (360 ÷ 5.19 = 69.36).")
  G("Par défaut : coopérative A 2014 (51.24 : 21.87 fois, 16.46 j ; 5.19 fois, 69.36 j ; 2.86 fois, 125.87 j). Le prof prend les fonds étrangers à c.t. comme dettes fournisseurs.")
  for _, s in ipairs(v._auto) do X(s) end
  T("Stocks")
  F.aff(RID.rotsto, v); F.aff(RID.dursto, v)
  T("Clients (crédits accordés)")
  F.aff(RID.rotcli, v); F.aff(RID.durcli, v)
  T("Fournisseurs (crédits obtenus)")
  F.aff(RID.rotfrs, v); F.aff(RID.durfrs, v)
  local a, b, c = v._r.dursto, v._r.durcli, v._r.durfrs
  if F.ok(a, b, c) then
    T("Cycle des liquidités (hors test)")
    COMMUN.calc("Cycle", "Durée des stocks + Durée des crédits accordés − Durée des crédits obtenus", d2(a) .. " + " .. d2(b) .. " − " .. d2(c), d2(a + b - c) .. " jours")
    X("Commentaire : " .. (a + b - c > 0 and "nombre de jours pendant lesquels l'entreprise doit financer elle-même son exploitation (besoin en fonds de roulement) ; plus il est court, moins il faut de liquidités."
      or "cycle négatif : les fournisseurs sont payés après l'encaissement des clients ; ce sont eux qui financent l'exploitation (cas du commerce de détail)."))
    G("Cycle des liquidités : 51.16-51.18, retiré du programme du 12.11.")
  end
  montrer("Rotations et durées")
end

------------------------------------------------------------------ 8. ROI, ROE, décomposition et effet de levier (51.25, 51.27)
local CH_REN = {"bn", "chf", "pf", "imp", "ebit", "tot", "tot1", "fp", "fp1", "can"}
local EX_REN = {bn = 117881, chf = 6480, pf = 0, imp = 0, tot = 1828321, tot1 = 1513362, fp = 1289789, fp1 = 1226908, can = 8432560}
function F.rentab(brut)
  local v = F.deriver(COMMUN.lireChamps(brut or "", F.champs(CH_REN, EX_REN)))
  vider()
  T("Rentabilités ROI et ROE")
  G("Méthode (51 p.41-42 imprimées, modèle 51.25) : EBIT = BN + charges financières (− produits financiers + impôts) ; ROI = EBIT × 100 ÷ total moyen des bilans ; ROE = BN × 100 ÷ capitaux propres moyens ; moyennes = (N-1 + N) ÷ 2. Par défaut : Colibri SA (EBIT 124'361 ; 7.44 % ; 9.37 %).")
  T("a) EBIT")
  if v.bn then
    local l = {{"Bénéfice net", m(v.bn)}}
    if (v.imp or 0) ~= 0 then table.insert(l, {"+ Impôts", m(v.imp)}) end
    table.insert(l, {"+ Charges financières", m(v.chf or 0)})
    if (v.pf or 0) ~= 0 then table.insert(l, {"./. Produits financiers", m(-v.pf)}) end
    table.insert(l, {"EBIT", m(v.ebit), gras = true, trait = true})
    GRILLE("EBIT", l, {entetes = {"", "N"}})
  end
  T("b) Rentabilité des capitaux investis")
  F.aff(RID.roi, v)
  T("c) Rentabilité des fonds propres")
  F.aff(RID.roe, v)
  if v.can then
    T("d) Décomposition du ROI (hors test)")
    local tme = F.aff(RID.tme, v, true)
    local rot = F.aff(RID.rota, v, true)
    if F.ok(tme, rot) then
      R(string.format("ROI = %.4f %% × %.5f = %s", tme, rot, p2(tme * rot)), "", "")
      X("Commentaire : " .. (rot >= 3 and "un niveau de rotation de l'actif assez élevé explique dans une large mesure le ROI ; le taux de marge EBIT est plutôt faible (51.27)."
        or (rot < 1.5 and "c'est grâce au taux de marge EBIT que l'entreprise obtient son ROI ; la rotation de l'actif est faible (51.28)."
        or "marge EBIT et rotation de l'actif contribuent toutes deux au ROI.")))
    end
  end
  if v.chf and F.ok(v.tot, v.fp) then
    T("e) Effet de levier (hors test)")
    F.aff(RID.levier, v)
  end
  G("Décomposition et effet de levier : 51.26-51.33, hors périmètre du test du 12.11 (chap. 51 évalué jusqu'à la p.65).")
  montrer("ROI, ROE")
end

------------------------------------------------------------------ 9. FRN seul
local CH_FRN = {"ac", "ct", "fp", "lt", "ai"}
function F.frnSeul(brut)
  local v = F.deriver(COMMUN.lireChamps(brut or "", F.champs(CH_FRN, EX.T25)))
  vider()
  T("Fonds de roulement net")
  G("Méthode (51 p.12) : deux calculs qui doivent donner le même résultat ; FRN positif = situation favorable. Comme la liquidité 3, il mesure la capacité à payer les dettes à court terme, mais en valeur absolue. Par défaut : test 2025 ex. 3 (2026). Absent de la liste des ratios.")
  F.frn(v)
  if F.ok(v.ac, v.ct) and v.ct ~= 0 then G("Lien : FRN > 0 ⇔ liquidité 3 > 100 % (ici " .. p2(v.ac * 100 / v.ct) .. ").") end
  montrer("FRN")
end

------------------------------------------------------------------ 10. vrai / faux (51.15 et pièges du chapitre)
local VF = {
  {"Un ratio d'intensité de l'actif immobilisé élevé implique des charges fixes importantes.", "V", "", "51.15"},
  {"En additionnant les taux de financement par fonds propres et par fonds étrangers, on obtient 100 %.", "V", "", "51.15"},
  {"Les banques exigent un degré de liquidité 1 de 40 % au minimum.", "F", "Un degré de liquidité 1 élevé ne donne pas beaucoup d'informations ; ce n'est pas un ratio intéressant pour une demande de crédit (valeur indicative 20 à 30 %).", "51.15"},
  {"Un degré de liquidité 2 de 100 % est considéré comme satisfaisant.", "V", "", "51.15"},
  {"Si le degré de liquidité 3 est supérieur à 100 %, le degré de couverture 1 l'est également.", "F", "Valable pour le degré de couverture 2 (FRN positif ⇔ liquidité 3 > 100 % ⇔ couverture 2 > 100 %).", "51.15"},
  {"Un faible degré d'autofinancement indique toujours une capacité bénéficiaire insuffisante.", "F", "L'entreprise peut faire de gros bénéfices mais les distribuer ; le ratio dépend aussi de l'âge de l'entreprise et de la politique de dividendes.", "51.15"},
  {"Les réserves issues du capital (agio) font partie du capital de croissance.", "F", "Elles font partie du capital social ; le capital de croissance = réserves issues du bénéfice + bénéfice reporté.", "51 p.10"},
  {"Le dividende décidé par l'AG reste dans les capitaux propres du bilan analytique.", "F", "Il devient une dette à court terme (bilan après répartition du bénéfice).", "51.10"},
  {"Le compte Actionnaires (capital non libéré) se déduit du capital-actions.", "V", "", "51.10"},
  {"Les titres de placement rapidement réalisables sont classés dans les liquidités.", "V", "Les participations, elles, sont des actifs immobilisés.", "51.11"},
  {"Le FRN peut se calculer par AC − CE ct ou par CP + CE lt − AI.", "V", "", "51 p.12"},
  {"La durée moyenne des crédits obtenus se calcule avec le PRAMV.", "F", "Avec le PRAMA (achats) ; le PRAMV sert à la rotation des stocks.", "51 p.42-43"},
  {"Si l'on ne connaît pas le CA à crédit, on prend le CAN total pour la rotation des clients.", "V", "", "51 p.41"},
  {"Le ROI se calcule avec le bénéfice net.", "F", "Avec l'EBIT (avant intérêts et impôts) ; le ROE utilise le bénéfice net.", "Liste des ratios"},
  {"Un degré de couverture 2 inférieur à 100 % signifie que la règle d'or n'est pas respectée.", "V", "", "51 p.13"},
  {"L'effet de levier est positif lorsque le ROI dépasse le taux d'intérêt moyen des dettes (hors test).", "V", "", "51.27"},
}
function F.vraiFaux()
  vider()
  T("Vrai / faux sur les ratios")
  G("Méthode (51.15) : répondre V ou F ; justifier par une brève explication si F. Réponses du prof (51.15) puis pièges tirés du chapitre.")
  for i, q in ipairs(VF) do
    X(i .. ". " .. q[1])
    R((q[2] == "V" and "Vrai" or "Faux") .. (q[3] ~= "" and (" — " .. q[3]) or ""), "", "")
    G(q[4])
  end
  montrer("Vrai / faux")
end

------------------------------------------------------------------ ratios un par un
function F.unRatio(id, brut)
  local d = RID[id]
  local ex = EX[d.ex]
  local v = F.deriver(COMMUN.lireChamps(brut or "", F.champs(d.champs, ex)))
  vider()
  T(d.nom)
  G("Formule (liste Profil M) : " .. d.nom .. " = " .. d.formule .. ". Par défaut : " .. ex.nom .. ".")
  F.aff(d, v)
  if d.src then G(d.src) end
  montrer(d.nom)
end
function F.menuRatios()
  local it = {}
  for _, d in ipairs(RAT) do
    local dd = d
    table.insert(it, {dd.nom, function()
      COMMUN.questionnaire(dd.nom, F.champs(dd.champs, EX[dd.ex]), function(_, brut) F.unRatio(dd.id, brut) end)
    end})
  end
  MENU = {titre = "Ratios un par un (26)", items = it}; sel = 1; ecran = "menu"; inval()
end

------------------------------------------------------------------ questionnaires guidés (bilan analytique, chiffres clés)
local AIDE_LISTE = "Format nom=montant (ex. Caisse=2600 ; déduction : ./.Ducroire=1200). Classement d'après le nom : caisse, poste, banque, titres → liquidités ; clients, ducroire → créances ; stock ; mobilier, machines, véhicules → AI ; fournisseurs → CE ct ; emprunt, hypothèque → CE lt ; capital, réserves, bénéfice. Forcer : ct:Banque=500."
function F.validerPoste(t)
  if t == "" then return nil end
  local nom, val = t:match("^(.-)=(.*)$")
  if not nom or nom:gsub("%s", "") == "" or COMMUN.num(val) == nil then return "Format attendu : nom=montant (ex. Caisse=2600)." end
end
function F.qAnalytique()
  local ch, div = {}, nil
  for seg in DEF_LISTE:gmatch("[^;]+") do
    local val = seg:match("^div=(.*)$")
    if val then div = val
    else table.insert(ch, {cle = "p" .. (#ch + 1), lib = "Poste " .. (#ch + 1) .. " du bilan (nom=montant)", defaut = seg, texte = true, aide = AIDE_LISTE, valider = F.validerPoste}) end
  end
  for _ = 1, 4 do
    table.insert(ch, {cle = "p" .. (#ch + 1), lib = "Poste " .. (#ch + 1) .. " du bilan (nom=montant)", defaut = "", texte = true, opt = true,
      aide = "Poste supplémentaire (vide = aucun). " .. AIDE_LISTE, valider = F.validerPoste})
  end
  table.insert(ch, {cle = "div", lib = "Dividende décidé par l'AG", defaut = div or "", opt = true,
    aide = "Le bénéfice de l'exercice est réparti AVANT de classer : dividende → CE à court terme, solde → réserve issue du bénéfice (capital de croissance) (51.10). Vide = bénéfice laissé dans le capital de croissance."})
  COMMUN.questionnaire("Bilan analytique", ch, function(_, _, rep)
    local t = {}
    for k, c in ipairs(ch) do
      if rep[k] ~= "" then table.insert(t, c.cle == "div" and ("div=" .. rep[k]) or rep[k]) end
    end
    F.analytique(table.concat(t, ";"))
  end)
end

local AIDE_CLES = {
  an = {"Années (séparées par des espaces)", "Ex. 1 2 3 4 ou 2023 2024 2025. Les questions suivantes demandent une valeur par année, dans le même ordre, séparées par des espaces."},
  ca = {"CA net de chaque année", "CA net = ventes − déductions accordées − pertes sur créances − frais directs de vente. Une valeur par année."},
  mb = {"Marge brute de chaque année", "Marge brute = CAN − PRAMV. Vide = taux de marge brute non calculé."},
  ebit = {"EBIT de chaque année", "EBIT = bénéfice net + impôts + charges financières − produits financiers. Vide = ignoré."},
  bn = {"Bénéfice net de chaque année", "Dernière ligne du compte de résultat. Vide = ignoré."},
  eff = {"Effectif (employés) de chaque année", "Sert au CA par employé = CAN ÷ effectif. Vide = ignoré."},
  m2 = {"Surface de vente (m²) de chaque année", "Sert au CA au m² = CAN ÷ surface. Vide = ignoré."},
}
function F.qCles()
  local ch = {}
  for seg in DEF_CLES:gmatch("[^;]+") do
    local k, val = seg:match("^%s*(%w+)%s*=%s*(.-)%s*$")
    if k and AIDE_CLES[k] then
      table.insert(ch, {cle = k, lib = AIDE_CLES[k][1], defaut = val, texte = true, aide = AIDE_CLES[k][2], opt = k ~= "an" and k ~= "ca",
        valider = k ~= "an" and function(t)
          for x in t:gmatch("%S+") do if COMMUN.num(x) == nil then return "« " .. x .. " » n'est pas un nombre : une valeur par année, séparées par des espaces." end end
        end or nil})
    end
  end
  COMMUN.questionnaire("Chiffres clés", ch, function(_, _, rep)
    local t = {}
    for k, c in ipairs(ch) do if rep[k] ~= "" then table.insert(t, c.cle .. "=" .. rep[k]) end end
    F.cles(table.concat(t, ";"))
  end)
end

------------------------------------------------------------------ exposition et menu
SOLVEURS.analyse = F.analyse
SOLVEURS.bilan = F.bilan
SOLVEURS.comparer = F.comparer
SOLVEURS.comparerRatios = F.comparerRatios
SOLVEURS.analytique = F.analytique
SOLVEURS.crDegres = F.cr
SOLVEURS.chiffresCles = F.cles
SOLVEURS.rotations = F.rotations
SOLVEURS.rentab = F.rentab
SOLVEURS.frn = F.frnSeul
SOLVEURS.vraiFaux = F.vraiFaux
SOLVEURS.ratio = F.unRatio

-- chaque entrée pose les questions une par une (COMMUN.questionnaire), puis appelle le solveur avec « cle=valeur;… »
local function quest(titre, champs, f) return function() COMMUN.questionnaire(titre, champs, function(_, brut) f(brut) end) end end
table.insert(MENUS_COMPTA, {ordre = 51, titre = "Analyse de bilan et résultat (51)", items = {
  {"Analyse complète, 26 ratios", quest("Analyse complète", F.champs(CH_ANA, EX_ANA), F.analyse)},
  {"Ratios du bilan, 1 année", quest("Bilan (test 2025 ex. 3)", F.champs(CH_BIL, EX.T25), F.bilan)},
  {"Comparer 1 à 5 bilans", function() F.qComparer(false) end},
  {"Comparer X entreprises (ratios)", function() F.qComparer(true) end},
  {"Bilan analytique (liste)", F.qAnalytique},
  {"CR à degrés (balance)", quest("CR à degrés (51.19)", CH_CR, F.cr)},
  {"Chiffres clés (années)", F.qCles},
  {"Rotations et durées", quest("Rotations (51.24)", F.champs(CH_ROT, EX_ROT), F.rotations)},
  {"ROI, ROE (+ levier, hors test)", quest("ROI, ROE (51.25)", F.champs(CH_REN, EX_REN), F.rentab)},
  {"Fonds de roulement net", quest("FRN", F.champs(CH_FRN, EX.T25), F.frnSeul)},
  {"Ratios un par un (26)", F.menuRatios},
  {"Vrai / faux (51.15)", F.vraiFaux},
}})
end

-- ===== module 57_tresorerie.lua
-- 57_tresorerie.lua : flux de trésorerie (chap. 57) — tableau des liquidités, cash flow direct / indirect,
-- tableau des flux de trésorerie complet, effets des opérations, ratios de cash flow ;
-- hors cours : BFR et cycle de trésorerie, budget de trésorerie.
do
  local N = COMMUN.num

  local function r0(x, d)
    local m = 10 ^ (d or 0)
    if x >= 0 then return math.floor(x * m + 0.5) / m end
    return -math.floor(-x * m + 0.5) / m
  end
  local function F(x, d) return fmt(r0(x or 0, d or 0), d or 0) end
  -- montant signé à la manière du prof : +25 / −30
  local function S(x) if (x or 0) > 0 then return "+" .. F(x) end; return F(x) end
  local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
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
  local function champs(defaut, txt)
    local v = {}
    for _, p in ipairs(paires(defaut)) do v[p[1]] = N(p[2]) end
    for _, p in ipairs(paires(txt)) do v[p[1]] = N(p[2]) end
    return v
  end
  -- « N-1/N » -> a, b
  local function deux(s)
    if s == nil then return 0, 0 end
    local a, b = tostring(s):match("^(.-)/(.*)$")
    if not a then local x = N(s) or 0; return x, x end
    return N(a) or 0, N(b) or 0
  end
  local function ligneCalc(nom, formule, app, res)
    X(nom .. " = " .. formule)
    if app then X("   = " .. app) end
    R("   = " .. res, "", "")
  end

  ------------------------------------------------------------------ lecture d'un dossier de trésorerie
  -- fonds : « L Caisse=55/80 » (« L -Banque cc=… » : compte du passif déduit) ; autres clés : montants ou paires N-1/N
  local function lireDossier(src)
    local d = {fonds = {}, v = {}, p = {}}
    for _, pr in ipairs(paires(src)) do
      local k, val = pr[1], pr[2]
      local nom = k:match("^L%s+(.+)$")
      if nom then
        local neg = nom:sub(1, 1) == "-"
        if neg then nom = trim(nom:sub(2)) end
        local a, b = deux(val)
        table.insert(d.fonds, {nom = nom, a = a, b = b, neg = neg})
      else
        d.v[k] = N(val)
        local a, b = deux(val)
        d.p[k] = {a, b}
      end
    end
    return d
  end
  local function val(d, k) return d.v[k] or 0 end
  local function delta(d, k) local p = d.p[k]; if not p then return 0 end; return p[2] - p[1] end

  local function tableauLiquidites(d)
    local l, ta, tb = {}, 0, 0
    for _, f in ipairs(d.fonds) do
      local s = f.neg and -1 or 1
      ta = ta + s * f.a; tb = tb + s * f.b
      table.insert(l, {(f.neg and "./. " or "") .. f.nom, F(s * f.a), F(s * f.b), S(s * (f.b - f.a))})
    end
    table.insert(l, {"Liquidités (total)", F(ta), F(tb), S(tb - ta), gras = true, trait = true})
    GRILLE("Tableau des liquidités", l, {entetes = {"Fonds", "N-1", "N", "Variation"}})
    return ta, tb
  end

  -- bénéfice net recalculé depuis le compte de résultat saisi
  local function beneficeNet(d)
    return val(d, "ven") + val(d, "pf") + val(d, "pvc") - val(d, "ach") - val(d, "sal") - val(d, "loy") - val(d, "ace") -
      val(d, "aut") - val(d, "cf") - val(d, "amo") - val(d, "nm") - val(d, "pc")
  end

  -- secteur exploitation, méthode directe : lignes {libellé, montant}
  local function exploitationDirecte(d)
    local l = {}
    local function aj(lib, x) if x and x ~= 0 then table.insert(l, {lib, x}) end end
    aj("Encaissements clients", val(d, "ven"))
    local dc = delta(d, "cre"); aj(dc > 0 and "./. Augm. créances" or "+ Dim. créances", -dc)
    local dr = delta(d, "ara"); aj(dr > 0 and "./. Augm. prod. à recevoir" or "+ Dim. prod. à recevoir", -dr)
    aj("./. Pertes s/créances", -val(d, "pc"))
    aj("+ Produits financiers", val(d, "pf"))
    aj("./. Fournisseurs (achats)", -val(d, "ach"))
    local ds = delta(d, "sto"); aj(ds > 0 and "./. Augm. stock" or "+ Dim. stock", -ds)
    local df = delta(d, "dfo"); aj(df > 0 and "+ Augm. dettes fourn." or "./. Dim. dettes fourn.", df)
    aj("./. Salaires", -val(d, "sal"))
    aj("./. Loyers", -val(d, "loy"))
    aj("./. ACE", -val(d, "ace"))
    aj("./. Autres charges", -val(d, "aut"))
    aj("./. Charges financières", -val(d, "cf"))
    local dp = delta(d, "pre"); aj(dp > 0 and "+ Augm. charges à payer" or "./. Dim. charges à payer", dp)
    local t = 0
    for _, x in ipairs(l) do t = t + x[2] end
    return l, t
  end

  local function exploitationIndirecte(d, bn)
    local l = {{"Bénéfice net", bn}}
    local function aj(lib, x) if x and x ~= 0 then table.insert(l, {lib, x}) end end
    aj("+ Amortissements", val(d, "amo"))
    aj("+ Provisions (sans effet)", val(d, "nm"))
    aj("./. Bén. s/cession d'AI", -val(d, "pvc"))
    local dc = delta(d, "cre"); aj(dc > 0 and "./. Augm. créances" or "+ Dim. créances", -dc)
    local dr = delta(d, "ara"); aj(dr > 0 and "./. Augm. prod. à recevoir" or "+ Dim. prod. à recevoir", -dr)
    local ds = delta(d, "sto"); aj(ds > 0 and "./. Augm. stock" or "+ Dim. stock", -ds)
    local df = delta(d, "dfo"); aj(df > 0 and "+ Augm. dettes fourn." or "./. Dim. dettes fourn.", df)
    local dp = delta(d, "pre"); aj(dp > 0 and "+ Augm. charges à payer" or "./. Dim. charges à payer", dp)
    local t = 0
    for _, x in ipairs(l) do t = t + x[2] end
    return l, t
  end

  local function grilleSecteur(titre, lignes, total, libTotal, out)
    table.insert(out, {titre, "", "", fond = true, gras = true})
    for _, x in ipairs(lignes) do table.insert(out, {x[1], F(x[2]), "", retrait = 1}) end
    table.insert(out, {libTotal, "", F(total), gras = true, trait = true})
  end

  local function controleBN(d, bn)
    if d.v.bn and math.abs(d.v.bn - bn) > 0.5 then
      A("Bénéfice recalculé " .. F(bn) .. " ≠ bénéfice saisi " .. F(d.v.bn) .. " : un poste du compte de résultat manque.")
    end
  end

  ------------------------------------------------------------------ 1. tableau des liquidités (D1)
  local DEF_LIQ = "Caisse=55/80;Poste=130/100"

  SOLVEURS.tresoLiq = function(txt)
    local src = source(txt, DEF_LIQ)
    local d = {fonds = {}}
    for _, pr in ipairs(paires(src)) do
      local nom = pr[1]:match("^L%s+(.+)$") or pr[1]
      local neg = nom:sub(1, 1) == "-"
      if neg then nom = trim(nom:sub(2)) end
      local a, b = deux(pr[2])
      table.insert(d.fonds, {nom = nom, a = a, b = b, neg = neg})
    end
    vider()
    T("Tableau des liquidités")
    G("Méthode : on liste les comptes du fonds (définition de l'énoncé) en N-1 et N ; variation = N − (N-1) ; un compte " ..
      "du passif inclus dans le fonds (banque c/c) se déduit. Les titres n'y entrent que s'ils sont des réserves de " ..
      "liquidités (57 p.4-8 ; modèle : test 2026-02 ex. 2 a, 3 pts ; 57.2, 57.3).")
    local ta, tb = tableauLiquidites(d)
    ligneCalc("Variation du fonds", "liquidités N − liquidités N-1", F(tb) .. " − " .. F(ta), S(tb - ta))
    G("Saisie : Nom=N-1/N ; préfixe « - » pour un compte du passif déduit (ex. -Banque cc=1600/1200).")
    montrer("Liquidités")
  end

  ------------------------------------------------------------------ 2. cash flow direct / indirect (D2)
  local DEF_CF = "ven=96100;sal=54000;ace=2600;aut=20200;amo=9000;pc=200;cre=0/3700;pre=0/8600;bn=10100"

  SOLVEURS.tresoCF = function(txt)
    local d = lireDossier(source(txt, DEF_CF))
    local bn = beneficeNet(d)
    vider()
    T("Cash flow : méthodes directe et indirecte")
    G("Méthode directe : encaissements − décaissements liés à l'exploitation (produits et charges corrigés des variations " ..
      "de créances, stocks, dettes). Méthode indirecte : bénéfice net + charges sans effet monétaire (amortissements, " ..
      "provisions) − produits sans effet monétaire ± variations du fonds de roulement. Les deux donnent le même cash flow " ..
      "(57 p.9-13 ; modèle : 57.4, 57.7, 57.12).")
    controleBN(d, bn)
    local ld, td = exploitationDirecte(d)
    local li, ti = exploitationIndirecte(d, bn)
    local g = {}
    grilleSecteur("Méthode directe", ld, td, "Cash flow", g)
    GRILLE("Exploitation (directe)", g, {entetes = {"", "Détail", "Total"}})
    g = {}
    grilleSecteur("Méthode indirecte", li, ti, "Cash flow", g)
    GRILLE("Exploitation (indirecte)", g, {entetes = {"", "Détail", "Total"}})
    if math.abs(td - ti) > 0.5 then A("Les deux méthodes divergent (" .. F(td) .. " / " .. F(ti) .. ") : vérifier les données.")
    else R("Cash flow = " .. F(td), "", "") end
    G("Clés : ven, ach (PRAMV), sal, loy, ace, aut, cf, pf, amo, nm (provisions), pvc (bén. s/cession), pc (pertes s/créances), bn (contrôle) ; " ..
      "paires N-1/N : cre, sto, ara (produits à recevoir), dfo (dettes fourn.), pre (charges à payer). Défaut : 57.7 (cash flow 24'000).")
    montrer("Cash flow")
  end

  ------------------------------------------------------------------ 3. tableau des flux de trésorerie complet (D3)
  local DEF_TFT = "L Caisse=55/80;L Poste=130/100;ven=1500;ach=700;sal=300;loy=150;ace=50;cf=10;amo=90;" ..
    "imo=800/850;dlt=400/260;cap=505/570;div=80;bn=200"

  SOLVEURS.tresoTFT = function(txt)
    local d = lireDossier(source(txt, DEF_TFT))
    local bn = beneficeNet(d)
    vider()
    T("Tableau des flux de trésorerie")
    G("Méthode : a) tableau des liquidités ; b) cash flow (indirecte) ; c) TFT en 3 secteurs : exploitation (directe) → cash flow ; " ..
      "investissement = variation des immobilisations nettes + amortissements + valeur comptable cédée ; financement = " ..
      "variation des dettes financières et du capital − dividende de N-1 payé. Contrôle : somme des flux = variation du fonds " ..
      "(57 p.9-22 ; modèle : test 2026-02 ex. 2, 16 pts ; 57.12, 57.17).")
    controleBN(d, bn)
    T("a) Tableau des liquidités")
    local ta, tb = tableauLiquidites(d)
    T("b) Cash flow (méthode indirecte)")
    local li, ti = exploitationIndirecte(d, bn)
    local g = {}
    for _, x in ipairs(li) do table.insert(g, {x[1], F(x[2])}) end
    table.insert(g, {"Cash flow", F(ti), gras = true, trait = true})
    GRILLE("Cash flow (indirecte)", g, {entetes = {"", "Montant"}})
    T("c) TFT (méthode directe)")
    local ld, td = exploitationDirecte(d)
    -- investissement
    local pi = d.p.imo or {0, 0}
    local i1, i2 = pi[1], pi[2]
    local ces, pvc = val(d, "ces"), val(d, "pvc")
    local vnc = ces - pvc
    local invest = (i2 - i1) + val(d, "amo") + vnc
    ligneCalc("Investissements", "AI nets N − AI nets N-1 + amortissements + valeur comptable cédée",
      F(i2) .. " − " .. F(i1) .. " + " .. F(val(d, "amo")) .. " + " .. F(vnc), F(invest))
    local linv = {}
    if invest ~= 0 then table.insert(linv, {"./. Investissements AI", -invest}) end
    if ces ~= 0 then table.insert(linv, {"+ Désinvestissements AI", ces}) end
    local dfi = delta(d, "ifi")
    if dfi ~= 0 then table.insert(linv, {dfi > 0 and "./. Invest. financiers" or "+ Désinvest. financiers", -dfi}) end
    local tinv = 0
    for _, x in ipairs(linv) do tinv = tinv + x[2] end
    -- financement
    local lfin = {}
    local dd = delta(d, "dlt")
    if dd ~= 0 then table.insert(lfin, {dd > 0 and "+ Augm. dettes fin." or "./. Remboursement dettes", dd}) end
    local dk = delta(d, "cap")
    if dk ~= 0 then table.insert(lfin, {dk > 0 and "+ Augmentation capital" or "./. Réduction capital", dk}) end
    if val(d, "div") ~= 0 then table.insert(lfin, {"./. Dividende N-1 payé", -val(d, "div")}) end
    local tfin = 0
    for _, x in ipairs(lfin) do tfin = tfin + x[2] end
    g = {}
    grilleSecteur("Exploitation (directe)", ld, td, "Cash flow", g)
    grilleSecteur("Investissement", linv, tinv, "Flux investissement", g)
    grilleSecteur("Financement", lfin, tfin, "Flux financement", g)
    local tot = td + tinv + tfin
    table.insert(g, {"Variation du fonds", "", S(tot), gras = true, trait = true})
    table.insert(g, {"Liquidités au 1.1", F(ta), ""})
    table.insert(g, {"Liquidités au 31.12", F(tb), ""})
    table.insert(g, {"Variation des liquidités", "", S(tb - ta), gras = true, trait = true})
    GRILLE("Tableau des flux de trésorerie", g, {entetes = {"", "Détail", "Total"}})
    X("Contrôle : " .. F(td) .. " + (" .. F(tinv) .. ") + (" .. F(tfin) .. ") = " .. S(tot) .. " ; variation du fonds = " .. S(tb - ta))
    if math.abs(tot - (tb - ta)) > 0.5 then
      A("Écart de " .. F(tot - (tb - ta)) .. " entre le TFT et le tableau des liquidités : il manque une donnée (cession, dividende, variation de créances…).")
    else R("TFT équilibré : " .. S(tot), "", "") end
    if math.abs(td - ti) > 0.5 then A("Cash flow direct " .. F(td) .. " ≠ indirect " .. F(ti) .. ".") end
    G("Pièges : dividende payé = celui de N-1 (au bilan N-1) ; investissement = variation nette + amortissements ; " ..
      "vente d'AI : désinvestissement au prix de vente, bénéfice de cession retiré du cash flow (57.6, 57.17).")
    G("Clés : L Nom=N-1/N (fonds, « L -Nom » au passif) ; CR : ven ach sal loy ace aut cf pf amo nm pvc pc bn ; BFR N-1/N : cre sto ara dfo pre ; " ..
      "imo=AI nets N-1/N ; ces = prix de cession ; ifi = immob. financières N-1/N ; dlt = dettes financières N-1/N ; cap = capital N-1/N ; div.")
    montrer("TFT")
  end

  ------------------------------------------------------------------ 4. effets des opérations (D4)
  SOLVEURS.tresoEffets = function()
    vider()
    T("Effets sur le résultat et les liquidités")
    G("Règle : une opération touche le résultat si elle passe par une charge ou un produit ; les liquidités si elle passe par " ..
      "caisse, poste ou banque (57.1, 57.9, 57.10 ; + augmente, − diminue, 0 sans effet).")
    GRILLE("Opération", {
      {"Vente au comptant", "+", "+"},
      {"Vente à crédit", "+", "0"},
      {"Encaissement client", "0", "+"},
      {"Achat march. comptant", "−", "−"},
      {"Achat march. à crédit", "−", "0"},
      {"Paiement fournisseur", "0", "−"},
      {"Salaires, loyer payés", "−", "−"},
      {"Intérêts payés", "−", "−"},
      {"Amortissement (AI)", "−", "0"},
      {"Diminution du stock", "−", "0"},
      {"Provision litige", "−", "0"},
      {"Ducroire, risque fictif", "−", "0"},
      {"Ducroire, risque avéré", "−", "−"},
      {"Remboursement dette", "0", "−"},
      {"Nouvel emprunt", "0", "+"},
      {"Achat AI au comptant", "0", "−"},
      {"Virement poste → banque", "0", "0"},
      {"Augm. capital libérée", "0", "+"},
      {"Dividende payé", "0", "−"}}, {entetes = {"", "Résultat", "Liquid."}})
    G("Ducroire pour risque avéré : « − / − » dans les corrigés du prof (57.9, 57.10).")
    T("Effets sur les ratios de cash flow (57.27)")
    GRILLE("Opération", {
      {"Liquidités / Ventes", "+", "+", "−"},
      {"Machines / Autres dettes", "0", "−", "+"},
      {"Loyers / Liquidités", "−", "−", "+"},
      {"Achats / Liquidités", "−", "−", "+"},
      {"Amort. / Véhicules", "0", "0", "0"}}, {entetes = {"", "Marge CF", "Ratio inv.", "Fact. end."}})
    montrer("Effets")
  end

  ------------------------------------------------------------------ 5. ratios de cash flow, free cash flow (D5)
  local DEF_RAT = "cf=65;can=1800;bn=0;inv=0;ai1=210;ai2=196;amo=35;pcess=0;bcess=0;ce=98;liq=54;cre=83"

  SOLVEURS.tresoRatios = function(txt)
    local v = champs(DEF_RAT, txt)
    vider()
    T("Ratios de cash flow")
    G("Formules du manuel (57 p.62) ; modèle : 57.22, 57.25, 57.26. Défaut : 57.25 (Mecanica).")
    local inv = v.inv
    if (inv or 0) == 0 then
      inv = (v.ai2 - v.ai1) + v.amo + (v.pcess or 0) - (v.bcess or 0)
      ligneCalc("Investissements nets", "(AI N − AI N-1) + amortissements + pertes s/cession − bénéfices s/cession",
        "(" .. F(v.ai2) .. " − " .. F(v.ai1) .. ") + " .. F(v.amo) .. " + " .. F(v.pcess or 0) .. " − " .. F(v.bcess or 0), F(inv))
    end
    ligneCalc("Marge de cash flow", "cash flow × 100 ÷ CA net", F(v.cf) .. " × 100 ÷ " .. F(v.can), COMMUN.pct(v.cf / v.can))
    G("À comparer dans le temps (évolution d'une année à l'autre).")
    if (v.bn or 0) ~= 0 then
      ligneCalc("Indice opérationnel", "cash flow ÷ bénéfice", F(v.cf) .. " ÷ " .. F(v.bn), COMMUN.dec2(v.cf / v.bn))
    end
    if inv ~= 0 then
      local ri = v.cf / inv
      ligneCalc("Ratio d'investissement", "cash flow × 100 ÷ investissements nets", F(v.cf) .. " × 100 ÷ " .. F(inv), COMMUN.pct(ri))
      if ri >= 1 then
        G("Commentaire : l'entreprise finance l'intégralité de ses investissements avec son cash flow (" .. COMMUN.pct(ri) .. " ≥ 100 %).")
      else
        G("Commentaire : l'entreprise ne finance que " .. COMMUN.pct(ri) .. " de ses investissements avec son cash flow ; le reste " ..
          "vient de fonds externes ou des liquidités. Prendre en compte la tendance à long terme.")
      end
    end
    local ee = v.ce - v.liq - v.cre
    ligneCalc("Endettement effectif", "capitaux étrangers − liquidités (sens large) − créances", F(v.ce) .. " − " .. F(v.liq) .. " − " .. F(v.cre), F(ee))
    if ee <= 0 then
      G("Commentaire : l'endettement effectif est négatif (ou nul) : il n'y a pas lieu de calculer le facteur d'endettement (57.25).")
    elseif v.cf <= 0 then
      A("Cash flow négatif : facteur d'endettement non calculable, l'entreprise ne peut pas rembourser ses dettes par l'exploitation.")
    else
      local fe = ee / v.cf
      ligneCalc("Facteur d'endettement", "endettement effectif ÷ cash flow", F(ee) .. " ÷ " .. F(v.cf), string.format("%.1f", fe))
      local app = fe <= 3 and "très bon (1 à 3)" or (fe <= 5 and "acceptable (entre 3 et 5)" or "insuffisant (> 5)")
      G("Commentaire : facteur de " .. string.format("%.1f", fe) .. " → " .. app .. ". Il faudrait " .. string.format("%.1f", fe) ..
        " exercices à l'entreprise pour rembourser son endettement effectif avec le cash flow qu'elle dégage. Plus il est faible, " ..
        "plus la sécurité des prêteurs est grande.")
    end
    local fcf = v.cf - inv
    ligneCalc("Free cash flow", "cash flow − investissements nets", F(v.cf) .. " − " .. F(inv), F(fcf))
    if fcf >= 0 then
      G("Commentaire : avec un free cash flow de " .. F(fcf) .. ", l'entreprise dispose de fonds pour rembourser des dettes, " ..
        "distribuer un dividende exceptionnel ou accumuler des fonds pour un investissement futur.")
    else
      G("Commentaire : avec un free cash flow de " .. F(fcf) .. ", l'entreprise ne dispose d'aucune marge de manœuvre pour " ..
        "rembourser des dettes ou verser un dividende exceptionnel.")
    end
    montrer("Ratios de cash flow")
  end

  ------------------------------------------------------------------ 6. BFR et cycle de trésorerie (hors cours)
  local DEF_BFR = "sto=40000;pramv=360000;cre=60000;ca=600000;dfo=30000;ach=360000;j=360"

  SOLVEURS.tresoBFR = function(txt)
    local v = champs(DEF_BFR, txt)
    vider()
    T("BFR, cycle de trésorerie (hors cours)")
    A("Hors cours : proche du « cycle des liquidités » du chap. 51 (section 3.4, retirée du programme).")
    G("Méthode : durées en jours (année de " .. fmt(v.j) .. " jours, comme la liste des ratios Profil M) ; cycle = stockage + crédit clients − crédit fournisseurs ; " ..
      "BFR d'exploitation = stocks + créances − dettes fournisseurs. Exemple simple vérifiable à la main.")
    local ds = v.sto * v.j / v.pramv
    local dc = v.cre * v.j / v.ca
    local df = v.dfo * v.j / v.ach
    ligneCalc("Durée de stockage", "stock moyen × " .. fmt(v.j) .. " ÷ PRAMV", F(v.sto) .. " × " .. fmt(v.j) .. " ÷ " .. F(v.pramv), F(ds, 1) .. " jours")
    ligneCalc("Crédit clients", "créances × " .. fmt(v.j) .. " ÷ CA", F(v.cre) .. " × " .. fmt(v.j) .. " ÷ " .. F(v.ca), F(dc, 1) .. " jours")
    ligneCalc("Crédit fournisseurs", "dettes fourn. × " .. fmt(v.j) .. " ÷ achats", F(v.dfo) .. " × " .. fmt(v.j) .. " ÷ " .. F(v.ach), F(df, 1) .. " jours")
    local cyc = ds + dc - df
    ligneCalc("Cycle de trésorerie", "stockage + clients − fournisseurs", F(ds, 1) .. " + " .. F(dc, 1) .. " − " .. F(df, 1), F(cyc, 1) .. " jours")
    local bfr = v.sto + v.cre - v.dfo
    ligneCalc("BFR d'exploitation", "stocks + créances − dettes fournisseurs", F(v.sto) .. " + " .. F(v.cre) .. " − " .. F(v.dfo), F(bfr))
    G("Lecture : pendant " .. F(cyc, 0) .. " jours, l'entreprise doit financer elle-même son exploitation ; un BFR positif se finance par le fonds de roulement net ou par du crédit à court terme.")
    montrer("BFR (hors cours)")
  end

  ------------------------------------------------------------------ 7. budget de trésorerie (hors cours)
  local DEF_BUD = "si=20000;mois=Jan,Fév,Mar,Avr;enc=50000,45000,60000,70000;dec=55000,60000,52000,58000;min=10000"

  SOLVEURS.tresoBudget = function(txt)
    local src = source(txt, DEF_BUD)
    local si, mn, mois, enc, dec = 0, 0, {}, {}, {}
    for _, p in ipairs(paires(src)) do
      if p[1] == "si" then si = N(p[2]) or 0
      elseif p[1] == "min" then mn = N(p[2]) or 0
      elseif p[1] == "mois" then mois = lst(p[2])
      elseif p[1] == "enc" then for _, x in ipairs(lst(p[2])) do table.insert(enc, N(x) or 0) end
      elseif p[1] == "dec" then for _, x in ipairs(lst(p[2])) do table.insert(dec, N(x) or 0) end end
    end
    vider()
    T("Budget de trésorerie (hors cours)")
    A("Hors cours : outil de gestion, absent des chap. 37-59.")
    G("Méthode : solde final du mois = solde initial + encaissements − décaissements ; le solde final devient le solde initial " ..
      "du mois suivant ; un solde sous le minimum (" .. F(mn) .. ") signale un besoin de financement. Exemple simple vérifiable à la main.")
    local l, s, besoin = {}, si, 0
    local n = math.max(#enc, #dec)
    for i = 1, n do
      local e, d = enc[i] or 0, dec[i] or 0
      local fin = s + e - d
      table.insert(l, {(mois[i] or ("Mois " .. i)) .. " (SI " .. F(s) .. ")", F(e), F(-d), F(fin), fond = fin < mn})
      if fin < mn then besoin = math.max(besoin, mn - fin) end
      s = fin
    end
    GRILLE("Budget", l, {entetes = {"", "Encaiss.", "Décaiss.", "Solde fin"}})
    X("Solde final = solde initial + encaissements − décaissements (lignes surlignées : sous le minimum).")
    if besoin > 0 then A("Besoin de financement maximal : " .. F(besoin) .. " (pour rester au minimum de " .. F(mn) .. ").")
    else R("Trésorerie toujours ≥ minimum", "", "") end
    montrer("Budget (hors cours)")
  end

  ------------------------------------------------------------------ menu
  local function saisir(msg, defaut, nom)
    return function() demander(msg, function(t) SOLVEURS[nom](t) end, defaut) end
  end
  table.insert(MENUS_COMPTA, {ordre = 57, titre = "Trésorerie (57)", items = {
    {"Tableau des liquidités", saisir("Compte=N-1/N ; « -Compte » au passif (banque c/c)", DEF_LIQ, "tresoLiq")},
    {"Cash flow direct / indirect", saisir("CR : ven ach sal loy ace aut cf pf amo nm pvc pc ; N-1/N : cre sto ara dfo pre ; bn", DEF_CF, "tresoCF")},
    {"Tableau des flux complet", saisir("L Compte=N-1/N ; CR ; BFR N-1/N ; imo ces ifi dlt cap div", DEF_TFT, "tresoTFT")},
    {"Effets des opérations", function() SOLVEURS.tresoEffets() end},
    {"Ratios de cash flow, free cash flow", saisir("cf ; can ; bn ; inv (ou ai1 ai2 amo pcess bcess) ; ce liq cre", DEF_RAT, "tresoRatios")},
    {"BFR, cycle de trésorerie (hors cours)", saisir("sto pramv cre ca dfo ach ; j = jours", DEF_BFR, "tresoBFR")},
    {"Budget de trésorerie (hors cours)", saisir("si ; mois=… ; enc=… ; dec=… ; min", DEF_BUD, "tresoBudget")},
  }})
end

-- ===== module 59_couts.lua
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

-- ===== module 70_finance.lua
-- 70_finance.lua : calcul financier (hors cours) — intérêts simples et composés, escompte, emprunts (annuités constantes,
-- amortissement constant), VAN / TRI / délai de récupération, amortissements linéaire et dégressif, TVA, coefficients de prix.
-- Aucune source dans le cours (chap. 37, 44, 51, 57, 59) : exemples simples vérifiables à la main. Taux modifiables à la saisie.
do
  local N = COMMUN.num

  local function r0(x, d)
    local m = 10 ^ (d or 0)
    if x >= 0 then return math.floor(x * m + 0.5) / m end
    return -math.floor(-x * m + 0.5) / m
  end
  local function F(x, d) return fmt(r0(x or 0, d or 0), d or 0) end
  local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
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
    for x in (tostring(s or "") .. ","):gmatch("(.-),") do if trim(x) ~= "" then table.insert(t, N(trim(x)) or 0) end end
    return t
  end
  -- valeurs par défaut puis saisie ; les clés listées dans « listes » restent des listes de nombres
  local function champs(defaut, txt, listes)
    local brut = {}
    for _, p in ipairs(paires(defaut)) do brut[p[1]] = p[2] end
    for _, p in ipairs(paires(txt)) do brut[p[1]] = p[2] end
    local v = {}
    for k, s in pairs(brut) do
      if listes and listes[k] then v[k] = lst(s) else v[k] = N(s) end
    end
    return v
  end
  local function ligneCalc(nom, formule, app, res)
    X(nom .. " = " .. formule)
    if app then X("   = " .. app) end
    R("   = " .. res, "", "")
  end
  local P = COMMUN.pct
  local HC = "Hors cours : aucun chapitre de calcul financier dans le cours ; exemple simple vérifiable à la main."

  ------------------------------------------------------------------ 1. intérêts, escompte
  local DEF_INT = "c=10000;t=3%;j=90;n=5;m=12;esc=2%;de=10;dp=30"

  SOLVEURS.finInterets = function(txt)
    local v = champs(DEF_INT, txt)
    vider()
    T("Intérêts, escompte (hors cours)")
    A(HC)
    G("Usage suisse : année commerciale de 360 jours pour les intérêts simples.")
    T("Intérêts simples")
    local i = v.c * v.t * v.j / 360
    ligneCalc("Intérêt", "capital × taux × jours ÷ 360", F(v.c, 2) .. " × " .. P(v.t, 3) .. " × " .. fmt(v.j) .. " ÷ 360", F(i, 2))
    R("Capital final = " .. F(v.c + i, 2), "", "")
    T("Intérêts composés")
    local cn = v.c * (1 + v.t) ^ v.n
    ligneCalc("Capital après n ans", "C0 × (1 + t)^n", F(v.c, 2) .. " × (1 + " .. P(v.t, 3) .. ")^" .. fmt(v.n), F(cn, 2))
    X("Intérêts cumulés = " .. F(cn, 2) .. " − " .. F(v.c, 2) .. " = " .. F(cn - v.c, 2))
    local c0 = v.c / (1 + v.t) ^ v.n
    ligneCalc("Valeur actuelle de C", "C ÷ (1 + t)^n", F(v.c, 2) .. " ÷ (1 + " .. P(v.t, 3) .. ")^" .. fmt(v.n), F(c0, 2))
    T("Taux équivalent")
    local te = (1 + v.t) ^ (1 / v.m) - 1
    ligneCalc("Taux par période (m = " .. fmt(v.m) .. ")", "(1 + t)^(1/m) − 1", "(1 + " .. P(v.t, 3) .. ")^(1/" .. fmt(v.m) .. ") − 1", P(te, 4))
    G("Taux proportionnel (à ne pas confondre) : t ÷ m = " .. P(v.t / v.m, 4) .. ".")
    T("Coût d'un escompte non utilisé")
    local ce = v.esc / (1 - v.esc) * 360 / (v.dp - v.de)
    ligneCalc("Taux annuel", "esc ÷ (1 − esc) × 360 ÷ (délai de paiement − délai d'escompte)",
      P(v.esc) .. " ÷ " .. P(1 - v.esc) .. " × 360 ÷ (" .. fmt(v.dp) .. " − " .. fmt(v.de) .. ")", P(ce))
    G("Lecture : renoncer à l'escompte revient à emprunter à " .. P(ce) .. " par an ; s'il dépasse le taux d'un crédit bancaire, il vaut mieux payer dans le délai d'escompte.")
    montrer("Intérêts (hors cours)")
  end

  ------------------------------------------------------------------ 2. emprunt, plan de remboursement
  local DEF_EMP = "k=100000;t=5%;n=5;type=1"

  SOLVEURS.finEmprunt = function(txt)
    local v = champs(DEF_EMP, txt)
    local n = math.floor(v.n + 0.5)
    vider()
    T("Emprunt, plan de remboursement (hors cours)")
    A(HC)
    G("Méthode : chaque année, intérêt = solde dû en début d'année × taux ; annuité = intérêt + amortissement ; solde = solde − amortissement.")
    local a
    if v.type == 2 then
      a = v.k / n
      ligneCalc("Amortissement constant", "capital ÷ n", F(v.k, 2) .. " ÷ " .. fmt(n), F(a, 2))
    else
      a = v.k * v.t / (1 - (1 + v.t) ^ (-n))
      ligneCalc("Annuité constante", "K × t ÷ (1 − (1 + t)^−n)", F(v.k, 2) .. " × " .. P(v.t, 3) .. " ÷ (1 − (1 + " .. P(v.t, 3) .. ")^−" .. fmt(n) .. ")", F(a, 2))
    end
    local l, s, ti, ta, tn = {}, v.k, 0, 0, 0
    for an = 1, n do
      local int = s * v.t
      local am, ann
      if v.type == 2 then am = a; ann = am + int else ann = a; am = ann - int end
      if an == n then am = s; ann = am + int end
      s = s - am
      ti = ti + int; ta = ta + am; tn = tn + ann
      table.insert(l, {fmt(an) .. "  annuité " .. F(ann), F(int), F(am), F(s)})
    end
    table.insert(l, {"Total  " .. F(tn), F(ti), F(ta), "", gras = true, trait = true})
    GRILLE(v.type == 2 and "Amortissement constant" or "Annuités constantes", l, {entetes = {"Année", "Intérêt", "Amort.", "Solde"}})
    X("Coût total du crédit (somme des intérêts) = " .. F(ti, 2))
    G("type=1 : annuités constantes ; type=2 : amortissement constant (annuités décroissantes). Grille arrondie au franc.")
    montrer("Emprunt (hors cours)")
  end

  ------------------------------------------------------------------ 3. VAN, TRI, délai de récupération
  local DEF_INV = "i0=100000;cf=30000,35000,40000,30000,20000;t=8%"

  SOLVEURS.finInvest = function(txt)
    local v = champs(DEF_INV, txt, {cf = true})
    local cf = v.cf or {}
    vider()
    T("VAN, TRI, délai (hors cours)")
    A(HC)
    G("Méthode : flux actualisé = flux ÷ (1 + t)^année ; VAN = −investissement + somme des flux actualisés ; TRI = taux qui " ..
      "annule la VAN (recherche par dichotomie) ; délai = année où le cumul couvre l'investissement (interpolation linéaire). " ..
      "Valeur résiduelle : à ajouter au dernier flux.")
    local function van(t)
      local s = -v.i0
      for k, x in ipairs(cf) do s = s + x / (1 + t) ^ k end
      return s
    end
    local l, cum, cuma = {}, -v.i0, -v.i0
    local dS, dA
    table.insert(l, {"0", F(-v.i0), F(-v.i0), F(-v.i0)})
    for k, x in ipairs(cf) do
      local xa = x / (1 + v.t) ^ k
      local avant, avantA = cum, cuma
      cum = cum + x; cuma = cuma + xa
      if not dS and cum >= 0 then dS = (k - 1) + (-avant) / x end
      if not dA and cuma >= 0 then dA = (k - 1) + (-avantA) / xa end
      table.insert(l, {fmt(k), F(x), F(xa), F(cuma)})
    end
    GRILLE("Flux (taux " .. P(v.t) .. ")", l, {entetes = {"Année", "Flux", "Actualisé", "Cumul act."}})
    local vn = van(v.t)
    ligneCalc("VAN", "−I0 + Σ flux ÷ (1 + t)^k", "−" .. F(v.i0) .. " + " .. F(vn + v.i0), F(vn, 2))
    G(vn >= 0 and "VAN ≥ 0 : le projet rapporte plus que le taux exigé → acceptable." or "VAN < 0 : le projet ne couvre pas le taux exigé → à rejeter.")
    -- TRI par dichotomie
    local a, b = -0.99, 10
    local fa = van(a)
    if fa * van(b) > 0 then
      A("TRI introuvable entre −99 % et 1000 % (flux sans changement de signe).")
    else
      for _ = 1, 200 do
        local m = (a + b) / 2
        local fm = van(m)
        if fa * fm <= 0 then b = m else a = m; fa = fm end
      end
      local tri = (a + b) / 2
      X("TRI : on cherche t tel que VAN(t) = 0 ; par dichotomie (VAN décroît quand t augmente).")
      R("TRI = " .. P(tri, 2) .. " (VAN = " .. F(van(tri), 2) .. ")", "", "")
      G(tri >= v.t and ("TRI ≥ taux exigé (" .. P(v.t) .. ") → projet rentable.") or ("TRI < taux exigé (" .. P(v.t) .. ") → projet non rentable."))
    end
    if dS then X("Délai de récupération simple = " .. string.format("%.2f", dS) .. " ans (cumul des flux non actualisés)")
    else X("Délai de récupération simple : non atteint sur la durée.") end
    if dA then R("Délai actualisé = " .. string.format("%.2f", dA) .. " ans", "", "")
    else A("Délai actualisé : non atteint sur la durée (VAN négative).") end
    G("Saisie : cf = flux annuels séparés par des virgules (décimales avec un point).")
    montrer("Investissement (hors cours)")
  end

  ------------------------------------------------------------------ 4. amortissements linéaire et dégressif
  local DEF_AMO = "v=50000;n=5;vr=0;td=40%"

  SOLVEURS.finAmort = function(txt)
    local v = champs(DEF_AMO, txt)
    local n = math.floor(v.n + 0.5)
    vider()
    T("Plans d'amortissement (hors cours)")
    A(HC .. " Les taux fiscaux admis ne sont pas figés ici.")
    T("Linéaire (sur la valeur d'acquisition)")
    local al = (v.v - v.vr) / n
    ligneCalc("Amortissement annuel", "(valeur d'acquisition − valeur résiduelle) ÷ durée", "(" .. F(v.v) .. " − " .. F(v.vr) .. ") ÷ " .. fmt(n), F(al, 2))
    X("Taux linéaire = 1 ÷ durée = " .. P(1 / n))
    local l, vc = {}, v.v
    for an = 1, n do vc = vc - al; table.insert(l, {fmt(an), F(al), F(vc)}) end
    GRILLE("Linéaire", l, {entetes = {"Année", "Amort.", "VC fin"}})
    T("Dégressif (sur la valeur comptable)")
    X("Amortissement = valeur comptable en début d'année × " .. P(v.td) .. " (souvent le double du taux linéaire)")
    l, vc = {}, v.v
    local tot = 0
    for an = 1, n do
      local a = vc * v.td
      vc = vc - a; tot = tot + a
      table.insert(l, {fmt(an), F(a), F(vc)})
    end
    table.insert(l, {"Total", F(tot), "", gras = true, trait = true})
    GRILLE("Dégressif", l, {entetes = {"Année", "Amort.", "VC fin"}})
    G("Le dégressif n'atteint jamais zéro : la valeur comptable restante (" .. F(vc) .. ") s'amortit en dernière année ou reste au bilan.")
    montrer("Amortissements (hors cours)")
  end

  ------------------------------------------------------------------ 5. TVA
  local DEF_TVA = "t=8.1%;ht=1000;ttc=0;vht=200000;aht=120000;ti=8.1%"

  SOLVEURS.finTVA = function(txt)
    local v = champs(DEF_TVA, txt)
    vider()
    T("TVA (hors cours)")
    A(HC .. " Taux à saisir (défaut 8.1 %, taux normal suisse 2024 : à vérifier).")
    if (v.ttc or 0) ~= 0 then
      local ht = v.ttc / (1 + v.t)
      ligneCalc("Prix HT", "TTC ÷ (1 + taux)", F(v.ttc, 2) .. " ÷ " .. string.format("%.4f", 1 + v.t), F(ht, 2))
      ligneCalc("TVA", "TTC − HT  (= TTC × t ÷ (1 + t))", F(v.ttc, 2) .. " − " .. F(ht, 2), F(v.ttc - ht, 2))
    else
      local tva = v.ht * v.t
      ligneCalc("TVA", "HT × taux", F(v.ht, 2) .. " × " .. P(v.t), F(tva, 2))
      ligneCalc("Prix TTC", "HT + TVA = HT × (1 + taux)", F(v.ht, 2) .. " × " .. string.format("%.4f", 1 + v.t), F(v.ht + tva, 2))
    end
    T("Décompte de TVA")
    local due = v.vht * v.t
    local ip = v.aht * v.ti
    GRILLE("Décompte", {
      {"TVA due s/ventes", F(due, 2)},
      {"./. Impôt préalable", F(-ip, 2)},
      {due >= ip and "TVA à payer" or "Créance (à recevoir)", F(due - ip, 2), gras = true, trait = true}}, {entetes = {"", "CHF"}})
    X("TVA due = ventes HT × taux = " .. F(v.vht) .. " × " .. P(v.t) .. " ; impôt préalable = achats HT × taux = " .. F(v.aht) .. " × " .. P(v.ti))
    R("Solde = " .. F(due - ip, 2), "", "")
    G("Saisir ttc ≠ 0 pour partir d'un prix TTC (sinon ht).")
    montrer("TVA (hors cours)")
  end

  ------------------------------------------------------------------ 6. coefficients de prix, marge et marque
  local DEF_PRIX = "pa=80;pv=100;maj=0;mq=0;tva=8.1%"

  SOLVEURS.finPrix = function(txt)
    local v = champs(DEF_PRIX, txt)
    vider()
    T("Marge, marque, coefficients (hors cours)")
    A(HC)
    G("Majoration = marge en % du prix d'achat (coût) ; marque = marge en % du prix de vente (= « taux de marge brute en % du CAN » " ..
      "du chap. 44, p.3). Coefficient = prix de vente ÷ prix d'achat. Saisir pv, ou maj, ou mq (une seule des trois ≠ 0).")
    local pv = v.pv or 0
    if (v.maj or 0) ~= 0 then
      pv = v.pa * (1 + v.maj)
      ligneCalc("Prix de vente HT", "prix d'achat × (1 + majoration)", F(v.pa, 2) .. " × (1 + " .. P(v.maj) .. ")", F(pv, 2))
    elseif (v.mq or 0) ~= 0 then
      pv = v.pa / (1 - v.mq)
      ligneCalc("Prix de vente HT", "prix d'achat ÷ (1 − marque)", F(v.pa, 2) .. " ÷ (1 − " .. P(v.mq) .. ")", F(pv, 2))
    end
    local m = pv - v.pa
    ligneCalc("Marge", "prix de vente − prix d'achat", F(pv, 2) .. " − " .. F(v.pa, 2), F(m, 2))
    ligneCalc("Taux de majoration", "marge × 100 ÷ prix d'achat", F(m, 2) .. " × 100 ÷ " .. F(v.pa, 2), P(m / v.pa))
    ligneCalc("Taux de marque", "marge × 100 ÷ prix de vente", F(m, 2) .. " × 100 ÷ " .. F(pv, 2), P(m / pv))
    ligneCalc("Coefficient HT", "prix de vente ÷ prix d'achat", F(pv, 2) .. " ÷ " .. F(v.pa, 2), string.format("%.4f", pv / v.pa))
    local k = pv / v.pa * (1 + v.tva)
    ligneCalc("Coefficient TTC", "coefficient HT × (1 + TVA)", string.format("%.4f", pv / v.pa) .. " × " .. string.format("%.4f", 1 + v.tva), string.format("%.4f", r0(k, 4)))
    X("Prix TTC = " .. F(v.pa, 2) .. " × " .. string.format("%.4f", k) .. " = " .. F(v.pa * k, 2))
    G("Passages : marque = majoration ÷ (1 + majoration) ; majoration = marque ÷ (1 − marque).")
    montrer("Prix (hors cours)")
  end

  ------------------------------------------------------------------ menu
  local function saisir(msg, defaut, nom)
    return function() demander(msg, function(t) SOLVEURS[nom](t) end, defaut) end
  end
  table.insert(MENUS_COMPTA, {ordre = 70, titre = "Finance (hors cours)", items = {
    {"Intérêts, escompte", saisir("c capital ; t taux ; j jours ; n années ; m périodes ; esc ; de délai escompte ; dp délai paiement", DEF_INT, "finInterets")},
    {"Emprunt, plan de remboursement", saisir("k capital ; t taux ; n années ; type 1 annuités constantes / 2 amortissement constant", DEF_EMP, "finEmprunt")},
    {"VAN, TRI, délai de récupération", saisir("i0 investissement ; cf=flux,flux,… ; t taux d'actualisation", DEF_INV, "finInvest")},
    {"Amortissements linéaire, dégressif", saisir("v valeur d'acquisition ; n durée ; vr valeur résiduelle ; td taux dégressif", DEF_AMO, "finAmort")},
    {"TVA : HT/TTC, décompte", saisir("t taux ; ht ou ttc ; vht ventes HT ; aht achats HT ; ti taux impôt préalable", DEF_TVA, "finTVA")},
    {"Marge, marque, coefficients", saisir("pa prix d'achat ; pv ou maj (majoration) ou mq (marque) ; tva", DEF_PRIX, "finPrix")},
  }})
end

-- ===== module 99_menu.lua
-- 99_menu.lua : menu principal assemble a partir des modules (charge en dernier, avant le socle de fin)
menuPrincipal = function()
  table.sort(MENUS_COMPTA, function(a, b) return (a.ordre or 50) < (b.ordre or 50) end)
  local items = {}
  for _, m in ipairs(MENUS_COMPTA) do
    local sous = m
    table.insert(items, {sous.titre, function()
      MENU = {titre = sous.titre, items = sous.items}; sel = 1; ecran = "menu"; inval()
    end})
  end
  table.insert(items, {"Historique des résultats", historiqueResultats or function() end})
  MENU = {titre = TITRE_APP, items = items}
  sel = 1; ecran = "menu"; inval()
end

PILE_MENUS = {}
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


local function hauteurGrille(e)
  return 18 + 15 * #e.lignes + (e.opts.entetes and 15 or 0) + 4
end

local function dessinerGrille(gc, e, x0, y0, w)
  local y = y0
  gc:setColorRGB(30, 70, 160); gc:setFont("sansserif", "b", 10); gc:drawString(e.titre or "", x0 + 2, y, "top")
  y = y + 17
  local ncol = 0
  for _, l in ipairs(e.lignes) do ncol = math.max(ncol, #l - 1) end
  if e.opts.entetes then ncol = math.max(ncol, #e.opts.entetes - 1) end
  local wl = math.floor((w - 4) * (ncol >= 2 and 0.46 or 0.6))
  local wc = ncol > 0 and math.floor((w - 4 - wl) / ncol) or 0
  local function ligne_(l, entete)
    if l.fond then gc:setColorRGB(235, 240, 250); gc:fillRect(x0, y - 1, w - 2, 15) end
    gc:setColorRGB(0, 0, 0)
    gc:setFont("sansserif", (l.gras or entete) and "b" or "r", 9)
    local lib = tostring(l[1] or "")
    while gc:getStringWidth(lib) > wl - 4 and #lib > 3 do lib = lib:sub(1, -2) end
    gc:drawString(lib, x0 + 3 + (l.retrait or 0) * 8, y, "top")
    for j = 2, #l do
      local s = tostring(l[j] or "")
      local xr = x0 + wl + (j - 1) * wc - 3
      gc:drawString(s, xr - gc:getStringWidth(s), y, "top")
    end
    if l.trait then gc:setColorRGB(0, 0, 0); gc:drawLine(x0 + wl, y - 1, x0 + w - 3, y - 1) end
    y = y + 15
  end
  if e.opts.entetes then local h = {}; for i, v in ipairs(e.opts.entetes) do h[i] = v end; ligne_(h, true) end
  for _, l in ipairs(e.lignes) do ligne_(l, false) end
  gc:setColorRGB(150, 150, 150); gc:drawRect(x0, y0 + 16, w - 2, y - y0 - 16)
end

-- grille compacte (GRILLE(..., {compact = true})) : tout le tableau sur un ecran.
-- dispo = hauteur libre depuis le haut de la grille jusqu'au pied quand le document est en haut ;
-- si elle ne suffit pas, la grille se dimensionne pour un ecran entier (tableau suivant d'une serie).
local function texteC(s) return (tostring(s or ""):gsub(" %%", "%%"):gsub("−", "-")) end
local function couperC(gc, s, larg)
  while gc:getStringWidth(s) > larg and #s > 1 do
    s = s:sub(1, -2)
    while #s > 1 and s:byte(-1) >= 128 and s:byte(-1) < 192 do s = s:sub(1, -2) end   -- pas de demi-caractere UTF-8
    if #s > 0 and s:byte(-1) >= 192 then s = s:sub(1, -2) end
  end
  return s
end
local function mesureCompacte(gc, e, w, dispo)
  local rows = {}
  if e.opts.entetes then table.insert(rows, {c = e.opts.entetes, ent = true}) end
  for _, l in ipairs(e.lignes) do table.insert(rows, {c = l, l = l}) end
  local ncol = 0
  for _, r in ipairs(rows) do ncol = math.max(ncol, #r.c - 1) end
  local ht = (e.titre and e.titre ~= "") and 12 or 0
  local nr = math.max(#rows, 1)
  if not dispo or dispo < ht + nr * 9 + 2 then dispo = 212 - 36 - 2 end
  -- hauteur de ligne = hauteur reelle de la police (sinon les traits coupent le haut des chiffres) :
  -- plus grande police dont toutes les lignes tiennent dans la place libre
  local f0, rh
  for f = 9, 7, -1 do
    gc:setFont("sansserif", "r", f)
    rh = gc:getStringHeight("0Lg") + 1
    f0 = f
    if ht + nr * rh + 2 <= dispo then break end
  end
  local L
  for f = f0, 7, -1 do
    for avecEnt = 1, 0, -1 do       -- d'abord en-tetes entiers, sinon en-tetes tronques a la largeur des valeurs
      local wl, wc = 0, {}
      for j = 1, ncol do wc[j] = 0 end
      for _, r in ipairs(rows) do
        gc:setFont("sansserif", (r.ent or (r.l and r.l.gras)) and "b" or "r", f)
        wl = math.max(wl, gc:getStringWidth(texteC(r.c[1])) + 5 + (r.l and r.l.retrait or 0) * 6)
        if not r.ent or avecEnt == 1 then
          for j = 1, ncol do wc[j] = math.max(wc[j], gc:getStringWidth(texteC(r.c[j + 1])) + 5) end
        end
      end
      local tot = wl
      for j = 1, ncol do wc[j] = math.max(wc[j], 14); tot = tot + wc[j] end
      gc:setFont("sansserif", "r", f)
      local rhf = math.max(rh, gc:getStringHeight("0Lg") + 1)
      L = {f = f, rh = rhf, wl = wl, wc = wc, tot = tot, ht = ht, ncol = ncol, nr = #rows}
      if tot <= w - 2 then break end
    end
    if L.tot <= w - 2 then break end
  end
  L.deborde = L.tot > w - 2
  local reste = (w - 2) - L.tot
  if reste > 0 then          -- place en trop : un peu pour les libelles, le reste reparti entre les colonnes
    local pl = ncol > 0 and math.floor(reste * 0.25) or reste
    L.wl = L.wl + pl
    for j = 1, ncol do L.wc[j] = L.wc[j] + math.floor((reste - pl) / ncol) end
  elseif reste < 0 then L.wl = math.max(20, L.wl + reste) end   -- trop large : libelles tronques
  L.h = ht + L.nr * L.rh + 2
  e._L = L
  return L.h
end

local function dessinerCompacte(gc, e, x0, y0, w)
  local L = e._L
  local y = y0
  if L.ht > 0 then
    gc:setColorRGB(30, 70, 160); gc:setFont("sansserif", "b", 9); gc:drawString(e.titre, x0 + 2, y - 1, "top")
    y = y + L.ht
  end
  local ytab = y
  local dy = 0
  local function rang(c, l, ent)
    if ent then gc:setColorRGB(220, 230, 250); gc:fillRect(x0, y, w - 2, L.rh)
    elseif l.fond then gc:setColorRGB(235, 240, 250); gc:fillRect(x0, y, w - 2, L.rh) end
    gc:setColorRGB(0, 0, 0)
    gc:setFont("sansserif", (ent or l.gras) and "b" or "r", L.f)
    local ret = (l and l.retrait or 0) * 6
    gc:drawString(couperC(gc, texteC(c[1]), L.wl - 4 - ret), x0 + 2 + ret, y + dy, "top")
    local xr = x0 + L.wl
    for j = 1, L.ncol do
      xr = xr + L.wc[j]
      local s = couperC(gc, texteC(c[j + 1]), L.wc[j] - 3)
      gc:drawString(s, xr - 3 - gc:getStringWidth(s), y + dy, "top")
    end
    if l and l.trait then gc:setColorRGB(0, 0, 0); gc:drawLine(x0 + L.wl, y, x0 + w - 3, y) end
    y = y + L.rh
    gc:setColorRGB(225, 225, 225); gc:drawLine(x0, y, x0 + w - 3, y)
  end
  if e.opts.entetes then rang(e.opts.entetes, nil, true) end
  for _, l in ipairs(e.lignes) do rang(l, l, false) end
  gc:setColorRGB(150, 150, 150)
  gc:drawRect(x0, ytab, w - 2, y - ytab)
  gc:drawLine(x0 + L.wl, ytab, x0 + L.wl, y)
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

-- ecran de saisie : question (gras), aide coupee en lignes, erreur (rouge), note (gris), puis zone de saisie.
-- Si le texte ne tient pas, la police de l'aide passe de 9 a 8 ; au-dela, les dernieres lignes sont remplacees par « … ».
local function lignesSaisie(gc, w, taille)
  local blocs = {{saisie.msg or "", "b", 10, {0, 0, 0}}}
  if saisie.aide and saisie.aide ~= "" then table.insert(blocs, {saisie.aide, "r", taille, {0, 0, 0}}) end
  if saisie.erreur and saisie.erreur ~= "" then table.insert(blocs, {saisie.erreur, "b", taille, {200, 0, 0}}) end
  if saisie.note and saisie.note ~= "" then table.insert(blocs, {saisie.note, "i", taille, {100, 100, 100}}) end
  local out = {}
  for _, b in ipairs(blocs) do
    gc:setFont("sansserif", b[2], b[3])
    for par in (b[1] .. "\n"):gmatch("(.-)\n") do
      for _, l in ipairs(couper(gc, par, w - 12)) do
        table.insert(out, {s = l, st = b[2], t = b[3], c = b[4], dy = b[3] >= 10 and 14 or (b[3] == 9 and 12 or 11)})
      end
    end
  end
  local haut = 0
  for _, l in ipairs(out) do haut = haut + l.dy end
  return out, haut
end

local function dessinerSaisie(gc, w, h)
  bandeau(gc, w, saisie.titre or "Saisie")
  local dispo = h - 16 - 23 - 28            -- entre le bandeau et la zone de saisie (28 px) au-dessus du pied
  local lignes, haut = lignesSaisie(gc, w, 9)
  if haut > dispo then lignes, haut = lignesSaisie(gc, w, 8) end
  local y = 23
  saisie.deborde = haut > dispo
  for i, l in ipairs(lignes) do
    if y + l.dy > 23 + dispo then
      gc:setColorRGB(200, 0, 0); gc:setFont("sansserif", "b", 9); gc:drawString("…", w - 14, y - l.dy, "top")
      break
    end
    gc:setColorRGB(l.c[1], l.c[2], l.c[3]); gc:setFont("sansserif", l.st, l.t)
    gc:drawString(l.s, 6, y, "top")
    y = y + l.dy
  end
  local yb = y + 2
  gc:setColorRGB(245, 245, 255); gc:fillRect(4, yb, w - 8, 24)
  gc:setColorRGB(30, 70, 160); gc:drawRect(4, yb, w - 8, 24)
  gc:setColorRGB(0, 0, 0); gc:setFont("sansserif", "r", 11)
  gc:drawString(saisie.txt, 8, yb + 4, "top")
  local cx = 8 + gc:getStringWidth(saisie.txt:sub(1, saisie.cur))
  gc:drawLine(cx, yb + 3, cx, yb + 21)
  -- apercu 2D (seulement s'il reste de la place)
  if saisie.txt ~= "" and yb + 24 + 34 < h - 16 then
    local ok, b = pcall(function() return mise(gc, arbre(saisie.txt), 1) end)
    if ok and yb + 30 + b.asc + b.desc < h - 16 then gc:setColorRGB(0, 0, 0); b.draw(gc, 8, yb + 30 + b.asc) end
  end
  pied(gc, w, h, saisie.pied or "◄► curseur  ▲▼ historique  enter : ok  esc : annuler")
end

local function hauteurElt(gc, e, w, dispo)
  if e.k == "txt" or e.k == "gris" or e.k == "alerte" then
    gc:setFont("sansserif", e.k == "gris" and "i" or (e.k == "alerte" and "b" or "r"), e.petit and 8 or 10)
    e._l = couper(gc, e.s, w - 10)
    return 4 + (e.petit and 11 or 15) * #e._l
  end
  if e.k == "tab" then return hauteurTab(e) + 2 end
  if e.k == "grille" and e.compact then return mesureCompacte(gc, e, w - 2, dispo) + 2 end
  if e.k == "grille" then return hauteurGrille(e) + 2 end
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
    -- place libre sous l'element quand le document est en haut (independant du defilement) : grilles compactes
    local he = hauteurElt(gc, e, w, (h - 16) - (22 + total + 1))
    e._y, e._h = 22 + total + 1, he - 2   -- position dans le document en haut de vue (banc de test)
    if y + he > 20 and y < h - 16 then
      if e.k == "grille" and e.compact then dessinerCompacte(gc, e, 2, y + 1, w - 2)
      elseif e.k == "grille" then dessinerGrille(gc, e, 2, y + 1, w - 2)
      elseif e.k == "tab" then dessinerTab(gc, e, 2, y + 1, w - 2)
      elseif e.k == "graphe" then dessinerGraphe(gc, e, 2, y + 1, w - 2)
      elseif e.k == "courbes" then dessinerCourbes(gc, e, 2, y + 1, w - 2)
      elseif e.k == "titre" then
        gc:setColorRGB(220, 230, 250); gc:fillRect(0, y, w, he)
        gc:setColorRGB(BLEU[1], BLEU[2], BLEU[3]); gc:setFont("sansserif", "b", 11); gc:drawString(e.s, 4, y + 2, "top")
      elseif e.k == "txt" or e.k == "gris" or e.k == "alerte" then
        if e.k == "txt" then gc:setColorRGB(0, 0, 0); gc:setFont("sansserif", "r", 10)
        elseif e.k == "gris" then gc:setColorRGB(110, 110, 110); gc:setFont("sansserif", "i", 10)
        else gc:setColorRGB(200, 0, 0); gc:setFont("sansserif", "b", 10) end
        if e.petit then gc:setFont("sansserif", "i", 8) end
        for i, l in ipairs(e._l or {e.s}) do gc:drawString(l, 4, y + 2 + (e.petit and 11 or 15) * (i - 1), "top") end
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
    sel = tonumber(ch)
    local avant = MENU
    MENU.items[sel][2]()
    if MENU ~= avant then table.insert(PILE_MENUS, {menu = avant, sel = sel}) end
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
  if ecran == "menu" then
    local avant, s0 = MENU, sel
    MENU.items[sel][2]()
    if MENU ~= avant then table.insert(PILE_MENUS, {menu = avant, sel = s0}) end
  elseif ecran == "saisie" then
    local t = saisie.txt
    if t == "" and not saisie.vide then return end
    memoriser(t)
    local s = saisie.suite
    local ok, err = pcall(s, t)
    if not ok then vider(); T("Erreur"); A(tostring(err)); montrer("Erreur") end
  else menuPrincipal() end
end

function on.escapeKey()
  if ecran ~= "menu" or MENU.titre ~= TITRE_APP then
    local p = table.remove(PILE_MENUS)
    if p then MENU = p.menu; sel = p.sel; ecran = "menu"; inval() else menuPrincipal() end
  end
end

------------------------------------------------------------------ demarrage et sauvegarde
function on.construction() menuPrincipal() end
function on.resize() inval() end
function on.save() return {hist = HIST} end
function on.restore(t) if type(t) == "table" and t.hist then HIST = t.hist end end

API_TEST = {doc = function() return DOC end, hist = function() return HIST end,
  ecran = function() return ecran end, vue = function() return vue end, saisie = function() return saisie end, menu = function() return MENU, sel end,
  -- saisie simulee : txt = nil garde le texte pre-rempli (ENTER seul)
  entrer = function(txt) if txt then saisie.txt = txt; saisie.cur = #txt end; on.enterKey() end,
  choisir = function(i) sel = i; on.enterKey() end}

