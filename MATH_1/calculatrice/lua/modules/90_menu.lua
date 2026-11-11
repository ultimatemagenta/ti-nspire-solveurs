-- 90_menu.lua : menus du classeur maths (9 entrees au plus par menu) et index de recherche INDEX_SOLVEURS
-- Chaque feuille : {libelle, action, forts = "…", mots = "…", si = "…"} ; les champs forts/mots/si alimentent
-- l'index « Trouver un solveur » du socle (radicaux minuscules sans accents ; forts = 3 pts, mots = 1 pt).
-- Le chemin de chaque entree d'index est calcule depuis l'arbre des menus : il ne peut pas deriver.
-- Les actions (questions et valeurs par defaut) sont celles de lua/solveur.lua, a l'identique.
do   -- bloc : limite de 200 variables locales du script principal
local auto, problemeA2, FIGB, problemeB2, FIGURES, chasles, analyse, identifier, norm, bilanFacto = M1.auto, M1.problemeA2, M1.FIGB, M1.problemeB2, M1.FIGURES, M1.chasles, M1.analyse, M1.identifier, M1.norm, M1.bilanFacto
local equation, inequation, changement, variable, division, simplifier, signePoly, factoLitterale, isoler = M1.equation, M1.inequation, M1.changement, M1.variable, M1.division, M1.simplifier, M1.signePoly, M1.factoLitterale, M1.isoler
local vNorme, vScalaire, vProjPoint, vProjVect, vVectoriel, vMixte, vParam, vComposantes, vBON, vConstruire = M1.vNorme, M1.vScalaire, M1.vProjPoint, M1.vProjVect, M1.vVectoriel, M1.vMixte, M1.vParam, M1.vComposantes, M1.vBON, M1.vConstruire
local domaineGeneral, bijectionI, parite, composition, bilin, vPoint, vColin, vUnitOrtho, vNormeDonnee = M1.domaineGeneral, M1.bijectionI, M1.parite, M1.composition, M1.bilin, M1.vPoint, M1.vColin, M1.vUnitOrtho, M1.vNormeDonnee
local vec, composantesBase, systemeVect, aide, aireFigure, minMaxTrinome = M1.vec, M1.composantesBase, M1.systemeVect, M1.aide, M1.aireFigure, M1.minMaxTrinome

-- feuille de menu indexee
local function F(lib, action, forts, mots, si) return {lib, action, forts = forts, mots = mots, si = si} end
-- sous-menu : {libelle, ouvre le menu, sous = menu}
local function S(lib, titre, items)
  local m = {titre = titre, items = items}
  return {lib, function() MENU = m; sel = 1; ecran = "menu"; inval() end, sous = m}
end

------------------------------------------------------------------ actions (copiees de lua/solveur.lua)
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

local function lancerAire()
  demander("points (A=x,y;…) = ", function(p)
    demander("décomposition = ", function(d)
      demander("contour (contrôle) = ", function(c) aireFigure(p, d, c) end, "A,B,C,I,H,G-E,D,J,F",
        {vide = true, aide = "Contour parcouru dans l'ordre, trous après « - » (formule des lacets). Vide : pas de contrôle."})
    end, "4*par(A,B,G)-2*tri(A,B,E)",
      {vide = true, aide = "par(X,Y,Z) = parallélogramme ||XY × XZ|| ; tri(X,Y,Z) = triangle 1/2·||XY × XZ|| ; coefficients et − admis. Vide : lacets seuls."})
  end, "A=-1,4;B=1,4;C=3,0;D=1,0;E=0,2;F=-1,0;G=-3,0;H=-1,-4;I=1,-4;J=0,-2",
    {aide = "Coordonnées lues sur le quadrillage (1 carré = 1 unité). Défaut : logo du test 2025, P3."})
end

local function lancerMinMax()
  demander("f(x) = ", function(f)
    demander("intervalles = ", function(i) minMaxTrinome(f, i) end, "R;[-1,1];[-3,-2]",
      {aide = "Séparés par ; — R, [a,b], ]a,b[ (ouvert), +inf / -inf. Défaut : série 7 ex.6."})
  end, "x^2+x+2", {aide = "Trinôme ax²+bx+c (ou les coefficients a,b,c). Défaut : série 7 ex.6."})
end

local function composantesBase2D()
  demander("w = ", function(w) demander("base (b1;b2[;b3]) = ", function(bs)
    vider(); T("Composantes dans une base")
    local b = {}
    for _, x in ipairs(decouper(bs, ";")) do table.insert(b, vec(x)) end
    G("Méthode : w = α·b1 + β·b2 (+ γ·b3) : une équation par coordonnée, puis résolution (substitution ou combinaison de lignes).")
    composantesBase(vec(w), b, "w = ")
    montrer("Composantes") end, "[1,1];[1,-1]") end, "3,1")
end

------------------------------------------------------------------ figures (probleme B) : libelles courts, memes definitions
local NOMS_FIGB = {"B : parallélogramme, centre, milieux", "B : triangle, milieux, gravité", "B : parallélépipède ABCDEFGH"}
local INDEX_FIGB = {
  {"parallelogramme centre", "milieu exprimer simplement somme figure vecteur chasles", "problème B : parallélogramme et milieux"},
  {"triangle gravite", "milieu exprimer simplement somme figure vecteur chasles", "problème B : triangle, milieux, gravité"},
  {"parallelepipede cube", "exprimer simplement somme figure vecteur chasles espace", "problème B : parallélépipède ou cube"},
}
local itemsB = {}
for k, fg in ipairs(FIGB) do
  local ix = INDEX_FIGB[k] or {"figure", "", ""}
  table.insert(itemsB, F(NOMS_FIGB[k] or fg[1], function()
    demander("sommes (séparées par ;) = ", function(sm) problemeB2(fg[2], sm) end, "AB+BC;AO+OC;AM;MN") end,
    "chasles " .. ix[1], ix[2] .. " probleme", ix[3]))
end
table.insert(itemsB, F("B : figure libre (points en u, v)", function()
  demander("points (A=0;B=u;…) = ", function(d) demander("sommes = ", function(sm) problemeB2(d, sm) end, "AB+BC") end, "A=0;B=u;D=v;C=u+v") end,
  "chasles libre logo exprimer", "simplement uniquement fonction figure somme probleme base vecteur",
  "autre figure (logo…) : points en u, v"))

local itemsSomme = {}
local INDEX_FIG = {{"parallelogramme centre"}, {"parallelepipede cube"}, {"triangle gravite milieu"}}
local NOMS_FIG = {"Parallélogramme ABCD, centre O", "Parallélépipède ABCDEFGH", "Triangle ABC, milieux, gravité G"}
for k, fg in ipairs(FIGURES) do
  table.insert(itemsSomme, F(NOMS_FIG[k] or fg[1], function() demander("somme = ", function(sm) chasles(fg[2], sm) end, "AG+GH+AB") end,
    "chasles combinaison", (INDEX_FIG[k] or {""})[1] .. " somme exprimer simplement vecteur", "une seule somme, figure préréglée"))
end
table.insert(itemsSomme, F("Figure libre (définir les points)", function()
  demander("points (A=0;B=u;…) = ", function(d) demander("somme = ", function(sm) chasles(d, sm) end, "AB+BC") end, "A=0;B=u;D=v;C=u+v") end,
  "chasles combinaison libre", "somme exprimer simplement vecteur figure", "une seule somme, points à définir"))

------------------------------------------------------------------ arbre des menus
local MENU_PRINCIPAL = {titre = TITRE_APP, items = {
  F("Résoudre (automatique)", function() demander("à résoudre = ", function(e) auto(e) end, HIST[#HIST]) end,
    "resoudre equation inequation", "parametre exponentielle valeur absolue solution racine",
    "inconnue x ; sinon « Isoler une lettre »"),
  F("Problème A : projection, ⊥, volume, base", function()
    demander("P = ", function(p) demander("Q = ", function(q) demander("R = ", function(r) demander("S (avec paramètre) = ", function(sx)
      demander("condition sur S = ", function(cd) problemeA2(p, q, r, sx, cd) end, "QS.QR=0") end, "x,x+2,x") end, "R(2;0;6)") end, "Q(7;2;5)") end, "P(-1;-7;7)") end,
    "probleme complet", "points projection orthogonale perpendiculaire volume parallelepipede base orthonormee directe composante espace",
    "énoncé P, Q, R, S en entier (test 2025 P2)"),
  S("Figure : exprimer (Chasles), aire", "Figure, Chasles, aire", {
    itemsB[1], itemsB[2], itemsB[3], itemsB[4],
    S("Une somme à la fois (Chasles)", "Chasles : une somme", itemsSomme),
    F("Aire d'une figure (quadrillage)", lancerAire, "aire surface quadrillage logo",
      "figure parallelogramme triangle unite polygone carre decomposer",
      "figure sur quadrillage : morceaux ou contour"),
  }),
  F("Fonction : domaine, zéros, asymptotes", lancerAnalyse,
    "asymptote pole zero analyse etude", "domaine signe tableau fonction rationnelle reciproque image variation graphe multiplicite courbe representer",
    "fraction rationnelle : étude complète"),
  S("Fonctions : domaine, bijection, min/max", "Fonctions (série 7)", {
    F("Domaine (racines, fractions)", function() demander("f(x) = ", function(f) domaineGeneral(norm(f)) end, "sqrt((x-2)/(x+2))") end,
      "domaine definition", "racine fraction ensemble existence", "seulement l'ensemble de définition"),
    F("Bijection sur I, f⁻¹ et courbes", function() demander("f(x) = ", function(f) demander("I = ", function(I) bijectionI(f, I) end, "]sqrt(3/2);+inf[") end, HIST[#HIST]) end,
      "bijection reciproque", "intervalle inverse ensemble expression image courbe", "intervalle I donné : J et f⁻¹"),
    F("Parité", function() demander("f(x) = ", function(f) parite(f) end, "x^3+x") end,
      "parite paire impaire", "fonction symetrie", "f(−x) = f(x) ou −f(x) ?"),
    F("Composition f∘g et g∘f", function() demander("f(x) = ", function(f) demander("g(x) = ", function(g) composition(f, g) end, "sqrt(1-x)") end, "sqrt(x^2-1)") end,
      "composition composee rond", "fonctions ensemble definition", "f∘g, g∘f et leur ensemble de définition"),
    F("Réels a, b tels que f = a + b/…", lancerIdent,
      "identifier reels tels", "nombres forme coefficient", "forme imposée avec des lettres a, b, c"),
    F("Min et max d'un trinôme sur I", lancerMinMax,
      "minimum maximum minima maxima extremum", "trinome intervalle sommet parabole second degre quadratique",
      "ax²+bx+c sur un ou plusieurs intervalles"),
  }),
  S("Équations, factoriser, isoler", "Équations, polynômes, lettres", {
    F("Résoudre une équation (Δ, paramètre…)", function()
      demander("équation = ", function(e) equation(norm(e)) end, "x^2-3x+2=0") end,
      "equation delta discriminant", "resoudre parametre second degre racine solution", "une équation : Δ, cas du paramètre"),
    F("Inéquation, valeur absolue", function()
      demander("inéquation = ", function(e) inequation(norm(e)) end, "(3x+1)/(2x-1)>=0") end,
      "inequation absolue", "resoudre signe tableau", "signe < > ≤ ≥, ou |…|"),
    F("Changement de variable", function()
      demander("équation = ", function(e)
        demander("X = ", function(sub) changement(norm(e), norm(sub), variable(e)) end, "x^2")
      end, "x^4-5x^2+4=0") end,
      "changement variable bicarree", "poser exponentielle resoudre equation", "bicarrée, eˣ, x^(1/3) : poser X = …"),
    F("Division en potence A ÷ B", function()
      demander("A(x) = ", function(a)
        demander("B(x) = ", function(b) division(norm(a), norm(b)) end, "x^2+x+1")
      end, "x^3+2x^2-3") end,
      "division quotient reste potence", "polynome euclidienne", "quotient et reste de A par B"),
    F("Simplifier une fraction / expression", function()
      demander("expression = ", function(e) simplifier(norm(e)) end, "(a-3)/(2a^2-18)") end,
      "simplifier", "fraction expression rationnelle", "fraction à simplifier"),
    F("Factoriser un polynôme (détail)", lancerFacto,
      "factoriser", "polynome racine evidente detail produit facteur", "polynôme en x : racine évidente, division"),
    F("Factoriser et étudier le signe", function()
      demander("P = ", function(e) signePoly(norm(e)) end, "x^3-7x^2-4x+28") end,
      "signe decomposer etudier", "factoriser produit facteur polynome tableau", "facteurs + tableau de signes"),
    F("Factoriser une expression (lettres)", function() demander("expression = ", function(e) factoLitterale(norm(e)) end, "a^3*b+a*b^3-2*a^2*b^2") end,
      "factoriser litterale", "lettres expression plusieurs factorisee reels", "plusieurs lettres (a, b…), pas de x"),
    F("Isoler une lettre", function() demander("équation = ", function(e) demander("lettre = ", function(l) isoler(norm(e), l) end, "c") end, "1/a+1/b=1/c") end,
      "isoler h", "lettre resoudre equation formule exprimer y v", "« résoudre pour y, h, v » : autre que x"),
  }),
  S("Vecteurs : produits, base, points", "Vecteurs (séries 4 à 6)", {
    F("Norme, vecteur unitaire", function() demander("u = ", function(u) vNorme(u) end, "2,-1,2") end,
      "norme unitaire", "vecteur longueur direction distance", "norme, distance, vecteur unitaire"),
    F("Produit scalaire, angle", function() demander("u = ", function(u) demander("v = ", function(v) vScalaire(u, v) end, "3,4,0") end, "1,1,0") end,
      "scalaire angle", "vecteur forme cosinus degre", "composantes connues ; sinon bilinéarité"),
    F("Projection d'un point sur une droite (AB)", function()
      demander("point P = ", function(p) demander("A = ", function(a) demander("B = ", function(b) vProjPoint(p, a, b) end, "R(2;0;6)") end, "Q(7;2;5)") end, "P(-1;-7;7)") end,
      "projection projete", "orthogonale point droite coordonnee distance", "point T, projeté de P sur une droite"),
    F("Projection d'un vecteur v sur u", function() demander("v = ", function(v) demander("u = ", function(u) vProjVect(v, u) end, "1,0,1") end, "2,3,1") end,
      "projection", "vecteur axe valeur orthogonale", "vecteur projeté sur un vecteur ou un axe"),
    F("Produit vectoriel, aire", function() demander("u = ", function(u) demander("v = ", function(v) vVectoriel(u, v) end, "4,5,6") end, "1,2,3") end,
      "vectoriel", "aire surface triangle parallelogramme produit", "u × v, aire d'un triangle (composantes)"),
    F("Produit mixte, volume, coplanarité", function()
      demander("a = ", function(a) demander("b = ", function(b) demander("c = ", function(c) vMixte(a, b, c) end, "-1,2,5") end, "0,4,2") end, "2,0,3") end,
      "mixte volume coplanaire", "parallelepipede points tetraedre base produit", "volume, 4 points coplanaires ?"),
    S("Paramètre : ⊥, colinéaires, système", "Vecteurs : paramètre", {
      F("Paramètre : u ⊥ v (QS ⊥ QR…)", function() demander("u = ", function(u) demander("v = ", function(v) vParam(u, v, "o") end, "-5,-2,1") end, "x-7,x,x-5") end,
        "perpendiculaire orthogonal", "parametre point tel coordonnee", "un paramètre, condition u·v = 0"),
      F("Paramètre : u, v colinéaires", function() demander("u = ", function(u) demander("v = ", function(v) vParam(u, v, "c") end, "2,4,6") end, "1,m,3") end,
        "colineaire", "parametre parallele", "un paramètre m, vecteurs colinéaires"),
      F("Système de conditions (u.v=0 and …)", function()
        demander("vecteurs (u=…;v=…) = ", function(d) demander("conditions = ", function(c) systemeVect(d, c) end, "u.v=0 and u.w=0") end, "u=[a,b,1];v=[1,2,3];w=[2,0,1]") end,
        "systeme condition", "vecteur inconnues rectangle aire tel orthogonal", "deux inconnues, plusieurs conditions"),
    }),
    S("Base : composantes, BON, unitaire", "Vecteurs : base", {
      F("Composantes dans une base 3D", function()
        demander("w = ", function(w) demander("b1 = ", function(b1) demander("b2 = ", function(b2) demander("b3 = ", function(b3) vComposantes(w, b1, b2, b3) end, "0,0,1") end, "-5,-2,1") end, "-8,-9,2") end, "-1,2,0") end,
        "composante base", "vecteur coordonnee alpha beta", "w = αb1 + βb2 + γb3 (3 vecteurs 3D)"),
      F("Composantes dans une base 2D (ou 3D)", composantesBase2D,
        "composante base", "vecteur coordonnee plan alpha beta", "base du plan {b1 ; b2}"),
      F("Base orthonormée directe ?", function()
        demander("a = ", function(a) demander("b = ", function(b) demander("c = ", function(c) vBON(a, b, c) end, "-2/3,2/3,-1/3") end, "2/3,1/3,-2/3") end, "1/3,2/3,2/3") end,
        "orthonormee", "base directe verifier", "vérifier normes, ⊥ et sens"),
      F("Construire une BON directe", function() demander("a (direction de u) = ", function(a) demander("b (⊥ a) = ", function(b) vConstruire(a, b) end, "-1,2,0") end, "-5,-2,1") end,
        "construire bon", "base orthonormee directe", "construire u, v, w = u × v"),
      F("Vecteur unitaire ⊥ à deux vecteurs", function() demander("a = ", function(a) demander("b = ", function(b) vUnitOrtho(a, b) end, "1,0,1") end, "1,2,3") end,
        "unitaire orthogonal", "deux perpendiculaire vecteur", "unitaire ⊥ à a et à b"),
      F("Vecteur de norme donnée", function() demander("a = ", function(a) demander("norme = ", function(d) vNormeDonnee(a, d) end, "3") end, "2,-1,2") end,
        "norme donnee", "vecteur meme direction sens", "même direction, norme imposée"),
    }),
    S("Points : alignés, milieu, gravité…", "Points", {
      F("Milieu de [AB]", function() demander("A = ", function(a) demander("B = ", function(b) vPoint("milieu", a, b) end, "3,3,1") end, "1,2,3") end,
        "milieu", "point segment", "milieu d'un segment"),
      F("Centre de gravité ABC", function() demander("A = ", function(a) demander("B = ", function(b) demander("C = ", function(c) vPoint("gravite", a, b, c) end, "0,0,3") end, "3,3,1") end, "1,2,3") end,
        "gravite", "centre triangle point", "centre de gravité d'un triangle"),
      F("D tel que ABCD parallélogramme", function() demander("A = ", function(a) demander("B = ", function(b) demander("C = ", function(c) vPoint("para", a, b, c) end, "4,1,0") end, "3,3,1") end, "1,2,3") end,
        "parallelogramme", "point quatrieme sommet", "4e sommet d'un parallélogramme"),
      F("Symétrique de A par rapport à B", function() demander("A = ", function(a) demander("B = ", function(b) vPoint("sym", a, b) end, "3,3,1") end, "1,2,3") end,
        "symetrique", "point", "symétrique par rapport à un point"),
      F("M tel que AM = k·AB", function() demander("A = ", function(a) demander("B = ", function(b) demander("k = ", function(k) vPoint("rapport", a, b, nil, k) end, "2/3") end, "3,3,1") end, "1,2,3") end,
        "rapport", "point fraction tel", "AM = k·AB, k donné"),
      F("M tel que αMA + βMB + γMC = 0", function() demander("A = ", function(a) demander("B = ", function(b) demander("C = ", function(c) demander("α,β,γ = ", function(k) vPoint("relation", a, b, c, k) end, "1,2,0") end, "0,0,0") end, "3,3,1") end, "1,2,3") end,
        "relation barycentre", "point tel", "relation vectorielle αMA + βMB + … = 0"),
      F("Alignés ? colinéaires ? (par λ)", function() demander("u = ", function(u) demander("v = ", function(v) vColin(u, v) end, "-2,m+4") end, "1,5") end,
        "aligne colineaire", "lambda points parallele montrer", "A, B, C alignés : AC = λ·AB ?"),
      F("Angle par bilinéarité (||a||, ||b||)", function()
        demander("équation en a, b = ", function(e) demander("||a|| = ", function(na) demander("||b|| = ", function(nb) bilin(norm(e), na, nb) end, "3") end, "2") end, "(2a-b)*(a+b)=0") end,
        "bilinearite sachant", "angle norme orthogonaux", "normes connues, pas de composantes"),
    }),
  }),
  F("Historique des résultats", historiqueResultats, "historique", "resultat precedent", "revoir un résultat déjà affiché"),
  F("Aide à la saisie", aide, "syntaxe", "saisie taper ecrire touche", "comment taper puissances, fractions…"),
}}

menuPrincipal = function()
  -- retour au menu principal : la pile des menus (socle_fin.lua) repart de zero, sinon elle garde des menus perimes
  if PILE_MENUS then for i = #PILE_MENUS, 1, -1 do PILE_MENUS[i] = nil end end
  MENU = MENU_PRINCIPAL
  sel = 1; ecran = "menu"; inval()
end

------------------------------------------------------------------ index de recherche (une entree par feuille)
INDEX_SOLVEURS = INDEX_SOLVEURS or {}
local function mots(s) local t = {}; for m in tostring(s or ""):gmatch("%S+") do t[#t + 1] = m end; return t end
local function indexer(m, prefixe)
  for i, it in ipairs(m.items) do
    local ch = prefixe and (prefixe .. "·" .. i) or tostring(i)
    if it.sous then indexer(it.sous, ch)
    elseif it.forts then
      table.insert(INDEX_SOLVEURS, {titre = it[1], chemin = ch, forts = mots(it.forts), mots = mots(it.mots), si = it.si, ouvrir = it[2]})
    end
  end
end
indexer(MENU_PRINCIPAL, nil)

-- fonctions exposees aux tests sur PC (tools/nspire/test_pc.py APP.lua NOM args…)
for k, v in pairs(M1) do if type(v) == "function" then SOLVEURS[k] = v end end
end
