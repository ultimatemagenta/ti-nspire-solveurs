-- 00_commun.lua : en-tete du classeur maths sur le socle commun (charge en premier, apres socle_debut.lua)
-- Les modules suivants sont des blocs do … end (limite de 200 variables locales du script principal) :
-- chacun exporte ses fonctions dans M1 et importe celles des modules precedents (local f = M1.f).
TITRE_APP = "MATH_1 – solveur"
local M1 = {}
INDEX_SOLVEURS = INDEX_SOLVEURS or {}   -- index de la recherche « Trouver un solveur » (rempli par 90_menu.lua)

-- hors bloc : socle_fin.lua (dessinerGraphe) appelle horner
local function horner(c, x) local r = 0; for _, a in ipairs(c) do r = r * x + a end; return r end
