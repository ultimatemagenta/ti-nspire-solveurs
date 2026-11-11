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
