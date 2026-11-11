# fonction : analyse complete d'une fonction rationnelle (probleme C, S7 ex.7-8)
# Lancer : run fonction  (ou importer puis analyse())
from m1outils import *
import facto
import graphe

def _ens_valeurs(rs):
    return "{" + " ; ".join(str(r) for r in rs) + "}"

def _limite_inf(f, cote):
    """Limite de f (simplifiee) en +inf (cote=1) ou -inf (cote=-1) : texte, valeur float ou None."""
    n, d = f.num, f.den
    if n.nul():
        return "0", 0.0
    if n.deg() < d.deg():
        return "0", 0.0
    if n.deg() == d.deg():
        v = n.dom() / d.dom()
        return str(v), fl(v)
    s = fl(n.dom() / d.dom()) * (cote ** (n.deg() - d.deg()))
    return ("+∞" if s > 0 else "-∞"), None

def _limite_pole(f, p, cote):
    """Limite en p a gauche (cote=-1) ou a droite (+1)."""
    e = 1e-7 * max(1.0, abs(p))
    v = f.num.valf(p + cote * e) / f.den.valf(p + cote * e)
    return "+∞" if v > 0 else "-∞"

def analyse(texte=None):
    print("Analyse d'une fonction rationnelle")
    print("Tape f(x), ex. (x^2+1)/(2x^2-3)")
    print("Note : 3/2x se lit (3/2)·x ; écris 3/(2x) sinon.")
    if texte is None:
        f0 = demander("f(x) = ")
    else:
        f0 = lire(texte)
    import ident
    from ecran import historique
    while True:
        effacer()
        print("f(x) = " + str(f0))
        print("1 tout   2 domaine  3 simplif")
        print("4 parité 5 zéros/pôles 6 signe")
        print("7 forme a+b/…  8 asymptotes")
        print("9 réciproque, image  10 variations")
        print("11 bijection  12 points du graphe")
        print("13 GRAPHE  14 factorisations détaillées")
        print("15 identifier a,b,c  c changer f")
        print("h historique  0 quitter")
        c = input("Choix : ").strip()
        if c in ("0", "q"):
            return
        if c == "c":
            f0 = demander("f(x) = ")
            continue
        if c == "h":
            historique()
            continue
        if c == "15":
            ident.identifier(f0)
            voir()
            continue
        try:
            ch = int(c)
        except:
            continue
        etapes = list(range(2, 14)) if ch == 1 else [ch]
        for k in etapes:
            if k not in ETAPES:
                continue
            ETAPES[k](f0)
            voir()

# ---------- etapes ----------

def _domaine(f0):
    d = f0.den
    rs, fa, inc = racines(d)
    return rs, fa

def e_domaine(f0):
    titre("2. Domaine de définition")
    print("Pourquoi : on ne peut pas diviser par 0,")
    print("on interdit donc les zéros du dénominateur")
    print("(forme tapée, AVANT toute simplification).")
    print("f existe ⟺ " + str(f0.den) + " ≠ 0")
    if f0.den.deg() >= 2:
        print("On factorise le dénominateur D(x) :")
        facto.bilan(f0.den, "D")
        pause()
    rs, fa = _domaine(f0)
    if f0.den.deg() == 0 or not rs:
        if f0.den.deg() > 0:
            print("Le dénominateur ne s'annule jamais")
            print("(pas de racine réelle).")
        print("D_f = ℝ")
        return
    print("Factorisé : " + ecrire_facto(f0.den, fa) + " ≠ 0")
    for r in rs:
        print("  x ≠ " + avec_approx(r.val))
    if f0.den.deg() >= 3:
        print("Comment trouver : racine évidente parmi")
        print("0, ±1, ±2, ±3, puis division en potence.")
    print("D_f = ℝ \\ " + _ens_valeurs([r.val for r in rs]))

def e_simplif(f0):
    titre("3. Simplification")
    fs, g = f0.simplifiee()
    rn, fn, _ = racines(f0.num)
    rd, fd, _ = racines(f0.den)
    print("Pourquoi : factoriser num et dén. montre")
    print("les facteurs communs, qu'on simplifie.")
    if f0.num.deg() >= 2:
        print("On factorise le numérateur N(x) :")
        facto.bilan(f0.num, "N")
        pause()
    print("num = " + ecrire_facto(f0.num, fn) if f0.num.deg() > 0 else "num = " + str(f0.num))
    print("dén = " + ecrire_facto(f0.den, fd) if f0.den.deg() > 0 else "dén = " + str(f0.den))
    if g.deg() <= 0:
        print("Aucun facteur commun : f est déjà")
        print("sous forme simplifiée.")
    else:
        print("Facteur commun : " + str(g))
        print("Pour x ∈ D_f : f(x) = " + str(fs))
        print("Attention : les valeurs interdites restent")
        print("interdites même après simplification.")
    return fs

def e_parite(f0):
    titre("4. Parité")
    fs, g = f0.simplifiee()
    print("Pourquoi : on compare f(-x) à f(x).")
    print("D_f doit être symétrique par rapport à 0.")
    rs, fa = _domaine(f0)
    sym = all(any(abs(fl(r) + fl(s)) < 1e-9 for s in rs) for r in rs)
    nm = fs.num.compose_moins(); dm = fs.den.compose_moins()
    print("f(-x) = " + str(F(nm, dm)))
    if not sym:
        print("D_f n'est pas symétrique : ni paire")
        print("ni impaire.")
        return
    if nm * fs.den == fs.num * dm:
        print("f(-x) = f(x) : f est PAIRE")
        print("(graphe symétrique par rapport à l'axe Oy).")
    elif nm * fs.den == -(fs.num * dm):
        print("f(-x) = -f(x) : f est IMPAIRE")
        print("(graphe symétrique par rapport à O).")
    else:
        print("Ni f(x) ni -f(x) : ni paire ni impaire.")
        print("Pour le prouver : un x où f(-x) ≠ ±f(x).")
        for x in (1, 2, 3, -1):
            try:
                a = fs.num.val(Q(x)) / fs.den.val(Q(x))
                b = fs.num.val(Q(-x)) / fs.den.val(Q(-x))
                if a != b and a != -b:
                    print("  f(" + str(x) + ") = " + str(a) + ", f(" + str(-x) + ") = " + str(b))
                    break
            except ZeroDivisionError:
                pass

def e_zeros(f0):
    titre("5. Zéros et pôles")
    fs, g = f0.simplifiee()
    print("Sur la forme SIMPLIFIÉE (sinon on compte")
    print("faux) : l'exposant d'un facteur = l'ordre.")
    print("f(x) = " + str(fs))
    rn, fn, _ = racines(fs.num)
    rd, fd, _ = racines(fs.den)
    if rn:
        for r in rn:
            print("Zéro " + avec_approx(r.val) + " d'ordre " + str(r.ordre))
    else:
        print("Aucun zéro (numérateur jamais nul).")
    if rd:
        for r in rd:
            print("Pôle " + avec_approx(r.val) + " d'ordre " + str(r.ordre))
    else:
        print("Aucun pôle.")
    rs0, _ = _domaine(f0)
    trous = [r for r in rs0 if all(abs(fl(r) - fl(p)) > 1e-9 for p in rd)]
    for t in trous:
        print("x = " + str(t.val) + " : interdite mais PAS un pôle")
        print("  (facteur simplifié) : pas d'asymptote là.")
    print("Ordre pair : f garde son signe en")
    print("traversant ; ordre impair : f change.")

def e_signe(f0):
    titre("6. Signe de f")
    fs, g = f0.simplifiee()
    print("Une ligne par facteur, puis la règle")
    print("des signes ; || sous une valeur interdite.")
    print("Sur la forme simplifiée : " + str(fs))
    rn, fn, _ = racines(fs.num)
    rd, fd, _ = racines(fs.den)
    rs0, _ = _domaine(f0)
    k = constante(fs, fn, fd)
    lignes = facteurs_lignes(fn, fd, k)
    lignes.append(("f(x)", lambda x: fs.num.valf(x) / fs.den.valf(x) if abs(fs.den.valf(x)) > 1e-15 else 0.0, [r.val for r in rs0]))
    print("Lignes : " + ", ".join(l[0] for l in lignes[:-1]))
    interdits = [fl(r) for r in rs0]
    bornes, sg = tableau_signes(lignes, interdits)
    pos = []; neg = []
    print("Lecture : f > 0 sur les intervalles +,")
    print("f < 0 sur les intervalles -.")

def e_forme(f0):
    titre("7. Forme a + b/… (division)")
    fs, g = f0.simplifiee()
    n, d = fs.num, fs.den
    if d.deg() == 0:
        print("f est un polynôme : rien à diviser.")
        return
    q, r = n.divmod(d)
    print("Pourquoi : séparer la partie qui reste")
    print("(quotient) de celle qui tend vers 0")
    print("(reste/dén.) donne l'asymptote.")
    print("Division en potence de " + str(n))
    print("par " + str(d) + " :")
    print("  quotient = " + str(q))
    print("  reste    = " + str(r))
    dfa = ecrire_facto(d, racines(d)[1])
    if r.dom() < 0:
        print("f(x) = " + str(q) + " - (" + str(-r) + ")/" + entre_par_p(d))
        print("     = " + str(q) + " - (" + str(-r) + ")/" + dfa)
    else:
        print("f(x) = " + str(q) + " + (" + str(r) + ")/" + entre_par_p(d))
    if n.deg() == d.deg() and r.deg() <= 0:
        a = q.coef(0)
        print("Par identification (méthode du prof) :")
        print(str(n) + " = a·(" + str(d) + ") + b")
        print("coef. de x^" + str(n.deg()) + " : a = " + str(a))
        print("terme constant : b = " + str(r.coef(0)))
    if n.deg() < d.deg():
        print("deg num < deg dén : quotient nul, f est")
        print("déjà « 0 + reste/dén ».")

def e_asymptotes(f0):
    titre("8. Asymptotes")
    fs, g = f0.simplifiee()
    n, d = fs.num, fs.den
    rd, fd, _ = racines(d)
    print("Verticales : x = pôle (forme simplifiée).")
    if not rd:
        print("  aucune")
    for r in rd:
        p = fl(r)
        print("  x = " + avec_approx(r.val) + " : à gauche " + _limite_pole(fs, p, -1) + ", à droite " + _limite_pole(fs, p, 1))
    if d.deg() == 0:
        print("Pas d'asymptote horizontale/oblique")
        print("(polynôme).")
        return
    q, r = n.divmod(d)
    if n.deg() > d.deg() + 1:
        print("deg num ≥ deg dén + 2 : ni horizontale")
        print("ni oblique (hors programme).")
        return
    nom = "horizontale" if q.deg() <= 0 else "oblique"
    print("Horizontale/oblique : f = quotient + reste/dén")
    print("et reste/dén → 0 en ±∞ (deg reste < deg dén).")
    print("Asymptote " + nom + " : y = " + str(q) + " en ±∞")
    if r.nul():
        print("Reste nul : f = y partout sur D_f.")
        return
    for cote, txt in ((1, "+∞"), (-1, "-∞")):
        x = cote * 1e6
        v = r.valf(x) / d.valf(x)
        print("  en " + txt + " : reste/dén " + (">0 : courbe AU-DESSUS" if v > 0 else "<0 : courbe EN DESSOUS"))
    zr = racines(r)[0]
    for z in zr:
        if abs(d.valf(fl(z))) > 1e-12:
            print("  courbe coupe l'asymptote en x = " + avec_approx(z.val))

def _coefs_y(fs):
    """y*den - num = somme (al_i*y + be_i) x^i."""
    n, d = fs.num, fs.den
    m = max(n.deg(), d.deg())
    return [(d.coef(i), -n.coef(i)) for i in range(m + 1)]

def _lin_y(a, b):
    return P([b, a], "y")

def e_reciproque(f0):
    titre("9. Réciproque et image I_f")
    fs, g = f0.simplifiee()
    co = _coefs_y(fs)
    while co and co[-1][0].nul() and co[-1][1].nul():
        co.pop()
    deg = len(co) - 1
    print("Méthode : poser y = f(x), isoler x,")
    print("puis I_f = D_{f⁻¹} (là où x existe).")
    print("y = " + str(fs))
    print("⟺ y·(" + str(fs.den) + ") = " + str(fs.num))
    rs0, _ = _domaine(f0)
    if deg == 1:
        A = _lin_y(*co[1]); B = _lin_y(*co[0])
        print("⟺ x·(" + str(A) + ") = " + str(-B))
        print("⟺ x = (" + str(-B) + ")/(" + str(A) + ") = f⁻¹(y)")
        za = racines(A)[0]
        if za:
            print("f⁻¹ existe ⟺ " + str(A) + " ≠ 0")
            print("I_f = ℝ \\ " + _ens_valeurs([z.val for z in za]))
        else:
            print("I_f = ℝ")
        print("Renommer : f⁻¹(x) = (" + str(P((-B).c, "x")) + ")/(" + str(P(A.c, "x")) + ")")
        _trous_image(f0, fs)
        return
    if deg == 2 and co[1][0].nul() and co[1][1].nul():
        A = _lin_y(*co[2]); C = _lin_y(*co[0])
        print("⟺ x²·(" + str(A) + ") = " + str(-C))
        N = -C; D = A
        print("⟺ x² = (" + str(N) + ")/(" + str(D) + ")")
        print("⟺ x = ±√((" + str(N) + ")/(" + str(D) + "))")
        print("Le ± : f⁻¹ n'est une fonction qu'après")
        print("restriction (+ pour x>0, - pour x<0).")
        print("f⁻¹ existe ⟺ (" + str(N) + ")/(" + str(D) + ") ≥ 0")
        print("               ET " + str(D) + " ≠ 0")
        rN = racines(N)[0]; rD = racines(D)[0]
        lignes = [(str(N), lambda y: N.valf(y), [r.val for r in rN]),
                  (str(D), lambda y: D.valf(y), [r.val for r in rD]),
                  ("quotient", lambda y: N.valf(y) / D.valf(y) if abs(D.valf(y)) > 1e-15 else 0.0, [])]
        bornes, sg = tableau_signes(lignes, [fl(r) for r in rD], "y")
        zero_interdit = any(abs(fl(r)) < 1e-12 for r in rs0)
        print("I_f = " + _union(bornes, sg, rN, rD, zero_interdit))
        if zero_interdit:
            print("(x = 0 est interdite : on exclut le y")
            print(" qui donnerait x² = 0.)")
        _trous_image(f0, fs)
        return
    if deg == 2:
        A = _lin_y(*co[2]); B = _lin_y(*co[1]); C = _lin_y(*co[0])
        print("⟺ (" + str(A) + ")x² + (" + str(B) + ")x + (" + str(C) + ") = 0")
        print("Équation du 2nd degré en x (y fixé).")
        Dl = B * B - A * C * 4
        print("Δ(y) = B² - 4AC = " + str(Dl))
        print("x = (" + str(-B) + " ± √(" + str(Dl) + "))/(2(" + str(A) + "))")
        print("y ∈ I_f ⟺ Δ(y) ≥ 0 (si A(y) ≠ 0)")
        rD = racines(Dl)[0]
        lignes = [("Δ(y)", lambda y: Dl.valf(y), [r.val for r in rD])]
        bornes, sg = tableau_signes(lignes, [], "y")
        print("I_f = " + _union(bornes, sg, rD, [], False))
        for z in racines(A)[0]:
            yv = z.val.a
            Bv = B.val(yv); Cv = C.val(yv)
            print("Cas A(y)=0 : y = " + str(yv) + " → " + str(Bv) + "x + " + str(Cv) + " = 0")
            if not Bv.nul():
                xv = -Cv / Bv
                ok = all(abs(fl(xv) - fl(t)) > 1e-9 for t in rs0)
                print("  x = " + str(xv) + (" ∈ D_f : y atteint" if ok else " interdit : y à retirer"))
        _trous_image(f0, fs)
        return
    print("Degré " + str(deg) + " en x : pas de réciproque")
    print("algébrique attendue au test.")

def _union(bornes, sg, zeros_ok, interdits, zero_interdit):
    """Union des intervalles ou sg >= 0, bornes incluses si zero autorise."""
    zf = [fl(r) for r in zeros_ok]
    inter = [fl(r) for r in interdits]
    noms = {}
    for r in list(zeros_ok) + list(interdits):
        noms[fl(r)] = str(r)
    parts = []
    n = len(bornes)
    i = 0
    while i <= n:
        if sg[i] == "+":
            j = i
            while j + 1 <= n and sg[j + 1] == "+" and not any(abs(bornes[j] - x) < 1e-9 for x in inter) and not (zero_interdit and any(abs(bornes[j] - x) < 1e-9 for x in zf)):
                j += 1
            g = bornes[i - 1] if i > 0 else None
            d = bornes[j] if j < n else None
            def ferme(b):
                return b is not None and any(abs(b - x) < 1e-9 for x in zf) and not zero_interdit
            gs = "]-∞" if g is None else (("[" if ferme(g) else "]") + noms.get(g, approx(g)))
            ds = "+∞[" if d is None else (noms.get(d, approx(d)) + ("]" if ferme(d) else "["))
            parts.append(gs + " ; " + ds)
            i = j + 1
        else:
            i += 1
    # zeros isoles (signe nul en un point entre deux -)
    for b in bornes:
        if any(abs(b - x) < 1e-9 for x in zf) and not zero_interdit:
            k = bornes.index(b)
            if sg[k] != "+" and sg[k + 1] != "+":
                parts.append("{" + noms.get(b, approx(b)) + "}")
    return " ∪ ".join(parts) if parts else "∅"

def _trous_image(f0, fs):
    rs0, _ = _domaine(f0)
    rd = racines(fs.den)[0]
    for t in rs0:
        if all(abs(fl(t) - fl(p)) > 1e-9 for p in rd) and t.val.exact():
            y = fs.num.val(t.val.a) / fs.den.val(t.val.a)
            # autre x donnant y ?
            eq = fs.num - fs.den * y
            autres = [r for r in racines(eq)[0] if all(abs(fl(r) - fl(s)) > 1e-9 for s in rs0)]
            if not autres:
                print("Valeur interdite x = " + str(t.val) + " (simplifiée) :")
                print("  y = " + str(y) + " n'est atteint par aucun x, à retirer de I_f.")

def _variations(fs):
    n, d = fs.num, fs.den
    dn = n.derive() * d - n * d.derive()
    return dn

def e_variations(f0):
    titre("10. Variations et extremums")
    fs, g = f0.simplifiee()
    print("Au test (avant le chap. 5), justifie par")
    print("le graphe ou la forme a+b/… ; ici la")
    print("calculatrice contrôle avec le signe de f'.")
    dn = _variations(fs)
    rd = racines(fs.den)[0]
    rs0, _ = _domaine(f0)
    crit = [r for r in racines(dn)[0] if all(abs(fl(r) - fl(s)) > 1e-9 for s in rs0)]
    pts = sorted([fl(r) for r in crit] + [fl(r) for r in rs0])
    tests = points_tests(pts)
    noms = {}
    for r in crit + rs0:
        noms[fl(r)] = str(r.val)
    fv = lambda x: fs.num.valf(x) / fs.den.valf(x)
    li, vi = _limite_inf(fs, -1)
    print("x → -∞ : f → " + li)
    for i in range(len(tests)):
        s = dn.valf(tests[i]) * (1 if fs.den.valf(tests[i]) ** 2 > 0 else 1)
        sens = "croissante ↗" if s > 0 else ("décroissante ↘" if s < 0 else "constante")
        g_ = "-∞" if i == 0 else noms[pts[i - 1]]
        d_ = "+∞" if i == len(tests) - 1 else noms[pts[i]]
        print("]" + g_ + " ; " + d_ + "[ : " + sens)
        if i < len(pts):
            p = pts[i]
            if any(abs(p - fl(r)) < 1e-9 for r in rs0):
                if any(abs(p - fl(r)) < 1e-9 for r in rd):
                    print("  x=" + noms[p] + " : pôle (" + _limite_pole(fs, p, -1) + " | " + _limite_pole(fs, p, 1) + ")")
                else:
                    print("  x=" + noms[p] + " : interdite (trou)")
            else:
                r = [c for c in crit if abs(fl(c) - p) < 1e-9][0]
                if r.val.exact():
                    v = fs.num.val(r.val.a) / fs.den.val(r.val.a); vs = str(v)
                else:
                    v = fv(p); vs = "≈ " + approx(v)
                s1 = dn.valf(tests[i]); s2 = dn.valf(tests[i + 1])
                if s1 > 0 and s2 < 0:
                    nat = "max local"
                elif s1 < 0 and s2 > 0:
                    nat = "min local"
                else:
                    nat = "palier (pas d'extremum)"
                print("  x=" + noms[p] + " : " + nat + ", f = " + vs)
    ls, vs_ = _limite_inf(fs, 1)
    print("x → +∞ : f → " + ls)
    print("Extremum GLOBAL seulement si aucune")
    print("limite ni autre valeur ne le dépasse.")
    if rd:
        print("Ici des pôles mènent à ±∞ : pas de max")
        print("et/ou min global de ce côté.")

def e_bijection(f0):
    titre("11. Bijection f : I → J")
    fs, g = f0.simplifiee()
    print("Pourquoi : f est bijective sur un")
    print("intervalle I où elle est strictement")
    print("monotone ; J = f(I) se lit aux bornes.")
    dn = _variations(fs)
    rs0, _ = _domaine(f0)
    crit = [r for r in racines(dn)[0] if all(abs(fl(r) - fl(s)) > 1e-9 for s in rs0)]
    allp = sorted(crit + rs0, key=lambda r: fl(r))
    pts = [fl(r) for r in allp]
    tests = points_tests(pts)
    fv = lambda x: fs.num.valf(x) / fs.den.valf(x)
    rd = racines(fs.den)[0]
    def val_borne(i, cote):
        # valeur (texte, ferme?) de f a la borne pts[i] cote -1 gauche/+1 droite
        p = pts[i]; r = allp[i]
        if any(abs(p - fl(z)) < 1e-9 for z in rd):
            return _limite_pole(fs, p, cote), False
        if any(abs(p - fl(z)) < 1e-9 for z in rs0):
            if r.val.exact():
                return str(fs.num.val(r.val.a) / fs.den.val(r.val.a)), False
            return approx(fv(p + 1e-9)), False
        if r.val.exact():
            return str(fs.num.val(r.val.a) / fs.den.val(r.val.a)), True
        return "≈" + approx(fv(p)), True
    for i in range(len(tests)):
        s = dn.valf(tests[i])
        if abs(s) < 1e-15:
            continue
        if i == 0:
            gx, gf, gc = "-∞", _limite_inf(fs, -1)[0], False
        else:
            gx = str(allp[i - 1].val); gf, gc = val_borne(i - 1, 1)
        if i == len(tests) - 1:
            dx, df, dc = "+∞", _limite_inf(fs, 1)[0], False
        else:
            dx = str(allp[i].val); df, dc = val_borne(i, -1)
        I = ("[" if gc else "]") + gx + " ; " + dx + ("]" if dc else "[")
        if s > 0:
            J = ("[" if gc else "]") + gf + " ; " + df + ("]" if dc else "[")
        else:
            J = ("[" if dc else "]") + df + " ; " + gf + ("]" if gc else "[")
        print("I = " + I + " → J = " + J + (" (↗)" if s > 0 else " (↘)"))
    print("Choisis-en un ; bornes cohérentes avec")
    print("le signe gardé dans f⁻¹ (question 9).")

def e_points(f0):
    titre("12. Points pour le graphe")
    fs, g = f0.simplifiee()
    print("Graphe en 3 étapes : asymptotes,")
    print("quelques points, lissage.")
    rs0, _ = _domaine(f0)
    xs = [Q(k, 2) for k in range(-8, 9)]
    lig = []
    for x in xs:
        if any(abs(fl(x) - fl(r)) < 1e-9 for r in rs0):
            continue
        y = f0.num.val(x) / f0.den.val(x)
        lig.append(str(x) + " → " + str(y) + ("" if y.q == 1 else " ≈ " + approx(y, 2)))
    for i in range(0, len(lig), 1):
        print(lig[i])

def e_graphe(f0):
    titre("13. Graphe")
    print("Lecture : bleu = courbe, rouge pointillé")
    print("= asymptotes, o vert = zéros, x rouge = trou.")
    graphe.tracer(f0)

def e_facto(f0):
    titre("14. Factorisations détaillées")
    if f0.num.deg() >= 1:
        facto.bilan(f0.num, "N")
        pause()
    if f0.den.deg() >= 1:
        facto.bilan(f0.den, "D")

ETAPES = {13: e_graphe, 14: e_facto, 2: e_domaine, 3: e_simplif, 4: e_parite, 5: e_zeros, 6: e_signe,
          7: e_forme, 8: e_asymptotes, 9: e_reciproque, 10: e_variations,
          11: e_bijection, 12: e_points}
