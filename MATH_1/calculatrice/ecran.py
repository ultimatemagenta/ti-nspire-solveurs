# ecran : sortie mise en forme pour la TI-Nspire CX II
# Les print() des modules sont mis en tampon, puis voir() les affiche en plein
# ecran (ti_draw) avec couleurs et defilement ; input() vide d'abord le tampon
# dans la console. Sur PC (pas de ti_draw), tout part dans la console.

_print = print
_input = input
_BUF = []

try:
    import ti_draw as _d
    import ti_system as _s
    import time as _t
    TI = True
except ImportError:
    TI = False

def ecrire(*args):
    texte = " ".join(str(a) for a in args)
    for l in texte.split("\n"):
        _BUF.append(l)

def _vider():
    for l in _BUF:
        _print(l)
    del _BUF[:]

def demander_txt(msg=""):
    _vider()
    return _input(msg)

# ---------- styles ----------
RESULTATS = ("D_f", "I_f", "S =", "Résultat", "Asymptote", "AV ", "AH ", "AO ",
             "Zéro", "Pôle", "proj", "u × v =", "u x v =", "BON", "x1 =", "x2 =",
             "Quotient", "f(x) = ", "Facteur commun", "Pour x", "û =", "θ =",
             "cos θ =", "Aire", "Volume", "Valeur connue", "Sommet", "Forme canonique",
             "I = ", "Δ(m) =", "P = (", "Q = (", "Donc")
ALERTES = ("REJET", "interdit", "Attention", "NON", "PÉNALISÉ", "Pas compris", "Erreur", "impossible")
EXPLIC = ("Pourquoi", "Méthode", "Comment", "Au test", "Lecture", "Formule", "Note", "Ordre pair",
          "Crochets", "Pense", "Contrôle", "Par identification", "Le ±", "Graphe en")

def _style(l):
    s = l.strip()
    if s.startswith("== "):
        return "titre"
    for a in ALERTES:
        if a in s:
            return "alerte"
    for r in RESULTATS:
        if s.startswith(r):
            return "resultat"
    if s.startswith("]") or s.startswith("x=") or s.startswith("y=") or s.startswith("m="):
        return "tableau"
    for e in EXPLIC:
        if s.startswith(e):
            return "explic"
    return "normal"

COUL = {"titre": (255, 255, 255), "resultat": (0, 120, 0), "alerte": (200, 0, 0),
        "tableau": (0, 60, 170), "explic": (110, 110, 110), "normal": (0, 0, 0)}

# ---------- visionneuse ----------
def _couper(l, largeur):
    """Coupe une ligne trop large (mesure reelle de la police)."""
    if _d.string_size(l)[0] <= largeur:
        return [l]
    mots = l.split(" ")
    out = []; cur = ""
    for m in mots:
        essai = (cur + " " + m) if cur else m
        if _d.string_size(essai)[0] <= largeur:
            cur = essai
        else:
            if cur:
                out.append(cur)
            cur = "  " + m
    if cur:
        out.append(cur)
    return out

def _touche():
    while True:
        k = _s.get_key()
        if k:
            return k
        _t.sleep(0.05)

def voir():
    """Affiche le tampon en plein ecran ; fleches pour defiler, enter/esc pour continuer."""
    if not _BUF:
        return
    if not TI:
        _archiver(_BUF)
        _vider()
        return
    try:
        _archiver(_BUF)
        _visionneuse(list(_BUF))
        del _BUF[:]
    except Exception as e:
        _vider()
        _print("(affichage : " + str(e) + ")")

def _visionneuse(lignes):
    L, H = _d.get_screen_dim()
    hl = _d.string_size("Mg")[1] + 2
    marge = 4
    lignes_vis = []
    for l in lignes:
        st = _style(l)
        for i, m in enumerate(_couper(l, L - 2 * marge - 2)):
            lignes_vis.append((m, st if (i == 0 or st != "titre") else "titre"))
    n = (H - hl - 2) // hl  # lignes visibles (pied de page reserve)
    haut = 0
    _d.use_buffer()
    while True:
        _d.set_color(255, 255, 255)
        _d.fill_rect(0, 0, L, H)
        y = 0
        for txt, st in lignes_vis[haut:haut + n]:
            if st == "titre":
                _d.set_color(30, 70, 160)
                _d.fill_rect(0, y, L, hl)
            r, g, b = COUL[st]
            _d.set_color(r, g, b)
            base = y + hl - 3
            _d.draw_text(marge, base, txt)
            if st in ("titre", "resultat", "alerte"):
                _d.draw_text(marge + 1, base, txt)  # gras
            y += hl
        # pied de page
        _d.set_color(225, 225, 225)
        _d.fill_rect(0, H - hl, L, hl)
        _d.set_color(60, 60, 60)
        fin = min(haut + n, len(lignes_vis))
        _d.draw_text(marge, H - 3, "flèches: défiler  enter: suite  " + str(fin) + "/" + str(len(lignes_vis)))
        _d.paint_buffer()
        k = _touche()
        if k in ("enter", "esc", "del"):
            break
        elif k == "down" and haut + n < len(lignes_vis):
            haut += 1
        elif k == "up" and haut > 0:
            haut -= 1
        elif k == "right":
            haut = min(haut + n - 1, max(0, len(lignes_vis) - n))
        elif k == "left":
            haut = max(0, haut - n + 1)

# ---------- historique des resultats ----------
ARCHIVE = []

def _archiver(lignes):
    t = ""
    for l in lignes:
        if l.strip().startswith("== "):
            t = l.strip().strip("= ").strip()
            break
    if not t:
        t = lignes[0].strip()[:30] if lignes else "?"
    ARCHIVE.append((t, list(lignes)))
    if len(ARCHIVE) > 15:
        del ARCHIVE[0]

def historique():
    """Rouvre un resultat deja affiche."""
    effacer()
    if not ARCHIVE:
        _print("Historique vide (rien encore affiché).")
        return
    for i in range(len(ARCHIVE)):
        _print(str(i + 1) + " " + ARCHIVE[i][0][:34])
    c = _input("Numéro (enter = retour) : ").strip()
    try:
        i = int(c) - 1
        lignes = ARCHIVE[i][1]
    except Exception:
        return
    if TI:
        try:
            _visionneuse(lignes)
            return
        except Exception:
            pass
    for l in lignes:
        _print(l)

def effacer():
    """Efface la console avant un menu (lisibilite)."""
    if TI:
        try:
            _s.disp_clr()
        except Exception:
            pass

# ---------- memoire des saisies ----------
MEMO = {}

def _cle_ti(cle):
    return "m1" + cle

def _charger(cle):
    if cle in MEMO:
        return MEMO[cle]
    l = []
    if TI:
        try:
            codes = _s.recall_list(_cle_ti(cle))
            cur = ""
            for c in codes:
                c = int(c)
                if c == 0:
                    if cur:
                        l.append(cur)
                    cur = ""
                else:
                    cur += chr(c)
            if cur:
                l.append(cur)
        except Exception:
            l = []
    MEMO[cle] = l
    return l

def _sauver(cle):
    if not TI:
        return
    try:
        codes = []
        for t in MEMO[cle]:
            codes += [ord(ch) for ch in t] + [0]
        _s.store_list(_cle_ti(cle), codes)
    except Exception:
        pass

def demander_txt_memo(msg, cle):
    """Saisie avec memoire : enter = derniere valeur, h = liste des precedentes."""
    l = _charger(cle)
    if l:
        _vider()
        _print("(enter = " + l[-1][:28] + " ; h = liste)")
    while True:
        t = demander_txt(msg).strip()
        if t == "" and l:
            t = l[-1]
            _print("→ " + t)
        elif t in ("h", "H") and l:
            for i in range(len(l)):
                _print(str(i + 1) + " " + l[i][:34])
            c = _input("Numéro : ").strip()
            try:
                t = l[int(c) - 1]
                _print("→ " + t)
            except Exception:
                continue
        if t == "":
            continue
        if t in l:
            l.remove(t)
        l.append(t)
        if len(l) > 8:
            del l[0]
        _sauver(cle)
        return t
