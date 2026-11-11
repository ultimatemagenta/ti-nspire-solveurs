-- 60_auto.lua : resolution automatique et aide a la saisie
-- (lignes 2428-2474 de lua/solveur.lua, decoupees le 11.11.2026 ; code inchange)
do   -- bloc : limite de 200 variables locales du script principal
local norm, analyse, cotes, simplifier, inequation, changement, equation, signePoly, domaineGeneral, factoLitterale = M1.norm, M1.analyse, M1.cotes, M1.simplifier, M1.inequation, M1.changement, M1.equation, M1.signePoly, M1.domaineGeneral, M1.factoLitterale
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

M1.aide = aide; M1.auto = auto
end
