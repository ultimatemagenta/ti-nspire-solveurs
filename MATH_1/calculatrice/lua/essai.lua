-- essai.lua : test de faisabilite Lua + CAS sur TI-Nspire CX II (etape 0)
platform.apiLevel = '2.4'

local L = {}          -- lignes {texte, couleur, gras, taille}
local haut = 0
local saisie = "x^3+x^2-8*x-12"
local compteur = 0    -- teste on.save / on.restore
local rich = nil

local function ajoute(t, c, g, s) table.insert(L, {t, c or {0,0,0}, g, s or 11}) end

local function cas(expr)
  local ok, r, err = pcall(math.evalStr, expr)
  if not ok then return "ERREUR pcall: " .. tostring(r) end
  if r == nil then return "nil (" .. tostring(err) .. ")" end
  return r
end

local function calculer()
  L = {}
  ajoute("Essai Lua + CAS", {255,255,255}, true, 12)
  ajoute("1) Calcul formel (math.evalStr)", {30,70,160}, true)
  ajoute("factor(" .. saisie .. ") = " .. cas("factor(" .. saisie .. ")"), {0,120,0}, true)
  ajoute("zeros = " .. cas("zeros(" .. saisie .. ",x)"))
  ajoute("solve(y=(x^2+1)/(2x^2-3),x):")
  ajoute("  " .. cas("solve(y=(x^2+1)/(2*x^2-3),x)"))
  ajoute("domain((x^2+1)/(2x^2-3),x) = " .. cas("domain((x^2+1)/(2*x^2-3),x)"))
  ajoute("propFrac((x^3-x^2+x+1)/(x^2+1),x) =")
  ajoute("  " .. cas("propFrac((x^3-x^2+x+1)/(x^2+1),x)"), {0,120,0}, true)
  ajoute("limit((x^2+1)/(2x^2-3),x,inf) = " .. cas("limit((x^2+1)/(2*x^2-3),x,∞)"))
  ajoute("expand((x+2)*(x^2-x-6)) = " .. cas("expand((x+2)*(x^2-x-6))"))
  ajoute("2) Polices", {30,70,160}, true)
  ajoute("normal 9", nil, false, 9)
  ajoute("gras 12", nil, true, 12)
  ajoute("grand 16", {200,0,0}, true, 16)
  ajoute("3) Touches : fleches = defiler, tab = saisir", {30,70,160}, true)
  ajoute("   tapez une expression puis enter", {110,110,110})
  ajoute("4) on.save/on.restore : compteur = " .. compteur)
  ajoute("5) Boite 2D en bas (D2Editor) : " .. (rich and "ok" or "absente"))
end

function on.construction()
  calculer()
end

function on.resize(w, h)
  if rich then rich:move(4, h - 46); rich:resize(w - 8, 42); return end
  local ok = pcall(function()
    rich = D2Editor.newRichText()
    rich:move(4, h - 46)
    rich:resize(w - 8, 42)
    rich:setReadOnly(true)
    rich:setText("A: \\0el {(x^2+1)/(2*x^2-3)}  B: " .. string.char(0) .. "el {1/2+5/(2*(2*x^2-3))}")
  end)
  if not ok then rich = nil end
  calculer()
end

local saisieActive = false

function on.paint(gc)
  local w, h = platform.window:width(), platform.window:height()
  gc:setColorRGB(30,70,160)
  gc:fillRect(0, 0, w, 20)
  local y = 2 - haut
  for i, l in ipairs(L) do
    gc:setFont("sansserif", l[3] and "b" or "r", l[4])
    gc:setColorRGB(l[2][1], l[2][2], l[2][3])
    if y > -20 and y < h - 50 then gc:drawString(l[1], 4, y, "top") end
    y = y + gc:getStringHeight("Mg") + 2
  end
  gc:setFont("sansserif", "r", 9)
  gc:setColorRGB(220,220,220)
  gc:fillRect(0, h - 64, w, 16)
  gc:setColorRGB(0,0,0)
  gc:drawString((saisieActive and "saisie> " or "expr: ") .. saisie, 4, h - 64, "top")
end

function on.arrowDown() haut = haut + 12; platform.window:invalidate() end
function on.arrowUp() haut = math.max(0, haut - 12); platform.window:invalidate() end
function on.tabKey() saisieActive = true; saisie = ""; platform.window:invalidate() end
function on.charIn(ch)
  if saisieActive then saisie = saisie .. ch; platform.window:invalidate() end
end
function on.backspaceKey()
  if saisieActive then saisie = saisie:sub(1, -2); platform.window:invalidate() end
end
function on.enterKey()
  saisieActive = false
  compteur = compteur + 1
  calculer(); platform.window:invalidate()
end
function on.escapeKey() saisieActive = false; platform.window:invalidate() end

function on.save() return {compteur = compteur, saisie = saisie} end
function on.restore(t)
  if type(t) == "table" then compteur = t.compteur or 0; saisie = t.saisie or saisie end
end
