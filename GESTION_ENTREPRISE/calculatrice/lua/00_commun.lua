-- 00_commun.lua : outils communs du classeur compta (charge en premier, apres le socle)
TITRE_APP = "Compta – solveur"
MENUS_COMPTA = {}   -- chaque module ajoute : table.insert(MENUS_COMPTA, {ordre = n, titre = "…", items = {{"libellé", fonction}, …}})
-- entrée indexée pour la recherche : {"libellé", fonction, forts = "mots forts", mots = "mots partagés", si = "à choisir si…"}
-- (99_menu en tire INDEX_SOLVEURS, voir CONVENTIONS-MODULES.md)
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

-- texte interne « clé=valeur;… » -> valeurs (arguments des solveurs dans les tests, et reconstruit par les questionnaires).
-- Plus de saisie sur une ligne pour l'utilisateur : une donnée = un champ (COMMUN.questionnaire / COMMUN.repeter).
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

-- questionnaire guide : une question par champ, pre-remplie avec la valeur par defaut.
-- champs : {{cle = "liq", lib = "Liquidités", defaut = "35+30", aide = "Liquidités = caisse + poste + banque …",
--            opt = true (vide = ignoré), texte = true (pas un nombre : nom…), valider = function(s) return msgErreur end}, …}
--   ou une fonction(val) -> liste de champs (questionnaire dynamique, voir COMMUN.repeter) : val[cle] = texte déjà saisi.
-- Touches : ENTER garde la valeur ; « < » (seul ou en fin de saisie) revient à la question précédente ;
-- « ! » valide tout le reste par défaut ; champ vide (ou « - ») = ignoré.
-- suite(v, brut, rep) : v = valeurs numériques (v._txt = textes saisis), brut = « cle=texte;… », rep = textes par rang
local NOTE_Q = "ENTER : garder · < : question précédente · ! : tout le reste par défaut · esc : annuler"
local function questionnaire(titre, champs, suite)
  local dyn = type(champs) == "function"
  local val = {}
  local liste = dyn and champs(val) or champs
  local function texte(c)
    local s = val[c.cle]
    if s == nil then s = c.defaut ~= nil and tostring(c.defaut) or "" end
    return s
  end
  local i, erreur = 1, nil
  local poser
  local function fin()
    local v, parts, rep = {_txt = {}}, {}, {}
    for k, c in ipairs(liste) do
      local s = texte(c)
      rep[k] = s
      v._txt[c.cle] = s
      if c.texte then v[c.cle] = s ~= "" and s or nil else v[c.cle] = num(s) end
      table.insert(parts, c.cle .. "=" .. s)
    end
    suite(v, table.concat(parts, ";"), rep)
  end
  local function noter(c, s)
    val[c.cle] = s
    if dyn then liste = champs(val) end
  end
  poser = function()
    local c = liste[i]
    local note = NOTE_Q .. ((c.opt or c.defaut == nil or c.defaut == "") and " · vide : ignoré" or "")
    demander(c.lib, function(txt)
      local t = tostring(txt or ""):gsub("^%s+", ""):gsub("%s+$", "")
      erreur = nil
      local cmd = t:sub(-1)
      if cmd == "<" then i = math.max(1, i - 1); return poser() end
      if cmd == "!" then
        local reste = t:sub(1, -2):gsub("%s+$", "")
        if reste ~= "" then noter(c, reste) end
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
      noter(c, t)
      i = i + 1
      if i > #liste then fin() else poser() end
    end, texte(c), {titre = titre .. "  " .. i .. "/" .. #liste, aide = c.aide, erreur = erreur, note = note, vide = true,
      pied = "enter : ok   < : précédente   ! : fin   esc : annuler"})
  end
  if #liste == 0 then fin() else poser() end
end

-- questionnaire « N éléments × champs » (une donnée = un champ) : segments = champs simples et groupes, dans l'ordre.
-- Groupe : {groupe = "Compte", n = {cle = "n", lib = "Combien de comptes ?", defaut = "4", max = 12, min = 1, aide = "…"},
--           champs = function(j, val) return {{cle = "nom", lib = "nom", defaut = "…", texte = true}, …} end}
--   (ou nombre = function(val) return n end à la place de n : nombre tiré des réponses précédentes, sans question ;
--    brut = true : libellés des champs gardés tels quels, sans « Compte 2/4 — »).
-- Chaque champ d'élément devient cle_j, posé « Compte 2/4 — nom » ; la question « Combien » se repose si on y revient avec <.
local function entier(s, def) local x = num(s); if not x then return def end; return math.floor(x + 0.5) end
local function repeter(segments)
  return function(val)
    local l = {}
    for _, s in ipairs(segments) do
      if s.groupe then
        local n
        if s.n then
          local q, mn, mx = s.n, s.n.min or 1, s.n.max or 12
          table.insert(l, {cle = q.cle, lib = q.lib, defaut = q.defaut, aide = q.aide, valider = function(t)
            local x = num(t)
            if not x or x ~= math.floor(x) or x < mn or x > mx then return "Entrer un nombre entier de " .. mn .. " à " .. mx .. "." end
          end})
          local brut = val[q.cle]; if brut == nil then brut = q.defaut end
          n = math.max(mn, math.min(mx, entier(brut, mn)))
        else n = s.nombre(val) end
        for j = 1, n do
          for _, c in ipairs(s.champs(j, val)) do
            local cc = {}
            for k, x in pairs(c) do cc[k] = x end
            cc.cle = c.cle .. "_" .. j
            cc.lib = s.brut and c.lib or (s.groupe .. " " .. (c.rang or (j .. "/" .. n)) .. " — " .. c.lib)
            table.insert(l, cc)
          end
        end
      else table.insert(l, s) end
    end
    return l
  end
end
-- lecture d'un questionnaire « repeter » : valeur saisie (ou défaut) d'une clé, et nombre d'éléments d'un groupe
local function lu(val, cle, defaut) local s = val[cle]; if s == nil then s = defaut end; return s end
-- éléments 1..n d'un groupe après le questionnaire : {{cle = texte saisi, …}, …} (v = 1er argument de suite)
local function elements(v, n, cles)
  local out = {}
  for j = 1, n or 0 do
    local e = {}
    for _, k in ipairs(cles) do e[k] = v._txt[k .. "_" .. j] or "" end
    out[j] = e
  end
  return out
end
-- « 2/3 » -> « (2/3) » : une valeur qui contient un séparateur de la ligne interne reste d'un seul tenant
local function bloc(s, seps)
  s = tostring(s or "")
  if s:find("[" .. (seps or "/;,") .. "]") then return "(" .. s .. ")" end
  return s
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

-- sous-menu : entrée {libellé, fonction, sous = items} ; 99_menu parcourt « sous » pour construire l'index de recherche
-- (chemins « 2·3·1 » toujours cohérents avec les menus). 9 entrées au plus par menu (un écran, touches 1-9).
local function sousMenu(lib, titre, items)
  return {lib, function() MENU = {titre = titre, items = items}; sel = 1; ecran = "menu"; inval() end, sous = items}
end

-- rend les helpers visibles aux modules suivants
COMMUN = {num = num, pct = pct, dec2 = dec2, montant = montant, estExpr = estExpr, exprTexte = exprTexte,
  lireChamps = lireChamps, questionnaire = questionnaire, repeter = repeter, lu = lu, entier = entier, elements = elements, bloc = bloc, calc = calc, commentaire = commentaire,
  sousMenu = sousMenu}
end
