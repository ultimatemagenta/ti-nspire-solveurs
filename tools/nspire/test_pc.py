"""Execute une application Lua TI-Nspire sur PC (sans calculatrice) avec lupa et des bouchons.

Usage : python tools/nspire/test_pc.py APP.lua NOM_SOLVEUR [arg1 arg2 ...]
  - charge le script assemble (cree par construire_app.py) ;
  - simule on.construction, puis appelle SOLVEURS_GLOBAL[NOM_SOLVEUR](args) ;
  - imprime le document de resultats (titres, textes, grilles) en texte ;
  - simule aussi un on.paint complet du document (detecte les erreurs de dessin).
Le calcul formel (math.evalStr) n'est pas disponible : il renvoie nil.
Sans NOM_SOLVEUR : liste les solveurs exposes.

Mode menu (suite de saisies, comme sur la calculatrice) :
  python tools/nspire/test_pc.py APP.lua --menu 4,1 [saisie1 saisie2 ...]
  - choisit les entrees 4 puis 1 dans les menus, puis repond aux questions successives (demander) ;
  - « = » : ENTER sans rien changer (garde la valeur pre-remplie) ; « "" » : champ vide ;
  - saisies epuisees : ENTER sur chaque question restante (valeurs par defaut), 400 questions au plus ;
  - chaque question est imprimee (bandeau, question, aide, note, texte pre-rempli) ; « DEBORDE » si le texte
    ne tient pas a l'ecran (318 x 212, police simulee a 6 px par octet, donc pessimiste).
"""
import sys
import lupa

BOUCHONS = r"""
local noop = function() end
platform = {apiLevel = '2.4', window = {invalidate = noop, width = function() return 318 end, height = function() return 212 end}}
on = {}
math.evalStr = function() return nil end
local gcm = {}
gcm.__index = function(t, k)
  if k == "getStringWidth" then return function(_, s) return 6 * #tostring(s) end end
  if k == "getStringHeight" then return function() return 12 end end
  return noop
end
GC = setmetatable({}, gcm)
"""


def main():
    if len(sys.argv) < 2:
        print(__doc__); sys.exit(1)
    L = lupa.LuaRuntime(unpack_returned_tuples=True)
    L.execute(BOUCHONS)
    src = open(sys.argv[1], encoding="utf-8").read()
    f = L.eval("function(s) local f, e = load(s, 'app'); if not f then error(e) end; return f end")(src)
    f()
    L.execute("if on.construction then on.construction() end")
    sol = L.globals().SOLVEURS_GLOBAL
    if len(sys.argv) >= 4 and sys.argv[2] == "--menu":
        return parcourir(L, [int(x) for x in sys.argv[3].split(",")], sys.argv[4:])
    if len(sys.argv) == 2:
        print("Solveurs :", sorted(k for k in sol.keys()))
        return
    nom = sys.argv[2]
    args = sys.argv[3:]
    fn = sol[nom]
    if fn is None:
        print("Solveur inconnu :", nom); sys.exit(2)
    fn(*args)
    imprimer(L)


def parcourir(L, chemin, saisies):
    api = L.globals().API_TEST
    for i in chemin:
        api.choisir(i)
    n = 0
    while api.ecran() == "saisie" and n < 400:
        n += 1
        sa = api.saisie()
        L.execute("on.paint(GC)")
        print("\n--- [" + str(sa.titre or "Saisie") + "] " + str(sa.msg)
              + ("   ** DEBORDE **" if sa.deborde else ""))
        for k in ("aide", "erreur", "note"):
            if sa[k]:
                print("    " + k + " : " + str(sa[k]))
        rep = saisies.pop(0) if saisies else "="
        print("    pre-rempli : " + repr(str(sa.txt)) + ("" if rep == "=" else "   -> saisi : " + repr(rep)))
        api.entrer(None if rep == "=" else rep)
    if api.ecran() == "saisie":
        print("\n(arret : trop de questions)")
        return
    if api.ecran() == "menu":
        m, sel = api.menu()
        print("\n(menu : " + str(m.titre) + ")")
        return
    imprimer(L)


def imprimer(L):
    doc = L.globals().API_TEST.doc()
    for i in range(1, len(doc) + 1):
        e = doc[i]
        k = e.k
        if k == "titre":
            print("\n== " + str(e.s))
        elif k in ("txt", "gris", "alerte"):
            print(("! " if k == "alerte" else "") + str(e.s))
        elif k in ("math", "res"):
            print(("=> " if k == "res" else "   ") + (e.avant or "") + str(e.s or "") + (e.apres or ""))
        elif k == "grille":
            print("[" + str(e.titre) + "]")
            ent = e.opts.entetes
            if ent:
                print("   " + " | ".join(str(ent[j]) for j in range(1, len(ent) + 1)))
            for j in range(1, len(e.lignes) + 1):
                l = e.lignes[j]
                print("   " + " | ".join(str(l[c]) for c in range(1, len(l) + 1)) + ("   (gras)" if l.gras else ""))
        else:
            print("<" + str(k) + ">")
    L.execute("on.paint(GC)")
    print("\n(dessin simule : OK)")


if __name__ == "__main__":
    main()
