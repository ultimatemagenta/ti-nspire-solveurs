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
Recherche d'un solveur (index INDEX_SOLVEURS, moteur CHERCHE du socle) :
  python tools/nspire/test_pc.py APP.lua --cherche "max stock"
  - imprime les 5 premiers resultats (chemin, titre, score, ligne « si ») ; simule aussi la frappe dans un menu
    (lettres -> ecran « Trouver un solveur », dessin, ENTER sur le premier resultat) ;
  python tools/nspire/test_pc.py APP.lua --cherche-tout CONSIGNES.txt
  - fichier : une consigne par ligne « saisie ; chemin attendu » (# = commentaire) ; imprime le rang de chaque attendu,
    les totaux « en tete » et « dans les 3 premiers », et verifie que chaque chemin de l'index mene a son libelle de menu.
    Code de sortie 1 si un attendu sort des 3 premiers ou si un chemin d'index est faux.
Apres chaque document : controle du premier tableau (« TABLEAU OK » / « TABLEAU DEBORDE » pour une grille compacte,
c.-a-d. un tableau comparatif qui doit tenir sur le premier ecran sans defilement).
"""
import sys
import lupa

BOUCHONS = r"""
local noop = function() end
platform = {apiLevel = '2.4', window = {invalidate = noop, width = function() return 318 end, height = function() return 212 end}}
on = {}
math.evalStr = function() return nil end
unpack = unpack or table.unpack
math.log10 = math.log10 or function(x) return math.log(x, 10) end
local gcm = {}
gcm.__index = function(t, k)
  if k == "getStringWidth" then return function(_, s) return 6 * #tostring(s) end end
  if k == "getStringHeight" then return function() return math.floor((GC_TAILLE or 9) * 1.5 + 0.5) end end
  if k == "setFont" then return function(_, fam, st, t) GC_TAILLE = t end end
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
    if len(sys.argv) >= 4 and sys.argv[2] == "--cherche":
        return cherche(L, sys.argv[3])
    if len(sys.argv) >= 4 and sys.argv[2] == "--cherche-tout":
        sys.exit(chercheTout(L, sys.argv[1], sys.argv[3]))
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


def classement(L, texte):
    res = L.globals().API_TEST.chercher(texte)
    return [res[i] for i in range(1, len(res) + 1)]


def cherche(L, texte, n=5):
    res = classement(L, texte)
    print("Recherche « " + texte + " » : " + str(len(res)) + " resultat(s)")
    for k, r in enumerate(res[:n], 1):
        print("  %d. %-7s %-38s score %d" % (k, r.chemin, r.titre, r.score))
        print("              si : " + str(r.si or ""))
    # frappe simulee depuis le menu principal : lettres, dessin de l'ecran, ENTER
    api = L.globals().API_TEST
    lettres = [c for c in texte]
    if lettres and lettres[0].isalpha():
        for c in lettres:
            L.globals().on.charIn(c)
        L.execute("on.paint(GC)")
        e = api.recherche()
        print("(ecran " + str(api.ecran()) + ", saisie « " + str(e.txt) + " », " + str(len(e.res)) + " resultats, dessin OK)")
        if len(e.res) > 0:
            L.execute("on.enterKey()")
            L.execute("on.paint(GC)")
            m, _ = api.menu()
            print("(ENTER -> ecran " + str(api.ecran()) + ", menu « " + str(m.titre) + " »)")
            L.execute("on.escapeKey()")
            m, _ = api.menu()
            print("(esc -> ecran " + str(api.ecran()) + ", menu « " + str(m.titre) + " »)")


def verifierIndex(L, chemin_app):
    """Chaque entree d'INDEX_SOLVEURS : en rejouant son chemin dans les menus, retrouve-t-on son libelle ?"""
    idx = L.globals().INDEX_SOLVEURS
    faux = 0
    for i in range(1, len(idx) + 1):
        e = idx[i]
        L2 = neuf(chemin_app)
        api = L2.globals().API_TEST
        pas_ = [int(x) for x in str(e.chemin).split("·")]
        for p in pas_[:-1]:
            api.choisir(p)
        m, _ = api.menu()
        it = m["items"][pas_[-1]] if api.ecran() == "menu" else None
        lib = str(it[1]) if it is not None else "?"
        if lib != str(e.titre):
            faux += 1
            print("INDEX FAUX : " + str(e.chemin) + " « " + str(e.titre) + " » -> « " + lib + " »")
    print("index : " + str(len(idx)) + " entrees, " + str(faux) + " chemin(s) faux")
    return faux


def chercheTout(L, chemin_app, fichier):
    top1 = top3 = n = 0
    rates = []
    for ligne in open(fichier, encoding="utf-8"):
        ligne = ligne.strip()
        if not ligne or ligne.startswith("#") or ";" not in ligne:
            continue
        saisie, attendu = [x.strip() for x in ligne.rsplit(";", 1)]
        res = classement(L, saisie)
        chemins = [str(r.chemin) for r in res]
        rang = chemins.index(attendu) + 1 if attendu in chemins else 0
        n += 1
        top1 += rang == 1
        top3 += 1 <= rang <= 3
        marque = "ok " if rang == 1 else ("~%d " % rang if 1 <= rang <= 3 else "RATE")
        print("%s %-8s %-60s -> %s" % (marque, attendu, saisie[:60], ", ".join(chemins[:3])))
        if not 1 <= rang <= 3:
            rates.append(saisie)
    print("\nen tete : %d / %d ; dans les 3 premiers : %d / %d" % (top1, n, top3, n))
    faux = verifierIndex(L, chemin_app)
    return 1 if rates or faux else 0


def neuf(chemin_app):
    L = lupa.LuaRuntime(unpack_returned_tuples=True)
    L.execute(BOUCHONS)
    src = open(chemin_app, encoding="utf-8").read()
    L.eval("function(s) local f, e = load(s, 'app'); if not f then error(e) end; return f end")(src)()
    L.execute("if on.construction then on.construction() end")
    return L


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
    verifierTableau(L)


def verifierTableau(L):
    """Premier element « grille » du document : tient-il dans le premier ecran (318 x 212, bandeau 20 px, pied 16 px),
    vue ouverte en haut ? Largeur mesuree avec la police simulee du banc (6 px par octet, pessimiste).
    Grille compacte (tableau comparatif) : « TABLEAU OK » / « TABLEAU DEBORDE ». Grille ordinaire : simple information."""
    api = L.globals().API_TEST
    doc = api.doc()
    haut = api.vue().haut or 0
    for i in range(1, len(doc) + 1):
        e = doc[i]
        if e.k != "grille":
            continue
        y, hg = int(e._y or 0), int(e._h or 0)
        bas = y + hg
        if not e.compact:
            print("(tableau 1 : grille ordinaire, y " + str(y) + " -> " + str(bas) + " px"
                  + ("" if bas <= 196 else ", hors du premier ecran") + ")")
            return
        c = e._L
        ok = bas <= 212 - 16 and not c.deborde and haut == 0
        print("TABLEAU " + ("OK" if ok else "DEBORDE") + " : " + str(int(c.ncol)) + " colonnes + libelles, "
              + "largeur necessaire " + str(int(c.tot)) + " / 314 px, hauteur " + str(hg) + " px, y " + str(y) + " -> " + str(bas)
              + " (limite 196), police " + str(int(c.f)) + ", lignes " + str(int(c.rh)) + " px, "
              + str(int(c.nr)) + " lignes dont en-tete, vue en haut : " + ("oui" if haut == 0 else "non"))
        return


if __name__ == "__main__":
    main()
