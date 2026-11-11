# facto : factorisation detaillee d'un polynome (degre 1 a 4), comme dans S7 ex.8
from m1outils import *

def _monome(a, k, v):
    if k == 0:
        return str(a)
    t = "" if a == 1 else ("-" if a == -1 else (str(a) if a.q == 1 else entre_par(a)))
    return t + v + ("^" + str(k) if k > 1 else "")

def potence(p, d, verbeux=True):
    """Division en potence de p par d, etape par etape. Renvoie (quotient, reste)."""
    v = p.v
    if verbeux:
        print("Division en potence : (" + str(p) + ") ÷ (" + str(d) + ")")
    reste = P(p.c, v)
    quot = P([], v)
    while not reste.nul() and reste.deg() >= d.deg():
        k = reste.deg() - d.deg()
        t = reste.dom() / d.dom()
        m = P([Q(0)] * k + [t], v)
        prod = m * d
        nouveau = reste - prod
        if verbeux:
            print(" " + _monome(reste.dom(), reste.deg(), v) + " ÷ " + _monome(d.dom(), d.deg(), v) + " = " + str(m))
            print("   " + str(m) + "·(" + str(d) + ") = " + str(prod))
            print("   reste : " + str(nouveau))
        quot = quot + m
        reste = nouveau
    if verbeux:
        print("Quotient " + str(quot) + ", reste " + str(reste))
    return quot, reste

def identification(p, r, nom="P"):
    """P = (x - r)·Q par identification des coefficients (methode du prof)."""
    v = p.v
    n = p.deg()
    noms = ["a", "b", "c", "d"][:n]
    print("Par identification : " + nom + " = (" + str(P([-r, 1], v)) + ")·(" + " + ".join(
        noms[i] + (v + "^" + str(n - 1 - i) if n - 1 - i > 1 else (v if n - 1 - i == 1 else "")) for i in range(n)) + ")")
    q = [Q(0)] * n  # q[i] = coef de x^i du quotient
    q[n - 1] = p.coef(n)
    print("  coef. de " + v + "^" + str(n) + " : " + noms[0] + " = " + str(q[n - 1]))
    for k in range(n - 1, 0, -1):
        # coef de x^k : q[k-1] - r q[k] = p_k
        q[k - 1] = p.coef(k) + r * q[k]
        nom = noms[n - k]
        print("  coef. de " + v + ("^" + str(k) if k > 1 else "") + " : " + nom + " - (" + str(r) + ")·" + noms[n - 1 - k] + " = " + str(p.coef(k)) + " → " + nom + " = " + str(q[k - 1]))
    ctrl = -r * q[0]
    print("  terme constant : -(" + str(r) + ")·" + noms[n - 1] + " = " + str(ctrl) + (" ✓" if ctrl == p.coef(0) else " ✗ (≠ " + str(p.coef(0)) + ")"))
    return P(q, v)

def _candidats(p):
    z = entiers(p)
    nums = diviseurs(z[0]); dens = diviseurs(z[-1])
    c = []
    for d in sorted(dens):
        for n in sorted(nums):
            for s in (1, -1):
                r = Q(s * n, d)
                if r not in c:
                    c.append(r)
    c.sort(key=lambda r: (abs(fl(r)), fl(r) < 0))
    return c, z

def detail(p, nom="P", niveau=0):
    """Affiche la factorisation pas a pas. Renvoie la liste (facteur, exposant) et la constante."""
    v = p.v
    if niveau == 0:
        titre("Factorisation de " + nom + "(" + v + ")")
        print(nom + "(" + v + ") = " + str(p))
    if p.deg() <= 0:
        print("Constante : rien à factoriser.")
        return [], p.dom() if not p.nul() else Q(0)
    facteurs = []
    k = p.dom()
    # 1. mise en evidence de v^m
    m = 0
    while p.c[m].nul():
        m += 1
    if m:
        print("1) Mise en évidence : " + v + ("^" + str(m) if m > 1 else "") + " est facteur commun")
        p = P(p.c[m:], v)
        print("   " + nom + " = " + v + ("^" + str(m) if m > 1 else "") + "·(" + str(p) + ")")
        facteurs.append((P([0, 1], v), m))
    # 2. degre 1
    if p.deg() == 1:
        a, b = p.c[1], p.c[0]
        print("Degré 1 : zéro " + v + " = " + str(-b / a))
        facteurs.append((primitif(p), 1))
        return _fin(nom, v, p, facteurs, k)
    # 3. degre 2 : discriminant
    if p.deg() == 2:
        _deg2(p, facteurs)
        return _fin(nom, v, p, facteurs, k)
    # 4. degre 4 bicarre
    if p.deg() == 4 and p.c[1].nul() and p.c[3].nul():
        print("Degré 4 bicarré (puissances paires) :")
        print("on pose X = " + v + "² (X ≥ 0).")
        qX = P([p.c[0], p.c[2], p.c[4]], "X")
        print("  " + str(qX) + " = 0")
        rs = racines(qX)[0]
        a, b, c = p.c[4], p.c[2], p.c[0]
        print("  Δ = " + entre_par(b) + "² - 4·" + entre_par(a) + "·" + entre_par(c) + " = " + str(b * b - 4 * a * c))
        if not rs:
            print("  Δ < 0 : pas de racine en X ;")
            print("  " + nom + " garde le signe de " + str(a) + ", aucun zéro réel.")
            facteurs.append((primitif(p), 1))
            return _fin(nom, v, p, facteurs, k)
        for r in rs:
            X = r.val
            if fl(X) < 0:
                print("  X = " + str(X) + " < 0 : " + v + "² = " + str(X) + " impossible,")
                if X.exact():
                    print("     facteur " + str(P([-X.a, 0, 1], v)) + " (toujours > 0)")
                    facteurs.append((primitif(P([-X.a, 0, 1], v)), r.ordre))
            elif X.exact():
                rx = racine(X.a)
                print("  X = " + str(X) + " : " + v + "² = " + str(X) + " → " + v + " = ±" + str(rx))
                if rx.exact():
                    facteurs.append((P([-rx.a.p, rx.a.q], v), r.ordre))
                    facteurs.append((P([rx.a.p, rx.a.q], v), r.ordre))
                else:
                    facteurs.append((primitif(P([-X.a, 0, 1], v)), r.ordre))
            else:
                print("  X = " + avec_approx(X) + " : " + v + " = ±√(" + str(X) + ")")
                facteurs.append((None, 1))
        facteurs = [f for f in facteurs if f[0] is not None]
        return _fin(nom, v, p, facteurs, k)
    # 5. racine evidente
    cands, z = _candidats(p)
    print("Racine évidente : candidats ± (diviseurs de " + str(abs(z[0])) + ") / (diviseurs de " + str(abs(z[-1])) + ")")
    trouve = None
    essais = 0
    for r in cands:
        val = p.val(r)
        essais += 1
        if essais <= 8 or val.nul():
            print("  " + nom + "(" + str(r) + ") = " + str(val) + (" ✓ racine" if val.nul() else ""))
        if val.nul():
            trouve = r
            break
    if trouve is None:
        print("Aucune racine rationnelle : pas de")
        print("factorisation « à la main » attendue.")
        rs = racines(p)[0]
        for x in rs:
            print("  zéro approché " + v + " ≈ " + approx(x.val))
        facteurs.append((primitif(p), 1))
        return _fin(nom, v, p, facteurs, k)
    r = trouve
    print("Donc (" + str(P([-r, 1], v)) + ") divise " + nom + " (car " + nom + "(" + str(r) + ") = 0).")
    q, reste = potence(p, P([-r, 1], v))
    identification(p, r, nom)
    print(nom + " = (" + str(P([-r, 1], v)) + ")·(" + str(q) + ")")
    facteurs.append((P([-r.p, r.q], v), 1))
    sous, kk = detail(q, "Q", niveau + 1)
    facteurs += sous
    return _fin(nom, v, p, facteurs, k)

def _deg2(p, facteurs):
    v = p.v
    a, b, c = p.c[2], p.c[1], p.c[0]
    D = b * b - 4 * a * c
    print("Degré 2 : " + str(p) + ", Δ = b² - 4ac")
    print("  Δ = " + entre_par(b) + "² - 4·" + entre_par(a) + "·" + entre_par(c) + " = " + str(D))
    if D > 0:
        rd = racine(D)
        print("  Δ > 0 : " + v + " = (-b ± √Δ)/(2a), √Δ = " + str(rd))
        rs = racines(p)[0]
        for x in rs:
            print("  " + v + " = " + avec_approx(x.val))
        if rd.exact():
            for x in rs:
                facteurs.append((P([-x.val.a.p, x.val.a.q], v), 1))
        else:
            print("  racines irrationnelles : on garde le")
            print("  facteur " + str(primitif(p)) + " (ou a(x-x1)(x-x2))")
            facteurs.append((primitif(p), 1))
    elif D.nul():
        u = -b / (2 * a)
        print("  Δ = 0 : racine double " + v + " = -b/(2a) = " + str(u))
        facteurs.append((P([-u.p, u.q], v), 2))
    else:
        print("  Δ < 0 : aucun zéro réel, facteur")
        print("  irréductible, du signe de a (" + ("+" if a > 0 else "-") + ")")
        facteurs.append((primitif(p), 1))

def _fin(nom, v, p, facteurs, k):
    # regroupe les facteurs identiques
    reg = []
    for f, e in facteurs:
        for i in range(len(reg)):
            if reg[i][0] == f:
                reg[i] = (f, reg[i][1] + e)
                break
        else:
            reg.append((f, e))
    return reg, k

def bilan(p, nom="P"):
    """Factorisation detaillee + forme finale + zeros avec multiplicite."""
    reg, k = detail(p, nom)
    tot = P([1], p.v)
    for f, e in reg:
        tot = tot * (f ** e)
    if tot.nul() or p.nul():
        return reg
    cst = p.dom() / tot.dom()
    txt = ""
    for f, e in reg:
        txt += entre_par_p(f) if (len(reg) > 1 or e > 1 or cst != 1) else str(f)
        if e > 1:
            txt += "^" + str(e)
    pre = "" if cst == 1 else ("-" if cst == -1 else entre_par(cst))
    print("Résultat : " + nom + "(" + p.v + ") = " + pre + txt)
    rs = racines(p)[0]
    if rs:
        print("Zéros (multiplicité = exposant du facteur) :")
        for r in rs:
            print("  " + avec_approx(r.val) + " : ordre " + str(r.ordre))
    print("Contrôle CAS : factor(" + str(p) + ")")
    return reg

def menu():
    p = demander("P(x) = ", poly=True)
    bilan(p)
