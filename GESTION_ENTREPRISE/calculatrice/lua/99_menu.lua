-- 99_menu.lua : menu principal assemble a partir des modules (charge en dernier, avant le socle de fin)
-- + index de recherche : chaque entree de menu qui porte forts / mots devient une entree d'INDEX_SOLVEURS,
--   avec son chemin calcule ici (« 2·3·1 ») : l'index suit les menus quand ils changent.
table.sort(MENUS_COMPTA, function(a, b) return (a.ordre or 50) < (b.ordre or 50) end)
do
  local function decoupe(s)
    if type(s) ~= "string" then return s end
    local t = {}
    for m in s:gmatch("%S+") do t[#t + 1] = m end
    return t
  end
  local function indexer(items, chemin)
    for i, it in ipairs(items) do
      local ch = chemin .. "·" .. i
      if it.forts or it.mots then
        table.insert(INDEX_SOLVEURS, {titre = it[1], chemin = ch, forts = decoupe(it.forts) or {}, mots = decoupe(it.mots) or {},
          si = it.si, ouvrir = it[2]})
      end
      if it.sous then indexer(it.sous, ch) end
    end
  end
  for k, m in ipairs(MENUS_COMPTA) do indexer(m.items, tostring(k)) end
end

menuPrincipal = function()
  local items = {}
  for _, m in ipairs(MENUS_COMPTA) do
    local sous = m
    table.insert(items, {sous.titre, function()
      MENU = {titre = sous.titre, items = sous.items}; sel = 1; ecran = "menu"; inval()
    end})
  end
  table.insert(items, {"Historique des résultats", historiqueResultats or function() end})
  PILE_MENUS = {}
  MENU = {titre = TITRE_APP, items = items}
  sel = 1; ecran = "menu"; inval()
end
