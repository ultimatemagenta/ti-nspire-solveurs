# m1outils : base commune des programmes MATH_1 (TI-Nspire CX II, Python)
# Fractions exactes, polynomes, fractions rationnelles, racines exactes,
# tableaux de signes. Pas de f-string (compatibilite TI Python).

import math
from ecran import ecrire as print, demander_txt as input, voir, demander_txt_memo, effacer

def fl(x):
    """Valeur decimale (le Python TI n'appelle pas __float__ des classes)."""
    if isinstance(x, (int, float)):
        return float(x)
    if isinstance(x, Q):
        return x.p / x.q
    if isinstance(x, R):
        return fl(x.a) + fl(x.b) * math.sqrt(x.r)
    if isinstance(x, Racine):
        return fl(x.val)
    return float(x)

# ---------- entiers et fractions ----------

def pgcd(a, b):
    a = abs(a); b = abs(b)
    while b:
        a, b = b, a % b
    return a

class Q:
    """Fraction exacte p/q (q > 0)."""
    def __init__(self, p, q=1):
        if isinstance(p, Q):
            q = p.q * q; p = p.p
        if q == 0:
            raise ZeroDivisionError("division par 0")
        if q < 0:
            p = -p; q = -q
        g = pgcd(p, q) or 1
        self.p = p // g; self.q = q // g
    def __add__(s, o):
        o = aq(o); return Q(s.p * o.q + o.p * s.q, s.q * o.q)
    __radd__ = __add__
    def __neg__(s):
        return Q(-s.p, s.q)
    def __sub__(s, o):
        return s + (-aq(o))
    def __rsub__(s, o):
        return aq(o) - s
    def __mul__(s, o):
        o = aq(o); return Q(s.p * o.p, s.q * o.q)
    __rmul__ = __mul__
    def __truediv__(s, o):
        o = aq(o); return Q(s.p * o.q, s.q * o.p)
    def __rtruediv__(s, o):
        return aq(o) / s
    def __pow__(s, n):
        r = Q(1)
        b = s if n >= 0 else Q(1) / s
        for _ in range(abs(n)):
            r = r * b
        return r
    def __eq__(s, o):
        o = aq(o); return s.p == o.p and s.q == o.q
    def __ne__(s, o):
        return not s == o
    def __lt__(s, o):
        o = aq(o); return s.p * o.q < o.p * s.q
    def __le__(s, o):
        return s < o or s == o
    def __gt__(s, o):
        return aq(o) < s
    def __ge__(s, o):
        return s > o or s == o
    def __hash__(s):
        return hash((s.p, s.q))
    def __float__(s):
        return s.p / s.q
    def nul(s):
        return s.p == 0
    def __str__(s):
        if s.q == 1:
            return str(s.p)
        return str(s.p) + "/" + str(s.q)
    __repr__ = __str__

def aq(x):
    if isinstance(x, Q):
        return x
    if isinstance(x, int):
        return Q(x)
    if isinstance(x, float):
        # decimale tapee : 0.5 -> 1/2 (6 chiffres)
        n = int(round(x * 1000000))
        return Q(n, 1000000)
    raise TypeError("nombre attendu")

def entre_par(q):
    """Fraction ecrite avec parentheses si besoin (pour un produit)."""
    s = str(q)
    if "/" in s or s.startswith("-"):
        return "(" + s + ")"
    return s

# ---------- racines carrees exactes ----------

def isqrt(n):
    if n < 0:
        raise ValueError
    if n < 2:
        return n
    x = int(math.sqrt(n))
    while x * x > n:
        x -= 1
    while (x + 1) * (x + 1) <= n:
        x += 1
    return x

def partie_carree(n):
    """n = k^2 * r avec r sans facteur carre ; renvoie (k, r)."""
    k = 1; r = n; d = 2
    while d * d <= r:
        while r % (d * d) == 0:
            r //= d * d; k *= d
        d += 1
    return k, r

class R:
    """Nombre a + b*sqrt(r) (a, b fractions, r entier sans facteur carre)."""
    def __init__(self, a, b=0, r=1):
        self.a = aq(a); self.b = aq(b); self.r = r
        if r == 1:
            self.a = self.a + self.b; self.b = Q(0)
        if self.b.nul():
            self.r = 1
    def __float__(s):
        return fl(s.a) + fl(s.b) * math.sqrt(s.r)
    def exact(s):
        return s.b.nul()
    def __str__(s):
        if s.b.nul():
            return str(s.a)
        rac = "√" + str(s.r)
        b = s.b
        if b == 1:
            t = rac
        elif b == -1:
            t = "-" + rac
        elif b.q == 1:
            t = str(b.p) + rac
        elif b.p == 1:
            t = rac + "/" + str(b.q)
        elif b.p == -1:
            t = "-" + rac + "/" + str(b.q)
        else:
            t = str(b.p) + rac + "/" + str(b.q)
        if s.a.nul():
            return t
        if t.startswith("-"):
            return str(s.a) + t
        return str(s.a) + "+" + t
    __repr__ = __str__

def racine(q):
    """sqrt(q) exacte pour q fraction >= 0 : renvoie R."""
    q = aq(q)
    if q.p < 0:
        raise ValueError("racine d'un negatif")
    # sqrt(p/q) = sqrt(p*q)/q
    k, r = partie_carree(q.p * q.q)
    return R(0, Q(k, q.q), r)

def div_rac(a, x):
    """a / x pour a fraction et x = b*sqrt(r) (R sans partie rationnelle) : resultat R rationalise."""
    a = aq(a)
    if x.r == 1:
        return R(a / x.a)
    return R(0, a / (x.b * x.r), x.r)

def mul_rac(k, x):
    """k * x pour k fraction et x R."""
    k = aq(k)
    return R(k * x.a, k * x.b, x.r)

def approx(x, n=4):
    v = fl(x)
    s = ("%." + str(n) + "f") % v
    if "." in s:
        s = s.rstrip("0").rstrip(".")
    if s == "-0":
        s = "0"
    return s

def avec_approx(x):
    s = str(x)
    if isinstance(x, R) and not x.exact():
        if x.a.nul():
            w = x.b * x.b * x.r
            if w.q != 1:
                s += " = " + ("-" if x.b < 0 else "") + "√(" + str(w) + ")"
        return s + " ≈ " + approx(x)
    return s

# ---------- polynomes ----------

class P:
    """Polynome a coefficients fractions ; c[i] = coefficient de v^i."""
    def __init__(self, c=None, v="x"):
        c = [aq(x) for x in (c or [])]
        while c and c[-1].nul():
            c.pop()
        self.c = c; self.v = v
    def deg(s):
        return len(s.c) - 1
    def nul(s):
        return not s.c
    def dom(s):
        return s.c[-1] if s.c else Q(0)
    def coef(s, i):
        return s.c[i] if 0 <= i < len(s.c) else Q(0)
    def __add__(s, o):
        o = ap(o, s.v); n = max(len(s.c), len(o.c))
        return P([s.coef(i) + o.coef(i) for i in range(n)], s.v)
    __radd__ = __add__
    def __neg__(s):
        return P([-x for x in s.c], s.v)
    def __sub__(s, o):
        return s + (-ap(o, s.v))
    def __rsub__(s, o):
        return ap(o, s.v) - s
    def __mul__(s, o):
        o = ap(o, s.v)
        if s.nul() or o.nul():
            return P([], s.v)
        r = [Q(0)] * (len(s.c) + len(o.c) - 1)
        for i in range(len(s.c)):
            for j in range(len(o.c)):
                r[i + j] = r[i + j] + s.c[i] * o.c[j]
        return P(r, s.v)
    __rmul__ = __mul__
    def __pow__(s, n):
        r = P([1], s.v)
        for _ in range(n):
            r = r * s
        return r
    def __eq__(s, o):
        o = ap(o, s.v); return s.c == o.c
    def divmod(s, o):
        """Division euclidienne (en potence) : s = o*quot + reste."""
        o = ap(o, s.v)
        if o.nul():
            raise ZeroDivisionError
        reste = P(s.c, s.v); quot = [Q(0)] * max(1, len(s.c) - len(o.c) + 1)
        while not reste.nul() and reste.deg() >= o.deg():
            k = reste.deg() - o.deg(); t = reste.dom() / o.dom()
            quot[k] = t
            reste = reste - P([Q(0)] * k + [t], s.v) * o
        return P(quot, s.v), reste
    def val(s, x):
        r = Q(0) if isinstance(x, Q) or isinstance(x, int) else 0.0
        if isinstance(x, int):
            x = Q(x)
        for a in reversed(s.c):
            r = r * x + (a if isinstance(r, Q) else fl(a))
        return r
    def valf(s, x):
        r = 0.0
        for a in reversed(s.c):
            r = r * x + fl(a)
        return r
    def derive(s):
        return P([s.c[i] * i for i in range(1, len(s.c))], s.v)
    def unitaire(s):
        return P([x / s.dom() for x in s.c], s.v) if s.c else s
    def compose_moins(s):
        """s(-v)"""
        return P([s.c[i] * (-1) ** i for i in range(len(s.c))], s.v)
    def __str__(s):
        if not s.c:
            return "0"
        out = ""
        for i in range(len(s.c) - 1, -1, -1):
            a = s.c[i]
            if a.nul():
                continue
            neg = a < 0; m = -a if neg else a
            if i == 0:
                t = str(m)
            else:
                if m == 1:
                    t = ""
                elif m.q == 1:
                    t = str(m.p)
                else:
                    t = "(" + str(m) + ")"
                t += s.v + ("^" + str(i) if i > 1 else "")
            if out == "":
                out = ("-" if neg else "") + t
            else:
                out += ("-" if neg else "+") + t
        return out
    __repr__ = __str__

def ap(x, v="x"):
    if isinstance(x, P):
        return x
    return P([aq(x)], v)

def pgcd_poly(a, b):
    a = P(a.c, a.v); b = P(b.c, b.v)
    while not b.nul():
        a, b = b, a.divmod(b)[1]
    return a.unitaire() if not a.nul() else a

def entre_par_p(p):
    s = str(p)
    if len(p.c) > 1 and sum(1 for x in p.c if not x.nul()) > 1:
        return "(" + s + ")"
    return s

# ---------- fractions rationnelles ----------

class F:
    """Fraction rationnelle num/den (non simplifiee par defaut)."""
    def __init__(self, num, den=None, v="x"):
        self.num = ap(num, v); self.den = ap(den if den is not None else 1, v)
        self.v = v
        if self.den.nul():
            raise ZeroDivisionError("division par 0")
    def __add__(s, o):
        o = af(o, s.v)
        return F(s.num * o.den + o.num * s.den, s.den * o.den, s.v)
    __radd__ = __add__
    def __neg__(s):
        return F(-s.num, s.den, s.v)
    def __sub__(s, o):
        return s + (-af(o, s.v))
    def __mul__(s, o):
        o = af(o, s.v); return F(s.num * o.num, s.den * o.den, s.v)
    __rmul__ = __mul__
    def __truediv__(s, o):
        o = af(o, s.v)
        if o.num.nul():
            raise ZeroDivisionError("division par 0")
        return F(s.num * o.den, s.den * o.num, s.v)
    def __pow__(s, n):
        if n < 0:
            return F(s.den ** (-n), s.num ** (-n), s.v)
        return F(s.num ** n, s.den ** n, s.v)
    def simplifiee(s):
        g = pgcd_poly(s.num, s.den)
        if g.deg() <= 0:
            n, d = s.num, s.den
        else:
            n = s.num.divmod(g)[0]; d = s.den.divmod(g)[0]
        # coefficients entiers, dominant du denominateur > 0
        m = 1
        for a in n.c + d.c:
            m = m * a.q // pgcd(m, a.q)
        c = 0
        for a in n.c + d.c:
            c = pgcd(c, (a * m).p)
        k = Q(m, c or 1)
        if d.dom() < 0:
            k = -k
        return F(n * k, d * k, s.v), g
    def __str__(s):
        if s.den.deg() == 0:
            return str(P([x / s.den.dom() for x in s.num.c], s.v))
        return entre_par_p(s.num) + "/" + entre_par_p(s.den)

def af(x, v="x"):
    if isinstance(x, F):
        return x
    return F(ap(x, v), None, v)

# ---------- lecture d'une expression tapee ----------
# Accepte : 2x^2-3, 3/2x+1, (x-1)(x+2), x**2, x²,
# 1/(x-1)-1/(x+1), (x^2+1)/(2x^2-3), 0.5x

def lire(texte, v="x"):
    s = texte.replace(" ", "").replace("**", "^").replace("²", "^2").replace("³", "^3")
    s = s.replace("−", "-").replace("·", "*").replace(":", "/").replace(",", ".")
    pos = [0]
    def voir():
        return s[pos[0]] if pos[0] < len(s) else ""
    def somme():
        r = produit()
        while voir() in ("+", "-"):
            op = voir(); pos[0] += 1
            t = produit()
            r = r + t if op == "+" else r - t
        return r
    def produit():
        r = unaire()
        while True:
            c = voir()
            if c == "*":
                pos[0] += 1; r = r * unaire()
            elif c == "/":
                pos[0] += 1; r = r / unaire()
            elif c != "" and (c.isdigit() or c == "(" or c.isalpha()):
                r = r * unaire()  # multiplication implicite
            else:
                return r
    def unaire():
        if voir() == "-":
            pos[0] += 1; return -unaire()
        if voir() == "+":
            pos[0] += 1; return unaire()
        return puissance()
    def puissance():
        b = atome()
        if voir() == "^":
            pos[0] += 1
            neg = False
            if voir() == "-":
                neg = True; pos[0] += 1
            d = pos[0]
            while voir().isdigit():
                pos[0] += 1
            if d == pos[0]:
                raise ValueError("exposant entier attendu")
            n = int(s[d:pos[0]])
            b = b ** (-n if neg else n)
        return b
    def atome():
        c = voir()
        if c == "(":
            pos[0] += 1; r = somme()
            if voir() != ")":
                raise ValueError("parenthese manquante")
            pos[0] += 1; return r
        if c.isdigit() or c == ".":
            d = pos[0]
            while voir().isdigit() or voir() == ".":
                pos[0] += 1
            t = s[d:pos[0]]
            if "." in t:
                e, f = t.split(".")
                return F(P([Q(int(e + f) if (e + f) else 0, 10 ** len(f))], v), None, v)
            return F(P([Q(int(t))], v), None, v)
        if c == v:
            pos[0] += 1; return F(P([0, 1], v), None, v)
        raise ValueError("caractere inattendu : " + (c or "fin"))
    if s == "":
        raise ValueError("expression vide")
    r = somme()
    if pos[0] != len(s):
        raise ValueError("caractere inattendu : " + s[pos[0]])
    return r

def lire_poly(texte, v="x"):
    f = lire(texte, v)
    if f.den.deg() > 0:
        f, g = f.simplifiee()
        if f.den.deg() > 0:
            raise ValueError("polynome attendu")
    k = f.den.dom()
    return P([x / k for x in f.num.c], v)

def demander(msg, v="x", poly=False):
    while True:
        t = demander_txt_memo(msg, ("p" if poly else "f") + v)
        try:
            return lire_poly(t, v) if poly else lire(t, v)
        except Exception as e:
            print("Pas compris (" + str(e) + "). Recommence.")

def demander_nombre(msg):
    while True:
        t = input(msg)
        try:
            f = lire(t, "x")
            if f.num.deg() > 0 or f.den.deg() > 0:
                raise ValueError("nombre attendu")
            return f.num.coef(0) / f.den.coef(0)
        except Exception as e:
            print("Pas compris (" + str(e) + "). Recommence.")

# ---------- racines d'un polynome ----------

def diviseurs(n):
    n = abs(n); d = []
    i = 1
    while i * i <= n:
        if n % i == 0:
            d.append(i)
            if i * i != n:
                d.append(n // i)
        i += 1
    return d

def entiers(p):
    """Coefficients entiers proportionnels a p."""
    m = 1
    for a in p.c:
        m = m * a.q // pgcd(m, a.q)
    return [int((a * m).p) for a in p.c]

def primitif(p):
    """Polynome a coefficients entiers premiers entre eux, dominant > 0."""
    z = entiers(p); g = 0
    for x in z:
        g = pgcd(g, x)
    if z[-1] < 0:
        g = -g
    return P([Q(x, g) for x in z], p.v)

def plus_moins(q):
    """' + q' ou ' - |q|'."""
    q = aq(q)
    return (" - " + str(-q)) if q < 0 else (" + " + str(q))

def facteurs_lignes(fn, fd, k):
    """Lignes d'un tableau de signes : constante (si != 1), facteurs avec exposant."""
    lignes = []
    if k != 1:
        lignes.append(("constante " + str(k), (lambda x, k=fl(k): k), []))
    for (p, e) in fn + fd:
        rp = racines(p)[0]
        nom = entre_par_p(p) + ("^" + str(e) if e > 1 else "")
        lignes.append((nom, (lambda x, p=p, e=e: p.valf(x) ** e), [r.val for r in rp]))
    return lignes

def constante(fs, fn, fd):
    k = fs.num.dom() / fs.den.dom()
    for (p, e) in fn:
        k = k / p.dom() ** e
    for (p, e) in fd:
        k = k * p.dom() ** e
    return k

class RA(R):
    """Racine connue seulement en valeur approchee."""
    def __str__(s):
        return "≈" + approx(fl(s))
    __repr__ = __str__

class Racine:
    def __init__(self, val, ordre=1):
        self.val = val if isinstance(val, R) else R(val)
        self.ordre = ordre
    def __float__(s):
        return fl(s.val)
    def __str__(s):
        return str(s.val)

def racines(p):
    """Racines reelles de p avec ordre. Renvoie (liste de Racine, facteurs, reste_inconnu).
    facteurs : liste de (polynome, exposant) ; exact si reste_inconnu est None."""
    p = P(p.c, p.v)
    res = []; fact = []
    if p.deg() <= 0:
        return res, fact, None
    # racine 0
    k = 0
    while p.c and p.c[0].nul():
        p = P(p.c[1:], p.v); k += 1
    if k:
        res.append(Racine(Q(0), k)); fact.append((P([0, 1], p.v), k))
    # racines rationnelles (theoreme des racines rationnelles)
    trouve = True
    while trouve and p.deg() >= 1:
        trouve = False
        z = entiers(p)
        for num in diviseurs(z[0]):
            for den in diviseurs(z[-1]):
                for sg in (1, -1):
                    r = Q(sg * num, den)
                    if p.val(r).nul():
                        m = 0
                        d = P([-r.p, r.q], p.v)  # facteur entier (qx - p)
                        while p.deg() >= 1 and p.val(r).nul():
                            p = p.divmod(d)[0]; m += 1
                        res.append(Racine(r, m)); fact.append((d, m))
                        trouve = True
                        break
                if trouve: break
            if trouve: break
    inconnu = None
    if p.deg() == 2:
        a, b, c = p.c[2], p.c[1], p.c[0]
        D = b * b - 4 * a * c
        if D > 0:
            rd = racine(D)  # sqrt(D) = b*sqrt(r)
            u = -b / (2 * a); w = rd.b / (2 * a)
            r1 = R(u, -w, rd.r); r2 = R(u, w, rd.r)
            res.append(Racine(r1)); res.append(Racine(r2))
            fact.append((primitif(p), 1))
        elif D.nul():
            u = -b / (2 * a)
            res.append(Racine(u, 2)); fact.append((P([-u.p, u.q], p.v), 2))
        else:
            fact.append((primitif(p), 1))  # sans racine reelle, signe constant
    elif p.deg() >= 3:
        inconnu = p
        bic = p.deg() == 4 and p.c[1].nul() and p.c[3].nul()
        if bic:
            for X in racines(P([p.c[0], p.c[2], p.c[4]], "X"))[0]:
                if X.val.exact() and X.val.a > 0:
                    rx = racine(X.val.a)
                    res.append(Racine(rx, X.ordre)); res.append(Racine(R(0, -rx.b, rx.r), X.ordre))
                elif not X.val.exact() and fl(X.val) > 0:
                    v = math.sqrt(fl(X.val))
                    res.append(Racine(RA(aq(round(v, 6))), X.ordre)); res.append(Racine(RA(aq(round(-v, 6))), X.ordre))
        else:
            for x in racines_num(p):
                res.append(Racine(RA(aq(round(x, 6))), 1))
        fact.append((primitif(p), 1))
    elif p.deg() >= 1:
        fact.append((primitif(p), 1))
    res.sort(key=lambda r: fl(r))
    return res, fact, inconnu

def racines_num(p):
    """Racines reelles approchees (bissection sur une grille)."""
    out = []
    borne = 1 + max(abs(fl(a / p.dom())) for a in p.c[:-1]) if p.deg() > 0 else 1
    n = 2000; h = 2 * borne / n
    x0 = -borne; y0 = p.valf(x0)
    for i in range(1, n + 1):
        x1 = -borne + i * h; y1 = p.valf(x1)
        if y0 == 0:
            out.append(x0)
        elif y0 * y1 < 0:
            a, b = x0, x1
            for _ in range(60):
                m = (a + b) / 2
                if p.valf(a) * p.valf(m) <= 0:
                    b = m
                else:
                    a = m
            out.append((a + b) / 2)
        x0, y0 = x1, y1
    return out

def ecrire_facto(p, fact):
    """p = k * produit des facteurs."""
    k = p.dom()
    for f, e in fact:
        k = k / (f.dom() ** e)
    t = ""
    for f, e in fact:
        t += entre_par_p(f) if (len(fact) > 1 or k != 1 or e > 1) else str(f)
        if e > 1:
            t += "^" + str(e)
    if k == 1:
        return t or "1"
    if k == -1:
        return "-" + t
    return entre_par(k) + t if t else str(k)

# ---------- intervalles et tableaux de signes ----------

def signe(v):
    if abs(v) < 1e-12:
        return "0"
    return "+" if v > 0 else "-"

def points_tests(bornes):
    """Points pris dans chaque intervalle entre bornes triees (floats)."""
    if not bornes:
        return [0.0]
    pts = [bornes[0] - 1]
    for i in range(len(bornes) - 1):
        pts.append((bornes[i] + bornes[i + 1]) / 2)
    pts.append(bornes[-1] + 1)
    return pts

def tableau_signes(lignes, interdits, var="x"):
    """lignes : liste (nom, fonction float->float) ; la derniere est le resultat.
    interdits : liste de floats (valeurs interdites).
    Affiche le tableau en vertical (ecran etroit). Renvoie (bornes, signes du resultat)."""
    bornes = []
    zer = {}
    for nom, f, zs in lignes:
        for z in zs:
            fz = fl(z)
            if all(abs(fz - b) > 1e-9 for b in bornes):
                bornes.append(fz); zer[fz] = z
    bornes.sort()
    pts = points_tests(bornes)
    def nom_b(b):
        return str(zer[b]) if b in zer else approx(b)
    res = []
    print("Tableau de signes (" + var + " de -∞ à +∞) :")
    for i in range(len(pts)):
        if i == 0:
            g = "-∞"
        else:
            g = nom_b(bornes[i - 1])
        d = "+∞" if i == len(pts) - 1 else nom_b(bornes[i])
        t = "]" + g + " ; " + d + "[ : "
        sg = [signe(f(pts[i])) for nom, f, zs in lignes]
        t += " ".join(sg[:-1]) + " => " + sg[-1] if len(sg) > 1 else sg[0]
        print(t)
        res.append(sg[-1])
        if i < len(bornes):
            b = bornes[i]
            if any(abs(b - x) < 1e-9 for x in interdits):
                print("  " + var + "=" + nom_b(b) + " : || (interdit)")
            else:
                print("  " + var + "=" + nom_b(b) + " : 0")
    return bornes, res

def pause():
    voir()

def titre(t):
    print("")
    print("== " + t + " ==")
