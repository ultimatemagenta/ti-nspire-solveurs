# parametre : equation a parametre m et changement de variable (serie 2)
# Lancer : run parametre
from m1outils import *

def _carre_parfait(D):
    """D polynome en m : renvoie s tel que s^2 = D, sinon None."""
    if D.nul():
        return P([], D.v)
    if D.deg() % 2 or D.dom() < 0:
        return None
    if D.deg() == 0:
        r = racine(D.dom())
        return P([r.a], D.v) if r.exact() else None
    if D.deg() == 2:
        r = racine(D.dom())
        if not r.exact():
            return None
        p = r.a; q = D.coef(1) / (2 * p)
        s = P([q, p], D.v)
        return s if s * s == D else None
    return None

def _sub_m(p, m):
    """valeur du polynome en m pour m fraction."""
    return p.val(m)

def e_parametre():
    titre("Équation a(m)x² + b(m)x + c(m) = 0")
    print("Identifie d'abord a, b, c (fonctions")
    print("de m) : regroupe les termes en x², x, 1.")
    a = demander("a(m) = ", "m", poly=True)
    b = demander("b(m) = ", "m", poly=True)
    c = demander("c(m) = ", "m", poly=True)
    print("(" + str(a) + ")x² + (" + str(b) + ")x + (" + str(c) + ") = 0")
    print("")
    print("1) Cas particulier a(m) = 0 : l'équation")
    print("n'est plus du 2nd degré (Δ interdit).")
    print("   OUBLI PÉNALISÉ au test.")
    ra = racines(a)[0] if a.deg() >= 1 else []
    if a.deg() < 1:
        print("   a = " + str(a) + " ne s'annule jamais.")
    for r in ra:
        if not r.val.exact():
            print("   m = " + str(r.val) + " : a = 0 (à traiter à la main)")
            continue
        m0 = r.val.a
        bv = _sub_m(b, m0); cv = _sub_m(c, m0)
        print("   m = " + str(m0) + " : " + str(bv) + "x + " + entre_par(cv) + " = 0")
        if not bv.nul():
            print("     → x = " + str(-cv / bv) + " (une solution)")
        elif cv.nul():
            print("     → 0 = 0 : tout x est solution")
        else:
            print("     → " + str(cv) + " = 0 impossible : S = ∅")
    print("")
    D = b * b - a * c * 4
    print("2) Cas a(m) ≠ 0 : Δ(m) = b² - 4ac")
    print("Δ(m) = (" + str(b) + ")² - 4(" + str(a) + ")(" + str(c) + ")")
    print("     = " + str(D))
    s = _carre_parfait(D)
    if D.deg() <= 0:
        print("Δ ne dépend pas de m.")
    rD, fD, _ = racines(D) if D.deg() >= 1 else ([], [], None)
    if D.deg() >= 1:
        lignes = [("Δ(m)", lambda m: D.valf(m), [r.val for r in rD])]
        bornes, sg = tableau_signes(lignes, [fl(r) for r in ra], "m")
        print("Lecture :")
        print(" Δ>0 : 2 solutions ; Δ=0 : 1 double ;")
        print(" Δ<0 : aucune (en excluant les m où a=0).")
        for r in rD:
            if r.val.exact():
                m0 = r.val.a
                if _sub_m(a, m0).nul():
                    continue
                x0 = -_sub_m(b, m0) / (2 * _sub_m(a, m0))
                print(" m = " + str(m0) + " : Δ = 0, x = -b/(2a) = " + str(x0))
    else:
        d0 = D.coef(0)
        print("Δ = " + str(d0) + (" > 0 : toujours 2 solutions" if d0 > 0 else (" = 0 : racine double" if d0.nul() else " < 0 : aucune solution")))
    print("")
    print("3) Solutions (si a ≠ 0, Δ ≥ 0) :")
    if s is not None:
        print("Δ = (" + str(s) + ")² : carré parfait,")
        print("donc pas de racine à garder.")
        x1 = F(-b + s, a * 2, "m").simplifiee()[0]
        x2 = F(-b - s, a * 2, "m").simplifiee()[0]
        print("x1 = (-b + √Δ)/(2a) = " + str(x1))
        print("x2 = (-b - √Δ)/(2a) = " + str(x2))
    else:
        print("x = (" + str(-b) + " ± √(" + str(D) + "))/(2(" + str(a) + "))")
    print("Contrôle CAS : solve(équation, x)")

def e_changement():
    titre("Changement de variable")
    print("Pourquoi : une équation compliquée en x")
    print("devient un 2nd degré en X. On résout en")
    print("X, puis on revient à x (étape oubliée")
    print("= solution fausse).")
    print("1 X = x²   (bicarrée, X ≥ 0)")
    print("2 X = √x   (X ≥ 0, x = X²)")
    print("3 X = x^(1/3) (tout X, x = X³)")
    print("4 X = 1/x  (X ≠ 0, x = 1/X)")
    print("5 X = (αx+β)/(γx+δ) (homographique)")
    t = input("Type : ").strip()
    print("Équation en X (polynôme) :")
    q = demander("Q(X) = 0 avec Q(X) = ", "X", poly=True)
    rs = racines(q)[0]
    print("Q(X) = " + str(q) + " ; racines en X :")
    if not rs:
        print("  aucune → S = ∅")
        return
    sol = []
    al = be = ga = de = None
    if t == "5":
        al = demander_nombre("α = "); be = demander_nombre("β = ")
        ga = demander_nombre("γ = "); de = demander_nombre("δ = ")
        print("X = (αx+β)/(γx+δ) ⟺ X(γx+δ) = αx+β")
        print("⟺ x(γX - α) = β - δX ⟺ x = (β - δX)/(γX - α)")
        if not ga.nul():
            print("X = α/γ = " + str(al / ga) + " n'est jamais atteint.")
    for r in rs:
        X = r.val
        lab = "  X = " + avec_approx(X)
        if t == "1":
            if fl(X) < 0:
                print(lab + " < 0 : REJETÉE (X = x² ≥ 0)")
            elif fl(X) == 0:
                print(lab + " : x = 0"); sol.append("0")
            else:
                if X.exact():
                    rx = racine(X.a)
                    print(lab + " : x² = " + str(X) + " → x = ±" + str(rx))
                    sol += ["-" + str(rx), str(rx)]
                else:
                    print(lab + " : x = ±√(" + str(X) + ")")
                    sol += ["-√(" + str(X) + ")", "√(" + str(X) + ")"]
        elif t == "2":
            if fl(X) < 0:
                print(lab + " < 0 : REJETÉE (√x ≥ 0)")
            else:
                v = X.a * X.a if X.exact() else None
                print(lab + " : x = X² = " + (str(v) if v is not None else "(" + str(X) + ")²"))
                sol.append(str(v) if v is not None else "(" + str(X) + ")²")
        elif t == "3":
            v = X.a ** 3 if X.exact() else None
            print(lab + " : x = X³ = " + (str(v) if v is not None else "(" + str(X) + ")³"))
            sol.append(str(v) if v is not None else "(" + str(X) + ")³")
        elif t == "4":
            if fl(X) == 0:
                print(lab + " : REJETÉE (1/x ≠ 0)")
            else:
                v = Q(1) / X.a if X.exact() else None
                print(lab + " : x = 1/X = " + (str(v) if v is not None else "1/(" + str(X) + ")"))
                sol.append(str(v) if v is not None else "1/(" + str(X) + ")")
        elif t == "5":
            if not X.exact():
                print(lab + " : x = (β - δX)/(γX - α) à la main")
                continue
            Xv = X.a
            den = ga * Xv - al
            if den.nul():
                print(lab + " : REJETÉE (X = α/γ inatteignable)")
            else:
                v = (be - de * Xv) / den
                print(lab + " : x = " + str(v))
                sol.append(str(v))
        else:
            print(lab)
    print("Pense au domaine de départ en x et")
    print("vérifie en remplaçant (CAS : |x=…).")
    print("S = {" + " ; ".join(sol) + "}" if sol else "S = ∅")

def menu():
    while True:
        effacer()
        print("Paramètre, changement de variable")
        print("1 équation à paramètre m")
        print("2 changement de variable  0 quitter")
        c = input("Choix : ").strip()
        if c in ("0", "q", ""):
            return
        if c == "1":
            e_parametre()
        elif c == "2":
            e_changement()
        voir()
