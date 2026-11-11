"""Extrait le socle commun (interface Lua TI-Nspire) depuis MATH_1/calculatrice/lua/solveur.lua.

socle_debut.lua : CAS, rendu 2D, document de resultats, memoire, etat, helpers generiques.
socle_fin.lua   : dessins (tableaux, graphes, grilles comptables), menus, saisie, vue, touches, sauvegarde.
Une application = socle_debut + ses modules (qui definissent menuPrincipal) + socle_fin.
"""
from pathlib import Path
import sys

# Depuis le 11.11.2026, socle_debut.lua / socle_fin.lua sont modifies a la main (saisie multi-lignes de demander(),
# API_TEST etendue pour test_pc.py --menu) : regenerer depuis solveur.lua ecraserait ces changements.
if "--force" not in sys.argv:
    sys.exit("socle edite a la main depuis le 11.11.2026 : relancer avec --force seulement apres y avoir reporte ces changements")

RACINE = Path(__file__).resolve().parents[2]
SRC = RACINE / "MATH_1" / "calculatrice" / "lua" / "solveur.lua"
ICI = Path(__file__).resolve().parent

lignes = SRC.read_text(encoding="utf-8").split("\n")


def bloc(debut, fin):
    """Lignes [debut ; fin[ reperees par leur texte de debut de ligne."""
    i = next(k for k, l in enumerate(lignes) if l.startswith(debut))
    j = next(k for k, l in enumerate(lignes) if k > i and l.startswith(fin)) if fin else len(lignes)
    return lignes[i:j]


entete = ["-- socle commun des classeurs TI-Nspire (genere par tools/nspire/extraire_socle.py, ne pas editer a la main)",
          "platform.apiLevel = '2.4'"]
debut = bloc("------------------------------------------------------------------ CAS",
             "------------------------------------------------------------------ module ")
helpers = bloc("local function nombre(e)", "local function racines(p)")
debut_txt = "\n".join(entete + debut + ["------------------------------------------------------------------ helpers generiques"] + helpers)
debut_txt += """
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
"""
fin = bloc("------------------------------------------------------------------ dessin : tableau de signes et graphe", None)
fin_txt = "\n".join(fin)
fin_txt = fin_txt.replace('MENU.titre ~= "MATH_1 – solveur"', "MENU.titre ~= TITRE_APP")

# element "grille" (tableaux comptables)
grille = '''
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
'''
fin_txt = fin_txt.replace("------------------------------------------------------------------ dessin\nlocal BLEU", grille + "\n------------------------------------------------------------------ dessin\nlocal BLEU", 1)
fin_txt = fin_txt.replace('''  if e.k == "tab" then return hauteurTab(e) + 2 end''',
                          '''  if e.k == "tab" then return hauteurTab(e) + 2 end
  if e.k == "grille" then return hauteurGrille(e) + 2 end''', 1)
fin_txt = fin_txt.replace('''      if e.k == "tab" then dessinerTab(gc, e, 2, y + 1, w - 2)''',
                          '''      if e.k == "grille" then dessinerGrille(gc, e, 2, y + 1, w - 2)
      elseif e.k == "tab" then dessinerTab(gc, e, 2, y + 1, w - 2)''', 1)
# pile de menus : esc revient au menu precedent
fin_txt = fin_txt.replace('''  if ecran == "menu" then MENU.items[sel][2]()
  elseif ecran == "saisie" then''', '''  if ecran == "menu" then
    local avant, s0 = MENU, sel
    MENU.items[sel][2]()
    if MENU ~= avant then table.insert(PILE_MENUS, {menu = avant, sel = s0}) end
  elseif ecran == "saisie" then''', 1)
fin_txt = fin_txt.replace('''    sel = tonumber(ch); MENU.items[sel][2]()''', '''    sel = tonumber(ch)
    local avant = MENU
    MENU.items[sel][2]()
    if MENU ~= avant then table.insert(PILE_MENUS, {menu = avant, sel = sel}) end''', 1)
fin_txt = fin_txt.replace('''function on.escapeKey()
  if ecran == "menu" and MENU.titre ~= TITRE_APP then menuPrincipal()
  elseif ecran ~= "menu" then menuPrincipal() end
end''', '''function on.escapeKey()
  if ecran ~= "menu" or MENU.titre ~= TITRE_APP then
    local p = table.remove(PILE_MENUS)
    if p then MENU = p.menu; sel = p.sel; ecran = "menu"; inval() else menuPrincipal() end
  end
end''', 1)
fin_txt = "PILE_MENUS = {}" + chr(10) + fin_txt
fin_txt += '''
API_TEST = {doc = function() return DOC end, hist = function() return HIST end}
'''
(ICI / "socle_debut.lua").write_text(debut_txt + "\n", encoding="utf-8", newline="\n")
(ICI / "socle_fin.lua").write_text(fin_txt + "\n", encoding="utf-8", newline="\n")
print("socle_debut.lua :", debut_txt.count("\n"), "lignes ; socle_fin.lua :", fin_txt.count("\n"), "lignes")
for mot in ["grille", "TITRE_APP"]:
    print(mot, "dans fin :", mot in fin_txt)
