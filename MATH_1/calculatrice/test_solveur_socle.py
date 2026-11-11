"""Non-regression du solveur maths sur socle : lua/solveur.lua (ancien) contre lua/solveur_socle.lua (nouveau).

Usage : python MATH_1/calculatrice/test_solveur_socle.py [-v]      (python avec lupa ; construire d'abord : construire_solveur.py)

1. Solveurs : chaque fonction de SOLVEURS (communes aux deux scripts) est appelee avec les donnees par defaut des menus,
   sous deux bouchons du CAS (math.evalStr -> nil, comme test_pc.py ; et « echo » qui renvoie l'expression recue, pour
   descendre plus loin dans le code), puis le document produit est imprime par test_pc.imprimer et compare.
   Les lectures de variables globales inconnues sont journalisees : une variable oubliee dans les imports d'un module
   apparaitrait ici comme globale nouvelle.
2. Menus : chaque entree de l'ancien menu est parcourue en mode --menu (test_pc.parcourir, valeurs par defaut) et comparee
   a la meme entree a son nouveau chemin (table CHEMINS).
3. Nouveau script seul : tous les menus <= 9 entrees, chaque feuille s'ouvre sans erreur, index INDEX_SOLVEURS coherent
   (chemin -> libelle et action), recherche sur les consignes de l'etude (section 3.3), nouveaux solveurs contre les corriges.
Ancien script : SOLVEURS_GLOBAL et API_TEST lui sont ajoutes en memoire (le fichier n'est pas modifie).
"""
import contextlib
import os
import io
import re
import sys
from pathlib import Path

import lupa

ICI = Path(__file__).resolve().parent
RACINE = ICI.parents[1]
sys.path.insert(0, os.environ.get("TEST_PC_DIR") or str(RACINE / "tools" / "nspire"))
import test_pc  # noqa: E402

ANCIEN = ICI / "lua" / "solveur.lua"
NOUVEAU = ICI / "lua" / "solveur_socle.lua"
VERBEUX = "-v" in sys.argv

# Lua 5.1 de la calculatrice : unpack, loadstring, math.log10 (absents de Lua 5.4/5.5) ; garde-fou contre les boucles
EXTRAS = r"""
unpack = unpack or table.unpack
loadstring = loadstring or load
math.log10 = math.log10 or function(x) return math.log(x, 10) end
"""
CAS = {
    "nil": "math.evalStr = function() return nil end",
    "echo": "math.evalStr = function(e) return tostring(e) end",
}

API_ANCIEN = r"""
API_TEST = {doc = function() return DOC end, hist = function() return HIST end,
  ecran = function() return ecran end, vue = function() return vue end, saisie = function() return saisie end, menu = function() return MENU, sel end,
  entrer = function(txt) if txt then saisie.txt = txt; saisie.cur = #txt end; on.enterKey() end,
  choisir = function(i) sel = i; on.enterKey() end}
"""


def source_ancien(noms):
    src = ANCIEN.read_text(encoding="utf-8")
    marque = "------------------------------------------------------------------ dessin : tableau de signes"
    expo = "SOLVEURS_GLOBAL = {" + ", ".join("%s = %s" % (n, n) for n in noms) + "}\n"
    assert marque in src
    return src.replace(marque, expo + marque, 1) + "\n" + API_ANCIEN


def charger(src, cas="nil"):
    L = lupa.LuaRuntime(unpack_returned_tuples=True)
    L.execute(test_pc.BOUCHONS)
    L.execute(EXTRAS)
    L.execute(CAS[cas])
    f = L.eval("function(s) local f, e = load(s, 'app'); if not f then error(e) end; return f end")(src)
    f()
    L.execute("if on.construction then on.construction() end")
    # journal des globales lues sans exister + garde-fou d'instructions (boucle infinie avec le CAS « echo »)
    L.execute(r"""
      INCONNUES = {}
      local std = {}
      setmetatable(_G, {__index = function(t, k) if not std[k] then INCONNUES[k] = true end; return nil end})
      GARDE = function(fn, ...)
        local n = 0
        debug.sethook(function() n = n + 1; if n > 20000 then debug.sethook(); error("GARDE : trop long") end end, "", 1000)
        local r = {pcall(fn, ...)}
        debug.sethook()
        return r[1], r[2]
      end
    """)
    return L


def sortie(fn):
    tampon = io.StringIO()
    with contextlib.redirect_stdout(tampon):
        try:
            fn()
        except Exception as e:  # noqa: BLE001
            print("EXCEPTION PYTHON :", str(e).split("\n")[0])
    return tampon.getvalue()


def appeler(L, nom, args):
    def run():
        fn = L.globals().SOLVEURS_GLOBAL[nom]
        if fn is None:
            print("SOLVEUR ABSENT :", nom)
            return
        ok, err = L.globals().GARDE(fn, *args)
        if not ok:
            print("ERREUR LUA :", str(err))
        test_pc.imprimer(L)
    out = sortie(run)
    inc = sorted(k for k in L.globals().INCONNUES.keys())
    L.execute("INCONNUES = {}")
    return out, inc


# donnees par defaut des menus (lua/solveur.lua) ; listes = arguments successifs
CAS_SOLVEURS = [
    ("auto", ["x^2-3x+2=0"]), ("auto", ["(3x+1)/(2x-1)>=0"]), ("auto", ["6e^(3x)+5e^(2x)-2e^(x)-1=0"]), ("auto", ["x^3-7x^2-4x+28"]),
    ("auto", ["(x^2+1)/(2x^2-3)"]), ("auto", ["sqrt(x-1)"]), ("auto", ["(a-3)/(2a^2-18)"]), ("auto", ["a^2-b^2"]), ("auto", ["2+3"]),
    ("analyse", ["(x^2+1)/(2x^2-3)"]), ("analyse", ["(x^3-3x^2)/(x^3+x^2-8x-12)"]),
    ("identifier", ["(x^3+x+1)/(x^2+1)", "a*x+b+c/(x^2+1)"]),
    ("bilanFacto", ["x^3-7x^2-4x+28", "P"]), ("factoriserDetail", ["x^3-7x^2-4x+28", "P"]),
    ("equation", ["x^2-3x+2=0"]), ("equation", ["(m*x)^2-2m*x-3=0"]), ("inequation", ["(3x+1)/(2x-1)>=0"]), ("inequation", ["abs(x-1)/(x+2)>=1/2"]),
    ("changement", ["x^4-5x^2+4=0", "x^2", "x"]), ("division", ["x^3+2x^2-3", "x^2+x+1"]), ("simplifier", ["(a-3)/(2a^2-18)"]),
    ("signePoly", ["x^3-7x^2-4x+28"]), ("parametre", ["(m*x)^2-2m*x-3=0", "x", "m"]),
    ("vNorme", ["2,-1,2"]), ("vScalaire", ["1,1,0", "3,4,0"]), ("vProjPoint", ["P(-1;-7;7)", "Q(7;2;5)", "R(2;0;6)"]),
    ("vProjVect", ["2,3,1", "1,0,1"]), ("vVectoriel", ["1,2,3", "4,5,6"]), ("vMixte", ["2,0,3", "0,4,2", "-1,2,5"]),
    ("vParam", ["x-7,x,x-5", "-5,-2,1", "o"]), ("vParam", ["1,m,3", "2,4,6", "c"]),
    ("vComposantes", ["-1,2,0", "-8,-9,2", "-5,-2,1", "0,0,1"]), ("vBON", ["1/3,2/3,2/3", "2/3,1/3,-2/3", "-2/3,2/3,-1/3"]),
    ("vConstruire", ["-5,-2,1", "-1,2,0"]),
    ("domaineGeneral", ["sqrt((x-2)/(x+2))"]), ("bijectionI", ["(x^2+1)/(2x^2-3)", "]sqrt(3/2);+inf["]), ("parite", ["x^3+x"]),
    ("composition", ["sqrt(x^2-1)", "sqrt(1-x)"]), ("factoLitterale", ["a^3*b+a*b^3-2*a^2*b^2"]), ("isoler", ["1/a+1/b=1/c", "c"]),
    ("bilin", ["(2a-b)*(a+b)=0", "2", "3"]), ("systemeVect", ["u=[a,b,1];v=[1,2,3];w=[2,0,1]", "u.v=0 and u.w=0"]),
    ("chasles", ["A=0;B=u;D=v;C=u+v;O=(u+v)/2", "AG+GH+AB"]), ("chasles", ["A=0;B=u;D=v;C=u+v", "AB+BC"]),
    ("problemeA", ["P(-1;-7;7)", "Q(7;2;5)", "R(2;0;6)", "x,x+2,x"]),
    ("problemeB", ["A=0;B=u;D=v;C=u+v;O=(u+v)/2;I=u/2;M=u+v/2;N=u/2+v;K=v/2", "AB+BC;AO+OC;AM;MN"]),
    ("problemeA2", ["P(-1;-7;7)", "Q(7;2;5)", "R(2;0;6)", "x,x+2,x", "QS.QR=0"]),
    ("problemeB2", ["A=0;B=u;D=v;C=u+v;O=(u+v)/2;I=u/2;M=u+v/2;N=u/2+v;K=v/2", "AB+BC;AO+OC;AM;MN"]),
    ("problemeB2", ["A=0;B=u;D=v;C=u+v", "AB+BC"]),
    ("vPoint", ["milieu", "1,2,3", "3,3,1"]), ("vPoint", ["gravite", "1,2,3", "3,3,1", "0,0,3"]), ("vPoint", ["para", "1,2,3", "3,3,1", "4,1,0"]),
    ("vPoint", ["sym", "1,2,3", "3,3,1"]), ("vPoint", ["rapport", "1,2,3", "3,3,1", None, "2/3"]),
    ("vPoint", ["relation", "1,2,3", "3,3,1", "0,0,0", "1,2,0"]),
    ("vColin", ["1,5", "-2,m+4"]), ("vUnitOrtho", ["1,2,3", "1,0,1"]), ("vNormeDonnee", ["2,-1,2", "3"]),
    ("ineqRat", ["(x-1)", "(x+2)", ">=", "x"]), ("ineqAbs", ["abs(x-1)", "1/2", ">=", "x"]),
    ("eqIrrationnelle", ["sqrt(x+5)=x-1"]), ("eqLog", ["ln(x)+ln(x-1)=ln(6)"]),
    ("aide", []),
]

# ancien chemin -> nouveau chemin, saisies (vide = valeurs par defaut)
CHEMINS = [
    ([1], [1], ["x^2-3x+2=0"]), ([2], [2], []),
    ([3, 1], [3, 1], []), ([3, 2], [3, 2], []), ([3, 3], [3, 3], []), ([3, 4], [3, 4], []),
    ([4], [4], ["(x^2+1)/(2x^2-3)"]), ([5], [5, 5], ["(x^3+x+1)/(x^2+1)"]), ([6], [6, 6], ["x^3-7x^2-4x+28"]),
    ([7, 1], [6, 1], []), ([7, 2], [6, 2], []), ([7, 3], [6, 3], []), ([7, 4], [6, 4], []), ([7, 5], [6, 5], []), ([7, 6], [6, 7], []),
    ([8, 1], [7, 1], []), ([8, 2], [7, 2], []), ([8, 3], [7, 3], []), ([8, 4], [7, 4], []), ([8, 5], [7, 5], []), ([8, 6], [7, 6], []),
    ([8, 7], [7, 7, 1], []), ([8, 8], [7, 7, 2], []), ([8, 9], [7, 8, 1], []), ([8, 10], [7, 8, 3], []), ([8, 11], [7, 8, 4], []),
    ([9, 1], [5, 1], []), ([9, 2], [5, 2], ["(x^2+1)/(2x^2-3)"]), ([9, 3], [5, 3], []), ([9, 4], [5, 4], []),
    ([10, 1], [3, 5, 1], []), ([10, 2], [3, 5, 2], []), ([10, 3], [3, 5, 3], []), ([10, 4], [3, 5, 4], []),
    ([11, 1], [7, 9, 8], []), ([11, 2, 1], [7, 9, 1], []), ([11, 2, 2], [7, 9, 2], []), ([11, 2, 3], [7, 9, 3], []),
    ([11, 2, 4], [7, 9, 4], []), ([11, 2, 5], [7, 9, 5], []), ([11, 2, 6], [7, 9, 6], []), ([11, 3], [7, 9, 7], []),
    ([11, 4], [7, 8, 5], []), ([11, 5], [7, 8, 6], []), ([11, 6], [7, 8, 2], []), ([11, 7], [7, 7, 3], []),
    ([12, 1], [6, 8], []), ([12, 2], [6, 9], []), ([13], [8], []), ([14], [9], []),
]

# consignes reelles de l'etude (tools/nspire/ETUDE-CHOIX-SOLVEUR.md 3.3) : saisie courte -> chemin attendu dans le nouveau menu
CONSIGNES = [
    ("resoudre parametre", "1"), ("projection point droite", "7·3"), ("perpendiculaire", "7·7·1"), ("volume parallelepipede", "7·6"),
    ("composantes base", "7·8·1"), ("orthonormee", "7·8·3"), ("construire base orthonormee", "7·8·4"),
    ("exprimer simplement", "3·4"), ("surface logo quadrillage", "3·6"), ("domaine definition", "5·1"), ("zeros poles", "4"),
    ("asym", "4"), ("reels tels", "5·5"), ("bijection reciproque", "5·2"), ("minima maxima", "5·6"), ("quotient reste", "6·4"),
    ("fact signe", "6·7"), ("isoler", "6·9"), ("colineaire parametre", "7·7·2"), ("align", "7·9·7"), ("angle sachant", "7·9·8"),
]

# feuilles dont la question pre-remplit avec l'historique (vide au demarrage) : saisie fournie
SAISIES_FEUILLES = {"1": ["x^2-3x+2=0"], "4": ["(x^2+1)/(2x^2-3)"], "5·2": ["(x^2+1)/(2x^2-3)"], "5·5": ["(x^3+x+1)/(x^2+1)"],
                    "6·6": ["x^3-7x^2-4x+28"]}

ECHEC = []


def echec(msg):
    ECHEC.append(msg)
    print("  ECHEC :", msg)


def comparer(etiquette, a, b, inc_a=(), inc_b=()):
    # les numeros de ligne des messages d'erreur Lua changent forcement (script reassemble) : on les retire
    a = re.sub(r'\[string "app"\]:\d+:', "[app]:", a)
    b = re.sub(r'\[string "app"\]:\d+:', "[app]:", b)
    nouvelles = sorted(set(inc_b) - set(inc_a))
    if nouvelles:
        echec(etiquette + " : globales inconnues lues seulement par le nouveau script : " + ", ".join(nouvelles))
    if a != b:
        la, lb = a.splitlines(), b.splitlines()
        k = next((i for i in range(min(len(la), len(lb))) if la[i] != lb[i]), min(len(la), len(lb)))
        echec(etiquette + " : documents differents (ligne %d) :\n      ancien : %s\n      nouveau: %s"
              % (k + 1, la[k] if k < len(la) else "<fin>", lb[k] if k < len(lb) else "<fin>"))
        return False
    return True


def jetons(t):
    """Jetons d'un source Lua (chaines et commentaires sautes) : [(type, texte)]."""
    i, out = 0, []
    while i < len(t):
        c = t[i]
        if t.startswith("--", i):
            m = re.match(r"--\[(=*)\[", t[i:])
            if m:
                i = t.find("]" + m.group(1) + "]", i) + len(m.group(1)) + 2
            else:
                j = t.find("\n", i)
                i = len(t) if j < 0 else j
            continue
        m = re.match(r"\[(=*)\[", t[i:])
        if m:
            i = t.find("]" + m.group(1) + "]", i) + len(m.group(1)) + 2
            out.append(("s", ""))
            continue
        if c in "\"'":
            j = i + 1
            while t[j] != c:
                j += 2 if t[j] == "\\" else 1
            i = j + 1
            out.append(("s", ""))
            continue
        m = re.match(r"[A-Za-z_]\w*", t[i:])
        if m:
            out.append(("id", m.group(0)))
            i += len(m.group(0))
            continue
        m = re.match(r"\d[\w.]*", t[i:])
        if m:
            out.append(("n", ""))
            i += len(m.group(0))
            continue
        if not c.isspace():
            out.append(("p", c))
        i += 1
    return out


def verifier_imports():
    """Chaque nom exporte dans M1 qu'un module utilise doit y etre declare (local, import, parametre, boucle)."""
    mods = sorted((ICI / "lua" / "modules").glob("[0-9][0-9]_*.lua"))
    exportes = set()
    for m in mods:
        exportes |= set(re.findall(r"M1\.(\w+)\s*=", m.read_text(encoding="utf-8")))
    total = 0
    for m in mods:
        T = jetons(m.read_text(encoding="utf-8"))
        utilises = {v for k, (ty, v) in enumerate(T) if ty == "id" and not (k and T[k - 1] in (("p", "."), ("p", ":")))}
        txt = " ".join(x[1] for x in T)
        decl = set()
        for ps in re.findall(r"function\s*[\w.: ]*\(([^)]*)\)", txt):
            decl |= {p.strip() for p in ps.split(",")}
        for vs in re.findall(r"\bfor ([\w ,]+?) (?:=|in)\b", txt):
            decl |= {p.strip() for p in vs.split(",")}
        for vs in re.findall(r"\blocal (?:function )?((?:\w+ , )*\w+)", txt):
            decl |= {p.strip() for p in vs.split(",")}
        manque = sorted((utilises & exportes) - decl)
        total += len(manque)
        if manque:
            echec("%s utilise sans les importer : %s" % (m.name, ", ".join(manque)))
    print("   %d modules, %d noms exportes dans M1, %d import(s) manquant(s)" % (len(mods), len(exportes), total))


def nom_exporte(L):
    return sorted(k for k in L.globals().SOLVEURS_GLOBAL.keys())


def main():
    if not NOUVEAU.exists():
        sys.exit("construire d'abord : python MATH_1/calculatrice/construire_solveur.py")
    src_n = NOUVEAU.read_text(encoding="utf-8")
    noms = [n for n in nom_exporte(charger(src_n)) if n not in ("aireFigure", "minMaxTrinome", "lireQ")]
    src_a = source_ancien(noms)

    print("== 0. Imports entre modules (analyse statique)")
    verifier_imports()
    print("== 1. Solveurs (ancien / nouveau, CAS nil et echo)")
    n_ok = n_tot = 0
    for cas in ("nil", "echo"):
        La, Ln = charger(src_a, cas), charger(src_n, cas)
        for nom, args in CAS_SOLVEURS:
            n_tot += 1
            a, ia = appeler(La, nom, args)
            b, ib = appeler(Ln, nom, args)
            if comparer("%s %s%s" % (cas, nom, tuple(args)), a, b, ia, ib):
                n_ok += 1
            if VERBEUX:
                print("--- %s %s\n%s" % (cas, nom, b))
            La, Ln = charger(src_a, cas), charger(src_n, cas)   # etat neuf (historique, document)
    print("   %d / %d documents identiques" % (n_ok, n_tot))
    absents = [n for n, _ in CAS_SOLVEURS if n not in noms]
    couverts = {n for n, _ in CAS_SOLVEURS}
    print("   fonctions de SOLVEURS appelees : %d ; non appelees directement (outils internes) : %s"
          % (len(couverts), ", ".join(n for n in noms if n not in couverts)))
    if absents:
        echec("solveurs absents : " + ", ".join(absents))

    print("== 2. Menus : ancienne entree -> nouveau chemin (parcours --menu, valeurs par defaut)")
    n_ok = 0
    for cas in ("nil", "echo"):
        for ca, cn, saisies in CHEMINS:
            La, Ln = charger(src_a, cas), charger(src_n, cas)
            a = sortie(lambda: test_pc.parcourir(La, ca, list(saisies)))
            b = sortie(lambda: test_pc.parcourir(Ln, cn, list(saisies)))
            a = re.sub(r"\(menu : .*\)", "(menu)", a)
            b = re.sub(r"\(menu : .*\)", "(menu)", b)
            if comparer("%s menu %s -> %s" % (cas, ".".join(map(str, ca)), "·".join(map(str, cn))), a, b):
                n_ok += 1
            if VERBEUX:
                print("--- %s %s\n%s" % (cas, cn, b))
    print("   %d / %d parcours identiques" % (n_ok, 2 * len(CHEMINS)))

    print("== 3. Nouveau script : menus, index, recherche")
    L = charger(src_n)
    verifier_menus(L)
    verifier_index(L)
    verifier_recherche(L)
    print("== 4. Nouveaux solveurs contre les corriges du prof")
    verifier_nouveaux(src_n)
    print("\n" + ("OK : aucune difference, aucune erreur" if not ECHEC else "%d ECHEC(S)" % len(ECHEC)))
    sys.exit(1 if ECHEC else 0)


def verifier_menus(L):
    L.execute(r"""
      FEUILLES, MENUS_VUS = {}, {}
      local function parcours(m, ch)
        table.insert(MENUS_VUS, {titre = m.titre, n = #m.items, ch = ch})
        for i, it in ipairs(m.items) do
          local c = ch == "" and tostring(i) or (ch .. "·" .. i)
          if it.sous then parcours(it.sous, c) else table.insert(FEUILLES, {ch = c, lib = it[1]}) end
        end
      end
      on.construction(); parcours((API_TEST.menu()), "")
    """)
    g = L.globals()
    trop = [(m.titre, m.n) for m in g.MENUS_VUS.values() if m.n > 9]
    print("   %d menus, le plus long : %d entrees%s" % (len(g.MENUS_VUS), max(m.n for m in g.MENUS_VUS.values()),
                                                       "" if not trop else " ; TROP LONGS : %s" % trop))
    if trop:
        echec("menus de plus de 9 entrees : %s" % trop)
    libs = [(f.ch, f.lib) for f in g.FEUILLES.values()]
    longs = [(c, l) for c, l in libs if len(l) > 42]
    print("   %d feuilles ; libelle le plus long : %d caracteres%s" % (len(libs), max(len(l) for _, l in libs),
                                                                    "" if not longs else " ; > 42 : %s" % longs))
    # chaque feuille : ouverture depuis le menu principal par ses chiffres, questions par defaut jusqu'au document
    err = 0
    for ch, lib in libs:
        Lf = charger(NOUVEAU.read_text(encoding="utf-8"))
        chemin = [int(x) for x in ch.split("·")]
        out = sortie(lambda: test_pc.parcourir(Lf, chemin, list(SAISIES_FEUILLES.get(ch, []))))
        fin = out.strip().splitlines()[-1] if out.strip() else "rien"
        attendu_menu = lib.startswith("Historique")      # l'historique ouvre une liste (menu), pas une question
        if "EXCEPTION PYTHON" in out or (fin.startswith("(menu") and not attendu_menu) or fin.startswith("(arret"):
            err += 1
            echec("feuille %s « %s » : %s" % (ch, lib, fin))
    print("   %d feuilles ouvertes par leurs chiffres et menees au resultat (valeurs par defaut), %d erreur(s)" % (len(libs), err))
    # esc : depuis un sous-sous-menu, retour d'un seul niveau
    Lf = charger(NOUVEAU.read_text(encoding="utf-8"))
    api = Lf.globals().API_TEST
    api.choisir(7); api.choisir(9)
    t1 = api.menu()[0].titre
    Lf.execute("on.escapeKey()")
    t2 = api.menu()[0].titre
    print("   esc depuis « %s » -> « %s »" % (t1, t2))
    if t2 != "Vecteurs (séries 4 à 6)":
        echec("esc ne remonte pas d'un niveau (%s -> %s)" % (t1, t2))


def verifier_index(L):
    L.execute(r"""
      IDX_PB = {}
      for k, e in ipairs(INDEX_SOLVEURS) do
        on.construction()
        local m, it = (API_TEST.menu()), nil
        for c in e.chemin:gmatch("%d+") do
          it = m.items[tonumber(c)]
          if not it then break end
          if it.sous then m = it.sous end
        end
        if not it then table.insert(IDX_PB, e.chemin .. " : chemin inexistant")
        elseif it[1] ~= e.titre then table.insert(IDX_PB, e.chemin .. " : libelle " .. it[1] .. " ~= " .. e.titre)
        elseif it[2] ~= e.ouvrir then table.insert(IDX_PB, e.chemin .. " : ouvrir ne correspond pas a l'action du menu") end
        if type(e.forts) ~= "table" or #e.forts == 0 then table.insert(IDX_PB, e.chemin .. " : forts vide") end
        for _, w in ipairs(e.forts) do if w:find("[^a-z0-9]") then table.insert(IDX_PB, e.chemin .. " : mot fort non normalise " .. w) end end
        for _, w in ipairs(e.mots) do if w:find("[^a-z0-9]") then table.insert(IDX_PB, e.chemin .. " : mot non normalise " .. w) end end
        local n = 0; for _ in (e.si or ""):gmatch("[^\128-\191]") do n = n + 1 end
        if n > 45 then table.insert(IDX_PB, e.chemin .. " : si trop long (" .. n .. ")") end
      end
    """)
    g = L.globals()
    pb = list(g.IDX_PB.values())
    print("   index : %d entrees, %d probleme(s)" % (len(g.INDEX_SOLVEURS), len(pb)))
    for p in pb:
        echec("index " + p)


def verifier_recherche(L):
    if L.globals().CHERCHE is None:
        print("   (moteur de recherche absent du socle : test de recherche saute)")
        return
    tete = trois = 0
    for txt, attendu in CONSIGNES:
        res = L.globals().CHERCHE.chercher(txt)
        chs = [res[i].chemin for i in range(1, min(3, len(res)) + 1)]
        tete += bool(chs) and chs[0] == attendu
        trois += attendu in chs
        if attendu not in chs:
            echec("recherche « %s » : %s attendu, obtenu %s" % (txt, attendu, chs))
        elif VERBEUX or chs[0] != attendu:
            print("   « %s » -> %s (attendu %s)" % (txt, chs, attendu))
    print("   recherche : %d / %d en tete, %d / %d dans les 3 premiers" % (tete, len(CONSIGNES), trois, len(CONSIGNES)))


def verifier_nouveaux(src):
    def doc(nom, args):
        L = charger(src)
        out, _ = appeler(L, nom, args)
        return out
    # test 2025 P3 c (corrige-prof.md p.2) : ||AB x AG|| = 8, ||AB x BE|| = 4, aire 28 u.a.
    out = doc("aireFigure", ["A=-1,4;B=1,4;C=3,0;D=1,0;E=0,2;F=-1,0;G=-3,0;H=-1,-4;I=1,-4;J=0,-2",
                             "4*par(A,B,G)-2*tri(A,B,E)", "A,B,C,I,H,G-E,D,J,F"])
    attendus = ["AB=[1-(-1),4-4]=[2,0]", "||AB × AG|| = |2·(-4) − 0·(-2)| = |-8| = 8", "Aire(ABFG) = 8 u.a.",
                "||AB × AE|| = |2·(-2) − 0·1| = |-4| = 4", "Aire(ABE) = 1/2*4=2 u.a.", "4Aire(ABFG) − 2Aire(ABE)", "4*8-2*2=28 u.a.",
                "Contour ABCIHG : Aire = 32 u.a.", "Trou EDJF : Aire = 4 u.a.", "Lacets : Aire = 28 u.a.  ✓"]
    controle("aire du logo (T25 P3 c)", out, attendus)
    out = doc("aireFigure", ["A(0;0);B(4;0);C(4;3)", "", "A,B,C"])
    controle("aire par lacets seuls", out, ["Aire = 6 u.a."])
    # serie 7 ex.6 (corrige-exo06.md) : sommet (-1/2 ; 7/4) ; [-1;1] max f(1)=4 ; [-3;-2] max f(-3)=8, min f(-2)=4
    out = doc("minMaxTrinome", ["x^2+x+2", "R;[-1,1];[-3,-2]"])
    controle("min/max S7 ex.6", out, [
        "x_S = -b/(2a)=-1/(2*1)=-1/2", "f(-1/2)=(-1/2)^2+(-1/2)+2=7/4", "Sommet S(-1/2 ; 7/4)",
        "a) sur ℝ", "Il n'y a pas de maximum (f(x) → +∞", "Il y a un minimum (global) en (-1/2 ; 7/4)",
        "b) sur [-1 ; 1]", "f(1)=1^2+1+2=4", "Il y a un maximum (local) en x = 1, de valeur f(1) = 4",
        "c) sur [-3 ; -2]", "f(-3)=(-3)^2+(-3)+2=8", "Il y a un maximum (local) en x = -3, de valeur f(-3) = 8",
        "Il y a un minimum (local) en x = -2, de valeur f(-2) = 4"])
    out = doc("minMaxTrinome", ["-2x^2+4x-1", "]0,3[;[2,+inf["])
    controle("min/max a < 0, bornes ouvertes", out, [
        "Sommet S(1 ; 1)", "Il y a un maximum (global) en (1 ; 1)", "Il n'y a pas de minimum : la valeur f(3) = -7", "Il y a un maximum (local) en x = 2",
        "Il y a un maximum (local) en x = 2, de valeur f(2) = -1", "Il n'y a pas de minimum (f(x) → −∞"])


def controle(nom, out, attendus):
    manque = [a for a in attendus if a not in out]
    if "ERREUR LUA" in out or "Erreur" in out.split("\n")[1:2]:
        echec(nom + " : erreur Lua\n" + out)
    elif manque:
        echec(nom + " : manque " + " | ".join(manque) + ("\n" + out if VERBEUX else ""))
    else:
        print("   %s : OK (%d controles)" % (nom, len(attendus)))
    if VERBEUX:
        print(out)


if __name__ == "__main__":
    main()
