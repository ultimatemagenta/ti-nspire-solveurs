"""Construit MATH_1/calculatrice/maths1.tns pour la TI-Nspire CX II.

1. Copie les scripts dans build/ en remplaçant les symboles absents de la police
   de la calculatrice (⟺, ∪, ✓, ℝ…) par des équivalents sûrs.
2. Vérifie qu'ils compilent.
3. Fabrique le classeur avec construire_tns.py (maths1.py s'ouvre en premier).

Usage : tools/py MATH_1/calculatrice/construire.py
"""
from pathlib import Path

from construire_tns import construire

ICI = Path(__file__).resolve().parent
SCRIPTS = ["maths1.py", "ecran.py", "m1outils.py", "facto.py", "graphe.py", "ident.py", "fonction.py", "vecteurs.py", "degre2.py", "parametre.py"]

# Symboles sûrs gardés tels quels : √ ∞ ≠ ≤ ≥ ² ³ ± · ≈ Δ θ π α β γ δ é è à ç ù ê â î ô
REMPLACE = {
    "⟺": "<=>", "⁻¹": "^-1", "∪": " U ", "↗": "^", "↘": "v", "✓": " ok", "✗": " NON",
    "‖": "||", "∅": "{}", "ℝ": "R", "…": "...", "∈": " dans ", "⊥": " orth. ", "×": "x",
    "→": "->", "∩": "n", "∪ ": "U ", "−": "-",
}


def nettoyer(texte: str) -> str:
    for a, b in REMPLACE.items():
        texte = texte.replace(a, b)
    return texte


def main() -> None:
    build = ICI / "build"
    build.mkdir(exist_ok=True)
    sorties = []
    for nom in SCRIPTS:
        src = (ICI / nom).read_text(encoding="utf-8")
        propre = nettoyer(src)
        compile(propre, nom, "exec")
        hors = sorted({c for c in propre if ord(c) > 0x7F and c not in "√∞≠≤≥²³±·≈ΔθπαβγδéèàçùêâîôÉÈÀ°"})
        if hors:
            print(nom, ": caractères non vérifiés :", " ".join(hors))
        p = build / nom
        p.write_text(propre, encoding="utf-8", newline="\n")
        sorties.append(p)
    construire(ICI / "maths1.tns", sorties)
    print("écrit :", ICI / "maths1.tns", f"({(ICI / 'maths1.tns').stat().st_size} octets)")


if __name__ == "__main__":
    main()
