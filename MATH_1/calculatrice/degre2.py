# degre2 : 2nd degre, factorisation, inequations (series 1 a 3)
# Lancer : run degre2
from m1outils import *
import facto

def e_trinome():
    titre("Trinôme ax²+bx+c")
    p = demander("p(x) = ", poly=True)
    if p.deg() != 2:
        print("Degré " + str(p.deg()) + " : utilise 2 (factoriser).")
        return
    a, b, c = p.c[2], p.c[1], p.c[0]
    print("a = " + str(a) + ", b = " + str(b) + ", c = " + str(c))
    D = b * b - 4 * a * c
    print("Formule : Δ = b² - 4ac")
    print("Δ = " + entre_par(b) + "² - 4·" + entre_par(a) + "·" + entre_par(c) + " = " + str(D))
    rs = racines(p)[0]
    if D > 0:
        print("Δ > 0 : deux racines x = (-b ± √Δ)/(2a)")
        print("√Δ = " + str(racine(D)))
        for r in rs:
            print("  x = " + avec_approx(r.val))
        print("p(x) = " + ("" if a == 1 else entre_par(a)) + "(x - x1)(x - x2)")
        print("     = " + ecrire_facto(p, racines(p)[1]))
    elif D.nul():
        print("Δ = 0 : racine double x = -b/(2a) = " + str(-b / (2 * a)))
        print("p(x) = " + ecrire_facto(p, racines(p)[1]))
    else:
        print("Δ < 0 : aucune racine réelle,")
        print("p ne se factorise pas dans ℝ ;")
        print("p a partout le signe de a (" + ("+" if a > 0 else "-") + ").")
    al = -b / (2 * a); be = p.val(al)
    print("Sommet S(-b/(2a) ; p(-b/(2a))) = (" + str(al) + " ; " + str(be) + ")")
    ca = "" if a == 1 else ("-" if a == -1 else entre_par(a))
    print("Forme canonique : p(x) = " + ca + "(x" + plus_moins(-al) + ")²" + plus_moins(be))
    if a > 0:
        print("a > 0 : parabole ∪, MINIMUM " + str(be) + " en x = " + str(al))
    else:
        print("a < 0 : parabole ∩, MAXIMUM " + str(be) + " en x = " + str(al))
    if rs:
        print("Somme des racines -b/a = " + str(-b / a) + ", produit c/a = " + str(c / a))
    print("Signe : du signe de a à l'extérieur")
    print("des racines, du signe opposé entre.")

def e_factoriser():
    titre("Factoriser un polynôme")
    p = demander("p(x) = ", poly=True)
    rs, fa, inc = racines(p)
    print("Méthode (deg 3) : chercher une racine")
    print("évidente r parmi les diviseurs du terme")
    print("constant / diviseurs du dominant ; puis")
    print("p(x) = (x - r)·q(x), q par division")
    print("en potence ou identification.")
    z = entiers(p)
    if p.deg() >= 3:
        for r in rs:
            if r.val.exact():
                rv = r.val.a
                print("Essai : p(" + str(rv) + ") = " + str(p.val(rv)) + " → racine")
                q, reste = p.divmod(P([-rv, 1]))
                print("p(x) = (" + str(P([-rv, 1])) + ")·(" + str(q) + ")")
                break
    print("Factorisation : " + ecrire_facto(p, fa))
    for r in rs:
        print("  racine " + avec_approx(r.val) + (" (ordre " + str(r.ordre) + ")" if r.ordre > 1 else ""))
    if inc is not None:
        print("Facteur " + str(inc) + " sans racine rationnelle :")
        print("racines approchées seulement.")

def e_diviser():
    titre("Division en potence A ÷ B")
    A = demander("A(x) = ", poly=True)
    B = demander("B(x) = ", poly=True)
    q, r = A.divmod(B)
    print("A = B·Q + R avec deg R < deg B")
    print("Q = " + str(q))
    print("R = " + str(r))
    if r.nul():
        print("Reste nul : B divise A.")
    print("Contrôle : B·Q + R = " + str(B * q + r))

def _intervalles(bornes, sg, noms, garder, fermes, interdits):
    parts = []
    n = len(bornes)
    i = 0
    while i <= n:
        if sg[i] in garder:
            j = i
            while j < n and sg[j + 1] in garder and not any(abs(bornes[j] - x) < 1e-9 for x in interdits) and (bornes[j] in fermes):
                j += 1
            g = None if i == 0 else bornes[i - 1]
            d = None if j == n else bornes[j]
            gs = "]-∞" if g is None else (("[" if g in fermes else "]") + noms[g])
            ds = "+∞[" if d is None else (noms[d] + ("]" if d in fermes else "["))
            parts.append(gs + " ; " + ds)
            i = j + 1
        else:
            i += 1
    for k in range(n):
        b = bornes[k]
        if b in fermes and sg[k] not in garder and sg[k + 1] not in garder:
            parts.append("{" + noms[b] + "}")
    return parts

def e_inequation():
    titre("Inéquation (tableau de signes)")
    print("Forme : gauche OP droite, OP parmi")
    print("<  <=  >  >=")
    g = demander("gauche = ")
    op = ""
    while op not in ("<", "<=", ">", ">="):
        op = input("OP = ").strip().replace("≤", "<=").replace("≥", ">=")
    d = demander("droite = ")
    print("Méthode : tout passer à gauche, réduire")
    print("au même dénominateur, factoriser, puis")
    print("tableau de signes. JAMAIS multiplier par")
    print("une expression de signe inconnu.")
    f0 = g - d
    rs0 = racines(f0.den)[0]
    fs, cm = f0.simplifiee()
    print(str(g) + " - (" + str(d) + ") " + op + " 0")
    print("⟺ " + str(fs) + " " + op + " 0")
    if rs0:
        print("Valeurs interdites : " + ", ".join(str(r.val) for r in rs0))
    rn, fn, _ = racines(fs.num)
    rd, fd, _ = racines(fs.den)
    k = constante(fs, fn, fd)
    lignes = facteurs_lignes(fn, fd, k)
    lignes.append(("total", lambda x: fs.num.valf(x) / fs.den.valf(x) if abs(fs.den.valf(x)) > 1e-15 else 0.0, [r.val for r in rs0]))
    print("Lignes : " + ", ".join(l[0] for l in lignes[:-1]))
    inter = [fl(r) for r in rs0]
    bornes, sg = tableau_signes(lignes, inter)
    noms = {}
    for r in rn + rd + rs0:
        noms[fl(r)] = str(r.val)
    for b in bornes:
        if b not in noms:
            noms[b] = approx(b)
    garder = ("-",) if op in ("<", "<=") else ("+",)
    fermes = []
    if op in ("<=", ">="):
        for r in rn:
            f = fl(r)
            if not any(abs(f - x) < 1e-9 for x in inter):
                fermes.append(f)
    parts = _intervalles(bornes, sg, noms, garder, fermes, inter)
    S = " ∪ ".join(parts) if parts else "∅"
    print("S = " + S)
    print("Crochets : fermés aux zéros si ≤ ou ≥,")
    print("toujours ouverts aux valeurs interdites.")

def e_absolue():
    titre("Valeur absolue |x - a| op r")
    print("|x - a| = distance de x à a.")
    a = demander_nombre("a = ")
    r = demander_nombre("r = ")
    op = ""
    while op not in ("<", "<=", ">", ">=", "="):
        op = input("OP (< <= > >= =) = ").strip()
    if r < 0:
        if op in ("<", "<=", "="):
            print("Une distance n'est jamais < 0 : S = ∅")
        else:
            print("Une distance est toujours ≥ 0 > r : S = ℝ")
        return
    g = a - r; d = a + r
    print("a - r = " + str(g) + ", a + r = " + str(d))
    if op == "=":
        print("S = {" + str(g) + " ; " + str(d) + "}")
    elif op == "<":
        print("⟺ " + str(g) + " < x < " + str(d) + " : S = ]" + str(g) + " ; " + str(d) + "[")
    elif op == "<=":
        print("S = [" + str(g) + " ; " + str(d) + "]")
    elif op == ">":
        print("S = ]-∞ ; " + str(g) + "[ ∪ ]" + str(d) + " ; +∞[")
    else:
        print("S = ]-∞ ; " + str(g) + "] ∪ [" + str(d) + " ; +∞[")

def e_equation():
    titre("Équation polynomiale / rationnelle")
    g = demander("gauche = ")
    d = demander("droite = ")
    f0 = g - d
    rs0 = racines(f0.den)[0]
    fs, cm = f0.simplifiee()
    print("Tout à gauche : " + str(fs) + " = 0")
    if rs0:
        print("Conditions : x ≠ " + ", ".join(str(r.val) for r in rs0))
    print("Un quotient est nul ⟺ numérateur nul")
    print("ET dénominateur non nul.")
    rn, fn, inc = racines(fs.num)
    if fs.num.deg() > 0:
        print("Numérateur : " + ecrire_facto(fs.num, fn) + " = 0")
    sol = []
    for r in rn:
        if any(abs(fl(r) - fl(z)) < 1e-9 for z in rs0):
            print("  x = " + str(r.val) + " REJETÉE (interdite)")
        else:
            sol.append(str(r.val))
            print("  x = " + avec_approx(r.val))
    # cas des racines du facteur commun simplifie
    for z in racines(cm)[0] if cm.deg() > 0 else []:
        if f0.num.val(z.val.a).nul() if z.val.exact() else False:
            print("  x = " + str(z.val) + " REJETÉE (interdite)")
    print("S = {" + " ; ".join(sol) + "}" if sol else "S = ∅")

def menu():
    while True:
        effacer()
        print("2nd degré, polynômes, inéquations")
        print("1 trinôme (Δ, sommet)  2 factoriser")
        print("3 division en potence  4 inéquation")
        print("5 |x-a| op r  6 équation  0 quitter")
        c = input("Choix : ").strip()
        if c in ("0", "q", ""):
            return
        f = {"1": e_trinome, "2": facto.menu, "3": e_diviser, "4": e_inequation,
             "5": e_absolue, "6": e_equation}.get(c)
        if f:
            f()
            voir()
