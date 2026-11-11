# ident : determiner des reels a, b, c... par identification (S7 ex.5, ex.7 b, S3)
from m1outils import *

LETTRES = "abcd"

def _forme(texte, vals):
    t = texte
    for i in range(len(LETTRES)):
        t = t.replace(LETTRES[i], "(" + str(vals[i]) + ")")
    return lire(t)

def _ppcm(a, b):
    g = pgcd_poly(a, b)
    return (a * b).divmod(g)[0] if g.deg() > 0 else a * b

def _lin(coefs, cst, noms):
    """texte de cst + somme coefs[i]*noms[i]"""
    out = ""
    for c, n in zip(coefs, noms):
        if c.nul():
            continue
        neg = c < 0; m = -c if neg else c
        t = n if m == 1 else (str(m) + n if m.q == 1 else "(" + str(m) + ")" + n)
        out += (" - " if neg else " + ") + t if out else ("-" + t if neg else t)
    if not cst.nul() or not out:
        out += (" - " + str(-cst) if cst < 0 else " + " + str(cst)) if out else str(cst)
    return out

def _resoudre(M, rhs, n):
    """Gauss sur des fractions. M : lignes de n coefficients. Renvoie (solution ou None, message)."""
    A = [list(M[i]) + [rhs[i]] for i in range(len(M))]
    piv = []
    r = 0
    for c in range(n):
        p = None
        for i in range(r, len(A)):
            if not A[i][c].nul():
                p = i; break
        if p is None:
            continue
        A[r], A[p] = A[p], A[r]
        k = A[r][c]
        A[r] = [x / k for x in A[r]]
        for i in range(len(A)):
            if i != r and not A[i][c].nul():
                f = A[i][c]
                A[i] = [A[i][j] - f * A[r][j] for j in range(n + 1)]
        piv.append(c); r += 1
    for i in range(r, len(A)):
        if not A[i][n].nul():
            return None, "système impossible : la forme ne convient pas"
    if r < n:
        return None, "infinité de solutions : forme mal choisie"
    sol = [Q(0)] * n
    for i in range(r):
        sol[piv[i]] = A[i][n]
    return sol, ""

def identifier(f=None, texte=None):
    titre("Identification de réels")
    if f is None:
        print("Ex. S7 ex.5 : f = (x^3-x^2+x+1)/(x^2+1)")
        f = demander("f(x) = ")
    if texte is None:
        print("Forme cherchée, inconnues a b c d :")
        print("ex. ax+b+c/(x^2+1)   a+b/(2x^2-3)")
        print("    (x+2)(ax^2+bx+c)")
        texte = demander_txt_memo("forme : ", "forme")
    noms = [l for l in LETTRES if l in texte]
    n = len(noms)
    if n == 0:
        print("Aucune inconnue a, b, c, d dans la forme.")
        return
    zero = [0] * len(LETTRES)
    T0 = _forme(texte, zero).simplifiee()[0]
    Ts = []
    for l in noms:
        v = [0] * len(LETTRES); v[LETTRES.index(l)] = 1
        Ts.append((_forme(texte, v) - T0).simplifiee()[0])
    # controle : forme lineaire en a, b, c, d
    for i in range(n):
        v = [0] * len(LETTRES); v[LETTRES.index(noms[i])] = 2
        diff = _forme(texte, v) - T0 - Ts[i] * 2
        if not diff.simplifiee()[0].num.nul():
            print("Forme non linéaire en " + noms[i] + " : méthode non applicable.")
            return
    titre("Méthode du prof (S7 ex.5)")
    print("D'une part f(x) = " + str(f))
    print("D'autre part f(x) = " + texte)
    # denominateur commun
    L = f.den
    for T in [T0] + Ts:
        L = _ppcm(L, T.den)
    L = primitif(L) if L.deg() >= 1 else P([1])
    print("Même dénominateur : " + str(L))
    gauche = f.num * f.den.divmod(L)[0] if False else (f.num * L).divmod(f.den)[0]
    N0 = (T0.num * L).divmod(T0.den)[0]
    Ns = [(T.num * L).divmod(T.den)[0] for T in Ts]
    print("On compare les numérateurs :")
    print(str(gauche) + " = " + _lin_poly(N0, Ns, noms))
    deg = max([gauche.deg(), N0.deg()] + [N.deg() for N in Ns])
    print("Par identification des coefficients de")
    print("chaque puissance de x :")
    M = []; rhs = []
    for p in range(deg, -1, -1):
        co = [N.coef(p) for N in Ns]
        c0 = N0.coef(p)
        g = gauche.coef(p)
        nomp = "x^" + str(p) if p > 1 else ("x" if p == 1 else "1")
        if not (all(x.nul() for x in co) and c0.nul() and g.nul()):
            print("  " + nomp + " : " + _lin(co, c0, noms) + " = " + str(g))
        M.append(co); rhs.append(g - c0)
    sol, msg = _resoudre(M, rhs, n)
    if sol is None:
        print(msg)
        return
    print("⟺ " + ", ".join(noms[i] + " = " + str(sol[i]) for i in range(n)))
    final = _substituer(texte, dict((noms[i], sol[i]) for i in range(n)))
    try:
        ff = lire(final)
        ok = (ff - f).simplifiee()[0].num.nul()
    except Exception:
        ok = False
    print("Résultat : f(x) = " + final)
    print("Contrôle (même fonction) :" + (" ok" if ok else " NON"))
    q, r = f.num.divmod(f.den)
    if f.den.deg() >= 1 and q.deg() <= 1 and not r.nul():
        print("Interprétation : " + str(r) + "/(" + str(f.den) + ") → 0 en ±∞")
        print("Asymptote " + ("horizontale" if q.deg() <= 0 else "oblique") + " : y = " + str(q) + " en ±∞")

def _substituer(texte, vals):
    """Remplace les lettres par leurs valeurs avec une ecriture propre."""
    out = ""
    i = 0
    while i < len(texte):
        ch = texte[i]
        if ch in vals:
            v = vals[ch]
            suiv = texte[i + 1] if i + 1 < len(texte) else ""
            colle = suiv.isalpha() or suiv == "("
            prec = out[-1] if out else ""
            neg = v < 0
            m = -v if neg else v
            if m == 1 and colle:
                t = ""
            elif m.q == 1:
                t = str(m.p)
            else:
                t = "(" + str(m) + ")"
            if neg:
                if prec == "+":
                    out = out[:-1] + "-" + t
                elif prec in ("", "("):
                    out += "-" + t
                else:
                    out += "(-" + (t or "1") + ")"
            else:
                out += t
        else:
            out += ch
        i += 1
    return out

def _lin_poly(N0, Ns, noms):
    """Affiche N0 + somme noms[i]*Ns[i] (forme developpee par lettre)."""
    parts = []
    if not N0.nul():
        parts.append(str(N0))
    for N, l in zip(Ns, noms):
        if N.nul():
            continue
        s = str(N)
        parts.append(l + ("·(" + s + ")" if len(N.c) > 1 and sum(1 for x in N.c if not x.nul()) > 1 or s.startswith("-") else ("" if s == "1" else "·" + s)))
    return " + ".join(parts) if parts else "0"

def menu():
    identifier()
