# vecteurs : calcul vectoriel exact (series 4 a 6, chap. 1 du poly)
# Lancer : run vecteurs
from m1outils import *
import math

def lire_vect(msg):
    while True:
        t = demander_txt_memo(msg, "v").strip().replace("[", "").replace("]", "").replace("(", "").replace(")", "").replace(";", ",")
        try:
            parts = [x for x in t.split(",") if x.strip() != ""]
            if len(parts) not in (2, 3):
                raise ValueError("2 ou 3 composantes")
            out = []
            for x in parts:
                f = lire(x)
                if f.num.deg() > 0 or f.den.deg() > 0:
                    raise ValueError("nombre attendu")
                out.append(f.num.coef(0) / f.den.coef(0))
            return out
        except Exception as e:
            print("Pas compris (" + str(e) + "). Ex. : 2,-1,3")

def vs(u):
    return "(" + " ; ".join(str(x) for x in u) + ")"

def scal(u, v):
    r = Q(0)
    for a, b in zip(u, v):
        r = r + a * b
    return r

def detail_scal(u, v):
    return " + ".join(entre_par(a) + "·" + entre_par(b) for a, b in zip(u, v))

def n2(u):
    return scal(u, u)

def norme(u):
    return racine(n2(u))

def vect(u, v):
    return [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]

def trois(u):
    if len(u) == 2:
        return [u[0], u[1], Q(0)]
    return u

def cos_exact(u, v):
    """cos(u,v) exact (R)."""
    ps = scal(u, v)
    rr = racine(n2(u) * n2(v))  # = b*sqrt(r)
    return div_rac(ps, rr)

ANGLES = [("1", 0, "0"), ("√3/2", 30, "π/6"), ("√2/2", 45, "π/4"), ("1/2", 60, "π/3"), ("0", 90, "π/2"),
          ("-1/2", 120, "2π/3"), ("-√2/2", 135, "3π/4"), ("-√3/2", 150, "5π/6"), ("-1", 180, "π")]

def e_norme():
    titre("Norme et vecteur unitaire")
    u = lire_vect("u = ")
    print("Formule : ‖u‖ = √(somme des carrés)")
    print("‖u‖ = √(" + " + ".join(entre_par(a) + "²" for a in u) + ")")
    print("    = √(" + str(n2(u)) + ") = " + avec_approx(norme(u)))
    if n2(u).nul():
        print("Vecteur nul : pas de vecteur unitaire.")
        return
    nu = norme(u)
    print("Unitaire : û = u/‖u‖ (même direction,")
    print("même sens, norme 1).")
    comp = []
    for a in u:
        # a / (b sqrt r) = a sqrt r /(b r)
        comp.append(str(div_rac(a, nu)))
    print("û = (" + " ; ".join(comp) + ")")

def e_scalaire():
    titre("Produit scalaire et angle")
    u = lire_vect("u = "); v = lire_vect("v = ")
    ps = scal(u, v)
    print("u·v = " + detail_scal(u, v) + " = " + str(ps))
    if ps.nul():
        print("u·v = 0 ⟺ u ⊥ v (orthogonaux)")
    print("Formule : cos θ = u·v / (‖u‖·‖v‖)")
    print("‖u‖ = " + avec_approx(norme(u)) + " ; ‖v‖ = " + avec_approx(norme(v)))
    if n2(u).nul() or n2(v).nul():
        print("Vecteur nul : angle non défini.")
        return
    c = cos_exact(u, v)
    print("cos θ = " + str(ps) + "/√(" + str(n2(u) * n2(v)) + ") = " + avec_approx(c))
    for txt, deg, rad in ANGLES:
        if str(c) == txt:
            print("Valeur connue : θ = " + str(deg) + "° = " + rad)
            return
    t = math.acos(max(-1.0, min(1.0, fl(c))))
    print("θ = arccos(" + str(c) + ") ≈ " + approx((t * 180 / math.pi), 2) + "° ≈ " + approx(t, 4) + " rad")
    print("(calculatrice en mode degrés/radians !)")

def e_projection():
    titre("Projection orthogonale de u sur v")
    u = lire_vect("u = "); v = lire_vect("v (direction) = ")
    if n2(v).nul():
        print("v nul : projection impossible.")
        return
    ps = scal(u, v); nv = n2(v)
    print("Formule : proj_v(u) = (u·v / ‖v‖²)·v")
    print("Pourquoi ‖v‖² : on divise une fois pour")
    print("rendre v unitaire, une fois pour la mesure.")
    print("u·v = " + detail_scal(u, v) + " = " + str(ps))
    print("‖v‖² = " + str(nv))
    k = ps / nv
    print("coefficient = " + str(ps) + "/" + str(nv) + " = " + str(k))
    p = [k * a for a in v]
    print("proj_v(u) = " + str(k) + "·" + vs(v) + " = " + vs(p))
    print("Mesure algébrique : u·v/‖v‖ = " + avec_approx(div_rac(ps, norme(v))))
    w = [a - b for a, b in zip(u, p)]
    print("Composante orthogonale u - proj = " + vs(w))
    print("Contrôle : (u - proj)·v = " + str(scal(w, v)) + " (doit être 0)")

def e_vectoriel():
    titre("Produit vectoriel u × v")
    u = trois(lire_vect("u = ")); v = trois(lire_vect("v = "))
    w = vect(u, v)
    print("Formule (déterminants 2×2, en croix) :")
    print("x : " + entre_par(u[1]) + "·" + entre_par(v[2]) + " - " + entre_par(u[2]) + "·" + entre_par(v[1]) + " = " + str(w[0]))
    print("y : " + entre_par(u[2]) + "·" + entre_par(v[0]) + " - " + entre_par(u[0]) + "·" + entre_par(v[2]) + " = " + str(w[1]))
    print("z : " + entre_par(u[0]) + "·" + entre_par(v[1]) + " - " + entre_par(u[1]) + "·" + entre_par(v[0]) + " = " + str(w[2]))
    print("u × v = " + vs(w))
    print("Contrôles : (u×v)·u = " + str(scal(w, u)) + ", (u×v)·v = " + str(scal(w, v)) + " (0 et 0)")
    if all(x.nul() for x in w):
        print("u × v = 0 ⟺ u et v colinéaires.")
    else:
        print("Aire du parallélogramme = ‖u×v‖ = " + avec_approx(norme(w)))
        a2 = mul_rac(Q(1, 2), norme(w))
        print("Aire du triangle = ‖u×v‖/2 = " + avec_approx(a2))

def e_mixte():
    titre("Produit mixte [a ; b ; c]")
    a = trois(lire_vect("a = ")); b = trois(lire_vect("b = ")); c = trois(lire_vect("c = "))
    w = vect(b, c)
    print("Définition : [a;b;c] = a·(b × c)")
    print("b × c = " + vs(w))
    m = scal(a, w)
    print("a·(b×c) = " + detail_scal(a, w) + " = " + str(m))
    if m.nul():
        print("[a;b;c] = 0 ⟺ a, b, c coplanaires")
        print("(pas une base).")
    else:
        print("≠ 0 : a, b, c forment une base,")
        print("directe si > 0, indirecte si < 0 : " + ("DIRECTE" if m > 0 else "INDIRECTE"))
        print("Volume du parallélépipède = |[a;b;c]| = " + str(m if m > 0 else -m))
        print("Volume du tétraèdre = |[a;b;c]|/6 = " + str((m if m > 0 else -m) / 6))

def e_bon():
    titre("Base orthonormée directe ?")
    a = trois(lire_vect("a = ")); b = trois(lire_vect("b = ")); c = trois(lire_vect("c = "))
    ok = True
    print("1) Normée : chaque norme vaut 1")
    for nom, u in (("a", a), ("b", b), ("c", c)):
        n = n2(u)
        print("  ‖" + nom + "‖² = " + str(n) + (" ✓" if n == 1 else " ✗"))
        ok = ok and n == 1
    print("2) Orthogonale : produits scalaires nuls")
    for nom, u, v in (("a·b", a, b), ("a·c", a, c), ("b·c", b, c)):
        s = scal(u, v)
        print("  " + nom + " = " + str(s) + (" ✓" if s.nul() else " ✗"))
        ok = ok and s.nul()
    m = scal(a, vect(b, c))
    print("3) Directe : [a;b;c] = " + str(m) + (" > 0 ✓" if m > 0 else " ✗"))
    if ok and m == 1:
        print("BON directe (et c = a × b = " + vs(vect(a, b)) + ")")
    elif ok:
        print("BON mais INDIRECTE.")
    else:
        print("Pas une BON (voir les ✗).")

def e_colineaires():
    titre("Colinéarité / coplanarité")
    u = trois(lire_vect("u = ")); v = trois(lire_vect("v = "))
    w = vect(u, v)
    print("u × v = " + vs(w))
    if all(x.nul() for x in w):
        print("u × v = 0 : u et v sont colinéaires.")
        for a, b in zip(u, v):
            if not b.nul():
                print("u = " + str(a / b) + "·v")
                break
    else:
        print("u × v ≠ 0 : pas colinéaires.")

def menu():
    while True:
        effacer()
        print("Vecteurs (composantes : 2,-1,3)")
        print("1 norme, unitaire  2 scalaire, angle")
        print("3 projection  4 vectoriel, aire")
        print("5 mixte, volume  6 BON directe ?")
        print("7 colinéaires ?  0 quitter")
        c = input("Choix : ").strip()
        if c in ("0", "q", ""):
            return
        f = {"1": e_norme, "2": e_scalaire, "3": e_projection, "4": e_vectoriel,
             "5": e_mixte, "6": e_bon, "7": e_colineaires}.get(c)
        if f:
            f()
            voir()
