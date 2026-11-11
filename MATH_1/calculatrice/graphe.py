# graphe : trace d'une fonction rationnelle sur l'ecran de la calculatrice (ti_plotlib)
from m1outils import *

try:
    import ti_plotlib as plt
except ImportError:
    plt = None

def _fenetre(fs, f0):
    """Fenetre [xmin;xmax]x[ymin;ymax] contenant zeros, poles, trous, extremums."""
    pts = []
    for p in (f0.num, f0.den, fs.num):
        if p.deg() >= 1:
            pts += [fl(r) for r in racines(p)[0]]
    dn = fs.num.derive() * fs.den - fs.num * fs.den.derive()
    crit = []
    if dn.deg() >= 1:
        crit = [fl(r) for r in racines(dn)[0]]
    pts += crit
    if pts:
        a = min(pts); b = max(pts)
    else:
        a = b = 0.0
    larg = max(b - a, 4.0)
    xmin = a - 0.6 * larg; xmax = b + 0.6 * larg
    f = lambda x: fs.num.valf(x) / fs.den.valf(x)
    ys = []
    for x in crit + [xmin, xmax]:
        try:
            ys.append(f(x))
        except ZeroDivisionError:
            pass
    for r in racines(fs.num)[0] if fs.num.deg() >= 1 else []:
        ys.append(0.0)
    q, r = fs.num.divmod(fs.den)
    if q.deg() <= 0:
        ys.append(fl(q.coef(0)))
    ys.append(0.0)
    ymin = min(ys); ymax = max(ys)
    h = max(ymax - ymin, 4.0)
    return xmin, xmax, ymin - 0.5 * h, ymax + 0.5 * h

def tracer(f0):
    fs, g = f0.simplifiee()
    xmin, xmax, ymin, ymax = _fenetre(fs, f0)
    poles = [fl(r) for r in racines(fs.den)[0]] if fs.den.deg() >= 1 else []
    rs0 = [r for r in racines(f0.den)[0]] if f0.den.deg() >= 1 else []
    trous = [r for r in rs0 if all(abs(fl(r) - p) > 1e-9 for p in poles)]
    q, reste = fs.num.divmod(fs.den)
    f = lambda x: fs.num.valf(x) / fs.den.valf(x)
    print("Fenêtre x : [" + approx(xmin, 2) + " ; " + approx(xmax, 2) + "]")
    print("Fenêtre y : [" + approx(ymin, 2) + " ; " + approx(ymax, 2) + "]")
    leg = []
    for p in poles:
        leg.append("AV x=" + approx(p, 2))
    if fs.num.deg() <= fs.den.deg() + 1 and fs.den.deg() >= 1:
        leg.append(("AH y=" if q.deg() <= 0 else "AO y=") + str(q))
    print("Asymptotes (pointillés) : " + (", ".join(leg) if leg else "aucune"))
    for t in trous:
        print("Trou (point exclu) en x = " + str(t.val))
    if plt is None:
        print("(ti_plotlib absent : graphe seulement")
        print(" sur la calculatrice)")
        return
    voir()
    try:
        _dessiner(fs, f0, xmin, xmax, ymin, ymax, poles, trous, q, leg, f)
    except Exception as e:
        print("Graphe impossible : " + str(e))

def _dessiner(fs, f0, xmin, xmax, ymin, ymax, poles, trous, q, leg, f):
    plt.cls()
    plt.window(xmin, xmax, ymin, ymax)
    plt.grid(1 if xmax - xmin < 30 else 5, 1 if ymax - ymin < 30 else 5, "dotted")
    plt.color(0, 0, 0)
    plt.axes("on")
    # asymptotes
    plt.color(220, 0, 0)
    plt.pen("thin", "dashed")
    for p in poles:
        plt.line(p, ymin, p, ymax, "default")
    if fs.num.deg() <= fs.den.deg() + 1 and fs.den.deg() >= 1:
        plt.line(xmin, q.valf(xmin), xmax, q.valf(xmax), "default")
    # courbe
    plt.color(0, 0, 220)
    plt.pen("medium", "solid")
    n = 240
    hauteur = ymax - ymin
    prec = None
    for i in range(n + 1):
        x = xmin + (xmax - xmin) * i / n
        if abs(fs.den.valf(x)) < 1e-12:
            prec = None
            continue
        y = f(x)
        if prec is not None:
            x0, y0 = prec
            coupe = any(x0 < p < x for p in poles) or fs.den.valf(x0) * fs.den.valf(x) < 0
            if not coupe and not ((y0 > ymax and y > ymax) or (y0 < ymin and y < ymin)):
                yc0 = max(min(y0, ymax + hauteur), ymin - hauteur)
                yc1 = max(min(y, ymax + hauteur), ymin - hauteur)
                plt.line(x0, yc0, x, yc1, "default")
        prec = (x, y)
    # zeros et trous
    plt.color(0, 150, 0)
    for r in racines(fs.num)[0] if fs.num.deg() >= 1 else []:
        plt.plot(fl(r), 0.0, "o")
    plt.color(220, 0, 0)
    for t in trous:
        x = fl(t)
        plt.plot(x, f(x), "x")
    plt.color(0, 0, 0)
    plt.text_at(12, " / ".join(leg)[:40], "left")
    plt.show_plot()
